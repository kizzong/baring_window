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