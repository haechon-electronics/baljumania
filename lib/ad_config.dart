/// AdMob 광고 ID 설정 (발주매니아 실제 ID 적용 완료)
///
/// ✅ 2026-07-29: 대표님 실제 AdMob ID로 교체 완료
/// - 앱 ID: ca-app-pub-1311449503181741~7509503082
///   (android/app/src/main/AndroidManifest.xml 에 등록됨)
/// - 배너 광고 단위 ID: 아래 bannerAdUnitId
///
/// 참고: 새 광고 단위는 광고 게재 시작까지 최대 1시간,
/// 신규 AdMob 앱은 승인까지 며칠 걸릴 수 있음 (그동안 '광고 준비 중' 표시됨)
class AdConfig {
  AdConfig._();

  /// 배너 광고 단위 ID (발주매니아 하단배너 - 실제 ID)
  static const String bannerAdUnitId =
      'ca-app-pub-1311449503181741/1478181276';

  /// 실제 ID 적용 완료
  static const bool isTestId = false;
}
