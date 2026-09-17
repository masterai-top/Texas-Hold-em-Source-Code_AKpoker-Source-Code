[简体中文](README.md) | [繁體中文](README.zh-TW.md) | [English](README.en.md)

# Texas Hold’em Source Code | Short Deck & Poker Club Modules

A visual starting point for Texas Hold’em client development, short-deck research and poker club evaluation. Review the actual screens and public modules before deciding what to build.

[Visual product page](https://masterai-top.github.io/Texas-Hold-em-Source-Code_AKpoker-Source-Code/en/) · [Code guide and delivery checklist](PROJECT_GUIDE.en.md) · [LICENSE](LICENSE)

## Project overview

See the product. Explore the code. Plan your poker project.

### Long-deck and short-deck entry

The lobby shows separate game categories. Public shortTexas scenes, protocol files and controllers provide a starting point for reading the short-deck client.

### Clubs and hand records

Review room screens, club navigation and hand-record modules to map the player and management journey.

### Insurance interfaces

Original screenshots show insurance and history screens. Rules and calculations still require validation against the delivered implementation.

## Real screens. A clearer development brief.

Images come from this repository’s Screencut folder and retain their original UI and marks. Page copy is translated; screenshots remain in Chinese and do not establish multilingual client support.

### Lobby and game categories

Review navigation between game categories and club features.

<img src="docs/assets/screenshots/lobby.webp" alt="Lobby and game categories" width="320">

### Texas Hold’em table

See the mobile layout for seats, cards and player actions.

<img src="docs/assets/screenshots/table.webp" alt="Texas Hold’em table" width="320">

### Room interface

Use the original room screen to discuss table-selection flows.

<img src="docs/assets/screenshots/room.webp" alt="Room interface" width="320">

### Insurance interface

Inspect how insurance-related information appears during play.

<img src="docs/assets/screenshots/insurance.webp" alt="Insurance interface" width="320">

### Insurance history

Review the history interface and information layout.

<img src="docs/assets/screenshots/insurance-history.webp" alt="Insurance history" width="320">

### Hand information

The source image is named “可存证牌界面”. An image does not verify fairness or the validity of any proof mechanism.

<img src="docs/assets/screenshots/hand-record.webp" alt="Hand information" width="320">

### Administration dashboard

The screenshot shows user, club and reporting menus. It does not establish that the corresponding admin source is public.

<img src="docs/assets/screenshots/admin.webp" alt="Administration dashboard" width="900">


## Technology and public directories

This repository presents source files and product material, not a verified one-click deployment. The public tree contains Cocos-style JavaScript client files and Lua backend modules. The C++ core, Vue 3 / Go admin and complete database/deployment materials described in the previous README require separate confirmation.

| Path | Module |
| --- | --- |
| [前端/Script/shortTexas](前端/Script/shortTexas) | Cocos / JavaScript |
| [后端/main.lua](后端/main.lua) | Lua |
| [后端/Club](后端/Club) | Club |
| [Screencut](Screencut) | View screenshots |

[Code guide and delivery checklist](PROJECT_GUIDE.en.md)

## Turn product interest into a concrete delivery brief

- **01 · Review the screens**：Explore lobby, table and admin screenshots and identify the flows you want to customize.
- **02 · Inspect the code**：Check public modules, dependencies, engine versions and missing project files.
- **03 · Verify the delivery**：Request a runnable demo, build instructions, database scripts, license scope and acceptance criteria.

## Repository and brand-search questions

### Is this the official AKpoker or KKpoker source code?

AKpoker appears in the repository name and KKPOKER appears in the original screenshots. Neither establishes official status, authorization, a partnership or adoption by either brand.

### What Yongwang Poker material is available?

The lobby screenshot displays 永旺德州 (Yongwang Poker). The repository also includes long-deck and short-deck navigation, table, insurance and admin screenshots. These help evaluate product flows, but do not establish brand ownership, parity with a live app or a complete source-code delivery.

### Can I deploy a complete poker platform from this download?

A complete build and deployment path has not been verified. Read the code guide and confirm the full project, runtime dependencies, database and deployment instructions with the maintainer.

### What about Omaha, AOF, MTT and SNG?

The previous README mentioned these modes, but the public files do not establish a complete runnable implementation. Ask for a matching demo and delivery checklist if you need them.

### How are code and custom services licensed?

The current LICENSE contains MIT license text. Refer to that file and the applicable rights for public code; confirm separate terms for unpublished projects, artwork, brand assets and custom work.

## Contact

Share your target platforms, game modes and delivery needs with the maintainer to discuss a demo and source scope.

- Telegram: [@xuzongbin001](https://t.me/xuzongbin001)
- Email: [masterai918@gmail.com](mailto:masterai918@gmail.com)

[简体中文](README.md) | [繁體中文](README.zh-TW.md) | [English](README.en.md)
