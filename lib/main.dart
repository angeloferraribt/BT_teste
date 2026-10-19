Import ‘package:flutter/material.dart’;
Import ‘package:flutter_localizations/flutter_localizations.dart’;
Import ‘package:sqflite/sqflite.dart’;
Import ‘package:path/path.dart’ as p;
Import ‘package:intl/intl.dart’;
Import ‘package:intl/date_symbol_data_local.dart’;

Void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Await initializeDateFormatting(‘pt_BR’, null);
  Await DatabaseHelper.instance.database;
  runApp(const GestaoAtletasApp());
}

Class GestaoAtletasApp extends StatefulWidget {
  Const GestaoAtletasApp({super.key});

  @override
  State<GestaoAtletasApp> createState() => _GestaoAtletasAppState();
}

Class _GestaoAtletasAppState extends State<GestaoAtletasApp> {
  ThemeMode _themeMode = ThemeMode.light;

  Void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    Return MaterialApp(
      Title: ‘Gestão de Atletas’,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale(‘pt’, ‘BR’)],
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
      Home: MainNavigationPage(onToggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE HELPER (SQLite 100% Offline)
// ─────────────────────────────────────────────────────────────────────────────
Class DatabaseHelper {
  Static final DatabaseHelper instance = DatabaseHelper._init();
  Static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    If (_database != null) return _database!;
    _database = await _initDB(‘gestao_atletas.db’);
    Return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Final dbPath = await getDatabasesPath();
    Final path = p.join(dbPath, filePath);

    Return await openDatabase(
      Path,
      Version: 1,
      onCreate: (db, version) async {
        await db.execute(‘’’
          CREATE TABLE turmas (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            Nome TEXT NOT NULL,
            Descricao TEXT,
            Dia_semana TEXT NOT NULL,
            Horario TEXT NOT NULL
          )
        ‘’’);

        Await db.execute(‘’’
          CREATE TABLE atletas (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            Nome TEXT NOT NULL,
            Celular TEXT,
            Aniversario TEXT,
            Observação TEXT,
            Status TEXT NOT NULL DEFAULT ‘Ativo’
          )
        ‘’’);

        Await db.execute(‘’’
          CREATE TABLE turma_atletas (
            Turma_id INTEGER NOT NULL,
            Atleta_id INTEGER NOT NULL,
            PRIMARY KEY (turma_id, atleta_id),
            FOREIGN KEY (turma_id) REFERENCES turmas (id) ON DELETE CASCADE,
            FOREIGN KEY (atleta_id) REFERENCES atletas (id) ON DELETE CASCADE
          )
        ‘’’);

        Await db.execute(‘’’
          CREATE TABLE chamadas (
            Id INTEGER PRIMARY KEY AUTOINCREMENT,
            Atleta_id INTEGER NOT NULL,
            Turma_id INTEGER NOT NULL,
            Data TEXT NOT NULL,
            Status_chamada TEXT NOT NULL,
            Observação TEXT,
            FOREIGN KEY (atleta_id) REFERENCES atletas (id) ON DELETE CASCADE,
            FOREIGN KEY (turma_id) REFERENCES turmas (id) ON DELETE CASCADE
          )
        ‘’’);
      },
      onConfigure: (db) async {
        await db.execute(‘PRAGMA foreign_keys = ON’);
      },
    );
  }

  Future<Map<String, int>> getStats() async {
    Final db = await database;
    Final totalAtletas = Sqflite.firstIntValue(await db.rawQuery(‘SELECT COUNT(*) FROM atletas’)) ?? 0;
    Final totalTurmas = Sqflite.firstIntValue(await db.rawQuery(‘SELECT COUNT(*) FROM turmas’)) ?? 0;
    Final totalReposicoes = Sqflite.firstIntValue(await db.rawQuery(“SELECT COUNT(*) FROM chamadas WHERE status_chamada = ‘MR’”)) ?? 0;

    Return {
      ‘atletas’: totalAtletas,
      ‘turmas’: totalTurmas,
      ‘reposicoes’: totalReposicoes,
    };
  }

  Future<Map<String, int>> getDailyStats(String data) async {
    Final db = await database;
    Final res = await db.rawQuery(
      ‘SELECT status_chamada, COUNT(*) as qtd FROM chamadas WHERE data = ? GROUP BY status_chamada’,
      [data]
    );

    Map<String, int> counts = {
      ‘P’: 0, ‘F’: 0, ‘A’: 0, ‘PE’: 0, ‘MR’: 0, ‘RR’: 0, ‘RP’: 0, ‘FE’: 0
    };

    For (var row in res) {
      Final st = row[‘status_chamada’] as String;
      Final qtd = row[‘qtd’] as int;
      Counts[st] = qtd;
    }
    Return counts;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVEGAÇÃO PRINCIPAL (Bottom Navigation Bar)
// ─────────────────────────────────────────────────────────────────────────────
Class MainNavigationPage extends StatefulWidget {
  Final VoidCallback onToggleTheme;
  Final bool isDarkMode;

  Const MainNavigationPage({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

Class _MainNavigationPageState extends State<MainNavigationPage> {
  Int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Final List<Widget> pages = [
      HomePage(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        onIrParaChamada: () => setState(() => _currentIndex = 1),
      ),
      ChamadaPage(onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode),
      AtletasPage(onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode),
      TurmasPage(onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode),
      MaisPage(onToggleTheme: widget.onToggleTheme, isDarkMode: widget.isDarkMode),
    ];

    Return Scaffold(
      Body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: const Color(0xFFC5F068),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: ‘Início’),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: ‘Chamada’),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: ‘Atletas’),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: ‘Turmas’),
          NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: ‘Mais’),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. TELA: INÍCIO (Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
Class HomePage extends StatefulWidget {
  Final VoidCallback onToggleTheme;
  Final bool isDarkMode;
  Final VoidCallback onIrParaChamada;

  Const HomePage({super.key, required this.onToggleTheme, required this.isDarkMode, required this.onIrParaChamada});

  @override
  State<HomePage> createState() => _HomePageState();
}

Class _HomePageState extends State<HomePage> {
  Int totalAtletas = 0;
  Int totalTurmas = 0;
  Int reposicoesPendentes = 0;
  Map<String, int> dailyStats = {};
  String dataSelecionadaStr = DateFormat(‘yyyy-MM-dd’).format(DateTime.now());

  @override
  Void initState() {
    Super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    Final stats = await DatabaseHelper.instance.getStats();
    Final daily = await DatabaseHelper.instance.getDailyStats(dataSelecionadaStr);
    If (mounted) {
      setState(() {
        totalAtletas = stats[‘atletas’] ?? 0;
        totalTurmas = stats[‘turmas’] ?? 0;
        reposicoesPendentes = stats[‘reposicoes’] ?? 0;
        dailyStats = daily;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Final hoje = DateTime.parse(dataSelecionadaStr);
    Final dataFormatada = DateFormat(“EEEE, d ‘De’ MMMM”, ‘pt_BR’).format(hoje);
    Final dataCapitalizada = dataFormatada[0].toUpperCase() + dataFormatada.substring(1);
    Final diaSemana = DateFormat(‘EEEE’, ‘pt_BR’).format(hoje);
    Final diaSemanaCap = diaSemana[0].toUpperCase() + diaSemana.substring(1);

    Return Scaffold(
      Body: SafeArea(
        Child: RefreshIndicator(
          onRefresh: _carregarDados,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  Padding: const EdgeInsets.all(20),
                  Decoration: const BoxDecoration(
                    Color: Color(0xFF00684A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  Child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dataCapitalizada, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          IconButton(
                            Icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.white),
                            onPressed: widget.onToggleTheme,
                          ),
                        ],
                      ),
                      Const Text(
                        ‘Gestão de Atletas’,
                        Style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Const SizedBox(height: 16),
                      SizedBox(
                        Width: double.infinity,
                        Child: ElevatedButton.icon(
                          Style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5F068),
                            foregroundColor: const Color(0xFF003824),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: widget.onIrParaChamada,
                          icon: const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text(‘Fazer chamada de hoje’, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  Padding: const EdgeInsets.all(16.0),
                  Child: Column(
                    Children: [
                      Card(
                        Elevation: 0,
                        Shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        Child: Padding(
                          Padding: const EdgeInsets.all(16.0),
                          Child: Row(
                            Children: [
                              Container(
                                Padding: const EdgeInsets.all(10),
                                Decoration: BoxDecoration(
                                  Color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                Child: const Icon(Icons.shield_outlined, color: Color(0xFF00684A)),
                              ),
                              Const SizedBox(width: 12),
                              Const Expanded(
                                Child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(‘Armazenamento permanente ativo’, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text(‘Banco SQLite nativo salvo no armazenamento do Android.’, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Const SizedBox(height: 12),
                      Row(
                        Children: [
                          Expanded(child: _buildStatCard(Icons.group_outlined, ‘$totalAtletas’, ‘Atletas’)),
                          Const SizedBox(width: 8),
                          Expanded(child: _buildStatCard(Icons.grid_view_outlined, ‘$totalTurmas’, ‘Turmas’)),
                          Const SizedBox(width: 8),
                          Expanded(child: _buildStatCard(Icons.refresh, ‘$reposicoesPendentes’, ‘Reposições pendentes’, isHighlight: true)),
                        ],
                      ),
                      Const SizedBox(height: 16),
                      Card(
                        Elevation: 0,
                        Shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        Child: Padding(
                          Padding: const EdgeInsets.all(16.0),
                          Child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(‘Resumo do dia’, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                Children: [
                                  Expanded(
                                    Child: InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: hoje,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        If (picked != null) {
                                          setState(() {
                                            dataSelecionadaStr = DateFormat(‘yyyy-MM-dd’).format(picked);
                                          });
                                          _carregarDados();
                                        }
                                      },
                                      Child: Container(
                                        Padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        Decoration: BoxDecoration(
                                          Border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        Child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(DateFormat(‘dd/MM/yyyy’).format(hoje)),
                                            Const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Const SizedBox(width: 8),
                                  Expanded(
                                    Child: Container(
                                      Padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      Decoration: BoxDecoration(
                                        Border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      Child: Text(diaSemanaCap, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ),
                                  ),
                                ],
                              ),
                              Const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.9,
                                children: [
                                  _buildGridStat(‘${dailyStats[‘P’] ?? 0}’, ‘Presenças’, const Color(0xFF22C55E)),
                                  _buildGridStat(‘${dailyStats[‘F’] ?? 0}’, ‘Faltas’, const Color(0xFFEF4444)),
                                  _buildGridStat(‘${dailyStats[‘A’] ?? 0}’, ‘Avulsas’, const Color(0xFF0EA5E9)),
                                  _buildGridStat(‘${dailyStats[‘PE’] ?? 0}’, ‘Personal’, const Color(0xFFA855F7)),
                                  _buildGridStat(‘${dailyStats[‘MR’] ?? 0}’, ‘Marcar Reps.’, const Color(0xFFF59E0B)),
                                  _buildGridStat(‘${dailyStats[‘RR’] ?? 0}’, ‘Reps. Feitas’, const Color(0xFF0D9488)),
                                  _buildGridStat(‘${dailyStats[‘RP’] ?? 0}’, ‘Reps. Perdidas’, const Color(0xFF78350F)),
                                  _buildGridStat(‘${dailyStats[‘FE’] ?? 0}’, ‘Feriado’, Colors.black),
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
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String title, {bool isHighlight = false}) {
    Return Card(
      Elevation: 0,
      Shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlight ? const BorderSide(color: Color(0xFFF59E0B), width: 2) : BorderSide.none,
      ),
      Child: Padding(
        Padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        Child: Column(
          Children: [
            Icon(icon, color: const Color(0xFF00684A), size: 24),
            Const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStat(String numVal, String label, Color numColor) {
    Return Container(
      Decoration: BoxDecoration(
        Color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16),
      ),
      Child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(numVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: numColor)),
          Const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TELA: CHAMADA
// ─────────────────────────────────────────────────────────────────────────────
Class ChamadaPage extends StatefulWidget {
  Final VoidCallback onToggleTheme;
  Final bool isDarkMode;

  Const ChamadaPage({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<ChamadaPage> createState() => _ChamadaPageState();
}

Class _ChamadaPageState extends State<ChamadaPage> {
  DateTime dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> turmas = [];
  Int? turmaSelecionadaId;
  List<Map<String, dynamic>> atletasNaTurma = [];
  Map<int, String> statusAtletas = {};
  Map<int, TextEditingController> obsControllers = {};

  @override
  Void initState() {
    Super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    Final db = await DatabaseHelper.instance.database;
    Final res = await db.query(‘turmas’);
    If (mounted) {
      setState(() {
        turmas = res;
        if (turmas.isNotEmpty) {
          turmaSelecionadaId = turmas.first[‘id’] as int;
          _carregarAtletasDaTurma();
        }
      });
    }
  }

  Future<void> _carregarAtletasDaTurma() async {
    If (turmaSelecionadaId == null) return;
    Final db = await DatabaseHelper.instance.database;
    Final res = await db.rawQuery(‘’’
      SELECT a.* FROM atletas a
      INNER JOIN turma_atletas ta ON ta.atleta_id = a.id
      WHERE ta.turma_id = ?
    ‘’’, [turmaSelecionadaId]);

    Final dataStr = DateFormat(‘yyyy-MM-dd’).format(dataSelecionada);
    Final chamadas = await db.query(
      ‘chamadas’,
      Where: ‘turma_id = ? AND data = ?’,
      whereArgs: [turmaSelecionadaId, dataStr],
    );

    Map<int, String> mapStatus = {};
    Map<int, TextEditingController> mapObs = {};

    For (var a in res) {
      Final aId = a[‘id’] as int;
      Final ch = chamadas.firstWhere((element) => element[‘atleta_id’] == aId, orElse: () => {});
      mapStatus[aId] = ch.isNotEmpty ? (ch[‘status_chamada’] as String) : ‘’;
      mapObs[aId] = TextEditingController(text: ch.isNotEmpty ? (ch[‘observação’] as String? ?? ‘’) : ‘’);
    }

    If (mounted) {
      setState(() {
        atletasNaTurma = res;
        statusAtletas = mapStatus;
        obsControllers = mapObs;
      });
    }
  }

  Future<void> _salvarStatus(int atletaId, String status) async {
    Final db = await DatabaseHelper.instance.database;
    Final dataStr = DateFormat(‘yyyy-MM-dd’).format(dataSelecionada);
    Final obs = obsControllers[atletaId]?.text ?? ‘’;

    Final existing = await db.query(
      ‘chamadas’,
      Where: ‘atleta_id = ? AND turma_id = ? AND data = ?’,
      whereArgs: [atletaId, turmaSelecionadaId, dataStr],
    );

    If (existing.isEmpty) {
      Await db.insert(‘chamadas’, {
        ‘atleta_id’: atletaId,
        ‘turma_id’: turmaSelecionadaId,
        ‘data’: dataStr,
        ‘status_chamada’: status,
        ‘observação’: obs,
      });
    } else {
      Await db.update(
        ‘chamadas’,
        {‘status_chamada’: status, ‘observação’: obs},
        Where: ‘atleta_id = ? AND turma_id = ? AND data = ?’,
        whereArgs: [atletaId, turmaSelecionadaId, dataStr],
      );
    }

    setState(() {
      statusAtletas[atletaId] = status;
    });
  }

  Future<void> _marcarRestantesPresentes() async {
    If (turmaSelecionadaId == null) return;
    For (var a in atletasNaTurma) {
      Final aId = a[‘id’] as int;
      If ((statusAtletas[aId] ?? ‘’).isEmpty) {
        Await _salvarStatus(aId, ‘P’);
      }
    }
    _carregarAtletasDaTurma();
  }

  @override
  Widget build(BuildContext context) {
    Final dataStr = DateFormat(‘dd/MM/yyyy’).format(dataSelecionada);
    Final diaSemanaStr = DateFormat(‘EEEE’, ‘pt_BR’).format(dataSelecionada);

    Return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(‘Chamada’, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(‘${atletasNaTurma.where((a) => (statusAtletas[a[‘id’]] ?? ‘’).isNotEmpty).length}/${atletasNaTurma.length} registrados’, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Actions: [
          IconButton(
            Icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      Body: Padding(
        Padding: const EdgeInsets.all(16.0),
        Child: Column(
          Children: [
            Row(
              Children: [
                Expanded(
                  Child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dataSelecionada,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      If (picked != null) {
                        setState(() {
                          dataSelecionada = picked;
                        });
                        _carregarAtletasDaTurma();
                      }
                    },
                    Child: Container(
                      Padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      Decoration: BoxDecoration(
                        Color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      Child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dataStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                Const SizedBox(width: 8),
                Expanded(
                  Child: Container(
                    Padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    Decoration: BoxDecoration(
                      Color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    Child: Text(
                      diaSemanaStr[0].toUpperCase() + diaSemanaStr.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            Const SizedBox(height: 12),
            Container(
              Padding: const EdgeInsets.symmetric(horizontal: 16),
              Decoration: BoxDecoration(
                Color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              Child: DropdownButtonHideUnderline(
                Child: DropdownButton<int>(
                  isExpanded: true,
                  value: turmaSelecionadaId,
                  hint: const Text(‘Selecione uma turma’),
                  items: turmas.map((t) {
                    return DropdownMenuItem<int>(
                      value: t[‘id’] as int,
                      child: Text(‘${t[‘nome’]} — ${t[‘horario’]}’),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      turmaSelecionadaId = val;
                    });
                    _carregarAtletasDaTurma();
                  },
                ),
              ),
            ),
            Const SizedBox(height: 8),
            Align(
              Alignment: Alignment.centerLeft,
              Child: TextButton.icon(
                onPressed: _marcarRestantesPresentes,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(‘Marcar presença nos restantes’),
              ),
            ),
            Const SizedBox(height: 8),
            Expanded(
              Child: atletasNaTurma.isEmpty
                  ? const Center(child: Text(‘Nenhum atleta vinculado a esta turma.’))
                  : ListView.builder(
                      itemCount: atletasNaTurma.length,
                      itemBuilder: (ctx, idx) {
                        final a = atletasNaTurma[idx];
                        final aId = a[‘id’] as int;
                        final currentSt = statusAtletas[aId] ?? ‘’;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(a[‘nome’], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(a[‘status’] ?? ‘Ativo’, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                Const SizedBox(height: 12),
                                Wrap(
                                  Spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildStatusBtn(aId, ‘P’, ‘P’, const Color(0xFF22C55E), currentSt),
                                    _buildStatusBtn(aId, ‘F’, ‘F’, const Color(0xFFEF4444), currentSt),
                                    _buildStatusBtn(aId, ‘A’, ‘A’, const Color(0xFF0EA5E9), currentSt),
                                    _buildStatusBtn(aId, ‘PE’, ‘PE’, const Color(0xFFA855F7), currentSt),
                                    _buildStatusBtn(aId, ‘MR’, ‘MR’, const Color(0xFFF59E0B), currentSt),
                                    _buildStatusBtn(aId, ‘RR’, ‘RR’, const Color(0xFF0D9488), currentSt),
                                    _buildStatusBtn(aId, ‘RP’, ‘RP’, const Color(0xFF78350F), currentSt),
                                    _buildStatusBtn(aId, ‘FE’, ‘FE’, Colors.black, currentSt),
                                  ],
                                ),
                                Const SizedBox(height: 12),
                                TextField(
                                  Controller: obsControllers[aId],
                                  Decoration: InputDecoration(
                                    hintText: ‘Observação...’,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onChanged: (val) {
                                    if (currentSt.isNotEmpty) {
                                      _salvarStatus(aId, currentSt);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBtn(int atletaId, String code, String label, Color color, String currentSt) {
    Final isSelected = currentSt == code;
    Return InkWell(
      onTap: () => _salvarStatus(atletaId, code),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 60,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
        ),
        Alignment: Alignment.center,
        Child: Text(
          Label,
          Style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TELA: ATLETAS & HISTÓRICO DO ATLETA
// ─────────────────────────────────────────────────────────────────────────────
Class AtletasScreen extends StatefulWidget {
  Final VoidCallback toggleTheme;
  Final bool isDarkMode;

  Const AtletasScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<AtletasScreen> createState() => _AtletasScreenState();
}

Class _AtletasScreenState extends State<AtletasScreen> {
  List<Map<String, dynamic>> atletas = [];
  List<Map<String, dynamic>> atletasFiltrados = [];
  String busca = ‘’;

  @override
  Void initState() {
    Super.initState();
    _carregarAtletas();
  }

  Future<void> _carregarAtletas() async {
    Final db = await DatabaseHelper.instance.database;
    Final res = await db.query(‘atletas’, orderBy: ‘nome ASC’);
    If (mounted) {
      setState(() {
        atletas = res;
        _filtrar();
      });
    }
  }

  Void _filtrar() {
    setState(() {
      if (busca.isEmpty) {
        atletasFiltrados = atletas;
      } else {
        atletasFiltrados = atletas.where((a) => (a[‘nome’] as String).toLowerCase().contains(busca.toLowerCase())).toList();
      }
    });
  }

  Void _abrirModalAtleta({Map<String, dynamic>? atletaExistente}) {
    Final nomeCtrl = TextEditingController(text: atletaExistente?[‘nome’] ?? ‘’);
    Final celularCtrl = TextEditingController(text: atletaExistente?[‘celular’] ?? ‘’);
    Final niverCtrl = TextEditingController(text: atletaExistente?[‘aniversario’] ?? ‘’);
    Final obsCtrl = TextEditingController(text: atletaExistente?[‘observação’] ?? ‘’);
    String statusSel = atletaExistente?[‘status’] ?? ‘Ativo’;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 24, left: 16, right: 16,
              ),
              Child: SingleChildScrollView(
                Child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(atletaExistente == null ? ‘Novo atleta’ : ‘Editar atleta’, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    Const SizedBox(height: 16),
                    TextField(controller: nomeCtrl, decoration: _inputDeco(‘Nome’)),
                    Const SizedBox(height: 12),
                    Row(
                      Children: [
                        Expanded(child: TextField(controller: celularCtrl, decoration: _inputDeco(‘Celular’))),
                        Const SizedBox(width: 8),
                        Expanded(child: TextField(controller: niverCtrl, decoration: _inputDeco(‘Dia/Mês aniversário’))),
                      ],
                    ),
                    Const SizedBox(height: 12),
                    TextField(controller: obsCtrl, decoration: _inputDeco(‘Observação’)),
                    Const SizedBox(height: 16),
                    Wrap(
                      Spacing: 8,
                      runSpacing: 8,
                      children: [‘Ativo’, ‘Avulso’, ‘Personal’, ‘Férias’, ‘Atestado’, ‘Inativo’].map((st) {
                        final sel = statusSel == st;
                        return ChoiceChip(
                          label: Text(st),
                          selected: sel,
                          selectedColor: const Color(0xFF00684A),
                          labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (val) setModalState(() => statusSel = st);
                          },
                        );
                      }).toList(),
                    ),
                    Const SizedBox(height: 20),
                    SizedBox(
                      Width: double.infinity,
                      Child: ElevatedButton(
                        Style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00684A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nomeCtrl.text.isNotEmpty) {
                            final db = await DatabaseHelper.instance.database;
                            if (atletaExistente == null) {
                              await db.insert(‘atletas’, {
                                ‘nome’: nomeCtrl.text,
                                ‘celular’: celularCtrl.text,
                                ‘aniversario’: niverCtrl.text,
                                ‘observação’: obsCtrl.text,
                                ‘status’: statusSel,
                              });
                            } else {
                              Await db.update(
                                ‘atletas’,
                                {
                                  ‘nome’: nomeCtrl.text,
                                  ‘celular’: celularCtrl.text,
                                  ‘aniversario’: niverCtrl.text,
                                  ‘observação’: obsCtrl.text,
                                  ‘status’: statusSel,
                                },
                                Where: ‘id = ?’,
                                whereArgs: [atletaExistente[‘id’]],
                              );
                            }
                            Navigator.pop(ctx);
                            _carregarAtletas();
                          }
                        },
                        Child: const Text(‘Salvar’, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    Return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F7F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    Return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(‘Atletas’, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(‘${atletas.length} cadastrados’, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Actions: [
          IconButton(
            Icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      Body: Padding(
        Padding: const EdgeInsets.all(16.0),
        Child: Column(
          Children: [
            TextField(
              Decoration: InputDecoration(
                hintText: ‘Buscar por nome...’,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                busca = val;
                _filtrar();
              },
            ),
            Const SizedBox(height: 16),
            Expanded(
              Child: atletasFiltrados.isEmpty
                  ? const Center(child: Text(‘Nenhum atleta encontrado.’))
                  : ListView.builder(
                      itemCount: atletasFiltrados.length,
                      itemBuilder: (ctx, idx) {
                        final a = atletasFiltrados[idx];
                        final initial = (a[‘nome’] as String).isNotEmpty ? (a[‘nome’] as String)[0].toUpperCase() : ‘A’;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFC5F068),
                              child: Text(initial, style: const TextStyle(color: Color(0xFF003824), fontWeight: FontWeight.bold)),
                            ),
                            Title: Text(a[‘nome’], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Subtitle: Text(a[‘celular’] != null && (a[‘celular’] as String).isNotEmpty ? a[‘celular’] : ‘Sem celular’),
                            Trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  Padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  Decoration: BoxDecoration(
                                    Color: const Color(0xFF00684A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  Child: Text(a[‘status’] ?? ‘Ativo’, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                Const SizedBox(width: 8),
                                Const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                            onTap: () => _abrirModalAtleta(atletaExistente: a),
                            onLongPress: () {
                              Navigator.push(
                                Context,
                                MaterialPageRoute(builder: (context) => AtletaDetalhesPage(atleta: a)),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00684A),
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalAtleta(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Class AtletaDetalhesPage extends StatefulWidget {
  Final Map<String, dynamic> atleta;
  Const AtletaDetalhesPage({super.key, required this.atleta});

  @override
  State<AtletaDetalhesPage> createState() => _AtletaDetalhesPageState();
}

Class _AtletaDetalhesPageState extends State<AtletaDetalhesPage> {
  List<Map<String, dynamic>> historico = [];
  Map<String, int> contadores = {};

  @override
  Void initState() {
    Super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    Final db = await DatabaseHelper.instance.database;
    Final res = await db.rawQuery(‘’’
      SELECT c.*, t.nome as turma_nome FROM chamadas c
      LEFT JOIN turmas t ON t.id = c.turma_id
      WHERE c.atleta_id = ?
      ORDER BY c.data DESC
    ‘’’, [widget.atleta[‘id’]]);

    Map<String, int> counts = {‘P’: 0, ‘F’: 0, ‘A’: 0, ‘PE’: 0, ‘MR’: 0, ‘RR’: 0, ‘RP’: 0, ‘FE’: 0};
    For (var row in res) {
      Final st = row[‘status_chamada’] as String;
      Counts[st] = (counts[st] ?? 0) + 1;
    }

    If (mounted) {
      setState(() {
        historico = res;
        contadores = counts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Return Scaffold(
      appBar: AppBar(title: Text(widget.atleta[‘nome’])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(‘${widget.atleta[‘celular’] ?? ‘Sem celular’} · ${widget.atleta[‘status’]}’, style: const TextStyle(color: Colors.grey)),
            Const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                _buildCountCard(‘Presenças’, ‘${contadores[‘P’] ?? 0}’, const Color(0xFF22C55E)),
                _buildCountCard(‘Faltas’, ‘${contadores[‘F’] ?? 0}’, const Color(0xFFEF4444)),
                _buildCountCard(‘Avulsas’, ‘${contadores[‘A’] ?? 0}’, const Color(0xFF0EA5E9)),
                _buildCountCard(‘Personal’, ‘${contadores[‘PE’] ?? 0}’, const Color(0xFFA855F7)),
                _buildCountCard(‘Marcar Rep.’, ‘${contadores[‘MR’] ?? 0}’, const Color(0xFFF59E0B)),
                _buildCountCard(‘Reps. Feitas’, ‘${contadores[‘RR’] ?? 0}’, const Color(0xFF0D9488)),
                _buildCountCard(‘Reps. Perd.’, ‘${contadores[‘RP’] ?? 0}’, const Color(0xFF78350F)),
                _buildCountCard(‘Feriado’, ‘${contadores[‘FE’] ?? 0}’, Colors.black),
              ],
            ),
            Const SizedBox(height: 16),
            Const Text(‘Histórico’, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Const SizedBox(height: 8),
            Expanded(
              Child: historico.isEmpty
                  ? const Center(child: Text(‘Nenhum registro.’))
                  : ListView.builder(
                      itemCount: historico.length,
                      itemBuilder: (ctx, idx) {
                        final h = historico[idx];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(‘${h[‘data’]} — ${h[‘turma_nome’] ?? ‘Turma’}’),
                            subtitle: Text(‘Observação: ${h[‘observação’] ?? ‘Nenhuma’}’),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00684A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              Child: Text(h[‘status_chamada’], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String title, String val, Color color) {
    Return Container(
      Decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      Child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. TELA: TURMAS
// ─────────────────────────────────────────────────────────────────────────────
Class TurmasScreen extends StatefulWidget {
  Final VoidCallback toggleTheme;
  Final bool isDarkMode;

  Const TurmasScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

Class _TurmasScreenState extends State<TurmasScreen> {
  List<Map<String, dynamic>> turmas = [];
  Map<int, List<String>> atletasPorTurma = {};

  @override
  Void initState() {
    Super.initState();
    _carregarTurmas();
  }

  Future<void> _carregarTurmas() async {
    Final db = await DatabaseHelper.instance.database;
    Final resTurmas = await db.query(‘turmas’);

    Map<int, List<String>> mapAtletas = {};
    For (var t in resTurmas) {
      Final tId = t[‘id’] as int;
      Final resAtletas = await db.rawQuery(‘’’
        SELECT a.nome FROM atletas a
        INNER JOIN turma_atletas ta ON ta.atleta_id = a.id
        WHERE ta.turma_id = ?
      ‘’’, [tId]);
      mapAtletas[tId] = resAtletas.map((row) => row[‘nome’] as String).toList();
    }

    If (mounted) {
      setState(() {
        turmas = resTurmas;
        atletasPorTurma = mapAtletas;
      });
    }
  }

  Void _exibirModalNovaTurma() async {
    Final nomeCtrl = TextEditingController();
    Final descCtrl = TextEditingController();
    String diaSemana = ‘Segunda’;
    String horario = ’06:00’;

    Final db = await DatabaseHelper.instance.database;
    Final todosAtletas = await db.query(‘atletas’, orderBy: ‘nome ASC’);
    Set<int> selecionados = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 24, left: 16, right: 16,
              ),
              Child: SingleChildScrollView(
                Child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(‘Nova turma’, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    Const SizedBox(height: 16),
                    TextField(controller: nomeCtrl, decoration: _inputDeco(‘Nome (ex: “Segunda 6h”)’)),
                    Const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: _inputDeco(‘Descrição’)),
                    Const SizedBox(height: 12),
                    Row(
                      Children: [
                        Expanded(
                          Child: DropdownButtonFormField<String>(
                            Value: diaSemana,
                            Decoration: _inputDeco(‘Dia da semana’),
                            Items: [‘Segunda’, ‘Terça’, ‘Quarta’, ‘Quinta’, ‘Sexta’, ‘Sábado’, ‘Domingo’].map((d) {
                              Return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) => setModalState(() => diaSemana = val!),
                          ),
                        ),
                        Const SizedBox(width: 8),
                        Expanded(
                          Child: TextField(
                            Decoration: _inputDeco(‘Horário (ex: 06:00)’),
                            onChanged: (val) => horario = val,
                          ),
                        ),
                      ],
                    ),
                    Const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(‘Atletas vinculados’, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(‘${selecionados.length} selecionados’, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Const SizedBox(height: 8),
                    SizedBox(
                      Height: 150,
                      Child: ListView.builder(
                        itemCount: todosAtletas.length,
                        itemBuilder: (ctx2, idx) {
                          final a = todosAtletas[idx];
                          final aId = a[‘id’] as int;
                          final isChecked = selecionados.contains(aId);

                          return CheckboxListTile(
                            title: Text(a[‘nome’] as String),
                            subtitle: Text(a[‘status’] as String? ?? ‘Ativo’),
                            value: isChecked,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selecionados.add(aId);
                                } else {
                                  Selecionados.remove(aId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Const SizedBox(height: 16),
                    SizedBox(
                      Width: double.infinity,
                      Child: ElevatedButton(
                        Style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00684A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nomeCtrl.text.isNotEmpty) {
                            final turmaId = await db.insert(‘turmas’, {
                              ‘nome’: nomeCtrl.text,
                              ‘descricao’: descCtrl.text,
                              ‘dia_semana’: diaSemana,
                              ‘horario’: horario,
                            });

                            For (var aId in selecionados) {
                              Await db.insert(‘turma_atletas’, {
                                ‘turma_id’: turmaId,
                                ‘atleta_id’: aId,
                              });
                            }

                            Navigator.pop(ctx);
                            _carregarTurmas();
                          }
                        },
                        Child: const Text(‘Salvar’, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    Return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F7F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    Return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(‘Turmas’, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(‘${turmas.length} turmas’, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Actions: [
          IconButton(
            Icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      Body: Padding(
        Padding: const EdgeInsets.all(16.0),
        Child: Column(
          Children: [
            TextField(
              Decoration: InputDecoration(
                hintText: ‘Buscar turma ou atleta...’,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
            Const SizedBox(height: 16),
            Expanded(
              Child: turmas.isEmpty
                  ? const Center(child: Text(‘Nenhuma turma cadastrada.’))
                  : ListView.builder(
                      itemCount: turmas.length,
                      itemBuilder: (ctx, idx) {
                        final t = turmas[idx];
                        final tId = t[‘id’] as int;
                        final listaAtletas = atletasPorTurma[tId] ?? [];

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t[‘nome’], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      Padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      Decoration: BoxDecoration(
                                        Color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      Child: Row(
                                        Children: [
                                          Const Icon(Icons.access_time, size: 14, color: Color(0xFF00684A)),
                                          Const SizedBox(width: 4),
                                          Text(‘${t[‘dia_semana’]} ${t[‘horario’]}’, style: const TextStyle(color: Color(0xFF00684A), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Const SizedBox(height: 12),
                                listaAtletas.isEmpty
                                    ? const Text(‘Nenhum atleta vinculado’, style: TextStyle(color: Colors.grey, fontSize: 12))
                                    : Wrap(
                                        Spacing: 6,
                                        runSpacing: 6,
                                        children: listaAtletas.map((nome) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            Child: Text(nome, style: const TextStyle(fontSize: 12)),
                                          );
                                        }).toList(),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00684A),
        foregroundColor: Colors.white,
        onPressed: _exibirModalNovaTurma,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. TELA: MAIS
// ─────────────────────────────────────────────────────────────────────────────
Class MaisPage extends StatelessWidget {
  Final VoidCallback toggleTheme;
  Final bool isDarkMode;

  Const MaisPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    Return Scaffold(
      appBar: AppBar(
        title: const Text(‘Mais’, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            Icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: toggleTheme,
          ),
        ],
      ),
      Body: Padding(
        Padding: const EdgeInsets.all(16.0),
        Child: Column(
          Children: [
            _buildOptionCard(
              Context,
              Icons.history,
              ‘Histórico e auditoria’,
              ‘Consultar e editar chamadas passadas’,
              () {},
            ),
            Const SizedBox(height: 12),
            _buildOptionCard(
              Context,
              Icons.picture_as_pdf_outlined,
              ‘Relatórios em PDF’,
              ‘Por período, turma ou atleta’,
              () {},
            ),
            Const SizedBox(height: 12),
            _buildOptionCard(
              Context,
              Icons.settings_outlined,
              ‘Configurações e backup’,
              ‘Instituição, exportar e restaurar’,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    Return Card(
      Elevation: 0,
      Shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      Child: ListTile(
        Leading: Container(
          Padding: const EdgeInsets.all(10),
          Decoration: BoxDecoration(
            Color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          Child: Icon(icon, color: const Color(0xFF00684A)),
        ),
        Title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
