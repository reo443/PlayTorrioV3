import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/theme/custom_background_service.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/my_list/my_list_service.dart';
import '../../../services/simkl/simkl_service.dart';
import '../../../services/trakt/trakt_service.dart';
import '../../../widgets/common/animated_ambient_background.dart';
import 'custom_background_settings_page.dart';

class HomeUiSettingsPage extends StatefulWidget {
  const HomeUiSettingsPage({super.key});

  @override
  State<HomeUiSettingsPage> createState() => _HomeUiSettingsPageState();
}

class _HomeUiSettingsPageState extends State<HomeUiSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final myListCount = MyListService.items.value.length;

    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, _, __) => _buildPage(myListCount),
    );
  }

  Widget _buildPage(int myListCount) {
    return Scaffold(
      backgroundColor: AppThemeService.currentPalette.value.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            SizedBox(height: 1),
            Text(
              'Personalize your app',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF9299AB)),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // ── 1. Appearance & Current Theme ──
              _buildThemeCard(),

              const SizedBox(height: 28),

              // ── 2. Ambient Background Lighting & Moving Glows ──
              Text(
                'AMBIENT BACKGROUND LIGHTING & MOVING GLOWS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildAmbientLightsCard(),

              const SizedBox(height: 28),

              // ── 2b. Custom Wallpaper & Background Photo ──
              Text(
                'CUSTOM BACKGROUND & WALLPAPER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<CustomBackgroundData>(
                valueListenable: CustomBackgroundService.notifier,
                builder: (context, customBg, _) {
                  final hasWallpaper = customBg.hasCustomBackground;
                  final palette = AppThemeService.currentPalette.value;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomBackgroundSettingsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppThemeService.currentPalette.value.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasWallpaper
                              ? palette.primaryColor.withValues(alpha: 0.40)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.wallpaper_rounded,
                              color: palette.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Custom Wallpaper & Lighting Blend',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hasWallpaper
                                      ? 'Custom background active with ambient light blending'
                                      : 'Upload photos or choose curated dark wallpapers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // ── 3. "Because you have on your list" Section ──
              Text(
                'SMART RECOMMENDATIONS ("BECAUSE YOU HAVE ON YOUR LIST")',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildSimilarRecommendationsCard(myListCount),

              const SizedBox(height: 28),

              // ── 4. Hero Carousel & Spotlight ──
              Text(
                'HERO BANNER & SPOTLIGHT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildHeroControlsCard(),

              const SizedBox(height: 28),

              // ── 5. Card Layout & Poster Density ──
              Text(
                'POSTER CARDS & DENSITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildCardDensityCard(),

              const SizedBox(height: 28),

              // ── 5b. Details Page Background ──
              Text(
                'DETAILS PAGE BACKGROUND',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailsBackgroundCard(),

              const SizedBox(height: 28),

              // ── 6. Feature Shortcuts & Buttons ──
              Text(
                'HEADER SHORTCUTS & BUTTONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureTogglesCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact current-theme card. Tapping opens the theme picker sheet.
  Widget _buildThemeCard() {
    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, current, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showThemePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppThemeService.currentPalette.value.cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF292D39)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          current.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF4F6FC),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Current theme',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9299AB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AccentDots(primary: current.primaryColor, accent: current.accentColor),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Color(0xFF9299AB),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ThemePickerSheet(
        current: AppThemeService.currentPalette.value,
      ),
    );
  }

  Widget _buildAmbientLightsCard() {
    final palette = AppThemeService.currentPalette.value;

    return ValueListenableBuilder<bool>(
      valueListenable: HomePageSettings.enableAmbientLights,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppThemeService.currentPalette.value.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? palette.primaryColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Mini Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: AnimatedAmbientBackground(),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_motion_rounded, size: 14, color: palette.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE LIGHTING ENGINE PREVIEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Master Switch
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.blur_linear_rounded,
                      color: palette.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moving Ambient Lights & Glows',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Drifting faded light waves & floating color orbs in background',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: palette.primaryColor,
                    onChanged: (val) {
                      HomePageSettings.setEnableAmbientLights(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Lighting Pattern / Position
                Text(
                  'Lighting Pattern & Position',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<AmbientLightPattern>(
                  valueListenable: HomePageSettings.ambientLightPattern,
                  builder: (context, currentPattern, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AmbientLightPattern.values.map((pat) {
                        final isSelected = pat == currentPattern;
                        return ChoiceChip(
                          label: Text(pat.label),
                          selected: isSelected,
                          selectedColor: palette.primaryColor.withValues(alpha: 0.25),
                          backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
                          labelStyle: TextStyle(
                            color: isSelected ? palette.primaryColor : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? palette.primaryColor.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              HomePageSettings.setAmbientLightPattern(pat);
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Strength / Intensity Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightIntensity,
                  builder: (context, intensity, _) {
                    final percent = (intensity * 200).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Glow Strength / Intensity',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: intensity,
                            min: 0.05,
                            max: 0.50,
                            divisions: 18,
                            onChanged: (val) => HomePageSettings.setAmbientLightIntensity(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Motion Speed Slider
                ValueListenableBuilder<double>(
                  valueListenable: HomePageSettings.ambientLightSpeed,
                  builder: (context, speed, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Motion Flow Speed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '${speed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: palette.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.primaryColor,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                            thumbColor: palette.primaryColor,
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: speed,
                            min: 0.4,
                            max: 2.5,
                            divisions: 21,
                            onChanged: (val) => HomePageSettings.setAmbientLightSpeed(val),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimilarRecommendationsCard(int myListCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeService.currentPalette.value.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppThemeService.currentPalette.value.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Recommendations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Configure personalized & algorithmic recommendation sliders',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 8),

          // 1. Because You Have... (My List)
          _buildRecommendationToggleRow(
            title: '"Because You Have..." (My List)',
            subtitle: 'BestSimilar recommendations based on titles saved in My List',
            listenable: HomePageSettings.enableSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableSimilar(val);
              setState(() {});
            },
          ),

          // 2. Because You're Watching... (Continue Watching)
          _buildRecommendationToggleRow(
            title: '"Because You\'re Watching..."',
            subtitle: 'BestSimilar recommendations based on active Continue Watching titles',
            listenable: HomePageSettings.enableWatchingSimilar,
            onChanged: (val) {
              HomePageSettings.setEnableWatchingSimilar(val);
              setState(() {});
            },
          ),

          // 3. Trakt Recommendations
          FutureBuilder<bool>(
            future: TraktService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: 'Trakt Recommendations',
                subtitle: isAuthed
                    ? 'Personalized recommendations computed by Trakt'
                    : 'Requires Trakt login in Settings -> Trakt',
                listenable: HomePageSettings.enableTraktRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAuthed ? const Color(0xFFED1C24) : Colors.white12).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isAuthed ? const Color(0xFFED1C24) : Colors.white24).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed ? 'CONNECTED' : 'DISCONNECTED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isAuthed ? const Color(0xFFFF5252) : Colors.white38,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableTraktRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          // 4. Simkl Recommendations
          FutureBuilder<bool>(
            future: SimklService.instance.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthed = snapshot.data ?? false;
              return _buildRecommendationToggleRow(
                title: 'Simkl Recommendations',
                subtitle: isAuthed
                    ? 'Top-rated & personalized suggestions from Simkl'
                    : 'Requires Simkl login in Settings -> Simkl',
                listenable: HomePageSettings.enableSimklRecommendations,
                trailingExtra: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAuthed ? const Color(0xFF00B2FF) : Colors.white12).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isAuthed ? const Color(0xFF00B2FF) : Colors.white24).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isAuthed ? 'CONNECTED' : 'DISCONNECTED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isAuthed ? const Color(0xFF40C4FF) : Colors.white38,
                    ),
                  ),
                ),
                onChanged: (val) {
                  HomePageSettings.setEnableSimklRecommendations(val);
                  setState(() {});
                },
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Position Dropdown
          Text(
            'Recommendation Sliders Position on Home Page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<SimilarSectionPosition>(
            valueListenable: HomePageSettings.similarPosition,
            builder: (context, pos, _) {
              return DropdownButtonFormField<SimilarSectionPosition>(
                value: pos,
                dropdownColor: AppThemeService.currentPalette.value.cardBackgroundColor,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                items: SimilarSectionPosition.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  );
                }).toList(),
                onChanged: (newPos) {
                  if (newPos != null) {
                    HomePageSettings.setSimilarPosition(newPos);
                    setState(() {});
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationToggleRow({
    required String title,
    required String subtitle,
    required ValueListenable<bool> listenable,
    required ValueChanged<bool> onChanged,
    Widget? trailingExtra,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, enabled, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (trailingExtra != null) ...[
                          const SizedBox(width: 8),
                          trailingExtra,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: enabled,
                activeColor: AppThemeService.currentPalette.value.primaryColor,
                onChanged: onChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroControlsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeService.currentPalette.value.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master Spotlight Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.movie_filter_rounded,
                      color: AppThemeService.currentPalette.value.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Hero Spotlight Banner',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Featured rotation banner at the top of the home page',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    activeColor: AppThemeService.currentPalette.value.primaryColor,
                    onChanged: (val) {
                      HomePageSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableSpotlight,
            builder: (context, enabled, _) {
              if (!enabled) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 12),

                  // Hero Style Selector
                  Text(
                    'Spotlight Style',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<HeroStyle>(
                    valueListenable: HomePageSettings.heroStyle,
                    builder: (context, currentStyle, _) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: HeroStyle.values.map((style) {
                          final isSelected = style == currentStyle;
                          return ChoiceChip(
                            label: Text(style.label),
                            selected: isSelected,
                            selectedColor: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.25),
                            backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppThemeService.currentPalette.value.primaryColor : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                HomePageSettings.setHeroStyle(style);
                                setState(() {});
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

          // Auto-Rotate Switch & Interval
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.heroAutoRotate,
            builder: (context, autoRotate, _) {
              return Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Rotate Spotlight',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cycles through featured titles automatically',
                              style: TextStyle(fontSize: 11.5, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: autoRotate,
                        activeColor: AppThemeService.currentPalette.value.primaryColor,
                        onChanged: (val) {
                          HomePageSettings.setHeroAutoRotate(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (autoRotate) ...[
                    const SizedBox(height: 10),
                    ValueListenableBuilder<int>(
                      valueListenable: HomePageSettings.heroRotateSeconds,
                      builder: (context, seconds, _) {
                        return Row(
                          children: [
                            Text(
                              'Interval: ${seconds}s',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppThemeService.currentPalette.value.primaryColor,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                  thumbColor: AppThemeService.currentPalette.value.primaryColor,
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: seconds.toDouble(),
                                  min: 3,
                                  max: 15,
                                  divisions: 12,
                                  onChanged: (val) =>
                                      HomePageSettings.setHeroRotateSeconds(val.round()),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Ambient Glow Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.ambientGlow,
            builder: (context, glow, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ambient Backdrop Lighting',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Soft diffused color glow behind active hero poster',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: glow,
                    activeColor: AppThemeService.currentPalette.value.primaryColor,
                    onChanged: (val) {
                      HomePageSettings.setAmbientGlow(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardDensityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeService.currentPalette.value.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grid Column Count (All Poster Grids)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Applies to Discover, Catalog, Search and My List grids across the whole app',
            style: TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: HomePageSettings.gridColumns,
            builder: (context, columns, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildGridColumnChip('Auto', 0, columns),
                  for (final n in const [2, 3, 4, 5, 6, 7, 8])
                    _buildGridColumnChip('$n', n, columns),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          Text(
            'Poster Size & Grid Density',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: HomePageSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CardDensity.values.map((density) {
                  final isSelected = density == currentDensity;
                  return ChoiceChip(
                    label: Text(density.label),
                    selected: isSelected,
                    selectedColor: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.25),
                    backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppThemeService.currentPalette.value.primaryColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HomePageSettings.setCardDensity(density);
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: HomePageSettings.gridColumns,
            builder: (context, columns, _) {
              if (columns < 2) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Poster density is ignored while a fixed column count is active',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.withValues(alpha: 0.7),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Poster Size Scale (Home, Anime & Manga)
          Text(
            'Poster Size — Home, Anime & Manga',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scales poster cards in home/anime sliders and the manga page grid',
            style: TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
          ValueListenableBuilder<double>(
            valueListenable: HomePageSettings.posterScale,
            builder: (context, scale, _) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scale',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${(scale * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppThemeService.currentPalette.value.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppThemeService.currentPalette.value.primaryColor,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: AppThemeService.currentPalette.value.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: scale,
                      min: 0.6,
                      max: 1.3,
                      divisions: 14,
                      onChanged: (val) => HomePageSettings.setPosterScale(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Rating Badges Switch
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.showRating,
            builder: (context, showRating, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show IMDB Rating Badges',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display rating star pill on poster corners',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: showRating,
                    activeColor: AppThemeService.currentPalette.value.primaryColor,
                    onChanged: (val) {
                      HomePageSettings.setShowRating(val);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Card Hover Zoom Strength
          ValueListenableBuilder<double>(
            valueListenable: HomePageSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Poster Hover Zoom Scale',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${zoom.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppThemeService.currentPalette.value.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppThemeService.currentPalette.value.primaryColor,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: AppThemeService.currentPalette.value.primaryColor,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) => HomePageSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridColumnChip(String label, int value, int current) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.25),
      backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
      labelStyle: TextStyle(
        color: isSelected ? AppThemeService.currentPalette.value.primaryColor : Colors.white70,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.08),
      ),
      onSelected: (selected) {
        if (selected) {
          HomePageSettings.setGridColumns(value);
          setState(() {});
        }
      },
    );
  }

  Widget _buildDetailsBackgroundCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeService.currentPalette.value.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.movie_filter_outlined,
                  color: AppThemeService.currentPalette.value.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details Page Background',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Choose what appears behind movie & series detail pages',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<DetailsBackground>(
            valueListenable: HomePageSettings.detailsBackground,
            builder: (context, current, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DetailsBackground.values.map((bg) {
                  final isSelected = bg == current;
                  return ChoiceChip(
                    label: Text(bg.label),
                    selected: isSelected,
                    selectedColor: AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.25),
                    backgroundColor: AppThemeService.currentPalette.value.appBarBackgroundColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppThemeService.currentPalette.value.primaryColor : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HomePageSettings.setDetailsBackground(bg);
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTogglesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeService.currentPalette.value.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TV Shows Airing Calendar
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableCalendar,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TV Airing Calendar',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show TV Calendar buttons on Home bar & sliders',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) => HomePageSettings.setEnableCalendar(val),
                    activeColor: const Color(0xFF38BDF8),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 12),

          // AI Recommendation Quiz
          ValueListenableBuilder<bool>(
            valueListenable: HomePageSettings.enableAiQuiz,
            builder: (context, enabled, _) {
              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF472B6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFF472B6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Recommendation Quiz',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show AI Quiz button on Home & Search bars',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: enabled,
                    onChanged: (val) => HomePageSettings.setEnableAiQuiz(val),
                    activeColor: const Color(0xFFF472B6),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Compact modal bottom sheet listing every existing theme. The selection is
/// pending until the user taps "Apply theme"; dismissing the sheet keeps the
/// active theme unchanged.
class _ThemePickerSheet extends StatefulWidget {
  final AppThemePalette current;

  const _ThemePickerSheet({required this.current});

  @override
  State<_ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<_ThemePickerSheet> {
  late AppThemePalette _pending;

  @override
  void initState() {
    super.initState();
    _pending = widget.current;
  }

  Future<void> _apply() async {
    await AppThemeService.setPalette(_pending);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePalette>(
      valueListenable: AppThemeService.currentPalette,
      builder: (context, _, __) => _buildSheet(),
    );
  }

  Widget _buildSheet() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: AppThemeService.currentPalette.value.cardBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF292D39),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose theme',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF4F6FC),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Select your preferred appearance',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF9299AB)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final palette in AppThemeService.palettes)
                      _buildThemeOption(palette),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeService.currentPalette.value.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _apply,
                  child: const Text(
                    'Apply theme',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(AppThemePalette palette) {
    final isSelected = palette.id == _pending.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _pending = palette),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppThemeService.currentPalette.value.primaryColor.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppThemeService.currentPalette.value.primaryColor : const Color(0xFF292D39),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    palette.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFFF4F6FC),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _AccentDots(primary: palette.primaryColor, accent: palette.accentColor),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: AppThemeService.currentPalette.value.primaryColor,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentDots extends StatelessWidget {
  final Color primary;
  final Color accent;

  const _AccentDots({required this.primary, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      ],
    );
  }
}
