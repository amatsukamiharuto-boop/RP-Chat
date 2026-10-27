import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

/// Identitas pengguna: karakter yang kamu mainkan sendiri di cerita.
class UserScreen extends StatefulWidget {
  final AppState state;
  const UserScreen({super.key, required this.state});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _identity;
  late final TextEditingController _hidden;

  @override
  void initState() {
    super.initState();
    final u = widget.state.user;
    _name = TextEditingController(text: u.name);
    _age = TextEditingController(text: u.age);
    _identity = TextEditingController(text: u.identity);
    _hidden = TextEditingController(text: u.hiddenIdentity);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _identity.dispose();
    _hidden.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.state.saveUser(UserProfile(
      name: _name.text.trim(),
      age: _age.text.trim(),
      identity: _identity.text.trim(),
      hiddenIdentity: _hidden.text.trim(),
    ));
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identitas disimpan')),
    );
  }

  Future<void> _clear() async {
    _name.clear();
    _age.clear();
    _identity.clear();
    _hidden.clear();
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Section(
          title: 'Dirimu di cerita',
          icon: Icons.account_circle_outlined,
          subtitle:
              'Karakter yang kamu mainkan sendiri. AI tidak akan menulis ucapan atau keputusanmu, hanya bereaksi terhadapnya.',
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Nama', hint: 'Contoh: Arya', icon: Icons.person_outline),
            ),
            TextField(
              controller: _age,
              decoration: inputDeco(
                'Umur',
                hint: 'Contoh: 24',
                icon: Icons.cake_outlined,
              ),
            ),
            TextField(
              controller: _identity,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Identitas',
                hint: 'Siapa kamu di mata orang lain: pekerjaan, status, penampilan...',
              ),
            ),
          ],
        ),
        Section(
          title: 'Identitas tersembunyi',
          icon: Icons.visibility_off_outlined,
          subtitle:
              'Hanya kamu yang tahu. Karakter lain tidak akan tahu kecuali kamu sendiri yang membukanya lewat cerita.',
          children: [
            TextField(
              controller: _hidden,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Rahasia identitasmu',
                hint: 'Contoh: sebenarnya mata-mata kerajaan yang menyamar jadi pedagang.',
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
                label: const Text('Simpan identitas'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
