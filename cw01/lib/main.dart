import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW1 Counter & Toggle',
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: HomePage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () => setState(() => _themeMode =
            _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.isDark, required this.onToggleTheme});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Task 1 state
  int _counter = 0;
  int _step = 1;
  int _goal = 20;
  final List<(int value, String label)> _history = [];

  // Task 2 state
  bool _isFirstImage = true;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1.0; // start with image1 visible
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _change(int delta) {
    setState(() {
      _counter = (_counter + delta).clamp(0, 9999);
      _history.insert(0, (_counter, delta > 0 ? '+$delta' : '$delta'));
      if (_history.length > 5) _history.removeLast();
    });
  }

  void _undo() {
    if (_history.length < 2) return;
    setState(() { _history.removeAt(0); _counter = _history.first.$1; });
  }

  void _reset() => setState(() {
    _counter = 0;
    _history.insert(0, (0, 'reset'));
    if (_history.length > 5) _history.removeLast();
  });

  void _toggleImage() {
    _isFirstImage ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _isFirstImage = !_isFirstImage);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (_counter / _goal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CW1 Counter & Toggle'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Counter display
            Text('$_counter',
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.green : cs.primary)),
            if (progress >= 1.0) const Text('🎉 Goal reached!'),

            // Progress bar and goal slider
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Goal:'),
              Expanded(
                child: Slider(
                  value: _goal.toDouble(), min: 5, max: 100, divisions: 19,
                  label: '$_goal',
                  onChanged: (v) => setState(() => _goal = v.round()),
                ),
              ),
              Text('$_goal'),
            ]),

            // Step selector
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [1, 5, 10].map((s) => ButtonSegment(value: s, label: Text('+$s'))).toList(),
              selected: {_step},
              onSelectionChanged: (s) => setState(() => _step = s.first),
            ),

            // Counter buttons
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: _counter <= 0 ? null : () => _change(-_step),
                child: Text('−$_step'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _change(_step),
                child: Text('+$_step'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _counter == 0 ? null : _reset,
                child: const Text('Reset'),
              ),
            ]),

            // History and undo
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Wrap(
                spacing: 6,
                children: _history.map((e) =>
                  Chip(label: Text('${e.$2}→${e.$1}'), visualDensity: VisualDensity.compact)
                ).toList(),
              ),
              TextButton.icon(
                onPressed: _history.length >= 2 ? _undo : null,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo'),
              ),
            ]),

            // Image toggle with fade animation
            const Divider(height: 40),
            Stack(alignment: Alignment.center, children: [
              Image.asset('assets/images/image2.jpg', width: 180, height: 180, fit: BoxFit.cover),
              FadeTransition(
                opacity: _fade,
                child: Image.asset('assets/images/image1.png', width: 180, height: 180, fit: BoxFit.cover),
              ),
            ]),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _toggleImage,
              icon: const Icon(Icons.swap_horiz),
              label: Text(_isFirstImage ? 'Switch to Night' : 'Switch to Day'),
            ),
          ],
        ),
      ),
    );
  }
}