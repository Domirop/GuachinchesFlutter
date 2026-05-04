import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';

/// Bottom sheet paso 2: selección de municipio dentro de una zona.
class MunicipalityPickerSheet extends StatelessWidget {
  final String zoneLabel;
  final List<SimpleMunicipality> municipalities;
  final String? selectedId;
  final ValueChanged<SimpleMunicipality?> onSelect; // null → "toda la zona"

  const MunicipalityPickerSheet({
    super.key,
    required this.zoneLabel,
    required this.municipalities,
    this.selectedId,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String zoneLabel,
    required List<SimpleMunicipality> municipalities,
    String? selectedId,
    required ValueChanged<SimpleMunicipality?> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.brand.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => MunicipalityPickerSheet(
          zoneLabel: zoneLabel,
          municipalities: municipalities,
          selectedId: selectedId,
          onSelect: onSelect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'MUNICIPIOS · ${zoneLabel.toUpperCase()}',
            style: AppTextStyles.eyebrow(
              size: 10,
              color: context.brand.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          // Botón "Sin filtrar"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onSelect(null);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedId == null
                      ? AppColors.atlantico.withOpacity(0.2)
                      : context.brand.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedId == null
                        ? AppColors.atlantico.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  'Sin filtrar municipio — toda la zona',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.brand.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              itemCount: municipalities.length,
              itemBuilder: (_, i) {
                final muni = municipalities[i];
                final active = selectedId == muni.id;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(muni);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.atlantico.withOpacity(0.2)
                          : context.brand.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? AppColors.atlantico.withOpacity(0.5)
                            : context.brand.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        muni.nombre,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displaySection(
                          size: 11,
                          color: active
                              ? AppColors.atlanticoClaro
                              : context.brand.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
