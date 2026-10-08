import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'session.dart';

/// DTO as returned by POST /login (snake_case on the wire).
class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.role = 'member',
    this.permissions = const [],
    this.mustChangePassword = false,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) => TokenResponseDto(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        role: (json['role'] as String?) ?? 'member',
        permissions:
            (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                const [],
        mustChangePassword: json['must_change_password'] == true || json['must_change_password'] == 1,
      );

  final String accessToken;
  final String? refreshToken;
  final String role;
  final List<String> permissions;
  final bool mustChangePassword;
}

/// Domain entity — camelCase.
class AuthResult {
  const AuthResult({
    required this.session,
    this.mustChangePassword = false,
  });

  final Session session;
  final bool mustChangePassword;
}

extension TokenResponseDtoX on TokenResponseDto {
  AuthResult toEntity() => AuthResult(
        session: Session(
          accessToken: accessToken,
          role: role,
          permissions: permissions.toSet(),
          mustChangePassword: mustChangePassword,
        ),
        mustChangePassword: mustChangePassword,
      );
}

/// Data source + repository in one: login / forgot / reset + persistence.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _api = apiClient,
        _tokens = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<AuthResult> login(String identifier, String password) async {
    final data = await _api.post('/login', {
      'identifier': identifier,
      'password': password,
    }) as Map<String, dynamic>;
    final dto = TokenResponseDto.fromJson(data);
    await _tokens.write(access: dto.accessToken, refresh: dto.refreshToken);
    return dto.toEntity();
  }

  Future<void> forgotPassword(String identifier) =>
      _api.post('/forgot-password', {'identifier': identifier});

  Future<void> resetPassword(String token, String newPassword) => _api.post('/reset-password', {
        'token': token,
        'new_password': newPassword,
      });

  Future<String?> currentToken() => _tokens.readAccess();

  Future<void> logout() => _tokens.clear();
}
