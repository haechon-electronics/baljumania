/// AdMob 광고 ID 설정
///
/// ⚠️ 현재는 구글 공식 "테스트 광고 ID"가 들어있습니다.
/// 테스트 ID로도 실제 광고가 표시되지만 수익은 발생하지 않습니다.
///
/// 📌 출시 전 교체 방법 (대표님이 하실 일):
/// 1. https://apps.admob.com 접속 → 로그인
/// 2. [앱] → [앱 추가] → Android → "발주매니아" 등록
/// 3. 발급받은 "앱 ID" (ca-app-pub-XXXX~YYYY) 를
///    android/app/src/main/AndroidManifest.xml 의 APPLICATION_ID 값에 교체
/// 4. [광고 단위] → [광고 단위 추가] → 배너 → 이름 "하단배너"
/// 5. 발급받은 "광고 단위 ID" (ca-app-pub-XXXX/ZZZZ) 를
///    아래 bannerAdUnitId 값에 교체
/// 6. 앱 재빌드 → 완료!
class AdConfig {
  AdConfig._();

  /// 배너 광고 단위 ID
  /// 현재: 구글 공식 테스트 배너 ID (Android)
  /// 출시 전: 대표님의 실제 광고 단위 ID로 교체
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// 테스트 ID 사용 중인지 여부 (실제 ID로 교체하면 false로 변경)
  static const bool isTestId = true;
}
