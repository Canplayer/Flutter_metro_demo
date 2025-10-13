import 'package:flutter/material.dart';

/// 围绕屏幕左侧轴旋转的动画组件
/// 
/// 这个组件会自动计算子组件相对于屏幕左侧的位置，
/// 并围绕屏幕最左侧的虚拟轴进行 Y 轴旋转动画
class LeftEdgeRotateAnimation extends StatefulWidget {
  /// 要应用动画的子组件
  final Widget child;
  
  /// 旋转角度（弧度制）
  /// 0 表示不旋转，π/2 表示旋转90度
  final double rotation;
  
  const LeftEdgeRotateAnimation({
    super.key,
    required this.child,
    required this.rotation,
  });

  @override
  State<LeftEdgeRotateAnimation> createState() => _LeftEdgeRotateAnimationState();
}

class _LeftEdgeRotateAnimationState extends State<LeftEdgeRotateAnimation> {
  final GlobalKey _childKey = GlobalKey();
  double _edgeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // 在首帧渲染后计算位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateEdgeOffset();
    });
  }

  @override
  void didUpdateWidget(LeftEdgeRotateAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当旋转角度更新时，重新计算偏移量
    if (widget.rotation != oldWidget.rotation) {
      _calculateEdgeOffset();
    }
  }

  /// 计算组件相对于屏幕左侧的偏移量
  void _calculateEdgeOffset() {
    if (_childKey.currentContext == null) return;
    
    final RenderBox? renderBox = 
        _childKey.currentContext!.findRenderObject() as RenderBox?;
    
    if (renderBox == null) return;
    
    // 获取组件在屏幕中的绝对位置
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // 计算组件中心点相对于屏幕左侧的距离
    // 这里使用中心点，所以加上宽度的一半
    setState(() {
      _edgeOffset = position.dx + size.width / 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      // 变换原点：相对于组件中心，偏移到屏幕左侧
      // 负值表示向左偏移
      origin: Offset(-_edgeOffset, 0),
      // Y 轴旋转变换
      transform: Matrix4.identity()..rotateY(widget.rotation),
      child: Container(
        key: _childKey,
        child: widget.child,
      ),
    );
  }
}
