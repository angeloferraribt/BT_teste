import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          secondary: const Color(0xFF80E080),
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
      home: MainNavigationPage(onToggleTheme: _toggleTheme),
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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        status TEXT NOT NULL
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
      CREATE TABLE frequencias (
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
}

// Navegação Principal por Abas
class MainNavigationPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MainNavigationPage({super.key, required this.onToggleTheme});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onToggleTheme: widget.onToggleTheme, onIrParaChamada: () => setState(() => _currentIndex = 1)),
      ChamadaPage(onToggleTheme: widget.onToggleTheme),
      AtletasPage(onToggleTheme: widget.onToggleTheme),
      TurmasPage(onToggleTheme: widget.onToggleTheme),
      MaisPage(onToggleTheme: widget.onToggleTheme),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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

// 1. Tela Início
class HomePage extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onIrParaChamada;

  const HomePage({super.key, required this.onToggleTheme, required this.onIrParaChamada});

  @override
  Widget build(BuildContext context) {
    final DateTime hoje = DateTime.now();
    final String dataFormatada = DateFormat("EEEE, d 'De' MMMM", 'pt_BR').format(hoje);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dataFormatada, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const Text('Gestão de Atletas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: onToggleTheme, icon: const Icon(Icons.nightlight_round_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB3F29B),
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: onIrParaChamada,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Fazer chamada de hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.verified_user_outlined, color: Colors.green, size: 32),
                  title: Text('Armazenamento permanente ativo', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Banco SQLite nativo salvo no armazenamento do Android.'),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: StatCard(title: '78', subtitle: 'Atletas', icon: Icons.group_outlined)),
                  SizedBox(width: 8),
                  Expanded(child: StatCard(title: '52', subtitle: 'Turmas', icon: Icons.grid_view)),
                  SizedBox(width: 8),
                  Expanded(child: StatCard(title: '0', subtitle: 'Reposições pendentes', icon: Icons.sync)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const StatCard({super.key, required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// 2. Tela Chamada
class ChamadaPage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const ChamadaPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamada'),
        actions: [IconButton(onPressed: onToggleTheme, icon: const Icon(Icons.nightlight_round_outlined))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '18/10/2026',
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Domingo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Selecione a Turma e Horário',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [],
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Tela Atletas
class AtletasPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const AtletasPage({super.key, required this.onToggleTheme});

  @override
  State<AtletasPage> createState() => _AtletasPageState();
}

class _AtletasPageState extends State<AtletasPage> {
  void _exibirModalNovoAtleta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Novo atleta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.cancel_outlined), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const TextField(decoration: InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Celular'))),
                SizedBox(width: 8),
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Dia/Mês aniversário'))),
              ],
            ),
            const SizedBox(height: 8),
            const TextField(decoration: InputDecoration(labelText: 'Observação')),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006847),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atletas'),
        actions: [IconButton(onPressed: widget.onToggleTheme, icon: const Icon(Icons.nightlight_round_outlined))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nome...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006847),
        onPressed: _exibirModalNovoAtleta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// 4. Tela Turmas
class TurmasPage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const TurmasPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turmas'),
        actions: [IconButton(onPressed: onToggleTheme, icon: const Icon(Icons.nightlight_round_outlined))],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar turma ou atleta...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Tela Mais
class MaisPage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const MaisPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mais'),
        actions: [IconButton(onPressed: onToggleTheme, icon: const Icon(Icons.nightlight_round_outlined))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Histórico e auditoria'),
              subtitle: Text('Consultar e editar chamadas passadas'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined),
              title: Text('Relatórios em PDF'),
              subtitle: Text('Por período, turma ou atleta'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Configurações e backup'),
              subtitle: Text('Instituição, exportar e restaurar'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
