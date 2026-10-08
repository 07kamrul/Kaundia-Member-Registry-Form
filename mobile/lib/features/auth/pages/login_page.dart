import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

/// Port of Angular `login.component.*`: centered auth card with the society
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
  bool _submitAttempted = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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
    context.read<AuthBloc>().add(AuthLoginRequested(
          identifier: _identifierController.text.trim().toLowerCase(),
          password: _passwordController.text,
          returnUrl: widget.returnUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final identifierError = _identifierError(loc);
    final passwordError = _passwordError(loc);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    if (state.mustChangePassword) {
                      context.go('/change-password');
                    } else {
                      context.go(destinationAfterLogin(state.session, widget.returnUrl));
                    }
                  }
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo placeholder (no binary assets in the app).
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.groups, size: 44, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(loc.authLoginTitle, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          loc.authLoginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final failure = state is AuthFailure ? state.error : null;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (failure != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      (failure.isBusiness && failure.businessMessage != null)
                                          ? failure.businessMessage!
                                          : loc.authLoginLoginFailedError,
                                      style: TextStyle(color: theme.colorScheme.error),
                                    ),
                                  ),
                                TextField(
                                  controller: _identifierController,
                                  autofillHints: const [AutofillHints.username],
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: loc.authLoginIdentifierLabel,
                                    errorText: identifierError,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: loc.authLoginPasswordLabel,
                                    errorText: passwordError,
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? loc.authLoginShowPassword
                                          : loc.authLoginHidePassword,
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.go('/forgot-password'),
                                    child: Text(loc.authLoginForgotPasswordLink),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppButton(
                                  label: state is AuthLoading
                                      ? loc.authLoginLoggingInButton
                                      : loc.authLoginSubmitButton,
                                  onPressed: state is AuthLoading ? null : _submit,
                                  expanded: true,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(loc.authLoginNotAMemberYet),
                        const SizedBox(height: 12),
                        AppButton(
                          label: loc.authLoginRegisterButton,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => context.go('/register'),
                          expanded: true,
                        ),
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: Text('← ${loc.authLoginBackToHome}'),
                        ),
                      ],
                    ),
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
