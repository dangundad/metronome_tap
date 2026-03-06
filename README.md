# Metronome & BPM Tap

메트로놈 및 BPM 탭 측정 앱 - 정확한 비트 스케줄링과 탭 템포 측정 기능을 제공합니다.

## 주요 기능
- 40~280 BPM 슬라이더 조절
- 드리프트 없는 절대 시간 기반 비트 스케줄링
- 탭 템포 측정 (최근 8회 평균)
- 박자 패턴 선택 (다운비트 강조)
- 템포 라벨 표시 (Largo ~ Prestissimo)
- 진동 피드백 (다운비트 강, 일반 비트 약)
- SystemSound 클릭 사운드
- BPM/박자/설정 자동 저장
- AdMob 광고 (배너/전면/보상형)

## 기술 스택
- **Framework**: Flutter 3.x / Dart 3.8+
- **State Management**: GetX
- **Local Storage**: Hive_CE (키-값 저장)
- **UI**: flutter_screenutil, flex_color_scheme, google_fonts
- **Ads**: google_mobile_ads + AppLovin/Pangle/Unity Mediation
- **Analytics**: Firebase Analytics & Crashlytics

## 설치 및 실행
```bash
flutter pub get
flutter analyze
flutter run
```

## 프로젝트 구조
```
lib/
├── main.dart
├── hive_registrar.g.dart
├── app/
│   ├── admob/          # 광고 관리
│   ├── bindings/       # GetX 바인딩
│   ├── controllers/    # 메트로놈/설정/통계 컨트롤러
│   ├── pages/          # 화면별 위젯
│   ├── routes/         # 라우팅
│   ├── services/       # Hive, 구매, 평가 서비스
│   ├── theme/          # FlexColorScheme 테마
│   ├── translate/      # 다국어 번역
│   └── utils/          # 상수
```

## 라이선스
Copyright (c) 2026 DangunDad. All rights reserved.
