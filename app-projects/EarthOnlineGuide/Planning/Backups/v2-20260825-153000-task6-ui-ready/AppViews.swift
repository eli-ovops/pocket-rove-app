import SwiftUI
import SwiftData

enum AppTab: Hashable { case today, history, settings }

struct OnboardingView: View {
    let modelContext: ModelContext
    @State private var guideID = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image("earth-guide-mark-v2", bundle: .main).resizable().scaledToFit().frame(width: 96, height: 96).accessibilityHidden(true)
            Text("欢迎来到地球Online").font(FontToken.pageTitle)
            Text("请设置你的ID").font(FontToken.label)
            TextField("向导ID", text: $guideID).textFieldStyle(.roundedBorder).focused($isFocused).submitLabel(.done).accessibilityIdentifier("onboarding-guide-id")
            Button("开始探索", systemImage: "arrow.right") { createProfile() }
                .buttonStyle(.borderedProminent).font(FontToken.button).disabled(guideID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("onboarding-start")
        }.padding().onAppear { isFocused = true }
    }

    private func createProfile() {
        let profile = LocalProfile(guideID: guideID.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(profile); try? modelContext.save()
    }
}

struct AppShell: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var selected: AppTab = .today
    var body: some View {
        TabView(selection: $selected) {
            TodayView(profile: profile, modelContext: modelContext).tabItem { Label("今日", systemImage: "sun.max.fill") }.tag(AppTab.today).accessibilityIdentifier("tab-today")
            HistoryView(profile: profile).tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }.tag(AppTab.history).accessibilityIdentifier("tab-history")
            SettingsView(profile: profile, modelContext: modelContext).tabItem { Label("设置", systemImage: "gearshape.fill") }.tag(AppTab.settings).accessibilityIdentifier("tab-settings")
        }
    }
}

struct TodayView: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var plan: DailyPlan?; @State private var errorText: String?
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 16) {
                Text("今日任务").font(FontToken.pageTitle)
                Text("每天 5:00 AM 刷新").font(FontToken.label).foregroundStyle(.secondary)
                if let plan { ForEach(plan.instances) { instance in TaskRow(instance: instance, language: profile.languageCode) { toggle(instance) } } }
                else if errorText == nil { ContentUnavailableView("暂无可用任务", systemImage: "tray") }
                if let errorText { Text(errorText).foregroundStyle(.red) }
            }.padding() }
            .navigationTitle("地球Online").navigationBarTitleDisplayMode(.inline)
        }.task { load() }
    }
    private func load() { do { plan = try DailyTaskService(context: modelContext, profile: profile).today() } catch { errorText = "无法保存今日计划" } }
    private func toggle(_ instance: DailyInstance) { do { try DailyTaskService(context: modelContext, profile: profile).toggle(instance) } catch { errorText = "无法保存完成状态" } }
}

struct TaskRow: View {
    let instance: DailyInstance; let language: String; let action: () -> Void
    private var title: String { language == "en" && !instance.snapshotEn.isEmpty ? instance.snapshotEn : instance.snapshotZh }
    private var completed: Bool { instance.completion?.revokedAt == nil && instance.completion != nil }
    var body: some View {
        Button(action: action) { HStack(spacing: 12) {
            GenericTaskIconView(iconKey: instance.iconKey)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(FontToken.taskTitle).multilineTextAlignment(.leading)
                Text(instance.type == "egg" ? "彩蛋" : "核心任务").font(FontToken.label).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: completed ? "checkmark.circle.fill" : "circle").foregroundStyle(completed ? .green : .secondary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background { Image(instance.type == "egg" ? "egg-task-card-frame-v2" : "core-task-card-frame-v2", bundle: .main).resizable().scaledToFill().opacity(0.32) }
            .background(.teal.opacity(0.08)).clipShape(.rect(cornerRadius: 14)) }
        .buttonStyle(.plain).accessibilityLabel("\(title)，\(completed ? "已完成，双击撤销" : "进行中，双击完成")").accessibilityIdentifier("today-task-\(instance.instanceID)")
    }
}

struct HistoryView: View {
    let profile: LocalProfile; @State private var filter = "全部"
    @Query private var allInstances: [DailyInstance]
    private var entries: [DailyInstance] { allInstances.filter { item in
        item.plan?.profile?.persistentModelID == profile.persistentModelID && item.completion?.revokedAt == nil && item.completion != nil &&
        (filter == "全部" || (filter == "核心" ? item.type == "core" : item.type == "egg"))
    }.sorted { ($0.completion?.completedAt ?? .distantPast) > ($1.completion?.completedAt ?? .distantPast) } }
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 14) {
            Text(Date.now.formatted(date: .complete, time: .omitted)).font(FontToken.dateTime).foregroundStyle(.secondary).accessibilityIdentifier("history-today-date")
            Picker("筛选", selection: $filter) { Text("全部").tag("全部"); Text("核心").tag("核心"); Text("彩蛋").tag("彩蛋") }.pickerStyle(.segmented).accessibilityIdentifier("history-filter")
            if entries.isEmpty { ContentUnavailableView("暂无完成记录", systemImage: "clock") }
            else { ForEach(entries) { item in HistoryRow(item: item, language: profile.languageCode) } }
        }.padding() }.navigationTitle("历史") }
    }
}

