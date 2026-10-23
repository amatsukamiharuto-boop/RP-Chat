import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'gemini_service.dart';
import 'models.dart';
import 'prompt_builder.dart';

class AppState extends ChangeNotifier {
  AppSettings settings = const AppSettings();
  CharProfile character = const CharProfile();
  StoryConfig story = const StoryConfig();
  final List<ChatMessage> messages = [];
  List<String> allGenres = [];

  bool sending = false;
  String? error;

  late final SharedPreferences _prefs;
  late final PromptBuilder _prompts;
  final GeminiService _gemini = GeminiService();

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

  /// Menghapus semua percakapan. Karakter dan cerita tetap tersimpan.
  Future<void> resetChat() async {
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

  Future<bool> send(String text, {bool hidden = false}) async {
    if (sending) return false;
    if (settings.apiKey.isEmpty) {
      error = 'Isi API key Gemini dulu di tab Setelan.';
      notifyListeners();
      return false;
    }

    final userMsg = ChatMessage(role: 'user', text: text, hidden: hidden);
    messages.add(userMsg);
    sending = true;
    error = null;
    notifyListeners();

    try {
      final reply = await _gemini.generate(
        apiKey: settings.apiKey,
        model: settings.model,
        systemPrompt: _prompts.build(
          mode: settings.mode,
          character: character,
          story: story,
        ),
        history: _historyForRequest(),
      );
      messages.add(ChatMessage(role: 'model', text: reply));
      await _persistMessages();
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
