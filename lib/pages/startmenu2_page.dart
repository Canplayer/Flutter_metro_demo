import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';

// ... 其他代码

class StartMenu2 extends StatefulWidget {
  const StartMenu2({super.key});

  @override
  State<StartMenu2> createState() => _StartMenu2State();
}

class _StartMenu2State extends State<StartMenu2> {
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
      body: Windows10StartMenu(),
    );
  }
}

class TileModel {
  final String id;
  int gridX;
  int gridY;
  final int widthCells;
  final int heightCells;
  final Color color;
  Offset? dragPixelOffset;
  final GlobalKey key;
  TileModel({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.widthCells,
    required this.heightCells,
    required this.color,
  }) : key = GlobalKey();
}

class Windows10StartMenu extends StatefulWidget {
  @override
  _Windows10StartMenuState createState() => _Windows10StartMenuState();
}

class _Windows10StartMenuState extends State<Windows10StartMenu> {
  final int crossAxisCount = 4;
  final double gridSpacing = 8.0;

  List<TileModel> tiles = [
    TileModel(
        id: '1',
        gridX: 0,
        gridY: 0,
        widthCells: 2,
        heightCells: 2,
        color: Colors.cyan[700]!),
    TileModel(
        id: '2',
        gridX: 2,
        gridY: 0,
        widthCells: 1,
        heightCells: 1,
        color: Colors.red[700]!),
    TileModel(
        id: '3',
        gridX: 3,
        gridY: 0,
        widthCells: 1,
        heightCells: 1,
        color: Colors.green[700]!),
    TileModel(
        id: '4',
        gridX: 0,
        gridY: 2,
        widthCells: 4,
        heightCells: 2,
        color: Colors.orange[700]!),
    TileModel(
        id: '5',
        gridX: 0,
        gridY: 4,
        widthCells: 1,
        heightCells: 1,
        color: Colors.purple[700]!),
  ];

  bool isEditMode = false;
  String? selectedTileId;
  String? draggingTileId;
  Offset? initialDragOffset;
  Offset? initialTouchPosition; // 🌟 新增：手指按下的全局绝对坐标
  bool hasMetDragThreshold = false; // 🌟 新增：是否已经突破了 100px 的拖拽死区

