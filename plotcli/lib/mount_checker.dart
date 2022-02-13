import 'dart:io';

import 'package:fimber/fimber.dart';

class MountChecker {
  List<DiskMount> mounts = [];
  Future searchMounts() async {
    ProcessResult mountsProcess = await Process.run('df', ['-l']);

    // Fimber.i("Process result: exit = ${mountsProcess.exitCode}");
    var mountsOutput = mountsProcess.stdout as String;
    final allLines = mountsOutput.split('\n');
    final firstLine = allLines.first;
    allLines.removeAt(0);
    // Fimber.i("firstLIne: $firstLine");
    final targetIndex = firstLine.indexOf('Mounted');
    final freeIndex = firstLine.indexOf('ifree');
    final usedIndex = firstLine.indexOf('iused');

    final foundMounts = allLines.map((line) {
      DiskMount? diskMount;
      if (line.length > targetIndex) {
        final target = line.substring(targetIndex).trim();
        diskMount = DiskMount(target);
        var endIndex = line.indexOf(' ', freeIndex);
        diskMount.free =
            int.tryParse(line.substring(freeIndex, endIndex)) ?? -1;
        endIndex = line.indexOf(' ', usedIndex);
        diskMount.used =
            int.tryParse(line.substring(usedIndex, endIndex)) ?? -1;
      }
      return diskMount;
    }).toList();
    foundMounts.removeWhere((e) => e == null);
    mounts = foundMounts.map((e) => e!).toList();
    Fimber.i("Found mounts: ${mounts}");
  }
}

class DiskMount {
  DiskMount(this.target, {this.free = -1, this.used = -1});
  String target;
  int free;
  int used;

  @override
  String toString() {
    return "DiskMount(target=$target, free=$free, used=$used)";
  }
}
