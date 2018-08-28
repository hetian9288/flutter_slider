import 'package:flutter/material.dart';

enum FlutterSliderEvent {
  PREV_INDEX,
  NEXT_INDEX,
  MOVE_INDEX,
  START_AUTOPLAY,
  STOP_AUTOPLAY
}

class FlutterSliderController extends ChangeNotifier {
  int index;
  bool animation;
  bool autoplay;
  FlutterSliderEvent _event;

  FlutterSliderEvent get event => _event;

  FlutterSliderController();

  /// move to index
  void move(int index, {bool animation: true}) {
    _event = FlutterSliderEvent.MOVE_INDEX;
    this.index = index;
    this.animation = animation;
    notifyListeners();
  }

  /// goto next index
  void next({bool animation: true}) {
    _event = FlutterSliderEvent.NEXT_INDEX;
    this.animation = animation;
    notifyListeners();
  }

  /// goto prev index
  void prev({bool animation: true}) {
    _event = FlutterSliderEvent.PREV_INDEX;
    this.animation = animation;
    notifyListeners();
  }

  void startAutoplay() {
    _event = FlutterSliderEvent.START_AUTOPLAY;
    this.autoplay = true;
    notifyListeners();
  }

  void stopAutoplay() {
    _event = FlutterSliderEvent.STOP_AUTOPLAY;
    this.autoplay = false;
    notifyListeners();
  }

}