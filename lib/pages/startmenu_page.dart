import 'dart:async';

import 'package:flutter/material.dart';
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
    return const MetroPageScaffold(
      //backgroundColor: Colors.blueGrey,
      stackPanel: StackPanel(
        top: Text('FLUMETRO'),
        bottom: Text('about'),
      ),
      body: MetroDraggableGrid(),
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
    GridItemData(
        id: '7', x: 0, y: 4, width: 2, height: 2, color: Colors.yellow),
    GridItemData(
        id: '8', x: 2, y: 4, width: 2, height: 2, color: Colors.yellow),
  ];

  List<GridItemData>? originalItems;
  Timer? hoverTimer;
  String? activeDragId;
  int lastHoverX = -1;
  int lastHoverY = -1;

  // --- 新增：记录抓取点相对磁贴左上角的偏移 ---
  Offset dragGrabOffset = Offset.zero;

  @override
  void dispose() {
    hoverTimer?.cancel();
    super.dispose();
  }

  void _onDragStarted(String id) {
    activeDragId = id;
    originalItems = items.map((e) => e.clone()).toList(); // 保存布局A
  }

  void _onDragEnd() {
    activeDragId = null;
    originalItems = null; // 接受布局B的最终状态
    hoverTimer?.cancel();
    lastHoverX = -1;
    lastHoverY = -1;
  }

  void _onDragCanceled() {
    if (originalItems != null) {
      setState(() {
        items = originalItems!;
      });
    }
    _onDragEnd();
  }

  void _updatePreview(int targetX, int targetY) {
    if (originalItems == null || activeDragId == null) return;

    List<GridItemData> nextLayout =
        originalItems!.map((e) => e.clone()).toList();
    GridItemData targetItem =
        nextLayout.firstWhere((e) => e.id == activeDragId);
    targetItem.x = targetX;
    targetItem.y = targetY;

    // 1. 找出直接与拖拽物重叠的物体
    List<GridItemData> directCollisions = nextLayout
        .where((item) => item.id != targetItem.id && item.overlaps(targetItem))
        .toList();

    if (directCollisions.isNotEmpty) {
      bool moved = false;
      bool canBreakCeiling = false;
      int ceilingOffsetX = 0;
      int ceilingOffsetY = 0;

      // --- 新增：提取碰撞组的整体边界与中心点 ---
      int groupLeft =
          directCollisions.map((e) => e.x).reduce((a, b) => a < b ? a : b);
      int groupRight = directCollisions
          .map((e) => e.x + e.width)
          .reduce((a, b) => a > b ? a : b);
      int groupTop =
          directCollisions.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      int groupBottom = directCollisions
          .map((e) => e.y + e.height)
          .reduce((a, b) => a > b ? a : b);

      double groupCenterX = groupLeft + (groupRight - groupLeft) / 2.0;
      double groupCenterY = groupTop + (groupBottom - groupTop) / 2.0;

      double targetCenterX = targetItem.x + targetItem.width / 2.0;
      double targetCenterY = targetItem.y + targetItem.height / 2.0;
      // ------------------------------------------

      // 定义尝试的方向：上、左、右、下
      final directions = [
        const Offset(0, -1),
        const Offset(-1, 0),
        const Offset(1, 0),
        const Offset(0, 1)
      ];

      for (var dir in directions) {
        // --- 核心修复：物理防穿透检查 ---
        // 绝对禁止碰撞组向着“穿过”拖拽物的方向移动
        if (dir.dx < 0 && groupCenterX > targetCenterX)
          continue; // 想向左推，但组在右侧（禁止向左穿透）
        if (dir.dx > 0 && groupCenterX < targetCenterX)
          continue; // 想向右推，但组在左侧（禁止向右穿透）
        if (dir.dy < 0 && groupCenterY > targetCenterY)
          continue; // 想向上推，但组在下方（禁止向上穿透）
        if (dir.dy > 0 && groupCenterY < targetCenterY)
          continue; // 想向下推，但组在上方（禁止向下穿透）
        // --------------------------------

        int offsetX = 0;
        int offsetY = 0;

        // ... (保持原有的偏移计算和越界检查逻辑不变)
        if (dir.dx < 0) {
          offsetX = targetItem.x - groupRight;
        } else if (dir.dx > 0) {
          offsetX = (targetItem.x + targetItem.width) - groupLeft;
        } else if (dir.dy < 0) {
          offsetY = targetItem.y - groupBottom;
        } else if (dir.dy > 0) {
          offsetY = (targetItem.y + targetItem.height) - groupTop;
        }

        bool isOutOfBoundsX = false;
        bool isColliding = false;
        bool isBreakingCeiling = false;

        for (var item in directCollisions) {
          int nx = item.x + offsetX;
          int ny = item.y + offsetY;

          if (nx < 0 || nx + item.width > columns) {
            isOutOfBoundsX = true;
            break;
          }

          GridItemData ghost = item.clone();
          ghost.x = nx;
          ghost.y = ny;

          for (var other in nextLayout) {
            if (other.id == targetItem.id) continue;
            if (directCollisions.any((e) => e.id == other.id)) continue;

            if (ghost.overlaps(other)) {
              isColliding = true;
              break;
            }
          }
          if (isColliding) break;

          if (ny < 0) {
            isBreakingCeiling = true;
          }
        }

        if (!isOutOfBoundsX && !isColliding) {
          if (!isBreakingCeiling) {
            for (var item in directCollisions) {
              item.x += offsetX;
              item.y += offsetY;
            }
            moved = true;
            break;
            //破天只允许有一个物体，若是受到干扰的物体超过一个了，就不破天了(原版就是这样的)
          } else if (dir.dy < 0 && directCollisions.length == 1) {
            canBreakCeiling = true;
            ceilingOffsetX = offsetX;
            ceilingOffsetY = offsetY;
          }
        }
      }

      if (!moved && canBreakCeiling) {
        for (var item in directCollisions) {
          item.x += ceilingOffsetX;
          item.y += ceilingOffsetY;
        }
        moved = true;
      }

      // 3. 终极保底方案：楔子分裂法 (Wedge Fallback)
      // 如果四个方向都不通，且无法突破天花板，则从拖拽物的第一行切开布局
      if (!moved) {
        // B. 处理下半部分：与拖拽物第一行下方发生重叠的组件
        var belowRowCollisions =
            directCollisions.where((e) => e.y > targetItem.y).toList();
        if (belowRowCollisions.isNotEmpty) {
          debugPrint('触发楔子分裂法，调整下半部分布局');
          // 计算需要整体向下推多少格，才能让这些重叠物的顶部脱离拖拽物的底部
          int maxShiftDown = 0;
          for (var item in belowRowCollisions) {
            int requiredShift = (targetItem.y + targetItem.height) - item.y;
            if (requiredShift > maxShiftDown) maxShiftDown = requiredShift;
          }
          // 将布局中所有在 targetItem 下方的组件（无论是否重叠）整体下移
          for (var item in nextLayout) {
            if (item.id != targetItem.id && item.y > targetItem.y) {
              item.y += maxShiftDown;
            }
          }
        }

        // A. 处理上半部分：与拖拽物第一行（或之上）发生重叠的组件
        var topRowCollisions =
            directCollisions.where((e) => e.y <= targetItem.y).toList();
        if (topRowCollisions.isNotEmpty) {
          debugPrint('触发楔子分裂法，调整上半部分布局');
          // 计算需要整体向上推多少格，才能让这些重叠物的底部脱离拖拽物的第一行
          int maxShiftUp = 0;
          for (var item in topRowCollisions) {
            int requiredShift = (item.y + item.height) - targetItem.y;
            if (requiredShift > maxShiftUp) maxShiftUp = requiredShift;
          }
          // 将布局中所有在 targetItem 及以上的组件（无论是否重叠）整体上移，保持相对布局不乱
          for (var item in nextLayout) {
            if (item.id != targetItem.id && item.y <= targetItem.y) {
              item.y -= maxShiftUp;
            }
          }
        }
      }
    }

    setState(() {
      items = nextLayout;
    });
  }

  void _finalizeLayout() {
    setState(() {
      // 1. 归一化：处理负值坐标，整体下移
      int minY = items.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      if (minY < 0) {
        int offset = minY.abs();
        for (var item in items) {
          item.y += offset;
        }
      }

      // 2. 压缩空行：消除中间和顶部的空白
      _compactLayout(items);
    });
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
  final Offset pointerLocalOffset = box.globalToLocal(details.offset);
  
  // 1. 计算左上角物理偏移
  final Offset itemTopLeftOffset = pointerLocalOffset - dragGrabOffset;
  
  final draggingItem = items.firstWhere((e) => e.id == activeDragId);

  // 2. 基于中心点进行吸附计算
  // 我们通过让中心点坐标除以格子大小取整，得到中心点所在的网格索引
  // 然后减去磁贴自身跨度的一半，得到左上角的网格索引
  int newX = ((itemTopLeftOffset.dx + (draggingItem.width * actualCellSize) / 2) / actualCellSize).floor() 
             - (draggingItem.width / 2).floor();
  int newY = ((itemTopLeftOffset.dy + (draggingItem.height * actualCellSize) / 2) / actualCellSize).floor() 
             - (draggingItem.height / 2).floor();

  // 3. 边界限制
  if (newX < 0) newX = 0;
  if (newX + draggingItem.width > columns) {
    newX = columns - draggingItem.width;
  }
  if (newY < 0) newY = 0;

                  if (newX != lastHoverX || newY != lastHoverY) {
                    lastHoverX = newX;
                    lastHoverY = newY;

                    hoverTimer?.cancel();
                    hoverTimer = Timer(const Duration(milliseconds: 100), () {
                      _updatePreview(newX, newY);
                    });
                  }
                },
                onAcceptWithDetails: (details) {
                  debugPrint('onAcceptWithDetails: ${details.data.id}');
                  if (activeDragId != null) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
  final Offset pointerLocalOffset = box.globalToLocal(details.offset);
  
  // 1. 计算左上角物理偏移
  final Offset itemTopLeftOffset = pointerLocalOffset - dragGrabOffset;
  
  final draggingItem = items.firstWhere((e) => e.id == activeDragId);

  // 2. 基于中心点进行吸附计算
  // 我们通过让中心点坐标除以格子大小取整，得到中心点所在的网格索引
  // 然后减去磁贴自身跨度的一半，得到左上角的网格索引
  int newX = ((itemTopLeftOffset.dx + (draggingItem.width * actualCellSize) / 2) / actualCellSize).floor() 
             - (draggingItem.width / 2).floor();
  int newY = ((itemTopLeftOffset.dy + (draggingItem.height * actualCellSize) / 2) / actualCellSize).floor() 
             - (draggingItem.height / 2).floor();

  // 3. 边界限制
  if (newX < 0) newX = 0;
  if (newX + draggingItem.width > columns) {
    newX = columns - draggingItem.width;
  }
  if (newY < 0) newY = 0;

                    _updatePreview(newX, newY);
                    _finalizeLayout();
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
                      // --- 修改区：用 Listener 包裹 Draggable ---
                      child: Listener(
                        onPointerDown: (event) {
                          // 记录手指按下时相对于当前磁贴左上角的坐标
                          dragGrabOffset = event.localPosition;
                        },
                        child: Draggable<GridItemData>(
                          data: item,
                          onDragStarted: () => _onDragStarted(item.id),
                          onDraggableCanceled: (_, __) => _onDragCanceled(),
                          childWhenDragging: //const SizedBox.shrink(),
                            Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.3),
                              border: Border.all(
                                  color: item.color,
                                  width: 2,
                                  style: BorderStyle.solid),
                            ),
                          ),
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
