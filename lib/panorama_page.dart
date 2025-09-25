//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/button.dart';
import 'package:metro_ui/page_scaffold.dart';

//Panorama和Pivot控件
class PanoramaPage extends StatefulWidget {
  const PanoramaPage({super.key});

  @override
  State<PanoramaPage> createState() => _PanoramaPageState();
}

class _PanoramaPageState extends State<PanoramaPage>
    with TickerProviderStateMixin {
  //牙面翻转的角度
  double _rotation = 0;
  //标题距离左边的距离
  double _titleLeft = 0;
  //主体内容距离左边的距离
  double _contentLeft = 0;
  //背景距离左边的距离
  double _backgroundLeft = 0;
  //翻转动画原点距离
  double _pivot = 0;

  //旋转动画控制器
  late AnimationController _rotationController;
  //平移动画控制器
  late AnimationController _translationController;

  //旋转动画
  late Animation<double> _rotationAnimation;
  //平移动画
  late Animation<double> _translationAnimation;

  @override
  void initState() {
    super.initState();
    //初始化旋转动画控制器
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    //初始化平移动画控制器
    _translationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    //旋转动画
    _rotationAnimation = Tween<double>(
      //-90度到0
      begin: -3.1415 * 0.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    //平移动画
    _translationAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _translationController,
      curve: Curves.easeOutCirc,
    ))
      ..addListener(() {
        setState(() {
          _backgroundLeft = _translationAnimation.value * 1200;
          _titleLeft = _translationAnimation.value * 2400;
          _contentLeft = _translationAnimation.value * 1800;
          //_pivot的数值由320到0
          _pivot = _translationAnimation.value * 320;
        });
      });

    //开始旋转动画
    _rotationController.forward();
    //开始平移动画
    _translationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 替换当前路由的动画
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      // onWillPop: () async {
      //   return true; //允许返回
      // },
      onDidPush: () async {
      },
      // onDidPop: () async {
      //   //延长3秒
      //   await Future.delayed(const Duration(milliseconds: 3000));
      // },
      onDidPopNext: () async {
      },
      
      body: Center(
        child: Transform(
          transform: Matrix4.rotationY(_rotationAnimation.value),
          //origin: const Offset(-37.5, 0),
          origin: Offset(-_pivot, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double containerWidth;
              final double parentWidth = constraints.maxWidth;
              final double parentHeight = constraints.maxHeight;

              if (parentWidth > parentHeight) {
                // 当父容器宽度大于高度时，宽度与父容器一致
                containerWidth = parentWidth;
              } else {
                // 否则，宽度允许超出父容器，使其与高度一致（保持正方形）
                containerWidth = parentHeight;
              }
              return OverflowBox(
                maxWidth: 1200,
                maxHeight: parentHeight,
                alignment: Alignment.topLeft,
                child: Stack(
                  children: [
                    // Positioned(
                    //   left: _backgroundLeft,
                    //   top: 0,
                    //   width: containerWidth,
                    //   height: parentHeight,
                    //   child: ColorFiltered(
                    //     colorFilter: ColorFilter.mode(
                    //       Colors.black.withOpacity(0.2), // 透明度越高，图片越暗
                    //       BlendMode.darken, // 使用暗化混合模式
                    //     ),
                    //     child: Image.asset(
                    //       'assets/background.jpg',
                    //       fit: BoxFit.cover,
                    //       alignment: Alignment.topLeft,
                    //     ),
                    //   ),
                    // ),
                    Positioned(
                      left: _titleLeft,
                      top: -30,
                      child: const Text(
                        'photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _contentLeft,
                      top: 140,
                      child: Column(
                        //左对齐
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            ' ',
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 50,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'camera roll',
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'albums',
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'data',
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'people',
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          MetroButton(
                            onTap: () async {
                              //开始旋转动画
                              _rotationController.reverse();
                              //开始平移动画
                              await _translationController.reverse();
                              _rotationController.forward();
                              _translationController.forward();
                            },
                            child: const Text('replay'),
                          ),
                          MetroButton(
                            onTap: () async {
                              //返回页面
                              Navigator.maybePop(context);

                              // Navigator.of(context).replaceRouteBelow(
                              //   anchorRoute: ModalRoute.of(context)!,
                              //   newRoute: MetroSlideRoute(
                              //     builder: (context) => widget,
                              //     isVertical: false,
                              //   ),
                              // );
                              //Navigator.of(context).pop();
                            },
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DelegatedTransition {
  // 定义委托的过渡动画构建器
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) transitionBuilder;

  const DelegatedTransition({required this.transitionBuilder});
}

// class CustomRoute<T> extends PageRoute<T> {
//   final Widget child;
//   final DelegatedTransition? delegatedTransition;

//   CustomRoute({
//     required this.child,
//     this.delegatedTransition,
//   });

//   @override
//   Widget buildTransitions(
//     BuildContext context,
//     Animation<double> animation,
//     Animation<double> secondaryAnimation,
//     Widget child,
//   ) {
//     // 1. 如果有委托的过渡动画，使用委托的构建器
//     if (delegatedTransition != null) {
//       return delegatedTransition!.transitionBuilder(
//         context,
//         animation,
//         secondaryAnimation,
//         child,
//       );
//     }

//     // 2. 否则使用默认过渡动画
//     return FadeTransition(
//       opacity: animation,
//       child: child,
//     );
//   }

//   @override
//   Widget buildPage(BuildContext context, Animation<double> animation,
//           Animation<double> secondaryAnimation) =>
//       child;

//   @override
//   // TODO: implement barrierColor
//   Color? get barrierColor => throw UnimplementedError();

//   @override
//   // TODO: implement barrierLabel
//   String? get barrierLabel => throw UnimplementedError();

//   @override
//   // TODO: implement maintainState
//   bool get maintainState => throw UnimplementedError();

//   @override
//   // TODO: implement transitionDuration
//   Duration get transitionDuration => throw UnimplementedError();
// }
