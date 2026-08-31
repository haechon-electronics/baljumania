// 발주매니아 기본 위젯 테스트
import 'package:flutter_test/flutter_test.dart';

import 'package:baljumania/gemini_key.dart';
import 'package:baljumania/utils.dart';

void main() {
  test('formatWon 포맷 확인', () {
    expect(formatWon(12000), '₩12,000');
    expect(formatWon(0), '₩0');
    expect(formatWon(1234567890), '₩1,234,567,890');
  });

  test('formatQty 소수점 처리', () {
    expect(formatQty(2), '2');
    expect(formatQty(2.5), '2.5');
  });

  test('내장 Gemini 키 복원 무결성 (평문은 테스트에도 미포함)', () {
    final k = EmbeddedGeminiKey.value;
    expect(k.length, 53);
    expect(k.startsWith('AQ.'), isTrue);
    expect(k.endsWith('Ru4A'), isTrue);
    // 복원값에 XOR 마스크 잔재(제어문자 등)가 없어야 함
    expect(k.codeUnits.every((c) => c >= 0x20 && c < 0x7f), isTrue);
  });
}
