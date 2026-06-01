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
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                   title: "목표 설정",
                   dday: "D-0",
                   percent: "0%",
                   progress: 0.0,
                   startDate: "2024/01/01",
                   targetDate: "2024/12/31",
                   selectedPreset: 0,
                   widgetFace: "cheering2_face",
                   goals: [],
                   weatherEmoji: "⛅",
                   tempText: "--°")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(),
                               title: "목표 설정",
                               dday: "D-0",
                               percent: "0%",
                               progress: 0.0,
                               startDate: "2024/01/01",
                               targetDate: "2024/12/31",
                               selectedPreset: 0,
                               widgetFace: "cheering2_face",
                               goals: [],
                               weatherEmoji: "⛅",
                               tempText: "--°")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.baringWidget")

        let title = sharedDefaults?.string(forKey: "title_text") ?? "목표 설정"
        let startDateStr = sharedDefaults?.string(forKey: "start_date") ?? "2024/01/01"
        let targetDateStr = sharedDefaults?.string(forKey: "target_date") ?? "2024/12/31"
        let selectedPreset = sharedDefaults?.integer(forKey: "selected_preset") ?? 0

        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = Locale(identifier: "en_US_POSIX")

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // D-Day 및 진행률 계산
        var dday = "D-0"
        var percent = "0%"
        var progress = 0.0

        if let targetDate = df.date(from: targetDateStr) {
            let targetStart = cal.startOfDay(for: targetDate)
            let remaining = cal.dateComponents([.day], from: today, to: targetStart).day ?? 0
            if remaining > 0 { dday = "D-\(remaining)" }
            else if remaining == 0 { dday = "D-DAY" }
            else { dday = "완료" }

            if let startDate = df.date(from: startDateStr) {
                let startStart = cal.startOfDay(for: startDate)
                let totalDays = cal.dateComponents([.day], from: startStart, to: targetStart).day ?? 0
                if totalDays > 0 {
                    let passedDays = cal.dateComponents([.day], from: startStart, to: today).day ?? 0
                    progress = min(max(Double(passedDays) / Double(totalDays), 0.0), 1.0)
                    percent = "\(Int(progress * 100))%"
                } else {
                    progress = 1.0; percent = "100%"
                }
            }
        }

        // 위젯 표정 계산
        var widgetFace = "cheering2_face"
        if let lastAppOpenStr = sharedDefaults?.string(forKey: "last_app_open") {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var lastOpenDate = isoFormatter.date(from: lastAppOpenStr)
            if lastOpenDate == nil {
                isoFormatter.formatOptions = [.withInternetDateTime]
                lastOpenDate = isoFormatter.date(from: lastAppOpenStr)
            }
            if let lastOpen = lastOpenDate {
                let daysSince = cal.dateComponents([.day], from: lastOpen, to: Date()).day ?? 0
                widgetFace = daysSince >= 3 ? "disappointed_face" : "cheering2_face"
            }
        }

        // 전체 목표 파싱 (다중 목표 뷰용)
        var goals: [GoalInfo] = []
        if let allGoalsStr = sharedDefaults?.string(forKey: "all_goals_json"),
           let data = allGoalsStr.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for g in arr {
                let gTitle = g["title"] as? String ?? "목표 설정"
                let gStartStr = g["start_date"] as? String ?? "2024/01/01"
                let gTargetStr = g["target_date"] as? String ?? "2024/12/31"
                let gPreset = g["preset"] as? Int ?? 0
                var gDday = "D-0", gPercent = "0%", gProgress = 0.0
                if let gTarget = df.date(from: gTargetStr) {
                    let gTargetStart = cal.startOfDay(for: gTarget)
                    let rem = cal.dateComponents([.day], from: today, to: gTargetStart).day ?? 0
                    if rem > 0 { gDday = "D-\(rem)" }
                    else if rem == 0 { gDday = "D-DAY" }
                    else { gDday = "완료" }
                    if let gStart = df.date(from: gStartStr) {
                        let gStartDay = cal.startOfDay(for: gStart)
                        let total = cal.dateComponents([.day], from: gStartDay, to: gTargetStart).day ?? 0
                        if total > 0 {
                            let passed = cal.dateComponents([.day], from: gStartDay, to: today).day ?? 0
                            gProgress = min(max(Double(passed) / Double(total), 0.0), 1.0)
                            gPercent = "\(Int(gProgress * 100))%"
                        } else {
                            gProgress = 1.0; gPercent = "100%"
                        }
                    }
                }
                goals.append(GoalInfo(title: gTitle, dday: gDday, percent: gPercent, progress: gProgress, preset: gPreset))
            }
        }

        // 위치 (Flutter 앱이 저장한 좌표, 없으면 서울 기본값)
        let lat = sharedDefaults?.object(forKey: "widget_lat") as? Double ?? 37.5665
        let lon = sharedDefaults?.object(forKey: "widget_lon") as? Double ?? 126.9780

        // 날씨 API 호출 후 타임라인 완성 (1시간마다 갱신)
        fetchWeather(lat: lat, lon: lon) { emoji, temp in
            let entry = SimpleEntry(
                date: Date(),
                title: title,
                dday: dday,
                percent: percent,
                progress: progress,
                startDate: startDateStr,
                targetDate: targetDateStr,
                selectedPreset: selectedPreset,
                widgetFace: widgetFace,
                goals: goals,
                weatherEmoji: emoji,
                tempText: temp
            )
            let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        }
    }
}

