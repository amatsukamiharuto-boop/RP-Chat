import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

class StoryScreen extends StatefulWidget {
  final AppState state;
  const StoryScreen({super.key, required this.state});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  late final TextEditingController _place;
  late final TextEditingController _time;
  final Set<String> _selected = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    final s = widget.state.story;
    _place = TextEditingController(text: s.place);
    _time = TextEditingController(text: s.time);
    _selected.addAll(s.genres);
  }

  @override
  void dispose() {
    _place.dispose();
    _time.dispose();
    super.dispose();
  }

  List<String> get _visibleGenres {
    final q = _query.trim().toLowerCase();
    final all = widget.state.allGenres;
    if (q.isEmpty) return all;
    return all.where((g) => g.toLowerCase().contains(q)).toList();
  }

  Future<void> _save() async {
    await widget.state.saveStory(StoryConfig(
      genres: _selected.toList(),
      place: _place.text.trim(),
      time: _time.text.trim(),
    ));
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cerita disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = _visibleGenres;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Section(
          title: 'Genre',
          icon: Icons.theater_comedy_outlined,
          subtitle:
              'Pilih satu atau lebih (disarankan 1 sampai 3). Daftar genre bisa kamu ubah di file assets/genres.txt.',
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: inputDeco('Cari genre', icon: Icons.search_rounded),
            ),
            if (genres.isEmpty)
              const Text('Tidak ada genre yang cocok.', style: TextStyle(color: kMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in genres)
                    FilterChip(
                      label: Text(g),
                      selected: _selected.contains(g),
                      showCheckmark: false,
                      backgroundColor: kField,
                      selectedColor: const Color(0xFF4A3FA8),
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: _selected.contains(g) ? kAccent : const Color(0x22FFFFFF),
                      ),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selected.add(g);
                          } else {
                            _selected.remove(g);
                          }
                        });
                      },
                    ),
                ],
              ),
            Text(
              'Terpilih: ${_selected.isEmpty ? 'belum ada' : _selected.join(', ')}',
              style: const TextStyle(color: kMuted, fontSize: 12.5),
            ),
          ],
        ),
        Section(
          title: 'Tempat dan waktu',
          icon: Icons.map_outlined,
          children: [
            TextField(
              controller: _place,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Tempat',
                hint: 'Kota pelabuhan yang diselimuti kabut',
                icon: Icons.place_outlined,
              ),
            ),
            TextField(
              controller: _time,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Latar waktu',
                hint: 'Malam hari musim hujan, tahun 1920',
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Simpan cerita'),
        ),
      ],
    );
  }
}
