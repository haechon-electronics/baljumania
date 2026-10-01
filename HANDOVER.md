# 발주매니아 인수인계 문서 (2026-10-01 실측 기준)

## 1. 프로젝트 개요
- 앱명: 발주매니아 / 패키지·번들ID: `com.baljumania.orders`
- 저장소: https://github.com/haechon-electronics/baljumania (main)
- 스택: Flutter 3.35.4 / Dart 3.9.2 / Provider / Hive(로컬 DB, 서버 없음) / google_mlkit_text_recognition / Gemini Flash Lite(REST) / google_mobile_ads / flutter_local_notifications
- 코드 규모: lib/ 31파일 11,8xx줄 (전수 열람 완료, `flutter analyze` 이슈 0)
- 대상: 요식업 소상공인(중장년), 큰 글씨·iOS 감성 UI

### 핵심 파일
| 파일 | 역할 |
|---|---|
| `lib/app_state.dart` | 전역 상태 + Hive 9개 박스 CRUD, 백업/복원 JSON, 알림 재예약, 발주 추천 |
| `lib/models.dart`, `models2.dart` | Supplier/StockItem/OrderLine/PurchaseOrder/Menu/Sale/Purchase/Employee/WorkLog/StoreInfo (Map 직렬화, 어댑터 없음) |
| `lib/scan_service.dart` | 1차 Gemini(`gemini-flash-lite-latest`) → 실패 시 ML Kit(한국어→라틴) 폴백 |
| `lib/scan_parsers.dart` | OCR 텍스트 규칙 파서 + 문서종류 자동판별(classifyDocument) |
| `lib/payroll.dart` | 급여계산(2026 요율: 최저시급 10,320 / 국민연금 4.75 / 건보 3.595 / 장기요양 13.14% / 고용 0.9) — 웹 실측과 일치 확인 |
| `lib/consult_engine.dart` | 규칙 기반 AI 상담(세무·노무 FAQ + 앱 데이터) |
| `lib/gemini_key.dart` | **git 미포함(.gitignore)**. Codemagic에서 `GEMINI_KEY_DART_B64` 환경변수로 생성 |
| `codemagic.yaml` | iOS App Store 자동서명(`fetch-signing-files --create`) + TestFlight 업로드 |

### 화면 맵 (18개)
홈 → 발주(목록/등록/상세) → 재고(목록/편집) → 거래처 → 더보기(서류지갑·스마트촬영·AI상담·메뉴레시피·판매입력·간편구매·매출분석·직원급여·세무내보내기·설정·백업복원)

## 2. 빌드/배포 상태
- Android: 샌드박스 `flutter build apk/appbundle` 가능 (서명키 `android/release-key.jks`)
- iOS: Codemagic `iOS Release (App Store)` 워크플로우. 필요한 Codemagic 설정:
  - Integrations → App Store Connect 키 `rawgram-asc-key` (Key ID 2JW2B29LCQ)
  - Environment variables 그룹 `gemini`: `GEMINI_KEY_DART_B64`(Secure), `CERTIFICATE_PRIVATE_KEY`(Secure, rawgram과 동일 RSA 키)
  - Apple Distribution 인증서 3개 상한 → 새 키 생성 불가, 반드시 기존 rawgram 개인키 재사용
- 웹 미리보기: `flutter build web --release` → `build/web` 정적 서빙 (포트 5060)

