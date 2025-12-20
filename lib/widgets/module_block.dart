import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/glass_effects.dart';
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
    return Container(
      decoration: GlassEffects.glassCard(
        primaryColor: AppTheme.surfaceVariant,
        accentColor: AppTheme.primaryGreen,
        opacity: 0.4,
        borderRadius: 24.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: module.icon.startsWith('assets/')
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
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      module.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}


