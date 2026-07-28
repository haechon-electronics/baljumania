import 'package:flutter/material.dart';

/// AdMob 배너 자리 (전 화면 하단 공통)
/// 웹 미리보기에서는 은은한 플레이스홀더로 표시,
/// Android 빌드 시 google_mobile_ads 배너로 교체됩니다.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('AD',
                style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 8),
          const Text('광고 영역',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAEAEB2))),
        ],
      ),
    );
  }
}
