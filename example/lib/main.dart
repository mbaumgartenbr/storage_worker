import 'package:flutter/material.dart';

import 'src/storage_controller.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _wasInitialized = false;

  late final controller = StorageController();

  @override
  void initState() {
    super.initState();
    controller.init().then((_) => setState(() => _wasInitialized = true));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_wasInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Storage Worker')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: ValueListenableBuilder<String>(
                    valueListenable: controller.text,
                    builder: (_, text, __) {
                      return Text(
                        text,
                        style: const TextStyle(fontSize: 48),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Colors.grey.shade400,
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: controller.failures,
                    builder: (_, failures, __) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: failures.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text(
                              '($index) ${failures[index]}',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontSize: 18,
                                    color: Colors.red.shade900,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              onPressed: () => controller.put(
                key: 'Key',
                value: {'name': 'John Doe', 'age': 50},
              ),
              backgroundColor: Colors.purple.shade900,
              label: const Text('Write Value'),
              icon: const Icon(Icons.edit_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: () => controller.get('Key'),
              backgroundColor: Colors.yellow.shade900,
              label: const Text('Read Value'),
              icon: const Icon(Icons.article_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: () => controller.delete('Key'),
              backgroundColor: Colors.blue.shade900,
              label: const Text('Delete Value'),
              icon: const Icon(Icons.delete_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: controller.openStore,
              backgroundColor: Colors.green.shade900,
              label: const Text('Open Store'),
              icon: const Icon(Icons.play_circle_outline_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: controller.closeStore,
              backgroundColor: Colors.red.shade900,
              label: const Text('Close Store'),
              icon: const Icon(Icons.pause_circle_outline_rounded),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
