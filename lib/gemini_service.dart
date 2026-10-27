import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class GeminiService {
  Future<String> generate({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );

    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        for (final m in history)
          {
            'role': m.role,
            'parts': [
              {'text': m.requestText},
            ],
          },
      ],
      'generationConfig': {
        'maxOutputTokens': 4096,
        'temperature': 1.0,
      },
    };

    final res = await http
        .post(
          uri,
          headers: {
            'content-type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 120));

    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons tidak valid (HTTP ${res.statusCode}).');
    }

    if (res.statusCode != 200) {
      final err = data['error'];
      final msg = err is Map ? err['message'] : null;
      throw Exception(msg ?? 'HTTP ${res.statusCode}');
    }

    final cands = data['candidates'];
    if (cands is! List || cands.isEmpty) {
      final fb = data['promptFeedback'];
      final block = fb is Map ? fb['blockReason'] : null;
      throw Exception('Gemini tidak membalas (${block ?? 'kosong'}). Coba ubah kalimatmu.');
    }

    final first = cands.first as Map;
    final content = first['content'];
    final parts = content is Map ? content['parts'] : null;
    final text = parts is List
        ? parts.map((p) => (p is Map ? (p['text'] ?? '') : '').toString()).join()
        : '';

    if (text.trim().isEmpty) {
      throw Exception(
        'Balasan kosong (${first['finishReason'] ?? 'tidak diketahui'}). Coba kirim ulang atau ubah kalimatmu.',
      );
    }
    return text.trim();
  }
}
