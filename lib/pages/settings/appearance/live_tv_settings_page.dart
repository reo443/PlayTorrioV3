import 'package:flutter/material.dart';
import '../../../services/theme/app_theme_service.dart';
import '../../../services/home/home_page_settings.dart';
import '../../../services/iptv/iptv_settings.dart';
import '../../../widgets/settings/settings_controls.dart';

class LiveTvSettingsPage extends StatefulWidget {
  const LiveTvSettingsPage({super.key});

  @override
  State<LiveTvSettingsPage> createState() => _LiveTvSettingsPageState();
}

class _LiveTvSettingsPageState extends State<LiveTvSettingsPage> {
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
          'Live TV & Sports UI',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── 1. Hero Spotlight Carousel ──
              const Text(
                'LIVE SPOTLIGHT & HERO BANNER',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),
              _buildHeroSpotlightCard(palette),

              const SizedBox(height: 28),

              // ── 2. Card Layout & Poster Density ──
              const Text(
                'CHANNEL CARDS & POSTER DENSITY',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),
              _buildCardDensityCard(palette),

              const SizedBox(height: 28),

              // ── 3. Category Visibility & Ordering ──
              const Text(
                'SECTIONS & CATEGORY MANAGER',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),
              _buildCategoryManagerCard(palette),

              const SizedBox(height: 28),

              // ── 4. Portals Modal Customization ──
              const Text(
                'PORTALS & PLAYLISTS MODAL',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),
              _buildPortalsModalCustomizerCard(palette),

              const SizedBox(height: 28),

