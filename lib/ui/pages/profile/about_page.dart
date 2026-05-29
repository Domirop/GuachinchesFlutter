import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class AcercaDePage extends StatelessWidget {
  const AcercaDePage({super.key});

  void _mostrarProximamente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'acerca-de-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        appBar: AppBar(
          backgroundColor: brand.base,
          elevation: 0,
          title: Text(
            'Acerca de',
            style: AppTextStyles.displayHero(size: 20),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: brand.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.atlantico.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    size: 40,
                    color: AppColors.atlantico,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  '¿Dónde Comer Canarias?',
                  style: AppTextStyles.displayHero(size: 22),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'v1.0.0',
                  style: AppTextStyles.ui(size: 13, color: brand.textMuted),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'GuachinchesModernos',
                  style: AppTextStyles.eyebrow(size: 10, color: brand.textMuted),
                ),
              ),
              const SizedBox(height: 32),
              Divider(color: brand.borderStrong),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Términos y condiciones',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: brand.textPrimary,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: brand.textMuted),
                onTap: () => _mostrarProximamente(context),
              ),
              Divider(color: brand.borderStrong, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Política de privacidad',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: brand.textPrimary,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: brand.textMuted),
                onTap: () => _mostrarProximamente(context),
              ),
              Divider(color: brand.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}