func fetchWeather(lat: Double, lon: Double, completion: @escaping (String, String) -> Void) {
    let apiKey = "f81d936aa84b2051e2ec5b60090c8b4f"
    let urlStr = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
    guard let url = URL(string: urlStr) else { completion("", ""); return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let weatherArr = json["weather"] as? [[String: Any]],
              let mainDict = json["main"] as? [String: Any],
              let icon = weatherArr.first?["icon"] as? String,
              let temp = mainDict["temp"] as? Double else {
            completion("", ""); return
        }
        completion(iconToEmoji(icon), "\(Int(temp.rounded()))°")
    }.resume()
}

func iconToEmoji(_ icon: String) -> String {
    switch icon.prefix(2) {
    case "01": return "☀️"
    case "02": return "⛅"
    case "03", "04": return "☁️"
    case "09", "10": return "🌧️"
    case "11": return "⛈️"
    case "13": return "🌨️"
    case "50": return "🌫️"
    default: return "🌤️"
    }
}

struct GoalInfo {
    let title: String
    let dday: String
    let percent: String
    let progress: Double
    let preset: Int
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
    let widgetFace: String
    let goals: [GoalInfo]   // 전체 목표 (큰 위젯용)
    let weatherEmoji: String
    let tempText: String
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

    var dateText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일 (E)"
        return df.string(from: entry.date)
    }

    var body: some View {
        if entry.goals.count >= 2 {
            multiGoalView
        } else {
            singleGoalView
        }
    }

    // 목표 1개: 기존 상세 레이아웃
    var singleGoalView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(dateText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if !entry.weatherEmoji.isEmpty {
                    Text("\(entry.weatherEmoji) \(entry.tempText)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Spacer().frame(height: 4)
            HStack(alignment: .lastTextBaseline) {
                Text(entry.title)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.dday)
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(entry.widgetFace)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .opacity(0.8)
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                HStack { Spacer(); Text(entry.percent).font(.system(size: 13, weight: .black)).foregroundColor(.white) }
                Spacer().frame(height: 4)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999).fill(Color.white.opacity(0.25)).frame(height: 8)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 999).fill(Color.white)
                            .frame(width: geo.size.width * CGFloat(entry.progress), height: 8)
                    }.frame(height: 8)
                }.frame(height: 8)
                Spacer().frame(height: 8)
                HStack {
                    Text(entry.startDate).font(.system(size: 11)).foregroundColor(.white)
                    Spacer()
                    Text(entry.targetDate).font(.system(size: 11)).foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)
        .widgetURL(URL(string: "baringapp://open"))
    }

    // 목표 2~3개: 컴팩트 리스트 레이아웃
    var multiGoalView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(dateText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if !entry.weatherEmoji.isEmpty {
                    Text("\(entry.weatherEmoji) \(entry.tempText)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Spacer().frame(height: 8)
            ForEach(Array(entry.goals.enumerated()), id: \.offset) { idx, goal in
                if idx > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                }
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(goal.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 5)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * CGFloat(goal.progress), height: 5)
                            }.frame(height: 5)
                        }
                    }
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(goal.dday)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(goal.percent)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
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
                selectedPreset: 0,
                widgetFace: "cheering2_face",
                goals: [],
                weatherEmoji: "⛅",
                tempText: "18°"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("기본 하늘 (단일)")

            BaringWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                title: "전기기사",
                dday: "D-30",
                percent: "70%",
                progress: 0.7,
                startDate: "2024/01/01",
                targetDate: "2024/12/31",
                selectedPreset: 0,
                widgetFace: "cheering2_face",
                goals: [
                    GoalInfo(title: "전기기사", dday: "D-30", percent: "70%", progress: 0.7, preset: 0),
                    GoalInfo(title: "토익 900", dday: "D-5", percent: "95%", progress: 0.95, preset: 2),
                    GoalInfo(title: "헬스 루틴", dday: "D-100", percent: "20%", progress: 0.2, preset: 7),
                ],
                weatherEmoji: "⛅",
                tempText: "18°"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("다중 목표")
        }
    }
}

