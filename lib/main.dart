import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const GestaoAtletasApp());
}

class GestaoAtletasApp extends StatefulWidget {
  const GestaoAtletasApp({super.key});

  @override
  State<GestaoAtletasApp> createState() => _GestaoAtletasAppState();
}

class _GestaoAtletasAppState extends State<GestaoAtletasApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Atletas',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
        primaryColor: const Color(0xFF00684A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00684A),
          primary: const Color(0xFF00684A),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFC5F068),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF00684A),
        ),
        useMaterial3: true,
      ),
      home: MainNavigationPage(onToggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestao_atletas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE turmas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            descricao TEXT,
            dia_semana TEXT NOT NULL,
            horario TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE atletas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            celular TEXT,
            aniversario TEXT,
            observacao TEXT,
            status TEXT NOT NULL DEFAULT 'Ativo'
          )
        ''');

        await db.execute('''
          CREATE TABLE turma_atletas (
            turma_id INTEGER NOT NULL,
            atleta_id INTEGER NOT NULL,
            PRIMARY KEY (turma_id, atleta_id),
            FOREIGN KEY (turma_id) REFERENCES turmas (id) ON DELETE CASCADE,
            FOREIGN KEY (atleta_id) REFERENCES atletas (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE chamadas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            atleta_id INTEGER NOT NULL,
            turma_id INTEGER NOT NULL,
            data TEXT NOT NULL,
            status_chamada TEXT NOT NULL,
            observacao TEXT,
            FOREIGN KEY (atleta_id) REFERENCES atletas (id) ON DELETE CASCADE,
            FOREIGN KEY (turma_id) REFERENCES turmas (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainNavigationPage({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        onIrParaChamada: () => setState(() => _currentIndex = 1),
      ),
      const PlaceholderPage(title: 'Chamada'),
      const PlaceholderPage(title: 'Atletas'),
      const PlaceholderPage(title: 'Turmas'),
      const PlaceholderPage(title: 'Mais'),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: const Color(0xFFC5F068),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Chamada'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Atletas'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Turmas'),
          NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: 'Mais'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final VoidCallback onIrParaChamada;

  const HomePage({super.key, required this.onToggleTheme, required this.isDarkMode, required this.onIrParaChamada});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final dataFormatada = DateFormat("EEEE, d 'De' MMMM", 'pt_BR').format(hoje);
    final dataCapitalizada = dataFormatada[0].toUpperCase() + dataFormatada.substring(1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF00684A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dataCapitalizada, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        IconButton(
                          icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.white),
                          onPressed: onToggleTheme,
                        ),
                      ],
                    ),
                    const Text('Gestão de Atletas', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC5F068),
                          foregroundColor: const Color(0xFF003824),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: onIrParaChamada,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Fazer chamada de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Icon(Icons.check_circle_outline, color: Color(0xFF00684A), size: 64),
              const SizedBox(height: 12),
              const Text('Aplicativo pronto e configurado!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Tela de $title')),
    );
  }
}
