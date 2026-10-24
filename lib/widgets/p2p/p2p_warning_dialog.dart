import 'package:flutter/material.dart';
import '../../services/p2p/p2p_settings_service.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/playtorrio_tokens.dart';
import '../ui/app_button.dart';

class P2pWarningDialog extends StatelessWidget {
  const P2pWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: size.height * 0.90,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppSemanticColors.warning.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppSemanticColors.warning.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                AppElevation.shadowMd,
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header Banner
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppSemanticColors.warning.withValues(alpha: 0.22),
                          AppSemanticColors.warning.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppSemanticColors.warning.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.warning.withValues(
                              alpha: 0.20,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppSemanticColors.warning.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppSemanticColors.warning,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppSemanticColors.warning
                                            .withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PRIVACY & NETWORK ADVISORY',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          color: AppSemanticColors.warning,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'P2P Torrent Streaming Notice',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: tokens.textSecondary,
                          ),
                          tooltip: 'Exit',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // 2. Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main advisory text
                          Text(
                            'P2P (peer-to-peer torrent) streaming connects directly to public torrent swarms to download and seed video pieces. In certain countries and regions, unencrypted torrent activity may be monitored and could result in warning letters or notices from your Internet Service Provider (ISP).',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: tokens.textPrimary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Engine Breakdown Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: tokens.bgPrimary.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tokens.borderSubtle,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSourceInfoRow(
                                  tokens: tokens,
                                  icon: Icons.cloud_done_rounded,
                                  iconColor: AppSemanticColors.success,
                                  title: 'PlayTorrio HTTP (Direct Stream)',
                                  subtitle: 'Safe direct HTTPS web streams. No torrenting or peer uploading.',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(
                                    height: 1,
                                    color: tokens.borderSubtle,
                                  ),
                                ),
                                _buildSourceInfoRow(
                                  tokens: tokens,
                                  icon: Icons.hub_rounded,
                                  iconColor: AppSemanticColors.warning,
                                  title: 'PlayTorrio (Torrent Engine)',
                                  subtitle: 'P2P swarms (Knaben, TorrentGalaxy). Involves peer data sharing.',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Prompt question
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppSemanticColors.warning.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppSemanticColors.warning.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.help_outline_rounded,
                                  color: AppSemanticColors.warning,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Would you like to turn off the built-in PlayTorrio P2P torrent source and use only direct HTTP streaming?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Note: You can easily toggle the built-in P2P source back on or off anytime in Settings.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tokens.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Responsive Action Buttons Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    decoration: BoxDecoration(
                      color: tokens.bgPrimary.withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                          color: tokens.borderSubtle,
                        ),
                      ),
                    ),
                    child: isSmallScreen
                        ? _buildStackedButtons(context)
                        : _buildHorizontalButtons(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceInfoRow({
    required PlayTorrioTokens tokens,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalButtons(BuildContext context) {
    return Row(
      children: [
        // Exit button
        AppButton(
          label: 'Exit',
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Spacer(),

        // Don't show again button (keeps P2P enabled)
        AppButton(
          label: "Don't Show Again",
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            await P2pSettingsService.setNeverShowWarning(true);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        const SizedBox(width: 10),

        // Yes, Turn Off P2P button
        AppButton(
          label: 'Yes, Turn Off P2P',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () async {
            await P2pSettingsService.setP2pEnabled(false);
            await P2pSettingsService.setNeverShowWarning(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('P2P torrent source turned off. PlayTorrioHTTP will be used.'),
                  backgroundColor: AppSemanticColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  Widget _buildStackedButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Yes, Turn Off P2P button
        AppButton(
          label: 'Yes, Turn Off P2P',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () async {
            await P2pSettingsService.setP2pEnabled(false);
            await P2pSettingsService.setNeverShowWarning(true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('P2P torrent source turned off. PlayTorrioHTTP will be used.'),
                  backgroundColor: AppSemanticColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: AppButton(
                label: "Don't Show Again",
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: () async {
                  await P2pSettingsService.setNeverShowWarning(true);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Exit',
              variant: AppButtonVariant.tertiary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }
}
