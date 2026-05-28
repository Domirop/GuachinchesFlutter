import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class AyudaPage extends StatelessWidget {
  const AyudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'ayuda-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        appBar: AppBar(
          backgroundColor: brand.base,
          elevation: 0,
          title: Text(
            'Ayuda y soporte',
            style: AppTextStyles.displayHero(size: 20),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: brand.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              ExpansionTile(
                iconColor: AppColors.atlantico,
                collapsedIconColor: brand.textMuted,
                title: Text(
                  'Cómo valorar un restaurante',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Visita la ficha del restaurante y desliza hasta la sección de valoraciones. Toca el botón "Valorar" y selecciona tu puntuación del 1 al 5. Escribe una reseña opcional y confirma para publicar tu valoración.',
                      style: AppTextStyles.ui(size: 13, color: brand.textSecondary),
                    ),
                  ),
                ],
              ),
              Divider(color: brand.borderStrong, height: 1),
              ExpansionTile(
                iconColor: AppColors.atlantico,
                collapsedIconColor: brand.textMuted,
                title: Text(
                  'Gestionar favoritos',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Toca el icono de marcador en la ficha de cualquier restaurante para guardarlo en favoritos. Accede a todos tus favoritos desde la sección "Favoritos" en tu perfil. Puedes eliminarlos tocando de nuevo el icono.',
                      style: AppTextStyles.ui(size: 13, color: brand.textSecondary),
                    ),
                  ),
                ],
              ),
              Divider(color: brand.borderStrong, height: 1),
              ExpansionTile(
                iconColor: AppColors.atlantico,
                collapsedIconColor: brand.textMuted,
                title: Text(
                  'Contactar con nosotros',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Si necesitas ayuda adicional, escríbenos a hola@dondecocomercanarias.es. Respondemos en un plazo máximo de 48 horas en días laborables. También puedes encontrarnos en nuestras redes sociales.',
                      style: AppTextStyles.ui(size: 13, color: brand.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
