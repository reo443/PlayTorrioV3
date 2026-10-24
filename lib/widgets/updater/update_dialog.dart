import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../services/updater/app_updater_service.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_glass_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/playtorrio_tokens.dart';
import '../ui/app_button.dart';
import '../ui/app_dialog.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = PlayTorrioTokens.of(context);
    return PopScope(
      canPop: !_isDownloading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_isDownloading) {
          AppUpdaterService.dismissVersion(widget.updateInfo.latestVersion);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tokens.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [AppElevation.glow(tokens.accent)],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.accent.withValues(alpha: 0.2),
                    tokens.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: tokens.accent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPDATE AVAILABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${widget.updateInfo.latestVersion}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version details container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppGlassColors.wash,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 11,
                                color: tokens.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.updateInfo.currentVersion,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: tokens.accent,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Latest',
                              style: TextStyle(
                                fontSize: 11,
                                color: tokens.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.updateInfo.latestVersion,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: tokens.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Release notes header & box
                  Text(
                    "WHAT'S NEW",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: tokens.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.bgPrimary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.borderSubtle,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.updateInfo.releaseNotes,
                        style: TextStyle(
                          fontSize: 13,
                          color: tokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  if (widget.updateInfo.isMacOS || widget.updateInfo.isIOS) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppSemanticColors.warning.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppSemanticColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.updateInfo.isIOS
                                  ? "iOS: You'll be redirected to GitHub to download the IPA"
                                  : "macOS: You'll be redirected to GitHub to download",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppSemanticColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isDownloading) ...[
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Downloading...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: tokens.accent,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: tokens.borderStrong,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tokens.accent,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Buttons
            if (!_isDownloading)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Later',
                        variant: AppButtonVariant.secondary,
                        expand: true,
                        onPressed: () {
                          AppUpdaterService.dismissVersion(
                            widget.updateInfo.latestVersion,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Update Now',
                        trailingIcon: Icons.download_rounded,
                        expand: true,
                        onPressed: _handleUpdate,
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

  Future<void> _handleUpdate() async {
    if (kIsWeb) {
      await AppUpdaterService().openDownloadPage(widget.updateInfo.downloadUrl);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (Platform.isAndroid) {
      await _downloadAndInstallAndroid();
    } else if (Platform.isWindows || Platform.isLinux) {
      await _downloadAndInstallDesktop();
    } else {
      // macOS / iOS - open browser
      await AppUpdaterService().openDownloadPage(widget.updateInfo.downloadUrl);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _downloadAndInstallAndroid() async {
    WakelockPlus.enable();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      OtaUpdate()
          .execute(
            widget.updateInfo.downloadUrl,
            destinationFilename:
                'PlayTorrio_${widget.updateInfo.latestVersion}.apk',
          )
          .listen(
            (OtaEvent event) {
              if (mounted) {
                setState(() {
                  switch (event.status) {
                    case OtaStatus.DOWNLOADING:
                      final value = event.value;
                      if (value != null) {
                        final numVal = num.tryParse(value.toString()) ?? 0;
                        _downloadProgress = (numVal / 100.0).clamp(0.0, 1.0);
                      }
                      break;
                    case OtaStatus.INSTALLING:
                      _downloadProgress = 1.0;
                      WakelockPlus.disable();
                      break;
                    case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                      _isDownloading = false;
                      WakelockPlus.disable();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enable "Install unknown apps" permission for PlayTorrio in Android settings.',
                          ),
                          duration: Duration(seconds: 5),
                          backgroundColor: AppSemanticColors.warning,
                        ),
                      );
                      Navigator.of(context).pop();
                      break;
                    case OtaStatus.ALREADY_RUNNING_ERROR:
                    case OtaStatus.INTERNAL_ERROR:
                    case OtaStatus.DOWNLOAD_ERROR:
                    case OtaStatus.CHECKSUM_ERROR:
                      _isDownloading = false;
                      WakelockPlus.disable();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Update failed: ${event.status}'),
                          backgroundColor: AppSemanticColors.destructive,
                        ),
                      );
                      Navigator.of(context).pop();
                      break;
                    default:
                      break;
                  }
                });
              }
            },
            onError: (error) {
              WakelockPlus.disable();
              if (mounted) {
                setState(() => _isDownloading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Download failed: $error'),
                    backgroundColor: AppSemanticColors.destructive,
                  ),
                );
              }
            },
          );
    } catch (e) {
      WakelockPlus.disable();
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppSemanticColors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _downloadAndInstallDesktop() async {
    WakelockPlus.enable();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {
        downloadsDir = null;
      }
      final dir = downloadsDir ?? await getTemporaryDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final extension = Platform.isWindows ? '.exe' : '.AppImage';
      final fileName =
          'PlayTorrio-${widget.updateInfo.latestVersion}$extension';
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);

      final request = http.Request(
        'GET',
        Uri.parse(widget.updateInfo.downloadUrl),
      );
      final response = await request.send();

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (contentLength > 0 &&
            mounted &&
            (now - lastUpdateTime > 100 || downloadedBytes == contentLength)) {
          lastUpdateTime = now;
          final progress = downloadedBytes / contentLength;
          setState(() {
            _downloadProgress = progress;
          });
        }
      }

      await sink.close();

      if (mounted) {
        WakelockPlus.disable();
        setState(() => _isDownloading = false);
        final tokens = PlayTorrioTokens.of(context);

        await showDialog(
          context: context,
          builder: (dialogContext) => AppDialog(
            title: 'Download Complete',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppSemanticColors.success,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Update downloaded.',
                      style: AppTypography.supporting.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: tokens.bgPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                  child: SelectableText(
                    filePath,
                    style: AppTypography.supporting.copyWith(
                      color: tokens.accent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  Platform.isWindows
                      ? 'Close PlayTorrio and run the installer to update.'
                      : 'Make the file executable and run it:\nchmod +x "$fileName"\n./$fileName',
                  style: AppTypography.supporting.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Open Folder',
                variant: AppButtonVariant.tertiary,
                onPressed: () async {
                  if (Platform.isWindows) {
                    await Process.run('explorer', ['/select,', filePath]);
                  } else if (Platform.isLinux) {
                    await Process.run('xdg-open', [dir.path]);
                  }
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              AppButton(
                label: 'OK',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      WakelockPlus.disable();
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }
}
