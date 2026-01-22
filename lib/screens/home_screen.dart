
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/ludo_logic.dart';
import '../utils/design_system.dart';
import 'dart:math' as math;



class AnimatedBackground extends StatelessWidget {
  final MankathaDesignSystem ds;
  const AnimatedBackground({super.key, required this.ds});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: ds.background)),
        
        // Dynamic Mesh Glows
        _MovingGlow(color: ds.accent.withOpacity(0.15), size: 600, top: -200, left: -100),
        _MovingGlow(color: (ds.theme == DashboardTheme.elite ? Colors.purple : ds.accent).withOpacity(0.1), size: 500, bottom: -150, right: -100),
        
        // Scanline/Grid Effect
        const Positioned.fill(child: _MovingGrid()),
        
        // Particle Field
        Positioned.fill(child: _ParticleField(ds: ds)),

        // Soft Animated Blurs
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [ds.accent.withOpacity(0.05), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovingGlow extends StatelessWidget {
  final Color color;
  final double size;
  final double? top, bottom, left, right;
  const _MovingGlow({required this.color, required this.size, this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .move(begin: const Offset(-30, -30), end: const Offset(30, 30), duration: 10.seconds, curve: Curves.easeInOut)
       .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 8.seconds),
    );
  }
}

class _MovingGrid extends StatelessWidget {
  const _MovingGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 10.seconds, color: Colors.white.withOpacity(0.02));
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticleField extends StatelessWidget {
  final MankathaDesignSystem ds;
  const _ParticleField({required this.ds});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(15, (index) {
        final random = math.Random(index);
        return _Particle(
          color: ds.accent.withOpacity(0.2),
          startX: random.nextDouble(),
          startY: random.nextDouble(),
          speed: random.nextDouble() * 5 + 5,
        );
      }),
    );
  }
}

