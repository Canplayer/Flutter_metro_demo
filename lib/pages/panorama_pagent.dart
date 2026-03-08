import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart'; // 请确保能正常引入

// 定义页面类型数据结构
class PanoramaItemConfig {
  final double? fixedWidth; // null 表示普通页面宽度 (屏幕宽度 - 50)，有值表示超长页
  final Color color;
  final String title;

  PanoramaItemConfig(this.title, this.color, {this.fixedWidth});
}

// ==========================================
// 专为 Panorama 定制的物理引擎
// 负责处理 快速滑动归位、慢速停在原地
// ==========================================
class PanoramaScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;
  final double cycleWidth;

  const PanoramaScrollPhysics({
    required this.snapPoints,
    required this.cycleWidth,
    super.parent,
  });

  @override
  PanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PanoramaScrollPhysics(
      snapPoints: snapPoints,
      cycleWidth: cycleWidth,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
//打印snapPoints和cycleWidth
    debugPrint('snapPoints: $snapPoints');
    debugPrint('cycleWidth: $cycleWidth');
    // 需求2：如果手指是缓慢停下再抬起（速度极小），保持原生行为，停在原地
    if (velocity.abs() < tolerance.velocity) {
      return super.createBallisticSimulation(position, velocity);
    }

    // 计算在当前循环周期内的偏移量
    int cycleIndex = (position.pixels / cycleWidth).floor();
    double offsetInCycle = position.pixels - cycleIndex * cycleWidth;
    double targetOffset;

    // 需求2：滑动时直接归位到逻辑上的“开头”或“末尾”
    if (velocity > 0) {
      // 向左划（往后翻）
      double? nextSnap;
      for (double p in snapPoints) {
        if (p > offsetInCycle + 1.0) {
          // +1.0 容差防止吸附在原地
          nextSnap = p;
          break;
        }
      }
      targetOffset = nextSnap != null
          ? cycleIndex * cycleWidth + nextSnap
          : (cycleIndex + 1) * cycleWidth + snapPoints.first;
    } else {
      // 向右划（往前翻）
      double? prevSnap;
      for (int i = snapPoints.length - 1; i >= 0; i--) {
        if (snapPoints[i] < offsetInCycle - 1.0) {
          prevSnap = snapPoints[i];
          break;
        }
      }
      targetOffset = prevSnap != null
          ? cycleIndex * cycleWidth + prevSnap
          : (cycleIndex - 1) * cycleWidth + snapPoints.last;
    }

    return ScrollSpringSimulation(
        spring, position.pixels, targetOffset, velocity);
  }
}

class PanoramaNewPage2 extends StatefulWidget {
  const PanoramaNewPage2({super.key});

  @override
  State<PanoramaNewPage2> createState() => _PanoramaNewPage2State();
}

class _PanoramaNewPage2State extends State<PanoramaNewPage2> {
  final Key _centerKey = UniqueKey();

  // 页面配置定义：包含两个普通页和一个 2000 宽度的超长页
  final List<PanoramaItemConfig> _items = [
    PanoramaItemConfig('Page 1', Colors.redAccent),
    PanoramaItemConfig('Wide Page 2 (2000px)', Colors.greenAccent,
        fixedWidth: 2000),
    PanoramaItemConfig('Page 3', Colors.blueAccent),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isSinglePage = _items.length <= 1;

    return MetroPageScaffold(
      body: Center(
        child: Stack(
          children: [
            // 标题层（悬浮在滚动内容上方）
            const Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Panorama',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // 内容滚动层
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              bottom: 0,
              // 需求4：使用 LayoutBuilder 响应宽度动态变化
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double screenWidth = constraints.maxWidth;
                  const double peekAmount = 50.0;

                  // 需求1：普通页面的宽度 = 屏幕宽度 - 50
                  final double normalWidth = screenWidth > peekAmount
                      ? screenWidth - peekAmount
                      : screenWidth;

                  // 预计算所有的宽度和吸附点（Snap Points）
                  List<double> itemWidths = [];
                  List<double> snapPoints = [];
                  double currentOffset = 0.0;

                  for (var item in _items) {
                    double width = item.fixedWidth ?? normalWidth;
                    itemWidths.add(width);

                    // 每一个项目开始的地方都是一个吸附归位点
                    snapPoints.add(currentOffset);
                    // 如果是超长页，需要额外在“页面末尾减去显示宽度”的地方增加一个吸附点，用来露出下一页的50px
                    if (width > normalWidth) {
                      snapPoints.add(currentOffset + width - normalWidth);
                    }
                    currentOffset += width;
                  }

                  final double cycleWidth = currentOffset; // 一个完整循环的总宽度

                  // 自定义滚动行为（支持全端手势）
                  final scrollBehavior =
                      const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown
                    },
                  );

                  // 需求3：单页不支持循环，多页支持双向无限循环
                  if (isSinglePage) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      children: [_buildItem(0, normalWidth)],
                    );
                  }
                  final physicsVersionKey = ValueKey(
                    '${constraints.maxWidth.toStringAsFixed(2)}|'
                    '${cycleWidth.toStringAsFixed(2)}|'
                    '${snapPoints.map((e) => e.toStringAsFixed(2)).join(",")}',
                  );

                  return ScrollConfiguration(
                    behavior: scrollBehavior,
                    child: CustomScrollView(
                      key: physicsVersionKey, // 关键：参数变化时重建 ScrollPosition
                      center: _centerKey, // 核心：以中间为基准点，前后都能无限拓展
                      scrollDirection: Axis.horizontal,
                      physics: PanoramaScrollPhysics(
                        snapPoints: snapPoints,
                        cycleWidth: cycleWidth,
                      ),
                      slivers: [
                        // 向左无限延伸
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildItem(-index - 1, normalWidth),
                          ),
                        ),
                        // 向右无限延伸
                        SliverList(
                          key: _centerKey,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildItem(index, normalWidth),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(int index, double normalWidth) {
    // 处理负数索引（支持向左滑动的无限循环）
    int realIndex = index % _items.length;
    if (realIndex < 0) {
      realIndex += _items.length;
    }

    final item = _items[realIndex];
    final double width = item.fixedWidth ?? normalWidth;

    return Container(
      width: width,
      color: item.color,
      padding: const EdgeInsets.only(left: 20),
      alignment: Alignment.centerLeft, // 左对齐方便查看长页内容
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
                fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (item.fixedWidth != null) ...[
            const SizedBox(height: 20),
            const Text(
              '这是一个超长页面\n你可以停在中间，也可以使劲滑触发头尾归位',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ]
        ],
      ),
    );
  }
}
