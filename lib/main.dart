// 导入Flutter的基础UI组件包
import 'package:flutter/widgets.dart';
// 导入自定义的引导启动文件（假设在hiddify包中）
import 'package:hiddify/bootstrap.dart';
// 导入环境配置文件
import 'package:hiddify/core/model/environment.dart';

// 应用程序的主入口函数
void main() async {
  // 确保Flutter的Widgets绑定已初始化
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 调用自定义的启动函数lazyBootstrap，传递初始化的Widgets绑定和开发环境配置
  return lazyBootstrap(widgetsBinding, Environment.dev);
}