              // ── 5. Portal Browser Customization ──
              const Text(
                'PORTAL BROWSER & CHANNEL GUIDE',
                style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Color(0xFF7E7E8C),
        ),
              ),
              const SizedBox(height: 12),
              _buildPortalBrowserCustomizerCard(palette),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSpotlightCard(AppThemePalette palette) {
    return ValueListenableBuilder<bool>(
      valueListenable: IptvSettings.enableSpotlight,
      builder: (context, enabled, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF12151E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled
                  ? palette.primaryColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Toggle
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
                      Icons.tv_rounded,
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
                          'Show Live Spotlight Banner',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Featured championship matches and top broadcast channels at the top',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: enabled,
                    semanticsLabel: 'Hero Spotlight',
                    onChanged: (val) {
                      IptvSettings.setEnableSpotlight(val);
                      setState(() {});
                    },
                  ),
                ],
              ),

              if (enabled) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Style Selection
                Text(
                  'Hero Banner Style',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<HeroStyle>(
                  valueListenable: IptvSettings.heroStyle,
                  builder: (context, currentStyle, _) {
                    return SettingsSegmentedControl<HeroStyle>(
                      values: HeroStyle.values,
                      selected: currentStyle,
                      onChanged: (style) {
                        IptvSettings.setHeroStyle(style);
                        setState(() {});
                      },
                      label: (style) => style.label,
                    );
                  },
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Auto Rotate
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-Rotate Channels',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Automatically cycle through featured live events',
                                style: TextStyle(fontSize: 11.5, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                        SettingsToggleSwitch(
                          value: autoRotate,
                          semanticsLabel: 'Auto-Rotate Channels',
                          onChanged: (val) => IptvSettings.setHeroAutoRotate(val),
                        ),
                      ],
                    );
                  },
                ),

                // Rotate Timer Slider
                ValueListenableBuilder<bool>(
                  valueListenable: IptvSettings.heroAutoRotate,
                  builder: (context, autoRotate, _) {
                    if (!autoRotate) return const SizedBox.shrink();
                    return ValueListenableBuilder<int>(
                      valueListenable: IptvSettings.heroRotateSeconds,
                      builder: (context, seconds, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rotation Interval',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '$seconds seconds',
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
                                value: seconds.toDouble(),
                                min: 3,
                                max: 15,
                                divisions: 12,
                                onChanged: (val) => IptvSettings.setHeroRotateSeconds(val.round()),
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _buildCardDensityCard(AppThemePalette palette) {
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
          // Density Choice
          Text(
            'Channel Card Size',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<CardDensity>(
            valueListenable: IptvSettings.cardDensity,
            builder: (context, currentDensity, _) {
              return SettingsSegmentedControl<CardDensity>(
                values: CardDensity.values,
                selected: currentDensity,
                onChanged: (density) {
                  IptvSettings.setCardDensity(density);
                  setState(() {});
                },
                label: (density) => density.label,
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Hover Zoom Slider
          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.cardHoverZoom,
            builder: (context, zoom, _) {
              final percent = ((zoom - 1.0) * 100).round();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card Hover Scale Zoom',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '+$percent%',
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
                      value: zoom,
                      min: 1.00,
                      max: 1.15,
                      divisions: 15,
                      onChanged: (val) => IptvSettings.setCardHoverZoom(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // HD Badge Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showHdBadge,
            builder: (context, showHd, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show LIVE / HD Stream Badge',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display radiant live broadcast badge on channel corners',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showHd,
                    semanticsLabel: 'Show LIVE / HD Stream Badge',
                    onChanged: (val) => IptvSettings.setShowHdBadge(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Category Tag Toggle
          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryTag,
            builder: (context, showTag, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Channel Category Tag',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show category label below channel name',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showTag,
                    semanticsLabel: 'Show Channel Category Tag',
                    onChanged: (val) => IptvSettings.setShowCategoryTag(val),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryManagerCard(AppThemePalette palette) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: IptvSettings.visibleCategories,
      builder: (context, visibleList, _) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Channel Categories & Sections',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toggle visibility of Live TV rows',
                        style: TextStyle(fontSize: 11.5, color: Colors.white54),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => IptvSettings.resetCategories(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset All', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 6),

              ...IptvSettings.defaultCategories.map((cat) {
                final isVisible = visibleList.contains(cat);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isVisible ? FontWeight.w700 : FontWeight.w500,
                      color: isVisible ? Colors.white : Colors.white38,
                    ),
                  ),
                  value: isVisible,
                  activeColor: palette.primaryColor,
                  checkColor: Colors.white,
                  onChanged: (val) {
                    IptvSettings.toggleCategoryVisibility(cat);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortalsModalCustomizerCard(AppThemePalette palette) {
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
          Text(
            'Portal Card Display Style',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalCardStyle>(
            valueListenable: IptvSettings.portalCardStyle,
            builder: (context, style, _) {
              return SettingsSegmentedControl<PortalCardStyle>(
                values: PortalCardStyle.values,
                selected: style,
                onChanged: (s) {
                  IptvSettings.setPortalCardStyle(s);
                  setState(() {});
                },
                label: (s) => s.label,
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalExpiry,
            builder: (context, showExpiry, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Portal Expiry Date',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display subscription expiration tag on portal cards',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showExpiry,
                    semanticsLabel: 'Show Portal Expiry Date',
                    onChanged: (val) => IptvSettings.setShowPortalExpiry(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showPortalConnections,
            builder: (context, showConn, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Max Active Connections Tag',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display current and max concurrent streaming connections',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showConn,
                    semanticsLabel: 'Show Max Active Connections Tag',
                    onChanged: (val) => IptvSettings.setShowPortalConnections(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          Text(
            'Default Starting Tab',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: IptvSettings.defaultPortalTab,
            builder: (context, tabIdx, _) {
              return SettingsSegmentedControl<int>(
                values: const [0, 1],
                selected: tabIdx,
                onChanged: (idx) => IptvSettings.setDefaultPortalTab(idx),
                label: (idx) => idx == 0 ? 'Xtream Panels' : 'M3U Playlists',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortalBrowserCustomizerCard(AppThemePalette palette) {
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
          Text(
            'Channel Stream Layout Mode',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              return SettingsSegmentedControl<PortalBrowserLayout>(
                values: PortalBrowserLayout.values,
                selected: layout,
                onChanged: (l) {
                  IptvSettings.setBrowserLayout(l);
                  setState(() {});
                },
                label: (l) => l.label,
              );
            },
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<PortalBrowserLayout>(
            valueListenable: IptvSettings.browserLayout,
            builder: (context, layout, _) {
              if (layout != PortalBrowserLayout.grid) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: IptvSettings.browserGridColumns,
                builder: (context, cols, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grid Stream Columns',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '$cols Columns',
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
                          value: cols.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          onChanged: (val) => IptvSettings.setBrowserGridColumns(val.round()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.06)),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<double>(
            valueListenable: IptvSettings.sidebarWidth,
            builder: (context, width, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Sidebar Width',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${width.round()} px',
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
                      value: width,
                      min: 200.0,
                      max: 340.0,
                      divisions: 14,
                      onChanged: (val) => IptvSettings.setSidebarWidth(val),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showStreamLogos,
            builder: (context, showLogos, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Channel Stream Logos',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display channel poster and logos in stream rows',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showLogos,
                    semanticsLabel: 'Show Channel Stream Logos',
                    onChanged: (val) => IptvSettings.setShowStreamLogos(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showEpgSnippet,
            builder: (context, showEpg, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show EPG "Now Playing" Snippet',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Display current television guide title below channel',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showEpg,
                    semanticsLabel: 'Show EPG "Now Playing" Snippet',
                    onChanged: (val) => IptvSettings.setShowEpgSnippet(val),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          ValueListenableBuilder<bool>(
            valueListenable: IptvSettings.showCategoryCount,
            builder: (context, showCount, _) {
              return Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Show Category Stream Counts',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Show number of available streams next to category names',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  SettingsToggleSwitch(
                    value: showCount,
                    semanticsLabel: 'Show Category Stream Counts',
                    onChanged: (val) => IptvSettings.setShowCategoryCount(val),
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