## 3. 이번 전수조사에서 발견·수정한 버그 (전부 실제 코드 수정, 커밋 91cd4c9)
| # | 심각도 | 내용 | 수정 위치 | 검증 |
|---|---|---|---|---|
| 0 | **치명** | 최초 실행 시 시드 후 `_loadAll()` 누락 → 모든 탭 빈 화면 | `app_state.dart init()` | 스크린샷 |
| 0-1 | **치명** | `_newId()` 마이크로초 충돌로 웹에서 시드 5개 중 3개만 저장 | `_newId()` seq+random | 스크린샷(5개 표시) |
| 1 | 높음 | 스캔 생성 라인(itemId '') 입고 시 재고 미반영 | `_applyReceivedLine` 신규 StockItem 자동 생성, `receiveOrderLine→bool`, `receiveAllLines→int`, 스낵바 안내 | 스크린샷("두부 입고 완료 · 재고 +10모") |
| 2 | 중 | 재고 삭제 참조 경고 없음 | `stockUsage()` + stock_screen/stock_edit_screen 삭제 다이얼로그 | 스크린샷(두부 스와이프 → "입고 대기 발주 1건에 들어 있어요") |
| 3 | 중 | 거래처 즉시 삭제 | `supplierItemCount()` + 확인 다이얼로그 | 스크린샷("연결된 품목 3개") |
| 4 | 중 | 간편구매 수정 불가 | `purchase_screen.dart` 탭→편집 시트 | 스크린샷(등록→탭→"구매 기록 수정" 프리필→금액 변경 저장→리스트 반영) |
| 5 | 중 | 발주 수정 불가 | `order_edit_screen.dart editOrder` 모드, `updateOrder()`, 입고된 라인 잠금 | 스크린샷(10모→12모 저장 → 상세 ₩14,400·문자 본문 12모·"발주 수정 완료!" 스낵바) |
| 6 | 높음 | `deleteSale` 재고 복원 안 함 | `_applySaleStock(sale, sign:1)` | 코드 |
| 7 | 중 | 백업 복원 붙여넣기만 | `file_picker` 파일 선택 복원 + 붙여넣기 폴백 | 스크린샷(시트 버튼 표시 + 붙여넣기 복원 전 과정 실행·성공) |
| 8 | 높음 | iOS 알림 미초기화 | Darwin init/permissions/details | 실기기 필요 |
| 9 | 중 | AdMob iOS ID | `ad_config.dart` 플랫폼 분기(iOS는 Google 테스트 ID). **실제 iOS 광고단위/앱 ID는 AdMob 콘솔에서 발급 후 `ad_config.dart`·`Info.plist` 교체 필요** | 코드 |
| 10 | 낮음 | OCR 실패 원인 안내 없음 | `scan_service.lastFailReason/failMessage()` → scan/smart_scan 화면 | 코드 |
| 11 | 중 | 이름 contains 오매칭 | `_findStockByName` 정확→공백제거→(길이≥2 & 후보 1개)만 부분일치 | 코드 |
| 12 | 낮음 | 배경색 미지정 | store_wallet/tax_export `backgroundColor` | 스크린샷(서류지갑 배경 일치) |
| + | UX | 홈 지표 탭→탭 이동(`MainShell.tabRequest`), 재고/품목선택 검색(8개 초과 시, 스크린샷 검증), 재고 롱프레스 수량 조정, 문자 전송 시 전화번호 없음 다이얼로그, 근무시간 24시 이상 "익일" 표기, 발주일 과거 선택 가드 | 각 화면 | 지표 탭·수량조정·전화번호 없음 다이얼로그(거래처 번호 삭제 후 문자 보내기 → "거래처 전화번호 없음" [취소/문자앱 열기]) 스크린샷 |

