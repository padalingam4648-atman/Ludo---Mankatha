import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'logic/ludo_logic.dart';
import 'models/ludo_color.dart';
import 'models/ludo_token.dart';
import 'utils/ludo_path.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'screens/home_screen.dart';
import 'screens/extra_screens.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for immersive experience on mobile
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  runApp(
    ChangeNotifierProvider(create: (_) => LudoLogic(), child: const LudoApp()),
  );
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final isLight = logic.currentTheme == DashboardTheme.light;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mankatha',
      theme: ThemeData(
        brightness: isLight ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: isLight
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF020205),
        textTheme: GoogleFonts.outfitTextTheme(
          isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const LudoScreen(),
    );
  }
}

class LudoScreen extends StatelessWidget {
  const LudoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();

    switch (logic.status) {
      case GameStatus.home:
        return const HomeScreen();
      case GameStatus.setup:
        return const Scaffold(body: PlayerSelectionScreen());
      case GameStatus.playing:
      case GameStatus.finished:
        final isLight = logic.currentTheme == DashboardTheme.light;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: isLight
                    ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
                    : [const Color(0xFF0F172A), const Color(0xFF020617)],
              ),
            ),
            child: SafeArea(child: _buildGameBoard(context, logic)),
          ),
        );
      case GameStatus.profile:
        return const ProfileEditorScreen();
      case GameStatus.settings:
        return const SettingsScreen();
      case GameStatus.howToPlay:
        return const HowToPlayScreen();
    }
  }

  Widget _buildGameBoard(BuildContext context, LudoLogic logic) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Column(
      children: [
        if (!isLandscape || !isMobile) _buildHeader(isMobile),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: EdgeInsets.all(
                  isMobile ? (isLandscape ? 4.0 : 8.0) : 16.0,
                ),
                child: Stack(
                  children: [
                    const LudoBoard(),
                    const StartHighlightOverlay(),
                    const TokensLayer(),
                    const DiceRollOverlay(),
                    const WinOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildFooter(context, isMobile),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Consumer<LudoLogic>(
      builder: (context, logic, child) {
        final textColor = logic.currentTheme == DashboardTheme.light
            ? Colors.black87
            : Colors.white;
        final accentColor = logic.playerColor(logic.currentPlayer.color);

        return Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor.withOpacity(0.7),
                      size: isMobile ? 18 : 20,
                    ),
                    onPressed: () => logic.goToHome(),
                  ),
                  SizedBox(width: isMobile ? 4 : 8),
                  Text(
                    'MANKATHA',
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isMobile ? 2 : 4,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                  vertical: isMobile ? 4 : 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isMobile
                      ? logic.currentPlayer.color.name.toUpperCase()
                      : "${logic.currentPlayer.color.name.toUpperCase()}'S TURN",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Consumer<LudoLogic>(
      builder: (context, logic, child) {
        return Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DiceWidget(
                value: logic.diceValue,
                isRolling: logic.isRolling,
                onTap: logic.rollDice,
                activeColor: _getColor(logic.currentPlayer.color),
                enabled:
                    !logic.diceRolled &&
                    !logic.gameFinished &&
                    !logic.currentPlayer.isAI,
                size: isMobile ? 60 : 80,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getNeonColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Color(0xFFFF007F);
      case LudoColor.green:
        return const Color(0xFF39FF14);
      case LudoColor.yellow:
        return const Color(0xFFFFFF33);
      case LudoColor.blue:
        return const Color(0xFF00F2FF);
    }
  }

  Color _getColor(LudoColor color) => _getNeonColor(color);
}

class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final theme = logic.currentTheme;
    final isLight = theme == DashboardTheme.light;

    return Container(
      decoration: BoxDecoration(
        color: logic.boardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.1 : 0.8),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          size: Size.infinite,
          painter: BoardPainter(
            gridLineColor: logic.gridLineColor,
            redColor: logic.playerColor(LudoColor.red),
            greenColor: logic.playerColor(LudoColor.green),
            yellowColor: logic.playerColor(LudoColor.yellow),
            blueColor: logic.playerColor(LudoColor.blue),
            isLight: isLight,
          ),
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final Color gridLineColor;
  final Color redColor;
  final Color greenColor;
  final Color yellowColor;
  final Color blueColor;
  final bool isLight;

  BoardPainter({
    required this.gridLineColor,
    required this.redColor,
    required this.greenColor,
    required this.yellowColor,
    required this.blueColor,
    required this.isLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridLineColor;

    // Draw Grid and highlights
    for (int i = 0; i < 15; i++) {
      for (int j = 0; j < 15; j++) {
        Rect rect = Rect.fromLTWH(
          i * cellSize,
          j * cellSize,
          cellSize,
          cellSize,
        );

        // Base colors with better gradients/opacities
        if (i < 6 && j < 6) {
          paint.color = redColor.withOpacity(0.04); // Red Base
        } else if (i > 8 && j < 6) {
          paint.color = greenColor.withOpacity(0.04); // Green Base
        } else if (i < 6 && j > 8) {
          paint.color = blueColor.withOpacity(0.04); // Blue Base
        } else if (i > 8 && j > 8) {
          paint.color = yellowColor.withOpacity(0.04); // Yellow Base
        } else if (i >= 6 && i <= 8 && j >= 6 && j <= 8) {
          paint.color = (isLight ? Colors.black : Colors.white).withOpacity(
            0.03,
          );
        } else {
          paint.color = Colors.transparent;
        }

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
      }
    }

    // Draw Home Areas
    _drawHomeArea(canvas, cellSize, const Offset(0, 0), redColor);
    _drawHomeArea(canvas, cellSize, const Offset(9, 0), greenColor);
    _drawHomeArea(canvas, cellSize, const Offset(9, 9), yellowColor);
    _drawHomeArea(canvas, cellSize, const Offset(0, 9), blueColor);

    // Draw Starting boxes and Path Highlights
    _drawPathCell(canvas, cellSize, const Offset(1, 6), redColor, isSafe: true);
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(8, 1),
      greenColor,
      isSafe: true,
    );
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(13, 8),
      yellowColor,
      isSafe: true,
    );
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(6, 13),
      blueColor,
      isSafe: true,
    );

    // Draw other safe spots (Shields)
    Color safeIconColor = isLight ? Colors.black38 : Colors.grey;
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(6, 2),
      safeIconColor,
      isSafe: true,
    );
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(12, 6),
      safeIconColor,
      isSafe: true,
    );
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(8, 12),
      safeIconColor,
      isSafe: true,
    );
    _drawPathCell(
      canvas,
      cellSize,
      const Offset(2, 8),
      safeIconColor,
      isSafe: true,
    );

    // Draw Home Stretches
    for (int i = 1; i <= 5; i++) {
      _drawPathCell(canvas, cellSize, Offset(i.toDouble(), 7), redColor);
    }
    for (int i = 1; i <= 5; i++) {
      _drawPathCell(canvas, cellSize, Offset(7, i.toDouble()), greenColor);
    }
    for (int i = 13; i >= 9; i--) {
      _drawPathCell(canvas, cellSize, Offset(i.toDouble(), 7), yellowColor);
    }
    for (int i = 13; i >= 9; i--) {
      _drawPathCell(canvas, cellSize, Offset(7, i.toDouble()), blueColor);
    }

    // Draw Center Home
    _drawCenter(canvas, size, cellSize);
  }

  void _drawPathCell(
    Canvas canvas,
    double cellSize,
    Offset pos,
    Color color, {
    bool isSafe = false,
  }) {
    final paint = Paint()..color = color.withOpacity(isSafe ? 0.15 : 0.12);
    final rect = Rect.fromLTWH(
      pos.dx * cellSize + 1.5,
      pos.dy * cellSize + 1.5,
      cellSize - 3,
      cellSize - 3,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );

    if (isSafe) {
      final iconPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(rect.center, cellSize / 4, iconPaint);
    }
  }

  void _drawHomeArea(
    Canvas canvas,
    double cellSize,
    Offset basePos,
    Color color,
  ) {
    final bgPaint = Paint()..color = color.withOpacity(0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          basePos.dx * cellSize + 4,
          basePos.dy * cellSize + 4,
          6 * cellSize - 8,
          6 * cellSize - 8,
        ),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          basePos.dx * cellSize + 8,
          basePos.dy * cellSize + 8,
          6 * cellSize - 16,
          6 * cellSize - 16,
        ),
        const Radius.circular(12),
      ),
      borderPaint,
    );

    _drawHomeCircles(canvas, cellSize, basePos, color);
  }

  void _drawHomeCircles(
    Canvas canvas,
    double cellSize,
    Offset basePos,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    List<Offset> relativeSpots = [
      Offset(1.5, 1.5),
      Offset(1.5, 4.5),
      Offset(4.5, 1.5),
      Offset(4.5, 4.5),
    ];

    for (var spot in relativeSpots) {
      canvas.drawCircle(
        Offset(
          (basePos.dx + spot.dx) * cellSize,
          (basePos.dy + spot.dy) * cellSize,
        ),
        cellSize * 0.45,
        paint,
      );
      canvas.drawCircle(
        Offset(
          (basePos.dx + spot.dx) * cellSize,
          (basePos.dy + spot.dy) * cellSize,
        ),
        cellSize * 0.45,
        borderPaint,
      );
    }
  }

  void _drawCenter(Canvas canvas, Size size, double cellSize) {
    final paint = Paint();

    Path redPath = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(7.5 * cellSize, 7.5 * cellSize)
      ..lineTo(6 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(redPath, paint..color = redColor.withOpacity(0.4));

    Path greenPath = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(7.5 * cellSize, 7.5 * cellSize)
      ..lineTo(9 * cellSize, 6 * cellSize)
      ..close();
    canvas.drawPath(greenPath, paint..color = greenColor.withOpacity(0.4));

    Path yellowPath = Path()
      ..moveTo(9 * cellSize, 6 * cellSize)
      ..lineTo(7.5 * cellSize, 7.5 * cellSize)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(yellowPath, paint..color = yellowColor.withOpacity(0.4));

    Path bluePath = Path()
      ..moveTo(6 * cellSize, 9 * cellSize)
      ..lineTo(7.5 * cellSize, 7.5 * cellSize)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(bluePath, paint..color = blueColor.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;
  final VoidCallback onTap;
  final Color activeColor;
  final bool enabled;

  final double size;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.onTap,
    required this.activeColor,
    required this.enabled,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final isLight = logic.currentTheme == DashboardTheme.light;
    final bgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final borderColor = enabled
        ? activeColor.withOpacity(0.5)
        : (isLight ? Colors.black12 : Colors.white.withOpacity(0.1));

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled ? activeColor.withOpacity(0.1) : bgColor,
          borderRadius: BorderRadius.circular(size / 4),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: activeColor.withOpacity(isLight ? 0.3 : 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: isRolling
              ? CircularProgressIndicator(color: activeColor, strokeWidth: 3)
              : _buildDiceFace(
                  value,
                  isLight
                      ? (enabled ? activeColor : Colors.black54)
                      : activeColor,
                ),
        ),
      ),
    );
  }

  Widget _buildDiceFace(int val, Color color) {
    if (val == 0) {
      return Text(
        'ROLL',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 2,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.all(size / 5),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (index) {
        bool showDot = false;
        switch (val) {
          case 1:
            showDot = index == 4;
            break;
          case 2:
            showDot = index == 0 || index == 8;
            break;
          case 3:
            showDot = index == 0 || index == 4 || index == 8;
            break;
          case 4:
            showDot = index == 0 || index == 2 || index == 6 || index == 8;
            break;
          case 5:
            showDot =
                index == 0 ||
                index == 2 ||
                index == 4 ||
                index == 6 ||
                index == 8;
            break;
          case 6:
            showDot =
                index == 0 ||
                index == 2 ||
                index == 3 ||
                index == 5 ||
                index == 6 ||
                index == 8;
            break;
        }
        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: showDot ? color : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: [
              if (showDot)
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        );
      }),
    );
  }
}

