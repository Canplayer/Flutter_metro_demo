import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:metro_demo/pages/about_page.dart';
import 'package:metro_demo/pages/safearea.dart';
import 'package:metro_demo/pages/spinner_demo_page.dart';
import 'package:metro_ui/animated_widgets.dart';
import 'package:metro_demo/pages/panorama_page.dart';
import 'package:metro_demo/splashscreen_page.dart';
import 'package:metro_demo/pages/switch_demo_page.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/context_menu.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final List<GlobalKey> _keys = [];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<bool> _tileVisibility; // 控制每个 tile 的可见性

  final int pushTime = 350; //非被点击的Tile总飞出时间
  final int singleTileTime = 150; //单个Tile飞出时间

  int _testIndex = 0;

  List<App> get apps => [
        App(
            name: 'Panorama',
            tile: LiveTile(
              size: LiveTileSize.medium,
              flipStyle: FlipStyle.elastic,
              name: const Text('Panorama'),
              children: [
                MetroAppTile(
                  icon: const Icon(
                    Icons.map,
                    size: 70,
                  ),
                  count: _testIndex,
                ),
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Panorama Hub页面，具有浓郁的WP特色',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            page: const PanoramaPage()),
        App(
          name: 'NormalPage',
          tile: const LiveTile(
            size: LiveTileSize.medium,
            flipStyle: FlipStyle.elastic,
            name: Text('Normal Page'),
            children: [
              MetroAppTile(
                icon: Icon(
                  Icons.file_copy,
                  size: 70,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  '普通带有标题副标题的页面',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          page: const AboutPage(),
        ),
        App(
            name: 'Switcher',
            tile: const LiveTile(
              size: LiveTileSize.medium,
              flipStyle: FlipStyle.elastic,
              name: Text('Switcher'),
              children: [
                MetroAppTile(
                  icon: Icon(
                    Icons.toggle_on,
                    size: 70,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    '开关组件演示',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            page: const SwitchDemoPage()),
        App(
            name: 'Splash Screen',
            tile: const LiveTile(
              size: LiveTileSize.medium,
              flipStyle: FlipStyle.elastic,
              name: Text('Splash Screen'),
              children: [
                MetroAppTile(
                  icon: Icon(
                    Icons.star,
                    size: 70,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    '开屏页面再走一次',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            page: const ArtisticTextPage()),
        App(
            name: 'SpinnerDemoPage',
            tile: const LiveTile(
              size: LiveTileSize.medium,
              flipStyle: FlipStyle.elastic,
              name: Text('Spinner'),
              children: [
                MetroAppTile(
                  icon: Icon(
                    Icons.refresh,
                    size: 70,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Metro风格的加载动画',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            page: const SpinnerDemoPage()),
        App(
            name: 'SafeArea Tester',
            tile: const LiveTile(
              size: LiveTileSize.medium,
              flipStyle: FlipStyle.elastic,
              name: Text('SafeArea Tester'),
              children: [
                MetroAppTile(
                  icon: Icon(
                    Icons.fullscreen,
                    size: 70,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'SafeArea适配测试',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            page: const SafeAreaPage()),
      ];

  @override
  void initState() {
    super.initState();
    //打印设备屏幕宽度

    _keys.addAll(List.generate(apps.length, (index) => GlobalKey()));

    _tileVisibility =
        List.generate(apps.length, (index) => false); // 初始化所有 tile 为可见

    _controllers = List.generate(apps.length, (index) {
      return AnimationController(
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));
    }).toList();

    //下一帧
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _startPushAnimations();
    // });

    //_startPushAnimations();
  }

  /// 判断组件是否在屏幕可见范围内
  ///
  /// [key] 要检查的 GlobalKey
  /// 返回 true 表示组件可见，false 表示不可见
  bool _isWidgetVisible(GlobalKey key) {
    //return true;
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return false;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    return position.dx + size.width > 0 &&
        position.dx < screenSize.width &&
        position.dy + size.height > 0 &&
        position.dy < screenSize.height;
  }

  Future<void> _startPushNextAnimations(GlobalKey tapKey) async {
    // 找出所有可见的元素索引
    final List<int> visibleIndices = [];
    for (int i = 0; i < apps.length; i++) {
      if (_isWidgetVisible(_keys[i])) {
        visibleIndices.add(i);
      }
    }

    setState(() {
      _controllers = List.generate(apps.length, (index) {
        // 只为可见元素创建真正的控制器
        if (visibleIndices.contains(index)) {
          return AnimationController(
            duration: Duration(milliseconds: singleTileTime),
            vsync: this,
          );
        } else {
          // 不可见元素创建空控制器
          return AnimationController(vsync: this);
        }
      });

      _animations = _controllers.asMap().entries.map((entry) {
        int index = entry.key;
        AnimationController controller = entry.value;

        // 只为可见元素创建真正的动画
        if (visibleIndices.contains(index)) {
          return Tween<double>(
            begin: 0.0,
            end: 3.1416 / 2,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: MetroCurves.normalPageRotateOut,
          ));
        } else {
          // 不可见元素创建空动画
          return Tween<double>(
            begin: 0.0,
            end: 0.0,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.linear,
          ));
        }
      }).toList();
    });

    int thisIndex = 0;
    final int visibleTilesCount = visibleIndices.length;

    // 计算每个元素之间的延迟时间
    final int delayTime =
        ((pushTime - singleTileTime) / (visibleTilesCount - 1)).round();

    // 执行动画（只对可见元素）
    for (int i = apps.length - 1; i >= 0; i--) {
      if (visibleIndices.contains(i)) {
        if (_keys[i] == tapKey) {
          thisIndex = i;
          continue;
        }
        _controllers[i].forward();
        await Future.delayed(Duration(milliseconds: delayTime));
      }
    }

    await Future.delayed(Duration(milliseconds: delayTime * 2));
    _controllers[thisIndex].forward();

    //结束await后执行动画重置
    await Future.delayed(Duration(milliseconds: singleTileTime));
    for (var controller in _controllers) {
      controller.reset();
      //透明度设置为0
      setState(() {
        _tileVisibility = List.generate(apps.length, (index) => false);
      });
    }
  }

  Future<void> _startPushAnimations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 找出所有可见的元素索引
      final List<int> visibleIndices = [];
      for (int i = 0; i < apps.length; i++) {
        if (_isWidgetVisible(_keys[i])) {
          visibleIndices.add(i);
        } else {
          _tileVisibility[i] = true;
        }
      }

      setState(() {
        for (int i in visibleIndices) {
          _tileVisibility[i] = false;
        }
        _controllers = List.generate(apps.length, (index) {
          // 只为可见元素创建真正的控制器
          if (visibleIndices.contains(index)) {
            return AnimationController(
              duration: Duration(milliseconds: singleTileTime * 3),
              vsync: this,
            );
          } else {
            // 不可见元素创建空控制器
            return AnimationController(vsync: this);
          }
        });

        _animations = _controllers.asMap().entries.map((entry) {
          int index = entry.key;
          AnimationController controller = entry.value;

          // 只为可见元素创建真正的动画
          if (visibleIndices.contains(index)) {
            return Tween<double>(
              begin: -3.1416 / 180 * 65,
              end: 0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          } else {
            // 不可见元素创建空动画
            return Tween<double>(
              begin: 0.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          }
        }).toList();
      });

      final int visibleTilesCount = visibleIndices.length;

      // 计算每个元素之间的延迟时间
      final int delayTime =
          ((pushTime - singleTileTime) / (visibleTilesCount - 1)).round();

      // 执行动画（只对可见元素）
      for (int i = apps.length - 1; i >= 0; i--) {
        if (visibleIndices.contains(i)) {
          setState(() {
            _tileVisibility[i] = true; // 动画开始前直接显示
          });
          _controllers[i].forward();
          await Future.delayed(Duration(milliseconds: delayTime));
        }
      }
    });
  }

  Future<void> _startPopNextAnimations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 找出所有可见的元素索引
      final List<int> visibleIndices = [];
      for (int i = 0; i < apps.length; i++) {
        if (_isWidgetVisible(_keys[i])) {
          visibleIndices.add(i);
        } else {
          _tileVisibility[i] = true;
        }
      }

      setState(() {
        for (int i in visibleIndices) {
          _tileVisibility[i] = false;
        }
        _controllers = List.generate(apps.length, (index) {
          // 只为可见元素创建真正的控制器
          if (visibleIndices.contains(index)) {
            return AnimationController(
              duration: Duration(milliseconds: singleTileTime * 3),
              vsync: this,
            );
          } else {
            // 不可见元素创建空控制器
            return AnimationController(vsync: this);
          }
        });

        _animations = _controllers.asMap().entries.map((entry) {
          int index = entry.key;
          AnimationController controller = entry.value;

          // 只为可见元素创建真正的动画
          if (visibleIndices.contains(index)) {
            return Tween<double>(
              begin: 3.1416 / 180 * 50,
              end: 0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          } else {
            // 不可见元素创建空动画
            return Tween<double>(
              begin: 0.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          }
        }).toList();
      });

      final int visibleTilesCount = visibleIndices.length;

      // 计算每个元素之间的延迟时间
      final int delayTime =
          ((pushTime - singleTileTime) / visibleTilesCount).round();

      // 执行动画（只对可见元素）
      for (int i = apps.length - 1; i >= 0; i--) {
        if (visibleIndices.contains(i)) {
          setState(() {
            _tileVisibility[i] = true; // 动画开始前直接显示
          });
          _controllers[i].forward();
          await Future.delayed(Duration(milliseconds: delayTime));
        }
      }
    });
  }

  //Future<void> _start

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      onDidPushNext: <T>(T data) async {
        //如果arguments存在arguments是int类型
        if (data is int) {
          await _startPushNextAnimations(_keys[data]);
        }
      },
      onDidPush: () async {
        await _startPushAnimations();
      },
      onDidPopNext: () async {
        //print("object");
        await _startPopNextAnimations();
      },
      onDidPop: () async {
        print("object2");
        //await _startPushAnimations();
      },
      body: Column(
        children: [
          const SizedBox(height: 80),
          MetroButton(
            child: const Text('Welcome to my demo'),
            onTap: () {
              //打印屏幕尺寸
              print(MediaQuery.of(context).size.toString());
              //_startPushAnimations();
              setState(() {
                _testIndex++;
              });
            },
          ),

          //TextButton(onPressed: (){}, child: Text('123')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20),
              clipBehavior: Clip.none,
              child: Center(
                //padding: const EdgeInsets.all(20),
                child: Wrap(
                    spacing: 9.6,
                    runSpacing: 9.6,
                    clipBehavior: Clip.none,
                    children: [
                      ...apps.asMap().entries.map((entry) {
                        int index = entry.key;
                        App app = entry.value;
                        return AnimatedBuilder(
                          animation: _animations[index],
                          builder: (context, child) {
                            return Opacity(
                              opacity:
                                  _tileVisibility[index] ? 1.0 : 0.0, // 控制可见性
                              child: LeftEdgeRotateAnimation(
                                rotation: _animations[index].value,
                                child: SizedBox(
                                    key: _keys[index],
                                    width: 168,
                                    height: 168,
                                    child: MetroContextMenu(
                                      menu: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          MetroContextMenuItem(
                                            onTap: () => print('Pin to start'),
                                            child: const Text('pin to start'),
                                          ),
                                          MetroContextMenuItem(
                                            onTap: () => print('Pin to start'),
                                            child: const Text('pin to start'),
                                          ),
                                        ],
                                      ),
                                      child: Tile(
                                        allowBack: true,
                                        onTap: () {
                                          metroPagePush(
                                            context,
                                            MetroPageRoute(
                                              builder: (context) {
                                                return app.page;
                                              },
                                            ),
                                            //提供一种便利的方法，可以将范型参数传递给onDidPushNext，主要设计目的是为了方便动画传参
                                            //例如：Windows Phone中，被点击的Tile往往是最后一个飞出的，可能需要把Tile的index传递过去，然后在onDidPushNext中处理动画
                                            dataToPass: index,
                                          );
                                        },
                                        child: app.tile,
                                      ),
                                    )),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class App {
  //储存名字、图标、路由
  String name;
  LiveTile tile;
  Widget page;
  App({required this.name, required this.tile, required this.page});
}

//动态磁贴
enum LiveTileSize { small, medium, wide }

enum FlipStyle { normal, elastic }

class LiveTile extends StatefulWidget {
  final List<Widget> children;
  final LiveTileSize size;
  final Widget? name;
  final FlipStyle flipStyle;

  const LiveTile({
    super.key,
    required this.children,
    this.name,
    this.size = LiveTileSize.medium,
    this.flipStyle = FlipStyle.normal,
  });

  @override
  State<LiveTile> createState() => _LiveTileState();
}

class _LiveTileState extends State<LiveTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _setupAnimation();
    _startTimer();
  }

  void _setupAnimation() {
    final curve = widget.flipStyle == FlipStyle.elastic
        ? Curves.elasticOut
        : Curves.easeInOut;

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    // 生成一个 3.0 到 6.0 之间的随机浮点数
    final double randomSeconds = 3.0 + math.Random().nextDouble() * 3.0;
    _timer =
        Timer(Duration(milliseconds: (randomSeconds * 1000).round()), _flip);
  }

  void _flip() async {
    if (!mounted) return;
    await _controller.forward();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.children.length;
    });
    _controller.reset();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipStyle != widget.flipStyle) {
      _setupAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    switch (widget.size) {
      case LiveTileSize.small:
        width = 80;
        height = 80;
        break;
      case LiveTileSize.medium:
        width = 168;
        height = 168;
        break;
      case LiveTileSize.wide:
        width = 345.6; // 168 * 2 + 9.6
        height = 168;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double rotationValue = _animation.value * math.pi;
          final bool showBack = rotationValue > math.pi / 2;
          final int nextIndex = (_currentIndex + 1) % widget.children.length;

          return Stack(fit: StackFit.expand, children: [
            ...List.generate(widget.children.length, (index) {
              bool isVisibleFace = false;
              Matrix4 transform = Matrix4.identity();

              if (index == _currentIndex && !showBack) {
                isVisibleFace = true;
                transform.rotateX(rotationValue);
              } else if (index == nextIndex && showBack) {
                isVisibleFace = true;
                transform.rotateX(rotationValue);
                transform.rotateX(math.pi);
              }

              return Offstage(
                offstage: !isVisibleFace,
                child: Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Stack(
                      children: [
                        widget.children[index],
                        if (widget.name != null)
                          Positioned(
                            left: 10,
                            bottom: 6,
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              child: widget.name!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

//普通磁贴模板
class MetroAppTile extends StatefulWidget {
  final Widget icon;
  final int? count;
  final Color? backgroundColor;

  const MetroAppTile({
    super.key,
    required this.icon,
    this.count,
    this.backgroundColor,
  });

  @override
  State<MetroAppTile> createState() => _MetroAppTileState();
}

class _MetroAppTileState extends State<MetroAppTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  int? _displayCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.count != null) {
      _displayCount = widget.count;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MetroAppTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      if (widget.count != null) {
        setState(() {
          _displayCount = widget.count;
        });
        _controller.reset();
        _controller.forward();
      } else {
        setState(() {
          _displayCount = null;
        });
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
      child:
          // 图标与数字组合：居中
          Center(
        child: Row(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: widget.icon,
            ),
            if (_displayCount != null && _displayCount! > 0) ...[
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(_rotationAnimation.value * math.pi),
                    child: Text(
                      '$_displayCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      // 标题：左下角
    );
  }
}