## 4. 다음 작업자 TODO
### A. 남은 확인 항목
1. iOS 실기기: 알림 권한/표시(#8), ML Kit 한국어 모델 첫 다운로드.
2. AdMob 실제 iOS 앱 ID·배너 ID 발급 후 교체(#9).
3. (완료) 품목 9개 이상 시 재고 검색창·발주 품목 선택 시트 검색창, 백업 붙여넣기 복원 — 전부 스크린샷 실측 완료. 10품목 백업 JSON 붙여넣기 → "정말 복원할까요?" 확인 → "복원 완료!" 스낵바·가게 이름 교체 → 재고 탭 검색창 노출·"파" 입력 시 양파/대파만 표시 → 새 발주 품목 선택 시트 검색창 노출·"고추" 입력 시 고추장만 표시.
4. 검증 하네스 메모: headless Chrome CDP 터치 좌표는 CSS px(430×932, DPR 1 실측). 모달 닫힘 직후 연속 탭은 무시되므로 별도 호출로 분리할 것.

### B. 시장조사 기반 추가 기능 제안 (경쟁앱 실측: 재고요 19,900~29,900원/월, 주담 9,900원/월, MIRI, 도도카트, 일기월장, 캐시노트)
경쟁앱이 전부 갖고 있고 발주매니아에 **없는** 것:
1. **소비기한/유통기한 관리 + 임박 알림** — 재고요·주담·MIRI 3사 모두 핵심 기능. `StockItem`에 `expiryDate` 필드 추가 → 홈 "3일 내 만료" 카드 + 아침 알림에 포함. (가장 높은 우선순위)
2. **배달앱 수수료 계산 반영 순매출** — 2026 차등수수료(배민·쿠팡이츠 2.0~7.8% + 배달비 1,900~3,400 + 결제 3% + VAT, 요기요 4.7~9.7%). 판매 채널별 "실제 정산액" 표시 → 일기월장의 차별 포인트. `SaleRecord.channel`이 이미 있어 구현 용이.
3. **폐기(로스) 기록** — 재고요의 "조리 손실률·직원식사" 반영. 재고 화면에 "폐기 -N" 버튼 + 월간 폐기 금액 분석.
4. **고정비 입력 + 손익분기점/순이익** — 임대료·공과금·인건비 합산 → "이번 달 손익분기 달성률". 월간요약 CSV에 이미 매출/매입/인건비 있어 고정비만 추가하면 됨.
5. **품목/거래처 검색창** — 품목 50개 넘어가면 스크롤 불편. 재고·발주 품목 선택 시트에 검색 필드.
6. **거래처별 단가 비교(B2B 비교발주)** — 현재 "준비중" 타일. 같은 품목을 거래처별 lastPrice 이력으로 비교만 해도 가치 있음 (`StockItem`에 `priceHistory: List<{date,price,supplierId}>`).
7. **다기기 동기화/클라우드 백업** — 로컬 전용이라 폰 분실 = 데이터 소실. Firebase 연동 또는 최소한 자동 주기 백업(share) 리마인더.
8. **발주 템플릿/반복 발주** — "지난번과 동일하게 발주" 원탭.
9. **직원 출퇴근 셀프 체크(QR/버튼)** — 일기월장 근태 기능. 현재는 사장이 메시지 붙여넣기.
10. **메뉴 원가 변동 알림** — 단가 상승으로 원가율 40% 초과 시 푸시.

### C. 품질/UX 개선 (저비용)
- 빈 상태 화면에 "샘플 보기/첫 등록 가이드" 버튼
- 발주 상세 "문자 보내기"에 거래처 전화 없을 때 사전 안내
- 홈 히어로 카드 숫자 탭 → 해당 목록으로 이동
- 재고 수량 빠른 조정(+/−) 목록에서 바로
- 다크모드 미지원 (중장년 타깃이라 우선순위 낮음)
- 접근성: 아이콘 버튼 tooltip/semantics 미설정 다수

## 5. 검증 방법 (샌드박스)
```bash
cd /home/user/flutter_app
flutter analyze && flutter build web --release
# 헤드리스 크롬 스크린샷 자동화: /tmp/chrome_daemon.sh + /tmp/shot.py (CDP, 포트 9333)
```
Android 실기 테스트 필수 항목: 카메라 촬영 인식(ML Kit 한국어), 알림 예약, 문자(sms:) 인텐트, 공유 시트, AdMob 배너.

## 6. 외부 계정/키 위치
- Gemini API 키: `lib/gemini_key.dart` (로컬) / Codemagic `GEMINI_KEY_DART_B64`
- AdMob: 앱 ID `ca-app-pub-1311449503181741~7509503082`, 배너 `…/1478181276` (`lib/ad_config.dart`, AndroidManifest)
- Apple: Team 9RP53DV2GY, ASC Key 2JW2B29LCQ
- 개인정보처리방침/약관: `docs/` (GitHub Pages)
