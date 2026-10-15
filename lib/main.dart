import 'package:flutter/material.dart';
import 'services/airtable_service.dart';

void main() {
  runApp(const BozorCrmApp());
}

class BozorCrmApp extends StatelessWidget {
  const BozorCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bozor CRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SotuvlarScreen(),
    OmborScreen(),
    QarzdorlarScreen(),
    HisobotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Sotuvlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Ombor',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Nasiya',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Hisobot',
          ),
        ],
      ),
    );
  }
}

// ================= 1. SOTUVLAR EKRANI =================
class SotuvlarScreen extends StatefulWidget {
  const SotuvlarScreen({super.key});

  @override
  State<SotuvlarScreen> createState() => _SotuvlarScreenState();
}

class _SotuvlarScreenState extends State<SotuvlarScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Map<String, dynamic>>> _sotuvlarFuture;

  @override
  void initState() {
    super.initState();
    _refreshSotuvlar();
  }

  void _refreshSotuvlar() {
    setState(() {
      _sotuvlarFuture = _airtableService.getSotuvlar();
    });
  }

  void _showAddSotuvDialog() async {
    final xaridorController = TextEditingController();
    final soniController = TextEditingController(text: '1');
    
    List<Map<String, dynamic>> tovarlar = [];
    try {
      tovarlar = await _airtableService.getTovarlar();
    } catch (_) {}

    Map<String, dynamic>? tanlanganTovar;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            double hisoblanganSumma = 0;
            if (tanlanganTovar != null) {
              final narxi = (tanlanganTovar!['fields']['Narxi'] ?? 0).toDouble();
              final soni = int.tryParse(soniController.text) ?? 1;
              hisoblanganSumma = narxi * soni;
            }

            return AlertDialog(
              title: const Text('Yangi sotuv qilish'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: 'Tovarni tanlang'),
                    items: tovarlar.map((t) {
                      final fields = t['fields'] ?? {};
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${fields['Nomi']} (${fields['Soni']} sht)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        tanlanganTovar = val;
                      });
                    },
                  ),
                  TextField(
                    controller: soniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sotilayotgan soni (shtuk)'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  TextField(
                    controller: xaridorController,
                    decoration: const InputDecoration(labelText: 'Xaridor ismi'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jami summa: \$$hisoblanganSumma',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tanlanganTovar != null) {
                      final fields = tanlanganTovar!['fields'] ?? {};
                      final tovarId = tanlanganTovar!['id'];
                      final joriySoni = (fields['Soni'] ?? 0) as int;
                      final sotilganSoni = int.tryParse(soniController.text) ?? 1;

                      if (sotilganSoni > joriySoni) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Omborda yetarli tovar yo\'q!')),
                        );
                        return;
                      }

                      final sotuvFields = {
                        'Mahsulot': fields['Nomi'],
                        'Summa': hisoblanganSumma,
                        'Xaridor': xaridorController.text,
                      };

                      final success = await _airtableService.addSotuv(sotuvFields);
                      if (success) {
                        await _airtableService.updateTovarSoni(tovarId, joriySoni - sotilganSoni);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _refreshSotuvlar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sotuv saqlandi va ombor yangilandi!')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bozor CRM - Sotuvlar'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSotuvlar,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sotuvlarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final sotuvlar = snapshot.data ?? [];
          if (sotuvlar.isEmpty) {
            return const Center(child: Text('Hozircha sotuvlar yo\'q'));
          }

          return ListView.builder(
            itemCount: sotuvlar.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final fields = sotuvlar[index]['fields'] ?? {};
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text(fields['Mahsulot'] ?? 'Noma\'lum', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Xaridor: ${fields['Xaridor'] ?? 'Ko\'rsatilmagan'}'),
                  trailing: Text('\$${fields['Summa'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSotuvDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ================= 2. OMBOR / TOVARLAR EKRANI (Qidiruv bilan) =================
class OmborScreen extends StatefulWidget {
  const OmborScreen({super.key});

  @override
  State<OmborScreen> createState() => _OmborScreenState();
}

class _OmborScreenState extends State<OmborScreen> {
  final AirtableService _airtableService = AirtableService();
  List<Map<String, dynamic>> _tovarlar = [];
  List<Map<String, dynamic>> _filteredTovarlar = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTovarlar();
    _searchController.addListener(_filterTovarlar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTovarlar() async {
    setState(() => _isLoading = true);
    try {
      final data = await _airtableService.getTovarlar();
      setState(() {
        _tovarlar = data;
        _filteredTovarlar = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filterTovarlar() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTovarlar = _tovarlar.where((tovar) {
        final nomi = (tovar['fields']['Nomi'] ?? '').toString().toLowerCase();
        return nomi.contains(query);
      }).toList();
    });
  }

  void _showAddTovarDialog() {
    final nomiController = TextEditingController();
    final narxiController = TextEditingController();
    final soniController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Omborga yangi tovar qo\'shish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomiController,
                decoration: const InputDecoration(labelText: 'Tovar nomi'),
              ),
              TextField(
                controller: narxiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sotish narxi (\$)'),
              ),
              TextField(
                controller: soniController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Soni (shtuk)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomiController.text.isNotEmpty) {
                  final fields = {
                    'Nomi': nomiController.text,
                    'Narxi': double.tryParse(narxiController.text) ?? 0,
                    'Soni': int.tryParse(soniController.text) ?? 0,
                  };

                  final success = await _airtableService.addTovar(fields);
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _loadTovarlar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tovar omborga qo\'shildi!')),
                      );
                    }
                  }
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ombor va Tovarlar'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTovarlar,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tovarni qidirish...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTovarlar.isEmpty
                    ? const Center(child: Text('Tovar topilmadi'))
                    : ListView.builder(
                        itemCount: _filteredTovarlar.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final fields = _filteredTovarlar[index]['fields'] ?? {};
                          final soni = fields['Soni'] ?? 0;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Text('$soni', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(fields['Nomi'] ?? 'Noma\'lum', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Omborda: $soni shtuk'),
                              trailing: Text('\$${fields['Narxi'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTovarDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ================= 3. QARZDORLAR EKRANI (Qarzni yopish bilan) =================
class QarzdorlarScreen extends StatefulWidget {
  const QarzdorlarScreen({super.key});

  @override
  State<QarzdorlarScreen> createState() => _QarzdorlarScreenState();
}

class _QarzdorlarScreenState extends State<QarzdorlarScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Map<String, dynamic>>> _qarzdorlarFuture;

  @override
  void initState() {
    super.initState();
    _refreshQarzdorlar();
  }

  void _refreshQarzdorlar() {
    setState(() {
      _qarzdorlarFuture = _airtableService.getQarzdorlar();
    });
  }

  void _showAddQarzdorDialog() {
    final xaridorController = TextEditingController();
    final qarzController = TextEditingController();
    final izohController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nasiya / Qarz yozish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xaridorController,
                decoration: const InputDecoration(labelText: 'Mijoz ismi va telefoni'),
              ),
              TextField(
                controller: qarzController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qarz summasi (\$)'),
              ),
              TextField(
                controller: izohController,
                decoration: const InputDecoration(labelText: 'Izoh / Qaysi tovar uchun'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (xaridorController.text.isNotEmpty) {
                  final fields = {
                    'Mijoz': xaridorController.text,
                    'QarzSummasi': double.tryParse(qarzController.text) ?? 0,
                    'Izoh': izohController.text,
                  };

                  final success = await _airtableService.addQarzdor(fields);
                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _refreshQarzdorlar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Qarz ro\'yxatga yozildi!')),
                      );
                    }
                  }
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteQarz(String recordId, String mijoz) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Qarzni yopish'),
          content: Text('$mijoz ning qarzini to\'landi deb yopamizmi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Yo\'q'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await _airtableService.deleteQarzdor(recordId);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _refreshQarzdorlar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Qarz muvaffaqiyatli yopildi!')),
                    );
                  }
                }
              },
              child: const Text('Ha, yopish'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nasiya va Qarzdorlar'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQarzdorlar,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _qarzdorlarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final qarzdorlar = snapshot.data ?? [];
          if (qarzdorlar.isEmpty) {
            return const Center(child: Text('Hozircha qarzdorlar yo\'q'));
          }

          return ListView.builder(
            itemCount: qarzdorlar.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = qarzdorlar[index];
              final fields = item['fields'] ?? {};
              final recordId = item['id'];
              final mijoz = fields['Mijoz'] ?? 'Noma\'lum mijoz';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(mijoz, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Izoh: ${fields['Izoh'] ?? 'Yo\'q'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${fields['QarzSummasi'] ?? 0}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () => _confirmDeleteQarz(recordId, mijoz),
                        tooltip: 'Qarzni yopish',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQarzdorDialog,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ================= 4. HISOBOTLAR EKRANI =================
class HisobotScreen extends StatefulWidget {
  const HisobotScreen({super.key});

  @override
  State<HisobotScreen> createState() => _HisobotScreenState();
}

class _HisobotScreenState extends State<HisobotScreen> {
  final AirtableService _airtableService = AirtableService();

  double _jamiSotuv = 0;
  double _jamiQarz = 0;
  int _tovarlarSoni = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final sotuvlar = await _airtableService.getSotuvlar();
      final qarzdorlar = await _airtableService.getQarzdorlar();
      final tovarlar = await _airtableService.getTovarlar();

      double sotuvSumma = 0;
      for (var s in sotuvlar) {
        sotuvSumma += (s['fields']['Summa'] ?? 0).toDouble();
      }

      double qarzSumma = 0;
      for (var q in qarzdorlar) {
        qarzSumma += (q['fields']['QarzSummasi'] ?? 0).toDouble();
      }

      int tSoni = 0;
      for (var t in tovarlar) {
        tSoni += ((t['fields']['Soni'] ?? 0) as num).toInt();
      }

      setState(() {
        _jamiSotuv = sotuvSumma;
        _jamiQarz = qarzSumma;
        _tovarlarSoni = tSoni;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobot va Tahlil'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCard('Jami Tushum (Sotuvlar)', '\$$_jamiSotuv', Icons.attach_money, Colors.green),
                _buildCard('Nasiyadagi Umumiy Qarz', '\$$_jamiQarz', Icons.money_off, Colors.deepOrange),
                _buildCard('Ombordagi Barcha Tovarlar', '$_tovarlarSoni shtuk', Icons.inventory, Colors.blueGrey),
              ],
            ),
    );
  }
}
