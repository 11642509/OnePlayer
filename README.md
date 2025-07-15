<!--
README 支持中英切换，使用 <details> 标签实现折叠/展开效果。
-->

# OnePlayer

> 让大屏体验焕然一新的 Flutter 全端视频播放器  
> _A next-generation, truly cross-platform Flutter video player for TV, mobile, web, and desktop_

---

<details open>
<summary><strong>🇨🇳 简体中文</strong></summary>

## 项目简介

**OnePlayer** 是一款专为智能电视、盒子、投影仪等大屏设备打造，同时也完美支持手机、平板、Web、桌面等全平台的 Flutter 视频应用。无论你用的是TV、安卓/iOS手机、平板、PC还是Web浏览器，OnePlayer 都能带来一致、极致的遥控与触控体验。

## ✨ 核心特性
- **全端支持**：一套代码，畅享 TV、手机、平板、Web、桌面等所有主流平台。
- **遥控器极致适配**：全局焦点管理，支持方向键、OK、返回、快进/快退、媒体键等主流遥控器操作。
- **美学与动画**：自研 FocusableGlow 辉光焦点、药丸Tab、B站风格卡片，横竖屏自适应，动画流畅。
- **高性能与稳定性**：超大缓存、滚动优化、焦点健壮，长时间运行不卡死。
- **多内核播放器**：支持 VLC、video_player 等多种内核，兼容多格式流媒体。
- **模块化与可扩展**：代码结构清晰，易于二次开发和自定义。
- **深浅色主题**：自动适配，夜间观影更护眼。

## 🖼️ 界面预览

> （此处可插入项目截图，建议展示 TV、手机、Web、桌面等多端界面）

## 🚀 快速开始
1. **环境准备**：Flutter 3.10+，Dart 3.0+，支持 TV、手机、平板、Web、桌面等全端环境
2. **安装依赖**：
   ```bash
   flutter pub get
   ```
3. **运行项目**：
   ```bash
   flutter run -d <device>
   ```
   你可以用 `flutter devices` 查看所有可用平台。
4. **全端体验**：
   - TV端：遥控器方向键/OK/返回/快进/快退
   - 手机/平板：触控手势、滑动、点击
   - Web/桌面：鼠标、键盘、全键盘遥控

## 🏗️ 技术架构
- Flutter 3.x 全平台支持（Android TV、iOS、iPad、Web、Windows、macOS、Linux...）
- GetX 响应式状态管理
- 自研焦点系统，支持复杂遥控器与键盘流转
- 多内核播放器：VLC、video_player 可切换
- 自适应布局，横竖屏/分辨率自动适配
- 高性能网格与滚动

## 💡 常见问题
- **支持哪些平台？** 几乎所有主流平台：TV、手机、平板、Web、桌面。
- **支持哪些遥控器？** 绝大多数Android TV、盒子、投影仪遥控器。
- **可以自定义UI和焦点效果吗？** 支持，FocusableGlow、Tab、导航栏等均可自定义。
- **支持哪些视频格式？** 取决于播放器内核，VLC支持mp4、mkv、flv、m3u8、dash等。
- **如何集成到自有项目？** 代码高度模块化，欢迎二次开发。

## 🤝 贡献与社区
欢迎提交 Issue、PR，或参与文档完善。期待你的 Star ⭐️ 与建议！

## 📧 联系与支持
- Issues/PR 欢迎提交
- 邮箱：hi@oneplayer.tv

## 📝 License
MIT

</details>

<details>
<summary><strong>🇺🇸 English</strong></summary>

## Overview

**OnePlayer** is a truly cross-platform Flutter video player app designed for smart TVs, set-top boxes, projectors, as well as mobile phones, tablets, web, and desktop. Whether you use TV, Android/iOS, iPad, PC, or a web browser, OnePlayer delivers a consistent, premium remote and touch experience everywhere.

## ✨ Core Features
- **Full Cross-Platform**: One codebase, runs on TV, mobile, tablet, web, and desktop (Windows/macOS/Linux) out of the box.
- **Ultimate Remote Support**: Global focus management, supports D-pad, OK, Back, Fast Forward/Rewind, and media keys.
- **Aesthetics & Animation**: Custom FocusableGlow, pill tabs, Bilibili-style cards, adaptive layouts, smooth transitions.
- **Performance & Stability**: Large cache, scroll optimization, robust focus, stable for long sessions.
- **Multi-core Player**: Supports VLC, video_player, and more, compatible with various streaming formats.
- **Modular & Extensible**: Clean codebase, easy for secondary development and customization.
- **Dark/Light Themes**: Auto-adapt, eye-friendly for night viewing.

## 🖼️ Screenshots

> (Insert screenshots for TV, mobile, web, desktop, etc.)

## 🚀 Quick Start
1. **Prerequisites**: Flutter 3.10+, Dart 3.0+, supports TV, mobile, tablet, web, desktop
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run -d <device>
   ```
   Use `flutter devices` to list all available platforms.
4. **Cross-Platform Experience**:
   - TV: Remote D-pad/OK/Back/FF/RW
   - Mobile/Tablet: Touch gestures, swipe, tap
   - Web/Desktop: Mouse, keyboard, full keyboard remote

## 🏗️ Architecture
- Flutter 3.x cross-platform (Android TV, iOS, iPad, Web, Windows, macOS, Linux...)
- GetX for reactive state management
- Custom focus system for complex remote & keyboard navigation
- Multi-core player: VLC, video_player switchable
- Adaptive layouts for landscape/portrait/resolution
- High-performance grid and scrolling

## 💡 FAQ
- **Which platforms are supported?** Virtually all: TV, mobile, tablet, web, desktop.
- **Which remotes are supported?** Most Android TV, box, and projector remotes.
- **Can I customize UI and focus effects?** Yes, FocusableGlow, tabs, nav bar, etc. are all customizable.
- **Which video formats are supported?** Depends on player core, VLC supports mp4, mkv, flv, m3u8, dash, etc.
- **How to integrate into my project?** Highly modular code, easy for secondary development.

## 🤝 Contributing
PRs, issues, and documentation improvements are welcome. Star ⭐️ and feedback appreciated!

## 📧 Contact & Support
- Issues/PRs welcome
- Email: hi@oneplayer.tv

## 📝 License
MIT

</details>
