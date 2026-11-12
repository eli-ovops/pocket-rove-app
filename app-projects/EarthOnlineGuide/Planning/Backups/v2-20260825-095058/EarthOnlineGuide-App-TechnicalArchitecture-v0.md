# 地球Online小向导 App｜最小技术架构 v0

状态：**文档已冻结到可创建工程底座；工程创建未授权且仍为 NOT STARTED。**

权威上游：`PROJECT_CORE.md`、`EarthOnlineGuide-App-MinPRD-v0.md`、`EarthOnlineGuide-App-RiskRegister-v0.md`。如实现与产品规则冲突，以产品规则和用户最新确认优先，先更新文档再编码。

## 1. 环境、目标与边界

### 1.1 已确认

- 本机：Xcode 26.6（Build 17F113）、Swift 6.3.3。
- 部署目标：`iOS 17+`；iPhone 竖屏为首版正式验收范围。
- UI：SwiftUI；持久化：SwiftData；任务内容：App 内置本地任务包。
- 无账号、云同步、分析 SDK、远程内容、音频、商城、社区或复杂 AI。
- 开发阶段中文优先；正式发布前必须完成 `zh-Hans` / `en` 双语和字体放行。

### 1.2 工程证据状态

- Xcode 工程、源代码、Build、Test、Simulator、真机、TestFlight、用户证据：全部 `NOT STARTED`。
- 工具链版本 PASS 不等于项目 Build PASS。
- Focumi 的方法可以复用，历史证据不能复用。

### 1.3 本架构不设计

远程签名任务包、内容后台、账号、CloudKit、服务器、IAP、社交、Widget 写入、App Intents/Shortcuts 完成、锁屏内联完成、Reminders 写入和后台刷新驱动业务真值。允许保留领域枚举或内部端口，但不得进入 MVP UI、权限或完成路径。

## 2. 架构原则与依赖方向

采用轻量 Clean Architecture：业务规则独立于 SwiftUI、SwiftData 和 UserNotifications；外层适配器依赖内层领域，领域不得反向导入界面或平台框架。

```text
AppShell / Features
        ↓
Application：DailyTaskEngine / use cases
        ↓
TaskDomain：纯领域模型、值对象、规则、端口
        ↑
Adapters：SwiftData Persistence / Notifications / Localization / Assets
```

约束：

- `TaskDomain` 不依赖 SwiftUI、SwiftData、UserNotifications 或具体文件格式。
- `DailyTaskEngine` 只通过持久化、时钟、日历、随机摘要和通知端口协调外部能力。
- SwiftData 模型与 `ModelContext` 不跨 actor；跨并发边界只传稳定业务 ID 或 persistent identifier，并在目标上下文重新读取。
- UI 不直接写 SwiftData；所有勾选、撤销、跨日和重置均进入应用用例，以保证幂等和唯一真值。
- 业务正确性不依赖后台准点执行、通知投递或界面当前显示。

## 3. 最小模块

### 3.1 AppShell

负责应用组合、依赖注入、根导航、应用生命周期和前台 `reconcile`，包含四个首版 Feature：

| Feature | 职责 | 禁止承担 |
|---|---|---|
| `Onboarding` | 首次显示“欢迎来到地球Online / 请设置你的ID”；保存本地显示 ID；解释通知后由用户主动开启。 | 账号、密码、远程唯一 ID、登录。 |
| `Today` | 展示当前业务日 3 个核心任务及可能出现的 1 个彩蛋；勾选即完成，当日可撤销。 | 领取、跳过、换题、完成当天任务、通知内完成。 |
| `History` | 只查询未撤销的 Completion，并使用实例双语快照展示完成时间。 | 显示未完成、跳过或过期任务。 |
| `Settings` | 修改本地 ID、语言、查看通知权限状态、进入系统设置、二次确认清除本机数据。 | 用 Toggle 冒充系统通知权限、云恢复承诺。 |

