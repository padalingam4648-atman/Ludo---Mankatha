
import 'ludo_color.dart';
import 'ludo_token.dart';

class LudoPlayer {
  final LudoColor color;
  final String name;
  final List<LudoToken> tokens;
  final bool isAI;

  LudoPlayer(this.color, this.name, {this.isAI = false}) : tokens = List.generate(4, (i) => LudoToken(i, color));

  bool get hasWon => tokens.every((t) => t.isFinished);
}