// MARK: - 2x2 목표 위젯 (Small)

struct BaringSmallWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단: 제목 + 응원 이미지
            HStack(alignment: .lastTextBaseline) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 4)

                Image(entry.widgetFace)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .opacity(0.8)
            }

            Spacer().frame(height: 2)

            // D-Day
            Text(entry.dday)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 0)

            // 하단: 퍼센트 + 프로그레스 바 + 마감일
            VStack(spacing: 0) {
                // 퍼센트 (오른쪽 정렬)
                HStack {
                    Spacer()
                    Text(entry.percent)
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 4)

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

                Spacer().frame(height: 6)

                // 마감일
                HStack {
                    Spacer()
                    Text(entry.targetDate)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
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
                selectedPreset: 0,
                widgetFace: "cheering2_face",
                goals: [],
                weatherEmoji: "⛅",
                tempText: "18°"
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
                selectedPreset: 4,
                widgetFace: "cheering2_face",
                goals: [],
                weatherEmoji: "⛅",
                tempText: "18°"
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
    let time: String?
    let routineId: String?
    let todoIndex: Int?
}

struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), items: [
            WidgetItem(id: 0, type: "todo", title: "할 일 1", time: "09:00", routineId: nil, todoIndex: 0),
            WidgetItem(id: 1, type: "routine", title: "루틴 1", time: nil, routineId: "0", todoIndex: nil),
        ], count: 2, total: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: Date(), items: [
            WidgetItem(id: 0, type: "todo", title: "할 일 1", time: "09:00", routineId: nil, todoIndex: 0),
            WidgetItem(id: 1, type: "routine", title: "루틴 1", time: nil, routineId: "0", todoIndex: nil),
        ], count: 2, total: 3)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.baringWidget")

        // ⭐ 전체 todos와 routines 데이터를 읽어서 현재 날짜 기준으로 필터링
        let allTodosJson = sharedDefaults?.string(forKey: "all_todos_json") ?? "{}"
        let allRoutinesJson = sharedDefaults?.string(forKey: "all_routines_json") ?? "[]"

        // 현재 날짜 계산
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // 1=일, 2=월, ..., 7=토
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // 1=월 ~ 7=일로 변환

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = dateFormatter.string(from: now)

        var items: [WidgetItem] = []
        var totalCount = 0

        // 1. 루틴 처리
        if let routinesData = allRoutinesJson.data(using: .utf8),
           let routinesArray = try? JSONSerialization.jsonObject(with: routinesData) as? [[String: Any]] {
            for routine in routinesArray {
                let routineType = routine["type"] as? String ?? ""
                var isForToday = false

                if routineType == "daily" {
                    isForToday = true
                } else if routineType == "weekly" {
                    if let days = routine["days"] as? [Int] {
                        isForToday = days.contains(adjustedWeekday)
                    }
                }

                if isForToday {
                    totalCount += 1
                    let completions = routine["completions"] as? [String: Bool] ?? [:]
                    if completions[todayKey] != true {
                        let title = routine["title"] as? String ?? ""
                        let routineId = "\(routine["id"] ?? "")"
                        items.append(WidgetItem(
                            id: items.count,
                            type: "routine",
                            title: title,
                            time: nil,
                            routineId: routineId,
                            todoIndex: nil
                        ))
                    }
                }
            }
        }

        // 2. 할 일 처리
        if let todosData = allTodosJson.data(using: .utf8),
           let todosDict = try? JSONSerialization.jsonObject(with: todosData) as? [String: Any],
           let todayTodos = todosDict[todayKey] as? [[String: Any]] {
            for (index, todo) in todayTodos.enumerated() {
                totalCount += 1
                let done = todo["done"] as? Bool ?? false
                if !done {
                    let title = todo["title"] as? String ?? ""
                    let time = todo["time"] as? String
                    items.append(WidgetItem(
                        id: items.count,
                        type: "todo",
                        title: title,
                        time: time,
                        routineId: nil,
                        todoIndex: index
                    ))
                }
            }
        }

        let entry = TodoEntry(date: now, items: items, count: items.count, total: totalCount)

        // ⭐ 다음 자정에 타임라인 갱신
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
    let count: Int
    let total: Int
}

