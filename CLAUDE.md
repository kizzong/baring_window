# Baring Window - CLAUDE.md

## 프로젝트 개요
Flutter로 만든 개인 생산성 앱 (iOS/Android). D-Day 트래킹, 할 일/루틴 관리, 통계 분석, 홈 위젯을 제공한다.

앱 이름: **바링 윈도우** | 패키지명: `baring_windows` | 버전: 1.1.12+14

## 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점, 라이프사이클 관리
├── theme/
│   └── app_colors.dart        # 다크/라이트 테마 색상
├── pages/
│   ├── home_page.dart         # 홈 (D-Day + 달성률 요약)
│   ├── todo_page.dart         # 할 일/루틴 (달력 + 바텀시트)
│   ├── analysis_page.dart     # 통계 분석 (월별 전환 애니메이션)
│   ├── profile_page.dart      # 프로필 (이름, 사진, 설정)
│   ├── dday_settings_page.dart
│   ├── notification_settings_page.dart
│   └── permission_settings_page.dart
├── services/
│   ├── widget_service.dart    # 홈 위젯 데이터 동기화
│   └── notification_service.dart  # 로컬 알림
└── onboarding/                # 온보딩 페이지들
```

## 주요 패키지 및 역할

| 패키지 | 역할 |
|--------|------|
| `hive` / `hive_flutter` | 로컬 데이터 저장 (단일 박스: `baring`) |
| `home_widget: ^0.9.0` | iOS/Android 홈 위젯 데이터 공유 |
| `flutter_local_notifications` | 할 일/루틴 알림 |
| `table_calendar` | 할 일 페이지 달력 |
| `device_calendar` | 캘린더 연동 |
| `image_picker` / `image_cropper` | 프로필 사진 |

## 데이터 구조 (Hive `baring` 박스)

- `todos`: `Map<String, List<Map>>` — 날짜(yyyy-MM-dd) → 할 일 목록
- `routines`: `List<Map>` — 루틴 목록 (type: 'daily'/'weekly', completions: Map)
- `eventCard`: `Map` — D-Day 이벤트 정보
- `lastAppOpen`: ISO8601 문자열
- `isDarkMode`: bool
- `userName`, `profileImagePath`: 프로필

## 홈 위젯 (home_widget)

**중요**: iOS에서 `setAppGroupId`는 반드시 `registerInteractivityCallback` **이전**에 호출해야 한다.

- iOS App Group ID: `group.baringWidget`
- iOS 위젯: `BaringWidget`, `BaringSmallWidget`, `TodoWidget`
- Android 위젯: `HomeWidgetProvider`, `SmallHomeWidgetProvider`, `TodoWidgetProvider`
- 백그라운드 콜백: `widgetInteractivityCallback` (`@pragma("vm:entry-point")`)
- 위젯 탭 → pending 토글 저장 → 앱 복귀 시 `processPendingToggles()`로 Hive 반영

## 앱 초기화 순서 (main.dart)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Hive.initFlutter()` + `openBox('baring')`
3. **iOS App Group 설정** (`setAppGroupId`) ← 반드시 먼저
4. `registerInteractivityCallback`
5. `runApp(MyApp())`
6. `initState` → `processPendingToggles` → `saveLastAppOpen` → `updateWidget` → `syncWidget`

## 테마

- 전역 다크모드: `isDarkMode` (ValueNotifier, main.dart에 선언)
- 색상 접근: `context.colors` (AppColors extension)
- 기본값: 다크모드

## 개발 규칙

- 모든 데이터는 `Hive.box('baring')` 단일 박스 사용
- 위젯 관련 작업은 반드시 `WidgetService`를 통해 처리
- iOS 전용 코드는 `Platform.isIOS` 조건 확인
- 타임존: `Asia/Seoul` 고정
