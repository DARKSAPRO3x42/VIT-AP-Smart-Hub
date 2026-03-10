import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/github_update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final GitHubUpdateService _updateService = GitHubUpdateService();
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'A new version is available!';

  Future<void> _startDownload() async {
    // Request storage or install permissions if needed
    final status = await Permission.requestInstallPackages.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installation permission is required to update.')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading update...';
    });

    try {
      await _updateService.downloadAndInstallUpdate(
        widget.updateInfo.downloadUrl,
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );
      setState(() {
        _statusMessage = 'Download complete. Installing...';
      });
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog after triggering install
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Update failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_statusMessage),
          const SizedBox(height: 16),
          if (_isDownloading)
            Column(
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text('${(_progress * 100).toStringAsFixed(1)}%'),
              ],
            )
          else
            Text('Version: ${widget.updateInfo.version}'),
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
        if (!_isDownloading)
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Update Now'),
          ),
      ],
    );
  }
}

void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UpdateDialog(updateInfo: updateInfo),
  );
}