### 3.2 TaskDomain

定义任务包、任务身份、DailyPlan、任务槽位、不可变快照、完成与撤销、内容许可和领域错误。特别、紧急、DLC 只保留 `TaskType` 值，不提供首版行为。

### 3.3 DailyTaskEngine

唯一协调以下写操作：

- 计算或恢复当前业务日与简化 EngineState；
- 选择并一次性创建完整 DailyPlan 及当日实例；
- 勾选完成与当日撤销；
- 前台跨日结算；
- 根据 DailyInstance 与未撤销 Completion 应用体验分散和 30 个业务日完成冷却；
- 请求通知适配器排程、取消或重排程；
- 清除本机数据时协调持久化与通知。

引擎必须串行处理状态变更。所有写操作具备稳定幂等键，并在成功后显式保存；不得依赖 SwiftData 不可预测的自动保存时机。

### 3.4 Persistence

SwiftData 是本机用户状态唯一持久化真值。适配器负责模型映射、显式保存、查询、迁移、完整性校验和恢复界面所需错误，不把 SwiftData 类型泄漏到领域层。

### 3.5 Notifications

只处理系统权限状态、提醒排程/取消/重排程和点击路由。通知点击只产生“打开 Today”意图，不携带完成、撤销或换题动作。

### 3.6 Localization

UI 固定文案由本地化资源管理；任务文案随 TaskPack 同时携带 `zh-Hans` 与 `en`。语言解析、回退和格式化不得参与随机种子。

### 3.7 DesignSystem

管理色彩、间距、圆角、图标、像素字体角色、系统字体回退、Dynamic Type、VoiceOver 标签、对比度、减少透明度/动态效果。生成资产无内嵌文字，保证双语复用。

## 4. 领域模型、唯一约束与关系

除用户显示 ID 外，所有唯一性依赖不可变的本地安装 ID；用户修改显示 ID 不得改变随机结果或数据键。TaskCard 的具体任务身份、文案修订和体验族必须分别使用 `canonicalTaskID`、`taskRevisionID`、`experienceFamilyKey`。

