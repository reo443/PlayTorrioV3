import 'package:flutter/material.dart';
import '../../services/stream/stream_bitrate_resolver.dart';
import 'player_glass.dart';

/// Quality selector popover for adaptive (multi-variant) HLS streams.
/// Falls back to a read-only resolution readout for fixed-quality streams.
class PlayerQualityMenu extends StatelessWidget {
  final List<HlsVariant>? variants;
  final bool isResolving;
  final String selectedQuality; // 'auto' or bandwidth kbps as string
  final int? currentHeight;
  final ValueChanged<String> onQualitySelected;
  final VoidCallback onClose;

  const PlayerQualityMenu({
    super.key,
    required this.variants,
    required this.isResolving,
    required this.selectedQuality,
    required this.currentHeight,
    required this.onQualitySelected,
    required this.onClose,
  });

  String get _playingLabel {
    final h = currentHeight;
    if (h == null || h <= 0) return '—';
    if (h >= 2160) return '4K';
    if (h >= 1440) return '1440p';
    return '${h}p';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hasVariants = variants != null && variants!.length > 1;

    return PlayerGlassCard(
      width: (300.0).clamp(240.0, screenWidth - 32),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'QUALITY',
                  style: TextStyle(
                    color: PlayerTheme.inkSubtle,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              PlayerIconButton(
                size: 28,
                iconSize: 14,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: 6),

          if (isResolving)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PlayerTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Detecting available qualities...',
                    style: TextStyle(
                      color: PlayerTheme.inkMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (!hasVariants)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hd_rounded, size: 16, color: PlayerTheme.inkMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Source quality: $_playingLabel',
                        style: const TextStyle(
                          color: PlayerTheme.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This stream has a single fixed quality.',
                    style: TextStyle(
                      color: PlayerTheme.inkSubtle,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Auto (Best)
            _buildOption(
              id: 'auto',
              label: 'Auto (Best)',
              subtitle: 'Highest available quality',
              isSelected: selectedQuality == 'auto',
            ),
            const SizedBox(height: 4),
            const Divider(color: PlayerTheme.edgeSoft, height: 1),
            const SizedBox(height: 6),

            // Variants
            ...variants!.map((v) {
              return _buildOption(
                id: '${v.bandwidthKbps}',
                label: v.label,
                subtitle: '${(v.bandwidthKbps / 1000).toStringAsFixed(1)} Mbps'
                    '${v.width != null ? ' • ${v.width}×${v.height}' : ''}',
                isSelected: selectedQuality == '${v.bandwidthKbps}',
              );
            }),
          ],

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Playing at: $_playingLabel',
              style: const TextStyle(
                color: PlayerTheme.inkSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String id,
    required String label,
    required String subtitle,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          onQualitySelected(id);
          onClose();
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? PlayerTheme.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? PlayerTheme.edge : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? PlayerTheme.ink : PlayerTheme.inkMuted,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PlayerTheme.inkSubtle,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, size: 16, color: PlayerTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}
