import 'package:flutter/material.dart';

import 'app_state.dart';

const Color kAccent = Color(0xFF8B7CFF);
const Color kCard = Color(0xFF14152A);
const Color kField = Color(0xFF1A1C2E);
const Color kMuted = Color(0xFF9A9CB8);

InputDecoration inputDeco(
  String label, {
  String? hint,
  String? helper,
  IconData? icon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 3,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: kField,
    border: border(Colors.transparent, 0),
    enabledBorder: border(Colors.transparent, 0),
    focusedBorder: border(kAccent, 1.5),
  );
}

class Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFB9B0FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle!,
                style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.35),
              ),
            ),
          const SizedBox(height: 14),
          for (final c in children) ...[c, const SizedBox(height: 12)],
        ],
      ),
    );
  }
}

Future<void> confirmReset(BuildContext context, AppState state) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset percakapan?'),
      content: const Text(
        'Semua percakapan akan dihapus. Karakter dan pengaturan cerita tetap tersimpan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await state.resetChat();
  }
}

/// Mengubah *aksi* jadi miring dan **pikiran** jadi tebal.
List<InlineSpan> formatRp(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*', dotAll: true);
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    if (m.group(1) != null) {
      spans.add(TextSpan(
        text: m.group(1),
        style: base.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFFD28A),
        ),
      ));
    } else {
      spans.add(TextSpan(
        text: m.group(2),
        style: base.copyWith(
          fontStyle: FontStyle.italic,
          color: const Color(0xFFC9C4FF),
        ),
      ));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}
