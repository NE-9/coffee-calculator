import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CoffeeMasterApp());
}

class CoffeeMasterApp extends StatelessWidget {
  const CoffeeMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const BrewCalculatorScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.coffee_maker), label: 'التحضير'),
          NavigationDestination(icon: Icon(Icons.history), label: 'السجل'),
        ],
      ),
    );
  }
}

class BrewCalculatorScreen extends StatefulWidget {
  const BrewCalculatorScreen({super.key});

  @override
  State<BrewCalculatorScreen> createState() => _BrewCalculatorScreenState();
}

class _BrewCalculatorScreenState extends State<BrewCalculatorScreen> {
  String brewMethod = 'V60';
  bool isIced = false;
  double coffeeAmount = 18.0;
  double ratio = 15.0;
  
  String selectedMachine = 'De\'Longhi';
  String selectedBeans = 'بلاك نايت';

  int secondsElapsed = 0;
  bool isTimerRunning = false;
  Timer? timer;

  double get totalWater => coffeeAmount * ratio;
  double get iceAmount => isIced ? totalWater * 0.40 : 0.0;
  double get hotWaterAmount => totalWater - iceAmount;

  String getMachineImagePath() {
    if (selectedMachine == 'De\'Longhi') {
      return 'assets/delonghi.jpg';
    }
    return 'assets/V60.jpg';
  }

  void toggleTimer() {
    if (isTimerRunning) {
      timer?.cancel();
      setState(() => isTimerRunning = false);
      saveBrewToHistory();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الوصفة في السجل!')));
    } else {
      setState(() => isTimerRunning = true);
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => secondsElapsed++);
      });
    }
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      isTimerRunning = false;
      secondsElapsed = 0;
    });
  }

  Future<void> saveBrewToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('brew_history') ?? [];
    
    Map<String, dynamic> newBrew = {
      'date': DateTime.now().toIso8601String(),
      'method': brewMethod,
      'machine': selectedMachine,
      'beans': selectedBeans,
      'coffee': coffeeAmount,
      'water': hotWaterAmount,
      'ice': iceAmount,
      'time': secondsElapsed,
      'imagePath': getMachineImagePath(),
    };
    
    history.add(jsonEncode(newBrew));
    await prefs.setStringList('brew_history', history);
  }

  String formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildAssetImage(String path, {double width = 45, double height = 45}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.brown.shade700,
child: const Icon(Icons.coffee, color: Colors.amber),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد الوصفة'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // صورة الهيدر العلوي
            Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: _buildAssetImage('assets/header.jpg', height: 140),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '$brewMethod - $selectedBeans',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // نوع التحضير
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'V60', label: Text('V60')),
                ButtonSegment(value: 'Espresso', label: Text('إسبريسو')),
              ],
              selected: {brewMethod},
              onSelectionChanged: (newSelection) {
                setState(() {
                  brewMethod = newSelection.first;
                  ratio = (brewMethod == 'Espresso') ? 2.0 : 15.0;
                  selectedMachine = (brewMethod == 'Espresso') ? 'De\'Longhi' : 'V60 Ceramic';
                });
              },
            ),
            SwitchListTile(
              title: const Text('مشروب بارد (مع ثلج)'),
              value: isIced,
              activeColor: Colors.lightBlueAccent,
              onChanged: (val) => setState(() => isIced = val),
            ),
            const Divider(),

            // اختيار الأدوات والبن
            ListTile(
              leading: _buildAssetImage(getMachineImagePath()),
              title: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'الآلة / الأداة', border: OutlineInputBorder()),
                value: selectedMachine,
                items: ['De\'Longhi', 'V60 Ceramic', 'V60 Plastic', 'أخرى']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => selectedMachine = val!),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: _buildAssetImage('assets/beans.jpg'),
              title: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'نوع البن (المحمصة)', border: OutlineInputBorder()),
                value: selectedBeans,
                items: ['بلاك نايت', 'خطوة جمل', 'أخرى']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => selectedBeans = val!),
              ),
            ),
            const Divider(),

            // أشرطة السحب
            Text('وزن البن: ${coffeeAmount.toInt()} جرام', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: coffeeAmount, min: 10, max: 30, divisions: 20, onChanged: (val) => setState(() => coffeeAmount = val)),

            Text('النسبة: 1:${ratio.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(value: ratio, min: brewMethod == 'Espresso' ? 1.5 : 12.0
           , max: brewMethod == 'Espresso' ? 3.0 : 18.0, onChanged: (val) => setState(() => ratio = val)),
            
            // مربع الحسابات
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (isIced) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الثلج:'), Text('${iceAmount.toInt()}g', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الماء الحار:'), Text('${hotWaterAmount.toInt()}g', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))]),
                  ],
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('الإجمالي:'), Text('${totalWater.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // المؤقت التفاعلي
            Center(
              child: Column(
                children: [
                  Text(formatTime(secondsElapsed), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.greenAccent)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(isTimerRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(isTimerRunning ? 'إنهاء وحفظ' : 'بدء الاستخلاص'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTimerRunning ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: toggleTimer,
                      ),
                      const SizedBox(width: 10),
                      IconButton(icon: const Icon(Icons.refresh), onPressed: resetTimer, tooltip: 'تصفير'),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = prefs.getStringList('brew_history') ?? [];
    setState(() {
      _history = historyStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList().reversed.toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('brew_history');
    setState(() => _history.clear());
  }

  Widget _buildHistoryImage(String? path) {
    if (path == null) return const Icon(Icons.coffee);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        path,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التحضير'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearHistory)
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _history.isEmpty 
        ? const Center(child: Text('لا توجد وصفات محفوظة بعد.'))
            : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final brew = _history[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: _buildHistoryImage(brew['imagePath']),
                      title: Text('${brew['method']} - ${brew['beans']}'),
                      subtitle: Text('الآلة: ${brew['machine']}\nالبن: ${brew['coffee']}g | الماء: ${brew['water']}g | الوقت: ${brew['time']} ثانية'),
                      trailing: Text(brew['date'].toString().substring(0, 10)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}