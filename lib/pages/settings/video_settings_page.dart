import 'package:flutter/material.dart';
import '../../services/theme/app_theme_service.dart';
import '../../services/player/player_settings.dart';
import '../../widgets/settings/settings_controls.dart';

class VideoSettingsPage extends StatefulWidget {
  const VideoSettingsPage({super.key});

  @override
  State<VideoSettingsPage> createState() => _VideoSettingsPageState();
}

class _VideoSettingsPageState extends State<VideoSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final palette = AppThemeService.currentPalette.value;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1017),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video & Upscaling',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── Top Intro Banner ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primaryColor.withValues(alpha: 0.12),
                      const Color(0xFF00E5FF).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: palette.primaryColor.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: palette.primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: palette.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anime4K Neural Upscaling',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Real-time GLSL anime upscaling and line reconstruction running directly on libmpv GPU shaders.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section: Presets ──
              const Text(
                'UPSCALING PRESETS',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),

              ValueListenableBuilder<Anime4KPreset>(
                valueListenable: PlayerSettings.anime4kPreset,
                builder: (context, currentPreset, _) {
                  return Column(
                    children: [
                      _buildPresetCard(
                        preset: Anime4KPreset.off,
                        title: 'Disabled (Off)',
                        subtitle: 'Standard playback. Lowest GPU overhead.',
                        tag: 'Standard',
                        tagColor: Colors.white38,
                        icon: Icons.block_rounded,
                        isSelected: currentPreset == Anime4KPreset.off,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.off),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeAFast,
                        title: 'Mode A — Fast / Balanced',
                        subtitle: 'Sharp lines & 2x upscale. Balanced GPU load.',
                        tag: 'Recommended',
                        tagColor: const Color(0xFF10B981),
                        icon: Icons.speed_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeAFast,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeAFast),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeAHQ,
                        title: 'Mode A — High Quality (Ultra)',
                        subtitle: 'Best quality via Large CNNs. For discrete GPUs.',
                        tag: 'Ultra Quality',
                        tagColor: const Color(0xFF7C5CFF),
                        icon: Icons.diamond_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeAHQ,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeAHQ),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeB,
                        title: 'Mode B — Soft / Denoise',
                        subtitle: 'Soft denoise. Best for blurry or older anime.',
                        tag: 'Denoise',
                        tagColor: const Color(0xFF00E5FF),
                        icon: Icons.blur_linear_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeB,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeB),
                      ),
                      const SizedBox(height: 10),
                      _buildPresetCard(
                        preset: Anime4KPreset.modeC,
                        title: 'Mode C — Deblur & Scale',
                        subtitle: 'Strong deblur. Best for 480p/720p sources.',
                        tag: 'Deblur',
                        tagColor: const Color(0xFFF59E0B),
                        icon: Icons.high_quality_rounded,
                        isSelected: currentPreset == Anime4KPreset.modeC,
                        palette: palette,
                        onTap: () => PlayerSettings.setAnime4kPreset(Anime4KPreset.modeC),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── Section: Details & Performance Note ──
              const Text(
                'PIPELINE & COMPATIBILITY',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E121B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Playback Start Application',
                      description: 'Shader changes apply to the next video you open.',
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      icon: Icons.memory_rounded,
                      title: 'Hardware Decoder Acceleration',
                      description: 'Hardware decoding feeds the GPU before the shader pass.',
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInfoRow(
                      icon: Icons.devices_rounded,
                      title: 'Platform Recommendation',
                      description: 'HQ for desktop GPUs; Fast for smooth mobile playback.',
                    ),
                  ],
                ),
              ),

              // ── Section: Hardware Acceleration & Decoding Engine ──
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'HARDWARE ACCELERATION & DECODING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: palette.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'All Platforms',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: palette.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ValueListenableBuilder<HardwareAccelerationMode>(
                valueListenable: PlayerSettings.hwdecMode,
                builder: (context, currentMode, _) {
                  return Column(
                    children: [
                      _buildHwdecCard(
                        mode: HardwareAccelerationMode.autoSafe,
                        title: 'Auto-Safe (Recommended)',
                        subtitle: 'GPU decoding with safe fallbacks. Best for most devices.',
                        badgeText: 'Default',
                        badgeColor: palette.primaryColor,
                        icon: Icons.speed_rounded,
                        currentMode: currentMode,
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _buildHwdecCard(
                        mode: HardwareAccelerationMode.software,
                        title: 'Software Decoding (Crash-Proof)',
                        subtitle: 'CPU decoding. Fixes black screens on old GPUs and VMs.',
                        badgeText: '100% Reliable',
                        badgeColor: const Color(0xFF10B981),
                        icon: Icons.memory_rounded,
                        currentMode: currentMode,
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _buildHwdecCard(
                        mode: HardwareAccelerationMode.forceHardware,
                        title: 'Direct Hardware',
                        subtitle: 'Direct GPU decoding. Fastest on modern GPUs.',
                        badgeText: 'Max GPU',
                        badgeColor: Colors.amber,
                        icon: Icons.bolt_rounded,
                        currentMode: currentMode,
                        palette: palette,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Auto-Recover Black Screens Toggle Card
              ValueListenableBuilder<bool>(
                valueListenable: PlayerSettings.autoRecoverBlackScreen,
                builder: (context, autoRecover, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: autoRecover
                          ? palette.primaryColor.withValues(alpha: 0.08)
                          : const Color(0xFF0E121B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: autoRecover
                            ? palette.primaryColor.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                        width: autoRecover ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: autoRecover
                                ? palette.primaryColor.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            color: autoRecover ? palette.primaryColor : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Auto-Recover Black Screens',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Active Watchdog',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Falls back to software decoding if video frames or GPU decoding fail at startup.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SettingsToggleSwitch(
                          value: autoRecover,
                          semanticsLabel: 'Auto-Recover Black Screens',
                          onChanged: (val) {
                            PlayerSettings.setAutoRecoverBlackScreen(val);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Section: Android Rendering Engine ──
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'ANDROID RENDERING ENGINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: palette.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Android',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: palette.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: PlayerSettings.enableSurfaceProducer,
                builder: (context, isSurface, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSurface
                          ? palette.primaryColor.withValues(alpha: 0.08)
                          : const Color(0xFF0E121B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSurface
                            ? palette.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSurface ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSurface
                                ? palette.primaryColor.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.layers_rounded,
                            color: isSurface ? palette.primaryColor : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Direct Surface (SurfaceView)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isSurface ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isSurface ? 'Zero-Copy' : 'Off (TextureView)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSurface ? const Color(0xFF10B981) : Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Boosts 4K/60fps playback and battery life on Android. Disable if you see glitches.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SettingsToggleSwitch(
                          value: isSurface,
                          semanticsLabel: 'Android Surface Producer Rendering',
                          onChanged: (val) {
                            PlayerSettings.setEnableSurfaceProducer(val);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Section: Touch Gestures ──
              const SizedBox(height: 28),
              Text(
                'TOUCH GESTURES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: palette.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: PlayerSettings.enablePlayerGestures,
                builder: (context, gestures, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gestures
                          ? palette.primaryColor.withValues(alpha: 0.08)
                          : const Color(0xFF0E121B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gestures
                            ? palette.primaryColor
                            : Colors.white.withValues(alpha: 0.08),
                        width: gestures ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: gestures
                                ? palette.primaryColor.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.swipe_rounded,
                            color: gestures ? palette.primaryColor : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Player Touch Gestures',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    gestures ? 'Enabled' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: gestures ? const Color(0xFF10B981) : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Left side swipes adjust brightness, right side volume, long-press fast-forwards.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white54,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SettingsToggleSwitch(
                          value: gestures,
                          semanticsLabel: 'Player Touch Gestures',
                          onChanged: (val) {
                            PlayerSettings.setEnablePlayerGestures(val);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required Anime4KPreset preset,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required bool isSelected,
    required AppThemePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.primaryColor.withValues(alpha: 0.08)
              : const Color(0xFF0E121B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? palette.primaryColor
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primaryColor.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? palette.primaryColor : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tagColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHwdecCard({
    required HardwareAccelerationMode mode,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required HardwareAccelerationMode currentMode,
    required dynamic palette,
  }) {
    final isSelected = mode == currentMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => PlayerSettings.setHwdecMode(mode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.primaryColor.withValues(alpha: 0.10)
                : const Color(0xFF0E121B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? palette.primaryColor
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.primaryColor.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? palette.primaryColor : Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
