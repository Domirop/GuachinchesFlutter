import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/map/marker_render_mode.dart';

void main() {
  const double bubbleThreshold = 13.0;
  const double labelThreshold = 14.0;
  const int maxLabels = 24;

  MarkerRenderMode resolve({
    required double zoom,
    required bool isSelected,
    required bool isDriving,
    required int indexInViewport,
    int viewportCount = 10,
  }) =>
      resolveMarkerRenderMode(
        zoom: zoom,
        isSelected: isSelected,
        isDriving: isDriving,
        indexInViewport: indexInViewport,
        viewportCount: viewportCount,
        bubbleZoomThreshold: bubbleThreshold,
        labelZoomThreshold: labelThreshold,
        maxLabelsInViewport: maxLabels,
      );

  group('resolveMarkerRenderMode', () {
    test('zoom below bubble threshold → dot', () {
      expect(
        resolve(zoom: 10.0, isSelected: false, isDriving: false, indexInViewport: 0),
        MarkerRenderMode.dot,
      );
    });

    test('zoom in middle range (>= bubble, < label) → dot', () {
      expect(
        resolve(zoom: 13.5, isSelected: false, isDriving: false, indexInViewport: 0),
        MarkerRenderMode.dot,
      );
    });

    test('zoom above label threshold → label', () {
      expect(
        resolve(zoom: 15.0, isSelected: false, isDriving: false, indexInViewport: 0),
        MarkerRenderMode.label,
      );
    });

    test('driving mode, not selected → dot regardless of zoom', () {
      expect(
        resolve(zoom: 15.0, isSelected: false, isDriving: true, indexInViewport: 0),
        MarkerRenderMode.dot,
      );
    });

    test('index at cap → dot', () {
      expect(
        resolve(
          zoom: 15.0,
          isSelected: false,
          isDriving: false,
          indexInViewport: maxLabels,
          viewportCount: 30,
        ),
        MarkerRenderMode.dot,
      );
    });

    test('index below cap → label', () {
      expect(
        resolve(
          zoom: 15.0,
          isSelected: false,
          isDriving: false,
          indexInViewport: maxLabels - 1,
          viewportCount: 30,
        ),
        MarkerRenderMode.label,
      );
    });

    test('selected → teardrop regardless of low zoom', () {
      expect(
        resolve(zoom: 10.0, isSelected: true, isDriving: false, indexInViewport: 0),
        MarkerRenderMode.teardrop,
      );
    });

    test('selected in driving mode → teardrop (not dot)', () {
      expect(
        resolve(zoom: 15.0, isSelected: true, isDriving: true, indexInViewport: 0),
        MarkerRenderMode.teardrop,
      );
    });
  });
}