| 模型 | 关键字段 | 唯一键 | 关系与删除策略 |
|---|---|---|---|
| `LocalProfile` | `singletonKey, installID, displayID, preferredLanguage, createdAtUTC` | `singletonKey = local-profile`；`installID` 在首次成功设置显示 ID 时生成随机 UUID | 独立单例。installID 只保存于 SwiftData，升级/重启不变；修改显示 ID 不影响它；清除所有数据或卸载后重装会产生新 installID。不写入 Keychain、UserDefaults、账号或云端。 |
| `TaskPack` | `packKey, packID, contentVersion, formatVersion, selectionPolicyVersion, minimumAppVersion, supportedLocales, checksum, status` | `packKey = packID + contentVersion` | 一对多拥有 `TaskCard`，显式 inverse；状态为 imported / validated / active / retired。新包只影响未来 DailyPlan，旧包不得反向修改快照。 |
| `TaskCard` | `cardKey, canonicalTaskID, taskRevisionID, packKey, localizedContent, type, experienceFamilyKey, availability, safetyTags, assetKeys, releaseStatus` | `cardKey = packKey + canonicalTaskID + taskRevisionID` | 属于一个 TaskPack；不直接拥有 DailyInstance 或 Completion。运行时只持有 approved / blocked / retired 精简状态；完整审核状态在内容源与 Validator 清单。canonicalTaskID 跨包稳定，修订不得冒充新任务。 |
| `DailyPlan` | `planKey, installID, businessDayKey, businessDaySequence, timeZoneID, startAtUTC, refreshAtUTC, packKey, algorithmVersion, lifecycleState, expectedCoreCount, expectedEggCount, generatedAtUTC, firstPresentedAtUTC` | `planKey = installID + businessDaySequence` | 当天聚合根，一对多拥有 DailyInstance，显式 inverse；删除计划时 cascade 实例与 Completion。同一计划内实例必须完整且使用同一 packKey；本地日期/时区仅作冻结事实，不单独承担唯一性。 |
| `DailyInstance` | `instanceKey, planKey, slotKey, canonicalTaskID, taskRevisionID, packKey, taskTypeSnapshot, localizedSnapshot, experienceFamilySnapshot, lifecycleState, assignedAtUTC` | `instanceKey = planKey + slotKey` | 属于一个 DailyPlan；不依赖活 TaskCard，保存不可变 `TaskSnapshot`。一对零或一 Completion，显式 inverse，删除实例时 cascade Completion。 |
| `Completion` | `completionKey, instanceKey, canonicalTaskID, completedAtUTC, completedLocalText, revokedAtUTC, updatedAtUTC, lastMutationID` | `completionKey = instanceKey` | 完成事实唯一真值。`revokedAtUTC == nil` 才进入历史与 30 个业务日冷却；再次完成复用记录并更新为最近一次有效完成时间。 |
| `EngineState` | `singletonKey, currentPlanKey, lastBusinessDaySequence, lastReconcileAtUTC, latestClosedBoundaryUTC` | `singletonKey = engine-state` | 独立单例；阻止时钟回拨重新开放已关闭业务日，并帮助定位当前计划。清除所有数据时删除。 |
| `NotificationSchedule` | `scheduleKey, installID, businessDayKey, kind, notificationID, scheduledForUTC, state, authorizationSnapshot, updatedAtUTC` | `scheduleKey = installID + businessDayKey + kind` | 不关联 Completion，不代表系统实际投递。清除数据、关闭提醒或语言/时间规则变化时按稳定 notificationID 取消。 |
| `ContentAsset` | `assetKey, assetID, version, kind, ownerScope, licenseStatus, provenance, checksum, localPath, usageScope` | `assetKey = assetID + version` | 独立台账；TaskCard/DesignSystem 只引用 assetKey。许可未 verified 的资产不得进入发布配置。 |

### 4.1 DailyPlan、状态与历史

- `DailyPlan` 生命周期只需 `active / closed`；`DailyInstance` 生命周期只需 `active / closed / withdrawn`。
- 是否完成不写入 DailyInstance 生命周期；只由唯一 Completion 的 `revokedAtUTC` 判断，避免双真值。
- 勾选：创建或更新唯一 Completion，写入最近一次有效 `completedAtUTC`、清空 `revokedAtUTC`；实例仍为 active。
- 当日撤销：写入 `revokedAtUTC`；历史查询立即排除，任务从下一业务日起重新具有抽取资格。
- 到达下一次 `refreshAtUTC`：关闭 DailyPlan 和其实例。未完成项不创建 Completion、不进入历史；过去业务日 Completion 不再允许撤销。
- 严重安全或许可问题可把尚未结束的实例标为 withdrawn，不自动换题；已有历史仍读取快照。

### 4.2 保存与并发

- DailyPlan 与其全部实例先在内存完成选择和校验，再在同一串行上下文中一次显式保存；Today 不展示缺槽位或混合任务包的部分计划。
- `expectedCoreCount / expectedEggCount` 必须与实际实例和槽位一致；首次展示时写入 `firstPresentedAtUTC`。生成、验证或保存失败时不创建可见计划，也不切换 seed。
- 重试必须复用相同 `businessDaySequence + activePackKey + algorithmVersion + selectionDomain`。如果选择算法持续失败，Today 显示可恢复错误，不得调用未审内容。
- 启动发现不完整计划时：仅当 `firstPresentedAtUTC == nil` 且不存在 Completion，才可删除该可重建半成品并以同一种子重建；否则停止自动修复并进入恢复界面。
- 每次勾选、撤销、结算、重排程元数据和删除都显式保存。
- `DailyTaskEngine` 持有自己的串行持久化协调边界；SwiftData 模型实例和 ModelContext 不跨 actor。
- UI/通知只提交 `instanceKey`、`mutationID` 等值；引擎在自己的上下文重新读取并验证业务日与状态。
- `lastMutationID` 和唯一键共同保证重复点击、重试、恢复时不生成第二条 Completion。

