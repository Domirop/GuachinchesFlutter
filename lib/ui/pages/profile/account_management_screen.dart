import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/cubit/account/account_cubit.dart';
import 'package:guachinches/data/cubit/account/account_state.dart';
import 'package:share_plus/share_plus.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountCubit, AccountState>(
      listener: (context, state) {
        if (state is AccountExportReady) {
          Share.shareXFiles([XFile(state.file.path)]);
        }
        if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.base : AppColors.crema;
        final surface = isDark ? AppColors.surface : Colors.white;
        final cubit = context.read<AccountCubit>();

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? AppColors.crema : AppColors.ink,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Mi cuenta',
              style: AppTextStyles.ui(
                size: 17,
                weight: FontWeight.w700,
                color: isDark ? AppColors.crema : AppColors.ink,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Deletion pending banner
              if (state is AccountDeletionScheduled)
                Semantics(
                  identifier: 'account-delete-scheduled-banner',
                  child: _DeletionBanner(scheduledAt: state.scheduledAt),
                ),

              const SizedBox(height: 8),

              // DESCARGAR MIS DATOS
              _SectionCard(
                isDark: isDark,
                surface: surface,
                title: 'Descargar mis datos',
                icon: Icons.download_rounded,
                iconColor: AppColors.atlantico,
                description:
                    'Exporta toda la información vinculada a tu cuenta en formato JSON.',
                child: state is AccountExporting
                    ? Semantics(
                        identifier: 'account-export-loader',
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.atlantico,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : Semantics(
                        identifier: 'account-export-button',
                        child: _ActionButton(
                          label: 'Exportar mis datos',
                          color: AppColors.atlantico,
                          onTap: () => cubit.exportData(),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // ELIMINAR MI CUENTA
              _SectionCard(
                isDark: isDark,
                surface: surface,
                title: 'Eliminar mi cuenta',
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.mojo,
                description:
                    'Solicitamos la eliminación de tu cuenta. Tienes 30 días para cancelar el proceso.',
                child: state is AccountDeletionScheduled
                    ? Semantics(
                        identifier: 'account-delete-cancel-button',
                        child: _ActionButton(
                          label: 'Cancelar eliminación',
                          color: AppColors.laurisilva,
                          onTap: () => cubit.cancelDeletion(),
                        ),
                      )
                    : Semantics(
                        identifier: 'account-delete-request-button',
                        child: _ActionButton(
                          label: 'Solicitar eliminación',
                          color: AppColors.mojo,
                          onTap: () => _showConfirmDeleteDialog(context, cubit),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, AccountCubit cubit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        title: Text(
          'Eliminar cuenta',
          style: AppTextStyles.ui(
            size: 17,
            weight: FontWeight.w700,
            color: AppColors.mojo,
          ),
        ),
        content: Text(
          'Tu cuenta y datos se eliminarán tras 30 días. Puedes cancelar el proceso antes de que expire el plazo.',
          style: AppTextStyles.ui(
            size: 14,
            color: isDark ? AppColors.crema.withOpacity(0.8) : AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancelar',
              style: AppTextStyles.ui(
                size: 14,
                color: isDark ? AppColors.crema.withOpacity(0.6) : AppColors.inkSoft,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.requestDeletion();
            },
            child: Text(
              'Eliminar',
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.mojo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletionBanner extends StatelessWidget {
  final DateTime scheduledAt;

  const _DeletionBanner({required this.scheduledAt});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDate(scheduledAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sol.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sol.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.sol, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cuenta programada para eliminarse el $formatted.',
              style: AppTextStyles.ui(size: 13, color: AppColors.sol),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String description;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.surface,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.ui(
                  size: 15,
                  weight: FontWeight.w700,
                  color: isDark ? AppColors.crema : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.ui(
              size: 13,
              color: isDark ? AppColors.crema.withOpacity(0.6) : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.ui(
            size: 14,
            weight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
