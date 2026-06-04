## Google Play Console 인앱 상품 설정 (Metronome Tap - 무료 + 3단 후원형 프리미엄)

> 2026-05-29 현재 구현 기준의 출시 준비 가이드입니다. 기존 기간형처럼 보이는 Premium 옵션을 Small / Medium / Large 3단 후원형 1회성 구매로 정리합니다. 어떤 옵션을 구매해도 동일하게 광고 제거 프리미엄 권한이 활성화됩니다.

### 앱 수익 모델
- **기본: 무료**: 핵심 기능을 무료로 제공합니다.
- **광고 포함**: 무료 버전에는 AdMob 광고가 표시될 수 있습니다.
- **프리미엄 구매(3단 후원)**: 일회성 관리형 상품(Non-Consumable) 3개를 제공합니다.
  - Small / Medium / Large 중 어떤 옵션을 구매해도 동일한 혜택 제공
  - 모든 광고 제거
  - 구매 상태는 단일 `isPremium` 플래그로 관리
  - 스토어 상세 설명과 스크린샷에는 실제 구현된 기능만 노출

### 프리미엄 상품

| 옵션 | Android ID | iOS ID | 권장 가격 | 설명 |
| --- | --- | --- | --- | --- |
| Small | `com.dangundad.metronometap.premium_small` | `com.dangundad.metronometap.premium.small` | $1.99 | 작은 후원, 광고 제거 |
| Medium | `com.dangundad.metronometap.premium_medium` | `com.dangundad.metronometap.premium.medium` | $4.99 | 인기 옵션, 광고 제거와 추가 후원 |
| Large | `com.dangundad.metronometap.premium_large` | `com.dangundad.metronometap.premium.large` | $9.99 | 광고 제거와 든든한 후원 |

### 구글 플레이 콘솔 상품 등록

1. 구글 플레이 콘솔 -> 앱 -> 수익 창출 -> 제품 -> 인앱 상품
2. "일회성 상품 만들기" 또는 "인앱 상품 만들기" 선택 (Non-consumable)
3. 아래 3개 상품을 등록한 뒤 활성화

**상품 1: Small Premium (커피 한 잔)**
- 상품 ID: `com.dangundad.metronometap.premium_small`
- 태그: `premium`
- 이름 (영어): `A cup of coffee`
- 설명 (한국어): 광고 제거와 커피 한 잔 후원
- 설명 (영어): `Remove ads and support Metronome Tap`
- 구매 옵션 ID: `metronometap-premium-small`
- 가격: 콘솔에서 국가별 최종 설정 (권장 `$1.99`)
- 상태: 활성화

**상품 2: Medium Premium (점심 한 끼)** - 인기/추천
- 상품 ID: `com.dangundad.metronometap.premium_medium`
- 태그: `premium`
- 이름 (영어): `A lunch treat`
- 설명 (한국어): 광고 제거와 추가 후원
- 설명 (영어): `Remove ads and add extra support`
- 구매 옵션 ID: `metronometap-premium-medium`
- 가격: 콘솔에서 국가별 최종 설정 (권장 `$4.99`)
- 상태: 활성화

**상품 3: Large Premium (든든한 후원)**
- 상품 ID: `com.dangundad.metronometap.premium_large`
- 태그: `premium`
- 이름 (영어): `Full support`
- 설명 (한국어): 광고 제거와 든든한 후원
- 설명 (영어): `Remove ads and fully support development`
- 구매 옵션 ID: `metronometap-premium-large`
- 가격: 콘솔에서 국가별 최종 설정 (권장 `$9.99`)
- 상태: 활성화

### PurchaseConstants

```dart
abstract class PurchaseConstants {
  static const String PREMIUM_SMALL_ANDROID =
      'com.dangundad.metronometap.premium_small';
  static const String PREMIUM_MEDIUM_ANDROID =
      'com.dangundad.metronometap.premium_medium';
  static const String PREMIUM_LARGE_ANDROID =
      'com.dangundad.metronometap.premium_large';

  static const List<String> ANDROID_PRODUCT_IDS = [
    PREMIUM_SMALL_ANDROID,
    PREMIUM_MEDIUM_ANDROID,
    PREMIUM_LARGE_ANDROID,
  ];
}
```

### 프리미엄 권한 정책
- Small / Medium / Large 중 어떤 상품이든 1개 구매가 확인되면 `isPremium = true`
- 앱 내부 권한은 단일 프리미엄 플래그로 통일 (옵션별 차등 없음)
- 기능 차등 없이 광고 제거와 개발 후원 의미만 다르게 표현
- 프리미엄은 구독이 아니라 일회성 구매임을 화면과 스토어 문구에서 일관되게 표시

### UI 노출 정책
- 프리미엄 페이지에 3개 옵션을 카드 형태로 동시 노출
- Small 옵션이 기본 선택
- Medium 옵션은 인기/추천 옵션으로 표현
- 사용자가 카드를 선택한 뒤 구매 CTA에서 결제 진입
- 한 번 구매하면 옵션과 무관하게 모든 광고 제거 혜택이 동일하게 활성화됨
- "weekly", "monthly", "yearly", "subscription"처럼 구독으로 오해될 수 있는 문구를 사용자 화면과 스토어 문구에 쓰지 않음