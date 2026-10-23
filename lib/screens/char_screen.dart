import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

class CharScreen extends StatefulWidget {
  final AppState state;
  const CharScreen({super.key, required this.state});

  @override
  State<CharScreen> createState() => _CharScreenState();
}

class _CharScreenState extends State<CharScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _personality;
  late final TextEditingController _likes;
  late final TextEditingController _secret;

  @override
  void initState() {
    super.initState();
    final c = widget.state.character;
    _name = TextEditingController(text: c.name);
    _age = TextEditingController(text: c.age);
    _personality = TextEditingController(text: c.personality);
    _likes = TextEditingController(text: c.likes);
    _secret = TextEditingController(text: c.secret);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _personality.dispose();
    _likes.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.state.saveCharacter(CharProfile(
      name: _name.text.trim(),
      age: _age.text.trim(),
      personality: _personality.text.trim(),
      likes: _likes.text.trim(),
      secret: _secret.text.trim(),
    ));
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Karakter disimpan')),
    );
  }

  Future<void> _clear() async {
    _name.clear();
    _age.clear();
    _personality.clear();
    _likes.clear();
    _secret.clear();
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Section(
          title: 'Identitas',
          icon: Icons.badge_outlined,
          subtitle: 'Karakter yang akan diperankan AI.',
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Nama', hint: 'Contoh: Rin', icon: Icons.person_outline),
            ),
            TextField(
              controller: _age,
              decoration: inputDeco(
                'Umur',
                hint: 'Contoh: 22, atau "ratusan tahun"',
                icon: Icons.cake_outlined,
              ),
            ),
          ],
        ),
        Section(
          title: 'Sifat dan selera',
          icon: Icons.favorite_border_rounded,
          children: [
            TextField(
              controller: _personality,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Kepribadian',
                hint: 'Sinis, pelindung, canggung kalau dipuji...',
              ),
            ),
            TextField(
              controller: _likes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Kesukaan',
                hint: 'Teh melati, hujan malam, buku tua...',
              ),
            ),
          ],
        ),
        Section(
          title: 'Rahasia',
          icon: Icons.lock_outline_rounded,
          subtitle:
              'Hanya diketahui karakter. AI tidak akan membukanya begitu saja, tapi membiarkannya terungkap pelan-pelan lewat cerita.',
          children: [
            TextField(
              controller: _secret,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Rahasia karakter',
                hint: 'Contoh: sebenarnya dia pewaris takhta yang melarikan diri.',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.layers_clear_outlined),
                label: const Text('Kosongkan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan karakter'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
