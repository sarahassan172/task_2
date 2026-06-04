import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Task {
  final String id;
  String title;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
  });


  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
  };


  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    isDone: json['isDone'] as bool,
  );
}


class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {

  List<Task> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  static const String _tasksKey = 'todo_tasks';


  @override
  void initState() {
    super.initState();
    _loadTasks(); // retrieve saved tasks when screen opens
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_tasksKey);

    if (data != null) {

      final List<dynamic> decoded = jsonDecode(data) as List<dynamic>;
      setState(() {
        _tasks = decoded
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }


  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final String data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, data);
  }


  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      ));
    });

    _controller.clear();
    _saveTasks(); // persist immediately after adding
  }


  void _toggleTask(int index) {
    setState(() => _tasks[index].isDone = !_tasks[index].isDone);
    _saveTasks();
  }


  void _deleteTask(int index) {
    final removed = _tasks[index];

    setState(() => _tasks.removeAt(index));
    _saveTasks();


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _tasks.insert(index, removed));
            _saveTasks();
          },
        ),
      ),
    );
  }


  void _clearCompleted() {
    setState(() => _tasks.removeWhere((t) => t.isDone));
    _saveTasks();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    final pending   = _tasks.where((t) => !t.isDone).toList();
    final completed = _tasks.where((t) =>  t.isDone).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (completed.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Clear completed',
              onPressed: _clearCompleted,
            ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Add a new task…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),

                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addTask,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(56, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${pending.length} remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_tasks.isNotEmpty)
                  Text(
                    '${completed.length}/${_tasks.length} done',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),


          Expanded(
            child: _tasks.isEmpty
                ? _buildEmptyState(theme)
                : ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16),
              children: [

                ...List.generate(pending.length, (i) {
                  final globalIndex = _tasks.indexOf(pending[i]);
                  return _buildTaskTile(
                      pending[i], globalIndex, theme);
                }),


                if (completed.isNotEmpty && pending.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8),
                        child: Text(
                          'Completed',
                          style:
                          theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                  ),


                ...List.generate(completed.length, (i) {
                  final globalIndex =
                  _tasks.indexOf(completed[i]);
                  return _buildTaskTile(
                      completed[i], globalIndex, theme);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTaskTile(Task task, int index, ThemeData theme) {
    return Dismissible(
      // Dismissible needs a unique key
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => _deleteTask(index),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          // Checkbox as leading widget — Task 1: toggles via setState
          leading: Checkbox(
            value: task.isDone,
            onChanged: (_) => _toggleTask(index),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isDone ? TextDecoration.lineThrough : null,
              color: task.isDone ? theme.colorScheme.outline : null,
            ),
          ),
          // Delete icon button on the right
          trailing: IconButton(
            icon: Icon(Icons.delete_outline,
                color: theme.colorScheme.outline, size: 20),
            onPressed: () => _deleteTask(index),
          ),
          onTap: () => _toggleTask(index),
        ),
      ),
    );
  }


  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded,
              size: 80, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No tasks yet!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 4),
          Text('Add one above to get started.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
              )),
        ],
      ),
    );
  }
}
