# 開發環境設定指南

本專案提供多種方式設定 Swift 開發環境。

## 目錄

- [使用 Dev Container (推薦)](#使用-dev-container-推薦)
- [本地安裝 Swift](#本地安裝-swift)
- [常用開發命令](#常用開發命令)
- [VS Code 設定](#vs-code-設定)
- [疑難排解](#疑難排解)

---

## 使用 Dev Container (推薦)

Dev Container 提供開箱即用的 Swift 6.1 開發環境，無需在本機安裝任何工具。

### 前置需求

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [VS Code](https://code.visualstudio.com/)
- [Dev Containers 擴展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### 快速開始

1. **Clone 專案**
   ```bash
   git clone https://github.com/vivalalova/codable-macro.git
   cd codable-macro
   ```

2. **在 VS Code 中開啟**
   ```bash
   code .
   ```

3. **啟動 Dev Container**
   - VS Code 會偵測到 `.devcontainer` 配置
   - 點擊右下角彈出的 "Reopen in Container" 按鈕
   - 或按 `F1` → 輸入 "Dev Containers: Reopen in Container"

4. **等待容器建置** (首次啟動需要幾分鐘)

5. **驗證環境**
   ```bash
   swift --version
   # Swift version 6.1
   ```

### Dev Container 特色

- ✅ Swift 6.1 已預先安裝
- ✅ 所有必要的開發工具
- ✅ VS Code Swift 擴展已配置
- ✅ LLDB 調試器支援
- ✅ 自動執行 `swift build`

---

## 本地安裝 Swift

### macOS

使用 Homebrew 安裝：

```bash
brew install swift
```

或從 [Swift.org](https://swift.org/download/) 下載官方安裝包。

### Ubuntu 24.04

```bash
# 安裝依賴
sudo apt-get update
sudo apt-get install -y \
  binutils \
  git \
  gnupg2 \
  libc6-dev \
  libcurl4-openssl-dev \
  libedit2 \
  libgcc-9-dev \
  libpython3.8 \
  libsqlite3-0 \
  libstdc++-9-dev \
  libxml2-dev \
  libz3-dev \
  pkg-config \
  tzdata \
  zlib1g-dev

# 下載並安裝 Swift 6.1
wget https://download.swift.org/swift-6.1-release/ubuntu2404/swift-6.1-RELEASE/swift-6.1-RELEASE-ubuntu24.04.tar.gz
tar xzf swift-6.1-RELEASE-ubuntu24.04.tar.gz
sudo mv swift-6.1-RELEASE-ubuntu24.04 /usr/share/swift
echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Windows

使用 [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) 並按照 Ubuntu 指南安裝。

---

## 常用開發命令

### 建置專案

```bash
# 基本建置
swift build

# Debug 模式建置（預設）
swift build -c debug

# Release 模式建置
swift build -c release

# 顯示詳細輸出
swift build -v
```

### 執行測試

```bash
# 執行所有測試
swift test

# 顯示詳細輸出
swift test -v

# 執行特定測試
swift test --filter ComplexUseCaseTests

# 執行特定測試方法
swift test --filter testTransformWithNestedKeyPath

# 顯示測試覆蓋率 (Linux)
swift test --enable-code-coverage
```

### 套件管理

```bash
# 更新依賴
swift package update

# 解析依賴
swift package resolve

# 清理建置產物
swift package clean

# 重置套件快取
swift package reset

# 生成 Xcode 專案 (macOS)
swift package generate-xcodeproj
```

### 執行範例

```bash
# 執行範例程式碼
swift run Examples.swift --demo
```

---

## VS Code 設定

本專案包含預先配置的 VS Code 設定：

### 內建任務 (Tasks)

按 `Cmd/Ctrl + Shift + B` 或 `F1` → "Tasks: Run Task"

- **Swift: Build** - 建置專案
- **Swift: Test** - 執行測試
- **Swift: Test Verbose** - 執行測試（詳細輸出）
- **Swift: Clean** - 清理建置產物
- **Swift: Update Dependencies** - 更新依賴
- **Swift: Test with Filter** - 執行特定測試（會提示輸入 filter）

### 調試配置 (Launch Configurations)

按 `F5` 開始調試：

- **Debug Tests** - 調試所有測試
- **Debug Specific Test** - 調試特定測試（會提示輸入 filter）

### 推薦的擴展

專案會自動推薦以下擴展：

- [Swift Language](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang) - Swift 語言支援
- [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) - LLDB 調試器
- [Makefile Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.makefile-tools) - Makefile 支援
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) - AI 程式碼助手

---

## 疑難排解

### 問題：`swift: command not found`

**解決方案：**
- 確認 Swift 已正確安裝：`which swift`
- 檢查 PATH 環境變數是否包含 Swift 路徑
- 重新啟動終端機或執行 `source ~/.bashrc`

### 問題：建置失敗 - "Missing required module"

**解決方案：**
```bash
# 清理並重新建置
swift package clean
swift package resolve
swift build
```

### 問題：測試無法執行

**解決方案：**
```bash
# 確認測試目標已建置
swift build --build-tests

# 列出所有測試
swift test --list-tests

# 使用 verbose 模式查看詳細錯誤
swift test -v
```

### 問題：Dev Container 建置失敗

**解決方案：**
1. 確認 Docker 正在運行
2. 刪除舊的容器和映像：
   ```bash
   docker system prune -a
   ```
3. 重新建置容器：
   - VS Code: `F1` → "Dev Containers: Rebuild Container"

### 問題：LLDB 調試無法運作

**解決方案：**
- macOS: 確認已安裝 Xcode Command Line Tools
  ```bash
  xcode-select --install
  ```
- Linux: 確認已安裝 LLDB
  ```bash
  sudo apt-get install lldb
  ```

---

## GitHub Actions CI/CD

專案配置了自動化測試流程：

### 觸發條件

- Push 到 `main` 或 `develop` 分支
- 建立 Pull Request 到 `main` 或 `develop` 分支

### 測試矩陣

- **OS**: Ubuntu 24.04, macOS 14
- **Swift**: 6.1

### 查看測試結果

1. 前往 [GitHub Actions](https://github.com/vivalalova/codable-macro/actions)
2. 選擇最新的 workflow run
3. 查看測試日誌和結果

---

## 貢獻指南

1. Fork 專案
2. 使用 Dev Container 或本地環境設定開發環境
3. 建立功能分支：`git checkout -b feature/amazing-feature`
4. 撰寫測試並確保通過：`swift test`
5. 提交變更：`git commit -m 'Add amazing feature'`
6. 推送到分支：`git push origin feature/amazing-feature`
7. 建立 Pull Request

### 程式碼風格

- 使用 4 個空格縮排
- 遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- 為新功能撰寫測試
- 更新文檔

---

## 資源連結

- [Swift 官方文檔](https://docs.swift.org/)
- [Swift Package Manager 指南](https://swift.org/package-manager/)
- [Swift Macros 文檔](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/)
- [SwiftSyntax API](https://swiftpackageindex.com/apple/swift-syntax)

---

## 授權

本專案使用 MIT License。詳見 [LICENSE](LICENSE) 檔案。
