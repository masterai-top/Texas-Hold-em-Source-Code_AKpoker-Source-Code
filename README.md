[简体中文](README.md) | [繁體中文](README.zh-TW.md) | [English](README.en.md)

# 德州扑克源码（德州源码）｜长牌、短牌与俱乐部系统

面向德州扑克客户端开发、短牌玩法研究与俱乐部系统评估。先看真实界面，再对照公开代码，确认适合你的开发需求。

[图文产品页](https://masterai-top.github.io/Texas-Hold-em-Source-Code_AKpoker-Source-Code/zh-cn/) · [代码导览与交付核对](PROJECT_GUIDE.zh-cn.md) · [LICENSE](LICENSE)

## 项目简介

从大厅到牌桌，直观看懂这套德州项目。

### 长牌与短牌入口

大厅截图展示长牌、短牌分类；公开客户端包含 shortTexas 场景、协议与控制器，可作为阅读短牌模块的起点。

### 俱乐部与牌局记录

查看房间列表、俱乐部入口和牌局记录模块，梳理从选桌到管理的产品流程。

### 保险与历史界面

通过原始截图观察保险信息和历史记录的呈现方式；具体规则与计算逻辑需结合完整交付验证。

## 真实产品截图，先看界面再谈开发

截图来自本仓库 Screencut，保留原界面与标识。网站说明支持三种语言，截图仍为原始中文，不代表客户端已完成三语本地化。

### 大厅与玩法入口

长牌、短牌和俱乐部导航集中展示，便于评估信息层级。

<img src="docs/assets/screenshots/lobby.webp" alt="大厅与玩法入口" width="320">

### 德州牌桌

座位、公共牌区与操作按钮，展示移动端牌桌布局。

<img src="docs/assets/screenshots/table.webp" alt="德州牌桌" width="320">

### 房间界面

对照房间画面，规划选桌与入桌流程。

<img src="docs/assets/screenshots/room.webp" alt="房间界面" width="320">

### 保险界面

查看保险相关信息在牌局中的呈现位置。

<img src="docs/assets/screenshots/insurance.webp" alt="保险界面" width="320">

### 历史保险

补充查看历史记录页面，评估信息查阅体验。

<img src="docs/assets/screenshots/insurance-history.webp" alt="历史保险" width="320">

### 牌局信息展示

原文件名为“可存证牌界面”；截图不构成公平性或存证有效性的验证。

<img src="docs/assets/screenshots/hand-record.webp" alt="牌局信息展示" width="320">

### 管理后台

截图展示用户、俱乐部、报表等菜单；仅凭截图不能确认对应后台源码已公开。

<img src="docs/assets/screenshots/admin.webp" alt="管理后台" width="900">


## 技术与公开目录

当前仓库是源码与产品资料的公开展示，不能据此承诺一键部署。公开文件可确认 Cocos 风格 JavaScript 客户端与 Lua 后端模块；原 README 描述的 C++ 核心、Vue 3 / Go 后台和完整数据库部署材料，需要单独核对。

| Path | Module |
| --- | --- |
| [前端/Script/shortTexas](前端/Script/shortTexas) | Cocos / JavaScript |
| [后端/main.lua](后端/main.lua) | Lua |
| [后端/Club](后端/Club) | Club |
| [Screencut](Screencut) | 浏览产品截图 |

[代码导览与交付核对](PROJECT_GUIDE.zh-cn.md)

## 把需求变成可核对的交付清单

- **01 · 看产品**：先浏览大厅、牌桌和后台截图，明确要保留或定制的流程。
- **02 · 看代码**：检查公开客户端和后端模块，核对依赖、引擎版本及缺失文件。
- **03 · 验证交付**：要求可运行演示、构建说明、数据库脚本、授权范围和功能验收记录。

## 选型与品牌检索常见问题

### 搜索 AKpoker、KKpoker 源码，为什么看到这个仓库？

仓库名称包含 AKpoker，原始截图中出现 KKPOKER 标识。这些信息可用于理解项目资料，但不足以证明本仓库是 AKpoker 或 KKpoker 官方源码，也不证明授权、合作或实际采用关系。

### 永旺德州有哪些可查看的产品资料？

本仓库大厅截图可见“永旺德州”名称，并提供长牌、短牌入口、牌桌、保险与管理后台图片。你可以据此评估产品流程；截图本身不证明品牌权属、线上版本一致性或完整代码交付范围。

### 公开仓库包含可直接部署的完整德州源码吗？

未验证。当前缺少可确认的完整构建与部署链路。下载前请阅读代码导览，并向维护者确认完整工程、运行依赖、数据库与部署说明。

### 还有奥马哈、AOF、MTT 和 SNG 吗？

原 README 提及这些玩法，当前公开文件不足以验证它们是否完整可用。若属于你的需求，应要求对应演示与交付清单。

### 如何理解授权与后续定制？

当前 LICENSE 含 MIT 许可文本。公开代码的许可应以该文件及权利范围为准；未公开工程、美术、品牌素材和定制服务需要另行确认。

## 联系维护者

带上目标平台、玩法和交付需求，与维护者沟通演示及代码范围。

- Telegram: [@xuzongbin001](https://t.me/xuzongbin001)
- Email: [masterai918@gmail.com](mailto:masterai918@gmail.com)

[简体中文](README.md) | [繁體中文](README.zh-TW.md) | [English](README.en.md)
