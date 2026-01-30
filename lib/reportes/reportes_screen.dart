import 'package:flutter/material.dart';
import 'package:appmantflutter/reportes/categorias_reporte_screen.dart'; // Importa la siguiente pantalla

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  // Lista de datos para las tarjetas de disciplina
  static final List<Map<String, dynamic>> disciplinasReporte = [
    {'id': 'arquitectura', 'nombre': 'Arquitectura', 'icon': Icons.account_balance, 'color': const Color(0xFF3498DB)},
    {'id': 'electricas', 'nombre': 'Eléctricas', 'icon': Icons.bolt, 'color': const Color(0xFFF1C40F)},
    {'id': 'estructuras', 'nombre': 'Estructuras', 'icon': Icons.apartment, 'color': const Color(0xFF7F8C8D)},
    {'id': 'mecanica', 'nombre': 'Mecánica', 'icon': Icons.miscellaneous_services, 'color': const Color(0xFFE67E22)},
    {'id': 'sanitarias', 'nombre': 'Sanitarias', 'icon': Icons.water_drop, 'color': const Color(0xFF1ABC9C)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Reportes"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Filtrar Reportes por Disciplina",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF34495E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // WRAP para el layout de la grilla con centrado
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: disciplinasReporte.map((item) {
                return _ReportCard(
                  title: item['nombre'],
                  icon: item['icon'],
                  color: item['color'],
                  onTap: () {
                    // NAVEGACIÓN A CATEGORÍAS
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoriasReporteScreen(
                          disciplinaId: item['id'],
                          disciplinaNombre: item['nombre'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget privado para la tarjeta de Reportes
class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final double cardSize = (MediaQuery.of(context).size.width / 2) - 30;

    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: cardSize,
          height: cardSize * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
