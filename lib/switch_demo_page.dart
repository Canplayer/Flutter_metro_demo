import 'package:flutter/material.dart';
import 'package:metro_ui/switcher.dart';
import 'package:metro_ui/button.dart';
import 'package:metro_ui/page_scaffold.dart';

class SwitchDemoPage extends StatefulWidget {
  const SwitchDemoPage({Key? key}) : super(key: key);

  @override
  State<SwitchDemoPage> createState() => _SwitchDemoPageState();
}

class _SwitchDemoPageState extends State<SwitchDemoPage> {
  bool _switch1Value = false;
  bool _switch2Value = true;
  bool _switch3Value = false;

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      //backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自定义 Switch 控件演示',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              
              // 第一个开关
              Row(
                children: [
                  const Text(
                    '开关 1: ',
                    style: TextStyle(fontSize: 18),
                  ),
                  CustomSwitch(
                    value: _switch1Value,
                    onChanged: (value) {
                      setState(() {
                        _switch1Value = value;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _switch1Value ? '开启' : '关闭',
                    style: TextStyle(
                      fontSize: 16,
                      color: _switch1Value ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // 第二个开关
              Row(
                children: [
                  const Text(
                    '开关 2: ',
                    style: TextStyle(fontSize: 18),
                  ),
                  CustomSwitch(
                    value: _switch2Value,
                    onChanged: (value) {
                      setState(() {
                        _switch2Value = value;
                      });
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.blueGrey,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _switch2Value ? '开启' : '关闭',
                    style: TextStyle(
                      fontSize: 16,
                      color: _switch2Value ? Colors.green : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // 第三个开关 - 禁用状态
              Row(
                children: [
                  const Text(
                    '开关 3 (禁用): ',
                    style: TextStyle(fontSize: 18),
                  ),
                  CustomSwitch(
                    value: _switch3Value,
                    onChanged: null, // 禁用状态
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _switch3Value ? '开启' : '关闭',
                    style: const TextStyle(
                      fontSize: 16
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 50),
              
              const Text(
                '使用说明:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '• 点击控件可以切换开关状态\n'
                '• 拖动白色滑块可以手动控制\n'
                '• 拖动超过中点松手会自动滑到对应位置\n'
                '• 支持自定义激活和非激活状态的颜色',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              // 返回按钮
              Center(
                child: MetroButton(
                  onTap: () {
                    Navigator.of(context).maybePop();
                  },
                  child: const Text(
                    '返回',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}