class AppSettings {
  final String apiKey;
  final String model;
  final String mode; // 'normal' atau 'gelap'

  const AppSettings({
    this.apiKey = '',
    this.model = 'gemini-3.5-flash-lite',
    this.mode = 'normal',
  });

  Map<String, dynamic> toJson() => {'apiKey': apiKey, 'model': model, 'mode': mode};

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        apiKey: (j['apiKey'] ?? '') as String,
        model: (j['model'] ?? 'gemini-3.5-flash-lite') as String,
        mode: (j['mode'] ?? 'normal') as String,
      );
}

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

class StoryConfig {
  final List<String> genres;
  final String place;
  final String time;

  const StoryConfig({
    this.genres = const [],
    this.place = '',
    this.time = '',
  });

  bool get isEmpty => genres.isEmpty && place.isEmpty && time.isEmpty;

  Map<String, dynamic> toJson() => {'genres': genres, 'place': place, 'time': time};

  factory StoryConfig.fromJson(Map<String, dynamic> j) => StoryConfig(
        genres: ((j['genres'] ?? []) as List).map((e) => e.toString()).toList(),
        place: (j['place'] ?? '') as String,
        time: (j['time'] ?? '') as String,
      );
}

class ChatMessage {
  final String role; // 'user' atau 'model'
  final String text;
  final bool hidden;

  const ChatMessage({required this.role, required this.text, this.hidden = false});

  Map<String, dynamic> toJson() => {'role': role, 'text': text, 'hidden': hidden};

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: (j['role'] ?? 'user') as String,
        text: (j['text'] ?? '') as String,
        hidden: (j['hidden'] ?? false) as bool,
      );
}
