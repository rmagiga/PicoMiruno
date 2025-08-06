import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../provider/current_image_index_provider.dart';
import '../provider/thumbnail_config_provider.dart';
import '../service/file_loading_service.dart';
import '../service/navigation_service.dart';
import '../utils/thumbnail_service.dart';
import '../widgets/image_grid_widget.dart';

/// 画像グリッド表示画面
/// SRP: 画面の状態管理とサービス間の調整のみを担当
class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({super.key, required this.directoryEntry, required this.cacheDir});

  final DirectoryEntry directoryEntry;
  final Directory cacheDir;

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen> {
  late Future<List<FileEntry>> _filesFuture;
  late final IFileLoadingService _fileLoadingService;
  late final INavigationService _navigationService;
  late final IThumbnailService _thumbnailService;

  @override
  void initState() {
    super.initState();
    _fileLoadingService = FileLoadingService();
    _navigationService = NavigationService();
    _initializeServices();
    _filesFuture = _loadFiles();
  }

  void _initializeServices() {
    final ThumbnailConfig thumbnailConfig = ref.read(thumbnailConfigProvider);
    _thumbnailService = ThumbnailService(
      cacheDir: widget.cacheDir,
      thumbSize: ThumbnailConstants.thumbSize,
      stalePeriodDays: thumbnailConfig.stalePeriodDays,
      maxNrOfCacheObjects: thumbnailConfig.maxDiskThumbnailCount,
    );
  }

  Future<List<FileEntry>> _loadFiles() async {
    return _fileLoadingService.loadFiles(widget.directoryEntry);
  }

  void _handleImageTap(List<FileEntry> files, int index) {
    ref.read(currentImageIndexProvider.notifier).index = index;
    _navigationService.navigateToFullScreenImage(context, files, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.directoryEntry.name)),
      body: FutureBuilder<List<FileEntry>>(
        future: _filesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<FileEntry>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('画像がありません'));
          }
          final List<FileEntry> files = snapshot.data!;
          return ImageGridWidget(
            files: files,
            thumbnailService: _thumbnailService,
            onImageTap: (int index) => _handleImageTap(files, index),
          );
        },
      ),
    );
  }
}
