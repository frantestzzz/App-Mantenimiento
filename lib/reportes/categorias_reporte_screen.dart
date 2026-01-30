import 'package:flutter/material.dart';
import 'package:appmantflutter/reportes/lista_reportes_por_categoria_screen.dart'; // Importa la siguiente pantalla

class CategoriasReporteScreen extends StatelessWidget {
  final String disciplinaId;
  final String disciplinaNombre;

  const CategoriasReporteScreen({
    super.key,
    required this.disciplinaId,
    required this.disciplinaNombre,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categorias = _getCategorias(disciplinaId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        // Título dinámico "Reportes de [Disciplina]"
        title: Text(
          "Reportes de $disciplinaNombre",
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Text(
              "Seleccione una Categoría",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF34495E),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final item = categorias[index];
                return _CategoriaCard(
                  // Usamos el nombre de visualización
                  nombre: item['display_name'],
                  icon: item['icon'],
                  onTap: () {
                    // NAVEGACIÓN A LA LISTA DE REPORTES FILTRADA
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListaReportesPorCategoriaScreen(
                          categoriaFilter: item['filter_value'], // <-- Valor en minúscula para el filtro de BD
                          categoriaTitle: item['display_name'],  // <-- Nombre legible para el título
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- BASE DE DATOS LOCAL DE CATEGORÍAS (SWITCH CASE) ---
  List<Map<String, dynamic>> _getCategorias(String id) {
    switch (id) {
      case 'electricas':
        return [
          // display_name es para mostrar, filter_value es para la query de Firestore
          {'display_name': 'Luminarias', 'filter_value': 'luminarias', 'icon': Icons.lightbulb},
          {'display_name': 'Aparatos Eléctricos', 'filter_value': 'aparatos eléctricos', 'icon': Icons.smart_toy},
          {'display_name': 'Tableros Eléctricos', 'filter_value': 'tableros eléctricos', 'icon': Icons.flash_on},
        ];
      case 'arquitectura':
        return [
          {'display_name': 'Acabados', 'filter_value': 'acabados', 'icon': Icons.format_paint},
          {'display_name': 'Carpintería', 'filter_value': 'carpintería', 'icon': Icons.door_front_door},
        ];
      case 'estructuras':
        return [
          {'display_name': 'Vigas y Columnas', 'filter_value': 'vigas y columnas', 'icon': Icons.view_column},
        ];
      case 'mecanica':
        return [
          {'display_name': 'Bombas de Agua', 'filter_value': 'bombas de agua', 'icon': Icons.cyclone},
        ];
      case 'sanitarias':
        return [
          {'display_name': 'Griferías', 'filter_value': 'griferías', 'icon': Icons.water_drop},
        ];
      default:
        return [];
    }
  }
}

// --- WIDGET DE LA TARJETA (Row style) ---
class _CategoriaCard extends StatelessWidget {
  final String nombre; // Este es ahora el nombre para visualización
  final IconData icon;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.nombre,
    required this.icon,
    required this.onTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 30, color: const Color(0xFF3498DB)),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    nombre, // Usamos el nombre de visualización
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
