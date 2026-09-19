import 'package:flutter/material.dart';
import 'package:soft_ui_kit/soft_ui_kit.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(AccentOption.teal.seed),
      darkTheme: AppTheme.dark(AccentOption.teal.seed),
      themeMode: ThemeMode.system,
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  static const _titles = ['Home', 'History', 'Billing'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: GlassPageHeader(title: _titles[_index], height: 64),
      body: Center(
        child: SoftCard(
          child: Text(
            _titles[_index],
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      bottomNavigationBar: SoftNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          SoftNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          SoftNavItem(icon: Icon(Icons.history), label: 'History'),
          SoftNavItem(
            icon: Icon(Icons.point_of_sale_outlined),
            label: 'Billing',
          ),
        ],
      ),
    );
  }
}
