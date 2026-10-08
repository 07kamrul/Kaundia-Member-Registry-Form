import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

/// Port of Angular `forgot-password.component.*`: identifier form, success box
/// once the reset link request is accepted, error box on failure.
class ForgotPasswordPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const ForgotPasswordPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  bool _submitAttempted = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _submitAttempted = true;
      _error = null;
    });
    if (_identifierController.text.trim().isEmpty) return;
    context.read<AuthBloc>().add(
          AuthForgotPasswordRequested(_identifierController.text.trim().toLowerCase()),
        );
  }

  String? _identifierError(AppLocalizations loc) {
    if (!_submitAttempted) return null;
    if (_identifierController.text.trim().isEmpty) {
      return loc.authForgotPasswordIdentifierRequiredError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final identifierError = _identifierError(loc);

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
                      Text(loc.authForgotPasswordTitle, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthActionSucceeded) {
                            setState(() => _sent = true);
                          } else if (state is AuthFailure) {
                            setState(
                              () => _error = state.error.businessMessage ??
                                  loc.authForgotPasswordErrorsRequestFailed,
                            );
                          }
                        },
                        builder: (context, state) {
                          if (_sent) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(loc.authForgotPasswordSentMessage),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                loc.authForgotPasswordSubtitle,
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
                                controller: _identifierController,
                                autofillHints: const [AutofillHints.username],
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                enableSuggestions: false,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: loc.authForgotPasswordIdentifierLabel,
                                  errorText: identifierError,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: state is AuthLoading
                                    ? loc.authForgotPasswordSendingButton
                                    : loc.authForgotPasswordSubmitButton,
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
