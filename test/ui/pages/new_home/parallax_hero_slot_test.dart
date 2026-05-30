import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero_slot.dart';

void main() {
  testWidgets(
    'ParallaxHeroSlot reposiciona el Positioned sin reconstruir el child',
    (tester) async {
      final offset = ValueNotifier<double>(0);
      int buildCount = 0;
      const stackKey = Key('test-stack');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              key: stackKey,
              children: [
                ParallaxHeroSlot(
                  offset: offset,
                  child: Builder(builder: (_) {
                    buildCount++;
                    return const ColoredBox(color: Colors.red);
                  }),
                ),
              ],
            ),
          ),
        ),
      );

      // (b) tras el primer pump, el child se construyó exactamente una vez.
      await tester.pump();
      expect(buildCount, 1);

      // (c) offset = 120 → top == -120, child NO se reconstruye.
      offset.value = 120;
      await tester.pump();
      final positioned1 = tester.widget<Positioned>(
        find.descendant(
          of: find.byKey(stackKey),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned1.top, -120);
      expect(buildCount, 1);

      // (d) offset = -50 (overscroll) → height == kHeroHeight + 50, child NO se reconstruye.
      offset.value = -50;
      await tester.pump();
      final positioned2 = tester.widget<Positioned>(
        find.descendant(
          of: find.byKey(stackKey),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned2.height, kHeroHeight + 50);
      expect(buildCount, 1);

      offset.dispose();
    },
  );
}
