import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await reveal(tester, finder);
  await tester.tap(finder.last);
}

/// Hosts a page on top of a root route so nested screens show their real Back arrow.
class NestedHost extends StatefulWidget {
  const NestedHost({super.key, required this.page});
  final Widget page;

  @override
  State<NestedHost> createState() => _NestedHostState();
}

class _NestedHostState extends State<NestedHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => widget.page));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
