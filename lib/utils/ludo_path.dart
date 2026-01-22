
import 'package:flutter/material.dart';
import '../models/ludo_color.dart';

class LudoPath {
  static List<Offset> getCommonPath() {
    List<Offset> path = [];
    
    // Left strip to center (0,6 to 5,6)
    for (int i = 0; i <= 5; i++) {
      path.add(Offset(i.toDouble(), 6));
    }
    // Top strip from center (6,5 to 6,0)
    for (int i = 5; i >= 0; i--) {
      path.add(Offset(6, i.toDouble()));
    }
    // Across top (7,0)
    path.add(Offset(7, 0));
    // Top strip to center (8,0 to 8,5)
    for (int i = 0; i <= 5; i++) {
      path.add(Offset(8, i.toDouble()));
    }
    // Right strip from center (9,6 to 14,6)
    for (int i = 9; i <= 14; i++) {
      path.add(Offset(i.toDouble(), 6));
    }
    // Across right (14,7)
    path.add(Offset(14, 7));
    // Right strip back to center (14,8 to 9,8)
    for (int i = 14; i >= 9; i--) {
      path.add(Offset(i.toDouble(), 8));
    }
    // Bottom strip from center (8,9 to 8,14)
    for (int i = 9; i <= 14; i++) {
      path.add(Offset(8, i.toDouble()));
    }
    // Across bottom (7,14)
    path.add(Offset(7, 14));
    // Bottom strip back to center (6,14 to 6,9)
    for (int i = 14; i >= 9; i--) {
      path.add(Offset(6, i.toDouble()));
    }
    // Left strip from center (5,8 to 0,8)
    for (int i = 5; i >= 0; i--) {
      path.add(Offset(i.toDouble(), 8));
    }
    // Across left (0,7)
    path.add(Offset(0, 7));
    
    return path;
  }

  static List<Offset> getHomeStretch(LudoColor color) {
    List<Offset> path = [];
    switch (color) {
      case LudoColor.red:
        for (int i = 1; i <= 5; i++) {
          path.add(Offset(i.toDouble(), 7));
        }
        break;
      case LudoColor.green:
        for (int i = 1; i <= 5; i++) {
          path.add(Offset(7, i.toDouble()));
        }
        break;
      case LudoColor.yellow:
        for (int i = 13; i >= 9; i--) {
          path.add(Offset(i.toDouble(), 7));
        }
        break;
      case LudoColor.blue:
        for (int i = 13; i >= 9; i--) {
          path.add(Offset(7, i.toDouble()));
        }
        break;
    }
    return path;
  }

  static Offset getBasePosition(LudoColor color, int tokenId) {
    switch (color) {
      case LudoColor.red:
        return [Offset(1, 1), Offset(1, 4), Offset(4, 1), Offset(4, 4)][tokenId];
      case LudoColor.green:
        return [Offset(10, 1), Offset(10, 4), Offset(13, 1), Offset(13, 4)][tokenId];
      case LudoColor.yellow:
        return [Offset(10, 10), Offset(10, 13), Offset(13, 10), Offset(13, 13)][tokenId];
      case LudoColor.blue:
        return [Offset(1, 10), Offset(1, 13), Offset(4, 10), Offset(4, 13)][tokenId];
    }
  }

  static Offset getHomePosition(LudoColor color) {
    return Offset(7, 7); // Center of 3x3
  }
}
