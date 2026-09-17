# 公開程式碼導覽與交付確認

檢查基準：2026-09-16，公開提交 e24a9f879ac7cac02a0bf4a67d36337c4b13b1a5。這是檔案範圍說明，並非已驗證的部署教學。

## 閱讀順序

1. 閱讀[專案說明](README.zh-TW.md)及[截圖目錄](Screencut)。
2. 查看[短牌場景](前端/Script/shortTexas/scene/ShortTexasScene.js)：採用 Cocos cc.Class，依賴 TexasScene；目前未確認該基底類別的完整公開實作。
3. 閱讀[短牌協定](前端/Script/shortTexas/proto)，了解請求及回應的組織。
4. 查看[Lua 入口](后端/main.lua)：依賴 publicApi、ServerInfo、SetingConfig 等環境模組，不能假設可獨立啟動。
5. 查看[俱樂部](后端/Club)及[大廳模組](后端/DB_s/Lobby)。

## 交付確認

| 項目 | 公開證據與待確認事項 |
| --- | --- |
| Cocos / JavaScript | 有場景、腳本及 prefab；須確認引擎版本、完整專案、相依項目及建置步驟 |
| Lua 後端 | 有入口及業務模組；須確認宿主執行環境、缺少的模組及設定範例 |
| C++ 核心 | 原 README 提及；本次未發現 .cpp，須確認完整清單 |
| Vue 3 / Go 後台 | 有原始描述及截圖；未發現 .vue/.go，須確認獨立交付內容 |
| 資料庫及部署 | 未發現完整 .sql 或已驗證的一鍵部署流程 |
| Omaha / AOF / MTT / SNG | 原 README 提及；須要求對應展示與驗收依據 |
| 效能 | 無公開基準測試，應依實際測試評估 |

## 授權與品牌

[LICENSE](LICENSE) 包含 MIT 授權文字，本次保留原檔。未公開材料、第三方素材與品牌標誌的權利需另行確認。

倉庫名稱包含 AKpoker，截圖可見 KKPOKER 與永旺德州標誌；這不構成官方原始碼、合作關係或品牌權屬的證明。

## 洽詢時提供

目標平台、長牌／短牌規則、俱樂部流程、後台需求、展示版本、完整檔案清單、編譯環境、資料庫腳本、授權範圍、驗收及維護安排。

[返回專案介紹](README.zh-TW.md)

