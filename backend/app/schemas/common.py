from pydantic import BaseModel


class AddressDetail(BaseModel):
    house: str | None = None
    road: str | None = None
    post_office: str | None = None
    upazila: str | None = None
    district: str | None = None
    division: str | None = None


class Nominee(BaseModel):
    name: str
    relation: str
    mobile: str
    address: str | None = None


class CoOwner(BaseModel):
    owner_name: str
    owner_phone: str


class ApplicableDocIn(BaseModel):
    doc_type: str


class PropertyIn(BaseModel):
    property_type: list[str] = []
    property_type_other: str | None = None
    khatian_no: str | None = None
    dag_no_cs: str | None = None
    dag_no_rs: str | None = None
    holding_number: str | None = None
    land_quantity: str | None = None
    ownership: str | None = None
    co_owners: list[CoOwner] = []
    applicable_docs: list[ApplicableDocIn] = []
