import 'package:flutter/material.dart';
import 'sliderItem.dart';
import 'flutterSliderController.dart';
import 'dart:async';

enum FlutterSliderStyle {
  def, // 按下焦点图会缩放
  n1, // 样式同上 左右切换同步放大缩小
  n2, // 切换同行，排版居左
  n3,
}
typedef  DragUpdateCallback = void Function(double offset, double r);
typedef  UpdateIndexCallback = void Function(int index);

class FlutterSlider extends StatefulWidget {
  // 子项列表
  final List<SliderItem> children;
  // 非焦点缩放比例 或者 缩放递减
  final double scale;
  // 子项宽度
  final double itemWidth;
  // 子项初始偏移 风格3适用
  final double initLeftOffset;
  // 容器宽度
  final double width;
  // 风格
  final FlutterSliderStyle style;
  // 是否开启自动播放
  final bool autoPlay;
  // 自动播放间隔
  final Duration duration;

  // 各种回调
  final VoidCallback onDragDown;
  final DragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final UpdateIndexCallback onUpdateIndex;

  final FlutterSliderController sliderController;

  FlutterSlider({
    Key key, 
    this.children,
    this.width,
    this.itemWidth,
    this.scale = 0.8, 
    this.style = FlutterSliderStyle.def,
    this.initLeftOffset = 0.0,
    this.onDragDown,
    this.onDragUpdate,
    this.onDragEnd,
    this.onUpdateIndex,
    this.sliderController,
    this.autoPlay = true,
    this.duration,
  })
      : super(key: key) {
    assert(this.children.length >= 2, "子项建议大于2个");
    for(int i = 0; i < this.children.length; i ++) {
      this.children[i].index = i;
    }
  }

  @override
  _FluterSliderState createState() => _FluterSliderState();
}

