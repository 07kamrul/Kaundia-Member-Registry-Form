import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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
    final theme = Theme.of(context);

    final declarationError = findError(state.stepErrors, RegErrorKind.declarationRequired) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesDeclarationAndSignature),
        RegSectionCard(
          child: RegTextField(
            label: l10n.registrationHeaderSubmissionDateLabel,
            value: state.form.submissionDate,
            readOnly: true,
            prefixIcon: Icons.event_outlined,
            onChanged: (_) {},
          ),
        ),
        const RegSectionCard(child: _SignaturePad()),
        RegSectionCard(
          title: l10n.registrationDeclarationTitle,
          icon: Icons.gavel_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.registrationDeclarationText, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: declarationError ? theme.colorScheme.error : theme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: RegCheckboxRow(
                  value: state.form.declarationAccepted,
                  label: l10n.registrationDeclarationConsentLabel,
                  onChanged: (v) => bloc.add(DeclarationToggled(v)),
                ),
              ),
              if (declarationError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.registrationDeclarationConsentRequired,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
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
  static const double _padHeight = 180;

  final _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasSignature = context.watch<RegistrationBloc>().state.form.memberSignature.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: RegLabel(text: l10n.registrationSignatureSectionTitle)),
            if (hasSignature)
              StatusBadge(kind: StatusKind.approved, label: l10n.registrationSignatureSavedButton),
          ],
        ),
        const SizedBox(height: 2),
        Text(l10n.registrationSignatureHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          height: _padHeight,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            color: Colors.white,
          ),
          // Claims the pointer on touch-down so vertical strokes draw instead
          // of scrolling the surrounding form.
          child: RawGestureDetector(
            gestures: {
              _EagerPanRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
                () => _EagerPanRecognizer(debugOwner: this),
                (recognizer) {
                  recognizer.onStart = (d) => setState(() => _strokes.add([d.localPosition]));
                  recognizer.onUpdate = (d) => setState(() => _strokes.last.add(d.localPosition));
                },
              ),
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm - 1),
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
        const SizedBox(height: 8),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          overflowSpacing: 8,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.restart_alt, size: 18),
              onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.clear()),
              label: Text(l10n.registrationSignatureClearButton),
            ),
            AppButton(
              label: hasSignature
                  ? l10n.registrationSignatureSavedButton
                  : l10n.registrationSignatureSaveButton,
              icon: hasSignature ? Icons.check_circle_outline : Icons.draw_outlined,
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

/// Pan recognizer that wins the gesture arena immediately on pointer down.
class _EagerPanRecognizer extends PanGestureRecognizer {
  _EagerPanRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
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
