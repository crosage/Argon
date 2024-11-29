import 'package:process_run/process_run.dart';

Future<void> runPythonScript(String scriptPath, int tabIndex) async {
  final shell = Shell(); // 使用Shell来执行命令
  String outputText = ''; // 用于存储脚本输出的文本

  try {
    // 执行Python脚本，并获取执行结果
    var result = await shell.run('python3 $scriptPath');
    outputText = result.join("\n"); // 将结果合并为一个字符串
  } catch (e) {
    outputText = '执行脚本时出错: $e'; // 捕获异常并输出错误信息
  }

  // 更新界面，显示脚本的输出
  // 此部分可以通过调用相应的状态更新方法来更新UI（如果需要）
}
