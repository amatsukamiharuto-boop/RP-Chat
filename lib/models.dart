class AppSettings {
  final String apiKey;
  final String model;
  final String mode; // 'normal' atau 'gelap'

  // Suara (text-to-speech)
  final bool ttsAuto; // bacakan balasan baru otomatis
  final bool ttsDialogOnly; // hanya bacakan isi "dialog"
  final String ttsVoice; // nama suara; kosong = bawaan sistem
  final String ttsLocale; // contoh: id-ID
  final double ttsRate; // 0.2 - 1.0
  final double ttsPitch; // 0.8 - 1.6

  const AppSettings({
    this.apiKey = '',
    this.model = 'gemini-3.5-flash-lite',
    this.mode = 'normal',
    this.ttsAuto = false,
    this.ttsDialogOnly = false,
    this.ttsVoice = '',
    this.ttsLocale = 'id-ID',
    this.ttsRate = 0.5,
    this.ttsPitch = 1.15,
  });

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'model': model,
        'mode': mode,
        'ttsAuto': ttsAuto,
        'ttsDialogOnly': ttsDialogOnly,
        'ttsVoice': ttsVoice,
        'ttsLocale': ttsLocale,
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        apiKey: (j['apiKey'] ?? '') as String,
        model: (j['model'] ?? 'gemini-3.5-flash-lite') as String,
        mode: (j['mode'] ?? 'normal') as String,
        ttsAuto: (j['ttsAuto'] ?? false) as bool,
        ttsDialogOnly: (j['ttsDialogOnly'] ?? false) as bool,
        ttsVoice: (j['ttsVoice'] ?? '') as String,
        ttsLocale: (j['ttsLocale'] ?? 'id-ID') as String,
        ttsRate: ((j['ttsRate'] ?? 0.5) as num).toDouble(),
        ttsPitch: ((j['ttsPitch'] ?? 1.15) as num).toDouble(),
      );
}

/// Karakter utama yang diperankan AI.
class CharProfile {
  final String name;
  final String age;
  final String personality;
  final String likes;
  final String secret;

  const CharProfile({
    this.name = '',
    this.age = '',
    this.personality = '',
    this.likes = '',
    this.secret = '',
  });

  bool get isEmpty =>
      name.isEmpty && age.isEmpty && personality.isEmpty && likes.isEmpty && secret.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'personality': personality,
        'likes': likes,
        'secret': secret,
      };

  factory CharProfile.fromJson(Map<String, dynamic> j) => CharProfile(
        name: (j['name'] ?? '') as String,
        age: (j['age'] ?? '') as String,
        personality: (j['personality'] ?? '') as String,
        likes: (j['likes'] ?? '') as String,
        secret: (j['secret'] ?? '') as String,
      );
}

/// Identitas pengguna (karakter yang kamu mainkan sendiri).
class UserProfile {
  final String name;
  final String age;
  final String identity;
  final String hiddenIdentity;

  const UserProfile({
    this.name = '',
    this.age = '',
    this.identity = '',
    this.hiddenIdentity = '',
  });

  bool get isEmpty =>
      name.isEmpty && age.isEmpty && identity.isEmpty && hiddenIdentity.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'identity': identity,
        'hiddenIdentity': hiddenIdentity,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] ?? '') as String,
        age: (j['age'] ?? '') as String,
        identity: (j['identity'] ?? '') as String,
        hiddenIdentity: (j['hiddenIdentity'] ?? '') as String,
      );
}

/// Tokoh tambahan di cerita. Bisa digerakkan AI atau oleh pengguna.
class Npc {
  final String name;
  final String age;
  final String description;
  final bool userControlled;

  const Npc({
    this.name = '',
    this.age = '',
    this.description = '',
    this.userControlled = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'description': description,
        'userControlled': userControlled,
      };

  factory Npc.fromJson(Map<String, dynamic> j) => Npc(
        name: (j['name'] ?? '') as String,
        age: (j['age'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        userControlled: (j['userControlled'] ?? false) as bool,
      );
}

class StoryConfig {
  final List<String> genres;
  final String place;
  final String time;
  final List<Npc> npcs;

  const StoryConfig({
    this.genres = const [],
    this.place = '',
    this.time = '',
    this.npcs = const [],
  });

  bool get isEmpty => genres.isEmpty && place.isEmpty && time.isEmpty;

  Map<String, dynamic> toJson() => {
        'genres': genres,
        'place': place,
        'time': time,
        'npcs': npcs.map((n) => n.toJson()).toList(),
      };

  factory StoryConfig.fromJson(Map<String, dynamic> j) => StoryConfig(
        genres: ((j['genres'] ?? []) as List).map((e) => e.toString()).toList(),
        place: (j['place'] ?? '') as String,
        time: (j['time'] ?? '') as String,
        npcs: ((j['npcs'] ?? []) as List)
            .map((e) => Npc.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ChatMessage {
  final String role; // 'user' atau 'model'
  final String text;
  final bool hidden;

  /// Nama NPC yang sedang digerakkan pengguna. Kosong = karakter pengguna sendiri.
  final String? speaker;

  const ChatMessage({
    required this.role,
    required this.text,
    this.hidden = false,
    this.speaker,
  });

  /// Teks yang dikirim ke Gemini. Pesan NPC diberi awalan [Nama].
  String get requestText {
    final s = speaker;
    if (role == 'user' && s != null && s.isNotEmpty) return '[$s] $text';
    return text;
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'hidden': hidden,
        'speaker': speaker,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: (j['role'] ?? 'user') as String,
        text: (j['text'] ?? '') as String,
        hidden: (j['hidden'] ?? false) as bool,
        speaker: j['speaker'] as String?,
      );
}