### 4.3 删除策略

- 用户“清除所有数据”必须二次确认，随后在一个受控流程中取消本 App 待处理通知，并删除 LocalProfile、EngineState、DailyPlan/DailyInstance/Completion、NotificationSchedule 和可重建的导入 TaskPack/TaskCard。
- 删除 App 或清除数据后不可恢复，不支持跨设备；界面必须明确说明。
- 自动迁移、启动失败或校验失败不得触发清库。

### 4.4 迁移策略

- 从首版即声明显式 Schema v1 与 MigrationPlan；即使当前仅轻量迁移，也不得依赖隐式长期兼容。
- 数据库 schema 版本与 TaskPack 内容版本分离；升级内容包不等于迁移用户数据库。
- 新版本先注册新 schema，再执行可验证迁移；已生成 DailyInstance 的快照、Completion 时间和唯一键不得改变。
- 破坏性迁移必须另行设计、备份/恢复评估和用户授权，不属于 MVP。

### 4.5 数据损坏恢复

恢复顺序固定为：重新打开存储 → 校验 schema/唯一键/必要字段 → 尝试只读读取和可逆修复 → 进入恢复界面。不得静默删除数据库。

- 内置 TaskPack 可从 App Bundle 重新导入，但不能因此宣称用户历史可恢复。
- 无法恢复用户数据时，向用户说明本地数据风险；只有用户明确确认“重建本机数据”后才创建新存储。
- 能保留损坏现场时保留，供诊断使用；不得把“新库能打开”表述为旧数据已恢复。
- LocalProfile 缺失但仍存在 DailyPlan、Completion 或历史时，不得静默生成新 installID 并重绑旧数据；必须进入恢复界面。只有完整清除或确认为全新安装时才生成新 installID。

### 4.6 installID 生命周期

- 用户首次成功提交 2–16 字符本地显示 ID 时生成随机 UUID，并与 LocalProfile 一次显式保存。
- installID 不是账号、秘密或公开用户标识，不上传、不展示，也不进入用户文案。
- App 升级、重启、语言或显示 ID 变化均保持 installID 不变；“清除所有数据”删除 LocalProfile、EngineState 和所有用户状态，随后回到 Onboarding。
- 卸载后重装视为新的本地玩家并生成新 installID；首版不使用 Keychain 或 UserDefaults 让身份跨卸载保留。

## 5. 本地任务包与随机抽取

### 5.1 任务包验证与版本

- 首版仅加载随 App 发布、经过 `imported → validated → active` 放行、校验值匹配且时间有效的本地包；retired 包不再用于新计划。
- 内容源为每条任务记录 `contentStatus / safetyStatus / localizationStatus / licenseStatus`。开发档允许 approved + safety passed 的中文任务在英文待补状态下用于本地测试；发布档只接受 content approved、safety passed、localization release-ready、license verified。
- 每条进入运行时 TaskPack 的 TaskCard 必须具有稳定 canonicalTaskID、taskRevisionID、类型、双语内容、完成判定、安全标签、experienceFamilyKey 和精简 releaseStatus。
- TaskPack Validator 提供开发与发布两档；发布档必须拒绝重复身份、空文案、双语缺失、未审安全/许可、无效资源、格式或最低 App 版本不兼容、容量模拟失败和非确定性抽取。
- App 更新可携带新 TaskPack；远程签名、热更新和 A/B 延后。

### 5.2 稳定种子

使用稳定摘要算法产生随机流；不得使用跨进程不稳定的默认 Hash。种子输入按固定顺序组成：

