import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  String? _islaSeleccionada;

  static const _islas = [
    'Tenerife',
    'Gran Canaria',
    'Lanzarote',
    'Fuerteventura',
    'La Palma',
    'La Gomera',
    'El Hierro',
    'La Graciosa',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambios guardados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'editar-perfil-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        appBar: AppBar(
          backgroundColor: brand.base,
          elevation: 0,
          title: Text(
            'Editar perfil',
            style: AppTextStyles.displayHero(size: 20),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: brand.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  'NOMBRE',
                  style: AppTextStyles.eyebrow(size: 10, color: brand.textMuted),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  style: AppTextStyles.ui(size: 15, color: brand.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre',
                    hintStyle: AppTextStyles.ui(size: 15, color: brand.textMuted),
                    filled: true,
                    fillColor: brand.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: brand.borderStrong),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: brand.borderStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.atlantico),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'EMAIL',
                  style: AppTextStyles.eyebrow(size: 10, color: brand.textMuted),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  style: AppTextStyles.ui(size: 15, color: brand.textMuted),
                  decoration: InputDecoration(
                    hintText: 'tu@email.com',
                    hintStyle: AppTextStyles.ui(size: 15, color: brand.textMuted),
                    filled: true,
                    fillColor: brand.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: brand.borderStrong),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: brand.borderStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: brand.borderStrong),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: Icon(Icons.lock_outline_rounded, size: 16, color: brand.textMuted),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ISLA',
                  style: AppTextStyles.eyebrow(size: 10, color: brand.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: brand.surface,
                    border: Border.all(color: brand.borderStrong),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _islaSeleccionada,
                      hint: Text(
                        'Selecciona tu isla',
                        style: AppTextStyles.ui(size: 15, color: brand.textMuted),
                      ),
                      isExpanded: true,
                      dropdownColor: brand.elevated,
                      style: AppTextStyles.ui(size: 15, color: brand.textPrimary),
                      items: _islas.map((isla) {
                        return DropdownMenuItem<String>(
                          value: isla,
                          child: Text(isla),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _islaSeleccionada = value),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.atlantico,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Guardar cambios',
                    style: AppTextStyles.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
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
