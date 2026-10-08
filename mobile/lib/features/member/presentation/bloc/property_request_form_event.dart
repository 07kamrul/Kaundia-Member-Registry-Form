part of 'property_request_form_bloc.dart';

sealed class PropertyRequestFormEvent extends Equatable {
  const PropertyRequestFormEvent();

  @override
  List<Object?> get props => const [];
}

class PropertyRequestFormInitialized extends PropertyRequestFormEvent {
  const PropertyRequestFormInitialized({this.propertyId});

  final String? propertyId;
}

class PropertyRequestFormFieldChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormFieldChanged({
    this.propertyType,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
  });

  final List<String>? propertyType;
  final String? propertyTypeOther;
  final String? khatianNo;
  final String? dagNoCs;
  final String? dagNoRs;
  final String? holdingNumber;
  final String? landQuantity;
  final String? myShareQuantity;
  final String? ownership;

  @override
  List<Object?> get props => [
        propertyType,
        propertyTypeOther,
        khatianNo,
        dagNoCs,
        dagNoRs,
        holdingNumber,
        landQuantity,
        myShareQuantity,
        ownership,
      ];
}

class PropertyRequestFormCoOwnerAdded extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerAdded();
}

class PropertyRequestFormCoOwnerRemoved extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerRemoved(this.index);

  final int index;
}

class PropertyRequestFormCoOwnerChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerChanged(this.index, this.row);

  final int index;
  final FormCoOwnerRow row;
}

class PropertyRequestFormDocAdded extends PropertyRequestFormEvent {
  const PropertyRequestFormDocAdded();
}

class PropertyRequestFormDocRemoved extends PropertyRequestFormEvent {
  const PropertyRequestFormDocRemoved(this.index);

  final int index;
}

class PropertyRequestFormDocChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormDocChanged(this.index, this.row);

  final int index;
  final FormDocRow row;
}

class PropertyRequestFormExistingDocKeepChanged
    extends PropertyRequestFormEvent {
  const PropertyRequestFormExistingDocKeepChanged(this.index,
      {required this.keep});

  final int index;
  final bool keep;
}

class PropertyRequestFormSubmitted extends PropertyRequestFormEvent {
  const PropertyRequestFormSubmitted();
}
