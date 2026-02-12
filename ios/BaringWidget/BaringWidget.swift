// //
// //  BaringWidget.swift
// //  BaringWidget
// //
// //  Created by 김지홍 on 1/28/26.
// //

// import WidgetKit
// import SwiftUI

// struct Provider: TimelineProvider {
//     func placeholder(in context: Context) -> SimpleEntry {
//         SimpleEntry(date: Date(), emoji: "😀")
//     }

//     func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//         let entry = SimpleEntry(date: Date(), emoji: "😀")
//         completion(entry)
//     }

//     func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//         var entries: [SimpleEntry] = []

//         // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//         let currentDate = Date()
//         for hourOffset in 0 ..< 5 {
//             let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//             let entry = SimpleEntry(date: entryDate, emoji: "😀")
//             entries.append(entry)
//         }

//         let timeline = Timeline(entries: entries, policy: .atEnd)
//         completion(timeline)
//     }

// //    func relevances() async -> WidgetRelevances<Void> {
// //        // Generate a list containing the contexts this widget is relevant in.
// //    }
// }

// struct SimpleEntry: TimelineEntry {
//     let date: Date
//     let emoji: String
// }

// struct BaringWidgetEntryView : View {
//     var entry: Provider.Entry

//     var body: some View {
//         VStack {
//             Text("Time:")
//             Text(entry.date, style: .time)

//             Text("Emoji:")
//             Text(entry.emoji)
//         }
//     }
// }

// struct BaringWidget: Widget {
//     let kind: String = "BaringWidget"

//     var body: some WidgetConfiguration {
//         StaticConfiguration(kind: kind, provider: Provider()) { entry in
//             if #available(iOS 17.0, *) {
//                 BaringWidgetEntryView(entry: entry)
//                     .containerBackground(.fill.tertiary, for: .widget)
//             } else {
//                 BaringWidgetEntryView(entry: entry)
//                     .padding()
//                     .background()
//             }
//         }
//         .configurationDisplayName("My Widget")
//         .description("This is an example widget.")
//     }
// }

// #Preview(as: .systemSmall) {
//     BaringWidget()
// } timeline: {
//     SimpleEntry(date: .now, emoji: "😀")
//     SimpleEntry(date: .now, emoji: "🤩")
// }
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), 
                   title: "목표 설정",
                   dday: "D-0",
                   percent: "0%",
                   progress: 0.0,
                   startDate: "2024/01/01",
                   targetDate: "2024/12/31",
                   selectedPreset: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), 
                               title: "목표 설정",
                               dday: "D-0",
                               percent: "0%",
                               progress: 0.0,
                               startDate: "2024/01/01",
                               targetDate: "2024/12/31",
                               selectedPreset: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.baringWidget")
        
        let title = sharedDefaults?.string(forKey: "title_text") ?? "목표 설정"
        let dday = sharedDefaults?.string(forKey: "dday_text") ?? "D-0"
        let percent = sharedDefaults?.string(forKey: "percent_text") ?? "0%"
        let progressValue = sharedDefaults?.integer(forKey: "progress") ?? 0
        let startDate = sharedDefaults?.string(forKey: "start_date") ?? "2024/01/01"
        let targetDate = sharedDefaults?.string(forKey: "target_date") ?? "2024/12/31"
        let selectedPreset = sharedDefaults?.integer(forKey: "selected_preset") ?? 0
        
        let progress = Double(progressValue) / 100.0
        
        let entry = SimpleEntry(date: Date(),
                               title: title,
                               dday: dday,
                               percent: percent,
                               progress: progress,
                               startDate: startDate,
                               targetDate: targetDate,
                               selectedPreset: selectedPreset)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let dday: String
    let percent: String
    let progress: Double
    let startDate: String
    let targetDate: String
    let selectedPreset: Int
}

