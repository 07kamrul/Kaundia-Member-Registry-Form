import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import 'auth_scaffold.dart';

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
    FocusScope.of(context).unfocus();
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
    return AuthScaffold(
      title: loc.authForgotPasswordTitle,
      subtitle: _sent ? null : loc.authForgotPasswordSubtitle,
      footer: [
        AuthFooterLink(
          label: loc.authForgotPasswordBackToLogin,
          onPressed: () => context.go('/login'),
        ),
      ],
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthActionSucceeded) {
            setState(() => _sent = true);
          } else if (state is AuthFailure) {
            setState(
              () => _error =
                  state.error.businessMessage ?? loc.authForgotPasswordErrorsRequestFailed,
            );
          }
        },
        builder: (context, state) {
          if (_sent) {
            return AuthNotice(message: loc.authForgotPasswordSentMessage, isError: false);
          }
          return _buildForm(loc, state is AuthLoading);
        },
      ),
    );
  }

  Widget _buildForm(AppLocalizations loc, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          AuthNotice(message: _error!),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _identifierController,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.send,
          enabled: !loading,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: loc.authForgotPasswordIdentifierLabel,
            prefixIcon: const Icon(Icons.alternate_email),
            errorText: _identifierError(loc),
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: loading ? loc.authForgotPasswordSendingButton : loc.authForgotPasswordSubmitButton,
          icon: Icons.send_outlined,
          loading: loading,
          onPressed: _submit,
          expanded: true,
        ),
      ],
    );
  }
}
