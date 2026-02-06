import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    // Keys must match Dart side
    let keyShlokaText = "shloka_text"
    let keyTranslation = "translation"
    let keyChapterShloka = "chapter_shloka"
    let keySpeaker = "speaker"
    let keyHeader = "header_text" // New key
    
    // Suite Name must match the App Group ID if using App Groups for sharing data.
    let appGroupId = "group.org.komal.bhagvadgeeta"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), shlokaText: "Loading...", translation: "Gita Wisdom", footer: "Chapter X", header: "DAILY GITA WISDOM")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), shlokaText: "Dharma Kshetre...", translation: "Field of Righteousness", footer: "Chapter 1, Shloka 1", header: "DAILY GITA WISDOM")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        let userDefaults = UserDefaults(suiteName: appGroupId)
        let shlokaText = userDefaults?.string(forKey: keyShlokaText) ?? "Open App to see Daily Shloka"
        let translation = userDefaults?.string(forKey: keyTranslation) ?? "Daily Wisdom"
        let footer = userDefaults?.string(forKey: keyChapterShloka) ?? ""
        let header = userDefaults?.string(forKey: keyHeader) ?? "DAILY GITA WISDOM" // Read header
        
        // Refresh every hour or when app updates
        let entry = SimpleEntry(
            date: currentDate,
            shlokaText: shlokaText,
            translation: translation,
            footer: footer,
            header: header
        )
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let shlokaText: String
    let translation: String
    let footer: String
    let header: String // Added header property
}

struct DailyShlokaWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(alignment: .center, spacing: 0) {
                content
            }
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            ZStack {
                Color(.systemBackground)
                VStack(alignment: .center, spacing: 0) {
                    content
                }
            }
        }
    }
    
    var content: some View {
        Group {
            // Title
            Text(entry.header) // Use dynamic header
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.pink)
                .padding(.top, 12)
            
            Spacer()
            
            // Shloka Text
            Text(entry.shlokaText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.primary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
            
            Spacer()
            
            // Footer
            Text(entry.footer)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.pink)
                .padding(.bottom, 12)
        }
    }
}

@main
struct DailyShlokaWidget: Widget {
    let kind: String = "DailyShlokaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyShlokaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Shloka")
        .description("View your daily wisdom from the Bhagavad Gita.")
        .supportedFamilies([.systemMedium])
    }
}

// Extension to use Hex colors if needed or just use standard colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
