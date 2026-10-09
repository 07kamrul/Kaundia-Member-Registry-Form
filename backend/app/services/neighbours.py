"""Database side of the neighbour directory: read approved members' plots and
hand them to the pure ranking rules in `app.services.neighbour_ranking`."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.member import Member, MemberStatus
from app.models.property import Property
from app.services.neighbour_ranking import (
    DagType,
    NeighbourDirectory,
    PlotRow,
    build_neighbour_directory,
)


async def load_approved_plot_rows(db: AsyncSession) -> list[PlotRow]:
    """Every property of every approved member, narrowed to the columns the
    directory may show.

    Dag values are free text that only Python can compare (Bangla digits,
    "830/1"), so ranking runs after this read and an index on the dag columns
    would never be used; the read itself filters on the indexed
    `members.status` and joins on the indexed `properties.member_id`.
    """
    result = await db.execute(
        select(
            Property.id,
            Property.member_id,
            Member.full_name,
            Member.mobile,
            Member.show_in_neighbour_directory,
            Property.land_quantity,
            Property.dag_no_rs,
            Property.dag_no_cs,
        )
        .join(Member, Member.id == Property.member_id)
        .where(Member.status == MemberStatus.APPROVED)
    )
    return [
        PlotRow(
            property_id=property_id,
            member_id=member_id,
            owner_name=full_name,
            mobile=mobile,
            shows_contact=bool(shows_contact),
            land_quantity=land_quantity,
            rs_dag=dag_no_rs,
            cs_dag=dag_no_cs,
        )
        for (
            property_id,
            member_id,
            full_name,
            mobile,
            shows_contact,
            land_quantity,
            dag_no_rs,
            dag_no_cs,
        ) in result.all()
    ]


async def find_member_neighbours(
    db: AsyncSession,
    *,
    member_id: int,
    dag_type: DagType | None,
    plot_limit: int,
) -> NeighbourDirectory:
    """The neighbour directory for an approved member's own plots."""
    rows = await load_approved_plot_rows(db)
    return build_neighbour_directory(member_id, rows, dag_type, plot_limit)


def describe_lookup(directory: NeighbourDirectory) -> str:
    """Audit detail for one lookup: dag type, the caller's dags queried and
    how many owners were returned - enough to spot scraping patterns."""
    dags = [group.dag_number for group in directory.properties if group.dag_number is not None]
    return f"dag_type={directory.dag_type.value} dags={dags} returned={directory.owner_count}"
