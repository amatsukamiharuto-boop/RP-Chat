import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../tts_service.dart';
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

  // Suara
  late bool _ttsAuto;
  late bool _dialogOnly;
  late String _voice;
  late String _locale;
  late double _rate;
  late double _pitch;
  List<VoiceInfo> _voices = [];
  bool _loadingVoices = true;

  @override
  void initState() {
    super.initState();
    final s = widget.state.settings;
    _apiKey = TextEditingController(text: s.apiKey);
    _model = TextEditingController(text: s.model);
    _mode = s.mode;
    _ttsAuto = s.ttsAuto;
    _dialogOnly = s.ttsDialogOnly;
    _voice = s.ttsVoice;
    _locale = s.ttsLocale;
    _rate = s.ttsRate.clamp(0.2, 1.0).toDouble();
    _pitch = s.ttsPitch.clamp(0.8, 1.6).toDouble();
    _loadVoices();
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _model.dispose();
    widget.state.tts.stop();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    final v = await widget.state.tts.voices();
    if (!mounted) return;
    setState(() {
      _voices = v;
      _loadingVoices = false;
    });
  }

  /// Suara Indonesia dulu; kalau HP tidak punya, tampilkan semua.
  List<VoiceInfo> get _shownVoices {
    final id = _voices.where((v) {
      final l = v.locale.toLowerCase();
      return l.startsWith('id') || l.startsWith('in');
    }).toList();
    return id.isEmpty ? _voices : id;
  }

  AppSettings _draft() => AppSettings(
        apiKey: _apiKey.text.trim(),
        model: _model.text.trim().isEmpty ? 'gemini-3.5-flash-lite' : _model.text.trim(),
        mode: _mode,
        ttsAuto: _ttsAuto,
        ttsDialogOnly: _dialogOnly,
        ttsVoice: _voice,
        ttsLocale: _locale,
        ttsRate: _rate,
        ttsPitch: _pitch,
      );

  Future<void> _save() async {
    await widget.state.saveSettings(_draft());
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setelan disimpan')),
    );
  }

  Future<void> _preview() async {
    await widget.state.tts.speak(
      'Halo, aku akan menemani ceritamu malam ini.',
      _draft(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shownVoices;
    final selected = shown.any((v) => v.name == _voice) ? _voice : '';

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
                hint: 'gemini-3.5-flash-lite',
                helper: 'Contoh: gemini-2.5-flash atau gemini-3.5-flash-lite',
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
        Section(
          title: 'Suara',
          icon: Icons.record_voice_over_outlined,
          subtitle:
              'Balasan bisa dibacakan. Ketuk ikon speaker di bubble untuk membaca satu balasan. Suara memakai mesin text-to-speech bawaan HP.',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ttsAuto,
              onChanged: (v) => setState(() => _ttsAuto = v),
              title: const Text('Bacakan balasan baru otomatis'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _dialogOnly,
              onChanged: (v) => setState(() => _dialogOnly = v),
              title: const Text('Hanya bacakan dialog'),
              subtitle: const Text(
                'Teks di dalam tanda kutip saja, narasi dilewati.',
                style: TextStyle(color: kMuted, fontSize: 12.5),
              ),
            ),
            if (_loadingVoices)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Memuat daftar suara...', style: TextStyle(color: kMuted)),
                ],
              )
            else if (shown.isEmpty)
              const Text(
                'Daftar suara tidak ditemukan. Pasang atau aktifkan mesin Text-to-speech di pengaturan HP (Google Text-to-speech), lalu buka ulang app.',
                style: TextStyle(color: Color(0xFFFFC857), fontSize: 12.5, height: 1.4),
              )
            else
              DropdownButtonFormField<String>(
                value: selected,
                isExpanded: true,
                decoration: inputDeco('Suara', icon: Icons.graphic_eq_rounded),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Bawaan sistem')),
                  for (final v in shown)
                    DropdownMenuItem(
                      value: v.name,
                      child: Text('${v.name}  (${v.locale})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (name) {
                  setState(() {
                    _voice = name ?? '';
                    final match = shown.where((v) => v.name == _voice);
                    if (match.isNotEmpty) _locale = match.first.locale;
                  });
                },
              ),
            const Text(
              'Android tidak memberi tahu mana suara perempuan. Coba satu per satu dengan tombol Tes suara, lalu pilih yang kamu suka.',
              style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.4),
            ),
            Text('Kecepatan: ${_rate.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13)),
            Slider(
              value: _rate,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              onChanged: (v) => setState(() => _rate = v),
            ),
            Text('Nada: ${_pitch.toStringAsFixed(2)}  (lebih tinggi = lebih feminin)',
                style: const TextStyle(fontSize: 13)),
            Slider(
              value: _pitch,
              min: 0.8,
              max: 1.6,
              divisions: 16,
              onChanged: (v) => setState(() => _pitch = v),
            ),
            OutlinedButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Tes suara'),
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
