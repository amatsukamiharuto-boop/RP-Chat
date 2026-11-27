import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/char_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/story_screen.dart';
import 'screens/user_screen.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  try {
    await state.init();
  } catch (e, st) {
    runApp(StartupErrorApp(error: '$e\n\n$st'));
    return;
  }
  runApp(RpApp(state: state));
}

/// Ditampilkan kalau aplikasi gagal start, supaya penyebabnya terlihat
/// (bukan layar putih kosong).
class StartupErrorApp extends StatelessWidget {
  final String error;
  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aplikasi gagal start',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Screenshot layar ini dan kirim ke pembuat aplikasi.',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  error,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RpApp extends StatelessWidget {
  final AppState state;
  const RpApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C6CFF),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'RP Gemini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B0C16),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: HomeShell(state: state),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _titles = ['Chat', 'Set Karakter', 'Identitasku', 'Set Cerita', 'Setelan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Suara berhenti saat app ditinggalkan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      widget.state.stopSpeaking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16173A), Color(0xFF0B0C16)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _titles[_index],
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_index == 0)
              IconButton(
                tooltip: 'Hapus giliran terakhir',
                icon: const Icon(Icons.undo_rounded),
                onPressed: widget.state.undoLast,
              ),
            if (_index == 0)
              IconButton(
                tooltip: 'Reset percakapan',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => confirmReset(context, widget.state),
              ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: [
            ChatScreen(state: widget.state),
            CharScreen(state: widget.state),
            UserScreen(state: widget.state),
            StoryScreen(state: widget.state),
            SettingsScreen(state: widget.state),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF11121F),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Karakter',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: 'Aku',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Cerita',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Setelan',
            ),
          ],
        ),
      ),
    );
  }
}
