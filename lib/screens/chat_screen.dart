import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

class ChatScreen extends StatefulWidget {
  final AppState state;
  const ChatScreen({super.key, required this.state});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Nama NPC yang sedang kamu gerakkan. null = karakter milikmu sendiri.
  String? _actingAs;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_scrollToEnd);
    _jumpToEnd();
  }

  @override
  void dispose() {
    widget.state.removeListener(_scrollToEnd);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Saat app dibuka, langsung lompat ke pesan terakhir.
  void _jumpToEnd([int frames = 4]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      if (frames > 1) _jumpToEnd(frames - 1);
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  List<Npc> _myNpcs(AppState s) =>
      s.story.npcs.where((n) => n.userControlled && n.name.trim().isNotEmpty).toList();

  String? _validSpeaker(AppState s) {
    final a = _actingAs;
    if (a == null) return null;
    return _myNpcs(s).any((n) => n.name.trim() == a) ? a : null;
  }

  Future<void> _showActions(ChatMessage m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF14152A),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Salin'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Hapus'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan disalin')),
      );
    } else if (action == 'edit') {
      final t = await showDialog<String>(
        context: context,
        builder: (_) => _EditDialog(initial: m.text),
      );
      if (t != null && t.trim().isNotEmpty) {
        await widget.state.editMessage(m, t.trim());
      }
    } else if (action == 'delete') {
      await widget.state.deleteMessage(m);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.state.sending) return;
    final speaker = _validSpeaker(widget.state);
    _controller.clear();
    final ok = await widget.state.send(text, speaker: speaker);
    if (!ok && mounted && _controller.text.isEmpty) {
      _controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final msgs = state.messages.where((m) => !m.hidden).toList();
        final charLabel = state.character.name.isEmpty ? 'Narator' : state.character.name;
        final selfLabel = state.user.name.isEmpty ? 'Aku' : state.user.name;
        final mine = _myNpcs(state);
        final speaker = _validSpeaker(state);

        String labelFor(ChatMessage m) {
          if (m.role == 'user') return m.speaker ?? state.user.name;
          return charLabel;
        }

        return Column(
          children: [
            if (state.error != null) _ErrorBanner(state: state),
            Expanded(
              child: msgs.isEmpty && !state.sending
                  ? _EmptyState(state: state)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      itemCount: msgs.length + (state.sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= msgs.length) {
                          return _Bubble(
                            message: const ChatMessage(role: 'model', text: '*menulis...*'),
                            label: charLabel,
                          );
                        }
                        final m = msgs[i];
                        final isLast = i == msgs.length - 1;
                        final isModel = m.role == 'model';
                        final isSpeaking = identical(state.speakingMsg, m);
                        return _Bubble(
                          message: m,
                          label: labelFor(m),
                          onMenu: state.sending ? null : () => _showActions(m),
                          onRegenerate: isLast && isModel && !state.sending
                              ? state.regenerate
                              : null,
                          speaking: isSpeaking,
                          onSpeak: isModel && !state.sending
                              ? () => isSpeaking ? state.stopSpeaking() : state.speak(m)
                              : null,
                        );
                      },
                    ),
            ),
            if (mine.isNotEmpty)
              _SpeakerBar(
                selfLabel: selfLabel,
                npcNames: [for (final n in mine) n.name.trim()],
                selected: speaker,
                onSelected: (name) => setState(() => _actingAs = name),
              ),
            _InputBar(
              controller: _controller,
              sending: state.sending,
              hint: speaker == null
                  ? 'Tulis aksi atau dialog...'
                  : 'Tulis aksi atau dialog sebagai $speaker...',
              onSend: _send,
            ),
          ],
        );
      },
    );
  }
}

class _SpeakerBar extends StatelessWidget {
  final String selfLabel;
  final List<String> npcNames;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SpeakerBar({
    required this.selfLabel,
    required this.npcNames,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool isSelected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: kField,
            selectedColor: const Color(0xFF4A3FA8),
            shape: const StadiumBorder(),
            side: BorderSide(color: isSelected ? kAccent : const Color(0x22FFFFFF)),
            onSelected: (_) => onTap(),
          ),
        );

    return Container(
      color: const Color(0xFF11121F),
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text('Bicara sebagai:', style: TextStyle(color: kMuted, fontSize: 12.5)),
              ),
            ),
            chip(selfLabel, selected == null, () => onSelected(null)),
            for (final n in npcNames) chip(n, selected == n, () => onSelected(n)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppState state;
  const _ErrorBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0x33FF5A5F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FF5A5F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFFF8A8E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error ?? '',
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: state.clearError,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppState state;
  const _EmptyState({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = state.character;
    final s = state.story;
    final details = <String>[
      if (s.genres.isNotEmpty) s.genres.join(', '),
      if (s.place.isNotEmpty) s.place,
      if (s.time.isNotEmpty) s.time,
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFB07CFF)],
                ),
              ),
              child: const Icon(Icons.auto_stories_rounded, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              c.name.isEmpty ? 'Belum ada karakter' : c.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              details.isEmpty
                  ? 'Atur karakter, identitasmu, dan cerita di tab bawah, atau langsung mulai bermain.'
                  : details.join('  •  '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: state.sending ? null : state.startStory,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Cerita'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Atau ketik aksi pertamamu di bawah.',
              style: TextStyle(color: kMuted, fontSize: 12.5),
            ),
            if (state.settings.apiKey.isEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Isi API key Gemini di tab Setelan dulu.',
                style: TextStyle(color: Color(0xFFFFC857), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final String label;
  final VoidCallback? onMenu;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSpeak;
  final bool speaking;

  const _Bubble({
    required this.message,
    required this.label,
    this.onMenu,
    this.onRegenerate,
    this.onSpeak,
    this.speaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    const base = TextStyle(fontSize: 15, height: 1.45, color: Color(0xFFF1F1F8));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(colors: [Color(0xFF5B4BD6), Color(0xFF8266F5)])
                : null,
            color: isUser ? null : const Color(0xFF1E2036),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isUser ? const Color(0xFFE2DCFF) : const Color(0xFFB9B0FF),
                      ),
                    ),
                  if (onSpeak != null)
                    InkWell(
                      onTap: onSpeak,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
                        child: Icon(
                          speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                          size: 18,
                          color: speaking ? kAccent : kMuted,
                        ),
                      ),
                    ),
                  if (onMenu != null)
                    InkWell(
                      onTap: onMenu,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 2, 0, 2),
                        child: Icon(Icons.more_horiz_rounded, size: 18, color: kMuted),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText.rich(
                TextSpan(children: formatRp(message.text, base)),
              ),
              if (onRegenerate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Ulangi balasan'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final String hint;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF11121F),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: kField,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: sending ? null : onSend,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String initial;
  const _EditDialog({required this.initial});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit pesan'),
      content: TextField(
        controller: _c,
        autofocus: true,
        minLines: 3,
        maxLines: 10,
        decoration: inputDeco('Isi pesan'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _c.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
