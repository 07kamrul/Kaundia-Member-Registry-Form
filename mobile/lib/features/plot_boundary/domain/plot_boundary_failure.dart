import '../../../core/network/api_exception.dart';

/// Failure families the plot-boundary UI distinguishes. Validation codes map
/// 1:1 to backend 400 codes; the rest follow the neighbours pattern.
enum PlotBoundaryFailureKind {
  network,
  selfIntersecting,
  outsideSociety,
  zeroArea,
  tooManyVertices,
  invalidGeometry,
  notYourProperty,
  boundaryExists,
  rateLimited,
  notApproved,
  other,
}

const String _codeSelfIntersecting = 'SELF_INTERSECTING';
const String _codeOutsideSociety = 'OUTSIDE_SOCIETY_AREA';
const String _codeZeroArea = 'ZERO_AREA';
const String _codeTooManyVertices = 'TOO_MANY_VERTICES';
const String _codeInvalidGeometry = 'INVALID_GEOMETRY';
const String _codeNotYourProperty = 'NOT_YOUR_PROPERTY';
const String _codeBoundaryExists = 'BOUNDARY_EXISTS';
const String _codeOwnerRateLimited = 'BOUNDARY_OWNER_RATE_LIMITED';
const String _codeBoundaryNotApproved = 'BOUNDARY_NOT_APPROVED';

const int _forbidden = 403;
const int _conflict = 409;
const int _tooManyRequests = 429;

PlotBoundaryFailureKind plotBoundaryFailureKindOf(ApiException e) {
  switch (e.errorCode) {
    case _codeSelfIntersecting:
      return PlotBoundaryFailureKind.selfIntersecting;
    case _codeOutsideSociety:
      return PlotBoundaryFailureKind.outsideSociety;
    case _codeZeroArea:
      return PlotBoundaryFailureKind.zeroArea;
    case _codeTooManyVertices:
      return PlotBoundaryFailureKind.tooManyVertices;
    case _codeInvalidGeometry:
      return PlotBoundaryFailureKind.invalidGeometry;
    case _codeNotYourProperty:
      return PlotBoundaryFailureKind.notYourProperty;
    case _codeBoundaryExists:
      return PlotBoundaryFailureKind.boundaryExists;
    case _codeOwnerRateLimited:
      return PlotBoundaryFailureKind.rateLimited;
    case _codeBoundaryNotApproved:
      return PlotBoundaryFailureKind.notApproved;
  }
  if (e.isNetwork) return PlotBoundaryFailureKind.network;
  if (e.statusCode == _tooManyRequests) {
    return PlotBoundaryFailureKind.rateLimited;
  }
  if (e.statusCode == _conflict) return PlotBoundaryFailureKind.boundaryExists;
  if (e.statusCode == _forbidden) {
    return PlotBoundaryFailureKind.notYourProperty;
  }
  return PlotBoundaryFailureKind.other;
}
