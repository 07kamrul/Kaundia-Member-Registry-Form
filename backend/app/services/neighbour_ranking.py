"""Pure ranking rules for the member neighbour directory.

No database access here: plot rows come in, ranked groups come out, so every
rule (proximity order, tie-break, same-type-only comparison, messy dag
values, caller exclusion, contact opt-out) is unit-testable on its own.

Rules:
- A dag is compared only with dags of the same type (RS with RS, CS with CS).
- Dag values are free text ("830/1", " ৮৩০ ", "দাগ নং 830"); the first run of
  digits after Bangla->ASCII conversion is the dag number. Values with no
  digits are left out of ranking rather than failing the lookup.
- Owners of the caller's own dag come first (`same_dag`). Then the
  `plot_limit` nearest *distinct* other dags, ordered by absolute numeric
  difference with the lower number first on ties, each with all its owners.
- The caller's own rows are never listed and never take a neighbour slot.
- An owner who opted out of the directory is listed name-only.
"""

import enum
import heapq
import re
from collections.abc import Iterable, Sequence
from dataclasses import dataclass

_BANGLA_TO_ASCII_DIGITS = str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")
_FIRST_INTEGER = re.compile(r"\d+", re.ASCII)

# Dags exactly one number apart are labelled "adjacent"; anything further is "near".
ADJACENT_DAG_DISTANCE = 1


class DagType(str, enum.Enum):
    RS = "rs"
    CS = "cs"


class PositionLabel(str, enum.Enum):
    SAME_DAG = "same_dag"
    ADJACENT = "adjacent"
    NEAR = "near"


@dataclass(frozen=True)
class PlotRow:
    """One property of an approved member, as read from the database."""

    property_id: int
    member_id: int
    owner_name: str
    mobile: str
    shows_contact: bool
    land_quantity: str | None
    rs_dag: str | None
    cs_dag: str | None

    def dag_for(self, dag_type: DagType) -> str | None:
        return self.rs_dag if dag_type is DagType.RS else self.cs_dag


@dataclass(frozen=True)
class OwnerEntry:
    """A neighbouring owner as shown to the caller - privacy-safe fields only."""

    owner_name: str
    mobile: str | None
    contact_hidden: bool
    land_quantity: str | None
    rs_dag: str | None
    cs_dag: str | None
    position_label: PositionLabel


@dataclass(frozen=True)
class PropertyNeighbours:
    own: PlotRow
    dag_number: int | None
    same_dag_owners: tuple[OwnerEntry, ...]
    neighbours: tuple[OwnerEntry, ...]

    @property
    def owner_count(self) -> int:
        return len(self.same_dag_owners) + len(self.neighbours)


@dataclass(frozen=True)
class NeighbourDirectory:
    dag_type: DagType
    plot_limit: int
    properties: tuple[PropertyNeighbours, ...]

    @property
    def owner_count(self) -> int:
        return sum(group.owner_count for group in self.properties)


def parse_dag_number(raw: str | None) -> int | None:
    """The dag number inside a free-text dag value, or None when it has no digits."""
    if raw is None:
        return None
    match = _FIRST_INTEGER.search(raw.translate(_BANGLA_TO_ASCII_DIGITS))
    return int(match.group()) if match else None


def default_dag_type(own_rows: Iterable[PlotRow]) -> DagType:
    """RS when any of the member's plots has a usable RS dag, else CS when one
    has a usable CS dag, else RS."""
    rows = tuple(own_rows)
    for dag_type in (DagType.RS, DagType.CS):
        if any(parse_dag_number(row.dag_for(dag_type)) is not None for row in rows):
            return dag_type
    return DagType.RS


def _owner_sort_key(row: PlotRow) -> tuple[str, int]:
    return (row.owner_name.casefold(), row.property_id)


def _to_entry(row: PlotRow, position: PositionLabel) -> OwnerEntry:
    return OwnerEntry(
        owner_name=row.owner_name,
        mobile=row.mobile if row.shows_contact else None,
        contact_hidden=not row.shows_contact,
        land_quantity=row.land_quantity,
        rs_dag=row.rs_dag,
        cs_dag=row.cs_dag,
        position_label=position,
    )


def _index_by_dag(rows: Iterable[PlotRow], dag_type: DagType) -> dict[int, tuple[PlotRow, ...]]:
    grouped: dict[int, list[PlotRow]] = {}
    for row in rows:
        number = parse_dag_number(row.dag_for(dag_type))
        if number is not None:
            grouped.setdefault(number, []).append(row)
    return {number: tuple(sorted(owners, key=_owner_sort_key)) for number, owners in grouped.items()}


def _nearest_dags(own_dag: int, candidate_dags: Iterable[int], limit: int) -> list[int]:
    others = (dag for dag in candidate_dags if dag != own_dag)
    return heapq.nsmallest(limit, others, key=lambda dag: (abs(dag - own_dag), dag))


def _rank_property(
    own: PlotRow,
    owners_by_dag: dict[int, tuple[PlotRow, ...]],
    dag_type: DagType,
    plot_limit: int,
) -> PropertyNeighbours:
    own_dag = parse_dag_number(own.dag_for(dag_type))
    if own_dag is None:
        return PropertyNeighbours(own=own, dag_number=None, same_dag_owners=(), neighbours=())

    same_dag = tuple(
        _to_entry(row, PositionLabel.SAME_DAG) for row in owners_by_dag.get(own_dag, ())
    )
    neighbours = tuple(
        _to_entry(
            row,
            PositionLabel.ADJACENT if abs(dag - own_dag) == ADJACENT_DAG_DISTANCE else PositionLabel.NEAR,
        )
        for dag in _nearest_dags(own_dag, owners_by_dag, plot_limit)
        for row in owners_by_dag[dag]
    )
    return PropertyNeighbours(own=own, dag_number=own_dag, same_dag_owners=same_dag, neighbours=neighbours)


def build_neighbour_directory(
    caller_member_id: int,
    rows: Sequence[PlotRow],
    dag_type: DagType | None,
    plot_limit: int,
) -> NeighbourDirectory:
    """Group the caller's own plots with the owners on and around each one.

    `rows` must already be limited to approved members; the caller's own rows
    are split out here. `dag_type=None` resolves to the caller's default.
    """
    own_rows = sorted((row for row in rows if row.member_id == caller_member_id), key=lambda r: r.property_id)
    resolved_type = dag_type or default_dag_type(own_rows)
    owners_by_dag = _index_by_dag(
        (row for row in rows if row.member_id != caller_member_id), resolved_type
    )
    return NeighbourDirectory(
        dag_type=resolved_type,
        plot_limit=plot_limit,
        properties=tuple(_rank_property(own, owners_by_dag, resolved_type, plot_limit) for own in own_rows),
    )
