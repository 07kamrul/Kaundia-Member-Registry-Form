import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/di/injector.dart';
import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../utils/download_utils.dart';
import 'widgets.dart';

enum AttachmentKind { image, pdf, other }

AttachmentKind attachmentKindFor(String url) {
  final lower = url.toLowerCase().split('?').first;
  if (RegExp(r'\.(png|jpe?g|gif|webp|avif)$').hasMatch(lower)) {
    return AttachmentKind.image;
  }
  if (lower.endsWith('.pdf') || lower.endsWith('/export.pdf')) {
    return AttachmentKind.pdf;
  }
  return AttachmentKind.other;
}

/// In-app attachment preview (mirrors the Angular profile/fund-transparency
/// attachment modal): images render inline with a friendly error fallback on
/// 404; every other type offers download + open via open_filex.
///
/// [rawPathOrUrl] accepts either a server-relative path (encoded with
/// [AppConfig.fileUrl]) or an absolute http(s) URL.
class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({super.key, required this.rawPathOrUrl, this.title, this.kind});

  final String rawPathOrUrl;
  final String? title;
  final AttachmentKind? kind;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late final AttachmentKind kind =
      widget.kind ?? attachmentKindFor(widget.rawPathOrUrl);
  late final String url = widget.rawPathOrUrl.startsWith('http')
      ? widget.rawPathOrUrl
      : AppConfig.fileUrl(widget.rawPathOrUrl);

  bool downloading = false;
  String? loadError;

  Future<void> _download() async {
    if (downloading) return;
    setState(() => downloading = true);
    final loc = AppLocalizations.of(context);
    try {
      final dioClient = sl<ApiClient>().dio;
      await downloadUrlAndOpen(
        dioClient: dioClient,
        url: url,
        fileName: _fileName(),
      );
      if (mounted) showAppToast(context, loc.attachmentViewerDownloadStarted);
    } catch (_) {
      if (mounted) showAppToast(context, loc.attachmentViewerDownloadFailed, error: true);
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  String _fileName() {
    final title = widget.title?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
    if (title != null && title.isNotEmpty) {
      final ext = RegExp(r'\.([a-z0-9]{1,8})$').firstMatch(url.split('?').first)?.group(1);
      return ext != null ? '$title.$ext' : title;
    }
    return Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.title!, style: theme.textTheme.titleMedium),
          ),
        if (kind == AttachmentKind.image)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: loadError != null
                  ? _missing(context)
                  : InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return _missing(context);
                        },
                      ),
                    ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  kind == AttachmentKind.pdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(loc.attachmentViewerPreviewUnavailable,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AppButton(
          label: downloading ? loc.commonLoading : loc.attachmentViewerDownloadOpen,
          icon: downloading ? Icons.hourglass_top : Icons.download,
          variant: AppButtonVariant.secondary,
          expanded: true,
          onPressed: downloading ? null : _download,
        ),
      ],
    );
  }

  Widget _missing(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined,
              size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).attachmentViewerMissing,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Opens the in-app attachment dialog (never a raw browser navigation).
Future<void> showAttachmentViewer(
  BuildContext context, {
  required String rawPathOrUrl,
  String? title,
  AttachmentKind? kind,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      content: AttachmentViewer(rawPathOrUrl: rawPathOrUrl, title: title, kind: kind),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).commonClose),
        ),
      ],
    ),
  );
}

/// Convenience for member/management screens holding a raw server path that
/// may be null (missing attachment).
Future<void> viewAttachmentOrNull(
  BuildContext context, {
  String? rawPathOrUrl,
  required String missingMessage,
  String? title,
}) async {
  if (rawPathOrUrl == null || rawPathOrUrl.isEmpty) {
    showAppToast(context, missingMessage, error: true);
    return;
  }
  await showAttachmentViewer(context, rawPathOrUrl: rawPathOrUrl, title: title);
}
