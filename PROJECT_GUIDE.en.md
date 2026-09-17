# Public code guide and delivery checklist

Inspected on 2026-09-16 at public commit e24a9f879ac7cac02a0bf4a67d36337c4b13b1a5. This guide describes file coverage; it is not a verified deployment tutorial.

## Reading order

1. Start with the [overview](README.en.md) and [original screenshots](Screencut).
2. Inspect [ShortTexasScene.js](前端/Script/shortTexas/scene/ShortTexasScene.js). It uses Cocos cc.Class and depends on TexasScene; a complete implementation of that base class was not established in the public tree.
3. Read the [short-deck protocol files](前端/Script/shortTexas/proto).
4. Inspect the [Lua entry point](后端/main.lua). It requires environment modules including publicApi, ServerInfo and SetingConfig; it should not be assumed to start independently.
5. Review the [club](后端/Club) and [lobby modules](后端/DB_s/Lobby).

## What to verify

| Component | Public evidence and next check |
| --- | --- |
| Cocos / JavaScript | Scenes, scripts and prefabs are present. Confirm engine version, full project, dependencies and build steps. |
| Lua backend | Entry point and business modules are present. Confirm host runtime, missing modules and sample configuration. |
| C++ core | Described in the previous README; no .cpp source was found in this inspection. Request a full inventory. |
| Vue 3 / Go admin | Described and shown in screenshots; no .vue/.go source was found. Confirm separate delivery. |
| Database and deployment | No complete .sql scripts or verified one-click deployment path were found. |
| Omaha / AOF / MTT / SNG | Mentioned in the previous README. Request matching demos and acceptance criteria. |
| Performance | No public benchmark report; evaluate measured results on specified hardware and workloads. |

## License and brands

The existing [LICENSE](LICENSE) contains MIT license text and is unchanged. Confirm separate rights for unpublished materials, third-party assets and brand marks.

AKpoker appears in the repository name; KKPOKER and 永旺德州 (Yongwang Poker) appear in screenshots. This does not establish official source status, a partnership or brand ownership.

## A useful development brief

Include target platforms, long-deck/short-deck rules, club flows, admin requirements, demo version, full file inventory, build environment, database scripts, license scope, acceptance criteria and maintenance needs.

[Back to the overview](README.en.md)

