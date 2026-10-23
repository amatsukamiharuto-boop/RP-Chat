import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late String _mode;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    final s = widget.state.settings;
    _apiKey = TextEditingController(text: s.apiKey);
    _model = TextEditingController(text: s.model);
    _mode = s.mode;
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final model = _model.text.trim();
    await widget.state.saveSettings(AppSettings(
      apiKey: _apiKey.text.trim(),
      model: model.isEmpty ? 'gemini-2.5-flash' : model,
      mode: _mode,
    ));
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setelan disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Section(
          title: 'Gemini',
          icon: Icons.key_rounded,
          subtitle:
              'API key bisa dibuat gratis di aistudio.google.com. Key hanya disimpan di perangkat ini.',
          children: [
            TextField(
              controller: _apiKey,
              obscureText: !_showKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: inputDeco('API key', hint: 'AIza...', icon: Icons.vpn_key_outlined)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            TextField(
              controller: _model,
              autocorrect: false,
              decoration: inputDeco(
                'Model',
                hint: 'gemini-2.5-flash',
                helper: 'Contoh: gemini-2.5-flash atau gemini-2.5-pro',
                icon: Icons.memory_rounded,
              ),
            ),
          ],
        ),
        Section(
          title: 'Mode cerita',
          icon: Icons.tune_rounded,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'normal',
                    label: Text('Normal'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: 'gelap',
                    label: Text('Gelap'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            Text(
              _mode == 'normal'
                  ? 'Konten SFW: romansa ringan, humor, petualangan.'
                  : 'Tema dewasa dan gelap (horor, thriller, perang, moral abu-abu). Adegan intim hanya tersirat, tanpa seks eksplisit.',
              style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Simpan setelan'),
        ),
        const SizedBox(height: 24),
        Section(
          title: 'Reset',
          icon: Icons.delete_sweep_outlined,
          subtitle: 'Menghapus semua percakapan. Karakter dan cerita tetap tersimpan.',
          children: [
            OutlinedButton.icon(
              onPressed: () => confirmReset(context, widget.state),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Reset percakapan'),
            ),
          ],
        ),
      ],
    );
  }
}