private struct HistoryRow: View {
    let item: DailyInstance; let language: String
    private var title: String { language == "en" && !item.snapshotEn.isEmpty ? item.snapshotEn : item.snapshotZh }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GenericTaskIconView(iconKey: item.iconKey)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) { Text(title).font(FontToken.taskTitle).multilineTextAlignment(.leading); TaskTypeBadgeView(type: item.type) }
                Text(item.type == "egg" ? "彩蛋" : "核心任务").font(FontToken.label).foregroundStyle(.secondary)
                Text(item.completion?.completedAt.formatted(date: .numeric, time: .shortened) ?? "").font(FontToken.dateTime).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.teal.opacity(0.08)).clipShape(.rect(cornerRadius: 12))
            .accessibilityElement(children: .combine).accessibilityIdentifier("history-entry-\(item.instanceID)")
    }
}

struct SettingsView: View {
    let profile: LocalProfile; let modelContext: ModelContext
    @State private var notificationState: NotificationAuthorizationState = .notDetermined
    private let notifications = NotificationService()
    var body: some View {
        NavigationStack { List {
            Section {
                HStack(spacing: 12) { Image("earth-guide-mark-v2", bundle: .main).resizable().scaledToFit().frame(width: 48, height: 48).accessibilityHidden(true); LabeledContent("向导ID", value: profile.guideID).font(FontToken.label) }
                notificationRow
                Toggle("音乐", isOn: binding(\.musicEnabled)).accessibilityIdentifier("settings-music")
                Toggle("音效", isOn: binding(\.soundEffectsEnabled)).accessibilityIdentifier("settings-sound")
                Text("音频资源未随测试版提供；开关仅保存未来偏好。").font(FontToken.dateTime).foregroundStyle(.secondary)
                LabeledContent("每日刷新", value: "5:00 AM").font(FontToken.label)
            } header: { Text("地球Online小向导") }
            Section {
                Picker("语言", selection: binding(\.languageCode)) { Text("简体中文").tag("zh-Hans"); Text("English").tag("en") }.accessibilityIdentifier("settings-language")
                NavigationLink("关于我们") { AboutView() }
            }
        }.navigationTitle("设置").task { notificationState = await notifications.status() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in Task { notificationState = await notifications.status() } } }
    }
    @ViewBuilder private var notificationRow: some View { switch notificationState {
    case .notDetermined: Button("开启通知") { Task { await notifications.requestAndSchedule(languageCode: profile.languageCode); notificationState = await notifications.status() } }
    case .authorized, .provisional: LabeledContent("通知", value: "已开启")
    case .denied: Button("通知已拒绝：打开系统设置") { notifications.openSettings() }
    } }
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<LocalProfile, T>) -> Binding<T> { Binding(get: { profile[keyPath: keyPath] }, set: { profile[keyPath: keyPath] = $0; try? modelContext.save() }) }
}

struct AboutView: View {
    var body: some View { List {
        Section("关于我们") { Text("地球Online小向导是仅在本机运行的每日任务向导。"); Text("版本 0.1（开发验证）") }
        Section("测试版限制") { Text("英文内容、嵌入字体、音乐与音效播放、真机与发布验证仍未完成。") }
    }.navigationTitle("关于我们") }
}
