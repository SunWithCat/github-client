# 贡献指南 | Contributing Guide

感谢你对 GhClient 的关注！我们欢迎任何形式的贡献。

## 🐛 报告 Bug

如果你发现了 Bug，请通过 [Issues](https://github.com/SunWithCat/github-client/issues) 提交，包含以下信息：

- **问题描述**：清晰描述遇到的问题
- **复现步骤**：如何重现这个问题
- **预期行为**：你期望的正确行为是什么
- **实际行为**：实际发生了什么
- **环境信息**：设备型号、系统版本、Flutter 版本等

## 💡 功能建议

有新功能的想法？欢迎提交 Issue 并标记为 `enhancement`。

## 🔧 提交代码

### 开发环境

```bash
# 确保已安装 Flutter SDK
flutter doctor

# 克隆仓库
git clone https://github.com/SunWithCat/github-client.git
cd github-client

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 提交流程

1. **Fork** 这个仓库
2. 创建你的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 **Pull Request**

### 代码规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 代码风格
- 运行 `flutter analyze` 确保没有警告
- 有意义的 commit message

## 📝 提交信息规范

推荐使用以下前缀：

| 前缀 | 说明 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | Bug 修复 |
| `docs:` | 文档更新 |
| `style:` | 代码格式（不影响功能） |
| `refactor:` | 重构代码 |
| `test:` | 测试相关 |
| `chore:` | 构建/工具相关 |

示例：`feat: 添加仓库搜索功能`

## ❤️ 感谢

感谢所有贡献者的付出！
