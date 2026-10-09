import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Injectable wrapper around url_launcher so widgets stay testable.
/// Returns false when no app can handle [uri].
abstract class ExternalLinkLauncher {
  Future<bool> open(Uri uri);
}

class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherExternalLinkLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
