import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';

// --- 1. 浮动效果包装器保持不变 ---
class FloatingWrapper extends StatefulWidget {
  final bool isFloating;
  final Widget child;

  const FloatingWrapper({Key? key, required this.isFloating, required this.child}) : super(key: key);

  @override
  _FloatingWrapperState createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<FloatingWrapper> {
  double _dx = 0;
  double _dy = 0;
  int _durationMs = 300;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isFloating) _startFloatingLoop();
  }

  @override
  void didUpdateWidget(FloatingWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFloating && !oldWidget.isFloating) {
      _startFloatingLoop();
    } else if (!widget.isFloating && oldWidget.isFloating) {
      _stopFloating();
    }
  }

  void _startFloatingLoop() {
    if (!widget.isFloating) return;
    setState(() {
      _dx = (_random.nextDouble() * 20) - 10;
      _dy = (_random.nextDouble() * 20) - 10;
      _durationMs = 1000 + _random.nextInt(1001);
    });
    _timer = Timer(Duration(milliseconds: _durationMs), _startFloatingLoop);
  }

  void _stopFloating() {
    _timer?.cancel();
    setState(() {
      _dx = 0;
      _dy = 0;
      _durationMs = 300;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: _durationMs),
      curve: Curves.easeInOutSine,
      transform: Matrix4.translationValues(_dx, _dy, 0),
      child: widget.child,
    );
  }
}

// --- 2. 升级后的 TileModel：包含克隆和碰撞检测 ---
class TileModel {
  final String id;
  int gridX;
  int gridY;
  final int widthCells;
  final int heightCells;
  final Color color;
  Offset? dragPixelOffset;
  GlobalKey key; // 去掉 final，因为克隆时需要共享同一个 Key 防止组件卸载

  TileModel({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.widthCells,
    required this.heightCells,
    required this.color,
  }) : key = GlobalKey();

  // 深度克隆（必须共享 Key！）
  TileModel clone() {
    return TileModel(
      id: id,
      gridX: gridX,
      gridY: gridY,
      widthCells: widthCells,
      heightCells: heightCells,
      color: color,
    )..key = key; 
  }

  // AABB 碰撞检测
  bool overlaps(TileModel other) {
    return gridX < other.gridX + other.widthCells &&
           gridX + widthCells > other.gridX &&
           gridY < other.gridY + other.heightCells &&
           gridY + heightCells > other.gridY;
  }
}

class Windows10StartMenu extends StatefulWidget {
  @override
  _Windows10StartMenuState createState() => _Windows10StartMenuState();
}

class _Windows10StartMenuState extends State<Windows10StartMenu> {
  final int crossAxisCount = 4;
  final double gridSpacing = 10.0;

  List<TileModel> tiles = [
    TileModel(id: '1', gridX: 0, gridY: 0, widthCells: 2, heightCells: 2, color: Colors.cyan[700]!),
    TileModel(id: '2', gridX: 2, gridY: 0, widthCells: 1, heightCells: 1, color: Colors.red[700]!),
    TileModel(id: '3', gridX: 3, gridY: 0, widthCells: 1, heightCells: 1, color: Colors.green[700]!),
    TileModel(id: '4', gridX: 0, gridY: 2, widthCells: 4, heightCells: 2, color: Colors.orange[700]!),
    TileModel(id: '5', gridX: 0, gridY: 4, widthCells: 1, heightCells: 1, color: Colors.purple[700]!),
  ];

  // --- UI状态 ---
  bool isEditMode = false;
  String? selectedTileId;
  String? draggingTileId;
  Offset? initialDragOffset;
  Offset? initialTouchPosition;
  bool hasMetDragThreshold = false;

  // --- 引擎状态 ---
  List<TileModel>? originalItems;
  Timer? hoverTimer;
  int lastHoverX = -1;
  int lastHoverY = -1;

  void _exitEditMode() {
    if (isEditMode) {
      setState(() {
        isEditMode = false;
        selectedTileId = null;
        draggingTileId = null;
      });
    }
  }

