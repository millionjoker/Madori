// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void setupWheelListener(
  void Function() refresh,
  double Function() getScale,
  void Function(double) setScale,
) {
  html.window.onWheel.listen((event) {
    double scale = getScale();
    scale -= event.deltaY * 0.001;
    scale = scale.clamp(0.2, 5.0);
    setScale(scale);
    refresh();
  });
}
