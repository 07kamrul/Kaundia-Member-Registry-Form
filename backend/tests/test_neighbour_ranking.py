"""Pure neighbour-ranking rules: dag parsing, proximity order, tie-break,
same-type-only comparison, caller exclusion and the contact opt-out."""

import pytest

from app.services.neighbour_ranking import (
    DagType,
    PlotRow,
    PositionLabel,
    build_neighbour_directory,
    default_dag_type,
    parse_dag_number,
)

CALLER_ID = 1


def _row(
    property_id: int,
    member_id: int,
    *,
    rs: str | None = None,
    cs: str | None = None,
    name: str | None = None,
    mobile: str = "01700000000",
    shows_contact: bool = True,
    land: str | None = "5",
) -> PlotRow:
    return PlotRow(
        property_id=property_id,
        member_id=member_id,
        owner_name=name or f"Owner {member_id}",
        mobile=mobile,
        shows_contact=shows_contact,
        land_quantity=land,
        rs_dag=rs,
        cs_dag=cs,
    )


def _neighbour_rs_dags(group) -> list[str | None]:
    return [entry.rs_dag for entry in group.neighbours]


# --- parse_dag_number --------------------------------------------------------


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("830", 830),
        ("  830  ", 830),
        ("৮৩০", 830),
        ("830/1", 830),
        ("৮৩০/১", 830),
        ("দাগ নং ৮৩০", 830),
        ("RS-0042", 42),
        ("830, 831", 830),
    ],
)
def test_parse_dag_number_normalizes_messy_values(raw: str, expected: int) -> None:
    assert parse_dag_number(raw) == expected


@pytest.mark.parametrize("raw", [None, "", "   ", "abc", "দাগ", "-/-"])
def test_parse_dag_number_returns_none_for_unparseable_values(raw: str | None) -> None:
    assert parse_dag_number(raw) is None


# --- proximity ranking ---------------------------------------------------------


def test_nearest_dags_ordered_by_absolute_difference_with_lower_number_first_on_ties() -> None:
    # Arrange
    rows = [
        _row(1, CALLER_ID, rs="100"),
        *[
            _row(10 + i, 100 + i, rs=str(dag))
            for i, dag in enumerate([98, 101, 103, 99, 104, 110, 97])
        ],
    ]

    # Act
    directory = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5)

    # Assert: distances 99/101 -> 1, 98 -> 2, 97/103 -> 3; 104 and 110 are cut.
    (group,) = directory.properties
    assert group.dag_number == 100
    assert _neighbour_rs_dags(group) == ["99", "101", "98", "97", "103"]


def test_position_label_is_adjacent_only_for_dags_one_apart() -> None:
    rows = [_row(1, CALLER_ID, rs="50"), _row(2, 2, rs="51"), _row(3, 3, rs="53")]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    labels = {entry.rs_dag: entry.position_label for entry in group.neighbours}
    assert labels == {"51": PositionLabel.ADJACENT, "53": PositionLabel.NEAR}


def test_plot_limit_is_a_parameter_not_a_literal() -> None:
    rows = [_row(1, CALLER_ID, rs="10")] + [
        _row(100 + n, 100 + n, rs=str(10 + n)) for n in range(1, 13)
    ]

    five = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5)
    ten = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=10)

    assert len(five.properties[0].neighbours) == 5
    assert len(ten.properties[0].neighbours) == 10
    assert five.plot_limit == 5
    assert ten.plot_limit == 10


def test_fewer_neighbours_than_the_limit_returns_what_exists() -> None:
    rows = [_row(1, CALLER_ID, rs="10"), _row(2, 2, rs="12"), _row(3, 3, rs="20")]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    assert _neighbour_rs_dags(group) == ["12", "20"]


def test_limit_counts_distinct_dags_and_returns_every_owner_of_each() -> None:
    rows = [
        _row(1, CALLER_ID, rs="10"),
        _row(2, 2, rs="11", name="Bina"),
        _row(3, 3, rs="11", name="Arif"),
        _row(4, 4, rs="12"),
        _row(5, 5, rs="13"),
    ]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=2).properties

    # Two distinct dags (11, 12); dag 11 has two owners, sorted by name.
    assert [(e.rs_dag, e.owner_name) for e in group.neighbours] == [
        ("11", "Arif"),
        ("11", "Bina"),
        ("12", "Owner 4"),
    ]


# --- same dag ----------------------------------------------------------------------


def test_every_other_owner_of_the_callers_dag_is_listed_first_as_same_dag() -> None:
    rows = [
        _row(1, CALLER_ID, rs="830"),
        _row(2, 2, rs="৮৩০", name="Zaman"),
        _row(3, 3, rs="830/1", name="Alam"),
        _row(4, 4, rs="831"),
    ]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    assert [e.owner_name for e in group.same_dag_owners] == ["Alam", "Zaman"]
    assert {e.position_label for e in group.same_dag_owners} == {PositionLabel.SAME_DAG}
    assert _neighbour_rs_dags(group) == ["831"]