`algorithmVersion + installID + businessDaySequence + activePackKey + selectionDomain`

其中 `selectionDomain` 分为 `core-order`、`egg-roll`、`egg-order`；语言、显示 ID、App 版本、当前打开次数和通知状态不得进入种子。

### 5.3 确定性抽取

1. 先按 `canonicalTaskID + taskRevisionID` 稳定排序候选。
2. 过滤非 approved、类型不符、时间无效、许可/安全不通过的卡片。
3. 查询最近 30 个业务日未撤销 Completion，按 canonicalTaskID 排除已完成任务；未完成任务不硬排除，从下一业务日起重新进入候选池。
4. 核心选择 3 个不同 canonicalTaskID，并优先保持不同 experienceFamilyKey；近期已展示的相似体验族只降低排序权重，不构成硬排除。槽位固定为 `core-0...2`。
5. 彩蛋独立使用 `egg-roll`；稳定随机结果落在 25% 区间时才选择 1 个 `egg-0`。
6. 创建完整 DailyPlan、DailyInstance 与双语 TaskSnapshot 后一次显式保存。再次 reconcile 先按 planKey 读取，完整计划存在即复用，绝不重抽。

### 5.4 任务池不足的安全降级

运行时降级不能突破任何硬约束，顺序固定：

1. 始终维持内容 approved、安全/许可、任务类型、明确时间与 availability、同日 canonicalTaskID 唯一及完成后 30 个业务日冷却。
2. 先放宽近期 experienceFamilyKey 软降权。
3. 再放宽同一 DailyPlan 内体验族分散，但仍不能出现相同 canonicalTaskID。
4. 核心仍不足 3 条时只展示可安全生成的数量，并显示中性“任务包暂不可用/不足”；不得调用未审、过期、时间不符、未授权或处于冷却期的内容。
5. 彩蛋候选不足时当日不显示彩蛋，不用核心任务替代；记录本地可诊断错误，不上传用户数据。

### 5.5 版本与语言不变性

- App 或任务包更新后，如果当前业务日已存在完整 DailyPlan，继续使用原 packKey、算法版本和快照；新包仅影响未来业务日。
- 切换语言从 DailyInstance 的双语快照选择展示，不重建实例、不改 seed、不改 Completion 或历史。
- 用户修改显示 ID 不改变 installID，不触发重抽。

## 6. 当地 `05:00` 业务日

### 6.1 定义

- 首次生成时使用设备当前时区。
- 业务日不是固定 24 小时：用该时区日历计算“当地 05:00 到下一当地 05:00”，并将边界同时保存为 UTC。
- `businessDayKey` 等价于“当前本地时间减去 5 小时后的日历日期”；用于稳定身份，不用于简单加 24 小时。

### 6.2 前台重算是真值

以下入口必须先调用同一个 reconcile：冷启动、回到前台、打开 Today、点击通知、勾选和撤销。reconcile 按持久化的当前实例与 `refreshAtUTC` 判断是否跨日；后台刷新和通知不得创建、完成或撤销任务。

### 6.3 时区变化

- 已生成业务日冻结 `timeZoneID` 与 `refreshAtUTC`；用户在当天切换时区不会重抽或改变旧实例。
- 当前冻结业务日结束后，下一业务日才采用设备届时的时区。
- 时区变化导致新时区当地 05:00 已经过时，也只在 reconcile 时生成当前业务日一次，不补生成中间不可见日期。

### 6.4 夏令时

下一边界必须由 Calendar 在对应时区求“下一当地 05:00”，不能使用 `now + 24h`。DST 的 23/25 小时日仍只对应一个业务日和一组实例。

### 6.5 手动修改系统时间

- 向后调整：不得重新打开已关闭业务日，不得删除未来已生成计划或回滚 Completion。通过简化 EngineState 持久化最新已关闭边界和单调业务日序列作为防回拨门。
- 向前调整：reconcile 关闭已跨过的当前业务日，只为现在所在业务日生成一次；不补建未打开期间的每日实例。
- 检测到时钟异常且无法安全判定时，保持现有实例只读并提示重新打开/恢复；不得通过重抽“修复”。