// MARK: - 할 일 위젯 인터랙션 (iOS 17+)

@available(iOS 17.0, *)
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "할 일 완료"

    @Parameter(title: "Item Type")
    var itemType: String

    @Parameter(title: "Routine ID")
    var routineId: String?

    @Parameter(title: "Todo Index")
    var todoIndex: Int?

    init() {}

    init(itemType: String, routineId: String?, todoIndex: Int?) {
        self.itemType = itemType
        self.routineId = routineId
        self.todoIndex = todoIndex
    }

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: "group.baringWidget")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let todayKey = dateFormatter.string(from: Date())

        // 1. all_todos_json / all_routines_json 직접 업데이트
        //    TodoProvider.getTimeline()이 이 데이터를 기반으로 재생성하므로,
        //    여기를 수정해야 reloadTimelines 후 아이템이 즉시 사라진다.
        if itemType == "todo", let idx = todoIndex {
            let jsonStr = sharedDefaults?.string(forKey: "all_todos_json") ?? "{}"
            if let data = jsonStr.data(using: .utf8),
               var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               var todayTodos = dict[todayKey] as? [[String: Any]] {
                if idx < todayTodos.count {
                    todayTodos[idx]["done"] = true
                    dict[todayKey] = todayTodos
                    if let updatedData = try? JSONSerialization.data(withJSONObject: dict),
                       let updatedStr = String(data: updatedData, encoding: .utf8) {
                        sharedDefaults?.set(updatedStr, forKey: "all_todos_json")
                    }
                }
            }
        } else if itemType == "routine", let rid = routineId {
            let jsonStr = sharedDefaults?.string(forKey: "all_routines_json") ?? "[]"
            if let data = jsonStr.data(using: .utf8),
               var routines = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for i in 0..<routines.count {
                    let rId = "\(routines[i]["id"] ?? "")"
                    if rId == rid {
                        var completions = routines[i]["completions"] as? [String: Any] ?? [:]
                        completions[todayKey] = true
                        routines[i]["completions"] = completions
                        break
                    }
                }
                if let updatedData = try? JSONSerialization.data(withJSONObject: routines),
                   let updatedStr = String(data: updatedData, encoding: .utf8) {
                    sharedDefaults?.set(updatedStr, forKey: "all_routines_json")
                }
            }
        }

        // 2. pending_widget_toggles에 추가 (앱 복귀 시 Hive 동기화용)
        let pendingStr = sharedDefaults?.string(forKey: "pending_widget_toggles") ?? "[]"
        var pendingArray: [[String: Any]] = []
        if let pendingData = pendingStr.data(using: .utf8),
           let existing = try? JSONSerialization.jsonObject(with: pendingData) as? [[String: Any]] {
            pendingArray = existing
        }

        var toggleEntry: [String: Any] = ["type": itemType]
        if let rid = routineId { toggleEntry["routineId"] = rid }
        if let tidx = todoIndex { toggleEntry["todoIndex"] = tidx }
        pendingArray.append(toggleEntry)

        if let pendingData = try? JSONSerialization.data(withJSONObject: pendingArray),
           let pendingUpdatedStr = String(data: pendingData, encoding: .utf8) {
            sharedDefaults?.set(pendingUpdatedStr, forKey: "pending_widget_toggles")
        }

        // 3. 위젯 타임라인 갱신
        WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidget")

        return .result()
    }
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
                        todoItemRow(item: item)
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

    @ViewBuilder
    private func todoItemRow(item: WidgetItem) -> some View {
        let itemContent = HStack(alignment: .top, spacing: 6) {
            Image(systemName: "square")
                .font(.system(size: 10))
                .foregroundColor(item.type == "routine" ? Color(hex: "34D399") : .white.opacity(0.5))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let time = item.time, !time.isEmpty {
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }

        if #available(iOS 17, *) {
            Button(intent: ToggleTodoIntent(
                itemType: item.type,
                routineId: item.routineId,
                todoIndex: item.todoIndex
            )) {
                itemContent
            }
            .buttonStyle(.plain)
        } else {
            itemContent
        }
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
                    WidgetItem(id: 0, type: "todo", title: "공부하기", time: "09:00", routineId: nil, todoIndex: 0),
                    WidgetItem(id: 1, type: "routine", title: "운동", time: nil, routineId: "1", todoIndex: nil),
                    WidgetItem(id: 2, type: "todo", title: "책 읽기", time: "14:30", routineId: nil, todoIndex: 1),
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
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("빈 상태")
        }
    }
}