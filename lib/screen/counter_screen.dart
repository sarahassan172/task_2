import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {

  int _counter = 0;
  bool _isLoading = true;

  static const String _counterKey = 'counter_value';


  @override
  void initState() {
    super.initState();
    _loadCounter();
  }


  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {

      _counter   = prefs.getInt(_counterKey) ?? 0;
      _isLoading = false;
    });
  }


  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, _counter);
  }


  void _increment() {
    setState(() => _counter++);
    _saveCounter();              
  }


  void _decrement() {
    if (_counter > 0) {
      setState(() => _counter--);
      _saveCounter();
    }
  }


  void _reset() {
    setState(() => _counter = 0);
    _saveCounter();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter App'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset counter',
            onPressed: _reset,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 48),
                child: Column(
                  children: [
                    Text(
                      'Counter Value',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),


                    Text(
                      '$_counter',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_alt,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-saved locally',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),


            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement button — Task 1
                FloatingActionButton(
                  heroTag: 'decrement',
                  onPressed: _counter > 0 ? _decrement : null,
                  backgroundColor: _counter > 0
                      ? theme.colorScheme.errorContainer
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.remove,
                    color: _counter > 0
                        ? theme.colorScheme.onErrorContainer
                        : Colors.grey,
                  ),
                ),

                const SizedBox(width: 32),

                // Increment button — Task 1
                FloatingActionButton.large(
                  heroTag: 'increment',
                  onPressed: _increment,
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 32),


            Text(
              'Value is saved automatically.\nClose and reopen the app to verify.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
