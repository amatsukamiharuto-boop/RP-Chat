import 'dart:math' as math;

import 'package:flutter_tts/flutter_tts.dart';

import 'models.dart';

class VoiceInfo {
  final String name;
  final String locale;
  const VoiceInfo(this.name, this.locale);
}

/// Membersihkan teks roleplay supaya enak dibacakan (tanpa tanda * dan kutip).
String cleanForSpeech(String text, {bool dialogOnly = false}) {
  var t = text;
  if (dialogOnly) {
    final re = RegExp(r'"([^"]+)"|“([^”]+)”');
    final parts = [
      for (final m in re.allMatches(t)) (m.group(1) ?? m.group(2) ?? '').trim(),
    ].where((e) => e.isNotEmpty).toList();
    if (parts.isNotEmpty) t = parts.join('. ');
  }
  t = t
      .replaceAll(RegExp(r'[*_#`~]'), '')
      .replaceAll('"', '')
      .replaceAll('“', '')
      .replaceAll('”', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return t;
}

/// Pembungkus text-to-speech bawaan HP. Semua error ditelan supaya app tidak crash.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  int _token = 0;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  Future<List<VoiceInfo>> voices() async {
    try {
      await _init();
      final raw = await _tts.getVoices;
      if (raw is! List) return [];
      final out = <VoiceInfo>[];
      for (final v in raw) {
        if (v is Map) {
          final name = (v['name'] ?? '').toString();
          final locale = (v['locale'] ?? '').toString().replaceAll('_', '-');
          if (name.isNotEmpty) out.add(VoiceInfo(name, locale));
        }
      }
      out.sort((a, b) => a.name.compareTo(b.name));
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> speak(String text, AppSettings s) async {
    final my = ++_token;
    try {
      await _init();
      await _tts.stop();
      final clean = cleanForSpeech(text, dialogOnly: s.ttsDialogOnly);
      if (clean.isEmpty) return;
      await _tts.setLanguage(s.ttsLocale.isEmpty ? 'id-ID' : s.ttsLocale);
      if (s.ttsVoice.isNotEmpty) {
        await _tts.setVoice({'name': s.ttsVoice, 'locale': s.ttsLocale});
      }
      await _tts.setSpeechRate(s.ttsRate);
      await _tts.setPitch(s.ttsPitch);
      for (final chunk in _chunks(clean)) {
        if (my != _token) return;
        await _tts.speak(chunk);
      }
    } catch (_) {
      // suara gagal: abaikan, chat tetap jalan
    }
  }

  Future<void> stop() async {
    _token++;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Android membatasi panjang teks sekali baca, jadi dipotong per kalimat.
  static List<String> _chunks(String t, {int max = 1500}) {
    final out = <String>[];
    var cur = StringBuffer();
    for (final s in t.split(RegExp(r'(?<=[.!?…])\s+'))) {
      if (cur.isNotEmpty && cur.length + s.length + 1 > max) {
        out.add(cur.toString());
        cur = StringBuffer();
      }
      if (s.length > max) {
        for (var i = 0; i < s.length; i += max) {
          out.add(s.substring(i, math.min(i + max, s.length)));
        }
        continue;
      }
      if (cur.isNotEmpty) cur.write(' ');
      cur.write(s);
    }
    if (cur.isNotEmpty) out.add(cur.toString());
    return out;
  }
}
