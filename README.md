# PicoMiruno

PicoMirunoはFlutter製のクロスプラットフォーム画像ビューアアプリです。

## 主な機能
- フォルダごとの画像一覧表示（複数フォルダ管理）
- サムネイル生成・キャッシュ（キャッシュ日数・最大個数の設定可）
- 画像のフルスクリーン表示（スワイプで前後移動）
- テーマ切り替え（ライト/ダーク/システム）
- 設定画面（テーマ・サムネイルキャッシュ設定）
- フォルダ追加・削除
- Android/Windows対応

## 使い方

1. 必要なパッケージのインストール

```
flutter pub get
```

2. アプリの起動

```
flutter run
```

## ディレクトリ構成

- `lib/`
  - `main.dart` : エントリーポイント
  - `pages/` : 画面ウィジェット（フォルダ一覧・画像グリッド・フルスクリーン・設定）
  - `constants/` : ルートや設定値などの定数
  - `platform/` : プラットフォームごとのファイル・ディレクトリ操作
  - `provider/` : Riverpodによる状態管理
  - `infrastructure/` : 設定・フォルダ情報の保存
  - `utils/` : サムネイル生成・キャッシュ・非同期制御

## 主な依存パッケージ
- flutter_riverpod
- shared_preferences
- path_provider
- flutter_cache_manager
- file_picker
- photo_view
- image（画像処理）

## ライセンス

このプロジェクトはMITライセンスです。
