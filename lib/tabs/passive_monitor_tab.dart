import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:io';

class ScriptExecutionTab extends StatefulWidget {
  final int index;
  ScriptExecutionTab({Key? key, required this.index}) : super(key: key);

  @override
  _ScriptExecutionTabState createState() => _ScriptExecutionTabState();
}

class _ScriptExecutionTabState extends State<ScriptExecutionTab> with AutomaticKeepAliveClientMixin<ScriptExecutionTab> {
  TextEditingController arg1Controller = TextEditingController();
  TextEditingController arg2Controller = TextEditingController();
  String commandOutput = "等待输出...";

  void updateCommandOutput(String output) {
    setState(() {
      commandOutput += output;
    });
  }

  Future<void> runScript(String arg1, String arg2) async {
    try {
      String scriptPath = 'D:\\code\\dns\\lib\\python_scripts\\passive_monitoring\\passive.py';

      Process process = await Process.start(
        'python',
        [
          scriptPath,
          arg1,
          '-o', arg2,
        ],
        runInShell: true,
        environment: {
          'PYTHONUNBUFFERED': '1',
        },
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        updateCommandOutput(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        updateCommandOutput("[Error]: $data");
      });

      int exitCode = await process.exitCode;
      if (exitCode == 0) {
        updateCommandOutput("[Script Finished Successfully]");
      } else {
        updateCommandOutput("[Script Failed with exit code $exitCode]");
      }

    } catch (e) {
      updateCommandOutput("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // 输入框
              TextBox(
                controller: arg1Controller,
                placeholder: '请输入网络接口',
              ),
              SizedBox(height: 5),
              TextBox(
                controller: arg2Controller,
                placeholder: '请输入保存路径',
              ),
              SizedBox(height: 5),

              FilledButton(
                onPressed: () {
                  String arg1 = arg1Controller.text;
                  String arg2 = arg2Controller.text;
                  print("运行脚本");
                  runScript(arg1, arg2);
                },
                child: Text('运行脚本'),
              ),
              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(10),
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[10],
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    commandOutput,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
