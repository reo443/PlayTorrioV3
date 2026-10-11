import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/manga/manga_settings.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import '../../../widgets/settings/settings_controls.dart';

class MangaSettingsPage extends StatefulWidget {
  const MangaSettingsPage({super.key});

  @override
  State<MangaSettingsPage> createState() => _MangaSettingsPageState();
}

class _MangaSettingsPageState extends State<MangaSettingsPage> {
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
          'Manga UI & Reader Atmosphere',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. Ambient Background Lighting ──
              _buildSectionHeader('AMBIENT BACKGROUND LIGHTING & MOVING GLOWS'),
              const SizedBox(height: 12),
              _buildAmbientLightsCard(palette),

              const SizedBox(height: 28),

              // 2. Discovery & Cards ──
              _buildSectionHeader('DISCOVERY & POSTER CARDS'),
              const SizedBox(height: 12),
              _buildCardsConfigCard(palette),

              const SizedBox(height: 28),

              // 3. Manga Reader Customization ──
              _buildSectionHeader('MANGA READER & CHAPTER VIEWER'),
              const SizedBox(height: 12),
              _buildReaderConfigCard(palette),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
    );
  }

  // 1. Ambient Lighting Card ──
  Widget _buildAmbientLightsCard(AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.enableAmbientLights,
            builder: (context, enabled, _) {
              return SettingsToggleRow(
                label: 'Enable Moving Ambient Lighting',
                description: 'Soft flowing glowing orbs and aurora waves themed to ${palette.name}',
                value: enabled,
                onChanged: (val) => MangaSettings.setEnableAmbientLights(val),
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),

          // Pattern selector
          Text(
            'Lighting Flow Pattern',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<AmbientLightPattern>(
            valueListenable: MangaSettings.ambientLightPattern,
            builder: (context, currentPattern, _) {
              return SettingsSegmentedControl<AmbientLightPattern>(
                values: AmbientLightPattern.values,
                selected: currentPattern,
                onChanged: (p) => MangaSettings.setAmbientLightPattern(p),
                label: (p) => p.label,
              );
            },
          ),

          const SizedBox(height: 16),

          // Intensity Slider
          ValueListenableBuilder<double>(
            valueListenable: MangaSettings.ambientLightIntensity,
            builder: (context, intensity, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Glow Strength / Opacity', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${(intensity * 100).round()}%', style: TextStyle(color: palette.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: palette.primaryColor,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: palette.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: intensity,
                      min: 0.08,
                      max: 0.60,
                      divisions: 26,
                      onChanged: (val) => MangaSettings.setAmbientLightIntensity(val),
                    ),
                  ),
                ],
              );
            },
          ),

          // Speed Slider
          ValueListenableBuilder<double>(
            valueListenable: MangaSettings.ambientLightSpeed,
            builder: (context, speed, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Motion Drift Speed', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${speed.toStringAsFixed(1)}x', style: TextStyle(color: palette.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: palette.primaryColor,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: palette.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: speed,
                      min: 0.2,
                      max: 3.0,
                      divisions: 14,
                      onChanged: (val) => MangaSettings.setAmbientLightSpeed(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // Atmosphere Live Preview Box
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  const Positioned.fill(child: AnimatedAmbientBackground()),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: palette.primaryColor, size: 14),
                          const SizedBox(width: 6),
                          const Text('Live Atmosphere Preview', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Discovery & Cards Config Card ──
  Widget _buildCardsConfigCard(AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContinueReading,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show "Continue Reading" Slider',
                description: 'Display your active reading history at the top of the Manga page',
                value: show,
                onChanged: (val) => MangaSettings.setShowContinueReading(val),
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),

          Text('Manga Poster Card Density', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaCardDensity>(
            valueListenable: MangaSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SettingsSegmentedControl<MangaCardDensity>(
                values: MangaCardDensity.values,
                selected: currentDensity,
                onChanged: (d) => MangaSettings.setCardDensity(d),
                label: (d) => d.label,
              );
            },
          ),

          const SizedBox(height: 14),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showContentTypeBadge,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show Content Type Badge (Manga/Manhwa)',
                value: show,
                onChanged: (val) => MangaSettings.setShowContentTypeBadge(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showMangaYear,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show Publication Year on Cards',
                value: show,
                onChanged: (val) => MangaSettings.setShowMangaYear(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.ambientCardGlow,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Poster Card Hover Glow Effect',
                value: show,
                onChanged: (val) => MangaSettings.setAmbientCardGlow(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showScrollTrack,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show Desktop Scroll Track',
                value: show,
                onChanged: (val) => MangaSettings.setShowScrollTrack(val),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Reader Configuration Card ──
  Widget _buildReaderConfigCard(AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default Reading Mode
          Text('Default Reading Mode', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReadingMode>(
            valueListenable: MangaSettings.defaultReadingMode,
            builder: (context, currentMode, _) {
              return SettingsSegmentedControl<MangaReadingMode>(
                values: MangaReadingMode.values,
                selected: currentMode,
                onChanged: (m) => MangaSettings.setDefaultReadingMode(m),
                label: (m) => m.label,
              );
            },
          ),

          const SizedBox(height: 16),

          // Reader Max Width
          Text('Page Reading Width Constraint', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReaderMaxWidth>(
            valueListenable: MangaSettings.readerMaxWidth,
            builder: (context, currentWidth, _) {
              return SettingsSegmentedControl<MangaReaderMaxWidth>(
                values: MangaReaderMaxWidth.values,
                selected: currentWidth,
                onChanged: (w) => MangaSettings.setReaderMaxWidth(w),
                label: (w) => w.label,
              );
            },
          ),

          const SizedBox(height: 16),

          // Reader Background Color
          Text('Reader Background Atmosphere', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaReaderBackground>(
            valueListenable: MangaSettings.readerBackground,
            builder: (context, currentBg, _) {
              return SettingsSegmentedControl<MangaReaderBackground>(
                values: MangaReaderBackground.values,
                selected: currentBg,
                onChanged: (b) => MangaSettings.setReaderBackground(b),
                label: (b) => b.label,
                indicator: (b) => Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: b.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Control Bar Style
          Text('Control Toolbar Style', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<MangaControlBarStyle>(
            valueListenable: MangaSettings.readerControlBarStyle,
            builder: (context, currentStyle, _) {
              return SettingsSegmentedControl<MangaControlBarStyle>(
                values: MangaControlBarStyle.values,
                selected: currentStyle,
                onChanged: (s) => MangaSettings.setReaderControlBarStyle(s),
                label: (s) => s.label,
              );
            },
          ),

          const SizedBox(height: 16),

          // Page Gap slider (for webtoon mode)
          ValueListenableBuilder<double>(
            valueListenable: MangaSettings.pageGap,
            builder: (context, gap, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vertical Page Gap', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${gap.round()} px', style: TextStyle(color: palette.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: palette.primaryColor,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: palette.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: gap,
                      min: 0,
                      max: 24,
                      divisions: 12,
                      onChanged: (val) => MangaSettings.setPageGap(val),
                    ),
                  ),
                ],
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showPageDeck,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show Page Deck / Thumbnail Previews',
                description: 'Interactive visual tray of thumbnail previews for instant page jumping',
                value: show,
                onChanged: (val) => MangaSettings.setShowPageDeck(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.showPageScrubber,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Show Page Scrubber Slider',
                value: show,
                onChanged: (val) => MangaSettings.setShowPageScrubber(val),
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: MangaSettings.enableNextChapterDeck,
            builder: (context, show, _) {
              return SettingsToggleRow(
                label: 'Enable Next Chapter Preview Card Deck',
                description: 'Rich glass deck card at the end of each chapter with chapter art and direct launch',
                value: show,
                onChanged: (val) => MangaSettings.setEnableNextChapterDeck(val),
              );
            },
          ),
        ],
      ),
    );
  }
}
