import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/plot_boundary_repository_impl.dart';
import '../../domain/plot_boundary_repository.dart';

/// Small indirection so the report use case can be swapped in tests.
class ReportSubmitter {
  ReportSubmitter(this._override);

  final Future<void> Function(String, String)? _override;

  Future<bool> call(String boundaryId, String note) async {
    try {
      if (_override != null) {
        await _override(boundaryId, note);
      } else {
        await ReportBoundaryProblem(
          PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()),
        )(boundaryId, note);
      }
      return true;
    } on Exception {
      return false;
    }
  }
}

/// "Report a problem" note sheet. Calls [onSent] once the report went out.
Future<void> showReportSheet(
  BuildContext context, {
  required String boundaryId,
  required ReportSubmitter submit,
  required VoidCallback onSent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportSheet(
      boundaryId: boundaryId,
      submit: submit,
      onSent: onSent,
    ),
  );
}

class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.boundaryId,
    required this.submit,
    required this.onSent,
  });

  final String boundaryId;
  final ReportSubmitter submit;
  final VoidCallback onSent;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _failed = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final note = _controller.text.trim();
    if (note.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final ok = await widget.submit(widget.boundaryId, note);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _failed = !ok;
      _sent = ok;
    });
    if (ok) widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.boundaryReport, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_sent)
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(child: Text(loc.boundaryReportSent)),
              ],
            )
          else ...[
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: loc.boundaryReportNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  loc.boundaryReportError,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            AppButton(
              label: loc.boundaryReportSubmit,
              expanded: true,
              loading: _sending,
              onPressed:
                  _controller.text.trim().isEmpty ? null : _send,
            ),
          ],
          if (_sent) ...[
            const SizedBox(height: 12),
            AppButton(
              label: loc.commonClose,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
