
enum LudoColor { red, yellow, green, blue }

extension LudoColorExtension on LudoColor {
  String get name {
    switch (this) {
      case LudoColor.red: return 'Red';
      case LudoColor.yellow: return 'Yellow';
      case LudoColor.green: return 'Green';
      case LudoColor.blue: return 'Blue';
    }
  }
}
