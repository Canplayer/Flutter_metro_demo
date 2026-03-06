import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';

class ParallaxData {
  final double tOffset;
  final double bOffset;
  const ParallaxData(this.tOffset, this.bOffset);
}

class MetroPanoramaItem {
  final String title;
  final Widget child;
  final double width;

  MetroPanoramaItem({
    required this.title,
    required this.child,
    this.width = 300,
  });
}

typedef TargetCallback = void Function(double target);

class PanoramaScrollPhysics extends ScrollPhysics {
  final List<double> snapPoints;
  final double cycleLength;
  final bool isInfinite;
  final TargetCallback? onTargetCalculated;

  const PanoramaScrollPhysics({
    required this.snapPoints,
    required this.cycleLength,
    required this.isInfinite,
    this.onTargetCalculated,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  PanoramaScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return PanoramaScrollPhysics(
      snapPoints: snapPoints,
      cycleLength: cycleLength,
      isInfinite: isInfinite,
      onTargetCalculated: onTargetCalculated,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;

    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    double pixels = position.pixels;
    double target = pixels + (velocity * 0.2);

    double bestSnap = pixels;
    double minDiff = double.infinity;

    if (isInfinite) {
      int cycle = (target / cycleLength).floor();
      for (int i = cycle - 1; i <= cycle + 1; i++) {
        for (double sp in snapPoints) {
          double absSp = i * cycleLength + sp;
          double diff = (absSp - target).abs();
          if (diff < minDiff) {
            minDiff = diff;
            bestSnap = absSp;
          }
        }
      }
    } else {
      for (double sp in snapPoints) {
        double diff = (sp - target).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestSnap = sp;
        }
      }
    }

    if (!isInfinite) {
      if (bestSnap < position.minScrollExtent)
        bestSnap = position.minScrollExtent;
      if (bestSnap > position.maxScrollExtent)
        bestSnap = position.maxScrollExtent;
    }

    if ((bestSnap - pixels).abs() < tolerance.distance) {
      return null;
    }

    if (onTargetCalculated != null) {
      onTargetCalculated!(bestSnap);
    }

    return ScrollSpringSimulation(
      spring,
      pixels,
      bestSnap,
      velocity,
      tolerance: tolerance,
    );
  }
}

//Panorama和Pivot控件
class PanoramaPage extends StatefulWidget {
  const PanoramaPage({super.key});

