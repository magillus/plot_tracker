import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  Fimber.plantTree(DebugTree.elapsed());
  Fimber.i('Args: $args');
  if (args.isEmpty) {
    final dr = '${homeDirectory() ?? '.'}/';
    runApp(PlotTrackerApp(pathStart: dr));
  } else {
    runApp(PlotTrackerApp(pathStart: args.first));
  }
}

class PlotTrackerApp extends StatelessWidget {
  const PlotTrackerApp({Key? key, required this.pathStart}) : super(key: key);

  final String pathStart;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot walker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlotWalkerPage(rootPath: pathStart),
    );
  }
}

class PlotWalkerPage extends StatefulWidget {
  const PlotWalkerPage({Key? key, required this.rootPath}) : super(key: key);

  final String rootPath;

  @override
  State<PlotWalkerPage> createState() => _PlotWalkerPageState();
}

class _PlotWalkerPageState extends State<PlotWalkerPage> {
  Directory? root;
  int _plotCount = 0;
  TrackerPage _currentPage = TrackerPage.count;
  String mountsOutput = '';
  @override
  void initState() {
    super.initState();
    FileSystemEntity.isDirectory(widget.rootPath).then((value) {
      if (value) {
        root = Directory(widget.rootPath);
      } else {
        root = Directory(File(widget.rootPath).path);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plot search: ${root?.path ?? '...'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  ButtonBar(
                    children: [
                      ElevatedButton(
                        onPressed: () => _showMounts(),
                        child: const Text('Mounts'),
                      ),
                    ],
                  ),
                ],
              ),
              _mainPage(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _seachPlots,
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _mainPage(BuildContext context) {
    switch (_currentPage) {
      case TrackerPage.count:
        {
          return Column(children: [
            const Text(
              'Searching for plots:',
            ),
            Text(
              '$_plotCount',
              style: Theme.of(context).textTheme.headline4,
            ),
          ]);
        }
      case TrackerPage.mounts:
        {
          return Text('Mounts:\n$mountsOutput');
        }
    }
  }

  void _seachPlots() {
    _plotCount = 0;
    final rootFile = root;
    if (rootFile != null) {
      Fimber.i('Searching for files at : $rootFile');
      rootFile.list(recursive: true).listen((event) {
        if (event is File) {
          Fimber.d("File: $event");
          setState(() {
            _currentPage = TrackerPage.count;
            _plotCount++;
          });
        }
      }, onError: (e) {
        if (e is FileSystemException) {
          Fimber.w("Skipping file: ${e.path} due to error: ${e.message}");
        } else {
          Fimber.w('Error to access file.', ex: e);
        }
      });
    }
  }

  _showMounts() async {
    setState(() {
      _currentPage = TrackerPage.mounts;
    });
    ProcessResult mountsProcess = await Process.run('df', ['-l']);
    Fimber.i("Process result: exit = ${mountsProcess.exitCode}");
    mountsOutput = mountsProcess.stdout as String;
    final firstLine = mountsOutput.split('\n').first;
    Fimber.i("firstLIne: $firstLine");
    final si = firstLine.indexOf('Mounted');
    Fimber.i("mounted at $si :\n$firstLine");
    mountsOutput = mountsOutput
        .split('\n')
        .map((line) {
          if (line.length > si) {
            return line.substring(si);
          } else {
            return line;
          }
        })
        .toList()
        .sublist(1)
        .join('\n');
    setState(() {});
    Fimber.i("Ouptut: \n $mountsOutput");
  }
}

enum TrackerPage { count, mounts }

String? homeDirectory() {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Platform.environment['HOME'];
    case 'windows':
      return Platform.environment['USERPROFILE'];
    case 'android':
      // Probably want internal storage.
      return '/storage/sdcard0';
    case 'ios':
      // iOS doesn't really have a home directory.
      return null;
    case 'fuchsia':
      // I have no idea.
      return null;
    default:
      return null;
  }
}