class _FluterSliderState extends State<FlutterSlider>
    with TickerProviderStateMixin {
  int activeIndex = 0;
  int nextIndex = 0;
  double _primaryDelta = 0.0; // 滑动距离
  int _direc = 1; // 滑动方向 -1/1

  AnimationController animationController;
  Animation<double> progress;

  AnimationController animationScalController;
  Animation<double> scalProgress;

  bool isAnimation = false;
  AnimationStatus animaStatus;
  double animEnd;
  String direction; // prev / next
  FlutterSliderController _sliderController;
  AnimationController _moveController;

  // 定时器
  Timer timer;
  Duration _duration;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _duration = widget.duration;
    if(_duration == null) {
      _duration = Duration(seconds: 5);
    }

    // 监听用户主动操作
    _sliderController = widget.sliderController;
    if(_sliderController == null){
      _sliderController = FlutterSliderController();
    }
    _sliderController.addListener(_actionOnListener);

    // 创建左右滑动动画
    animationController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);

    switch(widget.style){
      case FlutterSliderStyle.def:
      case FlutterSliderStyle.n1:
      case FlutterSliderStyle.n3:
        animEnd = widget.itemWidth;
        break;
      case FlutterSliderStyle.n2:
        animEnd = widget.width;
        break;
    }

    progress =
        Tween(begin: 0.0, end: animEnd).animate(animationController)
          ..addListener(() {
            setState(() {});
            if(widget.onDragDown != null) {
              widget.onDragUpdate(progress.value * _direc, animationController.value);
            }
          })
          ..addStatusListener((AnimationStatus status) {
            setState(() {
              animaStatus = status;
              if (status == AnimationStatus.forward ||
                  status == AnimationStatus.reverse) {
                isAnimation = true;
              } else {
                isAnimation = false;
                activeIndex = nextActiveIndex(progress.value);
                animationScalController.reverse();
              }
            });
          });
    // 创建按下缩小动画
    animationScalController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    scalProgress = Tween(begin: 1.0, end: widget.scale)
        .animate(animationScalController)
          ..addListener(() {
            setState(() {});
          });
  }

  @override
  void didChangeDependencies(){
    _startPlay();
    super.didChangeDependencies();
  }


  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void dispose(){
    _stopPlay();
    animationController.dispose();
    animationScalController.dispose();
    if(_moveController != null) {
      _moveController.dispose();
    }
    super.dispose();
  }

  int _prevIndex() {
    int pre = activeIndex - 1;
    return pre < 0 ? widget.children.length - 1 : pre;
  }

  int _nextIndex() {
    int next = activeIndex + 1;
    return next < widget.children.length ? next : 0;
  }

  void _move(int toindex, {bool animation}) {
    if(_moveController != null) {
      return ;
    }
    _stopPlay();
    double startX = 0.0;
    double endX = 0.0;
    switch(widget.style) {
      case FlutterSliderStyle.def:
      case FlutterSliderStyle.n1:
      case FlutterSliderStyle.n3:
        if(activeIndex == widget.children.length - 1 && toindex ==0) {
          endX = -widget.itemWidth;
        }else if(activeIndex == 0 && toindex == widget.children.length - 1){
          endX = widget.itemWidth;
        }else{
          endX = (activeIndex - toindex) * widget.itemWidth;
        }
      break;
      case FlutterSliderStyle.n2:
        endX = - widget.width;
      break;
    }

    if(widget.onDragDown != null) {
      widget.onDragDown();
    }
    
    animationScalController.forward();
    _moveController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    Animation<double> _a;
    _a = Tween(begin: startX, end: endX).animate(_moveController)
      ..addListener((){
        setState(() {
          if(_primaryDelta < 0) {
            _direc = -1;
            direction = "next";
          }else{
            _direc = 1;
            direction = "prev";
          }
          if(widget.onDragUpdate != null) {
              widget.onDragUpdate(_a.value, _moveController.value);
          }
          _primaryDelta = _a.value;
        });
      })
      ..addStatusListener((AnimationStatus status){
        if(status == AnimationStatus.completed) {
          setState(() {
            _primaryDelta = 0.0;
            activeIndex = toindex;
            if(widget.onDragEnd != null) {
              widget.onDragEnd();
            }
            if(widget.onUpdateIndex != null) {
                widget.onUpdateIndex(activeIndex);
            }
            animationScalController.reverse();
            _moveController.dispose();
            _moveController = null;
            _startPlay();
          });
        }
      });
      _moveController.forward();
    
  }

  void _startPlay(){
    if(widget.autoPlay == false) {
      return ;
    }
    if(timer != null) {
      timer.cancel();
    }
    timer = Timer.periodic(_duration, (Timer t){
      _move(_nextIndex(), animation: true);
    });
  }

  void _stopPlay(){
    if(widget.autoPlay && timer != null) {
      timer.cancel();
    }
  }

  void _actionOnListener() {
    switch (_sliderController.event) {
      case FlutterSliderEvent.PREV_INDEX:
        if(widget.style == FlutterSliderStyle.n2) {
          throw new Exception(
            "风格2只能使用下一页功能!");
        }else{
          _move(_prevIndex(), animation: _sliderController.animation);
        }
      break;
      case FlutterSliderEvent.NEXT_INDEX:
        _move(_nextIndex(), animation: _sliderController.animation);
      break;
      case FlutterSliderEvent.MOVE_INDEX:
        if(widget.style == FlutterSliderStyle.n2) {
          throw new Exception(
            "风格2只能使用下一页功能!");
        }else{
          _move(_sliderController.index, animation: _sliderController.animation);
        }
      break;
      case FlutterSliderEvent.START_AUTOPLAY:
        _startPlay();
      break;
      case FlutterSliderEvent.STOP_AUTOPLAY:
        _stopPlay();
      break;
    }
  }


  int nextActiveIndex(double primary) {
    double _primary = primary.abs();
    int index = activeIndex;
    if (direction == "prev" && _primary / widget.itemWidth > 0.33333333) {
      index = activeIndex - 1;
    } else if (direction == "next" &&
        _primary / widget.itemWidth > 0.33333333) {
      index = activeIndex + 1;
    }
    int nextIndex = index > widget.children.length - 1
        ? 0
        : index < 0 ? widget.children.length - 1 : index;
    if(nextIndex != activeIndex && widget.onUpdateIndex != null) {
      widget.onUpdateIndex(nextIndex);
    }
    return nextIndex;
  }


  void onHorizontalDragDown(DragDownDetails details) {
    animationScalController.forward();
    _stopPlay();
    if(widget.onDragDown != null) {
      widget.onDragDown();
    }
  }

  void onHorizontalDragStart(DragStartDetails details) {
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      double _f = _primaryDelta + details.primaryDelta;
      _direc = _f > 0 ? 1 : -1;
      _primaryDelta = _f.abs() > widget.itemWidth ? details.primaryDelta > 0 ? widget.itemWidth : -widget.itemWidth : _f;
      switch(widget.style){
        case FlutterSliderStyle.def:
        case FlutterSliderStyle.n1:
        case FlutterSliderStyle.n3:
          if (_primaryDelta > 0) {
            direction = "prev";
          } else if (_primaryDelta < 0) {
            direction = "next";
          }
        break;
        case FlutterSliderStyle.n2:
          direction = "next";
          break;
        default:
          direction = "next";
          break;
      }
    });
    if(widget.onDragUpdate != null) {
      widget.onDragUpdate(_primaryDelta, _primaryDelta / animEnd);
    }
  }

  void onHorizontalDragCancel() {
    animationScalController.reverse();
    _startPlay(); // 手动结束自动播放
    if(widget.onDragEnd != null) {
      widget.onDragEnd();
    }
  }

  void onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      double offset = _primaryDelta;
      nextIndex = nextActiveIndex(offset);
      double r = offset.abs() / animEnd;
      if (r == 1.0 || r == 0.0) {
        activeIndex = nextIndex;
        animationScalController.reverse();
        _primaryDelta = 0.0;
        return ;
      }
      if (nextIndex == activeIndex) {
        animationController.reverse(
            from: offset.abs() / animEnd);
      } else {
        animationController.forward(
            from: offset.abs() / animEnd);
      }
      _primaryDelta = 0.0;
    });
    _startPlay(); // 手动结束自动播放
    if(widget.onDragEnd != null) {
      widget.onDragEnd();
    }
  }

  double getScale(int index) {
    switch(widget.style) {
      case FlutterSliderStyle.def:
        return index == activeIndex ? scalProgress.value : widget.scale;
        break;
      case FlutterSliderStyle.n1:
      case FlutterSliderStyle.n3:
        double offset = isAnimation ? progress.value : _primaryDelta;

        double r = offset.abs() / (widget.itemWidth);
        if (direction == "next") {
          if (activeIndex + 1 == index) {
            double s = r * (1 - widget.scale) + widget.scale;
            return s > 1.0 ? 1.0 : s;
          }
        } else if (direction == "prev") {
          if (activeIndex - 1 == index) {
            double s = r * (1 - widget.scale) + widget.scale;
            return s > 1.0 ? 1.0 : s;
          }
        }
        if (activeIndex == index) {
          double s = 1.0 - r * (1 - widget.scale);
          return s < widget.scale ? widget.scale : s;
        }

        if (index == activeIndex) {
          return 1.0;
        } else {
          return widget.scale;
        }
        break;
      case FlutterSliderStyle.n2:
        double offset = isAnimation ? progress.value : _primaryDelta;
        double r = offset.abs() / (widget.width);
        if (index == activeIndex){
          return 1.0;
        }
        return 1 - (activeIndex - index).abs() * widget.scale + r * widget.scale;
      default:
        return 1.0;
    }

  }

  double getOffset() {
    switch(widget.style){
      case FlutterSliderStyle.def:
      case FlutterSliderStyle.n1:
      case FlutterSliderStyle.n3:
        return isAnimation
                ?  progress.value * _direc
                : _primaryDelta;
        break;
      case FlutterSliderStyle.n2:
        return isAnimation
                ?  progress.value * _direc
                : _primaryDelta;
        break;
      default:
        return isAnimation
                ?  progress.value * _direc
                : _primaryDelta;
        break;
    }
  }

  double getOpacity(int index) {
    switch(widget.style){
      case FlutterSliderStyle.n2:
        double offset = isAnimation ? progress.value : _primaryDelta;
        double r = offset.abs() / (widget.width);
        if(activeIndex == index){
          return 1.0;
        }
        if (activeIndex - index <= 2) {
          return 1.0 - (activeIndex - index) * 0.25 + 0.25 * r;
        }else if(activeIndex - index == 3){
          return 0.0 + 0.5 * r;
        }else{
          return 0.0;
        }
        break;
      default:
        return 1.0;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.length == 0) {
      return null;
    }
    List<Widget> children = List<Widget>();
    List<SliderItem> newChildren = widget.children.toList();
    switch(widget.style){
      case FlutterSliderStyle.def:
      case FlutterSliderStyle.n1:
      case FlutterSliderStyle.n3:
        if (widget.children.length == 1) {
          newChildren.add(widget.children[0]);
          newChildren.add(widget.children[0]);
          newChildren.add(widget.children[0]);
          newChildren.add(widget.children[0]);
        } else {
          List<SliderItem> startLists = new List<SliderItem>();
          startLists.add(widget.children[widget.children.length - 2]);
          startLists.add(widget.children[widget.children.length - 1]);
          List<SliderItem> endLists = widget.children.sublist(0, 2);
          newChildren.insertAll(0, startLists);
          newChildren.addAll(endLists);
        };
        for (int i = -2; i < widget.children.length + 2; i++) {
          children.add(LayoutId(
              id: "slideritem$i",
              child: Transform.scale(
                scale: getScale(i),
                child: newChildren[i + 2].child,
              )
            )
          );
        }
        break;
      case FlutterSliderStyle.n2:
        List<SliderItem> newChildren = widget.children.reversed.toList();
        newChildren.insertAll(0, widget.children.sublist(0, activeIndex).reversed.toList());
        for (int i = -widget.children.length+1+activeIndex; i <= activeIndex; i++) {
          children.add(LayoutId(
              id: "slideritem$i",
              child: Opacity(
                opacity: getOpacity(i),
                child: Transform.scale(
                  scale: getScale(i),
                  child: newChildren[i + widget.children.length-1-activeIndex].child,
                ),
              )
            )
          );
        }
        break;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return GestureDetector(
        onHorizontalDragDown: onHorizontalDragDown,
        onHorizontalDragStart: onHorizontalDragStart,
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragCancel: onHorizontalDragCancel,
        onHorizontalDragEnd: onHorizontalDragEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(width: widget.width),
          child: CustomMultiChildLayout(
            delegate: new _SliderMultiChildLayout(
              count: widget.children.length,
              activeIndex: activeIndex,
              nextIndex: nextIndex,
              offset: getOffset(),
              thumb: widget.style,
              itemWidth: widget.itemWidth,
              isAnimation: isAnimation,
              scale: widget.scale,
              initLeftOffset: widget.initLeftOffset,
            ),
            children: children,
          ),
        ),
      );
    });
  }
}