### 6.6 长时间未打开

下次启动时关闭旧 DailyPlan；保留未撤销的历史 Completion，未完成项不进历史；直接生成当前业务日，跳过中间日期，不虚构历史。

### 6.7 `05:00` 并发、勾选与重启

- 所有 reconcile、勾选与撤销由同一串行引擎协调。
- 写入前重新读取实例并比较当前 UTC 与其 `refreshAtUTC`；若已到边界，拒绝修改旧实例并先跨日。
- `04:59:59` 已成功显式保存的完成可进入历史；边界后未保存/重试的旧日操作不得补写。
- 重启后按 DailyPlan 唯一键、完整性校验和 EngineState 恢复，不根据界面缓存推断结果。

## 7. 本地通知

### 7.1 权限状态

- 首次启动不自动请求。用户看到说明并主动点击“开启提醒”后才调用系统授权。
- 必须处理：未决定、已授权、临时授权、已拒绝。
- 已拒绝后 App 不能再次弹系统授权，只能解释并提供“前往系统设置”。设置页不得使用可写 Toggle 表示系统权限。
- 拒绝、关闭或未决定都不阻断 Today、勾选、撤销与 History。

### 7.2 排程模型

- 提醒时间：设备当地 `09:00` 和 `20:00`。
- 使用稳定 notificationID，包含 installID、businessDayKey 与 kind；同一 scheduleKey 重试时先对账，再覆盖或取消，不能追加重复请求。
- 排程采用小范围滚动窗口，并在启动/前台、语言变化、权限变化和业务日转换后对账；NotificationSchedule 只记录“请求状态”，不证明系统实际投递。
- 当天 3 个核心任务都已完成时取消尚未触发的 `20:00`；当天撤销且仍早于 `20:00` 时幂等恢复该提醒。
- `09:00` 文案只表示“今日任务可查看”；`20:00` 只提醒仍有核心任务未完成。彩蛋不决定晚间提醒。
- MVP 不捆绑自定义音频；系统提示方式由系统权限与用户设置决定。

### 7.3 点击行为

通知点击只路由到 Today，随后由 AppShell 调用 reconcile。通知 payload 不包含完成、撤销、换题或写入动作；锁屏内联完成、Shortcut 完成和 Widget 写入均延后。

## 8. 双语、字体与视觉资产

### 8.1 本地化数据

- UI 固定文案使用稳定本地化 key，至少提供 `zh-Hans` 和 `en`。
- TaskCard 的标题、叙事、说明、完成反馈分别存储 `zh-Hans`/`en`；入包时两种语言均须通过字段完整性校验。
- DailyInstance 在生成时保存两种语言快照。历史随当前语言展示对应快照；缺失时按 `用户选择语言 → zh-Hans → 安全占位` 回退，并记录本地诊断错误。
- 日期、时间和数字使用当前语言区域格式化，但业务日身份和完成 UTC 不改变。

### 8.2 字体

- 开发像素中文字体必须有可追溯来源和允许内部开发嵌入的许可；不得因“仅开发”忽略许可。
- 发布前中文/英文字体都必须确认商业使用、App 嵌入、地域、期限和分发范围；许可 UNKNOWN 即阻断发布。
- 每个文字角色定义像素字体与系统字体回退。字体加载失败、缺字或辅助功能字号超出像素字体可用范围时自动使用系统字体。
- 使用可缩放文字样式；大字号允许换行和滚动，不以固定字号、截断或极端 minimum scale 维持像素版式。
- VoiceOver 必须读出任务类型、任务文本、完成状态和按钮动作；颜色不得成为唯一状态信号。正常文本对比度目标至少 4.5:1，大文本至少 3:1。

