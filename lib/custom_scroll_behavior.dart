import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 超滚动状态管理器
///
/// 使用静态 ValueNotifier 在不同组件间共享超滚动状态
class OverscrollStateManager {
  // 使用 Map 存储多个滚动视图的状态，key 为唯一标识
  static final Map<int, ValueNotifier<double>> _notifiers = {};

  /// 获取或创建指定 ID 的状态通知器
  static ValueNotifier<double> getNotifier(int id) {
    return _notifiers.putIfAbsent(id, () => ValueNotifier<double>(0.0));
  }

  /// 移除指定 ID 的状态通知器
  static void removeNotifier(int id) {
    _notifiers[id]?.dispose();
    _notifiers.remove(id);
  }

  /// 获取当前超滚动量
  static double getOverscrollAmount(int id) {
    return _notifiers[id]?.value ?? 0.0;
  }

  /// 设置超滚动量
  static void setOverscrollAmount(int id, double amount) {
    getNotifier(id).value = amount;
  }
}

/// 自定义滚动行为
///
/// 功能：
/// 1. 自定义滚动条样式：2单位宽，距离边缘1单位
/// 2. 超距离滑动时的缩放效果
class CustomMetroScrollBehavior extends ScrollBehavior {
  const CustomMetroScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return RawScrollbar(
      controller: details.controller,
      thumbColor: Colors.grey.withOpacity(0.5),
      thickness: 2.0,
      radius: const Radius.circular(0), // 矩形滚动条
      padding: const EdgeInsets.all(1.0), // 距离边缘1单位
      child: child,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // 使用自定义的超距离滑动指示器
    // 从 details.clipBehavior 获取滚动组件设置的裁切行为
    return CustomOverscrollIndicator(
      axisDirection: details.direction,
      clipBehavior: details.clipBehavior ?? Clip.hardEdge, // 使用滚动组件的 clipBehavior
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 使用自定义的滚动物理效果，使用默认 ID 0
    return const CustomDampingScrollPhysics(scrollViewId: 0);
  }
}

/// 自定义滚动物理效果
///
/// 当页面overScroll时，反向拉动不允许继续滚动
class CustomDampingScrollPhysics extends ClampingScrollPhysics {
  const CustomDampingScrollPhysics({super.parent, this.scrollViewId = 0});

  final int scrollViewId;

  @override
  CustomDampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomDampingScrollPhysics(
        parent: buildParent(ancestor), scrollViewId: scrollViewId);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // 获取 overscrollAmount
    final overscrollAmount =
        OverscrollStateManager.getOverscrollAmount(scrollViewId);

    // 如果处于超滚动状态
    if (overscrollAmount != 0.0) {
      // 判断是否是反向恢复滑动
      final isRecovering = (overscrollAmount > 0 && offset > 0) ||
          (overscrollAmount < 0 && offset < 0);

      if (isRecovering) {
        // 反向恢复时，阻止列表滚动
        return 0.0;
      }
    }

    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 自定义边界条件，减小阻尼让惯性滚动飞得更远
    
    // 检查是否超出边界
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      // 向上超滚动（顶部边界）
      // 减小阻尼：只吸收部分能量，让剩余的能量继续推动滚动
      return (value - position.pixels) * 0.3; // 0.3 = 只吸收 30% 的能量，70% 继续飞
    }
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) {
      // 向下超滚动（底部边界）
      return (value - position.pixels) * 0.3; // 0.3 = 只吸收 30% 的能量
    }
    
    // 其他情况使用默认行为
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // 使用默认的惯性滚动模拟
    // 这会让惯性滚动更自然
    return super.createBallisticSimulation(position, velocity);
  }
}

/// 自定义超距离滑动指示器
///
/// 当滑动超过内容边界时，以容器顶部向上320单位为原点进行纵向缩放
class CustomOverscrollIndicator extends StatefulWidget {
  const CustomOverscrollIndicator({
    super.key,
    required this.child,
    required this.axisDirection,
    this.clipBehavior = Clip.none, // 默认不裁切
  });

  final Widget child;
  final AxisDirection axisDirection;
  final Clip clipBehavior; // 裁切行为

  @override
  State<CustomOverscrollIndicator> createState() =>
      _CustomOverscrollIndicatorState();
}

