import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 5: submission date, declaration checkbox, and a drawn signature pad
/// (saved as PNG; the data URL rides the payload's member_signature).
class DeclarationStep extends StatelessWidget {
  const DeclarationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);

    final declarationError = findError(state.stepErrors, RegErrorKind.declarationRequired) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegTextField(
          label: l10n.registrationHeaderSubmissionDateLabel,
          value: state.form.submissionDate,
          readOnly: true,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        const _SignaturePad(),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l10n.registrationDeclarationTitle}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: l10n.registrationDeclarationText),
                  ],
                ),
              ),
              RegCheckboxRow(
                value: state.form.declarationAccepted,
                label: l10n.registrationDeclarationConsentLabel,
                onChanged: (v) => bloc.add(DeclarationToggled(v)),
              ),
              if (declarationError)
                Text(
                  l10n.registrationDeclarationConsentRequired,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Freehand signature capture with CustomPainter; "save" rasterizes the
/// boundary to PNG bytes, writes a temp file and dispatches SignatureSaved.
class _SignaturePad extends StatefulWidget {
  const _SignaturePad();

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSignature = context.watch<RegistrationBloc>().state.form.memberSignature.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(
          text: l10n.registrationSignatureSectionTitle,
          child: Text(l10n.registrationSignatureHint, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 4),
        Container(
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: GestureDetector(
            onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
            onPanUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: CustomPaint(
                  painter: _SignaturePainter(strokes: _strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _strokes.clear()),
              child: Text(l10n.registrationSignatureClearButton),
            ),
            const Spacer(),
            AppButton(
              label: hasSignature ? l10n.registrationSignatureSavedButton : l10n.registrationSignatureSaveButton,
              onPressed: _strokes.isEmpty ? null : () => _save(context),
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (!context.mounted) return;
    context.read<RegistrationBloc>().add(SignatureSaved(file.path));
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes});

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = AppColors.gray800
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        canvas.drawCircle(stroke.first, 1.5, Paint()..color = AppColors.gray800);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
