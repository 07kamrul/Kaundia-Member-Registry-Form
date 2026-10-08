import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';

/// Saves [bytes] into the app's downloads directory and returns the file.
Future<File> saveDownload(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final downloads = Directory('${dir.path}/downloads');
  if (!downloads.existsSync()) downloads.createSync(recursive: true);
  final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  final file = File('${downloads.path}/$safeName');
  await file.writeAsBytes(bytes);
  return file;
}

/// Downloads via [api] (Bearer-authenticated) then opens with open_filex.
/// Used for PDFs and other non-inline attachments.
Future<void> downloadAndOpen({
  required ApiClient api,
  required String path,
  required String fileName,
  Map<String, dynamic>? query,
}) async {
  final bytes = await api.downloadBytes(path, query: query);
  final file = await saveDownload(bytes, fileName);
  await OpenFilex.open(file.path);
}

/// Opens an absolute URL by downloading through dio (no auth header needed
/// for static uploads) then open_filex.
Future<void> downloadUrlAndOpen({
  required dio.Dio dioClient,
  required String url,
  required String fileName,
}) async {
  final res = await dioClient.get<List<int>>(
    url,
    options: dio.Options(responseType: dio.ResponseType.bytes),
  );
  final file = await saveDownload(res.data ?? const [], fileName);
  await OpenFilex.open(file.path);
}
