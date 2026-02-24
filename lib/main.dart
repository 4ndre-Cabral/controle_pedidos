import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/solicitar_page.dart';
import 'screens/pedidos_page.dart';
import 'services/excel_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip Excel initialization on web since dart:io is not available
  if (!kIsWeb) {
    await ExcelService().init();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Pedidos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Inicial'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Solicitar'),
              onTap: () {
                // Close the drawer
                Navigator.pop(context);
                // Navigate to Solicitar
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SolicitarPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Pedidos'),
              onTap: () {
                // Close the drawer
                Navigator.pop(context);
                // Navigate to Pedidos
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PedidosPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Bem-vindo! Selecione uma opção no menu.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