  // --- 🌟 完美移植：网格碰撞推挤引擎 ---
  void _updatePreview(int targetX, int targetY) {
    if (originalItems == null || draggingTileId == null) return;

// --- 🌟 核心修复 1：在覆盖前，先提取当前拖拽砖块的实时像素坐标 ---
    Offset? currentPixelOffset;
    try {
      currentPixelOffset = tiles.firstWhere((e) => e.id == draggingTileId).dragPixelOffset;
    } catch (e) {}
    // -------------------------------------------------------------

    List<TileModel> nextLayout = originalItems!.map((e) => e.clone()).toList();
    TileModel targetItem = nextLayout.firstWhere((e) => e.id == draggingTileId);
    
    targetItem.gridX = targetX;
    targetItem.gridY = targetY;

    // --- 🌟 核心修复 2：将实时坐标强行注入给新的克隆体，防止丢失 ---
    targetItem.dragPixelOffset = currentPixelOffset;
    // -------------------------------------------------------------

    List<TileModel> directCollisions = nextLayout
        .where((item) => item.id != targetItem.id && item.overlaps(targetItem))
        .toList();

    if (directCollisions.isNotEmpty) {
      bool moved = false;
      bool canBreakCeiling = false;
      int ceilingOffsetX = 0;
      int ceilingOffsetY = 0;

      int groupLeft = directCollisions.map((e) => e.gridX).reduce((a, b) => a < b ? a : b);
      int groupRight = directCollisions.map((e) => e.gridX + e.widthCells).reduce((a, b) => a > b ? a : b);
      int groupTop = directCollisions.map((e) => e.gridY).reduce((a, b) => a < b ? a : b);
      int groupBottom = directCollisions.map((e) => e.gridY + e.heightCells).reduce((a, b) => a > b ? a : b);

      double groupCenterX = groupLeft + (groupRight - groupLeft) / 2.0;
      double groupCenterY = groupTop + (groupBottom - groupTop) / 2.0;

      double targetCenterX = targetItem.gridX + targetItem.widthCells / 2.0;
      double targetCenterY = targetItem.gridY + targetItem.heightCells / 2.0;

      final directions = [const Offset(0, -1), const Offset(-1, 0), const Offset(1, 0), const Offset(0, 1)];

      for (var dir in directions) {
        if (dir.dx < 0 && groupCenterX > targetCenterX) continue;
        if (dir.dx > 0 && groupCenterX < targetCenterX) continue;
        if (dir.dy < 0 && groupCenterY > targetCenterY) continue;
        if (dir.dy > 0 && groupCenterY < targetCenterY) continue;

        int offsetX = 0;
        int offsetY = 0;

        if (dir.dx < 0) {
          offsetX = targetItem.gridX - groupRight;
        } else if (dir.dx > 0) {
          offsetX = (targetItem.gridX + targetItem.widthCells) - groupLeft;
        } else if (dir.dy < 0) {
          offsetY = targetItem.gridY - groupBottom;
        } else if (dir.dy > 0) {
          offsetY = (targetItem.gridY + targetItem.heightCells) - groupTop;
        }

        bool isOutOfBoundsX = false;
        bool isColliding = false;
        bool isBreakingCeiling = false;

        for (var item in directCollisions) {
          int nx = item.gridX + offsetX;
          int ny = item.gridY + offsetY;

          if (nx < 0 || nx + item.widthCells > crossAxisCount) {
            isOutOfBoundsX = true;
            break;
          }

          TileModel ghost = item.clone();
          ghost.gridX = nx;
          ghost.gridY = ny;

          for (var other in nextLayout) {
            if (other.id == targetItem.id) continue;
            if (directCollisions.any((e) => e.id == other.id)) continue;
            if (ghost.overlaps(other)) {
              isColliding = true;
              break;
            }
          }
          if (isColliding) break;
          if (ny < 0) isBreakingCeiling = true;
        }

        if (!isOutOfBoundsX && !isColliding) {
          if (!isBreakingCeiling) {
            for (var item in directCollisions) {
              item.gridX += offsetX;
              item.gridY += offsetY;
            }
            moved = true;
            break;
          } else if (dir.dy < 0 && directCollisions.length == 1) {
            canBreakCeiling = true;
            ceilingOffsetX = offsetX;
            ceilingOffsetY = offsetY;
          }
        }
      }

      if (!moved && canBreakCeiling) {
        for (var item in directCollisions) {
          item.gridX += ceilingOffsetX;
          item.gridY += ceilingOffsetY;
        }
        moved = true;
      }

      if (!moved) {
        var belowRowCollisions = directCollisions.where((e) => e.gridY > targetItem.gridY).toList();
        if (belowRowCollisions.isNotEmpty) {
          int maxShiftDown = 0;
          for (var item in belowRowCollisions) {
            int requiredShift = (targetItem.gridY + targetItem.heightCells) - item.gridY;
            if (requiredShift > maxShiftDown) maxShiftDown = requiredShift;
          }
          for (var item in nextLayout) {
            if (item.id != targetItem.id && item.gridY > targetItem.gridY) {
              item.gridY += maxShiftDown;
            }
          }
        }

        var topRowCollisions = directCollisions.where((e) => e.gridY <= targetItem.gridY).toList();
        if (topRowCollisions.isNotEmpty) {
          int maxShiftUp = 0;
          for (var item in topRowCollisions) {
            int requiredShift = (item.gridY + item.heightCells) - targetItem.gridY;
            if (requiredShift > maxShiftUp) maxShiftUp = requiredShift;
          }
          for (var item in nextLayout) {
            if (item.id != targetItem.id && item.gridY <= targetItem.gridY) {
              item.gridY -= maxShiftUp;
            }
          }
        }
      }
    }

    setState(() {
      tiles = nextLayout;
    });
  }

