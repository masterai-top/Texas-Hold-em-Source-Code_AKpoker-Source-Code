# 🃏 Texas Hold'em Poker Source Code
## 企业级德州扑克源码 | 德州源码|德州扑克|KKpoker源码俱乐部|多人竞技 | 俱乐部系统 | 联盟赛事|KK德州|永旺德州

[![GitHub stars](https://img.shields.io/github/stars/masterai-top/Texas-Hold-em-Source-Code)](https://github.com/masterai-top/Texas-Hold-em-Source-Code/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/masterai-top/Texas-Hold-em-Source-Code)](https://github.com/masterai-top/Texas-Hold-em-Source-Code/network)
[![License](https://img.shields.io/badge/license-Commercial-blue.svg)](LICENSE)

> **线上稳定运营多年 | 支持联盟/俱乐部/私人局 | 媲美 hhpoker, wpk | 源码+美术+运维脚本**[reference:6]

---

## 📖 目录

- [项目简介](#项目简介)
- [核心功能](#核心功能)
- [技术架构](#技术架构)
- [快速开始](#快速开始)
- [功能展示](#功能展示)
- [为什么选择我们](#为什么选择我们)
- [交付内容](#交付内容)
- [联系我们](#联系我们)

---

## 项目简介

这是一套 **真正上线运营多年、久经考验** 的德州扑克全套解决方案[reference:7]。不同于市面上拼凑的 Demo，我们的代码持续迭代，服务稳定，已被多个俱乐部用于实际运营。包括AKpoker和KKpoker都是使用我们的源码；

**适用场景：**
- 🏢 搭建自有品牌的德州扑克平台
- 🎯 开发俱乐部/联盟竞技系统
- 📱 上架 iOS/Android 商店的棋牌游戏
- 🛠️ 学习企业级 C++/Cocos 游戏开发

---

## ✨ 核心功能

| 模块 | 功能说明 |
|------|----------|
| **大厅系统** | 多玩法入口、公告、排行榜、商城[reference:8] |
| **约局/俱乐部** | 好友约局、俱乐部创建/管理、联盟赛事[reference:9] |
| **牌桌逻辑** | 标准德州 / 短牌 / 奥马哈，自动 Buy-in，Straddle，保险[reference:10] |
| **赛事系统** | MTT（多桌锦标赛）、SNG（坐满即玩）[reference:11] |
| **后台管理** | 玩家管理、报表统计、局分调整、风险控制[reference:12] |

### 🎮 完整玩法矩阵

- **德州扑克**（Texas Hold'em）—— 经典玩法
- **奥马哈**（Omaha）—— 四张底牌，更多变化
- **短牌**（Short Deck）—— 节奏更快，策略不同
- **AOF**（All-in or Fold）—— 刺激的 All-in 玩法
- **MTT**（多桌锦标赛）—— 大规模竞技
- **SNG**（坐满即玩）—— 快速开赛[reference:13]

---

## 🏗️ 技术架构

┌─────────────────────────────────────────────────────────────┐
│ 技术架构全景 │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │ 客户端 │ │ 服务端 │ │ 数据层 │ │
│ │ Cocos/Unity │◀──▶│ C++ 高并发 │◀──▶│ MySQL+Redis │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ │
│ │ │ │ │
│ ▼ ▼ ▼ │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │ H5/Web端 │ │ Tars/私有 │ │ 数据持久化 │ │
│ │ 跨平台适配 │ │ 高效通信协议 │ │ 缓存加速 │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────┘

客户端：cocos+js
服务器：c++和lua
管理后台：使用vue-admin-gin开源框架搭建。
         vue3写前端页面
		 go实现管理后台服务器
		 
###🏆 为什么选择我们
1. 久经考验，稳定可靠
这套源码已在多个俱乐部 实际运营多年，服务稳定，代码持续迭代。

2. 功能全面，对标顶流
在功能、稳定性和扩展性上，全面优于 hhpoker 和 wpk。

3. 高性能服务端
C++ 编写的服务端，支持 千人同时在线，无压力运行。

4. 完整交付，开箱即用
✅ 全套服务端源码 + 客户端源码

✅ 完整的数据库脚本

✅ 高清美术资源和 UI 源文件

✅ 部署运维脚本和文档

5. 可二次开发
代码结构清晰，模块化设计，支持 客制化开发和功能扩展。
###📦 交付内容
text
交付清单
├── 服务端源码（C++）
│   ├── 核心游戏逻辑
│   ├── 网络通信模块
│   └── 后台管理接口
├── 客户端源码（Cocos Creator / Unity）
│   ├── UI/UX 完整实现
│   └── 多平台适配
├── 数据库脚本（MySQL）
│   ├── 表结构
│   └── 初始数据
├── 美术资源
│   ├── 高清图片
│   ├── UI 源文件
│   └── 音效文件
└── 运维文档
    ├── 部署指南
    └── 运维脚本[reference:24]

### 🖼️ 功能展示  
<img width="246" height="381" alt="主界面" src="https://github.com/user-attachments/assets/d0b2f8fd-8436-4767-998b-c5b55cde276f" />
<img width="246" height="381" alt="账单界面" src="https://github.com/user-attachments/assets/95706dcc-a864-43b5-9141-990a927472aa" />
<img width="246" height="381" alt="游戏界面" src="https://github.com/user-attachments/assets/bce93909-e79f-46c2-8a2e-6fa97ddb75a9" />
<img width="246" height="381" alt="游戏房间界面" src="https://github.com/user-attachments/assets/3d06669e-a7c2-4c73-bafb-433ca8ce712c" />
<img width="956" height="457" alt="系统管理后台界面" src="https://github.com/user-attachments/assets/047ad980-a99f-453b-b1e7-38cbca9b4b48" />
<img width="246" height="381" alt="我的界面" src="https://github.com/user-attachments/assets/9729f825-79d8-4c3a-a931-9a04ac92b0ee" />
<img width="246" height="381" alt="提币界面" src="https://github.com/user-attachments/assets/6e5aa6bc-57f3-4eab-8653-68c9a91fda01" />
<img width="246" height="381" alt="历史保险界面" src="https://github.com/user-attachments/assets/f9c78301-c6c2-4118-a4d0-428ea22c4c10" />
<img width="246" height="381" alt="可存证牌界面" src="https://github.com/user-attachments/assets/1fb14d89-52c7-40c4-9477-b2cc1604c6a1" />
<img width="246" height="381" alt="活动界面" src="https://github.com/user-attachments/assets/2ec07b48-e74e-4692-9d91-e53effb8eb47" />
<img width="246" height="381" alt="充值账单界面" src="https://github.com/user-attachments/assets/72b6ad88-7717-4407-b354-4bc2c2cfc9f4" />
<img width="246" height="381" alt="充币界面" src="https://github.com/user-attachments/assets/87193e5b-d26c-4c46-b9fc-318f61a53bc6" />
<img width="246" height="381" alt="保险界面" src="https://github.com/user-attachments/assets/23202125-00fb-4e72-a5a2-bd388749749b" />
###📞 联系我们
Telegram	@xuzongbin001
备用邮箱	masterai918@gmail.com


###⭐ 支持我们
如果这个项目对您有帮助，请给我们一个 Star ⭐，这是对我们最大的认可！

https://api.star-history.com/svg?repos=masterai-top/Texas-Hold-em-Source-Code&type=Date




