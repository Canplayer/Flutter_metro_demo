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
    GridItemData(
        id: '1', x: 0, y: 0, width: 2, height: 2, color: Colors.yellow),
    GridItemData(
        id: '2', x: 2, y: 0, width: 1, height: 1, color: Colors.yellow),
        GridItemData(
        id: '3', x: 3, y: 0, width: 1, height: 1, color: Colors.yellow),
            GridItemData(
        id: '4', x: 2, y: 1, width: 1, height: 1, color: Colors.yellow),
        GridItemData(
        id: '5', x: 3, y: 1, width: 1, height: 1, color: Colors.yellow),
        GridItemData(
        id: '6', x: 0, y: 2, width: 4, height: 2, color: Colors.yellow),
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

    List<GridItemData> nextLayout = originalItems!.map((e) => e.clone()).toList();
    GridItemData targetItem = nextLayout.firstWhere((e) => e.id == activeDragId);
    targetItem.x = targetX;
    targetItem.y = targetY;

    // 1. 找出直接与拖拽物重叠的物体
    List<GridItemData> directCollisions = nextLayout
        .where((item) => item.id != targetItem.id && item.overlaps(targetItem))
        .toList();

    if (directCollisions.isNotEmpty) {
      bool moved = false;

      // 定义尝试的方向：上、左、右、下
      final directions = [const Offset(0, -1), const Offset(-1, 0), const Offset(1, 0), const Offset(0, 1)];

      for (var dir in directions) {
        // 计算该方向下，组需要移动到的“目标偏移量”
        // 比如左移，偏移量 = (拖拽物左边界 - 组右边界)
        int offsetX = 0;
        int offsetY = 0;

        if (dir.dx < 0) { // 向左
          int groupRight = directCollisions.map((e) => e.x + e.width).reduce((a, b) => a > b ? a : b);
          offsetX = targetItem.x - groupRight;
        } else if (dir.dx > 0) { // 向右
          int groupLeft = directCollisions.map((e) => e.x).reduce((a, b) => a < b ? a : b);
          offsetX = (targetItem.x + targetItem.width) - groupLeft;
        } else if (dir.dy < 0) { // 向上
          int groupBottom = directCollisions.map((e) => e.y + e.height).reduce((a, b) => a > b ? a : b);
          offsetY = targetItem.y - groupBottom;
        } else if (dir.dy > 0) { // 向下
          int groupTop = directCollisions.map((e) => e.y).reduce((a, b) => a < b ? a : b);
          offsetY = (targetItem.y + targetItem.height) - groupTop;
        }

        // 获取递归后的完整碰撞组
        List<GridItemData> fullGroup = _findRecursiveGroup(nextLayout, directCollisions, targetItem, offsetX, offsetY);

        if (_canMoveFullGroup(nextLayout, fullGroup, targetItem, offsetX, offsetY)) {
          for (var item in fullGroup) {
            item.x += offsetX;
            item.y += offsetY;
          }
          moved = true;
          break;
        }
      }

      // 2. 保底方案：整体向下平移（插入行）
      if (!moved) {
        int minYOfImpacted = directCollisions.fold(targetItem.y, (prev, e) => e.y < prev ? e.y : prev);
        for (var item in nextLayout) {
          if (item.id != targetItem.id && item.y >= minYOfImpacted) {
            item.y += targetItem.height;
          }
        }
      }
    }

    // 3. 最终碰撞清理 & 消除空行
    //_resolveCascadingOverlaps(nextLayout, targetItem);
    _compactLayout(nextLayout);

    setState(() {
      items = nextLayout;
    });
  }

  // 递归寻找所有受影响的物体
  List<GridItemData> _findRecursiveGroup(List<GridItemData> allItems, List<GridItemData> currentGroup, GridItemData draggingItem, int dx, int dy) {
    List<GridItemData> totalGroup = List.from(currentGroup);
    bool added;
    do {
      added = false;
      List<GridItemData> toAdd = [];
      for (var member in totalGroup) {
        // 模拟成员移动后的位置
        GridItemData ghost = member.clone();
        ghost.x += dx;
        ghost.y += dy;

        for (var other in allItems) {
          if (other.id == draggingItem.id || totalGroup.any((m) => m.id == other.id)) continue;
          if (ghost.overlaps(other)) {
            toAdd.add(other);
            added = true;
          }
        }
      }
      totalGroup.addAll(toAdd);
    } while (added);
    return totalGroup;
  }

  // 检查整个递归后的组是否可以移动到新位置
  bool _canMoveFullGroup(List<GridItemData> allItems, List<GridItemData> group, GridItemData draggingItem, int dx, int dy) {
    for (var item in group) {
      int nx = item.x + dx;
      int ny = item.y + dy;
      
      // 边界检查
      if (nx < 0 || nx + item.width > columns || ny < 0) return false;

      GridItemData ghost = item.clone();
      ghost.x = nx; ghost.y = ny;

      // 不能与拖拽物重叠
      if (ghost.overlaps(draggingItem)) return false;

      // 理论上递归组不会与其他静态物体重叠，因为重叠的都被拉进组了
      // 但如果撞到了无法移动的边界或逻辑错误，这里做最终把关
    }
    return true;
  }


  /// 消除空行逻辑
  void _compactLayout(List<GridItemData> allItems) {
    // 找到当前布局的最大高度
    int maxY = allItems.fold(
        0, (max, e) => e.y + e.height > max ? e.y + e.height : max);

    // 从第一行开始向下检查
    for (int y = 0; y < maxY; y++) {
      // 检查当前行 y 是否有任何磁贴占用
      // 磁贴占用行的条件是：y >= item.y && y < (item.y + item.height)
      bool isRowOccupied =
          allItems.any((item) => y >= item.y && y < item.y + item.height);

      if (!isRowOccupied) {
        // 如果这一行是空的，检查上方是否还有磁贴（防止把最顶部的空行也算进去，虽然 y 从 0 开始不会有此问题）
        // 且下方必须有磁贴才需要“坍缩”
        bool hasItemsBelow = allItems.any((item) => item.y > y);

        if (hasItemsBelow) {
          // 将所有在空行下方的磁贴向上移动 1 格
          for (var item in allItems) {
            if (item.y > y) {
              item.y -= 1;
            }
          }
          // 因为移动了，所以当前行号 y 需要重新检查一次，同时最大高度也减小了
          y--;
          maxY--;
        }
      }
    }
  }

  // 辅助函数：处理连锁重叠（始终向下推）
  void _resolveCascadingOverlaps(
      List<GridItemData> allItems, GridItemData targetItem) {
    bool hasOverlap = true;
    int safetyCounter = 0; // 防止无限循环
    while (hasOverlap && safetyCounter < 50) {
      hasOverlap = false;
      safetyCounter++;
      for (var i in allItems) {
        for (var j in allItems) {
          if (i.id != j.id && i.overlaps(j)) {
            // 永远让非拖拽物或者是更靠下的物体往下走
            GridItemData topper = (i.id == targetItem.id)
                ? i
                : (j.id == targetItem.id ? j : (i.y <= j.y ? i : j));
            GridItemData lower = (topper == i) ? j : i;

            lower.y = topper.y + topper.height;
            hasOverlap = true;
          }
        }
      }
    }
  }

  // 检测组是否可以移动（保持原样）
  bool _canMoveGroupTogether(List<GridItemData> allItems,
      List<GridItemData> group, GridItemData draggingItem, Offset dir) {
    for (var item in group) {
      int newX = item.x + dir.dx.toInt();
      int newY = item.y + dir.dy.toInt();
      if (newX < 0 || newX + item.width > columns || newY < 0) return false;

      GridItemData ghost = item.clone();
      ghost.x = newX;
      ghost.y = newY;

      if (ghost.overlaps(draggingItem)) return false;

      for (var other in allItems) {
        if (other.id == draggingItem.id) continue;
        if (!group.any((g) => g.id == other.id) && ghost.overlaps(other)) {
          return false;
        }
      }
    }
    return true;
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
                        childWhenDragging: const SizedBox.shrink(),
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
                                    style:
                                        const TextStyle(color: Colors.black))),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          color: item.color,
                          child: Center(
                              child: Text(item.id,
                                  style: const TextStyle(color: Colors.black))),
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
