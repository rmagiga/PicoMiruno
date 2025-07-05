import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../platform/file_entry.dart';
import '../provider/file_entry_list_provider.dart';
import '../provider/thumbnail_config_provider.dart';
import '../utils/thumbnail_service.dart';
import '../widgets/thumbnail_image.dart';

class ImageGridScreen extends ConsumerStatefulWidget {
  const ImageGridScreen({super.key, required this.directoryEntry, required this.cacheDir});

  final DirectoryEntry directoryEntry;
  final Directory cacheDir;

  @override
  ConsumerState<ImageGridScreen> createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends ConsumerState<ImageGridScreen> {
  // --- 定数・フィールド ---
  final double _itemWidth = 120;
  Stream<FileEntry>? _filesStream;
  StreamSubscription<FileEntry>? _subscription;
  bool _loading = true;
  bool _hasError = false;

  // --- ライフサイクル ---
  @override
  void initState() {
    super.initState();
    _initializeStreamsAndProviders();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // --- 初期化処理 ---
  void _initializeStreamsAndProviders() {
    _filesStream = widget.directoryEntry.listFilesStream();
    ref.read(thumbnailConfigProvider.notifier).loadFromStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileEntryListProvider.notifier).clear();
      _startListeningFileStream();
    });
  }

  void _startListeningFileStream() {
    _subscription = _filesStream?.listen(
      (FileEntry entry) {
        ref.read(fileEntryListProvider.notifier).add(entry);
        if (_loading) {
          setState(() => _loading = false);
        }
      },
      onError:
          (_) => setState(() {
            _hasError = true;
            _loading = false;
          }),
      onDone: () => setState(() => _loading = false),
    );
  }

  // --- Widget構築 ---
  @override
  Widget build(BuildContext context) {
    final ThumbnailConfig thumbnailConfig = ref.watch(thumbnailConfigProvider);
    final List<FileEntry> files = ref.watch(fileEntryListProvider);
    final List<FileEntry> sortedFiles = _getSortedFiles(files);
    final CacheManager cacheManager = _createCacheManager(thumbnailConfig);
    final IThumbnailService thumbnailService = _createThumbnailService(cacheManager);

    if (_loading && sortedFiles.isEmpty) {
      return _buildLoading();
    }
    if (_hasError) {
      return _buildError();
    }
    if (sortedFiles.isEmpty) {
      return _buildNoImages();
    }
    return _buildGrid(context, sortedFiles, thumbnailService);
  }

  // --- Widget分割 ---
  Widget _buildLoading() => const Scaffold(body: Center(child: CircularProgressIndicator()));
  Widget _buildError() => const Scaffold(body: Center(child: Text('画像の取得に失敗しました')));
  Widget _buildNoImages() => const Scaffold(body: Center(child: Text('画像がありません')));

  Widget _buildGrid(
    BuildContext context,
    List<FileEntry> files,
    IThumbnailService thumbnailService,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.directoryEntry.name)),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int crossAxisCount = (constraints.maxWidth / _itemWidth).floor().clamp(1, 10);
          return GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: files.length,
            itemBuilder: (BuildContext context, int index) {
              final FileEntry entry = files[index];
              return GestureDetector(
                onTap: () => _onImageTap(context, index),
                child: ThumbnailImage(entry: entry, thumbnailService: thumbnailService),
              );
            },
          );
        },
      ),
    );
  }

  // --- ユーティリティ ---
  List<FileEntry> _getSortedFiles(List<FileEntry> files) {
    final List<FileEntry> sorted = List<FileEntry>.from(files);
    sorted.sort(
      (FileEntry a, FileEntry b) => b.getLastModifiedTime().compareTo(a.getLastModifiedTime()),
    );
    return sorted;
  }

  CacheManager _createCacheManager(ThumbnailConfig config) {
    return CacheManager(
      Config(
        'thumbCache',
        stalePeriod: Duration(days: config.stalePeriodDays),
        maxNrOfCacheObjects: config.maxDiskThumbnailCount,
      ),
    );
  }

  IThumbnailService _createThumbnailService(CacheManager cacheManager) {
    return ThumbnailService(
      cacheDir: widget.cacheDir,
      thumbSize: ThumbnailConstants.thumbSize,
      cacheManager: cacheManager,
    );
  }

  void _onImageTap(BuildContext context, int index) {
    Navigator.pushNamed(
      context,
      Routes.fullScreenImage,
      arguments: <String, Object>{'initialIndex': index},
    );
  }
}