  @override
  State<PanoramaPage> createState() => _PanoramaPageState();
}

class _PanoramaPageState extends State<PanoramaPage>
    with TickerProviderStateMixin {
  static const double _pi = 3.1415926535897932;
  static double _degreesToRadians(double degrees) => degrees * _pi / 180;
  final double _pivot = -250 * 0.8;

  late AnimationController _rotationController;
  late AnimationController _translationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _translationAnimation;

  late ScrollController _scrollController;

  final ValueNotifier<ParallaxData> _parallaxNotifier =
      ValueNotifier<ParallaxData>(const ParallaxData(0.0, 0.0));
  // 用于将 _translationAnimation 的值透传到各子层，以便分别施加不同的偏移量
  final ValueNotifier<double> _translationNotifier = ValueNotifier<double>(1.0);

  bool _isDragging = false;
  bool _isBallistic = false;
  double _targetS = 0.0;
  double _releaseS = 0.0;
  double _releaseT = 0.0;
  double _releaseB = 0.0;
  // 标题容器宽度（与渲染时 SizedBox 的 width 一致）
  static const double _titleContainerWidth = 500.0;
  double _titleSpacing = 1500.0;
  final double _bgPatternWidth = 1000.0;

  final List<MetroPanoramaItem> _items = [];
  final List<double> _snapPoints = [];
  double _cycleLength = 0;

  @override
  void initState() {
    super.initState();

    // 添加默认的测试数据
    _items.addAll([
      MetroPanoramaItem(
        title: "camera roll",
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 280, height: 120, color: Colors.blue.withOpacity(0.3)),
            const SizedBox(height: 10),
            Container(
                width: 280, height: 120, color: Colors.blue.withOpacity(0.3)),
          ],
        ),
      ),
      MetroPanoramaItem(
        title: "albums",
        width: 300,
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          children: List.generate(
              4,
              (i) => Container(
                  width: 130,
                  height: 130,
                  color: Colors.green.withOpacity(0.3))),
        ),
      ),
      MetroPanoramaItem(
        title: "long data view",
        width: 800,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // 让父级ListView接管滑动体验
          child: Row(
            children: List.generate(
                10,
                (i) => Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 15),
                      color: Colors.orange.withOpacity(0.3 + (i % 5) * 0.1),
                      child: Center(
                          child: Text("Item ${i + 1}",
                              style: const TextStyle(fontSize: 16))),
                    )),
          ),
        ),
      ),
      MetroPanoramaItem(
        title: "people",
        width: 300,
        child: Container(
          width: 280,
          height: 250,
          color: Colors.purple.withOpacity(0.3),
          child: const Center(
              child: Text("Contacts", style: TextStyle(fontSize: 20))),
        ),
      ),
    ]);

    // 计算滑动停靠点 (Snap points)
    double current = 0;
    for (var item in _items) {
      _snapPoints.add(current);
      if (item.width > 300) {
        // 如果过长，给尾部增加一个停靠点保证露出后一页的一点点
        _snapPoints.add(current + item.width - 300);
      }
      current += item.width;
    }
    _cycleLength = current;

    _scrollController = ScrollController(initialScrollOffset: 0.0);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotationAnimation =
        Tween<double>(begin: -86.5, end: 0).animate(CurvedAnimation(
      parent: _rotationController,
      curve: MetroCurves.panoramaRotateIn,
    ));

    _translationAnimation =
        Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(
      parent: _translationController,
      curve: MetroCurves.panoramaTranslateIn,
    ));
    _translationAnimation.addListener(() {
      _translationNotifier.value = _translationAnimation.value;
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _translationController.dispose();
    _scrollController.dispose();
    _parallaxNotifier.dispose();
    _translationNotifier.dispose();
    super.dispose();
  }

  // 获得一个精确到目标的数学最终视觉左边距 (大标题)
  double _getIdealT(double S, double parentWidth) {
    if (_cycleLength == 0) return 0.0;
    int cycle = (S / _cycleLength).floor();
    double localS = S - cycle * _cycleLength;
    double S_last = _snapPoints.isEmpty ? 0 : _snapPoints.last;

    double targetWidth = _titleContainerWidth;
    double T_loc;
    if (localS <= S_last && S_last > 0) {
      T_loc = -(targetWidth - parentWidth) * (localS / S_last);
    } else if (S_last > 0) {
      double p = (localS - S_last) / (_cycleLength - S_last);
      double T_start = -(targetWidth - parentWidth);
      double T_end = -_titleSpacing;
      T_loc = T_start + p * (T_end - T_start);
    } else {
      T_loc = 0;
    }
    return T_loc - cycle * _titleSpacing;
  }

  // 获得目标的最终背景图位置
  double _getIdealB(double S, double parentWidth) {
    if (_cycleLength == 0) return 0.0;
    int cycle = (S / _cycleLength).floor();
    double localS = S - cycle * _cycleLength;
    double S_last = _snapPoints.isEmpty ? 0 : _snapPoints.last;

    double B_loc;
    if (localS <= S_last && S_last > 0) {
      B_loc = -(_bgPatternWidth - parentWidth) * (localS / S_last);
    } else if (S_last > 0) {
      double p = (localS - S_last) / (_cycleLength - S_last);
      double B_start = -(_bgPatternWidth - parentWidth);
      double B_end = -_bgPatternWidth;
      B_loc = B_start + p * (B_end - B_start);
    } else {
      B_loc = 0;
    }
    return B_loc - cycle * _bgPatternWidth;
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      onDidPush: () {
        _rotationController.forward();
        _translationController.forward();
      },
      onDidPopNext: () async {},
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 计算足够跨度安全的 Title Spacing 并让飞入飞出能跨过一个屏幕的宽度
            _titleSpacing = _titleContainerWidth + constraints.maxWidth + 100.0;

            return AnimatedBuilder(
              animation:
                  Listenable.merge([_rotationAnimation, _translationAnimation]),
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.rotationY(
                      _degreesToRadians(_rotationAnimation.value)),
                  origin: Offset(_pivot, 0),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: constraints.maxHeight,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: _buildPanoramaContent(
                    constraints.maxWidth, constraints.maxHeight),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanoramaContent(double parentWidth, double parentHeight) {
    bool isInfinite = _items.length > 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. 无限层与标题层
        //    使用 AnimatedBuilder 同时监听视差数据与入场平移值，以便分别施加不同幅度的偏移
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_parallaxNotifier, _translationNotifier]),
            builder: (context, _) {
              final data = _parallaxNotifier.value;
              final tv = _translationNotifier.value;

              // 处理渲染坐标将其框在首个循环位置内
              double renderT = (data.tOffset % _titleSpacing) - _titleSpacing;
              if (renderT <= -_titleSpacing) renderT += _titleSpacing;

              double renderB = (data.bOffset % _bgPatternWidth) - _bgPatternWidth;
              if (renderB <= -_bgPatternWidth) renderB += _bgPatternWidth;

              // 入场动画各层独立偏移量
              final double bgEntryOffset = tv * 900 * 0.8;
              final double titleEntryOffset = tv * 1520 * 0.8;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景图层平铺（入场偏移 900 * 0.8）
                  Positioned(
                    left: 0,
                    top: 0,
                    width: _bgPatternWidth * 4,
                    height: parentHeight,
                    child: Transform.translate(
                      offset: Offset(bgEntryOffset, 0),
                      child: Stack(clipBehavior: Clip.none, children: [
                        for (int i = 0; i < 4; i++)
                          Positioned(
                            left: renderB + i * _bgPatternWidth,
                            top: 0,
                            width: _bgPatternWidth,
                            height: parentHeight,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.1),
                                BlendMode.darken,
                              ),
                              child: Image.asset(
                                'images/IMG_0023.PNG',
                                fit: BoxFit.cover,
                                alignment: Alignment.topLeft,
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),

                  // 大标题层平铺（入场偏移 1520 * 0.8）
                  Positioned(
                    top: -30,
                    left: 0,
                    height: 150,
                    right: -2000,
                    child: Transform.translate(
                      offset: Offset(titleEntryOffset, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < 2; i++)
                            Positioned(
                              left: renderT + i * _titleSpacing + 20,
                              top: 0,
                              child: const SizedBox(
                                width: _titleContainerWidth,
                                child: Text(
                                  'photos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w200,
                                    fontSize: 120,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 2. 避免列表本身的重复构建，采用中心切分的双向无限ScrollView（入场偏移 1200 * 0.8）
        Positioned(
          top: 140,
          left: 0,
          bottom: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _translationNotifier,
            builder: (context, tv, child) => Transform.translate(
              offset: Offset(tv * 1200 * 0.8, 0),
              child: child,
            ),
            child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  _isDragging = true;
                  _isBallistic = false;
                }
              } else if (notification is UserScrollNotification) {
                if (notification.direction == ScrollDirection.idle) {
                  _isDragging = false;
                } else {
                  _isDragging = true;
                  _isBallistic = false;
                }
              } else if (notification is ScrollEndNotification) {
                _isBallistic = false;
                _isDragging = false;
                double S = notification.metrics.pixels;
                _parallaxNotifier.value = ParallaxData(
                  _getIdealT(S, parentWidth),
                  _getIdealB(S, parentWidth),
                );
              } else if (notification is ScrollUpdateNotification) {
                double dx = notification.scrollDelta ?? 0.0;
                if (_isDragging && !_isBallistic) {
                  double newT = _parallaxNotifier.value.tOffset - dx / 4.0;
                  double newB = _parallaxNotifier.value.bOffset - dx / 3.0;
                  _parallaxNotifier.value = ParallaxData(newT, newB);
                } else if (_isBallistic) {
                  double S = notification.metrics.pixels;
                  double distance = _targetS - _releaseS;
                  double p =
                      distance.abs() > 0.001 ? (S - _releaseS) / distance : 1.0;
                  double idealT = _getIdealT(_targetS, parentWidth);
                  double idealB = _getIdealB(_targetS, parentWidth);

                  _parallaxNotifier.value = ParallaxData(
                    _releaseT + p * (idealT - _releaseT),
                    _releaseB + p * (idealB - _releaseB),
                  );
                }
              }
              return false; // 允许冒泡不阻断
            },
            child: CustomScrollView(
              clipBehavior: Clip.none,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              center: const ValueKey('center_sliver'),
              physics: PanoramaScrollPhysics(
                snapPoints: _snapPoints,
                cycleLength: _cycleLength,
                isInfinite: isInfinite,
                onTargetCalculated: (target) {
                  _targetS = target;
                  _releaseS = _scrollController.position.pixels;
                  _releaseT = _parallaxNotifier.value.tOffset;
                  _releaseB = _parallaxNotifier.value.bOffset;
                  _isBallistic = true;
                },
              ),
              slivers: [
                if (isInfinite)
                  // 向前滚动时（向左扫，展现左侧视图）使用的反向列表
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        int realIndex =
                            (_items.length - 1 - (index % _items.length)) %
                                _items.length;
                        return _buildItemWidget(_items[realIndex]);
                      },
                    ),
                  ),
                // 初始化默认从这里0开始向后构建
                SliverList(
                  key: const ValueKey('center_sliver'),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      int realIndex =
                          isInfinite ? index % _items.length : index;
                      return _buildItemWidget(_items[realIndex]);
                    },
                    childCount: isInfinite ? null : _items.length,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),

        // 3. 左侧前一页的"影子"渲染层
        //    始终定位于屏幕左侧之外，3D 旋转期间自然透过 Transform 漏出，
        //    正常静止状态超出屏幕范围不可见（Stack clipBehavior: Clip.none 保证不裁剪）
        if (_items.isNotEmpty)
          Positioned(
            top: 140,
            left: 0,
            width: _items.last.width,
            bottom: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _translationNotifier,
              builder: (context, tv, child) => Transform.translate(
                offset: Offset(tv * 1200 * 0.8 - _items.last.width, 0),
                child: child!,
              ),
              child: _buildItemWidget(_items.last),
            ),
          ),

        // 4. 测试用浮动按钮
        Positioned(
          bottom: 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetroButton(
                onTap: () async {
                  _rotationController.reset();
                  _translationController.reset();
                  _rotationController.forward();
                  _translationController.forward();
                },
                child: const Text('replay'),
              ),
              const SizedBox(height: 10),
              MetroButton(
                onTap: () {
                  Navigator.maybePop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemWidget(MetroPanoramaItem item) {
    return Container(
      color: Colors.transparent,
      width: item.width,
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 50,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: item.child),
        ],
      ),
    );
  }
}

class DelegatedTransition {
  final Widget Function(
          BuildContext, Animation<double>, Animation<double>, Widget)
      transitionBuilder;
  const DelegatedTransition({required this.transitionBuilder});
}
