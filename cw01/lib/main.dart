import 'package:flutter/material.dart';

void main() {
  runApp(const CounterImageToggleApp());
}

// 1. We change the Root Widget to be Stateful.
// This allows it to hold the Theme State for the ENTIRE app.
class CounterImageToggleApp extends StatefulWidget {
  const CounterImageToggleApp({super.key});

  @override
  State<CounterImageToggleApp> createState() => _CounterImageToggleAppState();
}

class _CounterImageToggleAppState extends State<CounterImageToggleApp> {
  // This variable now controls the theme for the WHOLE app
  bool _isDark = false;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW1 Counter & Toggle',
      debugShowCheckedModeBanner: false,
      // The theme logic happens here at the top
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      // We pass the toggle function down to the HomePage
      home: HomePage(isDark: _isDark, onThemeToggle: _toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Task 1 State
  int _counter = 0;
  int _step = 1;
  int _goal = 20;
  final List<(int value, String label)> _history = [];

  // Task 2 State
  bool _isFirstImage = true;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.value = 1.0; // Start visible
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FIX: The Animation Logic ---
  void _toggleImage() async {
    // 1. Fade OUT the old image
    await _controller.reverse();
    
    // 2. SWAP the image file while it is invisible
    setState(() => _isFirstImage = !_isFirstImage);
    
    // 3. Fade IN the new image
    _controller.forward();
  }

  void _change(int delta) {
    setState(() {
      _counter = (_counter + delta).clamp(0, 9999);
      _history.insert(0, (_counter, delta > 0 ? '+$delta' : '$delta'));
      if (_history.length > 5) _history.removeLast();
    });
  }

  void _undo() {
    if (_history.length < 2) return;
    setState(() {
      _history.removeAt(0);
      _counter = _history.first.$1;
    });
  }

  void _reset() => setState(() {
        _counter = 0;
        _history.clear();
      });

  @override
  Widget build(BuildContext context) {
    final progress = (_counter / _goal).clamp(0.0, 1.0);

    // --- FIX: NO MaterialApp here. Just Scaffold. ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('CW1 Counter & Toggle'),
        actions: [
          // This button calls the function in the Root Widget
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Counter
            Text(
              '$_counter',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                // Use theme colors so it updates automatically
                color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (progress >= 1.0) const Text('🎉 Goal reached!', style: TextStyle(fontWeight: FontWeight.bold)),

            // Goal & Progress
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Goal: '),
              Expanded(
                child: Slider(
                  value: _goal.toDouble(),
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: '$_goal',
                  onChanged: (v) => setState(() => _goal = v.round()),
                ),
              ),
              Text('$_goal'),
            ]),

            // Step Selector
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: [1, 5, 10]
                  .map((s) => ButtonSegment(value: s, label: Text('+$s')))
                  .toList(),
              selected: {_step},
              onSelectionChanged: (s) => setState(() => _step = s.first),
            ),

            // Controls
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                onPressed: _counter <= 0 ? null : () => _change(-_step),
                child: Text('−$_step'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                   foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () => _change(_step),
                child: Text('+$_step'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _counter == 0 ? null : _reset,
                child: const Text('Reset'),
              ),
            ]),

            // History
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _history.length >= 2 ? _undo : null,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo'),
              ),
            ),

            // Image Toggle
            const Divider(height: 40),
            FadeTransition(
              opacity: _animation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _isFirstImage ? 'assets/images/image1.png' : 'assets/images/image2.jpg',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 180, height: 180, color: Colors.grey.shade300, 
                    child: const Icon(Icons.broken_image)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _toggleImage,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Toggle Image'),
            ),
          ],
        ),
      ),
    );
  }
}