"""Response models for GET /api/member/neighbours.

These models are the privacy whitelist: only owner name, mobile (withheld
when the owner opted out), land quantity, RS/CS dag and relative position
ever leave the server - never NID, email, address, DOB, parents, documents,
payments, or another member's id.
"""

from pydantic import BaseModel

from app.services.neighbour_ranking import (
    DagType,
    NeighbourDirectory,
    OwnerEntry,
    PositionLabel,
    PropertyNeighbours,
)


class NeighbourOwnerOut(BaseModel):
    owner_name: str
    mobile: str | None
    contact_hidden: bool
    land_quantity: str | None
    rs_dag: str | None
    cs_dag: str | None
    position_label: PositionLabel

    @classmethod
    def from_entry(cls, entry: OwnerEntry) -> "NeighbourOwnerOut":
        return cls(
            owner_name=entry.owner_name,
            mobile=entry.mobile,
            contact_hidden=entry.contact_hidden,
            land_quantity=entry.land_quantity,
            rs_dag=entry.rs_dag,
            cs_dag=entry.cs_dag,
            position_label=entry.position_label,
        )


class OwnPlotOut(BaseModel):
    property_id: int
    rs_dag: str | None
    cs_dag: str | None
    land_quantity: str | None
    # The number ranked for the requested dag type; None when that dag is
    # missing or has no digits, in which case the group has no owners.
    dag_number: int | None


class NeighbourGroupOut(BaseModel):
    own: OwnPlotOut
    same_dag_owners: list[NeighbourOwnerOut]
    neighbours: list[NeighbourOwnerOut]

    @classmethod
    def from_group(cls, group: PropertyNeighbours) -> "NeighbourGroupOut":
        return cls(
            own=OwnPlotOut(
                property_id=group.own.property_id,
                rs_dag=group.own.rs_dag,
                cs_dag=group.own.cs_dag,
                land_quantity=group.own.land_quantity,
                dag_number=group.dag_number,
            ),
            same_dag_owners=[NeighbourOwnerOut.from_entry(e) for e in group.same_dag_owners],
            neighbours=[NeighbourOwnerOut.from_entry(e) for e in group.neighbours],
        )


class NeighbourDirectoryOut(BaseModel):
    dag_type: DagType
    plot_limit: int
    properties: list[NeighbourGroupOut]

    @classmethod
    def from_directory(cls, directory: NeighbourDirectory) -> "NeighbourDirectoryOut":
        return cls(
            dag_type=directory.dag_type,
            plot_limit=directory.plot_limit,
            properties=[NeighbourGroupOut.from_group(g) for g in directory.properties],
        )
