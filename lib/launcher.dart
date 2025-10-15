import 'package:flutter/material.dart';
import 'package:metro_demo/pages/about_page.dart';
import 'package:metro_demo/pages/spinner_demo_page.dart';
import 'package:metro_ui/animated_widgets.dart';
import 'package:metro_demo/pages/panorama_page.dart';
import 'package:metro_demo/pages/phoneapplication_page.dart';
import 'package:metro_demo/splashscreen_page.dart';
import 'package:metro_demo/pages/switch_demo_page.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/tile.dart';

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

  List<App> apps = [
    App(name: 'Panorama', icon: Icons.map, page: const PanoramaPage()),
    App(name: 'PhoneApplication', icon: Icons.android, page: const PhoneApplicationPage()),
    App(
        name: 'Switch Demo',
        icon: Icons.toggle_on,
        page: const SwitchDemoPage()),
    App(
        name: 'Splash Screen',
        icon: Icons.star,
        page: const ArtisticTextPage()),
    App(
        name: 'Fake GSM Network',
        icon: Icons.phone,
        page: const PanoramaPage()),
    App(
        name: 'SpinnerDemoPage',
        icon: Icons.calendar_today,
        page: const SpinnerDemoPage()),
    App(name: 'About', icon: Icons.abc_outlined, page: const AboutPage()),
    App(name: 'Music', icon: Icons.music_note, page: const PanoramaPage()),
    App(name: 'People', icon: Icons.people, page: const PanoramaPage()),
    App(name: 'Weather', icon: Icons.wb_sunny, page: const PanoramaPage()),
    App(name: 'Store', icon: Icons.store, page: const PanoramaPage()),
    App(name: 'News', icon: Icons.article, page: const PanoramaPage()),
    App(name: 'Photos', icon: Icons.photo, page: const PanoramaPage()),
    App(
        name: 'Videos',
        icon: Icons.video_collection,
        page: const PanoramaPage()),
    App(name: 'Settings', icon: Icons.settings, page: const PanoramaPage()),
    App(
        name: 'Wallet',
        icon: Icons.account_balance_wallet,
        page: const PanoramaPage()),
    App(name: 'Calculator', icon: Icons.calculate, page: const PanoramaPage()),
    App(name: 'Alarms', icon: Icons.alarm, page: const PanoramaPage()),
    App(name: 'Notes', icon: Icons.note, page: const PanoramaPage()),
    App(
        name: 'Reminders',
        icon: Icons.notifications,
        page: const PanoramaPage()),
    App(name: 'Tasks', icon: Icons.task, page: const PanoramaPage()),
    App(name: 'Sports', icon: Icons.sports_soccer, page: const PanoramaPage()),
    App(name: 'Health', icon: Icons.favorite, page: const PanoramaPage()),
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
    for (int i = 0; i < _keys.length; i++) {
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
    for (int i = _keys.length - 1; i >= 0; i--) {
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
      for (int i = 0; i < _keys.length; i++) {
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
              duration: Duration(milliseconds: singleTileTime*3),
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
      for (int i = _keys.length - 1; i >= 0; i--) {
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
      for (int i = 0; i < _keys.length; i++) {
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
              duration: Duration(milliseconds: singleTileTime*3),
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
              begin: 3.1416 / 180 * 40,
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
      for (int i = _keys.length - 1; i >= 0; i--) {
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
              _startPushAnimations();
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
                  children: apps.map((App app) {
                    int index = apps.indexOf(app);
                    return AnimatedBuilder(
                      animation: _animations[index],
                      builder: (context, child) {
                        return Opacity(
                          opacity: _tileVisibility[index] ? 1.0 : 0.0, // 控制可见性
                          child: LeftEdgeRotateAnimation(
                            rotation: _animations[index].value,
                            child: SizedBox(
                              key: _keys[index],
                              width: 168,
                              height: 168,
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
                                child: Container(
                                  color: Theme.of(context).colorScheme.primary,
                                  child:
                                      //分层布局
                                      Stack(
                                    children: [
                                      //图标：居中
                                      Center(
                                        child: Icon(
                                          app.icon,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                      //文字：左下角
                                      Positioned(
                                        left: 10,
                                        bottom: 6,
                                        child: Text(
                                          app.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
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
  IconData icon;
  Widget page;
  App({required this.name, required this.icon, required this.page});
}
