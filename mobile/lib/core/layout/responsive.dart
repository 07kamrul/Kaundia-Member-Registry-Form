import 'package:flutter/material.dart';

/// Material 3 window size classes. Every layout decision in the app should go
/// through these instead of ad-hoc `MediaQuery` width checks.
enum WindowSize { compact, medium, expanded }

class Breakpoints {
  const Breakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;

  /// Readable max width for forms / detail pages.
  static const double formMaxWidth = 720;

  /// Max width for list / dashboard content.
  static const double contentMaxWidth = 1200;

  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }
}

extension ResponsiveContext on BuildContext {
  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);
  bool get isCompact => windowSize == WindowSize.compact;
  bool get isMedium => windowSize == WindowSize.medium;
  bool get isExpanded => windowSize == WindowSize.expanded;

  /// Horizontal page gutter that grows with the window.
  double get pageGutter => switch (windowSize) {
        WindowSize.compact => 16,
        WindowSize.medium => 24,
        WindowSize.expanded => 32,
      };

  /// Pick a value per size class (medium/expanded fall back to the smaller one).
  T responsive<T>({required T compact, T? medium, T? expanded}) => switch (windowSize) {
        WindowSize.compact => compact,
        WindowSize.medium => medium ?? compact,
        WindowSize.expanded => expanded ?? medium ?? compact,
      };
}

/// Centers [child] and caps its width so content never stretches edge to edge
/// on tablets / landscape.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// Lays children out in as many columns as fit [minItemWidth], so the same
/// list shows 1 column on phones and 2–4 on tablets. Children keep their
/// natural height (no forced aspect ratio).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 320,
    this.spacing = 12,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            ((width + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
