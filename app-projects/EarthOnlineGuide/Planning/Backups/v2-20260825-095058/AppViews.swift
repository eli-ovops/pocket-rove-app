import SwiftUI
import SwiftData

enum AppTab: Hashable { case today, history, settings }

struct OnboardingView: View {
    let modelContext: ModelContext
    @State private var guideID = ""
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe.asia.australia.fill").font(.largeTitle).foregroundStyle(.teal).accessibilityHidden(true)
            Text("欢迎来到地球Online").font(.largeTitle).bold()
            Text("请设置你的ID").font(.headline)
            TextField("向导ID", text: $guideID).textFieldStyle(.roundedBorder).focused($isFocused).submitLabel(.done)
            Button("开始探索", systemImage: "arrow.right") { createProfile() }.buttonStyle(.borderedProminent).disabled(guideID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.padding().onAppear { isFocused = true }
    }
    private func createProfile() { let profile = LocalProfile(guideID: guideID.trimmingCharacters(in: .whitespacesAndNewlines)); modelContext.insert(profile); try? modelContext.save() }
}

struct AppShell: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var selected: AppTab = .today
    var body: some View {
        TabView(selection: $selected) {
            TodayView(profile: profile, modelContext: modelContext).tabItem { Label("今日", systemImage: "sun.max.fill") }.tag(AppTab.today)
            HistoryView(profile: profile).tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }.tag(AppTab.history)
            SettingsView(profile: profile, modelContext: modelContext).tabItem { Label("设置", systemImage: "gearshape.fill") }.tag(AppTab.settings)
        }
    }
}

struct TodayView: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var plan: DailyPlan?; @State private var errorText: String?
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 16) {
                Text("今日任务").font(.largeTitle).bold(); Text("每天 5:00 AM 刷新").foregroundStyle(.secondary)
                if let plan { ForEach(plan.instances) { instance in TaskRow(instance: instance, language: profile.languageCode) { toggle(instance) } } }
                if let errorText { Text(errorText).foregroundStyle(.red) }
            }.padding() }.navigationTitle("地球Online").navigationBarTitleDisplayMode(.inline)
        }.task { load() }
    }
    private func load() { do { plan = try DailyTaskService(context: modelContext, profile: profile).today() } catch { errorText = "无法保存今日计划" } }
    private func toggle(_ instance: DailyInstance) { do { try DailyTaskService(context: modelContext, profile: profile).toggle(instance) } catch { errorText = "无法保存完成状态" } }
}

struct TaskRow: View {
    let instance: DailyInstance; let language: String; let action: () -> Void
    private var title: String { language == "en" ? instance.snapshotEn : instance.snapshotZh }
    private var completed: Bool { instance.completion?.revokedAt == nil && instance.completion != nil }
    var body: some View {
        Button(action: action) { HStack(spacing: 12) { Image(systemName: completed ? "checkmark.circle.fill" : "circle").foregroundStyle(completed ? .green : .secondary); VStack(alignment: .leading) { Text(title).font(.body); Text(instance.type == "egg" ? "彩蛋" : "核心任务").font(.caption).foregroundStyle(.secondary) }; Spacer() } .padding().frame(maxWidth: .infinity, alignment: .leading).background(.teal.opacity(0.08)).clipShape(.rect(cornerRadius: 14)) }
            .buttonStyle(.plain).accessibilityLabel("\(title)，\(completed ? "已完成，双击撤销" : "进行中，双击完成")")
    }
}

struct HistoryView: View {
    let profile: LocalProfile; @State private var filter = "全部"
    @Query private var allInstances: [DailyInstance]
    private var entries: [DailyInstance] { allInstances.filter { item in
        item.plan?.profile?.persistentModelID == profile.persistentModelID &&
        item.completion?.revokedAt == nil && item.completion != nil &&
        (filter == "全部" || (filter == "核心" ? item.type == "core" : item.type == "egg"))
    }.sorted { ($0.completion?.completedAt ?? .distantPast) > ($1.completion?.completedAt ?? .distantPast) } }
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 14) { Picker("筛选", selection: $filter) { Text("全部").tag("全部"); Text("核心").tag("核心"); Text("彩蛋").tag("彩蛋") }.pickerStyle(.segmented); if entries.isEmpty { ContentUnavailableView("暂无完成记录", systemImage: "clock") } else { ForEach(entries) { item in VStack(alignment: .leading) { Text(profile.languageCode == "en" ? item.snapshotEn : item.snapshotZh).bold(); Text(item.completion?.completedAt.formatted(date: .abbreviated, time: .shortened) ?? "").font(.caption).foregroundStyle(.secondary) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.teal.opacity(0.08)).clipShape(.rect(cornerRadius: 12)) } } }.padding() }.navigationTitle("历史") } }
}

struct SettingsView: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var notificationState: NotificationAuthorizationState = .notDetermined
    private let notifications = NotificationService()
    var body: some View { NavigationStack { List { Section { LabeledContent("向导ID", value: profile.guideID); notificationRow; Toggle("音乐", isOn: binding(\.musicEnabled)); Toggle("音效", isOn: binding(\.soundEffectsEnabled)); LabeledContent("每日刷新", value: "5:00 AM") } header: { Label("地球Online小向导", systemImage: "globe.asia.australia.fill") }; Section { Picker("语言", selection: binding(\.languageCode)) { Text("简体中文").tag("zh-Hans"); Text("English").tag("en") }; NavigationLink("关于我们") { AboutView() } } }.navigationTitle("设置").task { notificationState = await notifications.status() }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in Task { notificationState = await notifications.status() } } } }
    @ViewBuilder private var notificationRow: some View { switch notificationState { case .notDetermined: Button("开启通知") { Task { await notifications.requestAndSchedule(); notificationState = await notifications.status() } }; case .authorized, .provisional: LabeledContent("通知", value: "已开启"); case .denied: Button("通知已拒绝：打开系统设置") { notifications.openSettings() } } }
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<LocalProfile, T>) -> Binding<T> { Binding(get: { profile[keyPath: keyPath] }, set: { profile[keyPath: keyPath] = $0; try? modelContext.save() }) }
}

struct AboutView: View { var body: some View { List { Section("关于我们") { Text("地球Online小向导是仅在本机运行的每日任务向导。") }; Section("法律与版本") { Text("隐私政策：本 MVP 不收集账号或云端数据。"); Text("用户协议：任务完成由用户在 App 内自行确认。"); Text("版本 0.1（开发验证）") }; Section("音频发布状态") { Text("BLOCKED：尚无音频文件、许可或播放证据。") } }.navigationTitle("关于我们") } }
