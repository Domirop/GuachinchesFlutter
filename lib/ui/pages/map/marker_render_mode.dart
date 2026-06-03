enum MarkerRenderMode { dot, label, teardrop }

/// Pure function: decides how to render a map marker given current context.
/// No BuildContext, State, or I/O dependencies.
MarkerRenderMode resolveMarkerRenderMode({
  required double zoom,
  required bool isSelected,
  required bool isDriving,
  required int indexInViewport,
  required int viewportCount,
  required double bubbleZoomThreshold,
  required double labelZoomThreshold,
  required int maxLabelsInViewport,
}) {
  if (isSelected) return MarkerRenderMode.teardrop;
  if (isDriving) return MarkerRenderMode.dot;
  if (zoom < labelZoomThreshold) return MarkerRenderMode.dot;
  if (indexInViewport >= maxLabelsInViewport) return MarkerRenderMode.dot;
  return MarkerRenderMode.label;
}
