import 'package:flutter/material.dart';
import 'package:metro_demo/widgets/metro_spinner.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';

/// Metro Spinner 示例页面
class SpinnerDemoPage extends StatelessWidget {
  const SpinnerDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Metro Spinner Demo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 60),

            // 默认样式
            const Text('默认样式:'),
            const SizedBox(height: 10),
            MetroSpinner(),
            const SizedBox(height: 40),

            // 自定义颜色
            const Text('自定义颜色:'),
            const SizedBox(height: 10),
            const SizedBox(
              width: 300,
              child: MetroSpinner(
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 40),

            // 大尺寸
            const Text('大尺寸:'),
            const SizedBox(height: 10),
            const SizedBox(
              width: 400,
              child: MetroSpinner(
                dotSize: 4.0,
                spacing: 8.0,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 40),

            // 快速动画
            const Text('快速动画:'),
            const SizedBox(height: 10),
            const SizedBox(
              width: 300,
              child: MetroSpinner(
                duration: Duration(milliseconds: 800),
                color: Colors.orange,
              ),
            ),

            const SizedBox(height: 40),

            // 全宽度
            const Text('全宽度:'),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: MetroSpinner(
                color: Colors.red,
              ),
            ),

            MetroButton(
              onTap: () {
                Navigator.maybePop(context);
              },
              child: const Text('返回')
            ),
          ],
        ),
      ),
    );
  }
}
