import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import 'auth_scaffold.dart';

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
  final _confirmFocus = FocusNode();
  bool _submitAttempted = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resetDone = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _confirmFocus.dispose();
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
    FocusScope.of(context).unfocus();
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
    final showForm = !_tokenMissing && !_resetDone;
    return AuthScaffold(
      title: loc.authResetPasswordTitle,
      subtitle: showForm ? loc.authResetPasswordSubtitle : null,
      footer: [
        if (_resetDone) ...[
          AppButton(
            label: loc.navLogin,
            icon: Icons.login,
            onPressed: () => context.go('/login'),
            expanded: true,
          ),
          const SizedBox(height: 4),
        ] else
          AuthFooterLink(
            label: loc.authForgotPasswordBackToLogin,
            onPressed: () => context.go('/login'),
          ),
      ],
      child: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_tokenMissing) {
      return AuthNotice(message: loc.authResetPasswordMissingTokenError);
    }
    if (_resetDone) {
      return AuthNotice(message: loc.authResetPasswordSuccessMessage, isError: false);
    }
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSucceeded) {
          setState(() => _resetDone = true);
        } else if (state is AuthFailure) {
          setState(() => _error = _mapFailure(loc, state.error));
        }
      },
      builder: (context, state) => _buildForm(loc, state is AuthLoading),
    );
  }

  Widget _buildForm(AppLocalizations loc, bool loading) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthNotice(message: _error!),
            const SizedBox(height: 16),
          ],
          _PasswordField(
            controller: _newPasswordController,
            label: loc.authResetPasswordNewPasswordLabel,
            helper: loc.authResetPasswordPasswordHint,
            error: _newPasswordError(loc),
            obscure: _obscureNew,
            enabled: !loading,
            textInputAction: TextInputAction.next,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmFocus,
            label: loc.authResetPasswordConfirmPasswordLabel,
            error: _confirmError(loc),
            obscure: _obscureConfirm,
            enabled: !loading,
            textInputAction: TextInputAction.done,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: loading
                ? loc.authResetPasswordResettingButton
                : loc.authResetPasswordSubmitButton,
            icon: Icons.lock_reset,
            loading: loading,
            onPressed: _submit,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.enabled,
    required this.textInputAction,
    required this.onToggle,
    required this.onChanged,
    required this.onSubmitted,
    this.focusNode,
    this.helper,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? helper;
  final String? error;
  final bool obscure;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      autofillHints: const [AutofillHints.newPassword],
      keyboardType: TextInputType.visiblePassword,
      textInputAction: textInputAction,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: error == null ? helper : null,
        helperMaxLines: 2,
        errorText: error,
        errorMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? loc.authLoginShowPassword : loc.authLoginHidePassword,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
