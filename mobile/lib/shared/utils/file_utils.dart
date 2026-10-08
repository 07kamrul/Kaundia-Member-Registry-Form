import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';

/// File helpers mirroring the Angular upload path: images are compressed
/// before upload and the payload must stay <= 5MB.

const maxUploadBytes = 5 * 1024 * 1024;

class AttachedFile {
  AttachedFile({required this.path, required this.fileName, required this.mimeType});

  final String path;
  final String fileName;
  final String mimeType;

  int get sizeBytes => File(path).lengthSync();
  bool get withinLimit => sizeBytes <= maxUploadBytes;
}

Future<AttachedFile?> prepareImage(String path) async {
  final compressed = await FlutterImageCompress.compressAndGetFile(
    path,
    '${path}_c.jpg',
    quality: 82,
    format: CompressFormat.jpeg,
  );
  final finalPath = compressed?.path ?? path;
  return AttachedFile(
    path: finalPath,
    fileName: finalPath.split(Platform.pathSeparator).last.split('/').last,
    mimeType: 'image/jpeg',
  );
}

Future<AttachedFile> prepareAnyFile(String path, String fileName) async {
  final mime = lookupMimeType(path) ?? 'application/octet-stream';
  final f = AttachedFile(path: path, fileName: fileName, mimeType: mime);
  if (!f.withinLimit) {
    throw const FileTooLargeError();
  }
  return f;
}

class FileTooLargeError implements Exception {
  const FileTooLargeError();
}

MultipartFile toMultipart(AttachedFile f) => MultipartFile.fromFileSync(
      f.path,
      filename: f.fileName,
      contentType: DioMediaType.parse(f.mimeType),
    );

/// Validation mirroring Angular: JPG/PNG/PDF only, <=5MB.
bool isAllowedDocType(String mimeType) =>
    {'image/jpeg', 'image/png', 'application/pdf'}.contains(mimeType);
