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
  final List<Npc> _npcs = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    final s = widget.state.story;
    _place = TextEditingController(text: s.place);
    _time = TextEditingController(text: s.time);
    _selected.addAll(s.genres);
    _npcs.addAll(s.npcs);
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

  Future<void> _persist({bool toast = true}) async {
    await widget.state.saveStory(StoryConfig(
      genres: _selected.toList(),
      place: _place.text.trim(),
      time: _time.text.trim(),
      npcs: List<Npc>.from(_npcs),
    ));
    if (!mounted || !toast) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cerita disimpan')),
    );
  }

  Future<void> _editNpc({int? index}) async {
    final result = await showModalBottomSheet<Npc>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14152A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NpcSheet(initial: index == null ? null : _npcs[index]),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _npcs.add(result);
      } else {
        _npcs[index] = result;
      }
    });
    await _persist(toast: false);
  }

  Future<void> _deleteNpc(int index) async {
    setState(() => _npcs.removeAt(index));
    await _persist(toast: false);
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
        Section(
          title: 'Tokoh tambahan (NPC)',
          icon: Icons.groups_2_outlined,
          subtitle:
              'Tokoh lain yang ikut di cerita. Tiap NPC bisa digerakkan AI, atau kamu sendiri yang menulis ucapan dan tindakannya (pilih lewat chip di atas kolom chat).',
          children: [
            if (_npcs.isEmpty)
              const Text('Belum ada NPC.', style: TextStyle(color: kMuted))
            else
              for (var i = 0; i < _npcs.length; i++)
                _NpcTile(
                  npc: _npcs[i],
                  onTap: () => _editNpc(index: i),
                  onDelete: () => _deleteNpc(i),
                ),
            OutlinedButton.icon(
              onPressed: () => _editNpc(),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Tambah NPC'),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: _persist,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Simpan cerita'),
        ),
      ],
    );
  }
}

class _NpcTile extends StatelessWidget {
  final Npc npc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NpcTile({required this.npc, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final info = [
      if (npc.age.trim().isNotEmpty) 'Umur ${npc.age.trim()}',
      if (npc.description.trim().isNotEmpty) npc.description.trim(),
    ].join('  •  ');
    final initial = npc.name.trim().isEmpty ? '?' : npc.name.trim()[0].toUpperCase();

    return Material(
      color: kField,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4A3FA8),
                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            npc.name.trim().isEmpty ? '(tanpa nama)' : npc.name.trim(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: npc.userControlled
                                ? const Color(0x33FFC857)
                                : const Color(0x338B7CFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            npc.userControlled ? 'Kamu' : 'AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: npc.userControlled
                                  ? const Color(0xFFFFD28A)
                                  : const Color(0xFFC9C4FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (info.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          info,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus NPC',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NpcSheet extends StatefulWidget {
  final Npc? initial;
  const _NpcSheet({this.initial});

  @override
  State<_NpcSheet> createState() => _NpcSheetState();
}

class _NpcSheetState extends State<_NpcSheet> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _desc;
  late bool _mine;
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    final n = widget.initial;
    _name = TextEditingController(text: n?.name ?? '');
    _age = TextEditingController(text: n?.age ?? '');
    _desc = TextEditingController(text: n?.description ?? '');
    _mine = n?.userControlled ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    Navigator.pop(
      context,
      Npc(
        name: name,
        age: _age.text.trim(),
        description: _desc.text.trim(),
        userControlled: _mine,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initial == null ? 'Tambah NPC' : 'Ubah NPC',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError) setState(() => _nameError = false);
              },
              decoration: inputDeco('Nama', hint: 'Contoh: Budi', icon: Icons.person_outline)
                  .copyWith(errorText: _nameError ? 'Nama wajib diisi' : null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _age,
              decoration: inputDeco('Umur', hint: 'Contoh: 30', icon: Icons.cake_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDeco(
                'Peran dan sifat',
                hint: 'Pedagang licik yang diam-diam setia pada sahabatnya...',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _mine,
              onChanged: (v) => setState(() => _mine = v),
              title: const Text('Aku yang kendalikan'),
              subtitle: Text(
                _mine
                    ? 'Kamu yang menulis ucapan dan tindakannya. AI hanya bereaksi.'
                    : 'AI yang menggerakkan NPC ini di dalam cerita.',
                style: const TextStyle(color: kMuted, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan NPC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