// 색상 프리셋 정의 (위젯 본체 + containerBackground 양쪽에서 사용)
func gradientColors(for preset: Int) -> [Color] {
    switch preset {
    case 0: return [Color(hex: "2D86FF"), Color(hex: "1B5CFF")]
    case 1: return [Color(hex: "0E2A68"), Color(hex: "245BFF")]
    case 2: return [Color(hex: "FF512F"), Color(hex: "DD2476")]
    case 3: return [Color(hex: "FF7EB3"), Color(hex: "FF758C")]
    case 4: return [Color(hex: "8A2BE2"), Color(hex: "FF3D8D")]
    case 5: return [Color(hex: "FF8A00"), Color(hex: "FF3D5A")]
    case 6: return [Color(hex: "FF9A5A"), Color(hex: "FF5E62")]
    case 7: return [Color(hex: "34D399"), Color(hex: "059669")]
    case 8: return [Color(hex: "2C2F4A"), Color(hex: "1A1C2C")]
    case 9: return [Color(hex: "1B2430"), Color(hex: "0F141B")]
    default: return [Color(hex: "2D86FF"), Color(hex: "1B5CFF")]
    }
}

struct BaringWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // 상단: 목표 뱃지
                HStack {
                    Text("목표")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(10)

                    Spacer()
                }
                .frame(height: 20)

                Spacer()
                    .frame(height: 10)

                // 중단: 제목과 D-Day
                HStack(alignment: .center, spacing: 6) {
                    Text(entry.title)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)

                    Spacer(minLength: 2)

                    Text(entry.dday)
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(height: geometry.size.height * 0.4)

                Spacer(minLength: 0)


                // 하단: 프로그레스
                VStack(alignment: .trailing, spacing: 4) {
                    // 퍼센트
                    Text(entry.percent)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(height: 12)

                    // 프로그레스 바
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.white.opacity(0.25))
                            .frame(height: 7)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.white)
                                .frame(width: geo.size.width * CGFloat(entry.progress), height: 7)
                        }
                        .frame(height: 7)
                    }
                    .frame(height: 7)

                    // 날짜
                    HStack(spacing: 0) {
                        Text(entry.startDate)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white)

                        Spacer()

                        Text(entry.targetDate)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white)
                    }
                    .frame(height: 12)
                }
                .frame(height: 44)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .widgetURL(URL(string: "baringapp://open"))
    }
}

struct BaringWidget: Widget {
    let kind: String = "BaringWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BaringWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors(for: entry.selectedPreset)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Baring D-Day")
        .description("목표까지 남은 날을 확인하세요")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()  // 이 줄 추가 ⭐ (iOS 17+)

    }
}

// Hex Color Extension
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
            (a, r, g, b) = (255, 0, 0, 0)
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

struct BaringWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BaringWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "전기기사",
                dday: "D-30",
                percent: "70%",
                progress: 0.7,
                startDate: "2024/01/01",
                targetDate: "2024/12/31",
                selectedPreset: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("기본 하늘")

            BaringWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "전기기사 자격증 취득",
                dday: "D-5",
                percent: "95%",
                progress: 0.95,
                startDate: "2024/01/01",
                targetDate: "2024/12/31",
                selectedPreset: 2
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("빨강")
        }
    }
}

// MARK: - 2x2 목표 위젯 (Small)

struct BaringSmallWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단: 목표 뱃지
            HStack {
                Text("목표")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)
                Spacer()
            }

            Spacer().frame(height: 8)

            // 제목
            Text(entry.title)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer().frame(height: 4)

            // D-Day
            Text(entry.dday)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 0)

            // 하단: 진행률 바 + 퍼센트 + 마감일
            VStack(alignment: .leading, spacing: 4) {
                // 퍼센트
                HStack {
                    Spacer()
                    Text(entry.percent)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }

                // 프로그레스 바
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 6)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.white)
                            .frame(width: geo.size.width * CGFloat(entry.progress), height: 6)
                    }
                    .frame(height: 6)
                }
                .frame(height: 6)

                // 마감일
                HStack {
                    Spacer()
                    Text(entry.targetDate)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .widgetURL(URL(string: "baringapp://open"))
    }
}

