from app.schemas.member import PropertyOut


def test_property_out_exposes_my_share_quantity():
    out = PropertyOut.model_validate(
        {"id": 1, "property_type": ["জমি"], "my_share_quantity": "3"}
    )
    assert out.my_share_quantity == "3"


def test_property_out_my_share_quantity_defaults_to_none():
    out = PropertyOut.model_validate({"id": 1, "property_type": []})
    assert out.my_share_quantity is None
