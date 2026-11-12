# EarthOnlineGuide P0 visual assets v2

Status: **PASS — Stage 1 accepted for design handoff**

Visual references were used only to restore the user-owned visual language; neither reference was cropped, extracted, or shipped as a production asset. Built-in `image_gen` initially emitted opaque RGB PNGs for the six transparent assets. Each was then non-destructively processed with the pre-existing local Pillow runtime: only edge-connected near-neutral light background pixels were made transparent, preserving the isolated deep-teal outlines and enclosed ivory panels.

| File | Intended use | Dimensions | Mode / alpha | Source and method | Version | Visual acceptance |
|---|---|---:|---|---|---|---|
| `earth-online-app-icon-v2.png` | iOS App Icon source | 1024×1024 | RGB / no alpha | Built-in `image_gen`; locally resized with `sips` | v2 | PASS — opaque, square, no rounded mask, original smiling globe / orbit direction |
| `earth-guide-mark-v2.png` | reusable globe mark | 1254×1254 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — real transparent corners, globe mark, no text or watermark |
| `core-task-card-frame-v2.png` | CoreTask dynamic-text frame | 1024×1536 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — transparent exterior, ivory reading panel, travel decoration stays in border |
| `egg-task-card-frame-v2.png` | EggTask dynamic-text frame | 1024×1536 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — transparent exterior, mystery route / stars / small globe; no envelope or letter-paper motif |
| `airplane-sticker-v2.png` | airplane sticker | 1239×1270 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — isolated plane, transparent corners, no text or watermark |
| `camera-sticker-v2.png` | camera sticker | 1402×1122 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — isolated camera, transparent corners, no text or watermark |
| `suitcase-sticker-v2.png` | suitcase sticker | 1254×1254 | RGB / alpha yes | Built-in `image_gen`; local edge-connected background removal | v2 | PASS — isolated suitcase, transparent corners, no text or watermark |

## Licence boundary

These are new, original generated production candidates for this app only. They inherit no right to any third-party game, map, character, UI, branded imagery, platform UI, font, watermark, or logo. The user-owned references define only the approved visual direction. No text is baked into reusable assets, so bilingual runtime text remains possible.

## Validation method

`sips` verified PNG format, RGB colour space, exact App Icon dimensions, and Alpha metadata. Pillow then confirmed all six transparent files have zero-alpha pixels at all four outer corners. Visual inspection verified no checkerboard is baked into the pixels, no visible text/watermark/platform UI, no obvious white fringe around the deep-teal outlines, and distinct CoreTask vs EggTask visual language.

## Stage 2 design-review pages

| File | Purpose | Dimensions | Acceptance |
|---|---|---:|---|
| `history-page-visual-v2.png` | Superseded History-page mockup | 853×1844 | **REJECTED / deprecated** — it incorrectly presented the product as a destination-travel record: fabricated destinations, countries/locations, landscape photos, and exploration/culture/history/nature categories. It is retained only as a rejected audit artifact and is not a current candidate. |
| `settings-page-visual-v2.png` | Previous Settings-page mockup | 853×1844 | CONDITIONAL PASS / superseded — visual direction was retained, but the unnecessary English subtitle and missing local-only ID explanation were corrected in v3. |
| `history-page-visual-v3.png` | Previous History-page mockup, design review only | 864×1821 | CONDITIONAL PASS / superseded — history semantics were accepted, but the first task was shortened to `拖延很久的事`; v4 makes it the complete task sentence `完成一件拖延很久的事`. |
| `settings-page-visual-v3.png` | Previous Settings-page mockup, design review only | 864×1821 | CONDITIONAL PASS / superseded — visual direction was accepted, but its `刷新时间 / 当地 05:00` row had a right chevron that incorrectly implied the fixed refresh boundary could be edited. |
| `history-page-visual-v4.png` | Previous History-page mockup, design review only | 864×1821 | superseded — v5 adds the user-confirmed current-date label and replaces task-specific row art with reusable generic icon categories. |
| `settings-page-visual-v4.png` | Previous Settings-page mockup, design review only | 864×1821 | superseded — v5 applies the confirmed single `向导ID`, Earth avatar, language option, About consolidation, and removes the clear-all-data entry. |
| `history-page-visual-v5.png` | Previous History-page mockup, design review only | 853×1844 | superseded — the confirmed reusable generic category icons were retained, but task-type badges were inadvertently omitted. |
| `settings-page-visual-v5.png` | Previous Settings-page mockup, design review only | 853×1844 | superseded — product structure remains accepted, but the visible text/digits/punctuation were not consistently rendered in the required pixel-font visual language. |
| `generic-task-icons-v1.png` | Eight reusable generic task-category icons, transparent PNG atlas | 1774×887 | **PASS — accepted for design handoff** — actual Alpha verified; 4×2 grid ordered as action, organizing, health, observation, record, outdoors, interaction, easter egg; no text, watermark, or platform UI. |
| `history-page-visual-v6.png` | Previous History-page mockup, design review only | 853×1844 | superseded — it showed each type badge twice, including an unwanted flag/egg immediately before every task title. |
| `history-page-visual-v7.png` | Previous History-page mockup, design review only | 853×1844 | superseded — product layout and semantics remain accepted, but the visible text/digits/punctuation were not consistently rendered in the required pixel-font visual language. |
| `core-task-type-badge-v1.png` | Reusable CoreTask type badge | 1254×1254 | **PASS — accepted for design handoff** — original minimal green pixel flag; real Alpha verified, no text or watermark. |
| `egg-task-type-badge-v1.png` | Reusable EggTask type badge | 1254×1254 | **PASS — accepted for design handoff** — original minimal gold pixel egg; real Alpha verified, no text or watermark. |
| `history-page-visual-v8.png` | Current History-page mockup, design review only, not a runnable App | 853×1844 | **PASS — accepted for design handoff** — page title, date label, filters, task titles, type labels, completion dates/times, and bottom navigation use one coordinated pixel-font visual language; no visible truncation, crowding, or duplicate type badge. |
| `settings-page-visual-v6.png` | Previous Settings-page mockup, design review only | 853×1844 | superseded — user authorized independent music and sound-effect settings and replaced refresh copy with static `5:00 AM`. |
| `settings-page-visual-v7.png` | Current Settings-page mockup, design review only, not a runnable App | 852×1846 | **PASS — accepted for design handoff** — independent `音乐` and `音效` ON switches; exact static no-arrow `5:00 AM`; unified pixel typography; Earth avatar, Guide ID, notification, language, About, and navigation accepted; no clear-data or standalone privacy/agreement entry. Switch states are visual examples only; audio functionality, audio assets, licences, SwiftUI integration, build, and real-device evidence remain unverified. |

## Visible text visual rule

All user-visible text, numbers, and punctuation in page visual drafts use a single coherent pixel-font visual system. This is a design-direction rule only: it does not select, license, embed, or prove a release font. Actual SwiftUI work must separately choose a license-traceable font covering `zh-Hans` / English / digits / punctuation, with fallback and Dynamic Type validation; no third-party game font may be copied.

**Acceptance boundary:** “PASS — accepted for design handoff” is visual/design-asset acceptance only. It does not demonstrate SwiftUI integration, an Xcode build, simulator behavior, or real-device acceptance.
