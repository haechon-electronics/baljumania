import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../consult_engine.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';

/// AI 업무상담 채팅 화면
class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg(this.text, this.isUser);
}

class _ConsultScreenState extends State<ConsultScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMsg(
      '안녕하세요 사장님! 발주매니아 AI 상담입니다. 😊\n\n'
      '세무·노무·가게 운영 궁금한 거 편하게 물어보세요.\n'
      '우리 가게 데이터(매출/급여/재고)를 보고 바로 답해드려요!\n\n'
      '아래 추천 질문을 눌러보셔도 됩니다. 👇',
      false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final q = text.trim();
    if (q.isEmpty) return;
    final engine = ConsultEngine(context.read<AppState>());
    setState(() {
      _messages.add(_ChatMsg(q, true));
      _messages.add(_ChatMsg(engine.answer(q), false));
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.support_agent, size: 26),
            SizedBox(width: 8),
            Text('AI 업무상담'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 안내 배너
          Container(
            width: double.infinity,
            color: AppColors.primarySoft,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Text(
              '💡 일반 정보 안내용이에요. 정확한 세무·법률 판단은 전문가 상담을 받아주세요. (전문가 연결 기능 준비 중!)',
              style: TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
          // 채팅 목록
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _bubble(_messages[i]),
            ),
          ),
          // 추천 질문
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: ConsultEngine.quickQuestions
                  .map((q) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(q,
                              style: const TextStyle(fontSize: 14)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: AppColors.primaryLight),
                          onPressed: () => _send(q),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // 입력창
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 17),
                      decoration: InputDecoration(
                        hintText: '궁금한 걸 물어보세요',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'consult_send',
                    onPressed: () => _send(_controller.text),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: m.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isUser ? 16 : 4),
            bottomRight: Radius.circular(m.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          m.text,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: m.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
