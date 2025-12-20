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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                module.icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                module.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


