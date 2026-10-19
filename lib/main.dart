import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
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
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        primaryColor: const Color(0xFF006847),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006847),
          primary: const Color(0xFF006847),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF80E080),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF006847),
        ),
        useMaterial3: true,
      ),
      home: MainNavigationPage(onToggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

// Helper SQLite Local
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
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
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
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final totalAtletas = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM atletas')) ?? 0;
    final totalTurmas = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM turmas')) ?? 0;
    final totalReposicoes = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM chamadas WHERE status_chamada = 'MR'")) ?? 0;

    return {
      'atletas': totalAtletas,
      'turmas': totalTurmas,
      'reposicoes': totalReposicoes,
    };
  }

  Future<Map<String, int>> getDailyStats(String data) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT status_chamada, COUNT(*) as qtd FROM chamadas WHERE data = ? GROUP BY status_chamada',
      [data]
    );

    Map<String, int> counts = {
      'P': 0, 'F': 0, 'A': 0, 'PE': 0, 'MR': 0, 'RR': 0, 'RP': 0, 'FE': 0
    };

    for (var row in res) {
      final st = row['status_chamada'] as String;
      final qtd = row['qtd'] as int;
      counts[st] = qtd;
    }
    return counts;
  }
}

// Navegação Principal por Abas
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
      const PlaceholderScreen(title: 'Chamada'),
      const PlaceholderScreen(title: 'Atletas'),
      const PlaceholderScreen(title: 'Turmas'),
      const MaisPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: const Color(0xFFD2E8DB),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Chamada'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Atletas'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Turmas'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mais'),
        ],
      ),
    );
  }
}

// 1. Tela Início Completa
class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final VoidCallback onIrParaChamada;

  const HomePage({super.key, required this.onToggleTheme, required this.isDarkMode, required this.onIrParaChamada});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalAtletas = 0;
  int totalTurmas = 0;
  int reposicoesPendentes = 0;
  Map<String, int> dailyStats = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final stats = await DatabaseHelper.instance.getStats();
    final hojeStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final daily = await DatabaseHelper.instance.getDailyStats(hojeStr);
    if (mounted) {
      setState(() {
        totalAtletas = stats['atletas'] ?? 0;
        totalTurmas = stats['turmas'] ?? 0;
        reposicoesPendentes = stats['reposicoes'] ?? 0;
        dailyStats = daily;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final dataFormatada = DateFormat("EEEE, d 'De' MMMM", 'pt_BR').format(hoje);
    final dataCapitalizada = dataFormatada[0].toUpperCase() + dataFormatada.substring(1);
    final dataCurta = DateFormat('dd/MM/yyyy').format(hoje);
    final diaSemanaCurto = DateFormat('EEEE', 'pt_BR').format(hoje);
    final diaSemanaCapitalizado = diaSemanaCurto[0].toUpperCase() + diaSemanaCurto.substring(1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Superior Verde
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF006C4C),
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
                          icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.white),
                          onPressed: widget.onToggleTheme,
                        ),
                      ],
                    ),
                    const Text(
                      'Gestão de Atletas',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB3F0C2),
                          foregroundColor: const Color(0xFF003824),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: widget.onIrParaChamada,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Fazer chamada de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Card Banco SQLite
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF006C4C)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Armazenamento permanente ativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 2),
                                  Text('Banco SQLite nativo salvo no armazenamento do Android.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cards de Resumo (Atletas, Turmas, Reposições)
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(Icons.group_outlined, '$totalAtletas', 'Atletas')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(Icons.grid_view_outlined, '$totalTurmas', 'Turmas')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(Icons.refresh, '$reposicoesPendentes', 'Reposições pendentes', isHighlight: true)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Painel Diário
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(dataCurta, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(diaSemanaCapitalizado, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Grade de 8 Status Diários
                            GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.9,
                              children: [
                                _buildGridStat('${dailyStats['P'] ?? 0}', 'Presenças', Colors.green),
                                _buildGridStat('${dailyStats['F'] ?? 0}', 'Faltas', Colors.red),
                                _buildGridStat('${dailyStats['A'] ?? 0}', 'Avulsas', Colors.teal),
                                _buildGridStat('${dailyStats['PE'] ?? 0}', 'Personal', Colors.amber.shade800),
                                _buildGridStat('${dailyStats['RR'] ?? 0}', 'Rep. Realizadas', Colors.green),
                                _buildGridStat('${dailyStats['RP'] ?? 0}', 'Rep. Perdidas', Colors.red),
                                _buildGridStat('${dailyStats['MR'] ?? 0}', 'Marcar Reposições', Colors.teal),
                                _buildGridStat('${dailyStats['FE'] ?? 0}', 'Feriado', Colors.amber.shade800),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String title, {bool isHighlight = false}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlight ? const BorderSide(color: Color(0xFFC7A200), width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF006C4C), size: 24),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStat(String numVal, String label, Color numColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(numVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: numColor)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black87)),
        ],
      ),
    );
  }
}

// Telas temporárias para as demais abas enquanto evoluímos
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Tela de $title em construção', style: const TextStyle(fontSize: 16, color: Colors.grey))),
    );
  }
}

class MaisPage extends StatelessWidget {
  const MaisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(leading: Icon(Icons.history), title: Text('Histórico e auditoria'))),
          Card(child: ListTile(leading: Icon(Icons.picture_as_pdf_outlined), title: Text('Relatórios em PDF'))),
          Card(child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Configurações e backup'))),
        ],
      ),
    );
  }
}
