import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/services/scraper/sites/fourkhdhub.dart';

/// The current 4KHDHub chain is:
///   detail page -> greenmotors.club (obfuscated payload)
///     -> hubcloud drive page (`<a id="download">`)
///       -> gamerxyt page (`<a ... class="btn btn-success">`)
///         -> presigned R2 file
void main() {
  group('FourKHDHub.decodeRedirectPayload', () {
    test('decodes the obfuscated payload into the hubcloud drive url', () {
      // Captured verbatim from https://greenmotors.club/?id=... (Fight Club, 2160p).
      const html = '''
        <script type="text/javascript">
          function stck(e,t,i){let n="";}s('o','Y214WE0xWjNZbXRhVUdwMmIxQldObFo2ZFRCeFZVOXRRbmxxYVV0UU9XRndla2w1YjNveGFYRlVPV3h3YkRWM1RERnFhVzVVT1dkTlNtdDFiM3BGZVhCNWFtbFdkbXAyYjJ4V05sWjZVMVpJZDA5M1JsSXdNa2RWZURWdk1rVkxSbnBqZGtWdGVHdEtlRm94Y0ZSYWJVaExUVzVHVW1OcVRWUXhTWEY2VW14R1lWZDJiM2xOTVVkNWRVcHlTbGRNUjNwMVRVbHRTV2hXWVRBOQ==',180*1000);
          setTimeout(()=>window.location.href='https://greenmotors.cc/homelander/', 2000);
        </script>
      ''';

      expect(
        FourKHDHubScraper.decodeRedirectPayload(html),
        'https://hubcloud.ist/drive/kbknun5urmsaang',
      );
    });

    test('returns null when there is no payload', () {
      expect(FourKHDHubScraper.decodeRedirectPayload('<html></html>'), isNull);
    });

    test('returns null instead of throwing on a corrupt payload', () {
      const html = "<script>s('o','not-base64!!',1000);</script>";

      expect(FourKHDHubScraper.decodeRedirectPayload(html), isNull);
    });
  });

  group('FourKHDHub.findDriveDownloadLink', () {
    test('reads the gamerxyt hop from the hubcloud drive page', () {
      const html = '''
        <div class="card">
          <a id="download" href="https://gamerxyt.com/hubcloud.php?host=hubcloud&id=kbknun5urmsaang&token=QjZiemM1eU1o" rel="noopener noreferrer nofollow" class="btn btn-primary h6 p-2">
        </div>
      ''';

      expect(
        FourKHDHubScraper.findDriveDownloadLink(html),
        'https://gamerxyt.com/hubcloud.php?host=hubcloud&id=kbknun5urmsaang&token=QjZiemM1eU1o',
      );
    });

    test('returns null when the page has no download anchor', () {
      expect(FourKHDHubScraper.findDriveDownloadLink('<p>nope</p>'), isNull);
    });
  });

  group('FourKHDHub.findFinalStreamUrl', () {
    test('picks the btn-success file link, not the ad buttons', () {
      const html = '''
        <a href="https://b6a3a2c1584bbac49ae84a20efcae68e.r2.cloudflarestorage.com/hub/88534ab0?X-Amz-Signature=abc" id="fsl" rel="noreferrer nofollow noopener" target="_blank" class="btn btn-success btn-lg h6">
        <a href="https://pixel.hubcloud.ist/?id=6c61" class="btn btn-danger btn-lg h6">
        <a href="https://hbplay.pages.dev/?u=aHR0" class="btn btn-primary btn-lg h6" id="tgbtn">
      ''';

      expect(
        FourKHDHubScraper.findFinalStreamUrl(html),
        'https://b6a3a2c1584bbac49ae84a20efcae68e.r2.cloudflarestorage.com/hub/88534ab0?X-Amz-Signature=abc',
      );
    });

    test('returns null when no success button exists', () {
      expect(
        FourKHDHubScraper.findFinalStreamUrl('<a href="https://x" class="btn2">x</a>'),
        isNull,
      );
    });
  });
}