  void _finalizeLayout() {
    setState(() {
      int minY = tiles.map((e) => e.gridY).reduce((a, b) => a < b ? a : b);
      if (minY < 0) {
        int offset = minY.abs();
        for (var item in tiles) {
          item.gridY += offset;
        }
      }
      _compactLayout(tiles);
    });
  }

  void _compactLayout(List<TileModel> allItems) {
    int maxY = allItems.fold(0, (max, e) => e.gridY + e.heightCells > max ? e.gridY + e.heightCells : max);
    for (int y = 0; y < maxY; y++) {
      bool isRowOccupied = allItems.any((item) => y >= item.gridY && y < item.gridY + item.heightCells);
      if (!isRowOccupied) {
        bool hasItemsBelow = allItems.any((item) => item.gridY > y);
        if (hasItemsBelow) {
          for (var item in allItems) {
            if (item.gridY > y) item.gridY -= 1;
          }
          y--;
          maxY--;
        }
      }
    }
  }

  // --- 滑动核心接管 ---
  void _onDragStart(TileModel tile, Offset touchPosition, double left, double top) {
    setState(() {
      isEditMode = true;
      selectedTileId = tile.id;
      draggingTileId = tile.id;
      initialDragOffset = Offset(left, top);
      initialTouchPosition = touchPosition;
      hasMetDragThreshold = false;
      tile.dragPixelOffset = initialDragOffset;
      
      // 🌟 保存布局快照
      originalItems = tiles.map((e) => e.clone()).toList();
    });
  }

  void _onDragUpdate(TileModel tile, Offset currentTouchPosition, double cellSize) {
    if (draggingTileId == tile.id && initialTouchPosition != null && initialDragOffset != null) {
      final distance = (currentTouchPosition - initialTouchPosition!).distance;

      setState(() {
        //拖拽距离达到一定程度才允许图标拖拽
        if (!hasMetDragThreshold && distance > 70.0) {
          hasMetDragThreshold = true;
        }
        if (hasMetDragThreshold) {
          // 更新物理像素用于渲染
          tile.dragPixelOffset = initialDragOffset! + (currentTouchPosition - initialTouchPosition!);

          // 🌟 结合你的基于中心点的平滑吸附计算
          int newGridX = ((tile.dragPixelOffset!.dx + (tile.widthCells * cellSize) / 2) / cellSize).floor() - (tile.widthCells / 2).floor();
          int newGridY = ((tile.dragPixelOffset!.dy + (tile.heightCells * cellSize) / 2) / cellSize).floor() - (tile.heightCells / 2).floor();

          newGridX = newGridX.clamp(0, crossAxisCount - tile.widthCells);
          newGridY = newGridY >= 0 ? newGridY : 0;

          // 🌟 Hover防抖判断
          if (newGridX != lastHoverX || newGridY != lastHoverY) {
            lastHoverX = newGridX;
            lastHoverY = newGridY;

            hoverTimer?.cancel();
            hoverTimer = Timer(const Duration(milliseconds: 120), () {
              _updatePreview(newGridX, newGridY);
            });
          }
        }
      });
    }
  }

