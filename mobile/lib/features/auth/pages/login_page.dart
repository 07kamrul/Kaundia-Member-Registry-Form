import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import 'auth_scaffold.dart';

/// Port of Angular `login.component.*`: branded auth layout with the society
/// logo, identifier + password fields, show/hide password, inline error box
/// for 401/business failures, and loading state on the submit button.
class LoginPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const LoginPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _submitAttempted = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _identifierError(AppLocalizations loc) {
    if (!_submitAttempted) return null;
    if (_identifierController.text.trim().isEmpty) {
      return loc.authLoginIdentifierRequiredError;
    }
    return null;
  }

  String? _passwordError(AppLocalizations loc) {
    if (!_submitAttempted) return null;
    if (_passwordController.text.isEmpty) return loc.authLoginPasswordRequiredError;
    return null;
  }

  void _submit() {
    setState(() => _submitAttempted = true);
    if (_identifierController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthLoginRequested(
          identifier: _identifierController.text.trim().toLowerCase(),
          password: _passwordController.text,
          returnUrl: widget.returnUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          if (state.mustChangePassword) {
            context.go('/change-password');
          } else {
            context.go(destinationAfterLogin(state.session, widget.returnUrl));
          }
        }
      },
      child: AuthScaffold(
        title: loc.authLoginTitle,
        subtitle: loc.authLoginSubtitle,
        footer: [
          Text(
            loc.authLoginNotAMemberYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: loc.authLoginRegisterButton,
            icon: Icons.how_to_reg_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go('/register'),
            expanded: true,
          ),
          const SizedBox(height: 4),
          AuthFooterLink(
            label: loc.authLoginBackToHome,
            icon: Icons.home_outlined,
            onPressed: () => context.go('/'),
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => _buildForm(context, loc, state),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations loc, AuthState state) {
    final failure = state is AuthFailure ? state.error : null;
    final loading = state is AuthLoading;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            AuthNotice(
              message: (failure.isBusiness && failure.businessMessage != null)
                  ? failure.businessMessage!
                  : loc.authLoginLoginFailedError,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _identifierController,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            enabled: !loading,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: loc.authLoginIdentifierLabel,
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _identifierError(loc),
            ),
          ),
          const SizedBox(height: 16),
          _passwordField(loc, loading),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: Text(loc.authLoginForgotPasswordLink),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: loading ? loc.authLoginLoggingInButton : loc.authLoginSubmitButton,
            icon: Icons.login,
            loading: loading,
            onPressed: _submit,
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _passwordField(AppLocalizations loc, bool loading) {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      enabled: !loading,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: loc.authLoginPasswordLabel,
        prefixIcon: const Icon(Icons.lock_outline),
        errorText: _passwordError(loc),
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? loc.authLoginShowPassword : loc.authLoginHidePassword,
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }
}
