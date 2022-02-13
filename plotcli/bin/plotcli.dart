import 'dart:io';
import 'dart:math';

import 'package:fimber/fimber.dart';
import 'package:plotcli/mount_checker.dart';
import 'package:plotcli/plot_tracker.dart';

void main(List<String> arguments) async {
  Fimber.plantTree(DebugTree.elapsed());
  final mountChecker = MountChecker();
  await mountChecker.searchMounts();

  final plotTracker = PlotTracker();
  if (mountChecker.mounts.isNotEmpty) {
    final plots = await plotTracker.searchPlots(mountChecker.mounts.last);
    for (var e in plots) {
      Fimber.i("Plot:$e");
    }

    Fimber.i("Plots found: ${plots.length}");
  }
}
