import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'gemini_key.dart';

/// 촬영 → 글자 인식 서비스
/// 1차: Gemini Flash AI 정밀인식 (기본 내장 — 무제한 무료 제공)
/// 2차: ML Kit (완전 무료, 폰에서 처리) — AI 실패/오프라인 시 자동 폴백
/// 본인 Gemini 키를 설정에 등록하면 본인 키로 대체 사용
class ScanService {
  ScanService._();
  static final ScanService instance = ScanService._();

  final _picker = ImagePicker();

  /// 사용자 본인 Gemini API 키 (선택사항 — 등록 시 본인 키 사용)
  String geminiApiKey = '';

  bool get hasUserKey => geminiApiKey.trim().isNotEmpty;

  /// AI 정밀인식 사용 가능 여부 — 키가 내장되어 있으므로 항상 켜짐 (무제한)
  bool get aiEnabled => true;

  String get _effectiveKey =>
      hasUserKey ? geminiApiKey.trim() : EmbeddedGeminiKey.value;

  /// 사진 선택/촬영
  Future<XFile?> pickImage({bool fromCamera = true}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2560,
        imageQuality: 92,
      );
    } catch (_) {
      return null;
    }
  }

  /// ML Kit 무료 OCR (한국어) — 폰 전용, 웹에서는 빈 문자열
  /// 한글 모델이 실패하거나 못 읽으면 라틴(숫자/영문) 모델로 자동 재시도
  Future<String> recognizeText(XFile image) async {
    if (kIsWeb) return '';
    final korean = await _runOcr(image, TextRecognitionScript.korean);
    if (korean.trim().isNotEmpty) return korean;
    return _runOcr(image, TextRecognitionScript.latin);
  }

  Future<String> _runOcr(XFile image, TextRecognitionScript script) async {
    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer(script: script);
      final input = InputImage.fromFilePath(image.path);
      final result = await recognizer.processImage(input);
      return result.text;
    } catch (e) {
      if (kDebugMode) debugPrint('OCR($script) 실패: $e');
      return '';
    } finally {
      await recognizer?.close();
    }
  }

  /// Gemini Flash 이미지 분석 (키 있을 때만)
  /// [task]에 따라 구조화된 JSON을 돌려받음
  Future<Map<String, dynamic>?> analyzeWithGemini(
      XFile image, String task) async {
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);

      final prompt = _promptFor(task);
      // gemini-flash-lite-latest: 항상 최신 경량 모델을 가리키는 별칭 (구버전 은퇴 영향 없음)
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=$_effectiveKey');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': b64,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'response_mime_type': 'application/json',
        }
      });

      final res = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('Gemini 오류 ${res.statusCode}: ${res.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
      if (text == null) return null;

      // JSON 응답 파싱 (```json 블록 제거)
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(json)?'), '')
            .replaceFirst(RegExp(r'```$'), '')
            .trim();
      }
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini 분석 실패: $e');
      return null;
    }
  }

  String _promptFor(String task) {
    switch (task) {
      case 'auto':
        return '이 사진이 어떤 문서인지 판별하고 내용을 추출하세요. 다음 JSON 형식으로만 답하세요:\n'
            '{"docType": "receipt|salesReport|bizCert|menu|buyList|unknown", "data": {...}}\n\n'
            'docType 판별 기준:\n'
            '- receipt: 내가 물건을 산 영수증(마트/식자재/거래처), 거래명세서, 납품서. 특징: 카드승인번호, 거스름돈, 품목별 단가\n'
            '- salesReport: 우리 가게의 매출 문서. 포스(POS) 일일매출/영업일보/마감정산/매출일계표/정산표. 특징: 카드매출+현금매출 구분, 총매출, 주문건수, 객단가, 메뉴별 판매수량, 시간대별/결제수단별 집계\n'
            '- bizCert: 사업자등록증\n'
            '- menu: 음식점 메뉴판 (메뉴명+가격만 나열, 수량 없음)\n'
            '- buyList: 손글씨/메모지/포스트잇에 적은 구매할 물건 목록(장보기 리스트). 특징: 가격 없이 품목명만 나열, 수량/단위만 있을 수 있음, 손글씨인 경우 많음\n'
            '- unknown: 위 어느 것도 아님\n'
            '주의: "일보", "마감", "정산", "매출" 단어가 보이면 salesReport일 가능성이 높음. 영수증과 일보 둘 다 금액 목록이 있지만, 일보는 가게 전체 매출 집계이고 영수증은 개별 구매 건임. 가격 없이 품목만 적혀 있으면 buyList일 가능성이 높음.\n\n'
            'data 형식 (docType별):\n'
            '- receipt: {"store": "매장명", "date": "YYYY-MM-DD", "items": [{"name": "품목", "qty": 숫자, "unit": "단위", "price": 단가숫자}], "total": 총액숫자}\n'
            '- salesReport: {"date": "YYYY-MM-DD", "menus": [{"name": "메뉴명", "qty": 수량숫자, "amount": 금액숫자}], "total": 총매출숫자}\n'
            '- bizCert: {"bizNumber": "000-00-00000", "storeName": "상호", "ownerName": "대표자", "address": "주소"}\n'
            '- menu: {"menus": [{"name": "메뉴명", "price": 가격숫자}]}\n'
            '- buyList: {"items": [{"name": "품목명", "qty": 수량숫자(없으면 1), "unit": "단위(없으면 개)"}]}\n'
            '- unknown: {}\n'
            '합계/부가세/카드승인 줄은 items/menus에서 제외. 불명확한 값은 빈문자열 또는 0.';
      case 'receipt':
        return '이 사진은 한국 영수증 또는 거래명세서입니다. 다음 JSON 형식으로만 답하세요:\n'
            '{"store": "매장/거래처명", "date": "YYYY-MM-DD (없으면 빈문자열)", '
            '"items": [{"name": "품목명", "qty": 수량숫자, "unit": "단위(개/kg/박스 등)", "price": 단가숫자}], '
            '"total": 총액숫자}\n'
            '수량이 불명확하면 1, 단가 불명확하면 0으로. 합계/부가세/카드승인 줄은 items에서 제외하세요.';
      case 'salesReport':
        return '이 사진은 한국 음식점 포스(POS) 일일 매출 리포트입니다. 다음 JSON 형식으로만 답하세요:\n'
            '{"date": "YYYY-MM-DD (없으면 빈문자열)", '
            '"menus": [{"name": "메뉴명", "qty": 판매수량숫자, "amount": 금액숫자}], '
            '"total": 총매출숫자}\n'
            '합계/부가세/할인 줄은 menus에서 제외하세요.';
      case 'bizCert':
        return '이 사진은 한국 사업자등록증입니다. 다음 JSON 형식으로만 답하세요:\n'
            '{"bizNumber": "000-00-00000 형식 사업자등록번호", "storeName": "상호", '
            '"ownerName": "대표자 성명", "address": "사업장 소재지"}\n'
            '읽을 수 없는 항목은 빈 문자열로.';
      case 'menu':
        return '이 사진은 한국 음식점 메뉴판입니다. 다음 JSON 형식으로만 답하세요:\n'
            '{"menus": [{"name": "메뉴명", "price": 가격숫자}]}\n'
            '가격이 없으면 0으로. 카테고리 제목은 제외하고 실제 메뉴만.';
      case 'buyList':
        return '이 사진은 손글씨 또는 메모로 적은 구매할 물건 목록(장보기 리스트)입니다. 다음 JSON 형식으로만 답하세요:\n'
            '{"items": [{"name": "품목명", "qty": 수량숫자, "unit": "단위(kg/개/모/단/박스 등)"}]}\n'
            '수량이 없으면 1, 단위가 없으면 "개"로. 손글씨가 흘려 있어도 최대한 추정해서 읽으세요. 제목 줄(구매목록, 장보기 등)은 items에서 제외.';
      default:
        return '사진의 모든 글자를 읽어 {"text": "..."} JSON으로만 답하세요.';
    }
  }
}
