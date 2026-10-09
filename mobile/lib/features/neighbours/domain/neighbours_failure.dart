import '../../../core/network/api_exception.dart';

enum NeighboursFailureKind { network, rateLimited, approvedOnly, other }

const String neighbourApprovedOnlyCode = 'NEIGHBOUR_DIRECTORY_APPROVED_ONLY';
const String neighbourRateLimitedCode = 'NEIGHBOUR_LOOKUP_RATE_LIMITED';
const int _forbidden = 403;
const int _tooManyRequests = 429;

/// Maps an [ApiException] to the message family the page shows.
NeighboursFailureKind neighboursFailureKindOf(ApiException e) {
  if (e.isNetwork) return NeighboursFailureKind.network;
  if (e.statusCode == _tooManyRequests ||
      e.errorCode == neighbourRateLimitedCode) {
    return NeighboursFailureKind.rateLimited;
  }
  if (e.statusCode == _forbidden && e.errorCode == neighbourApprovedOnlyCode) {
    return NeighboursFailureKind.approvedOnly;
  }
  return NeighboursFailureKind.other;
}
