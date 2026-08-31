// 발주매니아 기본 위젯 테스트
import 'package:flutter_test/flutter_test.dart';

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
}
