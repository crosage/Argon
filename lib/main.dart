import 'package:fluent_ui/fluent_ui.dart';
import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      theme: FluentThemeData(
        scaffoldBackgroundColor: Colors.white,
        accentColor: Colors.blue,
        iconTheme: const IconThemeData(size: 24),
      ),
      darkTheme: FluentThemeData(
        scaffoldBackgroundColor: Colors.black,
        accentColor: Colors.blue,
        iconTheme: const IconThemeData(size: 24),
      ),
      home: HomePage(),
    );
  }
}