  void _exitEditMode() {
    if (isEditMode) {
      setState(() {
        isEditMode = false;
        selectedTileId = null;
        draggingTileId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 核心视觉修复1：改为深色背景 (类似 Windows 10 Start Menu 的深色)
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Win10 磁贴布局 (视觉修复版)'),
        backgroundColor: Colors.grey[850],
      ),
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
                if (tile.id == selectedTileId) {
                  activeTileWidget = tileWidget;
                } else {
                  normalTiles.add(tileWidget);
                }
              }

              if (activeTileWidget != null) {
                normalTiles.add(activeTileWidget);
              }

              return Stack(
                children: normalTiles,
              );
            },
          ),
        ),
      ),
    );
  }

  // 🌟 新增：提取松手归位的共用逻辑
  void _handleDragEnd(TileModel tile, double cellSize) {
    setState(() {
      // 🌟 核心修复：只有真正被拖拽过的磁贴，才触发网格吸附
      if (tile.dragPixelOffset != null && hasMetDragThreshold) {
        int newGridX = (tile.dragPixelOffset!.dx / cellSize).round();
        int newGridY = (tile.dragPixelOffset!.dy / cellSize).round();

        // 边界限制
        newGridX = newGridX.clamp(0, crossAxisCount - tile.widthCells);
        newGridY = newGridY >= 0 ? newGridY : 0;

        tile.gridX = newGridX;
        tile.gridY = newGridY;
      }

      // 结束拖拽，但保留选中状态（不退出编辑模式）
      draggingTileId = null;
      tile.dragPixelOffset = null;
      initialDragOffset = null;
      initialTouchPosition = null; // 重置触摸点
      hasMetDragThreshold = false; // 重置阈值标志
    });
  }

  Widget _buildTile(TileModel tile, double cellSize) {
    final bool isSelected = tile.id == selectedTileId;

// 🌟 新增：必须是当前操作的磁贴，且突破了 100px 阈值，才算真正的“拖动状态”
    final bool isActuallyDragging =
        (tile.id == draggingTileId) && hasMetDragThreshold;
    double targetOpacity = 1.0;
    if (isEditMode) {
      if (isSelected) {
        // 🌟 核心视觉：拖拽状态下 80% (0.8) 透明度，单纯点亮未拖拽时 100% (1.0)
        targetOpacity = isActuallyDragging ? 0.8 : 1.0;
      } else {
        targetOpacity = 0.5;
      }
    }

    final bool isDragging = tile.id == draggingTileId;

    // --- 核心逻辑修复1：透明度逻辑 ---

    // if (isEditMode) {
    //   if (isSelected) {
    //     // --- 核心修复：按住的磁贴、选中的磁贴，恒定 1.0 不透明 ---
    //     targetOpacity = 1.0;
    //   } else {
    //     // 未被选中的其他磁贴：半透明
    //     targetOpacity = 0.5;
    //   }
    // }

    // 缩放逻辑保持原样
    double targetScale = (!isEditMode || isSelected) ? 1.0 : 0.9;

    final double left = isDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dx
        : tile.gridX * cellSize;
    final double top = isDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dy
        : tile.gridY * cellSize;

    final double width = tile.widthCells * cellSize - gridSpacing;
    final double height = tile.heightCells * cellSize - gridSpacing;

    final double targetZ = (isEditMode && !isSelected) ? 150.0 : 0.0;

    return Positioned(
      key: ValueKey(tile.id),
      // 为了让阴影过渡自然，我们在拖拽时稍微偏移一点 z 轴（模拟抬起）
      left: left + gridSpacing / 2,
      top: top + gridSpacing / 2,
      width: width,
      height: height,
      child: FloatingWrapper(
        isFloating: isEditMode && !isSelected,
        child: GestureDetector(
          onTap: () {
            if (isEditMode) {
              setState(() {
                selectedTileId = tile.id;
              });
            }
          },

          // --- 长按事件 ---
          onLongPressStart: (details) {
            setState(() {
              isEditMode = true;
              selectedTileId = tile.id;
              draggingTileId = tile.id;

              initialDragOffset = Offset(left, top);
              initialTouchPosition = details.globalPosition; // 记录手指初始位置
              hasMetDragThreshold = false; // 锁死坐标
              tile.dragPixelOffset = initialDragOffset; // 呆在原地
            });
          },
          onLongPressMoveUpdate: (details) {
            if (draggingTileId == tile.id &&
                initialTouchPosition != null &&
                initialDragOffset != null) {
              // 计算手指移动的绝对直线距离
              final distance =
                  (details.globalPosition - initialTouchPosition!).distance;

              setState(() {
                // 距离超过 100px，解锁死区
                if (!hasMetDragThreshold && distance > 100.0) {
                  hasMetDragThreshold = true;
                }
                // 解锁后，磁贴瞬间吸附并跟随手指
                if (hasMetDragThreshold) {
                  tile.dragPixelOffset = initialDragOffset! +
                      (details.globalPosition - initialTouchPosition!);
                }
              });
            }
          },
          onLongPressEnd: (details) {
            _handleDragEnd(tile, cellSize);
          },

          // --- 滑动事件 (完全相同的逻辑) ---
          onPanStart: (isEditMode && isSelected)
              ? (details) {
                  setState(() {
                    draggingTileId = tile.id;

                    initialDragOffset = Offset(left, top);
                    initialTouchPosition = details.globalPosition;
                    hasMetDragThreshold = false;
                    tile.dragPixelOffset = initialDragOffset; // 呆在原地
                  });
                }
              : null,
          onPanUpdate: (isEditMode && isSelected)
              ? (details) {
                  if (draggingTileId == tile.id &&
                      initialTouchPosition != null &&
                      initialDragOffset != null) {
                    final distance =
                        (details.globalPosition - initialTouchPosition!)
                            .distance;

                    setState(() {
                      if (!hasMetDragThreshold && distance > 100.0) {
                        hasMetDragThreshold = true;
                      }
                      if (hasMetDragThreshold) {
                        tile.dragPixelOffset = initialDragOffset! +
                            (details.globalPosition - initialTouchPosition!);
                      }
                    });
                  }
                }
              : null,
          onPanEnd: (isEditMode && isSelected)
              ? (details) {
                  _handleDragEnd(tile, cellSize);
                }
              : null,
          child: TweenAnimationBuilder<double>(
              // Tween 定义了动画要在什么值之间过渡
              tween: Tween<double>(begin: 0.0, end: targetZ),
              duration: Duration(milliseconds: isDragging ? 0 : 200),
              curve: Curves.easeOut,
              // builder 会在动画的每一帧用最新的 zValue 重新构建 UI
              builder: (context, zValue, child) {
                // 2. 实时构建当前的 3D 矩阵
                Matrix4 currentTransform = Matrix4.identity();

                // 只有当 zValue 小于 0（也就是开始往后退）时，才加上透视效果
                if (zValue != 0) {
                  currentTransform.rotateX(0.0000001);
                }
                // 应用当前帧的 Z 轴偏移
                currentTransform.translate(0.0, 0.0, zValue);
                return Transform(
                  alignment: FractionalOffset.center,
                  transform: currentTransform,
                  child: AnimatedScale(
                    duration: Duration(milliseconds: 200),
                    scale: targetScale,
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 200),
                      opacity: targetOpacity,
                      // 核心视觉修复2：使用 AnimatedContainer 管理阴影过渡，模拟“抬起”

                      child: Container(
                        color: tile.color,
                        child: Center(
                          child: Text(
                            '${tile.widthCells}x${tile.heightCells} + (${targetOpacity}})',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class FloatingWrapper extends StatefulWidget {
  final bool isFloating; // 是否开启浮动
  final Widget child;

  const FloatingWrapper(
      {Key? key, required this.isFloating, required this.child})
      : super(key: key);

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
    // 监听状态变化：开启 or 关闭浮动
    if (widget.isFloating && !oldWidget.isFloating) {
      _startFloatingLoop();
    } else if (!widget.isFloating && oldWidget.isFloating) {
      _stopFloating();
    }
  }

  void _startFloatingLoop() {
    if (!widget.isFloating) return;

    setState(() {
      // X和Y轴生成 -10 到 10的随机偏移量
      _dx = (_random.nextDouble() * 20) - 10;
      _dy = (_random.nextDouble() * 20) - 10;
      // 生成 1500 到 2000 毫秒的随机时长
      _durationMs = 1000 + _random.nextInt(1001);
    });

    // 等待当前动画执行完毕后，递归调用自己，形成无限循环
    _timer = Timer(Duration(milliseconds: _durationMs), _startFloatingLoop);
  }

  void _stopFloating() {
    _timer?.cancel();
    setState(() {
      _dx = 0;
      _dy = 0;
      _durationMs = 300; // 停止时，用300毫秒平滑归位到中心
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
      curve: Curves.easeInOutSine, // 使用 Sine 曲线，让来回浮动更加丝滑柔和
      transform: Matrix4.translationValues(_dx, _dy, 0),
      child: widget.child,
    );
  }
}
