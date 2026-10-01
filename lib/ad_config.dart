import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob 광고 ID 설정 (플랫폼별)
///
/// ■ Android — 실제 ID 적용 완료 (2026-07-29)
///   - 앱 ID: ca-app-pub-1311449503181741~7509503082  (AndroidManifest.xml)
///   - 배너 단위: ca-app-pub-1311449503181741/1478181276
///
/// ■ iOS — ⚠️ 아직 AdMob 콘솔에 iOS 앱이 등록되지 않음.
///   AdMob 앱 ID / 광고 단위 ID는 플랫폼마다 **다르게 발급**되므로
///   Android ID를 iOS에서 쓰면 광고가 영원히 "준비 중"으로 뜸 (no-fill).
///   아래 iOS 값은 Google 공식 테스트 ID → 출시 전 실제 iOS ID로 교체:
///     1) AdMob 콘솔 → 앱 추가 → iOS → 번들ID com.baljumania.orders
///     2) 앱 ID → ios/Runner/Info.plist 의 GADApplicationIdentifier 교체
///     3) 배너 광고 단위 생성 → 아래 _iosBannerId 교체
class AdConfig {
  AdConfig._();

  static const String _androidBannerId =
      'ca-app-pub-1311449503181741/1478181276';

  /// Google 공식 iOS 배너 테스트 ID (실제 iOS 단위 발급 후 교체)
  static const String _iosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// 현재 플랫폼의 배너 광고 단위 ID
  static String get bannerAdUnitId =>
      _isIOS ? _iosBannerId : _androidBannerId;

  /// 현재 플랫폼이 테스트 ID를 쓰고 있는지 (iOS는 실제 ID 발급 전까지 true)
  static bool get isTestId => _isIOS;
}