struct BaringSmallWidget: Widget {
    let kind: String = "BaringSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BaringSmallWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors(for: entry.selectedPreset)),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Baring 목표")
        .description("목표와 D-Day를 한눈에 확인하세요")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct BaringSmallWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BaringSmallWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "전기기사",
                dday: "D-30",
                percent: "70%",
                progress: 0.7,
                startDate: "2024/01/01",
                targetDate: "2024/12/31",
                selectedPreset: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("2x2 파랑")

            BaringSmallWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "토익 900",
                dday: "D-DAY",
                percent: "100%",
                progress: 1.0,
                startDate: "2024/01/01",
                targetDate: "2024/12/31",
                selectedPreset: 4
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("2x2 보라")
        }
    }
}

// MARK: - 할 일 위젯

struct WidgetItem: Identifiable {
    let id: Int
    let type: String   // "todo" or "routine"
    let title: String
}

struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), items: [
            WidgetItem(id: 0, type: "todo", title: "할 일 1"),
            WidgetItem(id: 1, type: "routine", title: "루틴 1"),
        ], count: 2, total: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: Date(), items: [
            WidgetItem(id: 0, type: "todo", title: "할 일 1"),
            WidgetItem(id: 1, type: "routine", title: "루틴 1"),
        ], count: 2, total: 3)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.baringWidget")
        let jsonStr = sharedDefaults?.string(forKey: "widget_items_json") ?? "[]"
        let count = sharedDefaults?.integer(forKey: "widget_items_count") ?? 0
        let total = sharedDefaults?.integer(forKey: "widget_items_total") ?? 0

        var items: [WidgetItem] = []
        if let data = jsonStr.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
            for (index, dict) in array.enumerated() {
                let type = dict["type"] ?? "todo"
                let title = dict["title"] ?? ""
                items.append(WidgetItem(id: index, type: type, title: title))
            }
        }

        let entry = TodoEntry(date: Date(), items: items, count: count, total: total)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
    let count: Int
    let total: Int
}

struct TodoWidgetEntryView: View {
    var entry: TodoProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단: 할 일 뱃지 + 개수
            HStack {
                Text("할 일")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(8)

                Spacer()

                if entry.total > 0 {
                    Text("\(entry.count)/\(entry.total)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer().frame(height: 8)

            if entry.items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("할 일을 모두\n완료했어요!")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                Spacer()
            } else {
                let maxItems = 7
                let hasMore = entry.items.count > maxItems
                let visibleItems = hasMore ? Array(entry.items.prefix(maxItems - 1)) : Array(entry.items.prefix(maxItems))

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(visibleItems) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.type == "routine" ? "arrow.trianglehead.2.clockwise" : "square")
                                .font(.system(size: 10))
                                .foregroundColor(item.type == "routine" ? Color(hex: "34D399") : .white.opacity(0.5))
                            Text(item.title)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    if hasMore {
                        Text("... 외 \(entry.items.count - visibleItems.count)개")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .widgetURL(URL(string: "baringapp://open"))
    }
}

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: "1A2332")
                }
        }
        .configurationDisplayName("Baring 할 일")
        .description("오늘의 할 일과 루틴을 확인하세요")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct TodoWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TodoWidgetEntryView(entry: TodoEntry(
                date: Date(),
                items: [
                    WidgetItem(id: 0, type: "todo", title: "공부하기"),
                    WidgetItem(id: 1, type: "routine", title: "운동"),
                    WidgetItem(id: 2, type: "todo", title: "책 읽기"),
                ],
                count: 3,
                total: 5
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("할 일 + 루틴")

            TodoWidgetEntryView(entry: TodoEntry(
                date: Date(),
                items: [],
                count: 0,
                total: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("빈 상태")
        }
    }
}