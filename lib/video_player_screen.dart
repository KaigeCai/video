import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:path_provider/path_provider.dart';

import 'common/globals.dart';
import 'common/widgets.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _saveScreenshot(Uint8List screenshot) async {
    try {
      // 获取存储路径
      String? directoryPath;

      if (Platform.isWindows) {
        // 如果是 Windows 系统，获取当前用户桌面路径
        String userProfile = Platform.environment['USERPROFILE'] ?? ''; // 获取当前用户的主目录
        if (userProfile.isNotEmpty) {
          directoryPath = '$userProfile\\Desktop'; // 拼接桌面路径
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        // 如果是 MacOS 或 Linux，使用 getDownloadsDirectory 获取下载目录（或根据需求修改）
        final desktopDir = await getDownloadsDirectory();
        directoryPath = desktopDir?.path ?? ''; // 设置路径
      } else if (Platform.isAndroid) {
        // Android 保存到下载文件夹
        final downloadDir = Directory('/storage/emulated/0/Download');
        directoryPath = downloadDir.path;
      } else if (Platform.isIOS) {
        // iOS 保存到 Documents 文件夹
        final documentsDir = await getApplicationDocumentsDirectory();
        directoryPath = documentsDir.path;
      } else {
        throw UnsupportedError("Unsupported platform");
      }
      // 确保目录存在
      final directory = Directory(directoryPath!);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      // 创建文件并保存截图
      final filePath = '$directoryPath/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(screenshot);

      // 提示保存成功
      debugPrint('Screenshot saved to $filePath');
    } catch (e) {
      debugPrint('Failed to save screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ValueListenableBuilder<VideoControllerConfiguration>(
          valueListenable: configuration,
          builder: (context, value, _) => TextButton(
            onPressed: () {
              configuration.value = VideoControllerConfiguration(
                enableHardwareAcceleration: !value.enableHardwareAcceleration,
              );
            },
            child: Text(value.enableHardwareAcceleration ? '硬件加速' : '软件加速'),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '截图',
            onPressed: () async {
              final screenshot = await player.screenshot();
              if (screenshot != null && mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: Image.memory(screenshot, scale: 1.2),
                    );
                  },
                );

                // 缓存截图到文件夹
                await _saveScreenshot(screenshot);

                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                });
              }
            },
            icon: const Icon(Icons.screenshot_monitor_rounded),
          ),
          IconButton(
            tooltip: '打开文件夹',
            onPressed: () {},
            icon: const Icon(Icons.view_list_rounded),
          ),
          IconButton(
            tooltip: '打开文件夹',
            onPressed: () {},
            icon: const Icon(Icons.folder_copy),
          ),
          IconButton(
            tooltip: '打开文件',
            onPressed: () => showFilePicker(context, player),
            icon: const Icon(Icons.file_open),
          ),
          IconButton(
            tooltip: '打开链接',
            onPressed: () => showURIPicker(context, player),
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: Video(controller: controller),
    );
  }
}
