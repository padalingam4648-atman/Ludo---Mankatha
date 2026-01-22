
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/ludo_logic.dart';
import '../utils/security_service.dart';
import '../utils/design_system.dart';
import 'home_screen.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _emailVerified = false;
  bool _phoneVerified = false;
  
  String? _emailError;
  String? _phoneError;
  String _passwordStrength = 'None';
  double _strengthValue = 0.0;
  Color _strengthColor = Colors.grey;

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = null;
        _emailVerified = false;
      } else if (!RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.com$').hasMatch(value)) {
        _emailError = 'Must be lowercase and end with .com';
        _emailVerified = false;
      } else {
        _emailError = null;
        _emailVerified = true;
      }
    });
  }

  void _validatePhone(String value) {
    setState(() {
      if (value.isEmpty) {
        _phoneError = null;
        _phoneVerified = false;
      } else if (value.length != 10) {
        _phoneError = 'Must be exactly 10 digits';
        _phoneVerified = false;
      } else {
        _phoneError = null;
        _phoneVerified = true;
      }
    });
  }

  void _checkPasswordStrength(String value) {
    int strength = 0;
    if (value.length >= 8) strength++;
    if (value.contains(RegExp(r'[A-Z]'))) strength++;
    if (value.contains(RegExp(r'[a-z]'))) strength++;
    if (value.contains(RegExp(r'[0-9]'))) strength++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    setState(() {
      _strengthValue = strength / 5;
      if (strength == 0) {
        _passwordStrength = 'None';
        _strengthColor = Colors.grey;
      } else if (strength <= 2) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.redAccent;
      } else if (strength <= 4) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orangeAccent;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.greenAccent;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final ds = MankathaDesignSystem(logic.currentTheme);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ds.background,
      drawer: isMobile ? const Drawer(child: Sidebar()) : null,
      body: Stack(
        children: [
          AnimatedBackground(ds: ds),
          Row(
            children: [
              if (!isMobile) const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Icons.menu_rounded, color: ds.textPrimary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 20 : 40),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: EdgeInsets.all(isMobile ? 24 : 40),
                            decoration: ds.cardDecoration.copyWith(color: ds.cardBg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'PROFILE EDITOR',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: ds.textPrimary,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _buildField(
                                  label: 'FULL NAME',
                                  controller: _nameController,
                                  icon: Icons.person_rounded,
                                  ds: ds,
                                ),
                                _buildField(
                                  label: 'EMAIL ADDRESS',
                                  controller: _emailController,
                                  icon: Icons.email_rounded,
                                  onChanged: _validateEmail,
                                  errorText: _emailError,
                                  isSuccess: _emailVerified,
                                  helperText: 'e.g. user@example.com',
                                  ds: ds,
                                ),
                                const SizedBox(height: 20),
                                _buildField(
                                  label: 'MOBILE NUMBER',
                                  controller: _phoneController,
                                  icon: Icons.phone_android_rounded,
                                  onChanged: _validatePhone,
                                  errorText: _phoneError,
                                  isSuccess: _phoneVerified,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                                  helperText: '10 digit numeric only',
                                  ds: ds,
                                ),
                                const SizedBox(height: 20),
                                _buildField(
                                  label: 'PASSWORD',
                                  controller: _passwordController,
                                  icon: Icons.lock_rounded,
                                  onChanged: _checkPasswordStrength,
                                  obscureText: true,
                                  helperText: 'Min 8 chars, mixed case, symbols',
                                  ds: ds,
                                ),
                                const SizedBox(height: 12),
                                if (_passwordController.text.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('STRENGTH: $_passwordStrength', 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _strengthColor)),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: _strengthValue,
                                          backgroundColor: ds.background,
                                          valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn().slideY(begin: 0.1),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: (_emailVerified && _phoneVerified && _nameController.text.isNotEmpty)
                                        ? () {
                                            logic.loginUser(
                                              name: _nameController.text,
                                              email: _emailController.text,
                                              phone: _phoneController.text,
                                              password: SecurityService.hashPassword(_passwordController.text),
                                            );
                                            logic.goToHome();
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ds.accent,
                                      foregroundColor: ds.theme == DashboardTheme.light ? Colors.white : Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 0,
                                    ),
                                    child: const Text('SAVE & LOGIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () => logic.goToHome(),
                                  child: Text('CANCEL', style: TextStyle(color: ds.textSecondary)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label, 
    required TextEditingController controller, 
    required IconData icon, 
    required MankathaDesignSystem ds,
    void Function(String)? onChanged,
    String? errorText,
    bool isSuccess = false,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ds.textSecondary, letterSpacing: 1.5)),
            if (isSuccess)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14).animate().fadeIn().scale(),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: ds.textPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isSuccess ? Colors.greenAccent : (errorText != null ? Colors.redAccent : ds.accent), size: 20),
            filled: true,
            fillColor: ds.background,
            hintText: helperText,
            hintStyle: TextStyle(color: ds.textSecondary.withOpacity(0.3), fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide(color: isSuccess ? Colors.greenAccent.withOpacity(0.5) : (errorText != null ? Colors.redAccent.withOpacity(0.5) : ds.glassBorder))
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide(color: isSuccess ? Colors.greenAccent : (errorText != null ? Colors.redAccent : ds.accent), width: 2)
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ).animate().fadeIn().shake(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final ds = MankathaDesignSystem(logic.currentTheme);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ds.background,
      drawer: isMobile ? const Drawer(child: Sidebar()) : null,
      body: Stack(
        children: [
          AnimatedBackground(ds: ds),
          Row(
            children: [
              if (!isMobile) const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Icons.menu_rounded, color: ds.textPrimary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          margin: EdgeInsets.all(isMobile ? 20 : 0),
                          padding: EdgeInsets.all(isMobile ? 24 : 40),
                          decoration: ds.cardDecoration.copyWith(color: ds.cardBg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('SETTINGS', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: ds.textPrimary, letterSpacing: 2)),
                              const SizedBox(height: 40),
                              _buildToggle(
                                label: 'MUSIC',
                                value: logic.musicEnabled,
                                onChanged: (_) => logic.toggleMusic(),
                                ds: ds,
                              ),
                              const SizedBox(height: 20),
                              _buildToggle(
                                label: 'SOUND EFFECTS',
                                value: true, 
                                onChanged: (_) {},
                                ds: ds,
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () => logic.goToHome(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ds.accent,
                                    foregroundColor: ds.theme == DashboardTheme.light ? Colors.white : Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({required String label, required bool value, required ValueChanged<bool> onChanged, required MankathaDesignSystem ds}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: ds.textPrimary, fontWeight: FontWeight.bold)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ds.accent,
        ),
      ],
    );
  }
}

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final ds = MankathaDesignSystem(logic.currentTheme);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: ds.background,
      drawer: isMobile ? const Drawer(child: Sidebar()) : null,
      body: Stack(
        children: [
          AnimatedBackground(ds: ds),
          Row(
            children: [
              if (!isMobile) const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Icons.menu_rounded, color: ds.textPrimary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 30 : 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOW TO PLAY', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: ds.textPrimary, letterSpacing: 2)),
                            const SizedBox(height: 40),
                            _buildRule(
                              'The Objective',
                              'The objective of Ludo is to move all four of your tokens from your base around the board and into your home triangle before your opponents do.',
                              ds,
                            ),
                            _buildRule(
                              'Moving Tokens',
                              'Roll the dice to move. A "6" is required to move a token from the base to the starting point. If you roll a 6, you also get an extra turn.',
                              ds,
                            ),
                            _buildRule(
                              'Capture & Safe Zones',
                              'Landing on an opponent\'s token sends them back to the base. Safe zones (marked with stars) protect your tokens from being captured.',
                              ds,
                            ),
                            _buildRule(
                              'Winning the Game',
                              'All four tokens must reach the home triangle. The exact number required to enter home must be rolled.',
                              ds,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: 250,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () => logic.goToHome(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ds.accent,
                                  foregroundColor: ds.theme == DashboardTheme.light ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String title, String desc, MankathaDesignSystem ds) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(color: ds.accent, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: ds.textSecondary, fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
