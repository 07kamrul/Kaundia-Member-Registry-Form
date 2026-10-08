import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../presentation/bloc/change_password_bloc.dart';

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
          final bloc = context.read<ChangePasswordBloc>();
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: state.success
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green.shade700, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  loc.memberChangePasswordSuccessMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.green.shade800),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  loc.memberChangePasswordTitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (state.generalError) ...[
                                  const SizedBox(height: 12),
                                  InlineError(
                                    message: loc.memberChangePasswordChangeFailedError,
                                    onRetry: () => bloc.add(ChangePasswordSubmitted(
                                      current: _current.text,
                                      next: _next.text,
                                    )),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _field(
                                  label: loc.memberChangePasswordCurrentPasswordLabel,
                                  controller: _current,
                                  errorText: _errorText(
                                      state.currentError, state.currentServerError, loc),
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: loc.memberChangePasswordNewPasswordLabel,
                                  controller: _next,
                                  errorText: _errorText(
                                      state.newError, state.newServerError, loc),
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: loc.memberChangePasswordConfirmPasswordLabel,
                                  controller: _confirm,
                                  errorText: _errorText(state.confirmError, null, loc),
                                ),
                                const SizedBox(height: 20),
                                AppButton(
                                  label: state.submitting
                                      ? loc.memberChangePasswordSavingButton
                                      : loc.memberChangePasswordSaveButton,
                                  expanded: true,
                                  onPressed: state.submitting
                                      ? null
                                      : () {
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
                                            bloc.add(ChangePasswordSubmitted(
                                              current: _current.text,
                                              next: _next.text,
                                            ));
                                          }
                                        },
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
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
