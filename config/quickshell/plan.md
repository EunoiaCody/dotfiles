# 计划：Replace Overview Schedule Card with Illustration + Hitokoto Widget

> 创建时间：7/17/2026, 3:44:46 PM
> 状态：审阅中

## 任务
我现在想要换掉课表卡片这一列，他的浮动视图不变，但是内容换掉

首先，要有一张图片显示在那里，同时，图片的右边要显示一句话，图片正常显示就好，但是那句话要用古代汉语的顺序来写，也就是每一个字按“从上到下，从左到右”的顺序

然后，要有一个类似"Wallpapers"栏一样的图片选择，在`/home/eunoia/Pictures/Illustraions`中选择，图片选择可以直接复用壁纸选择

最后，显然空间不够，原本的课表卡片列也只够放一个图片而已，文字不够，所以overview的大小也要改，纵向长度应该不用变，水平长度改成和wallpapers栏的水平长度一样长就好

另外，显示的那一句话从著名项目"hitokoto"(一言)获取，他的接口说明在`https://developer.hitokoto.cn/sentence/#%E6%8E%A5%E5%8F%A3%E8%AF%B4%E6%98%8E`

Now I have all the dimensions and code patterns. Let me construct the full plan.

---

## Plan: Replace Overview Schedule Card with Illustration + Hitokoto Widget

### Overview

Replace the 3rd column of `OverviewContent` (currently `ScheduleWidget` inside a `FloatingHoleCard`) with a new `IllustrationHitokoto` widget that shows a selectable illustration on the left and a Hitokoto quote rendered in ancient Chinese vertical text (top→bottom, right→left) on the right. The Overview panel widens from 860px to 960px to accommodate the new layout. The floating-hole visual effect is preserved by updating the cutout rectangles in `DynamicIsland.qml`.

### Affected Files

| File | Change |
|------|--------|
| `Modules/DynamicIsland/OverviewContent/IllustrationHitokoto.qml` | **NEW** — image + vertical text + compact carousel |
| `Modules/DynamicIsland/OverviewContent/OverviewContent.qml` | **MODIFY** — wider layout, replace 3rd column |
| `Modules/DynamicIsland/Hub/HubContent.qml` | **MODIFY** — Overview tab width 860→960 |
| `Modules/DynamicIsland/DynamicIsland.qml` | **MODIFY** — two hole cutouts (340→448 width) |
| `Modules/DynamicIsland/OverviewContent/ScheduleWidget.qml` | **UNTOUCHED** — kept as file, no longer referenced |

### Step-by-Step Plan

---

#### Phase 1: Create `IllustrationHitokoto.qml` — The New Widget

- [ ] **1.1** Create the file `Modules/DynamicIsland/OverviewContent/IllustrationHitokoto.qml`
- [ ] **1.2** Define the root `Item` with a `FloatingHoleCard` wrapper (reuse the existing component from `OverviewContent.qml`)
- [ ] **1.3** Implement **image scanning** from `/home/eunoia/Pictures/Illustraions/` using `Process` + `find` (same pattern as `WallpaperContent.qml` lines 15–30): scan for `*.jpg`, `*.jpeg`, `*.png`, `*.webp`
- [ ] **1.4** Add `property string currentImagePath` and `ListModel { id: imageModel }` for tracking the selected illustration
- [ ] **1.5** Implement **Hitokoto API fetch** via `XMLHttpRequest` to `https://v1.hitokoto.cn/` (GET, returns JSON). Store `hitokoto`, `from`, `from_who` properties. Fetch on component mount and provide a refresh button
- [ ] **1.6** Implement the **main display area** (`Row` layout):
  - **Left**: `Image` component (~180×240px) showing `currentImagePath`, with `PreserveAspectCrop`, rounded corners, and a click handler to focus the carousel
  - **Right**: Ancient Chinese vertical text rendering — a `Row` with `layoutDirection: Qt.RightToLeft` containing dynamically-generated `Column` items, each holding ~8–10 characters. Split the `hitokoto` string into N-character chunks. Also show `—— " + from` at the bottom of the last column
- [ ] **1.7** Implement a **compact image carousel** at the bottom of the card:
  - A horizontal `PathView` (or simpler `ListView`) ~80px tall showing thumbnail previews
  - Each thumbnail ~60×40px, clickable to select the current image
  - Reference: adapt `WallpaperContent.qml` PathView pattern (lines 55–160) but scaled down
- [ ] **1.8** Add a **refresh button** for the Hitokoto quote (small circular button, Material Symbols `refresh` icon) and a brief fade animation on quote change

---

#### Phase 2: Update `OverviewContent.qml` — Layout Changes

- [ ] **2.1** Change `implicitWidth` from `860` to `960` (line 12)
- [ ] **2.2** Replace the 3rd column (lines 148–162, the `Item` containing `FloatingHoleCard { ScheduleWidget }`) with a reference to `IllustrationHitokoto`:
  ```qml
  Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      IllustrationHitokoto {
          width: 448
          anchors.left: parent.left
          anchors.leftMargin: 32  // card starts at root horizontal center
          anchors.top: parent.top
          anchors.bottom: parent.bottom
      }
  }
  ```
