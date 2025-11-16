# yonnkomi

## セットアップ

このプロジェクトは[XcodeGen](https://github.com/yonaskolb/XcodeGen)を使用してXcodeプロジェクトファイルを生成します。

### 必要な環境

- Xcode 14.0以降
- XcodeGen

### XcodeGenのインストール

```bash
brew install xcodegen
```

### プロジェクトのセットアップ

1. リポジトリをクローンします

```bash
git clone <repository-url>
cd yonnkomi
```

2. XcodeGenを実行してプロジェクトファイルを生成します

```bash
xcodegen
```

3. 生成された`yonnkomi.xcodeproj`を開きます

```bash
open yonnkomi.xcodeproj
```

4. Xcodeで、Signing & Capabilitiesタブから自分のDevelopment Teamを選択します

### 注意事項

- `.xcodeproj`ファイルはgitで管理されていません
- プロジェクトの設定を変更する場合は`project.yml`を編集してください
- `project.yml`を編集した後は、`xcodegen`コマンドを実行してプロジェクトを再生成してください
- チーム設定は各開発者が個別に設定する必要があります（`project.yml`には含まれていません）
