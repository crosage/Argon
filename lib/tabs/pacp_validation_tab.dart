import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:io';

class PcapValidationTab extends StatefulWidget {
  final int index;
  PcapValidationTab({Key? key, required this.index}) : super(key: key);

  @override
  _PcapValidationTabState createState() => _PcapValidationTabState();
}

class _PcapValidationTabState extends State<PcapValidationTab> with AutomaticKeepAliveClientMixin<PcapValidationTab> {
  TextEditingController folderController = TextEditingController();
  String commandOutput = "等待输出...";

  void updateCommandOutput(String output) {
    setState(() {
      commandOutput += output;
    });
  }

  Future<void> runPcapValidationScript(String folderPath) async {
    try {
      Process process = await Process.start(
        'python',
        [
          "D:\\code\\dns\\lib\\python_scripts\\cross_validate\\cross_validate.py",
          folderPath,
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
    super.build(context); // 需要调用super.build(context)
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              TextBox(
                controller: folderController,
                placeholder: '请输入pcap文件夹路径',
              ),
              SizedBox(height: 5),
              FilledButton(
                onPressed: () {
                  String folderPath = folderController.text;
                  print("运行脚本");
                  runPcapValidationScript(folderPath);
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
