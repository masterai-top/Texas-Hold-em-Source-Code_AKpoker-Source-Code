[简体中文](README.md) | [繁體中文](README.zh-TW.md) | [English](README.en.md)

# 長牌、短牌與保險玩法德州撲克系統|KKpoker|AApoker|永旺德州

## 企業級德州撲克源碼 | 德州源碼|德州撲克|KKpoker源碼俱樂部|多人競技 | 俱樂部系統 | 聯盟賽事|KK德州|永旺德州


[![GitHub stars](https://img.shields.io/github/stars/masterai-top/Texas-Hold-em-Source-Code)](https://github.com/masterai-top/Texas-Hold-em-Source-Code/stargazers)

[![GitHub forks](https://img.shields.io/github/forks/masterai-top/Texas-Hold-em-Source-Code)](https://github.com/masterai-top/Texas-Hold-em-Source-Code/network)

[![License](https://img.shields.io/badge/license-Commercial-blue.svg)](LICENSE)


> **線上穩定營運多年 | 支援聯盟/俱樂部/私人局 | 媲美 hhpoker, wpk | 原始碼+美術+維運腳本**[reference:6]


---


## 📖 目錄


- [專案簡介](#專案簡介)

- [核心功能](#核心功能)

- [技術架構](#技術架構)

- [快速開始](#快速開始)

- [功能展示](#功能展示)

- [為什麼選擇我們](#為什麼選擇我們)

- [交付內容](#交付內容)

- [聯絡我們](#聯絡我們)


---


## 專案簡介


這是一套 **真正上線運作多年、久經考驗** 的德州撲克全套解決方案[reference:7]。
不同於市面上拼湊的 Demo，我們的程式碼持續迭代，服務穩定，已被多個俱樂部用於實際運作。
包括AKpoker和KKpoker都是使用我們的原始碼；


**適用場景：**

- 🏢 搭建自有品牌的德州撲克平台

- 🎯 開發俱樂部/聯盟競技系統

- 📱 上架 iOS/Android 商店的棋牌遊戲

- 🛠️ 學習企業級 C++/Cocos 遊戲開發


---


## ✨ 核心功能


| 模組 | 功能說明 |

|------|----------|

| **大廳系統** | 多玩法入口、公告、排行榜、商城[reference:8] |

| **約局/俱樂部** | 好友約局、俱樂部創建/管理、聯盟賽事[reference:9] |

| **牌桌邏輯** | 標準德州 / 短牌 / 奧馬哈，自動 Buy-in，Straddle，保險[reference:10] |

| **賽事系統** | MTT（多桌錦標賽）、SNG（坐滿即玩）[reference:11] |

| **後台管理** | 玩家管理、報表統計、局分調整、風險控制[reference:12] |


##  🎮 完整玩法矩陣


- **德州撲克**（Texas Hold'em）— 經典玩法

- **奧馬哈**（Omaha）—— 四張底牌，更多變化

- **短牌**（Short Deck）— 節奏更快，策略不同

- **AOF**（All-in or Fold）— 刺激的 All-in 玩法

- **MTT**（多桌錦標賽）— 大規模競技

- **SNG**（坐滿即玩）— 快速開賽[reference:13]


---


## 🏗️ 技術架構


┌──────────────────────────────────────────────────────────────┐

│ 技術架構全景 │

├──────────────────────────────────────────────────────────────┤

│ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ │

│ │ 用戶端 │ │ 服務端 │ │ 資料層 │ │

│ │ Cocos/Unity │◀－▶│ C++ 高併發 │◀──▶│ MySQL+Redis │ │

│ └──────────────┘ └─────────────┘ └─────────────┘ │

│ │ │ │ │

│ ▼ ▼ ▼ │

│ ┌──────────────┐ ┌─────────────┐ ┌─────────────┐ │

│ │ H5/Web端 │ │ Tars/私有 │ │ 資料持久化 │ │

│ │ 跨平台適配 │ │ 高效率通訊協定 │ │ 快取加速 │ │

│ └──────────────┘ └─────────────┘ └─────────────┘ │

└──────────────────────────────────────────────────────────────┘


客戶端：cocos+js

伺服器：c++和lua

管理後台：使用vue-admin-gin開源框架建構。
         vue3写前端页面
go實作管理後台伺服器


###🏆 為什麼選擇我們

1. 久經考驗，穩定可靠

這套源碼已在多個俱樂部 實際運作多年，服務穩定，程式碼持續迭代。


2. 功能全面，對標頂流

在功能、穩定性和擴展性上，全面優於 hhpoker 和 wpk。


3. 高效能服務端

C++ 編寫的服務端，支援 千人同時在線，無壓力運行。


4. 完整交付，開箱即用

✅ 全套服務端源碼 + 客戶端源碼


✅ 完整的資料庫腳本


✅ 高清美術資源與 UI 原始檔


✅ 部署運維腳本和文檔


5. 可二次開發

程式碼結構清晰，模組化設計，支援 客製化開發和功能擴充。

###📦 交付內容

text

交付清單

├── 服務端源碼（C++）

│ ├── 核心遊戲邏輯

│ ├── 網路通訊模組

│ └── 後台管理介面

├── 客戶端源碼（Cocos Creator / Unity）

│ ├── UI/UX 完整實現

│ └── 多平台適配

├── 資料庫腳本（MySQL）

│ ├── 表結構

│ └── 初始數據

├── 美術資源

│ ├── 高清圖片

│ ├── UI 原始檔

│ └── 音效文件

└── 維運文檔
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

## 📞 聯絡我們

Telegram @xuzongbin001

備用信箱 masterai918@gmail.com


## ⭐ 支持我們

如果這個項目對您有幫助，請給我們一個 Star ⭐，這是對我們最大的認可！


https://api.star-history.com/svg?repos=masterai-top/Texas-Hold-em-Source-Code&type=Date
