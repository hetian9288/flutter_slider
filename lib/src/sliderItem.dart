import 'package:flutter/widgets.dart';

// 幻灯片子项
class SliderItem {
  int index;

  // 子项组件
  final Widget child;

  // 子项背景组件
  final Widget backChild;

  // 子项触发
  final VoidCallback callback;

  SliderItem({this.child, this.backChild, this.callback});

}