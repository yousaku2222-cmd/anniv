import WidgetKit
import SwiftUI

// Must match AppHomeWidgetService.appGroupId (lib/features/widget/data/…) and
// the App Group capability on both the Runner and AnnivWidget targets.
private let appGroupId = "group.com.annivapp.anniv"

// Anniv brand (lib/core/theme/app_tokens.dart): vermilion "朱色".
private let annivBrand = Color(red: 0xE8 / 255, green: 0x5D / 255, blue: 0x43 / 255)
private let annivCream = Color(red: 0xFB / 255, green: 0xF7 / 255, blue: 0xF0 / 255)

// MARK: - Entry

struct AnnivEntry: TimelineEntry {
    let date: Date
    let isEmpty: Bool
    let title: String
    let count: String
    let unit: String
    let caption: String

    static let placeholder = AnnivEntry(
        date: Date(),
        isEmpty: false,
        title: "ママの誕生日",
        count: "12",
        unit: "日",
        caption: "9月3日 まで"
    )
}

// MARK: - Provider

struct AnnivProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnnivEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (AnnivEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnnivEntry>) -> Void) {
        let entry = readEntry()
        // Refresh just after the next local midnight so "あと N 日" stays honest
        // even when the app isn't opened.
        let cal = Calendar.current
        let nextMidnight = cal.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func readEntry() -> AnnivEntry {
        let store = UserDefaults(suiteName: appGroupId)
        let hasData = store?.object(forKey: "anniv_title") != nil
        let flaggedEmpty = store?.bool(forKey: "anniv_empty") ?? true
        return AnnivEntry(
            date: Date(),
            isEmpty: !hasData || flaggedEmpty,
            title: store?.string(forKey: "anniv_title") ?? "記念日を追加",
            count: store?.string(forKey: "anniv_count") ?? "—",
            unit: store?.string(forKey: "anniv_unit") ?? "",
            caption: store?.string(forKey: "anniv_caption") ?? "Anniv を開いて登録"
        )
    }
}

// MARK: - View

struct AnnivWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: AnnivEntry

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetBackground(annivCream)
    }

    @ViewBuilder
    private var content: some View {
        if entry.isEmpty {
            emptyState
        } else {
            switch family {
            case .systemSmall: smallLayout
            default: mediumLayout
            }
        }
    }

    private var brandMark: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(annivBrand)
            .frame(width: 22, height: 22)
            .overlay(
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var bigNumber: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(entry.count)
                .font(.system(size: family == .systemSmall ? 44 : 52,
                              weight: .heavy, design: .rounded))
                .foregroundColor(annivBrand)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            if !entry.unit.isEmpty {
                Text(entry.unit)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                brandMark
                Text("Anniv")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.primary.opacity(0.7))
            }
            Spacer(minLength: 0)
            bigNumber
            Text(entry.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(entry.caption)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(14)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    brandMark
                    Text("Anniv")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.primary.opacity(0.7))
                }
                Spacer(minLength: 0)
                Text(entry.title)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(entry.caption)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                bigNumber
                Text("COUNTDOWN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                brandMark
                Text("Anniv")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.primary.opacity(0.7))
            }
            Spacer(minLength: 0)
            Text(entry.title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(.primary)
            Text(entry.caption)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
}

// iOS 17 wants `containerBackground`; earlier versions take a plain background.
private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}

// MARK: - Widget

struct AnnivWidget: Widget {
    let kind = "AnnivWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnnivProvider()) { entry in
            AnnivWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("次の記念日")
        .description("次に来る記念日までの残り日数を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    AnnivWidget()
} timeline: {
    AnnivEntry.placeholder
    AnnivEntry(date: Date(), isEmpty: false, title: "沖縄旅行", count: "当日", unit: "", caption: "12月30日")
    AnnivEntry(date: Date(), isEmpty: true, title: "記念日を追加", count: "—", unit: "", caption: "Anniv を開いて登録")
}