class DiceRollOverlay extends StatelessWidget {
  const DiceRollOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();

    if (!(logic.diceRolled && logic.diceValue > 0 && !logic.isRolling)) {
      return const SizedBox.shrink();
    }

    final isLight = logic.currentTheme == DashboardTheme.light;
    final accentColor = logic.playerColor(logic.currentPlayer.color);

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Text(
            '${logic.diceValue}',
            style: GoogleFonts.outfit(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: accentColor,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TokensLayer extends StatelessWidget {
  const TokensLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cs = constraints.maxWidth / 15;

        List<Widget> tokenWidgets = [];
        for (var player in logic.players) {
          for (var token in player.tokens) {
            tokenWidgets.add(
              TokenWidget(
                token: token,
                cellSize: cs,
                onTap: () => logic.moveToken(token),
                isClickable:
                    logic.currentPlayer.color == token.color &&
                    logic.canMoveToken(token) &&
                    !logic.currentPlayer.isAI,
              ),
            );
          }
        }
        return Stack(children: tokenWidgets);
      },
    );
  }
}

class TokenWidget extends StatelessWidget {
  final LudoToken token;
  final double cellSize;
  final VoidCallback onTap;
  final bool isClickable;

  const TokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    required this.onTap,
    required this.isClickable,
  });

  @override
  Widget build(BuildContext context) {
    Offset pos;
    if (token.isInBase) {
      pos = LudoPath.getBasePosition(token.color, token.id);
    } else if (token.isFinished) {
      pos = LudoPath.getHomePosition(token.color);
    } else if (token.isInHomeStretch) {
      pos = LudoPath.getHomeStretch(token.color)[token.position - 51];
    } else {
      // Red offset 1, Green 14, Yellow 27, Blue 40 (Aligned with Logic)
      int offset = 0;
      switch (token.color) {
        case LudoColor.red:
          offset = 1;
          break;
        case LudoColor.green:
          offset = 14;
          break;
        case LudoColor.yellow:
          offset = 27;
          break;
        case LudoColor.blue:
          offset = 40;
          break;
      }
      // Special case: Shared path starts at index 0 for Red, but coord 0 is (0,6)
      // LudoPath.getCommonPath logic: (0,6) is index 0.
      // My Logic says Red starts at position 0.
      // Let's check getGlobalPosition
      int globalIdx = (offset + token.position) % 52;
      pos = LudoPath.getCommonPath()[globalIdx];
    }

    final logic = context.watch<LudoLogic>();
    final tokenColor = logic.playerColor(token.color);
    final isLight = logic.currentTheme == DashboardTheme.light;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: pos.dx * cellSize,
      top: pos.dy * cellSize,
      width: cellSize,
      height: cellSize,
      child: GestureDetector(
        onTap: isClickable ? onTap : null,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tokenColor.withOpacity(isClickable ? 1.0 : 0.8),
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withOpacity(0.4), Colors.transparent],
              center: const Alignment(-0.3, -0.3),
              radius: 0.6,
            ),
            border: Border.all(
              color: isClickable ? Colors.white : Colors.white.withOpacity(0.4),
              width: isClickable ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tokenColor.withOpacity(isClickable ? 0.6 : 0.3),
                blurRadius: isClickable ? 12 : 6,
                spreadRadius: isClickable ? 2 : 0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.stars_rounded,
              size: cellSize * 0.55,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  int _playerCount = 2;

  final List<TextEditingController> _controllers = List.generate(
    4,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );
  // Default colors
  final List<LudoColor> _selectedColors = [
    LudoColor.red,
    LudoColor.blue,
    LudoColor.green,
    LudoColor.yellow,
  ];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.read<LudoLogic>();

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 450),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => logic.goToHome(),
                  ),
                ),
                Text(
                  'MANKATHA',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'GAME SETUP',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white54,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),

                // Choose Number of Players
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NUMBER OF PLAYERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [2, 3, 4].map((count) {
                    bool isSelected = _playerCount == count;
                    final selectionWidth =
                        (math.min(
                              MediaQuery.of(context).size.width * 0.9,
                              450,
                            ) -
                            80) /
                        3;
                    return GestureDetector(
                      onTap: () => setState(() => _playerCount = count),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selectionWidth,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white10,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                // Player Names Entry
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ENTER PLAYER NAMES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                ...List.generate(4, (index) {
                  bool isEnabled = index < _playerCount;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isEnabled ? 1.0 : 0.3,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _controllers[index],
                            enabled: isEnabled,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Player ${index + 1}',
                              hintStyle: TextStyle(color: Colors.white24),
                              prefixIcon: Icon(
                                Icons.person,
                                color: isEnabled
                                    ? logic.playerColor(_selectedColors[index])
                                    : Colors.white24,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: logic.playerColor(
                                    _selectedColors[index],
                                  ),
                                  width: 2,
                                ),
                              ),
                              errorStyle: const TextStyle(
                                color: Color(0xFFFF007F),
                              ),
                            ),
                            validator: (value) {
                              if (isEnabled &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Name cannot be blank';
                              }
                              return null;
                            },
                          ),
                          if (isEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: LudoColor.values.map((c) {
                                  bool isSelected = _selectedColors[index] == c;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColors[index] = c;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: logic.playerColor(c),
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              )
                                            : null,
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: logic
                                                  .playerColor(c)
                                                  .withOpacity(0.6),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 30),

                // Start Game Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        List<String> names = _controllers
                            .take(_playerCount)
                            .map((c) => c.text.trim())
                            .toList();

                        List<LudoColor> colors = _selectedColors
                            .take(_playerCount)
                            .toList();

                        // Basic check for duplicates?
                        if (colors.toSet().length != colors.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select different colors for each player!',
                              ),
                            ),
                          );
                          return;
                        }

                        logic.startGame(names, colors);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'START GAME',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WinOverlay extends StatelessWidget {
  const WinOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    if (!logic.gameFinished) return const SizedBox.shrink();

    final isLight = logic.currentTheme == DashboardTheme.light;
    final accentColor = logic.playerColor(
      logic.winner?.color ?? LudoColor.yellow,
    );

    return Container(
      color: (isLight ? Colors.white : Colors.black).withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONGRATULATIONS!',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black87 : Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${logic.winner?.name.toUpperCase()} HAS WON!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                List<LudoColor> currentColors = logic.players
                    .map((p) => p.color)
                    .toList();
                logic.startGame(logic.lastUsedNames, currentColors);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'PLAY AGAIN',
                style: TextStyle(
                  color: isLight ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartHighlightOverlay extends StatelessWidget {
  const StartHighlightOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();

    // Check condition: Rolls 6 AND has tokens in base
    bool shouldHighlight =
        logic.diceValue == 6 &&
        !logic.isRolling &&
        logic.currentPlayer.tokens.any((t) => t.isInBase);

    if (!shouldHighlight) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellSize = constraints.maxWidth / 15;
        Offset startPos = _getStartPos(logic.currentPlayer.color);
        final accentColor = logic.playerColor(logic.currentPlayer.color);
        final isLight = logic.currentTheme == DashboardTheme.light;

        return Positioned(
              left: startPos.dx * cellSize,
              top: startPos.dy * cellSize,
              width: cellSize,
              height: cellSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isLight ? Colors.black54 : Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_downward,
                    color: isLight ? Colors.black54 : Colors.white,
                    size: cellSize * 0.5,
                  ),
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 500.ms,
            );
      },
    );
  }

  Offset _getStartPos(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Offset(1, 6);
      case LudoColor.green:
        return const Offset(8, 1);
      case LudoColor.yellow:
        return const Offset(13, 8);
      case LudoColor.blue:
        return const Offset(6, 13);
    }
  }
}
