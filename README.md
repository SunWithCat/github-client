# GhClient

<p align="center">
  <strong>一款精美的 Flutter GitHub 客户端</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
  <img src="https://img.shields.io/github/stars/SunWithCat/github-client?style=flat-square" alt="Stars" />
</p>


<p align="center">
  <a href="https://github.com/SunWithCat/github-client/stargazers">
    <img src="https://img.shields.io/github/stars/SunWithCat/github-client?style=social" alt="Stars" />
  </a>
  <a href="https://github.com/SunWithCat/github-client/network/members">
    <img src="https://img.shields.io/github/forks/SunWithCat/github-client?style=social" alt="Forks" />
  </a>
  <a href="https://github.com/SunWithCat/github-client/issues">
    <img src="https://img.shields.io/github/issues/SunWithCat/github-client" alt="Issues" />
  </a>
  <img src="https://img.shields.io/github/last-commit/SunWithCat/github-client" alt="Last Commit" />
</p>

---

GhClient 是一款使用 Flutter 构建的第三方 GitHub 客户端，旨在提供流畅、美观且功能丰富的移动端 GitHub 体验。

## 📑 目录

- [功能特性](#-功能特性)
- [应用截图](#-应用截图)
- [技术栈](#-技术栈)
- [快速开始](#-快速开始)
- [许可证](#-许可证)

## ✨ 功能特性

- 🔐 **安全登录** - 通过 GitHub OAuth 实现安全可靠的用户认证
- 📂 **仓库阅览** - 浏览、搜索您的个人仓库和星标仓库
- 🔍 **项目探索** - 查看、搜索本月/周/日的趋势项目
- 🌓 **主题切换** - 内置浅色和深色两种主题模式
- 📄 **HTML 渲染** - 使用轻量的 HTML 渲染 README 和文档内容

## 📱 应用截图

<p align="center">
  <img src="home.jpg" width="24%" alt="主页" />
  <img src="repos.jpg" width="24%" alt="仓库" />
  <img src="starred_repos.jpg" width="24%" alt="星标" />
  <img src="detail.jpg" width="24%" alt="详情" />
</p>
<p align="center">
  <img src="explore.jpg" width="24%" alt="探索" />
  <img src="search.jpg" width="24%" alt="搜索" />
</p>

## 🔧 技术栈

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Riverpod-0553B1?style=flat-square&logo=riverpod&logoColor=white" alt="Riverpod" />
  <img src="https://img.shields.io/badge/go__router-00ADD8?style=flat-square&logo=flutter&logoColor=white" alt="go_router" />
  <img src="https://img.shields.io/badge/Dio-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dio" />
  <img src="https://img.shields.io/badge/Hive-FFD43B?style=flat-square&logo=hive&logoColor=black" alt="Hive" />
</p>

| 类别 | 库 | 用途 |
|------|-----|------|
| **状态管理** | [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) | 声明式响应式状态管理 |
| **路由管理** | [go_router](https://pub.dev/packages/go_router) | 声明式路由与重定向 |
| **网络请求** | [Dio](https://pub.dev/packages/dio) | HTTP 客户端 |
| **本地存储** | [Hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) + [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) | 数据持久化 & 安全存储 |
| **Deep Links** | [app_links](https://pub.dev/packages/app_links) | OAuth 回调处理 |
| **Markdown** | [flutter_widget_from_html_core](https://pub.dev/packages/flutter_widget_from_html_core) | HTML/Markdown 渲染 |
| **OAuth 授权** | [url_launcher](https://pub.dev/packages/url_launcher) | 打开外部浏览器进行授权 |
| **动画效果** | [flutter_animate](https://pub.dev/packages/flutter_animate) | 流畅的动画效果 |
| **SVG 支持** | [flutter_svg](https://pub.dev/packages/flutter_svg) | SVG 图标和图像渲染 |
| **图标** | [flutter_octicons](https://pub.dev/packages/flutter_octicons) | GitHub 图标库 |
| **图片** | [cached_network_image](https://pub.dev/packages/cached_network_image) | 网络图片缓存 |

## 🚀 快速开始

### 环境要求

- Flutter SDK `>=3.7.2`
- Dart SDK `>=3.7.2`
- Android Studio / VS Code
- Android SDK / Xcode

### 安装运行

```bash
# 克隆项目
git clone https://github.com/SunWithCat/github-client.git
cd github-client

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建发布

```bash
# Android
flutter build apk --release # 构建分包使用 flutter build apk --split-per-abi

# iOS
flutter build ios --release
```

## ⚙️ 配置说明

在 lib/config.dart 中配置 GitHub OAuth 相关参数：

```dart
class AppConfig {
  static const String githubClientId = 'Ovxxxxxxxxxxx';
  static const String githubClientSecret =
      'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String githubCallbackUrl = 'myfluttergithubapp://callback';
}
```

使用 GitHub OAuth 功能需要：

1. 在 [GitHub Developer Settings](https://github.com/settings/developers) 创建 OAuth 应用
2. 设置回调 URL（与 `lib/config.dart` 保持一致）: `myfluttergithubapp://callback`
3. 获取 `Client ID` 和 `Client Secret`
4. 在 `lib/config.dart` 中配置 `githubClientId`、`githubClientSecret`、`githubCallbackUrl`

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

---

<p align="center">
  如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！
</p>