# --- dag type isolation --------------------------------------------------------------


def test_rs_and_cs_dags_are_never_compared_with_each_other() -> None:
    rows = [
        _row(1, CALLER_ID, rs="100", cs="500"),
        _row(2, 2, rs=None, cs="101"),  # close to 100 only if types were mixed
        _row(3, 3, rs="150", cs=None),
    ]

    rs_group = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties[0]
    cs_group = build_neighbour_directory(CALLER_ID, rows, DagType.CS, plot_limit=5).properties[0]

    assert [e.owner_name for e in rs_group.neighbours] == ["Owner 3"]
    assert [e.owner_name for e in cs_group.neighbours] == ["Owner 2"]
    assert cs_group.dag_number == 500


def test_unparseable_candidate_dags_are_excluded_without_crashing() -> None:
    rows = [
        _row(1, CALLER_ID, rs="10"),
        _row(2, 2, rs="abc"),
        _row(3, 3, rs=None),
        _row(4, 4, rs="11"),
    ]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    assert _neighbour_rs_dags(group) == ["11"]


def test_own_property_without_a_parseable_dag_yields_an_empty_group() -> None:
    rows = [_row(1, CALLER_ID, rs="unknown"), _row(2, 2, rs="11")]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    assert group.dag_number is None
    assert group.same_dag_owners == ()
    assert group.neighbours == ()


# --- several properties / caller exclusion ---------------------------------------------


def test_member_with_several_properties_gets_one_group_per_property() -> None:
    rows = [
        _row(7, CALLER_ID, rs="200"),
        _row(3, CALLER_ID, rs="10"),
        _row(20, 2, rs="11"),
        _row(21, 3, rs="201"),
    ]

    directory = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=1)

    assert [g.own.property_id for g in directory.properties] == [3, 7]
    assert [_neighbour_rs_dags(g) for g in directory.properties] == [["11"], ["201"]]


def test_callers_own_rows_never_appear_or_consume_a_neighbour_slot() -> None:
    rows = [
        _row(1, CALLER_ID, rs="10"),
        _row(2, CALLER_ID, rs="11"),  # caller's second plot right next door
        _row(3, 2, rs="10", name="Shared"),
        _row(4, 3, rs="12"),
    ]

    directory = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=1)
    first = directory.properties[0]

    assert [e.owner_name for e in first.same_dag_owners] == ["Shared"]
    assert _neighbour_rs_dags(first) == ["12"]
    for group in directory.properties:
        owners = group.same_dag_owners + group.neighbours
        assert all(e.owner_name != f"Owner {CALLER_ID}" for e in owners)


def test_member_with_no_properties_gets_no_groups() -> None:
    directory = build_neighbour_directory(CALLER_ID, [_row(2, 2, rs="11")], DagType.RS, plot_limit=5)

    assert directory.properties == ()


# --- contact opt-out -------------------------------------------------------------------


def test_opted_out_owner_is_listed_name_only() -> None:
    rows = [
        _row(1, CALLER_ID, rs="10"),
        _row(2, 2, rs="10", name="Private", mobile="01711111111", shows_contact=False),
        _row(3, 3, rs="11", name="Open", mobile="01722222222"),
    ]

    (group,) = build_neighbour_directory(CALLER_ID, rows, DagType.RS, plot_limit=5).properties

    (hidden,) = group.same_dag_owners
    (visible,) = group.neighbours
    assert (hidden.owner_name, hidden.mobile, hidden.contact_hidden) == ("Private", None, True)
    assert hidden.land_quantity == "5"
    assert (visible.mobile, visible.contact_hidden) == ("01722222222", False)


# --- default dag type --------------------------------------------------------------------


def test_default_dag_type_prefers_rs_then_falls_back_to_cs() -> None:
    assert default_dag_type([_row(1, CALLER_ID, rs="10", cs="20")]) is DagType.RS
    assert default_dag_type([_row(1, CALLER_ID, rs="n/a", cs="20")]) is DagType.CS
    assert default_dag_type([_row(1, CALLER_ID)]) is DagType.RS
    assert default_dag_type([]) is DagType.RS


def test_requested_dag_type_none_resolves_to_the_callers_default() -> None:
    rows = [_row(1, CALLER_ID, cs="20"), _row(2, 2, cs="21")]

    directory = build_neighbour_directory(CALLER_ID, rows, None, plot_limit=5)

    assert directory.dag_type is DagType.CS
    assert [e.cs_dag for e in directory.properties[0].neighbours] == ["21"]