  void _onDragEnd(TileModel tile, double cellSize) {
    setState(() {
      hoverTimer?.cancel();

      if (tile.dragPixelOffset != null && hasMetDragThreshold) {
        int finalX = ((tile.dragPixelOffset!.dx + (tile.widthCells * cellSize) / 2) / cellSize).floor() - (tile.widthCells / 2).floor();
        int finalY = ((tile.dragPixelOffset!.dy + (tile.heightCells * cellSize) / 2) / cellSize).floor() - (tile.heightCells / 2).floor();
        finalX = finalX.clamp(0, crossAxisCount - tile.widthCells);
        finalY = finalY >= 0 ? finalY : 0;

        // 强制最后执行一次确保落地位置正确
        _updatePreview(finalX, finalY);
        _finalizeLayout();
      } else {
        // 如果没有突破死区，恢复快照
        if (originalItems != null) {
          tiles = originalItems!;
        }
      }

      // 清理引擎状态
      draggingTileId = null;
      tile.dragPixelOffset = null;
      initialDragOffset = null;
      initialTouchPosition = null;
      hasMetDragThreshold = false;
      originalItems = null;
      lastHoverX = -1;
      lastHoverY = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      backgroundColor: Colors.grey[900],
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _exitEditMode,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cellSize = constraints.maxWidth / crossAxisCount;

              List<Widget> normalTiles = [];
              Widget? activeTileWidget;

              for (var tile in tiles) {
                Widget tileWidget = _buildTile(tile, cellSize);
                if (tile.id == draggingTileId) {
                  activeTileWidget = tileWidget;
                } else {
                  normalTiles.add(tileWidget);
                }
              }

              if (activeTileWidget != null) normalTiles.add(activeTileWidget);

              return Stack(children: normalTiles);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTile(TileModel tile, double cellSize) {
    final bool isSelected = tile.id == selectedTileId;
    final bool isActuallyDragging = (tile.id == draggingTileId) && hasMetDragThreshold;

    double targetOpacity = 1.0;
    if (isEditMode) {
      targetOpacity = isSelected ? (isActuallyDragging ? 0.8 : 1.0) : 0.5;
    }

    final double targetZ = isEditMode ? 150.0 : 0.0;
    //final double targetZ = (isEditMode && !isSelected) ? 150.0 : 0.0;
    double targetScale = (!isEditMode || isSelected) ? 1.0 : 0.9;

    // 非拖拽状态下使用计算出的物理像素
    final double targetLeft = tile.gridX * cellSize;
    final double targetTop = tile.gridY * cellSize;

    // 拖拽时使用真实像素
    final double left = isActuallyDragging && tile.dragPixelOffset != null ? tile.dragPixelOffset!.dx : targetLeft;
    final double top = isActuallyDragging && tile.dragPixelOffset != null ? tile.dragPixelOffset!.dy : targetTop;
    final double width = tile.widthCells * cellSize - gridSpacing;
    final double height = tile.heightCells * cellSize - gridSpacing;

    // 🌟 核心：使用 AnimatedPositioned 实现布局改变时的自动顺滑挤推
    return AnimatedPositioned(
      key: tile.key,
      duration: Duration(milliseconds: isActuallyDragging ? 0 : 300), // 拖拽时立即响应，排版推挤时300ms过渡
      curve: Curves.easeOutCubic,
      left: left + gridSpacing / 2,
      top: top + gridSpacing / 2,
      width: width,
      height: height,
      child: FloatingWrapper(
        isFloating: isEditMode && !isSelected,
        child: GestureDetector(
          onTap: () {
            if (isEditMode) setState(() => selectedTileId = tile.id);
          },
          onLongPressStart: (details) => _onDragStart(tile, details.globalPosition, targetLeft, targetTop),
          onLongPressMoveUpdate: (details) => _onDragUpdate(tile, details.globalPosition, cellSize),
          onLongPressEnd: (details) => _onDragEnd(tile, cellSize),
          
          onPanStart: (isEditMode && isSelected) ? (details) => _onDragStart(tile, details.globalPosition, targetLeft, targetTop) : null,
          onPanUpdate: (isEditMode && isSelected) ? (details) => _onDragUpdate(tile, details.globalPosition, cellSize) : null,
          onPanEnd: (isEditMode && isSelected) ? (details) => _onDragEnd(tile, cellSize) : null,
          
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: targetScale,
            curve: Curves.easeOutCubic,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetZ),
              duration: Duration(milliseconds: isActuallyDragging ? 0 : 200),
              curve: Curves.easeOut,
              builder: (context, zValue, child) {
                Matrix4 currentTransform = Matrix4.identity();
                if(zValue != 0) {
                  currentTransform.rotateX(0.000000001);
                }
                currentTransform.translate(0.0, 0.0, zValue);

                return Transform(
                  alignment: FractionalOffset.center,
                  transform: currentTransform,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: targetOpacity,
                    child: Container(
                      color: tile.color,
                      child: Center(
                        child: Text('${tile.widthCells}x${tile.heightCells}',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}