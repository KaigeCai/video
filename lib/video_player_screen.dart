import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  final configuration = ValueNotifier<VideoControllerConfiguration>(
    const VideoControllerConfiguration(enableHardwareAcceleration: true),
  );

  late final VideoController controller = VideoController(
    player,
    configuration: configuration.value,
  );

  List<Map<String, String>> playlist = []; // 存储播放列表，包含标题与链接

  int currentIndex = -1; // 当前播放索引

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  /// 解析 m3u 文件内容并返回标题与链接列表
  List<Map<String, String>> parseM3U(String content) {
    final lines = content.split('\n');
    List<Map<String, String>> items = [];
    String? currentTitle;

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('#EXTINF')) {
        // 提取标题
        final titleMatch = RegExp(r'#EXTINF:.*?,(.+)').firstMatch(line);
        if (titleMatch != null) {
          currentTitle = titleMatch.group(1);
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        // 当前行是链接，将标题与链接保存
        if (currentTitle != null) {
          items.add({'title': currentTitle, 'url': line});
          currentTitle = null; // 清空当前标题
        }
      }
    }
    return items;
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
      // 显示 Toast 消息
      Fluttertoast.showToast(
        msg: 'Screenshot saved to $filePath', // 显示的消息
        toastLength: Toast.LENGTH_SHORT, // Toast 显示时长，短暂
        gravity: ToastGravity.BOTTOM, // 显示位置：底部
        timeInSecForIosWeb: 1, // iOS Web平台的显示时间
        backgroundColor: Colors.black, // 背景颜色
        textColor: Colors.white, // 文本颜色
        fontSize: 16.0, // 字体大小
      );
    } catch (e) {
      debugPrint('Failed to save screenshot: $e');
    }
  }

  /// 加载播放列表到 Player
  void loadPlaylistToPlayer() {
    final urls = playlist.map((item) => Media(item['url']!)).toList();
    player.open(
      Playlist(urls), // 使用 media_kit 提供的 Playlist 功能
      play: true, // 自动播放
    );
  }

  /// 打开文件选择器并解析 m3u 文件
  Future<void> showFilePicker(BuildContext context, Player player) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result?.files.isNotEmpty ?? false) {
      final file = result!.files.first;

      if (file.path != null && file.extension == 'm3u') {
        try {
          final content = await File(file.path!).readAsString();
          final parsedPlaylist = parseM3U(content);
          if (parsedPlaylist.isNotEmpty) {
            setState(() {
              playlist = parsedPlaylist;
              currentIndex = -1; // 重置当前索引
            });
            loadPlaylistToPlayer(); // 加载到 Player 的播放列表
          } else {
            Fluttertoast.showToast(msg: '播放列表为空或解析失败');
          }
        } catch (e) {
          Fluttertoast.showToast(msg: '解析 m3u 文件失败: $e');
        }
      } else {
        await player.open(Media(file.path!)); // 非 m3u 文件直接播放
      }
    }
  }

  Future<void> showURIPicker(BuildContext context, Player player) async {
    final key = GlobalKey<FormState>();
    final src = TextEditingController();
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        alignment: Alignment.center,
        child: Form(
          key: key,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  controller: src,
                  style: const TextStyle(fontSize: 14.0),
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Video URI',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a URI';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        player.open(Media(src.text));
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: const Text('Play'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            tooltip: '打开文件',
            onPressed: () => showFilePicker(context, player),
            icon: const Icon(Icons.file_open),
          ),
          IconButton(
            tooltip: '打开链接',
            onPressed: () => showURIPicker(context, player),
            icon: const Icon(Icons.link),
          ),
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
            tooltip: '播放列表',
            onPressed: () {
              /// 展示播放列表
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView.builder(
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final item = playlist[index];
                      final title = item['title']!;
                      return ListTile(
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          setState(() {
                            currentIndex = index; // 更新当前播放索引
                          });
                          player.jump(index); // 使用 media_kit 的跳转功能
                          Navigator.of(context).pop(); // 关闭 BottomSheet
                        },
                      );
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.view_list_rounded),
          ),
          IconButton(
            tooltip: '打开文件夹',
            onPressed: () {},
            icon: const Icon(Icons.folder_copy),
          ),
        ],
      ),
      body: Video(controller: controller),
    );
  }
}
