import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/module_config.dart';

class ModuleBlock extends StatelessWidget {
  final ModuleConfig module;
  final VoidCallback onTap;

  const ModuleBlock({
    super.key,
    required this.module,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppTheme.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceVariant.withOpacity(0.8),
                AppTheme.surfaceDark.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 12,
                offset: Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              module.icon.startsWith('assets/')
                  ? Image.asset(
                      module.icon,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen.withOpacity(0.3),
                            AppTheme.primaryGreenDark.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        module.icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
              // Glassmorphism overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


