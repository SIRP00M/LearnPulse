import 'package:flutter/material.dart';

import 'theme.dart';

/// Window classes use available logical width, including resizable windows.
abstract final class StudioLayout {
  static const medium = 600.0;
  static const expanded = 840.0;
  static const maxWorkspace = 1200.0;
  static const reading = 760.0;

  static bool columns(BuildContext context, double width) =>
      width >= expanded && MediaQuery.textScalerOf(context).scale(16) <= 28;

  static double gutter(double width) => width < medium ? Space.md : Space.xl;
}

/// Bounded page with one scroll owner and a stable tree during rotation.
class StudioPage extends StatelessWidget {
  const StudioPage({
    super.key,
    required this.children,
    this.secondary = const [],
    this.maxWidth = StudioLayout.maxWorkspace,
    this.padding,
  });

  final List<Widget> children;
  final List<Widget> secondary;
  final double maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding:
          padding ?? EdgeInsets.all(StudioLayout.gutter(constraints.maxWidth)),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: StudioColumns(
              primary: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
              secondary: secondary.isEmpty
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: secondary,
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Flex changes direction without replacing or reparenting stateful content.
class StudioColumns extends StatelessWidget {
  const StudioColumns({super.key, required this.primary, this.secondary});
  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = StudioLayout.columns(context, constraints.maxWidth);
      return Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: wide ? 3 : 0,
            child: SizedBox(
              width: double.infinity,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                child: primary,
              ),
            ),
          ),
          if (secondary != null) ...[
            SizedBox(width: wide ? Space.xl : 0, height: wide ? 0 : Space.lg),
            Flexible(
              flex: wide ? 2 : 0,
              child: SizedBox(
                width: double.infinity,
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: secondary,
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
