import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key});

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _rolCtrl = TextEditingController();

  Future<void> _guardarUsuario() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('usuarios').add({
          'nombre': _nombreCtrl.text.trim(),
          'dni': _dniCtrl.text.trim(),
          'cargo': _cargoCtrl.text.trim(),
          'area': _areaCtrl.text.trim(),
          'celular': _celularCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'rol': _rolCtrl.text.trim(),
          'fechaRegistro': FieldValue.serverTimestamp(),
          'avatarUrl': '',
          'firmaUrl': '',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario guardado exitosamente')),
          );
          Navigator.pop(context); // Regresar a la lista
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpiar controladores
    _nombreCtrl.dispose(); _dniCtrl.dispose(); _cargoCtrl.dispose();
    _areaCtrl.dispose(); _celularCtrl.dispose(); _emailCtrl.dispose(); _rolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Agregar Nuevo Usuario"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Nombre Completo*"),
              _buildTextField(_nombreCtrl, "Ingrese nombre", required: true),

              _buildInputLabel("DNI*"),
              _buildTextField(_dniCtrl, "Ingrese DNI", required: true, isNumber: true),

              _buildInputLabel("Cargo*"),
              _buildTextField(_cargoCtrl, "Ej: Técnico Electricista", required: true),

              _buildInputLabel("Área"),
              _buildTextField(_areaCtrl, "Ej: Mantenimiento"),

              _buildInputLabel("Celular"),
              _buildTextField(_celularCtrl, "Ingrese celular", isNumber: true),

              _buildInputLabel("Email"),
              _buildTextField(_emailCtrl, "Ingrese email"),

              _buildInputLabel("Rol*"),
              _buildTextField(_rolCtrl, "Ej: admin, tecnico", required: true),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: _guardarUsuario,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Guardar"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF495057))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool required = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCED4DA))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
