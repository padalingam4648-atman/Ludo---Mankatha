
import 'ludo_color.dart';

class LudoToken {
  final int id;
  final LudoColor color;
  
  // -1: In Base
  // 0-50: Common Path (51 steps)
  // 51-55: Home Stretch (5 steps)
  // 56: Finished
  int position = -1;

  LudoToken(this.id, this.color);

  bool get isInBase => position == -1;
  bool get isFinished => position == 56;
  bool get isOnPath => position >= 0 && position <= 50;
  bool get isInHomeStretch => position >= 51 && position <= 55;

  void reset() {
    position = -1;
  }
}
