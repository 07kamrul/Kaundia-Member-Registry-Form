import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';

/// Port of Angular `reset-password.component.*`: token comes from the `token`
/// query parameter (same contract as the emailed reset link), missing token ->
/// error box, mismatched confirm -> field error, 422 -> weak password,
/// 400 -> invalid/expired token.
class ResetPasswordPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const ResetPasswordPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitAttempted = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resetDone = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _token =>
      GoRouterState.of(context).uri.queryParameters['token'] ?? '';

  bool get _tokenMissing => _token.trim().isEmpty;

  bool get _mismatch =>
      _newPasswordController.text != _confirmPasswordController.text;

  String? _newPasswordError(AppLocalizations loc) {
    if (!_submitAttempted) return null;
    if (_newPasswordController.text.isEmpty) return loc.authResetPasswordPasswordHint;
    return null;
  }

  String? _confirmError(AppLocalizations loc) {
    if (!_submitAttempted) return null;
    if (_confirmPasswordController.text.isEmpty) {
      return loc.authResetPasswordPasswordRequiredError;
    }
    if (_mismatch) return loc.authResetPasswordMismatchError;
    return null;
  }

  void _submit() {
    setState(() {
      _submitAttempted = true;
      _error = null;
    });
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _mismatch) {
      return;
    }
    context.read<AuthBloc>().add(AuthResetPasswordRequested(
          token: _token,
          newPassword: _newPasswordController.text,
        ));
  }

  String _mapFailure(AppLocalizations loc, ApiException error) {
    if (error.statusCode == 422) return loc.authResetPasswordWeakPasswordError;
    if (error.statusCode == 400) return loc.authResetPasswordInvalidTokenError;
    return loc.authResetPasswordErrorsResetFailed;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.groups, size: 44, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(loc.authResetPasswordTitle, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      if (_tokenMissing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.authResetPasswordMissingTokenError,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        )
                      else if (_resetDone)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(loc.authResetPasswordSuccessMessage),
                        )
                      else
                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthActionSucceeded) {
                              setState(() => _resetDone = true);
                            } else if (state is AuthFailure) {
                              setState(() => _error = _mapFailure(loc, state.error));
                            }
                          },
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  loc.authResetPasswordSubtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 24),
                                if (_error != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: theme.colorScheme.error),
                                    ),
                                  ),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  autofillHints: const [AutofillHints.newPassword],
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: loc.authResetPasswordNewPasswordLabel,
                                    errorText: _newPasswordError(loc),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNew
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscureNew = !_obscureNew),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  autofillHints: const [AutofillHints.newPassword],
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: loc.authResetPasswordConfirmPasswordLabel,
                                    errorText: _confirmError(loc),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: state is AuthLoading
                                      ? loc.authResetPasswordResettingButton
                                      : loc.authResetPasswordSubmitButton,
                                  onPressed: state is AuthLoading ? null : _submit,
                                  expanded: true,
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      const Divider(),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('← ${loc.authForgotPasswordBackToLogin}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