- [ ] **2.3** Remove the `FloatingHoleCard` component definition from `OverviewContent.qml` since it now lives in `IllustrationHitokoto.qml` (or keep a shared component — decide: since it's used nowhere else, move it to the new file)
- [ ] **2.4** Keep columns 1 (sliders, 48px) and 2 (SysInfo + Calendar, 320px) unchanged

---

#### Phase 3: Update `HubContent.qml` — Tab Width

- [ ] **3.1** Change `currentIndex === 0 ? 860` → `currentIndex === 0 ? 960` on line 28

---

#### Phase 4: Update `DynamicIsland.qml` — Hole Cutout Dimensions

- [ ] **4.1** In `shadowHoleWrapper` (line ~123–131): change `width: 340` → `width: 448`, change `anchors.leftMargin: 48` → `anchors.leftMargin: 0` (card now starts at center)
- [ ] **4.2** In `rootHoleWrapper` (line ~412–419): same changes — `width: 340` → `width: 448`, `anchors.leftMargin: 48` → `anchors.leftMargin: 0`
- [ ] **4.3** The hole `height: 456`, `anchors.topMargin: 132`, and `radius: 24` remain unchanged

---

### Dimensions Summary (Reference)

| Element | Old Value | New Value |
|---------|-----------|-----------|
| Overview total width | 860px | 960px |
| Overview total height | 520px | 520px (unchanged) |
| Col3 available width | 380px | 480px |
| `FloatingHoleCard` width | 340px | 448px |
| `FloatingHoleCard` leftMargin | 30px | 32px |
| Card left edge (root space) | center+48 | center+0 |
| Hole width (×2 locations) | 340px | 448px |
| Hole `anchors.leftMargin` | 48 | 0 |
| Hole height & topMargin | 456, 132 | 456, 132 (unchanged) |
| Hub tab width for index 0 | 860 | 960 |

### Vertial Text Layout Detail

For a Hitokoto sentence like "用代码表达言语的魅力，用代码书写山河的壮丽。" (22 chars), split into 3 columns:

```
layoutDirection: Qt.RightToLeft

  Column 3      Column 2      Column 1
  ┌──────┐     ┌──────┐      ┌──────┐
  │  用  │     │  达  │      │  丽  │
  │  代  │     │  言  │      │  。  │
  │  码  │     │  语  │      │      │
  │  书  │     │  的  │      │      │
  │  写  │     │  魅  │      │      │
  │  山  │     │  力  │      │      │
  │  河  │     │  ，  │      │      │
  │  的  │     │  用  │      │      │
  │  壮  │     │  表  │      │      │
  └──────┘     └──────┘      └──────┘
```

Each column: 10 chars max, font ~13px → column height ~130px, well within the ~300px available.

### Hitokoto API Integration

```
Request:  GET https://v1.hitokoto.cn/?c=a&c=b&c=d&c=i&c=k
Response: {
    "id": 7338,
    "hitokoto": "用代码表达言语的魅力，用代码书写山河的壮丽。",
    "type": "f",
    "from": "一言开发者中心",
    "from_who": "一言",
    ...
}
```

Parameters: `c=a` (anime), `c=b` (comic), `c=d` (literature), `c=i` (poetry), `c=k` (philosophy) — exclude `c=j` (NetEase, deprecated) and `c=l` (抖机灵/memes).

Use `XMLHttpRequest` (Qt's QML-supported network API), async GET, parse JSON with `JSON.parse()`, populate properties.

### Risks & Considerations

1. **Directory `Illustraions` may not exist** — The widget should handle the case gracefully: show a placeholder icon and "No illustrations found" text when the directory is empty or missing
2. **Hitokoto API rate limit** — The API has a 2 QPS limit. Add a cooldown/throttle on the refresh button (disable for ~2 seconds after each fetch). Cache the result locally
3. **Hitokoto API network failure** — Fallback to a hardcoded default quote (e.g., "岁月失语，惟石能言。") if the request fails or times out
4. **Vertical text splitting** — Chinese punctuation (，。) should stay at the bottom of a column, not be orphaned at the top of the next. Basic rule: if a column would start with punctuation, pull the previous char down too
5. **XMLHttpRequest in QML** — Qt's QML network support may not be available in all builds. Verify `QtQuick` XMLHttpRequest works; fallback to a `Process` calling `curl` if needed
6. **Hole alignment precision** — Any miscalculation in the hole position will misalign the transparent cutout. The key invariant: `card.leftEdge === root.centerX + hole.leftMargin`. Double-check after changes
7. **Card content overflow** — With vertical text that could be very long (some Hitokoto sentences are 30+ chars), implement `clip: true` and limit column count to ~12 columns max

### Estimated Impact

- Files to create: **1** (`IllustrationHitokoto.qml`)
- Files to modify: **3** (`OverviewContent.qml`, `HubContent.qml`, `DynamicIsland.qml`)
- Files to delete: **0** (ScheduleWidget.qml kept as unused file)

---

**PLAN COMPLETE**