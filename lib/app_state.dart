import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'gemini_service.dart';
import 'models.dart';
import 'prompt_builder.dart';
import 'tts_service.dart';

class AppState extends ChangeNotifier {
  AppSettings settings = const AppSettings();
  CharProfile character = const CharProfile();
  UserProfile user = const UserProfile();
  StoryConfig story = const StoryConfig();
  final List<ChatMessage> messages = [];
  List<String> allGenres = [];

  bool sending = false;
  String? error;

  /// Pesan yang sedang dibacakan suara (null = tidak ada).
  ChatMessage? speakingMsg;

  late final SharedPreferences _prefs;
  late final PromptBuilder _prompts;
  final GeminiService _gemini = GeminiService();
  final TtsService tts = TtsService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _prompts = await PromptBuilder.load();

    final rawGenres = await rootBundle.loadString('assets/genres.txt');
    allGenres = rawGenres
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();

    settings = _read('settings', AppSettings.fromJson) ?? const AppSettings();
    character = _read('character', CharProfile.fromJson) ?? const CharProfile();
    user = _read('user', UserProfile.fromJson) ?? const UserProfile();
    story = _read('story', StoryConfig.fromJson) ?? const StoryConfig();

    final rawMessages = _prefs.getString('messages');
    if (rawMessages != null) {
      try {
        final list = jsonDecode(rawMessages) as List;
        messages.addAll(
          list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        // data rusak: abaikan
      }
    }
  }

  T? _read<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return parse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    await _prefs.setString('settings', jsonEncode(s.toJson()));
    notifyListeners();
  }

  Future<void> saveCharacter(CharProfile c) async {
    character = c;
    await _prefs.setString('character', jsonEncode(c.toJson()));
    notifyListeners();
  }

  Future<void> saveUser(UserProfile u) async {
    user = u;
    await _prefs.setString('user', jsonEncode(u.toJson()));
    notifyListeners();
  }

  Future<void> saveStory(StoryConfig s) async {
    story = s;
    await _prefs.setString('story', jsonEncode(s.toJson()));
    notifyListeners();
  }

  Future<void> _persistMessages() async {
    await _prefs.setString(
      'messages',
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  // ---------- Suara ----------

  Future<void> speak(ChatMessage m) async {
    speakingMsg = m;
    notifyListeners();
    await tts.speak(m.text, settings);
    if (identical(speakingMsg, m)) {
      speakingMsg = null;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    if (speakingMsg == null) {
      await tts.stop();
      return;
    }
    speakingMsg = null;
    notifyListeners();
    await tts.stop();
  }

  // ---------- Percakapan ----------

  /// Menghapus semua percakapan. Karakter dan cerita tetap tersimpan.
  Future<void> resetChat() async {
    await stopSpeaking();
    messages.clear();
    error = null;
    await _persistMessages();
    notifyListeners();
  }

  Future<bool> startStory() => send(_prompts.openingPrompt, hidden: true);

  List<ChatMessage> _historyForRequest() {
    var h = messages.length > 60
        ? messages.sublist(messages.length - 60)
        : List<ChatMessage>.from(messages);
    while (h.isNotEmpty && h.first.role != 'user') {
      h = h.sublist(1);
    }
    return h;
  }

  Future<String> _generateReply() => _gemini.generate(
        apiKey: settings.apiKey,
        model: settings.model,
        systemPrompt: _prompts.build(
          mode: settings.mode,
          character: character,
          user: user,
          story: story,
        ),
        history: _historyForRequest(),
      );

  /// Membuat ulang balasan AI terakhir. Kalau gagal, balasan lama dikembalikan.
  Future<bool> regenerate() async {
    if (sending || messages.isEmpty || messages.last.role != 'model') return false;
    if (settings.apiKey.isEmpty) {
      error = 'Isi API key Gemini dulu di tab Setelan.';
      notifyListeners();
      return false;
    }
    await stopSpeaking();
    final old = messages.removeLast();
    sending = true;
    error = null;
    notifyListeners();
    try {
      final reply = await _generateReply();
      final msg = ChatMessage(role: 'model', text: reply);
      messages.add(msg);
      await _persistMessages();
      if (settings.ttsAuto) speak(msg);
      return true;
    } catch (e) {
      messages.add(old);
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> deleteMessage(ChatMessage m) async {
    if (sending) return;
    await stopSpeaking();
    messages.remove(m);
    await _persistMessages();
    notifyListeners();
  }

  Future<void> editMessage(ChatMessage m, String newText) async {
    if (sending) return;
    final i = messages.indexOf(m);
    if (i < 0) return;
    await stopSpeaking();
    messages[i] = ChatMessage(
      role: m.role,
      text: newText,
      hidden: m.hidden,
      speaker: m.speaker,
    );
    await _persistMessages();
    notifyListeners();
  }

  /// Hapus giliran terakhir: balasan AI dan pesanmu sebelumnya.
  Future<void> undoLast() async {
    if (sending || messages.isEmpty) return;
    await stopSpeaking();
    if (messages.last.role == 'model') messages.removeLast();
    if (messages.isNotEmpty && messages.last.role == 'user') messages.removeLast();
    await _persistMessages();
    notifyListeners();
  }

  Future<bool> send(String text, {bool hidden = false, String? speaker}) async {
    if (sending) return false;
    if (settings.apiKey.isEmpty) {
      error = 'Isi API key Gemini dulu di tab Setelan.';
      notifyListeners();
      return false;
    }

    await stopSpeaking();
    final userMsg = ChatMessage(
      role: 'user',
      text: text,
      hidden: hidden,
      speaker: speaker,
    );
    messages.add(userMsg);
    sending = true;
    error = null;
    notifyListeners();

    try {
      final reply = await _generateReply();
      final msg = ChatMessage(role: 'model', text: reply);
      messages.add(msg);
      await _persistMessages();
      if (settings.ttsAuto) speak(msg);
      return true;
    } catch (e) {
      messages.remove(userMsg);
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}
