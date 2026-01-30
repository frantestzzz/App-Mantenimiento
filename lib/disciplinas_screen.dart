import 'package:flutter/material.dart';
import 'package:appmantflutter/productos/lista_productos_screen.dart'; // Usaremos esta pantalla para listar productos por Disciplina

// Definimos un modelo simple para los datos
class DisciplinaData {
  final String id;
  final String nombre;
  final IconData icon;
  final Color color;

  DisciplinaData(this.id, this.nombre, this.icon, this.color);
}

class DisciplinasScreen extends StatelessWidget {
  const DisciplinasScreen({super.key});

  // Lista de datos estática
  static final List<DisciplinaData> disciplinas = [
    DisciplinaData('arquitectura', 'Arquitectura', Icons.account_balance, const Color(0xFF3498db)),
    DisciplinaData('electricas', 'Eléctricas', Icons.bolt, const Color(0xFFf1c40f)),
    DisciplinaData('estructuras', 'Estructuras', Icons.domain, const Color(0xFF95a5a6)),
    DisciplinaData('mecanica', 'Mecánica', Icons.settings, const Color(0xFFe67e22)),
    DisciplinaData('sanitarias', 'Sanitarias', Icons.water_drop, const Color(0xFF1abc9c)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Disciplinas'),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Seleccione una Disciplina',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF34495e),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: disciplinas.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final item = disciplinas[index];
                return _DisciplinaCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplinaCard extends StatelessWidget {
  final DisciplinaData item;

  const _DisciplinaCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: InkWell(
        onTap: () {
          // NAVEGACIÓN A LA LISTA DE PRODUCTOS FILTRADA POR DISCIPLINA
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListaProductosScreen(
                filterBy: 'disciplina', // Nuevo parámetro de filtro
                filterValue: item.id,
                title: item.nombre,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 40,
              color: item.color,
            ),
            const SizedBox(height: 15),
            Text(
              item.nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF34495e),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
