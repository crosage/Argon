import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:io';

class ActiveDetectionTab extends StatefulWidget {
  final int index;
  ActiveDetectionTab({Key? key, required this.index}) : super(key: key);

  @override
  _ActiveDetectionTabState createState() => _ActiveDetectionTabState();
}

class _ActiveDetectionTabState extends State<ActiveDetectionTab> with AutomaticKeepAliveClientMixin<ActiveDetectionTab> {
  TextEditingController interfaceController = TextEditingController();
  TextEditingController dnsServerController = TextEditingController();
  TextEditingController probeDomainController = TextEditingController();
  TextEditingController probeIntervalController = TextEditingController();
  String commandOutput = "等待输出..."; // 默认输出

  void updateCommandOutput(String output) {
    setState(() {
      commandOutput += output; // 累加输出
    });
  }

  Future<void> runActiveDetectionScript(String interface, String dnsServer, String probeDomain, int probeInterval) async {
    try {
      Process process = await Process.start(
        'python',
        [
          "D:\\code\\dns\\lib\\python_scripts\\active_detection\\DNS_cli.py",
          '--interface', interface,
          '--dns-server', dnsServer,
          '--probe-domain', probeDomain,
          '--probe-interval', probeInterval.toString(),
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
              // 输入框
              TextBox(
                controller: interfaceController,
                placeholder: '请输入网络接口',
              ),
              SizedBox(height: 5),
              TextBox(
                controller: dnsServerController,
                placeholder: '请输入DNS服务器',
              ),
              SizedBox(height: 5),
              TextBox(
                controller: probeDomainController,
                placeholder: '请输入探测域名',
              ),
              SizedBox(height: 5),
              TextBox(
                controller: probeIntervalController,
                placeholder: '请输入探测间隔时间',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 5),
              // 运行按钮
              FilledButton(
                onPressed: () {
                  String interface = interfaceController.text;
                  String dnsServer = dnsServerController.text;
                  String probeDomain = probeDomainController.text;
                  int probeInterval = int.tryParse(probeIntervalController.text) ?? 5;
                  print("运行脚本");
                  runActiveDetectionScript(interface, dnsServer, probeDomain, probeInterval);
                },
                child: Text('运行脚本'),
              ),
              SizedBox(height: 20),
              // 输出区域
              Container(
                padding: EdgeInsets.all(10),
                height: 300,
                width: double.infinity, // 让宽度填满父容器
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
  bool get wantKeepAlive => true;  // 让当前页面保持活动状态
}
