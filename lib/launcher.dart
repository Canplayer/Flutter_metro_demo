import 'package:flutter/material.dart';
import 'package:metro_demo/animated_widgets.dart';
import 'package:metro_demo/panorama_page.dart';
import 'package:metro_demo/phoneapplication_page.dart';
import 'package:metro_demo/splashscreen_page.dart';
import 'package:metro_demo/switch_demo_page.dart';
import 'package:metro_ui/button.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/tile.dart';

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

  List<App> apps = [
    App(name: 'Panorama', icon: Icons.map, page: const PanoramaPage()),
    App(name: 'About', icon: Icons.email, page: const PhoneApplicationPage()),
    App(name: 'Switch Demo', icon: Icons.toggle_on, page: const SwitchDemoPage()),
    App(name: 'Splash Screen', icon: Icons.star, page: const ArtisticTextPage()),
    App(name: 'Camera', icon: Icons.camera, page: const PanoramaPage()),
    App(name: 'Calendar', icon: Icons.calendar_today, page: const PanoramaPage()),
    App(name: 'Clock', icon: Icons.access_time, page: const PanoramaPage()),
    App(name: 'Music', icon: Icons.music_note, page: const PanoramaPage()),
    App(name: 'People', icon: Icons.people, page: const PanoramaPage()),
    App(name: 'Weather', icon: Icons.wb_sunny, page: const PanoramaPage()),
    App(name: 'Store', icon: Icons.store, page: const PanoramaPage()),
    App(name: 'News', icon: Icons.article, page: const PanoramaPage()),
    App(name: 'Photos', icon: Icons.photo, page: const PanoramaPage()),
    App(name: 'Videos', icon: Icons.video_collection, page: const PanoramaPage()),
    App(name: 'Settings', icon: Icons.settings, page: const PanoramaPage()),
    App(name: 'Wallet', icon: Icons.account_balance_wallet, page: const PanoramaPage()),
    App(name: 'Calculator', icon: Icons.calculate, page: const PanoramaPage()),
    App(name: 'Alarms', icon: Icons.alarm, page: const PanoramaPage()),
    App(name: 'Notes', icon: Icons.note, page: const PanoramaPage()),
    App(name: 'Reminders', icon: Icons.notifications, page: const PanoramaPage()),
    App(name: 'Tasks', icon: Icons.task, page: const PanoramaPage()),
    App(name: 'Sports', icon: Icons.sports_soccer, page: const PanoramaPage()),
    App(name: 'Health', icon: Icons.favorite, page: const PanoramaPage()),
  ];

  @override
  void initState() {
    super.initState();
    //打印设备屏幕宽度
    


    _keys.addAll(List.generate(apps.length, (index) => GlobalKey()));

    _controllers = List.generate(apps.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 3.1416 / 2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInExpo,
      ));
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        //_isAddPostFrame = true;
      });
    });
  }

  //sync方法
  Future<void> _startAnimations(GlobalKey tapKey) async {
    int thisIndex = 0;

    for (int i = _keys.length - 1; i >= 0; i--) {
      final RenderBox renderBox =
          _keys[i].currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenSize = MediaQuery.of(context).size;
      // 过滤掉不在屏幕内的元素
      if (position.dx + size.width > 0 &&
          position.dx < screenSize.width &&
          position.dy + size.height > 0 &&
          position.dy < screenSize.height) {
        if (_keys[i] == tapKey) {
          thisIndex = i;
          continue;
        }
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    _controllers[thisIndex].forward();

    //结束await后执行动画重置
    await Future.delayed(const Duration(milliseconds: 500));
      for (var controller in _controllers) {
        controller.reset();
      }
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      onDidPushNext: <T>(T data) async {
        //如果arguments存在arguments是int类型
        if (data is int) {
          await _startAnimations(_keys[data]);
        }
      },
      
      body: Column(
        children: [
          const SizedBox(height: 80),
          MetroButton(
            child: const Text('Welcome to my demo'),
            onTap: () {
              //打印屏幕尺寸
              debugPrint(MediaQuery.of(context).size.toString());
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
                  spacing: 9,
                  runSpacing: 9,
                  clipBehavior: Clip.none,
                  children: apps.map((App app) {
                    int index = apps.indexOf(app);
                    return AnimatedBuilder(
                      animation: _animations[index],
                      builder: (context, child) {
                        return LeftEdgeRotateAnimation(
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
                                        size: 100,
                                        color: Colors.white,
                                      ),
                                    ),
                                    //文字：左下角
                                    Positioned(
                                      left: 10,
                                      bottom: 10,
                                      child: Text(
                                        app.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ],
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

