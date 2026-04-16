import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), probability: 0, location: "東京")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), probability: 30, location: "東京")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 本来はここで実際の天気データをフェッチしますが、
        // 簡易化のため現在の時刻からタイムラインを作成します
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // サンプルとして1時間ごとのエントリを作成
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, probability: 10 * hourOffset, location: "現在地")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let probability: Int
    let location: String
}

struct CrystalDropWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.location)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(entry.probability)%")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            
            Text("最大降水確率")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.blue.gradient, for: .widget)
    }
}

struct CrystalDropWidget: Widget {
    let kind: String = "CrystalDropWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CrystalDropWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Rain Alert Widget")
        .description("現在の降水確率をチェックします。")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    CrystalDropWidget()
} displayName: {
    Provider.placeholder(in: .init(displaySize: .zero))
}
