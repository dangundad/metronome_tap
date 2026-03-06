# Metronome & BPM Tap - TODO

## 구현 완료 기능
- [x] 40~280 BPM 슬라이더 조절
- [x] 드리프트 없는 절대 시간 기반 비트 스케줄링
- [x] 마이크로초 단위 인터벌 계산
- [x] 재생 중 BPM 변경 시 부드러운 전환 (_rescheduleFromNow)
- [x] 탭 템포 측정 (최근 8회 평균)
- [x] 3초 비활동 시 탭 히스토리 자동 초기화
- [x] 박자 패턴 선택 (Time Signature)
- [x] 다운비트 강조 (강한 진동 200ms)
- [x] SystemSound.click 사운드 출력
- [x] 템포 라벨 표시 (Largo ~ Prestissimo)
- [x] BPM/박자/설정 자동 저장 (Hive)
- [x] 진동 on/off, 사운드 on/off 토글
- [x] 가이드/도움말 페이지
- [x] 배너/전면/보상형 광고 통합
- [x] 설정 (햅틱, 사운드)
- [x] 다국어 번역 (ko)
- [x] FlexColorScheme 테마 (redWine)
- [x] Firebase Analytics/Crashlytics
- [x] 인앱 구매 서비스
- [x] 앱 평가 서비스

## 출시 전 남은 작업
- [ ] 앱 아이콘 디자인 및 적용 (`dart run flutter_launcher_icons`)
- [ ] 스플래시 화면 디자인 및 적용 (`dart run flutter_native_splash:create`)
- [ ] Google Play Console 앱 등록
- [ ] Apple App Store Connect 앱 등록
- [ ] AdMob 광고 단위 ID 실제 값으로 교체
- [ ] Firebase 프로젝트 연동 (google-services.json / GoogleService-Info.plist)
- [ ] 개인정보처리방침 URL 생성
- [ ] 스토어 스크린샷 및 그래픽 이미지 제작
- [ ] 릴리스 빌드 테스트
- [ ] 실기기 테스트 (다양한 해상도)
- [ ] 고BPM(200+)에서 비트 정확도 실기기 검증
- [ ] ProGuard 규칙 확인
