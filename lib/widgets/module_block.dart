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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                alignment: Alignment.center,
                child: Text(
                  module.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
      ),
    );
  }
}


