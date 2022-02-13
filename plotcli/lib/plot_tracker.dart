import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:plotcli/mount_checker.dart';

class PlotTracker {
  int plotCount = 0;
  List<PlotFile> allPlots = [];

  Future<List<PlotFile>> searchPlots(DiskMount mount,
      [bool recursive = false]) async {
    Fimber.d('Searching for plots at $mount');
    final dir = Directory(mount.target);
    final dirFiles = await searchPlotsAtDirectory(dir);
    final startOfPath = dir.path.length;

    final foundPlots = await Future.wait(dirFiles.map((e) async {
      final len = await e.length();
      return PlotFile(e.path.substring(startOfPath), mount, len);
    }).toList());
    Fimber.d('Found ${foundPlots.length} plots.');
    return foundPlots;
  }

  Future<List<File>> searchPlotsAtDirectory(Directory rootDir,
      [bool recursive = false]) async {
    final files = <File>[];
    Fimber.i('Searching for files at : $rootDir');
    await rootDir.list(recursive: recursive, followLinks: false).listen(
      (event) {
        if (event is File) {
          Fimber.d("File: $event");
          plotCount++;
          files.add(event);
        }
      },
      onError: (e) {
        if (e is FileSystemException) {
          Fimber.w("Skipping file: ${e.path} due to error: ${e.message}");
        } else {
          Fimber.w('Error to access file.', ex: e);
        }
      },
    ).asFuture();
    return files;
  }
}

class PlotFile {
  PlotFile(this.path, this.mount, this.size);

  /// Path relative from mount point
  String path;
  int size;
  DiskMount mount;

  @override
  String toString() {
    return "PlotFile(name=$path, size=$size, mount=$mount)";
  }
}
