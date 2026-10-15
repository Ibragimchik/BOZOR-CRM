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
    
    // Ombordagi tovarlarni olamiz
    List<Map<String, dynamic>> tovarlar = [];
    try {
      tovarlar = await _airtableService.getTovarlar();
    } catch (e) {
      // Xatolik bo'lsa bo'sh qoladi
    }

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
                        // Ombordagi sonini kamaytiramiz
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

// ================= 2. OMBOR / TOVARLAR EKRANI =================
class OmborScreen extends StatefulWidget {
  const OmborScreen({super.key});

  @override
  State<OmborScreen> createState() => _OmborScreenState();
}

class _OmborScreenState extends State<OmborScreen> {
  final AirtableService _airtableService = AirtableService();
  late Future<List<Map<String, dynamic>>> _tovarlarFuture;

  @override
  void initState() {
    super.initState();
    _refreshTovarlar();
  }

  void _refreshTovarlar() {
    setState(() {
      _tovarlarFuture = _airtableService.getTovarlar();
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
                      _refreshTovarlar();
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
            onPressed: _refreshTovarlar,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tovarlarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final tovarlar = snapshot.data ?? [];
          if (tovarlar.isEmpty) {
            return const Center(child: Text('Omborda tovar yo\'q'));
          }

          return ListView.builder(
            itemCount: tovarlar.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final fields = tovarlar[index]['fields'] ?? {};
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTovarDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ================= 3. QARZDORLAR EKRANI =================
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
              final fields = qarzdorlar[index]['fields'] ?? {};

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(fields['Mijoz'] ?? 'Noma\'lum mijoz', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Izoh: ${fields['Izoh'] ?? 'Yo\'q'}'),
                  trailing: Text('\$${fields['QarzSummasi'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
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
    } catch (e) {
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
