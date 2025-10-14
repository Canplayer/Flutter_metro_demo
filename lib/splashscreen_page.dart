import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_demo/widgets/metro_spinner.dart';
import 'package:metro_ui/animated_widgets.dart';
import 'package:metro_demo/launcher.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';

/// 艺术化文字展示页面
class ArtisticTextPage extends StatefulWidget {
  const ArtisticTextPage({super.key});

  @override
  State<ArtisticTextPage> createState() => _ArtisticTextPageState();
}

class _ArtisticTextPageState extends State<ArtisticTextPage>
    with TickerProviderStateMixin {
  final GlobalKey<MetroPageScaffoldState> _scaffoldKey =
      GlobalKey<MetroPageScaffoldState>();

  //logo controllers
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  //text1 controllers
  late AnimationController _text1Controller;
  late Animation<double> _text1Animation;

  //text2 controllers
  late AnimationController _text2Controller;
  late Animation<double> _text2Animation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoAnimation = Tween<double>(begin: 1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: MetroCurves.normalPageRotateIn,
      ),
    );

    _text1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _text1Animation = Tween<double>(begin: 1, end: 0.0).animate(
      CurvedAnimation(
        parent: _text1Controller,
        curve: MetroCurves.normalPageRotateIn,
      ),
    );

    _text2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _text2Animation = Tween<double>(begin: 1, end: 0.0).animate(
      CurvedAnimation(
        parent: _text2Controller,
        curve: MetroCurves.normalPageRotateIn,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });

    //倒计时2秒后跳转到launcher
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
      // 在这里延迟跳转
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // 确保组件还在树中
          jumpToLauncher();
        }
      });
    });
  }

  void jumpToLauncher() {
    metroPagePush(
      context,
      scaffoldKey: _scaffoldKey,
      MetroPageRoute(
        builder: (context) {
          return const MyHomePage(title: 'Flutter Demo Home Page');
        },
      ),
    );
  }

  void _startAnimations() async {
    _logoController.forward();
    _text1Controller.forward();
    _text2Controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      key: _scaffoldKey,
      body: Center(
        child:
            //3DY轴旋转动画

            SizedBox(
          width: 330,
          height: 128,
          // color: Colors.grey.shade300,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 90,
                top: -15,
                child: AnimatedBuilder(
                  animation: _text1Animation,
                  builder: (context, child) {
                    return LeftEdgeRotateAnimation(
                      //-90度
                      rotation: 3.1416 / 180 * -65 * _text1Animation.value,
                      child: Transform(
                        transform: Matrix4.translationValues(
                            100 * _text1Animation.value, 0, 0),
                        child: const Text(
                          'Flumetro',
                          style: TextStyle(
                            fontSize: 66,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -3.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 90,
                top: 45,
                child: AnimatedBuilder(
                  animation: _text2Animation,
                  builder: (context, child) {
                    return LeftEdgeRotateAnimation(
                      rotation: 3.1416 / 180 * -180 * _text2Animation.value,
                      child: Transform(
                        transform: Matrix4.translationValues(
                            400 * _text2Animation.value, 0, 0),
                        child: const SizedBox(
                          width: 200,
                          height: 80,
                          child: const Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 66,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -3.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              //一个80x80的红色矩形，中间一个icon
              Positioned(
                child: AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return LeftEdgeRotateAnimation(
                      rotation: 3.1416 / 180 * -20 * _logoAnimation.value,
                      child: Transform(
                        transform: Matrix4.translationValues(
                            60 * _logoAnimation.value, 0, 0),
                        child: Container(
                          width: 73.6,
                          height: 73.6,
                          color: const Color.fromARGB(255, 229, 20, 0),
                          child: Center(
                            child: SvgPicture.asset(
                              height: 50,
                              width: 50,
                              'images/icons/flutter.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              bottom: -50,
              left: 0,
              right: 0,
              child: MetroSpinner(),),
            ],
          ),
        ),
      ),
    );
  }
}
