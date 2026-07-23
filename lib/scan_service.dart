import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// 촬영 → 글자 인식 서비스
/// 1차: ML Kit (완전 무료, 폰에서 처리)
/// 2차: Gemini Flash (API 키 있으면 자동 사용, 해석 정확도 대폭 상승)
class ScanService {
  ScanService._();
  static final ScanService instance = ScanService._();

  final _picker = ImagePicker();

  /// Gemini API 키 (설정에서 입력, 없으면 ML Kit만 사용)
  String geminiApiKey = '';

  bool get aiEnabled => geminiApiKey.trim().isNotEmpty;

  /// 사진 선택/촬영
  Future<XFile?> pickImage({bool fromCamera = true}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 88,
      );
    } catch (_) {
      return null;
    }
  }

  /// ML Kit 무료 OCR (한국어) — 폰 전용, 웹에서는 빈 문자열
  Future<String> recognizeText(XFile image) async {
    if (kIsWeb) return '';
    TextRecognizer? recognizer;
    try {
      recognizer =
          TextRecognizer(script: TextRecognitionScript.korean);
      final input = InputImage.fromFilePath(image.path);
      final result = await recognizer.processImage(input);
      return result.text;
    } catch (e) {
      if (kDebugMode) debugPrint('OCR 실패: $e');
      return '';
    } finally {
      await recognizer?.close();
    }
  }

  /// Gemini Flash 이미지 분석 (키 있을 때만)
  /// [task]에 따라 구조화된 JSON을 돌려받음
  Future<Map<String, dynamic>?> analyzeWithGemini(
      XFile image, String task) async {
    if (!aiEnabled) return null;
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);

      final prompt = _promptFor(task);
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey.trim()}');

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
      default:
        return '사진의 모든 글자를 읽어 {"text": "..."} JSON으로만 답하세요.';
    }
  }
}