### 8.3 视觉资产台账

当前没有可直接复用的原始资产。每个重新生成/制作的地球、边框、飞机、相机、行李箱、贴纸和图标必须记录：assetKey、来源、生成提示或作者、生成/修改日期、修改说明、许可、校验值、版本、语言中立性和使用位置。

- 公开截图只作账号自有画风参考，不裁切为生产资产。
- 双语复用资产不得烘焙文字。
- 概念图不自动成为生产资产；需独立验收、导出和台账放行。

## 9. 工程底座创建范围

获得后续授权后，首个工程底座只应创建：

- AppShell 与四个空 Feature 边界；
- TaskDomain 的 DailyPlan、TaskSnapshot、任务身份、简化状态机、端口和错误边界；
- DailyTaskEngine 最小用例边界与 TaskPack Validator；
- SwiftData Schema v1 / MigrationPlan 和本地适配器；
- Notifications、Localization、DesignSystem 的最小适配器接口；
- 可注入 Clock、Calendar、TimeZone、稳定摘要与内存持久化替身，以支持无设备的领域测试。

不得顺带创建远程服务、账号、CloudKit、IAP、Widget、Shortcuts 完成、Reminders、CMS、分析 SDK 或第三方依赖。

## 10. 验收证据分层

| 证据层 | 当前状态 | 该层只能证明 |
|---|---|---|
| 环境 | **PASS** | Xcode 26.6（Build 17F113）、Swift 6.3.3 已核验。 |
| 代码 | **NOT STARTED** | 实现存在并接受静态审查；不能证明可构建。 |
| Build | **NOT STARTED** | 指定 scheme/configuration 编译成功；不能证明测试或运行正确。 |
| Test | **NOT STARTED** | 指定自动化用例通过；不能证明模拟器/真机平台行为。 |
| Simulator | **NOT STARTED** | 目标模拟器上的界面与本地流程；不能证明真机通知或系统时序。 |
| 真机 | **NOT STARTED** | 指定设备/iOS 上通知、生命周期、字体和恢复行为。 |
| 用户 | **NOT STARTED** | 真实用户可理解和复用；勾选仍只是自报，不能证明现实行为。 |

## 11. 首批最小 Spike

### 11.1 当地 `05:00` 跨日

- PASS：固定种子在重启/切换语言/升级后保持同日实例；正常日、DST、改时区、手动前后调时钟、长期未打开、边界并发和重启均不重抽、不回滚、不重复 Completion。
- FAIL：任一场景重抽、改写历史、重复完成，或必须依赖后台准点执行。
- 停止条件：FAIL 后停止通知、UI 和其他底座扩展，先修正 TaskDomain/DailyTaskEngine。

### 11.2 离线/重启恢复

- PASS：飞行模式下完成生成、勾选、撤销、历史、显式保存、强制退出和重启；唯一键无重复；损坏存储进入恢复界面，不静默清库。
- FAIL：数据丢失、重复实例/Completion、孤儿关系、撤销失效或自动重置。
- 停止条件：FAIL 后停止 TestFlight 和内容扩充。

### 11.3 本地通知真机

- PASS：用户主动触发授权；四种权限状态 UI 正确；`09:00`/`20:00` 排程、取消、重排程无重复；完成三项后取消晚间提醒，撤销后可恢复；点击只打开 Today；拒绝不阻断核心闭环。
- FAIL：重复/错误时间、权限误导、点击写任务状态、拒绝后不可用。
- 停止条件：FAIL 后隐藏 MVP 提醒入口，以纯前台离线闭环继续验证。

## 12. 文档放行结论

本规格使项目达到“**可创建工程底座**”，但不构成创建授权，也不构成代码、Build、Test、Simulator、真机、TestFlight 或用户 PASS。下一步必须等待用户明确授权后，才可创建 Xcode 工程；创建后先完成三项最小 Spike，再决定是否扩展 UI 和内容。
