import 'package:flutter/material.dart';

/// AdMob 배너 자리 (전 화면 하단 공통)
/// 웹 미리보기에서는 플레이스홀더로 표시,
/// Android 빌드 시 google_mobile_ads 배너로 교체됩니다.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('AD',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text('광고 배너 영역 (AdMob)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
