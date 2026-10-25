import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/addon/addon.dart';
import 'package:playtorrio/models/stream/stream_model.dart';
import 'package:playtorrio/services/scraper/builtin_providers_settings_service.dart';
import 'package:playtorrio/services/stream/source_ranker.dart';

StreamSource http({
  String addon = 'AddonA',
  String? title,
  String? providerId,
}) =>
    StreamSource(
      addonName: addon,
      title: title,
      url: 'https://example.com/video.mp4',
      providerId: providerId,
    );

StreamSource torrent({
  String addon = 'AddonA',
  String? title,
  String? infoHash = 'abc123',
}) =>
    StreamSource(addonName: addon, title: title, infoHash: infoHash);

StreamSource debrid({String addon = 'AddonA', String? title}) => StreamSource(
      addonName: addon,
      name: '[RD] $title',
      title: title,
      url: 'https://example.com/debrid.mp4',
      infoHash: 'abc123',
    );

List<StreamSource> rank(
  List<StreamSource> sources, {
  Map<String, int> addonOrder = const {},
  bool customBuiltinProviders = false,
  bool p2pActive = true,
  bool httpActive = true,
}) =>
    SourceRanker.rank(
      sources,
      addonOrder: addonOrder,
      customBuiltinProviders: customBuiltinProviders,
      p2pActive: p2pActive,
      httpActive: httpActive,
    );

InstalledAddon installed(String id, String name) => InstalledAddon(
      baseUrl: 'https://$id.example',
      manifest: AddonManifest(
        id: id,
        name: name,
        version: '1.0.0',
        resources: const [],
        types: const [],
        idPrefixes: const [],
        catalogs: const [],
      ),
    );

void main() {
  group('SourceRanker.rank', () {
    test('drops non-debrid torrents when P2P is off', () {
      final direct = http(title: 'Movie 1080p');
      final p2p = torrent(title: 'Movie 1080p');

      expect(rank([direct, p2p], p2pActive: false), [direct]);
    });

    test('keeps debrid sources when P2P is off', () {
      final cached = debrid(title: 'Movie 1080p');

      expect(rank([cached], p2pActive: false), [cached]);
    });

    test('drops playtorriohttp when the built-in HTTP provider is off', () {
      final builtin = http(addon: 'playtorriohttp');
      final aliasCase = http(addon: 'PlayTorrioHttp');

      expect(rank([builtin, aliasCase], httpActive: false), isEmpty);
    });

    test('orders by configured provider rank in custom mode', () {
      const providers = BuiltinProvidersSettingsService.defaultProviders;
      final best = providers.first.id;
      final worse = providers[2].id;
      expect(
        BuiltinProvidersSettingsService.instance.getProviderRank(best),
        lessThan(BuiltinProvidersSettingsService.instance.getProviderRank(worse)),
      );

      final lowQuality =
          http(addon: 'playtorriohttp', title: 'Movie 480p', providerId: best);
      final highQuality =
          http(addon: 'playtorriohttp', title: 'Movie 1080p', providerId: worse);

      expect(
        rank([highQuality, lowQuality], customBuiltinProviders: true),
        [lowQuality, highQuality],
      );
    });

    test('ignores provider rank outside custom mode', () {
      const providers = BuiltinProvidersSettingsService.defaultProviders;
      final best = providers.first.id;
      final worse = providers[2].id;

      final lowQuality =
          http(addon: 'playtorriohttp', title: 'Movie 480p', providerId: best);
      final highQuality =
          http(addon: 'playtorriohttp', title: 'Movie 1080p', providerId: worse);

      expect(rank([highQuality, lowQuality]), [highQuality, lowQuality]);
    });

    test('orders by installed addon order outside custom mode', () {
      final firstAddon = http(addon: 'AddonA', title: 'Movie 480p');
      final laterAddon = http(addon: 'AddonB', title: 'Movie 1080p');

      expect(
        rank([laterAddon, firstAddon], addonOrder: {'addona': 0, 'addonb': 5}),
        [firstAddon, laterAddon],
      );
    });

    test('orders by quality then seeders within one addon', () {
      final hd = torrent(title: 'Movie 1080p S: 3');
      final sd = torrent(title: 'Movie 720p S: 900');
      expect(rank([sd, hd]), [hd, sd]);

      final moreSeeders = torrent(title: 'Movie 720p S: 900');
      final fewerSeeders = torrent(title: 'Movie 720p S: 10');
      expect(rank([fewerSeeders, moreSeeders]), [moreSeeders, fewerSeeders]);
    });

    test('keeps input order for fully equal candidates', () {
      final a = http(addon: 'Same', title: 'Movie');
      final b = http(addon: 'Same', title: 'Movie');
      final c = http(addon: 'Same', title: 'Movie');

      expect(rank([c, a, b]), [c, a, b]);
    });
  });

  group('SourceRanker.buildAddonOrder', () {
    test('maps manifest id, name and the playtorrio aliases', () {
      final order = SourceRanker.buildAddonOrder([
        installed('builtin.playtorriohttp', 'PlayTorrio HTTP'),
        installed('builtin.playtorrio', 'PlayTorrio'),
        installed('org.example.other', 'Other'),
      ]);

      expect(order['playtorriohttp'], 0);
      expect(order['playtorrio http'], 0);
      expect(order['builtin.playtorriohttp'], 0);
      expect(order['playtorrio'], 1);
      expect(order['other'], 2);
      expect(order['org.example.other'], 2);
    });
  });
}
