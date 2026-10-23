import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Membaca semua teks prompt dari assets/prompts/ lalu menyusunnya.
/// Ubah isi file .txt di folder itu untuk mengubah perilaku AI.
class PromptBuilder {
  final String _base;
  final String _normal;
  final String _gelap;
  final String _charTpl;
  final String _storyTpl;
  final String _opening;

  PromptBuilder._(
    this._base,
    this._normal,
    this._gelap,
    this._charTpl,
    this._storyTpl,
    this._opening,
  );

  static Future<PromptBuilder> load() async {
    Future<String> read(String name) => rootBundle.loadString('assets/prompts/$name');
    return PromptBuilder._(
      await read('system_prompt.txt'),
      await read('mode_normal.txt'),
      await read('mode_gelap.txt'),
      await read('character_template.txt'),
      await read('story_template.txt'),
      await read('opening_prompt.txt'),
    );
  }

  String get openingPrompt => _opening.trim();

  String build({
    required String mode,
    required CharProfile character,
    required StoryConfig story,
  }) {
    final parts = <String>[
      _base.trim(),
      (mode == 'gelap' ? _gelap : _normal).trim(),
    ];

    if (!character.isEmpty) {
      parts.add(_fill(_charTpl, {
        'name': character.name,
        'age': character.age,
        'personality': character.personality,
        'likes': character.likes,
        'secret': character.secret,
      }));
    }

    if (!story.isEmpty) {
      parts.add(_fill(_storyTpl, {
        'genres': story.genres.join(', '),
        'place': story.place,
        'time': story.time,
      }));
    }

    return parts.join('\n\n');
  }

  static String _fill(String tpl, Map<String, String> values) {
    var out = tpl;
    values.forEach((key, value) {
      final v = value.trim().isEmpty ? '(tidak ditentukan)' : value.trim();
      out = out.replaceAll('{{$key}}', v);
    });
    return out.trim();
  }
}
