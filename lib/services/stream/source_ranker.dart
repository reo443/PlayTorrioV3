import '../../models/addon/addon.dart';
import '../../models/stream/stream_model.dart';
import '../addon/addon_manager.dart';
import '../scraper/builtin_providers_settings_service.dart';

/// Sorts a stream list into playback order.
typedef StreamSorter = List<StreamSource> Function(
    Iterable<StreamSource> sources);

/// The ordering that used to live inside `WatchScreen`.
///
/// Provider rank (custom built-in mode only, direct HTTP providers only),
/// then installed-addon order, then quality, then seeders. Ties keep the
/// order they arrived in, so the result is deterministic.
abstract final class SourceRanker {
  static const int unknownAddonOrder = 999;

  static const String _httpAddonName = 'playtorriohttp';

  /// Lookup table keyed by both the manifest id and the manifest name, plus
  /// the aliases the built-in providers are addressed by.
  static Map<String, int> buildAddonOrder(Iterable<InstalledAddon> addons) {
    final map = <String, int>{};
    var index = 0;
    for (final addon in addons) {
      map[addon.manifest.name.toLowerCase()] = index;
      map[addon.manifest.id.toLowerCase()] = index;
      if (addon.manifest.id == 'builtin.playtorriohttp' ||
          addon.baseUrl == 'builtin:playtorriohttp') {
        map[_httpAddonName] = index;
      }
      if (addon.manifest.id == 'builtin.playtorrio' ||
          addon.baseUrl == 'builtin:playtorrio') {
        map['playtorrio'] = index;
      }
      index++;
    }
    return map;
  }

  static List<StreamSource> rank(
    Iterable<StreamSource> sources, {
    required Map<String, int> addonOrder,
    required bool customBuiltinProviders,
    required bool p2pActive,
    required bool httpActive,
  }) {
    final filtered = <StreamSource>[];
    for (final source in sources) {
      if (!p2pActive && source.isTorrent) continue;
      if (!httpActive && source.addonName.toLowerCase() == _httpAddonName) {
        continue;
      }
      filtered.add(source);
    }

    // Pair each source with its arrival index so equal candidates keep their
    // order (List.sort is not stable).
    final indexed = filtered.asMap().entries.toList();
    indexed.sort((a, b) {
      final x = a.value;
      final y = b.value;

      final xIsHttp = x.addonName.toLowerCase() == _httpAddonName;
      final yIsHttp = y.addonName.toLowerCase() == _httpAddonName;
      if (customBuiltinProviders && xIsHttp && yIsHttp) {
        final xRank = BuiltinProvidersSettingsService.instance.getProviderRank(
          x.providerId ?? BuiltinProvidersSettingsService.detectProviderId(x),
        );
        final yRank = BuiltinProvidersSettingsService.instance.getProviderRank(
          y.providerId ?? BuiltinProvidersSettingsService.detectProviderId(y),
        );
        if (xRank != yRank) return xRank.compareTo(yRank);
      }

      final xOrder = addonOrder[x.addonName.toLowerCase()] ?? unknownAddonOrder;
      final yOrder = addonOrder[y.addonName.toLowerCase()] ?? unknownAddonOrder;
      if (xOrder != yOrder) return xOrder.compareTo(yOrder);

      if (x.qualityRank != y.qualityRank) {
        return y.qualityRank.compareTo(x.qualityRank);
      }

      final xSeeders = x.seeders ?? 0;
      final ySeeders = y.seeders ?? 0;
      if (xSeeders != ySeeders) return ySeeders.compareTo(xSeeders);

      return a.key.compareTo(b.key);
    });

    return [for (final entry in indexed) entry.value];
  }

  /// Builds the ordering inputs from the live addon settings and ranks.
  static List<StreamSource> rankWithLiveSettings(
      Iterable<StreamSource> sources) {
    return rank(
      sources,
      addonOrder: buildAddonOrder(AddonManager.instance.addons),
      customBuiltinProviders: BuiltinProvidersSettingsService.instance.isCustom,
      p2pActive: AddonManager.instance.isPlayTorrioActive,
      httpActive: AddonManager.instance.isPlayTorrioHttpActive,
    );
  }
}
