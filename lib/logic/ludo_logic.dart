
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ludo_color.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/security_service.dart';

enum GameStatus { home, setup, playing, finished, profile, settings, howToPlay }
enum DashboardTheme { light, dark, elite }

class LudoLogic extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<LudoPlayer> players = [];
  int playerCount = 4;
  GameStatus status = GameStatus.home;
  bool isGameStarted = false; 
  bool musicEnabled = false; // Start disabled to avoid auto-play blocking in browsers
  List<String> lastUsedNames = [];

  LudoLogic() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSecureSession();
  }

  Future<void> _loadSecureSession() async {
    String? savedName = await SecurityService.readSecureData('user_name');
    String? savedEmail = await SecurityService.readSecureData('user_email');
    if (savedName != null && savedEmail != null) {
      userName = savedName;
      userEmail = savedEmail;
      isLoggedIn = true;
      isGuest = false;
      notifyListeners();
    }
  }

  DashboardTheme currentTheme = DashboardTheme.elite;

  // User Profile
  bool isLoggedIn = false;
  bool isGuest = true;
  String userName = "Guest Player";
  String userEmail = "";
  String userPhone = "";
  
  // Dashboard Stats
  int totalWins = 0;
  int xpPoints = 0;
  int gamesPlayed = 0;

  void setTheme(DashboardTheme theme) {
    currentTheme = theme;
    notifyListeners();
  }

  void loginAsGuest() {
    isLoggedIn = false;
    isGuest = true;
    userName = "Guest Player";
    notifyListeners();
  }

  void loginUser({required String name, required String email, required String phone, String? password}) async {
    // Sanitize inputs
    userName = SecurityService.sanitize(name);
    userEmail = SecurityService.sanitize(email);
    userPhone = SecurityService.sanitize(phone);
    
    isLoggedIn = true;
    isGuest = false;

    // Securely persist non-sensitive session info
    await SecurityService.saveSecureData('user_name', userName);
    await SecurityService.saveSecureData('user_email', userEmail);
    
    // If password provided, we would hash it if we were sending to a backend
    // In this local-only mode, we just ensure it's not stored as plain text anywhere.
    
    notifyListeners();
  }

  void logout() async {
    isLoggedIn = false;
    isGuest = true;
    userName = "Guest Player";
    await SecurityService.deleteSecureData('user_name');
    await SecurityService.deleteSecureData('user_email');
    notifyListeners();
  }

  void updateStatsAfterWin() {
    if (isLoggedIn) {
      totalWins++;
      xpPoints += 500;
      notifyListeners();
    }
  }

  // Game Board Colors based on Theme
  Color get boardBackground {
    switch (currentTheme) {
      case DashboardTheme.light: return const Color(0xFFFFFFFF);
      case DashboardTheme.dark: return const Color(0xFF1E293B);
      case DashboardTheme.elite: return const Color(0xFF0F172A);
    }
  }

  Color get gridLineColor {
    switch (currentTheme) {
      case DashboardTheme.light: return Colors.black.withOpacity(0.05);
      case DashboardTheme.dark: return Colors.white.withOpacity(0.05);
      case DashboardTheme.elite: return Colors.white.withOpacity(0.05);
    }
  }

  Color playerColor(LudoColor color) {
    bool isElite = currentTheme == DashboardTheme.elite;
    bool isLight = currentTheme == DashboardTheme.light;
    
    switch (color) {
      case LudoColor.red:
        if (isElite) return const Color(0xFFFF007F);
        if (isLight) return const Color(0xFFEF4444);
        return const Color(0xFFFF4D4D);
      case LudoColor.green:
        if (isElite) return const Color(0xFF39FF14);
        if (isLight) return const Color(0xFF22C55E);
        return const Color(0xFF4ADE80);
      case LudoColor.yellow:
        if (isElite) return const Color(0xFFFFFF33);
        if (isLight) return const Color(0xFFEAB308);
        return const Color(0xFFFACC15);
      case LudoColor.blue:
        if (isElite) return const Color(0xFF00F2FF);
        if (isLight) return const Color(0xFF3B82F6);
        return const Color(0xFF60A5FA);
    }
  }


  void toggleMusic() async {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      // You can replace this with your local asset path
      // _audioPlayer.play(AssetSource('music/bg_music.mp3'));
    } else {
      await _audioPlayer.stop();
    }
    notifyListeners();
  }

  void goToSetup() {
    status = GameStatus.setup;
    notifyListeners();
  }

  void goToHome() {
    status = GameStatus.home;
    notifyListeners();
  }

  void goToProfile() {
    status = GameStatus.profile;
    notifyListeners();
  }

  void goToSettings() {
    status = GameStatus.settings;
    notifyListeners();
  }

  void goToHowToPlay() {
    status = GameStatus.howToPlay;
    notifyListeners();
  }

  void startGame(List<String> names, List<LudoColor> colors, {List<bool>? isAIList}) {
    lastUsedNames = names;
    playerCount = names.length;
    players = [];
    
    for (int i = 0; i < playerCount; i++) {
      players.add(LudoPlayer(colors[i], names[i], isAI: isAIList != null ? isAIList[i] : false));
    }
    
    currentPlayerIndex = 0;
    diceValue = 0;
    diceRolled = false;
    gameFinished = false;
    winner = null;
    isGameStarted = true;
    status = GameStatus.playing;
    _isAIActionInProgress = false;
    notifyListeners();

    // If first player is AI, start their turn
    if (currentPlayer.isAI) {
      _triggerAITurn();
    }
  }

  void startSinglePlayerGame() {
    // One vs One: Red (Human) vs Yellow (AI) - Opposite sides
    List<String> names = ['You', 'CPU'];
    List<LudoColor> colors = [LudoColor.red, LudoColor.yellow];
    List<bool> isAIList = [false, true];
    startGame(names, colors, isAIList: isAIList);
  }

  bool _isAIActionInProgress = false;


  int currentPlayerIndex = 0;
  int diceValue = 0;
  bool isRolling = false;
  bool diceRolled = false;
  bool gameFinished = false;
  LudoPlayer? winner;

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  void rollDice() {
    if (diceRolled || gameFinished || isRolling) return;
    
    isRolling = true;
    notifyListeners();

    // Instant roll
    diceValue = Random().nextInt(6) + 1;
    isRolling = false;
    diceRolled = true;
    notifyListeners();
    
    // For AI, we don't auto-handle here, _triggerAITurn will handle the logic
    if (currentPlayer.isAI) return;

    // Calculate movable tokens for HUMAN
    List<LudoToken> movableTokens = currentPlayer.tokens
        .where((t) => canMoveToken(t))
        .toList();

    if (movableTokens.isEmpty) {
      _handleNoMoves();
    } else if (movableTokens.length == 1) {
       Future.delayed(const Duration(milliseconds: 300), () {
        if (!isMoving && diceRolled) {
          moveToken(movableTokens.first);
        }
       });
    }
  }

  bool hasPossibleMoves() {
    for (var token in currentPlayer.tokens) {
      if (canMoveToken(token)) return true;
    }
    return false;
  }

  bool isMoving = false;

  bool canMoveToken(LudoToken token) {
    if (!diceRolled || isMoving) return false;
    
    if (token.isInBase) {
      return diceValue == 6;
    }
    
    if (token.isFinished) return false;
    
    // Check if move exceeds home stretch
    if (token.position + diceValue > 56) return false;
    
    return true;
  }

  Future<void> moveToken(LudoToken token) async {
    if (!canMoveToken(token)) return;

    isMoving = true;
    notifyListeners();

    int stepsToMove = diceValue;
    bool wasInBase = token.isInBase;
    
    if (wasInBase) {
      token.position = 0;
      stepsToMove = 0;
    }

    for (int i = 0; i < stepsToMove; i++) {
      if (token.position < 56) {
        token.position++;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    // Check for capture
    bool captured = false;
    if (token.isOnPath) {
      captured = checkCapture(token);
    }

    // Check for win
    if (currentPlayer.hasWon) {
      gameFinished = true;
      winner = currentPlayer;
      if (isLoggedIn && (winner?.name == userName || winner?.name == "You")) {
        totalWins++;
        xpPoints += 500;
      }
      isMoving = false;
      _isAIActionInProgress = false;
      notifyListeners();
      return;
    }

    // Extra turn rules
    if (diceValue == 6 || token.isFinished || captured) {
      diceRolled = false;
      diceValue = 0;
      isMoving = false;
      _isAIActionInProgress = false; // Reset so AI can act again
      notifyListeners();
      
      if (currentPlayer.isAI && !gameFinished) {
        _triggerAITurn();
      }
    } else {
      isMoving = false;
      notifyListeners();
      nextTurn();
    }
  }

  bool checkCapture(LudoToken activeToken) {
    int globalPos = getGlobalPosition(activeToken.color, activeToken.position);
    bool anyCaptured = false;
    
    // Safe spots check
    List<int> safeSpots = [1, 9, 14, 22, 27, 35, 40, 48];
    if (safeSpots.contains(globalPos)) return false;

    for (var player in players) {
      if (player.color == activeToken.color) continue;
      
      for (var token in player.tokens) {
        if (token.isOnPath) {
          int otherGlobalPos = getGlobalPosition(token.color, token.position);
          if (globalPos == otherGlobalPos) {
            token.reset();
            anyCaptured = true;
          }
        }
      }
    }
    return anyCaptured;
  }

  int getGlobalPosition(LudoColor color, int relativePos) {
    if (relativePos < 0 || relativePos > 50) return -1;
    
    int startOffset = 0;
    switch (color) {
      case LudoColor.red: startOffset = 1; break;
      case LudoColor.green: startOffset = 14; break;
      case LudoColor.yellow: startOffset = 27; break;
      case LudoColor.blue: startOffset = 40; break;
    }
    
    return (startOffset + relativePos) % 52;
  }

  void nextTurn() {
    if (gameFinished) return;
    
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    diceRolled = false;
    diceValue = 0;
    _isAIActionInProgress = false; // Clear flag for next player
    notifyListeners();

    if (currentPlayer.isAI) {
      _triggerAITurn();
    }
  }

  Future<void> _triggerAITurn() async {
    if (!currentPlayer.isAI || gameFinished || _isAIActionInProgress) return;
    
    _isAIActionInProgress = true;
    int turnPlayerIndex = currentPlayerIndex;

    // Wait for user to see it's AI turn
    await Future.delayed(const Duration(milliseconds: 1000));
    if (currentPlayerIndex != turnPlayerIndex || gameFinished) return;
    
    rollDice();
    
    // Check if dice roll allowed move
    await Future.delayed(const Duration(milliseconds: 800));
    if (currentPlayerIndex != turnPlayerIndex || gameFinished) return;

    List<LudoToken> movableTokens = currentPlayer.tokens.where((t) => canMoveToken(t)).toList();
    
    if (movableTokens.isEmpty) {
      _handleNoMoves();
    } else {
      _runAIMove();
    }
  }

  void _runAIMove() {
    if (!currentPlayer.isAI || gameFinished || !diceRolled || isMoving) return;

    List<LudoToken> movableTokens = currentPlayer.tokens.where((t) => canMoveToken(t)).toList();
    if (movableTokens.isEmpty) return;

    LudoToken? bestToken;

    // 1. Try to finish
    for (var t in movableTokens) {
      if (t.position + diceValue == 56) {
        bestToken = t;
        break;
      }
    }

    // 2. Try to capture
    if (bestToken == null) {
      for (var t in movableTokens) {
        int targetPos = t.position + (t.isInBase ? 0 : diceValue);
        if (targetPos <= 50) {
          int globalPos = getGlobalPosition(t.color, targetPos);
          if (_willCaptureAt(globalPos, t.color)) {
            bestToken = t;
            break;
          }
        }
      }
    }

    // 3. Move out of base
    if (bestToken == null && diceValue == 6) {
      for (var t in movableTokens) {
        if (t.isInBase) {
          bestToken = t;
          break;
        }
      }
    }

    // 4. Furthest token
    if (bestToken == null) {
      movableTokens.sort((a, b) => b.position.compareTo(a.position));
      bestToken = movableTokens.first;
    }

    moveToken(bestToken);
  }

  bool _willCaptureAt(int globalPos, LudoColor avoidColor) {
    List<int> safeSpots = [1, 9, 14, 22, 27, 35, 40, 48];
    if (safeSpots.contains(globalPos)) return false;

    for (var player in players) {
      if (player.color == avoidColor) continue;
      for (var token in player.tokens) {
        if (token.isOnPath && getGlobalPosition(token.color, token.position) == globalPos) {
          return true;
        }
      }
    }
    return false;
  }
  Future<void> _handleNoMoves() async {
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    nextTurn();
    notifyListeners();
  }
}
