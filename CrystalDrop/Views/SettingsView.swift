import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 7
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @AppStorage("fontSizeLarge") private var fontSizeLarge = false

    @Environment(\.dismiss) private var dismiss

    private let notificationService = NotificationService()

    @State private var notificationTime = Calendar.current.date(
        bySettingHour: 7, minute: 0, second: 0, of: Date()
    )!

    var body: some View {
        NavigationStack {
            List {
                // MARK: 通知セクション
                Section {
                    Toggle(isOn: $notificationEnabled) {
                        Label("毎朝の通知", systemImage: "bell.fill")
                            .font(.system(size: 18))
                    }
                    .onChange(of: notificationEnabled) { _, enabled in
                        if enabled {
                            scheduleNotification()
                        } else {
                            notificationService.cancelDaily()
                        }
                    }
                    .tint(Color.appAccent)

                    if notificationEnabled {
                        DatePicker(
                            "通知する時刻",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(size: 18))
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .onChange(of: notificationTime) { _, time in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                            notificationHour = components.hour ?? 7
                            notificationMinute = components.minute ?? 0
                            scheduleNotification()
                        }
                    }
                } header: {
                    Text("通知")
                        .font(.system(size: 14, weight: .semibold))
                }

                // MARK: 表示セクション
                Section {
                    HStack {
                        Label("文字の大きさ", systemImage: "textformat.size")
                            .font(.system(size: 18))
                        Spacer()
                        Picker("", selection: $fontSizeLarge) {
                            Text("標準").tag(false)
                            Text("大").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                } header: {
                    Text("表示")
                        .font(.system(size: 14, weight: .semibold))
                }

                // MARK: 情報セクション
                Section {
                    HStack {
                        Label("バージョン", systemImage: "info.circle")
                            .font(.system(size: 18))
                        Spacer()
                        Text(appVersion)
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("天気データ提供", systemImage: "cloud.sun")
                            .font(.system(size: 18))
                        Spacer()
                        Text("Open-Meteo")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("情報")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .font(.system(size: 18))
                    }
                }
            }
        }
        .onAppear {
            notificationTime = Calendar.current.date(
                bySettingHour: notificationHour,
                minute: notificationMinute,
                second: 0,
                of: Date()
            ) ?? notificationTime
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func scheduleNotification() {
        Task {
            let granted = await notificationService.requestAuthorization()
            if granted {
                notificationService.scheduleDaily(at: notificationHour, minute: notificationMinute)
            }
        }
    }
}

#Preview {
    SettingsView()
}