class _CustomOverscrollIndicatorState extends State<CustomOverscrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _overscrollAmount = 0.0;
  bool _isDragging = false; // 跟踪拖动状态
  double _lastPointerPosition = 0.0; // 记录上一次指针位置
  final int _scrollViewId = 0; // 滚动视图 ID，用于状态管理
  Timer? _debugTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _controller.addListener(() {
      // 动画过程中，更新 overscroll 值
      if (!_isDragging) {
        setState(() {
          _overscrollAmount *= (1.0 - _controller.value);
          // 同步到状态管理器
          OverscrollStateManager.setOverscrollAmount(
              _scrollViewId, _overscrollAmount);
        });
      }
    });

    // // 每隔500毫秒打印一次
    // _debugTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
    //   print('Overscroll amount in state: $_overscrollAmount');
    // });
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    _controller.dispose();
    OverscrollStateManager.removeNotifier(_scrollViewId);
    super.dispose();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDragging && _overscrollAmount != 0.0) {
      // 计算指针移动的距离
      final delta = event.position.dy - _lastPointerPosition;
      _lastPointerPosition = event.position.dy;

      // 判断是否是反向滑动（恢复方向）
      final isRecovering = !((_overscrollAmount > 0 && delta < 0) ||
          (_overscrollAmount < 0 && delta > 0));
      if (isRecovering) {
        setState(() {
          if (_overscrollAmount < 0) {
            _overscrollAmount -= delta;
            if (_overscrollAmount - delta > 0) {
              _overscrollAmount = 0.0;
            }
          }
          if (_overscrollAmount > 0) {
            _overscrollAmount -= delta;
            if (_overscrollAmount - delta < 0) {
              _overscrollAmount = 0.0;
            }
          }

          OverscrollStateManager.setOverscrollAmount(
              _scrollViewId, _overscrollAmount);
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // 用户开始拖动
    if (notification is ScrollStartNotification) {
      _isDragging = true;
      // 如果有正在进行的回弹动画，立即停止
      if (_controller.isAnimating) {
        _controller.stop();
        setState(() {});
      }
    }
    // 超出滚动范围
    else if (notification is OverscrollNotification) {
      if (_isDragging) {
        setState(() {
          _overscrollAmount += notification.overscroll;
          // 同步到状态管理器
          OverscrollStateManager.setOverscrollAmount(
              _scrollViewId, _overscrollAmount);
        });
      }
    }
    // 用户停止滚动交互（手指抬起或触控板手势结束）
    else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _isDragging = false;
        // 如果有超滚动，开始回弹
        if (_overscrollAmount != 0.0) {
          _controller.forward(from: 0.0);
        }
      }
    }
    // 滚动动画结束（包括惯性滚动）
    else if (notification is ScrollEndNotification) {
      // 如果不是在拖动状态下结束（通常是惯性滚动结束）
      if (!_isDragging) {
        // 如果有超滚动，开始回弹
        if (_overscrollAmount != 0.0) {
          _controller.forward(from: 0.0);
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _handlePointerMove,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ClipRect(
          clipBehavior: widget.clipBehavior,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 计算缩放效果
              final scaleValue = _calculateScale();
              final alignment = _calculateAlignment(constraints);

              return Transform.scale(
                scaleY: scaleValue,
                alignment: alignment,
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }

  /// 计算缩放值
  ///
  /// 根据超距离滑动的距离计算缩放比例
  double _calculateScale() {
    // 缩放因子：超距离越大，缩放越明显
    // 使用非线性函数使效果更自然
    final scaleFactor = (_overscrollAmount.abs() / 1000).clamp(0.0, 0.3);

    // 向上滑动（overscroll为负）或向下滑动时都变扁
    return 1.0 - scaleFactor;
  }

  /// 计算变换的对齐点
  ///
  /// 向上滑动：以容器顶部向上320单位为原点
  /// 向下滑动：以容器底部向下320单位为原点
  Alignment _calculateAlignment(BoxConstraints constraints) {
    final height = constraints.maxHeight;

    if (height == 0 || height.isInfinite) {
      return Alignment.topCenter;
    }

    // 向下滑动（overscroll为正）
    if (_overscrollAmount > 0) {
      // 320单位向上 = 顶部 - 320
      // 将这个点转换为 Alignment 坐标系
      // Alignment.y: -1.0 是顶部, 1.0 是底部
      // y = -1.0 - (320 / (height / 2))
      final alignmentY = -1.0 - (320.0 / (height / 2));
      return Alignment(0.0, alignmentY);
    }
    // 向上滑动（overscroll为负）
    else if (_overscrollAmount < 0) {
      // 320单位向下 = 底部 + 320
      // y = 1.0 + (320 / (height / 2))
      final alignmentY = 1.0 + (320.0 / (height / 2));
      return Alignment(0.0, alignmentY);
    }
    // 没有超滚动
    else {
      return Alignment.center;
    }
  }
}
