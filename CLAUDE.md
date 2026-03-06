# CLAUDE.md - Metronome & BPM Tap

## 프로젝트 개요
메트로놈 및 BPM 탭 측정 앱. 정확한 비트 스케줄링, 탭 템포 측정, 진동 피드백을 제공하는 음악 도구.
- **패키지명**: `com.dangundad.metronometap`
- **퍼블리셔**: DangunDad
- **수익 모델**: 완전 무료 + AdMob 광고 (배너 + 전면 + 보상형)

## 기술 스택
- **Flutter** 3.x / Dart 3.8+
- **상태 관리**: GetX (`GetxController`, `.obs`, `Obx()`)
- **로컬 저장**: Hive_CE (키-값 저장, HiveType 모델 없음)
- **UI**: flutter_screenutil, flex_color_scheme (FlexScheme.redWine), google_fonts, lucide_icons_flutter
- **광고**: google_mobile_ads + AppLovin/Pangle/Unity 미디에이션
- **기타**: vibration, flutter_animate, firebase_core/analytics/crashlytics, in_app_purchase, in_app_review

## 개발 명령어
```bash
flutter pub get
flutter analyze
flutter run
```

## 아키텍처 (프로젝트 구조)
```
lib/
├── main.dart                          # 앱 진입점
├── hive_registrar.g.dart              # Hive 어댑터 등록 (스텁)
├── app/
│   ├── admob/                         # 광고 (배너/전면/보상형)
│   ├── bindings/app_binding.dart      # GetX 바인딩
│   ├── controllers/
│   │   ├── metronome_controller.dart  # 메트로놈 핵심 로직
│   │   ├── history_controller.dart    # 기록 관리
│   │   ├── home_controller.dart       # 홈 화면
│   │   ├── premium_controller.dart    # 프리미엄
│   │   ├── setting_controller.dart    # 설정
│   │   └── stats_controller.dart      # 통계
│   ├── pages/
│   │   ├── guide/guide_page.dart      # 가이드/도움말
│   │   ├── history/history_page.dart
│   │   ├── home/home_page.dart        # 메인 화면 (메트로놈 + 탭 템포)
│   │   ├── premium/
│   │   ├── settings/settings_page.dart
│   │   └── stats/stats_page.dart
│   ├── routes/
│   ├── services/
│   │   ├── activity_log_service.dart
│   │   ├── app_rating_service.dart
│   │   ├── hive_service.dart
│   │   └── purchase_service.dart
│   ├── theme/
│   │   ├── app_flex_theme.dart
│   │   └── app_theme.dart             # 추가 테마 설정
│   ├── translate/translate.dart
│   └── utils/app_constants.dart
```

## 메트로놈 핵심 로직
### BPM 범위
- 최소: 40 BPM (Largo)
- 최대: 280 BPM (Prestissimo)

### 템포 라벨
| BPM 범위 | 라벨 |
|----------|------|
| < 60 | Largo |
| 60-65 | Larghetto |
| 66-75 | Adagio |
| 76-107 | Andante |
| 108-119 | Moderato |
| 120-155 | Allegro |
| 156-175 | Vivace |
| 176-199 | Presto |
| 200+ | Prestissimo |

### 비트 스케줄링 (Drift-Free)
- 절대 시간 기반 스케줄링: `_nextBeatTime`을 wall-clock 기준으로 추적
- 각 비트 후 정확히 1 interval만큼 `_nextBeatTime`을 전진
- 이벤트 루프 지연이 발생해도 다음 간격을 보정하여 누적 드리프트 방지
- 인터벌 계산: `Duration(microseconds: (60000000 / bpm).round())`

### 박자 (Time Signature)
- 기본값: 4/4 박자
- 다운비트(beat 0): 강한 진동 (200ms)
- 일반 비트: 약한 진동 (100ms)
- `SystemSound.play(SystemSoundType.click)` 사운드 출력

### 탭 템포 (Tap BPM)
- 최근 8회 탭의 평균 간격으로 BPM 계산
- 3초간 탭이 없으면 히스토리 초기화
- `tapCount.value`로 현재 탭 횟수 표시

## 저장 데이터 (Hive 키-값)
| 키 | 타입 | 설명 |
|----|------|------|
| metro_bpm | int | 마지막 BPM |
| metro_time_sig | int | 박자 |
| metro_haptic | bool | 진동 활성화 |
| metro_sound | bool | 사운드 활성화 |

## 개발 가이드라인
- HiveType 모델이 없으므로 `hive_registrar.g.dart`는 스텁 파일
- BPM 변경 시 재생 중이면 `_rescheduleFromNow()`로 부드럽게 전환
- SettingController 등록 여부 확인 후 haptic/sound 설정 참조
- Timer 정리: `onClose()`에서 `_beatTimer`, `_tapResetTimer` 반드시 cancel