class _SliderMultiChildLayout extends MultiChildLayoutDelegate {
  final int activeIndex;
  final int nextIndex;

  final int count;
  final double itemWidth;
  final double offset;
  final FlutterSliderStyle thumb;
  final bool isAnimation;
  final double scale;
  // 子项初始偏移 风格3适用
  final double initLeftOffset;

  _SliderMultiChildLayout(
      {this.activeIndex, this.count, this.offset, this.nextIndex,this.itemWidth, this.thumb, this.isAnimation, this.scale = 1.0, this.initLeftOffset = 12.0});

  @override
  void performLayout(Size size) {
    switch (thumb) {
      case FlutterSliderStyle.def:
      case FlutterSliderStyle.n1:
        double startX = ((activeIndex + 2) * itemWidth).abs() * -1 + (size.width - itemWidth) / 2;
        for (int i = -2; i < count + 2; i++) {
          layoutChild("slideritem$i",
                  BoxConstraints(maxWidth: size.width, maxHeight: size.height));
//      print(this.offset);
          positionChild("slideritem$i",
                  Offset(startX + (offset > itemWidth ? itemWidth : offset), 0.0));
          startX += itemWidth;
        }
        break;
      case FlutterSliderStyle.n2:
        double startX = (size.width - itemWidth) / 2;
        positionChild("slideritem$activeIndex", Offset(startX + offset, 0.0));
        for (int i = -count+1+activeIndex; i <= activeIndex; i++) {
          layoutChild("slideritem$i",
                  BoxConstraints(maxWidth: size.width, maxHeight: size.height));
          if(activeIndex != i) {
            double j = scale * itemWidth * 0.75;
            double f = (activeIndex - i) * j;
            positionChild("slideritem$i", Offset(startX, f + j * (offset.abs() * -1 / size.width)));
          }
        }
        break;
      case FlutterSliderStyle.n3:
        double startX = ((activeIndex + 2) * itemWidth).abs() * -1 + initLeftOffset;
        for (int i = -2; i < count + 2; i++) {
          layoutChild("slideritem$i",
                  BoxConstraints(maxWidth: size.width, maxHeight: size.height));
//      print(this.offset);
          positionChild("slideritem$i",
                  Offset(startX + (offset > itemWidth ? itemWidth : offset), 0.0));
          startX += itemWidth;
        }
        break;
    }

  }

  @override
  bool shouldRelayout(_SliderMultiChildLayout oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.count != count ||
        oldDelegate.offset != offset ||
            oldDelegate.itemWidth != itemWidth ||
            oldDelegate.isAnimation != isAnimation ||
            oldDelegate.nextIndex != nextIndex || oldDelegate.scale != scale || oldDelegate.initLeftOffset != initLeftOffset;
  }
}
