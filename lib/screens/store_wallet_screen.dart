import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../models2.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';

/// 가게 서류지갑: 사업자 정보 + 사업자등록증/통장 사진 보관·즉시 전송
class StoreWalletScreen extends StatefulWidget {
  const StoreWalletScreen({super.key});

  @override
  State<StoreWalletScreen> createState() => _StoreWalletScreenState();
}

class _StoreWalletScreenState extends State<StoreWalletScreen> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final info = app.storeInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('가게 서류지갑')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.folder_shared, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '사업자번호·계좌·등록증을 한 곳에!\n필요할 때 바로 복사하거나 보내세요.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 가게 정보 카드 ──
          _sectionTitle('🏪 가게 정보'),
          Card(
            child: Column(
              children: [
                _infoTile('상호', info.storeName, Icons.storefront),
                _infoTile('사업자등록번호', info.bizNumber, Icons.badge),
                _infoTile('주소', info.address, Icons.place),
                _infoTile('대표자', info.ownerName, Icons.person),
                _infoTile('연락처', info.phone, Icons.call),
                _infoTile('계좌번호', info.bankAccount, Icons.account_balance),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editInfo(context, info),
                          icon: const Icon(Icons.edit),
                          label: const Text('정보 수정'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _shareAllInfo(info),
                          icon: const Icon(Icons.send),
                          label: const Text('전체 전송'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 사업자등록증 ──
          _sectionTitle('📄 사업자등록증'),
          _docCard(
            context,
            base64Image: info.bizCertImage,
            emptyText: '사업자등록증을 촬영하거나\n사진첩에서 등록해 두세요',
            fileName: 'business_certificate.jpg',
            shareText: '${info.storeName} 사업자등록증입니다.',
            onPick: (src) => _pickImage(src, (b64) {
              info.bizCertImage = b64;
              app.saveStoreInfo(info);
            }),
            onDelete: () {
              info.bizCertImage = null;
              app.saveStoreInfo(info);
            },
          ),
          const SizedBox(height: 20),

          // ── 통장 앞면 ──
          _sectionTitle('🏦 통장 앞면 (계좌 안내용)'),
          _docCard(
            context,
            base64Image: info.bankbookImage,
            emptyText: '통장 앞면을 촬영해 두면\n계좌 물어볼 때 바로 보낼 수 있어요',
            fileName: 'bankbook.jpg',
            shareText:
                '${info.storeName} 계좌 안내드립니다.\n${info.bankAccount.isNotEmpty ? info.bankAccount : ''}',
            onPick: (src) => _pickImage(src, (b64) {
              info.bankbookImage = b64;
              app.saveStoreInfo(info);
            }),
            onDelete: () {
              info.bankbookImage = null;
              app.saveStoreInfo(info);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '※ 사진은 이 폰 안에만 저장됩니다. 외부 서버로 전송되지 않아요.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(t,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _infoTile(String label, String value, IconData icon) {
    final has = value.trim().isNotEmpty;
    return ListTile(
      dense: false,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(
        has ? value : '미입력',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: has ? Colors.black87 : Colors.grey,
        ),
      ),
      trailing: has
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '복사',
                  icon: const Icon(Icons.copy, size: 22),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    _toast('$label 복사 완료!');
                  },
                ),
                IconButton(
                  tooltip: '보내기',
                  icon: const Icon(Icons.send,
                      size: 22, color: AppColors.primary),
                  onPressed: () => Share.share(value),
                ),
              ],
            )
          : null,
    );
  }

  Widget _docCard(
    BuildContext context, {
    required String? base64Image,
    required String emptyText,
    required String fileName,
    required String shareText,
    required void Function(ImageSource) onPick,
    required VoidCallback onDelete,
  }) {
    Uint8List? bytes;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        bytes = base64Decode(base64Image);
      } catch (_) {}
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (bytes != null)
            GestureDetector(
              onTap: () => _viewImage(context, bytes!),
              child: Image.memory(
                bytes,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 160,
              width: double.infinity,
              color: const Color(0xFFF0F4F0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 42, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(emptyText,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.grey)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: bytes == null
                ? Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => onPick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('촬영'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onPick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('사진첩'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _shareImage(bytes!, fileName, shareText),
                          icon: const Icon(Icons.send),
                          label: const Text('바로 보내기'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => onPick(ImageSource.camera),
                        child: const Icon(Icons.photo_camera),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger),
                        onPressed: () => _confirmDelete(onDelete),
                        child: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
      ImageSource source, void Function(String) onSaved) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      onSaved(base64Encode(bytes));
      if (mounted) setState(() {});
      _toast('사진 저장 완료!');
    } catch (e) {
      _toast('사진을 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _shareImage(
      Uint8List bytes, String fileName, String text) async {
    try {
      final xfile = XFile.fromData(bytes, name: fileName, mimeType: 'image/jpeg');
      await Share.shareXFiles([xfile], text: text);
    } catch (_) {
      // 이미지 공유 미지원 환경 → 텍스트만 공유
      await Share.share(text);
    }
  }

  void _viewImage(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(child: Image.memory(bytes)),
      ),
    );
  }

  void _confirmDelete(VoidCallback onDelete) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('저장된 사진을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) {
      onDelete();
      if (mounted) setState(() {});
    }
  }

  void _shareAllInfo(StoreInfo info) {
    final lines = <String>[];
    if (info.storeName.isNotEmpty) lines.add('상호: ${info.storeName}');
    if (info.bizNumber.isNotEmpty) lines.add('사업자등록번호: ${info.bizNumber}');
    if (info.ownerName.isNotEmpty) lines.add('대표자: ${info.ownerName}');
    if (info.address.isNotEmpty) lines.add('주소: ${info.address}');
    if (info.phone.isNotEmpty) lines.add('연락처: ${info.phone}');
    if (info.bankAccount.isNotEmpty) lines.add('계좌: ${info.bankAccount}');
    if (lines.isEmpty) {
      _toast('먼저 가게 정보를 입력해 주세요.');
      return;
    }
    Share.share(lines.join('\n'));
  }

  Future<void> _editInfo(BuildContext context, StoreInfo info) async {
    final app = context.read<AppState>();
    final nameC = TextEditingController(text: info.storeName);
    final bizC = TextEditingController(text: info.bizNumber);
    final addrC = TextEditingController(text: info.address);
    final ownerC = TextEditingController(text: info.ownerName);
    final phoneC = TextEditingController(text: info.phone);
    final bankC = TextEditingController(text: info.bankAccount);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('가게 정보 수정',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _field(nameC, '상호 (가게 이름)'),
              _field(bizC, '사업자등록번호', hint: '예: 123-45-67890',
                  keyboard: TextInputType.number),
              _field(addrC, '주소'),
              _field(ownerC, '대표자 이름'),
              _field(phoneC, '연락처', keyboard: TextInputType.phone),
              _field(bankC, '계좌번호', hint: '예: 국민 123-45-678900 홍길동'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  info.storeName = nameC.text.trim();
                  info.bizNumber = bizC.text.trim();
                  info.address = addrC.text.trim();
                  info.ownerName = ownerC.text.trim();
                  info.phone = phoneC.text.trim();
                  info.bankAccount = bankC.text.trim();
                  app.saveStoreInfo(info);
                  Navigator.pop(ctx);
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 17),
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
