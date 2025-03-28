import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:practice_project/todo.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const TodoApp(),
  ));
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  _TodoAppState createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  List<Todo> todos = [];
  late File csvFile;
  String filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final directory = await getApplicationDocumentsDirectory();
    csvFile = File('${directory.path}/todos.csv');
    if (await csvFile.exists()) {
      List<String> lines = await csvFile.readAsLines();
      setState(() {
        todos = lines.map((line) {
          var parts = line.split(',');
          return Todo(
            id: parts[0],
            title: parts[1],
            description: parts[2],
            createdAt: int.parse(parts[3]),
            status: parts[4],
          );
        }).toList();
      });
    }
  }

  Future<void> _saveTodos() async {
    String content = todos.map((todo) => todo.toCsv()).join('\n');
    await csvFile.writeAsString(content);
  }

  void _addTodo(String title, String description) {
    setState(() {
      todos.add(Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: 'pending',
      ));
      _saveTodos();
    });
  }

  void _updateTodo(Todo todo, String newTitle, String newDescription, String newStatus) {
    setState(() {
      todo.title = newTitle;
      todo.description = newDescription;
      todo.status = newStatus;
      _saveTodos();
    });
  }

  void _deleteTodo(String id) {
    setState(() {
      todos.removeWhere((todo) => todo.id == id);
      _saveTodos();
    });
  }

  Future<void> _importFromJson(File jsonFile) async {
    String jsonString = await jsonFile.readAsString();
    List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      todos.addAll(jsonList.map((json) => Todo.fromJson(json)).toList());
      _saveTodos();
    });
  }

  Future<void> _pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null) {
      File file = File(result.files.single.path!);
      _importFromJson(file);
    }
  }

  Future<void> _exportCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportPath = '${directory.path}/exported_todos.csv';
    final exportFile = File(exportPath);
    await exportFile.writeAsString(await csvFile.readAsString());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV exported to: $exportPath')));
  }

  void _showAddTodoDialog() {
    String title = '';
    String description = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (value) => title = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => description = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addTodo(title, description);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(Todo todo) {
    String title = todo.title;
    String description = todo.description;
    String status = todo.status;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              controller: TextEditingController(text: title),
              onChanged: (value) => title = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              controller: TextEditingController(text: description),
              onChanged: (value) => description = value,
            ),
            DropdownButtonFormField(
              value: status,
              items: ['ready', 'pending', 'completed'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) => status = value as String,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateTodo(todo, title, description, status);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<Todo> getFilteredTodos() {
    if (filterStatus == 'all') {
      return todos;
    } else {
      return todos.where((todo) => todo.status == filterStatus).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
        actions: [
          Tooltip(
            message: 'Import JSON File',
            child: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _pickJsonFile,
            ),
          ),
          Tooltip(
            message: 'Export CSV File',
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportCsv,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Dropdown to filter by status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: filterStatus,
              onChanged: (newValue) {
                setState(() {
                  filterStatus = newValue!;
                });
              },
              items: ['all', 'pending', 'completed', 'ready'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
            ),
          ),
          // List of todos
          Expanded(
            child: ListView.builder(
              itemCount: getFilteredTodos().length,
              itemBuilder: (context, index) {
                final todo = getFilteredTodos()[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: todo.statusColor, // Use statusColor for simple background color
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(
                      todo.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(todo.description),
                        const SizedBox(height: 5),
                        Text(
                          'Status: ${todo.status}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: todo.status == 'completed'
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditTodoDialog(todo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTodo(todo.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
