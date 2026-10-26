import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color ink = Color(0xFF202A44);
const Color violet = Color(0xFF6D5CE8);
const Color canvas = Color(0xFFF6F7FB);
const String storageKey = 'memonest_notes_v1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MemoNestApp());
}

class MemoNestApp extends StatelessWidget {
  const MemoNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: violet),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: violet, width: 1.5),
          ),
        ),
      ),
      home: const MemoNestHome(),
    );
  }
}

class MemoNote {
  MemoNote({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.colorValue,
    required this.updatedAt,
    this.pinned = false,
    this.tags = const [],
  });

  final String id;
  String title;
  String body;
  String category;
  int colorValue;
  DateTime updatedAt;
  bool pinned;
  List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'colorValue': colorValue,
        'updatedAt': updatedAt.toIso8601String(),
        'pinned': pinned,
        'tags': tags,
      };

  factory MemoNote.fromJson(Map<String, dynamic> json) => MemoNote(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Untitled note',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'Personal',
        colorValue: json['colorValue'] as int? ?? 0xFFEDE9FE,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        pinned: json['pinned'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

const categories = ['All notes', 'Study', 'Ideas', 'Projects', 'Personal'];
const noteColors = <int>[
  0xFFEDE9FE,
  0xFFE0F2FE,
  0xFFDCFCE7,
  0xFFFFF1D6,
  0xFFFFE4E6,
];

List<MemoNote> starterNotes() => [
      MemoNote(
        id: 'seed-1',
        title: 'Machine Learning — quick revision',
        body: 'Linear regression predicts a continuous value.\n\n• Simple regression uses one input feature.\n• Multiple regression uses two or more input features.\n• MSE measures average squared prediction error.\n• R² describes how much variation the model explains.',
        category: 'Study',
        colorValue: noteColors[0],
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        pinned: true,
        tags: ['revision', 'ML'],
      ),
      MemoNote(
        id: 'seed-2',
        title: 'Mini-project ideas',
        body: 'Build small tools that solve a real student problem. Keep the interface clear, validate forms, save data locally, and make the web layout responsive.',
        category: 'Ideas',
        colorValue: noteColors[1],
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['flutter', 'planning'],
      ),
      MemoNote(
        id: 'seed-3',
        title: 'Project checklist',
        body: '□ Create the main screen\n□ Add search and filters\n□ Validate the editor form\n□ Test browser refresh persistence\n□ Verify the production web build',
        category: 'Projects',
        colorValue: noteColors[2],
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['checklist'],
      ),
      MemoNote(
        id: 'seed-4',
        title: 'A thought to keep',
        body: 'Progress is easier to maintain when the next action is small, specific, and visible.',
        category: 'Personal',
        colorValue: noteColors[3],
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        tags: ['inspiration'],
      ),
    ];

class MemoNestHome extends StatefulWidget {
  const MemoNestHome({super.key});

  @override
  State<MemoNestHome> createState() => _MemoNestHomeState();
}

class _MemoNestHomeState extends State<MemoNestHome> {
  List<MemoNote> _notes = [];
  bool _loading = true;
  String _query = '';
  String _category = 'All notes';
  bool _pinnedOnly = false;
  String _sort = 'Recently updated';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      final loaded = <MemoNote>[];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              try {
                loaded.add(MemoNote.fromJson(Map<String, dynamic>.from(item)));
              } catch (_) {
                // Skip one malformed record instead of failing the whole collection.
              }
            }
          }
        }
      }
      if (loaded.isEmpty && raw == null) {
        loaded.addAll(starterNotes());
        await _saveNotes(loaded);
      }
      if (!mounted) return;
      setState(() {
        _notes = loaded;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notes = starterNotes();
        _loading = false;
      });
      _message('Could not read browser storage. Sample notes are shown for this session.');
    }
  }

  Future<void> _saveNotes([List<MemoNote>? value]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode((value ?? _notes).map((note) => note.toJson()).toList()),
      );
    } catch (_) {
      if (mounted) _message('Could not save changes. Check browser storage settings.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<MemoNote> get _visibleNotes {
    final q = _query.trim().toLowerCase();
    final result = _notes.where((note) {
      final matchesQuery = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.body.toLowerCase().contains(q) ||
          note.category.toLowerCase().contains(q) ||
          note.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchesCategory = _category == 'All notes' || note.category == _category;
      return matchesQuery && matchesCategory && (!_pinnedOnly || note.pinned);
    }).toList();
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (_sort == 'Title A–Z') return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (_sort == 'Oldest first') return a.updatedAt.compareTo(b.updatedAt);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return result;
  }

  Future<void> _openEditor({MemoNote? note}) async {
    final result = await showDialog<MemoNote>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NoteEditorDialog(note: note),
    );
    if (result == null) return;
    setState(() {
      final index = _notes.indexWhere((n) => n.id == result.id);
      if (index >= 0) {
        _notes[index] = result;
      } else {
        _notes.insert(0, result);
      }
    });
    await _saveNotes();
    _message(note == null ? 'Note added to your nest.' : 'Your note has been updated.');
  }

  Future<void> _togglePin(MemoNote note) async {
    setState(() => note.pinned = !note.pinned);
    await _saveNotes();
    _message(note.pinned ? 'Note pinned.' : 'Note unpinned.');
  }

  Future<void> _deleteNote(MemoNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: Text('"${note.title}" will be removed from this browser.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC4545)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete note'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _saveNotes();
    _message('Note deleted.');
  }

  Future<void> _resetDemoNotes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore sample notes?'),
        content: const Text('This replaces your current notes with the original demo collection.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _notes = starterNotes());
      await _saveNotes();
      _message('Sample notes restored.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final notes = _visibleNotes;
    final pinnedCount = _notes.where((n) => n.pinned).length;
    final studyCount = _notes.where((n) => n.category == 'Study').length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: violet,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MemoNest', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                Text('A little space for big thoughts',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7B8195))),
              ],
            ),
          ],
        ),
        actions: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: OutlinedButton.icon(
                onPressed: _resetDemoNotes,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Restore demo data'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE8E4FF),
              child: const Icon(Icons.person_rounded, color: violet),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) _sidePanel(width, pinnedCount, studyCount),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(compact ? 16 : 30, 20, compact ? 16 : 30, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _welcomeBanner(compact),
                        const SizedBox(height: 22),
                        _statsRow(compact, _notes.length, pinnedCount, studyCount),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Your collection',
                                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: ink)),
                            ),
                            Text('${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                                style: const TextStyle(color: Color(0xFF7B8195))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _searchAndSort(compact),
                        const SizedBox(height: 12),
                        _categoryChips(compact),
                        const SizedBox(height: 18),
                        if (notes.isEmpty)
                          _emptyState()
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 1120
                                  ? 3
                                  : constraints.maxWidth >= 650
                                      ? 2
                                      : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: notes.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 248,
                                ),
                                itemBuilder: (context, index) => _noteCard(notes[index]),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                        if (compact)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _pinnedOnly = !_pinnedOnly),
                                icon: const Icon(Icons.push_pin_outlined),
                                label: Text(_pinnedOnly ? 'Show all notes' : 'Pinned notes'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _resetDemoNotes,
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Restore demo data'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sidePanel(double width, int pinnedCount, int studyCount) {
    return Container(
      width: width >= 1200 ? 240 : 205,
      margin: const EdgeInsets.only(left: 18, top: 18, bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Text('WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Color(0xFF9398A8), fontWeight: FontWeight.bold)),
          ),
          _sideItem(Icons.grid_view_rounded, 'All notes', _category == 'All notes' && !_pinnedOnly,
              () => setState(() { _category = 'All notes'; _pinnedOnly = false; })),
          _sideItem(Icons.push_pin_rounded, 'Pinned', _pinnedOnly, () => setState(() => _pinnedOnly = !_pinnedOnly),
              trailing: '$pinnedCount'),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text('CATEGORIES', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Color(0xFF9398A8), fontWeight: FontWeight.bold)),
          ),
          _sideItem(Icons.school_rounded, 'Study', _category == 'Study', () => setState(() { _category = 'Study'; _pinnedOnly = false; }), trailing: '$studyCount'),
          _sideItem(Icons.lightbulb_outline_rounded, 'Ideas', _category == 'Ideas', () => setState(() { _category = 'Ideas'; _pinnedOnly = false; })),
          _sideItem(Icons.rocket_launch_outlined, 'Projects', _category == 'Projects', () => setState(() { _category = 'Projects'; _pinnedOnly = false; })),
          _sideItem(Icons.favorite_border_rounded, 'Personal', _category == 'Personal', () => setState(() { _category = 'Personal'; _pinnedOnly = false; })),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF4F1FF), borderRadius: BorderRadius.circular(18)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa_outlined, color: violet),
                SizedBox(height: 8),
                Text('Small thoughts matter.', style: TextStyle(fontWeight: FontWeight.bold, color: ink)),
                SizedBox(height: 4),
                Text('Save a thought today. Thank yourself later.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF72758C), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String label, bool selected, VoidCallback onTap, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFFF0EDFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 19, color: selected ? violet : const Color(0xFF858A9C)),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? violet : ink, fontSize: 13))),
                if (trailing != null) Text(trailing, style: const TextStyle(color: Color(0xFF8B8FA0), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeBanner(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D5CE8), Color(0xFF8D7FF2), Color(0xFFB6A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR MIND, UNCLUTTERED', style: TextStyle(color: Color(0xFFE5E0FF), fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Keep the good\nthoughts close.',
                    style: TextStyle(color: Colors.white, fontSize: compact ? 25 : 32, height: 1.1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Ideas, study notes, and plans — all in one calm place.',
                    style: TextStyle(color: Color(0xFFF1EEFF), fontSize: 13, height: 1.4)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: violet),
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Capture a thought'),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 18),
            Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 74),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsRow(bool compact, int total, int pinned, int study) {
    final cards = [
      _statCard('All notes', '$total', Icons.notes_rounded, const Color(0xFFEDE9FE), violet),
      _statCard('Pinned', '$pinned', Icons.push_pin_rounded, const Color(0xFFFFF1D6), const Color(0xFFB7791F)),
      _statCard('Study notes', '$study', Icons.school_rounded, const Color(0xFFDCFCE7), const Color(0xFF16845B)),
    ];
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9EAF2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: fg, size: 18)),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF858A9C))),
        ],
      ),
    );
  }

  Widget _searchAndSort(bool compact) {
    return compact
        ? Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search title, content, category, or tag...',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              _sortDropdown(),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search title, content, category, or tag...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: _sortDropdown()),
            ],
          );
  }

  Widget _sortDropdown() => DropdownButtonFormField<String>(
        value: _sort,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.sort_rounded), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        items: const [
          DropdownMenuItem(value: 'Recently updated', child: Text('Recently updated', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: 'Oldest first', child: Text('Oldest first')),
          DropdownMenuItem(value: 'Title A–Z', child: Text('Title A–Z')),
        ],
        onChanged: (value) => setState(() => _sort = value ?? 'Recently updated'),
      );

  Widget _categoryChips(bool compact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: _category == category && !_pinnedOnly,
                onSelected: (_) => setState(() { _category = category; _pinnedOnly = false; }),
                selectedColor: const Color(0xFFE8E3FF),
                labelStyle: TextStyle(
                  color: _category == category && !_pinnedOnly ? violet : const Color(0xFF72778B),
                  fontWeight: _category == category && !_pinnedOnly ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(color: _category == category && !_pinnedOnly ? const Color(0xFFD4CCFF) : const Color(0xFFE4E6EF)),
                backgroundColor: Colors.white,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: const Icon(Icons.push_pin_outlined, size: 15),
              label: const Text('Pinned only'),
              selected: _pinnedOnly,
              onSelected: (value) => setState(() => _pinnedOnly = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(MemoNote note) {
    final tint = Color(note.colorValue);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showNoteDetails(note),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9EAF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_categoryIcon(note.category), color: ink, size: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: note.pinned ? 'Unpin note' : 'Pin note',
                    onPressed: () => _togglePin(note),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        color: note.pinned ? violet : const Color(0xFF9A9EAE), size: 19),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Note actions',
                    onSelected: (value) {
                      if (value == 'edit') _openEditor(note: note);
                      if (value == 'delete') _deleteNote(note);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                      PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'), contentPadding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: ink, fontSize: 16, height: 1.25)),
              const SizedBox(height: 8),
              Expanded(
                child: Text(note.body, maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.55, color: Color(0xFF777D90))),
              ),
              if (note.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: note.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F8), borderRadius: BorderRadius.circular(8)),
                      child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Color(0xFF777D90))),
                    )).toList(),
                  ),
                ),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: violet, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(width: 6),
                  Expanded(child: Text(note.category, style: const TextStyle(fontSize: 11, color: Color(0xFF777D90)))),
                  Text(_formatDate(note.updatedAt), style: const TextStyle(fontSize: 10, color: Color(0xFF9A9EAE))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(MemoNote note) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(note.title)),
            if (note.pinned) const Icon(Icons.push_pin_rounded, color: violet, size: 20),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(label: Text(note.category)),
                const SizedBox(height: 8),
                SelectableText(note.body.isEmpty ? 'This note has no content yet.' : note.body,
                    style: const TextStyle(height: 1.6)),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(spacing: 6, children: note.tags.map((tag) => Chip(label: Text('#$tag'))).toList()),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openEditor(note: note);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit note'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE9EAF2))),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, color: violet, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Nothing in this corner yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: ink)),
          const SizedBox(height: 7),
          const Text('Try another search or create a note to get started.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF858A9C))),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add), label: const Text('Create a note')),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school_rounded;
      case 'Ideas':
        return Icons.lightbulb_outline_rounded;
      case 'Projects':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.favorite_border_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return 'Today';
    }
    if (now.difference(date).inDays == 1) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class NoteEditorDialog extends StatefulWidget {
  const NoteEditorDialog({super.key, this.note});
  final MemoNote? note;

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _tagsController;
  late String _category;
  late int _colorValue;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _bodyController = TextEditingController(text: note?.body ?? '');
    _tagsController = TextEditingController(text: note?.tags.join(', ') ?? '');
    _category = note?.category ?? 'Study';
    _colorValue = note?.colorValue ?? noteColors[0];
    _pinned = note?.pinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim().replaceAll(RegExp(r'^#+'), ''))
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    final old = widget.note;
    Navigator.pop(
      context,
      MemoNote(
        id: old?.id ?? now.microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        category: _category,
        colorValue: _colorValue,
        updatedAt: now,
        pinned: _pinned,
        tags: tags,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 32, vertical: 24),
      title: Text(widget.note == null ? 'Capture a thought' : 'Edit your note',
          style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Note title', hintText: 'Give this thought a name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter a title.';
                    if (value.trim().length < 2) return 'Title must contain at least 2 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.folder_open_outlined)),
                  items: categories.where((item) => item != 'All notes').map((category) =>
                      DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) => setState(() => _category = value ?? 'Study'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: 3000,
                  decoration: const InputDecoration(labelText: 'Your note', hintText: 'Write down the details while they are fresh...'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Add a few details before saving.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(labelText: 'Tags (optional)', hintText: 'exam, ideas, important'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Card color', style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: noteColors.map((value) => InkWell(
                    onTap: () => setState(() => _colorValue = value),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(color: _colorValue == value ? violet : const Color(0xFFD9DCE7), width: _colorValue == value ? 3 : 1),
                      ),
                      child: _colorValue == value ? const Icon(Icons.check_rounded, size: 18, color: ink) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pin this note'),
                  subtitle: const Text('Keep it near the top of your collection'),
                  value: _pinned,
                  onChanged: (value) => setState(() => _pinned = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: violet, foregroundColor: Colors.white),
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save note'),
        ),
      ],
    );
  }
}
