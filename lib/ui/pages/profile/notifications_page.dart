import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  bool _novedadesSemanales = false;
  bool _recordatoriosValoracion = false;
  bool _promociones = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: 'notificaciones-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        appBar: AppBar(
          backgroundColor: brand.base,
          elevation: 0,
          title: Text(
            'Notificaciones',
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Novedades semanales',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Recibe un resumen semanal con los mejores restaurantes',
                  style: AppTextStyles.ui(size: 12, color: brand.textMuted),
                ),
                value: _novedadesSemanales,
                activeColor: AppColors.atlantico,
                onChanged: (v) => setState(() => _novedadesSemanales = v),
              ),
              Divider(color: brand.borderStrong, height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Recordatorios de valoración',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Te recordamos que valores tus visitas recientes',
                  style: AppTextStyles.ui(size: 12, color: brand.textMuted),
                ),
                value: _recordatoriosValoracion,
                activeColor: AppColors.atlantico,
                onChanged: (v) => setState(() => _recordatoriosValoracion = v),
              ),
              Divider(color: brand.borderStrong, height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Promociones',
                  style: AppTextStyles.ui(
                    size: 14,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Ofertas y promociones especiales de restaurantes',
                  style: AppTextStyles.ui(size: 12, color: brand.textMuted),
                ),
                value: _promociones,
                activeColor: AppColors.atlantico,
                onChanged: (v) => setState(() => _promociones = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
