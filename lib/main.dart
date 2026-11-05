import 'package:flutter/material.dart';

import 'screens/cuenta.dart';
import 'screens/personas.dart';
import 'screens/semana.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.cargar();
  runApp(FinanzasApp(store: store));
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis viajes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: Inicio(store: store),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key, required this.store});

  final AppStore store;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      SemanaScreen(store: widget.store),
      CuentaScreen(store: widget.store),
      PersonasScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Semana',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Cuenta',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Personas',
          ),
        ],
      ),
    );
  }
}
