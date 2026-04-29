import 'dart:async';

import 'package:flutter/material.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';

// ... 其他代码

class StartMenu extends StatefulWidget {
  const StartMenu({super.key});

  @override
  State<StartMenu> createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      //backgroundColor: Colors.blueGrey,
      stackPanel: const StackPanel(
        top: Text('FLUMETRO'),
        bottom: Text('about'),
      ),
      body: const MetroDraggableGrid(),
    );
  }
}

class GridItemData {
  String id;
  int x;
  int y;
  int width;
  int height;
  Color color;

  GridItemData({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  GridItemData clone() {
    return GridItemData(
      id: id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
    );
  }

  // 检查是否与另一个矩形发生重叠
  bool overlaps(GridItemData other) {
    if (this.id == other.id) return false;
    bool noOverlap = this.x >= other.x + other.width ||
        other.x >= this.x + this.width ||
        this.y >= other.y + other.height ||
        other.y >= this.y + this.height;
    return !noOverlap;
  }
}

class MetroDraggableGrid extends StatefulWidget {
  const MetroDraggableGrid({super.key});

  @override
  State<MetroDraggableGrid> createState() => _MetroDraggableGridState();
}

class _MetroDraggableGridState extends State<MetroDraggableGrid> {
  final int columns = 6;
  final double cellSize = 60.0;

  List<GridItemData> items = [
    GridItemData(id: '1', x: 0, y: 0, width: 1, height: 1, color: Colors.red),
    GridItemData(
        id: '2', x: 1, y: 0, width: 2, height: 2, color: Colors.yellow),
    GridItemData(id: '3', x: 3, y: 0, width: 4, height: 2, color: Colors.green),
  ];

  List<GridItemData>? originalItems;
  Timer? hoverTimer;
  String? activeDragId;
  int lastHoverX = -1;
  int lastHoverY = -1;

  @override
  void dispose() {
    hoverTimer?.cancel();
    super.dispose();
  }

  void _onDragStarted(String id) {
    debugPrint('0');
    activeDragId = id;
    originalItems = items.map((e) => e.clone()).toList(); // 保存布局A
  }

  void _onDragEnd() {
    debugPrint('2');
    activeDragId = null;
    originalItems = null; // 接受布局B的最终状态
    hoverTimer?.cancel();
    lastHoverX = -1;
    lastHoverY = -1;
  }

  void _onDragCanceled() {
    debugPrint('Drag canceled, reverting to original layout');
    if (originalItems != null) {
      debugPrint('1');
      setState(() {
        items = originalItems!;
      });
    }
    _onDragEnd();
  }

  void _updatePreview(int targetX, int targetY) {
    if (originalItems == null || activeDragId == null) return;

    // 从布局A重新计算布局C/B
    List<GridItemData> newPreview =
        originalItems!.map((e) => e.clone()).toList();
    GridItemData targetItem =
        newPreview.firstWhere((e) => e.id == activeDragId);

    targetItem.x = targetX;
    targetItem.y = targetY;

    debugPrint(
        'Preview update: targetItem ${targetItem.id} to ($targetX, $targetY)');

    // 解决重叠：将下方组件向下推
    bool hasOverlap = true;
    while (hasOverlap) {
      hasOverlap = false;

      // 1. targetItem把其他交叠的往下推
      for (var i in newPreview) {
        if (i.id != targetItem.id && i.overlaps(targetItem)) {
          i.y = targetItem.y + targetItem.height;
          hasOverlap = true;
        }
      }

      // 2. 其他组件相互之间如果由于下推产生了重叠，继续下推
      for (var i in newPreview) {
        for (var j in newPreview) {
          if (i.id != targetItem.id &&
              j.id != targetItem.id &&
              i.id != j.id &&
              i.overlaps(j)) {
            // y值更大的被推下去
            GridItemData lower = (i.y < j.y)
                ? j
                : ((i.y > j.y) ? i : (i.id.compareTo(j.id) < 0 ? j : i));
            lower.y += 1;
            hasOverlap = true;
          }
        }
      }
    }

    setState(() {
      items = newPreview;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final actualCellSize = constraints.maxWidth / columns;

      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        color: Colors.transparent,
        child: Stack(
          children: [
            // 放置区域接收器
            Positioned.fill(
              child: DragTarget<GridItemData>(
                hitTestBehavior: HitTestBehavior.opaque,
                builder: (context, candidateData, rejectedData) {
                  return Container(color: Colors.transparent);
                },
                onMove: (details) {
                  if (activeDragId == null) return;

                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localOffset = box.globalToLocal(details.offset);

                  int newX = (localOffset.dx / actualCellSize).round();
                  int newY = (localOffset.dy / actualCellSize).round();
                  // 获取当前拖拽物体宽度以做边界限制
                  final draggingItem =
                      items.firstWhere((e) => e.id == activeDragId);

                  if (newX < 0) newX = 0;
                  if (newX + draggingItem.width > columns)
                    newX = columns - draggingItem.width;
                  if (newY < 0) newY = 0;

                  // 位置发生变化，重新计时
                  if (newX != lastHoverX || newY != lastHoverY) {
                    lastHoverX = newX;
                    lastHoverY = newY;

                    hoverTimer?.cancel();

                    // 如果需要立即返回布局A，可以在这里setState(items = originalItems)
                    // 但通常保留当前预览会更顺滑，直接等待100ms重新计算新C即可

                    hoverTimer = Timer(const Duration(milliseconds: 100), () {
                      _updatePreview(newX, newY);
                    });
                  }
                },
                onAcceptWithDetails: (details) {
                  if (activeDragId != null) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final Offset localOffset =
                        box.globalToLocal(details.offset);

                    int newX = (localOffset.dx / actualCellSize).round();
                    int newY = (localOffset.dy / actualCellSize).round();

                    debugPrint(
                        'Drag accepted at local offset: $localOffset, grid pos: ($newX, $newY)');

                    final draggingItem =
                        items.firstWhere((e) => e.id == activeDragId);

                    if (newX < 0) newX = 0;
                    if (newX + draggingItem.width > columns)
                      newX = columns - draggingItem.width;
                    if (newY < 0) newY = 0;

                    // 放下时立刻做最后一次确认计算
                    _updatePreview(newX, newY);
                  }
                  _onDragEnd();
                },
                onLeave: (data) {
                  // 离开当前区域时不应直接取消，不然会打断拖拽手势
                },
              ),
            ),
            // 网格物体
            IgnorePointer(
              // 关键点：只要 activeDragId 不为空，表示正在拖拽
              // 此时这层楼所有的格子（包括占位符）对“手指”来说都是透明的
              ignoring: activeDragId != null,
              child: Stack(
                children: [
                  ...items.map((item) {
                    // 使用AnimatedPositioned代替Positioned实现平移动画
                    return AnimatedPositioned(
                      key:
                          ValueKey(item.id), // 【修复】增加 Key，防止跨格重绘时组件复用错乱导致拖拽意外中止
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      left: item.x * actualCellSize,
                      top: item.y * actualCellSize,
                      width: item.width * actualCellSize,
                      height: item.height * actualCellSize,
                      child: Draggable<GridItemData>(
                          data: item,
                          onDragStarted: () => _onDragStarted(item.id),
                          onDraggableCanceled: (_, __) => _onDragCanceled(),
                          // 【修复】在被拖走后的真实坑位显示一个半透明虚拟物体占位符
                          childWhenDragging: 
                          const SizedBox.shrink(),
                          // Container(
                          //   margin: const EdgeInsets.all(2),
                          //   decoration: BoxDecoration(
                          //     color: item.color.withOpacity(0.3),
                          //     border: Border.all(
                          //         color: item.color,
                          //         width: 2,
                          //         style: BorderStyle.solid),
                          //   ),
                          // ),
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: item.width * actualCellSize,
                              height: item.height * actualCellSize,
                              color: item.color.withOpacity(0.8),
                              child: Center(
                                  child: Text(item.id,
                                      style: const TextStyle(
                                          color: Colors.black))),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            color: item.color,
                            child: Center(
                                child: Text(item.id,
                                    style:
                                        const TextStyle(color: Colors.black))),
                          ),
                        ),
                      
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