class _Particle extends StatelessWidget {
  final Color color;
  final double startX, startY, speed;
  const _Particle({required this.color, required this.startX, required this.startY, required this.speed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: startX * constraints.maxWidth,
          top: startY * constraints.maxHeight,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ).animate(onPlay: (c) => c.repeat())
           .moveY(begin: 0, end: -100 - (speed * 10), duration: speed.seconds, curve: Curves.linear)
           .fadeOut(duration: speed.seconds, curve: Curves.easeIn),
        );
      }
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showPlaySubMenu = false;

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final ds = MankathaDesignSystem(logic.currentTheme);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: ds.background,
      body: Stack(
        children: [
          AnimatedBackground(ds: ds),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, logic, ds),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : size.width * 0.1, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(logic, ds, isMobile),
                      const SizedBox(height: 40),
                      _buildThemeSwitcher(logic, ds),
                      const SizedBox(height: 40),
                      AnimatedSwitcher(
                        duration: 400.ms,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: anim.drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero)),
                            child: child,
                          ),
                        ),
                        child: _showPlaySubMenu 
                          ? _buildPlayMenu(logic, ds, isMobile) 
                          : _buildMainMenu(logic, ds, isMobile),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, LudoLogic logic, MankathaDesignSystem ds) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      floating: true,
      title: Row(
        children: [
          Hero(
            tag: 'logo',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: ds.primaryGradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: ds.accent.withOpacity(0.3), blurRadius: 10)],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'MANKATHA',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 2,
              color: ds.textPrimary
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => logic.goToSettings(),
          icon: Icon(Icons.tune_rounded, color: ds.textSecondary),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildHeader(LudoLogic logic, MankathaDesignSystem ds, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WELCOME BACK,",
          style: GoogleFonts.outfit(
            color: ds.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                logic.userName.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: ds.textPrimary,
                  fontSize: isMobile ? 36 : 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
            _IconButton(
              icon: Icons.edit_outlined, 
              onTap: () => _showEditName(context, logic, ds),
              ds: ds,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildThemeSwitcher(LudoLogic logic, MankathaDesignSystem ds) {
    return Row(
      children: [
        Text("THEME", style: GoogleFonts.outfit(color: ds.textSecondary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
        const SizedBox(width: 16),
        _ThemeButton(
          label: "LIGHT", 
          isActive: logic.currentTheme == DashboardTheme.light,
          onTap: () => logic.setTheme(DashboardTheme.light),
          ds: ds,
        ),
        const SizedBox(width: 8),
        _ThemeButton(
          label: "DARK", 
          isActive: logic.currentTheme == DashboardTheme.dark,
          onTap: () => logic.setTheme(DashboardTheme.dark),
          ds: ds,
        ),
        const SizedBox(width: 8),
        _ThemeButton(
          label: "ELITE", 
          isActive: logic.currentTheme == DashboardTheme.elite,
          onTap: () => logic.setTheme(DashboardTheme.elite),
          ds: ds,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMainMenu(LudoLogic logic, MankathaDesignSystem ds, bool isMobile) {
    return Column(
      key: const ValueKey('main'),
      children: [
        _PremiumCard(
          title: "PLAY GAME",
          subtitle: "BATTLE FOR THE THRONE",
          icon: Icons.play_arrow_rounded,
          ds: ds,
          isPrimary: true,
          onTap: () => setState(() => _showPlaySubMenu = true),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: "HOW TO PLAY",
          subtitle: "MASTER THE MANKATHA RULES",
          icon: Icons.auto_stories_rounded,
          ds: ds,
          onTap: () => logic.goToHowToPlay(),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: "PREFERENCES",
          subtitle: "AUDIO AND NOTIFICATIONS",
          icon: Icons.settings_rounded,
          ds: ds,
          onTap: () => logic.goToSettings(),
        ),
      ],
    );
  }

  Widget _buildPlayMenu(LudoLogic logic, MankathaDesignSystem ds, bool isMobile) {
    return Column(
      key: const ValueKey('play'),
      children: [
        Row(
          children: [
            _IconButton(icon: Icons.close, onTap: () => setState(() => _showPlaySubMenu = false), ds: ds),
            const SizedBox(width: 16),
            Text("CHOOSE YOUR MODE", style: GoogleFonts.outfit(color: ds.textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 30),
        _PremiumCard(
          title: "SOLARYS AI",
          subtitle: "CHALLENGE OUR CYBER ENGINE",
          icon: Icons.bolt_rounded,
          ds: ds,
          isPrimary: true,
          onTap: () => logic.startSinglePlayerGame(),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: "MULTIVERSE",
          subtitle: "LOCAL MULTIPLAYER MADNESS",
          icon: Icons.public_rounded,
          ds: ds,
          onTap: () => logic.goToSetup(),
        ),
      ],
    );
  }

  void _showEditName(BuildContext context, LudoLogic logic, MankathaDesignSystem ds) {
    final controller = TextEditingController(text: logic.userName);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: 300.ms,
      pageBuilder: (c, a1, a2) => Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(32),
          decoration: ds.cardDecoration.copyWith(color: ds.cardBg),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("NICKNAME", style: GoogleFonts.outfit(color: ds.textPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  style: TextStyle(color: ds.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ds.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("CANCEL", style: TextStyle(color: ds.textSecondary)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            logic.loginUser(name: controller.text, email: logic.userEmail, phone: logic.userPhone);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: ds.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("UPDATE"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: ScaleTransition(scale: a1, child: child)),
    );
  }
}

class _PremiumCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final MankathaDesignSystem ds;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PremiumCard({required this.title, required this.subtitle, required this.icon, required this.ds, this.isPrimary = false, required this.onTap});

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ds = widget.ds;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: 200.ms,
          child: AnimatedContainer(
            duration: 200.ms,
            height: 120,
            decoration: widget.isPrimary 
              ? ds.cardDecoration.copyWith(
                  gradient: LinearGradient(colors: ds.primaryGradient),
                  boxShadow: [BoxShadow(color: ds.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                )
              : ds.cardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  Positioned(
                    right: -30, bottom: -30,
                    child: Icon(widget.icon, size: 160, color: (widget.isPrimary ? Colors.black : ds.accent).withOpacity(0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (widget.isPrimary ? Colors.black : ds.accent).withOpacity(0.1),
                            shape: BoxShape.circle
                          ),
                          child: Icon(widget.icon, color: widget.isPrimary ? Colors.black : ds.accent, size: 24),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: GoogleFonts.outfit(color: widget.isPrimary ? Colors.black : ds.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              Text(widget.subtitle, style: GoogleFonts.outfit(color: (widget.isPrimary ? Colors.black : ds.textSecondary).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: widget.isPrimary ? Colors.black : ds.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final MankathaDesignSystem ds;
  const _IconButton({required this.icon, required this.onTap, required this.ds});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ds.cardDecoration.copyWith(borderRadius: BorderRadius.circular(16), color: ds.cardBg),
        child: Icon(icon, color: ds.accent, size: 20),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final MankathaDesignSystem ds;
  const _ThemeButton({required this.label, required this.isActive, required this.onTap, required this.ds});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ds.accent : ds.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? ds.accent : ds.glassBorder),
        ),
        child: Text(
          label, 
          style: GoogleFonts.outfit(
            color: isActive ? (ds.theme == DashboardTheme.light ? Colors.white : Colors.black) : ds.textSecondary, 
            fontSize: 10, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          )
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LudoLogic>();
    final ds = MankathaDesignSystem(logic.currentTheme);

    return Container(
      width: 280,
      color: ds.cardBg,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: LinearGradient(colors: ds.primaryGradient), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('MANKATHA', style: GoogleFonts.outfit(color: ds.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 60),
          _SideItem(label: "DASHBOARD", icon: Icons.grid_view_rounded, isActive: logic.status == GameStatus.home, onTap: () => logic.goToHome(), ds: ds),
          _SideItem(label: "HOW TO PLAY", icon: Icons.auto_stories_rounded, isActive: logic.status == GameStatus.howToPlay, onTap: () => logic.goToHowToPlay(), ds: ds),
          _SideItem(label: "SETTINGS", icon: Icons.tune_rounded, isActive: logic.status == GameStatus.settings, onTap: () => logic.goToSettings(), ds: ds),
          const Spacer(),
          Text("v1.2.0-Elite", style: GoogleFonts.outfit(color: ds.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final MankathaDesignSystem ds;
  const _SideItem({required this.label, required this.icon, required this.isActive, required this.onTap, required this.ds});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: isActive ? ds.accent : ds.textSecondary, size: 20),
      title: Text(label, style: GoogleFonts.outfit(color: isActive ? ds.textPrimary : ds.textSecondary, fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, fontSize: 13, letterSpacing: 1.2)),
    );
  }
}
