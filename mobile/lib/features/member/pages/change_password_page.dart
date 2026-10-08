import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../presentation/bloc/change_password_bloc.dart';
import '../presentation/widgets/member_ui.dart';

/// Port of Angular ChangePasswordComponent: current/new/confirm fields with
/// password policy validation, server 422 field mapping and the success state
/// followed by a redirect to /dashboard.
class ChangePasswordPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ChangePasswordPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChangePasswordBloc(
        repository: MemberRepository(apiClient: sl<ApiClient>()),
      ),
      child: const _ChangePasswordView(),
    );
  }
}

/// A password card reads best narrow, even on tablets.
const double _cardMaxWidth = 560;

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _redirecting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(ChangePasswordBloc bloc) {
    bloc.add(ChangePasswordValidated(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    ));
    if (validateChangePassword(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    ).ok) {
      bloc.add(ChangePasswordSubmitted(current: _current.text, next: _next.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          if (state.success && !_redirecting) {
            _redirecting = true;
            Future<void>.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted && sl<SessionManager>().isAuthenticated) {
                context.go('/dashboard');
              }
            });
          }
        },
        builder: (context, state) {
          return PageBody(
            maxWidth: _cardMaxWidth,
            children: [
              PageHeader(title: loc.memberChangePasswordTitle, icon: Icons.lock_reset_outlined),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: state.success
                      ? _SuccessPanel(message: loc.memberChangePasswordSuccessMessage)
                      : _form(context, state, loc),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _form(BuildContext context, ChangePasswordState state, AppLocalizations loc) {
    final bloc = context.read<ChangePasswordBloc>();
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.generalError)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NoticeBanner(
                margin: EdgeInsets.zero,
                tone: NoticeTone.error,
                message: loc.memberChangePasswordChangeFailedError,
                action: TextButton.icon(
                  onPressed: () => bloc.add(
                    ChangePasswordSubmitted(current: _current.text, next: _next.text),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(loc.commonRetry),
                ),
              ),
            ),
          _PasswordField(
            label: loc.memberChangePasswordCurrentPasswordLabel,
            controller: _current,
            icon: Icons.lock_outline,
            autofillHint: AutofillHints.password,
            errorText: _errorText(state.currentError, state.currentServerError, loc),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            label: loc.memberChangePasswordNewPasswordLabel,
            controller: _next,
            icon: Icons.key_outlined,
            autofillHint: AutofillHints.newPassword,
            errorText: _errorText(state.newError, state.newServerError, loc),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            label: loc.memberChangePasswordConfirmPasswordLabel,
            controller: _confirm,
            icon: Icons.verified_user_outlined,
            autofillHint: AutofillHints.newPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: state.submitting ? null : (_) => _submit(bloc),
            errorText: _errorText(state.confirmError, null, loc),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: state.submitting
                ? loc.memberChangePasswordSavingButton
                : loc.memberChangePasswordSaveButton,
            icon: Icons.check,
            expanded: true,
            loading: state.submitting,
            onPressed: () => _submit(bloc),
          ),
        ],
      ),
    );
  }

  String? _errorText(
      ChangePasswordFieldError error, String? serverMessage, AppLocalizations loc) {
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    return switch (error) {
      ChangePasswordFieldError.required =>
        loc.memberChangePasswordCurrentPasswordRequiredError,
      ChangePasswordFieldError.policy => loc.memberChangePasswordPasswordPolicyError,
      ChangePasswordFieldError.sameAsCurrent =>
        loc.memberChangePasswordSameAsCurrentError,
      ChangePasswordFieldError.mismatch =>
        loc.memberChangePasswordPasswordMismatchError,
      ChangePasswordFieldError.none => null,
    };
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.autofillHint,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String autofillHint;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: [widget.autofillHint],
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        errorMaxLines: 3,
        prefixIcon: Icon(widget.icon),
        suffixIcon: IconButton(
          tooltip: _obscure ? loc.passwordfieldShow : loc.passwordfieldHide,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}
