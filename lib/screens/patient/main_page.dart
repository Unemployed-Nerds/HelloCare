import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../providers/module_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/module_block.dart';

class PatientMainPage extends StatefulWidget {
  const PatientMainPage({super.key});

  @override
  State<PatientMainPage> createState() => _PatientMainPageState();
}

class _PatientMainPageState extends State<PatientMainPage> {
  @override
  Widget build(BuildContext context) {
    final moduleProvider = Provider.of<ModuleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('HelloCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddModuleDialog(context, moduleProvider),
            tooltip: 'Add Module',
          ),
        ],
      ),
      drawer: _buildDrawer(context, moduleProvider, userProvider),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data if needed
        },
        child: moduleProvider.pinnedModules.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dashboard,
                      size: 64,
                      color: AppTheme.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No modules pinned',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the + button to add modules',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: moduleProvider.pinnedModules.length,
                itemBuilder: (context, index) {
                  final module = moduleProvider.pinnedModules[index];
                  return ModuleBlock(
                    module: module,
                    onTap: () => _navigateToModule(context, module.id),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    ModuleProvider moduleProvider,
    UserProvider userProvider,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 48,
                  color: AppTheme.white,
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.currentUser?.name ?? 'User',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userProvider.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...moduleProvider.allModules.map((module) {
            final isPinned = moduleProvider.pinnedModules
                .any((pinned) => pinned.id == module.id);
            return ListTile(
              leading: Text(module.icon, style: const TextStyle(fontSize: 24)),
              title: Text(module.title),
              trailing: IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? AppTheme.primaryGreen : AppTheme.grey,
                ),
                onPressed: () {
                  moduleProvider.togglePin(module.id);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToModule(context, module.id);
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await userProvider.signOut();
              if (context.mounted) {
                context.go('/role-selection');
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToModule(BuildContext context, String moduleId) {
    switch (moduleId) {
      case AppConstants.moduleSubmitReport:
        context.go('/patient/submit-report');
        break;
      case AppConstants.moduleViewReports:
        context.go('/patient/reports');
        break;
      case AppConstants.moduleAISummary:
        context.go('/patient/ai-summary');
        break;
      case AppConstants.moduleSuggestions:
        context.go('/patient/suggestions');
        break;
      case AppConstants.moduleBookAppointment:
        context.go('/patient/book-appointment');
        break;
      case AppConstants.moduleMyAppointments:
        context.go('/patient/appointments');
        break;
      case AppConstants.moduleShareReports:
        context.go('/patient/share-reports');
        break;
      case AppConstants.moduleExportReports:
        context.go('/patient/export-reports');
        break;
      case AppConstants.moduleProfile:
        context.go('/patient/profile');
        break;
    }
  }

  void _showAddModuleDialog(
    BuildContext context,
    ModuleProvider moduleProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Module'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moduleProvider.allModules.length,
            itemBuilder: (context, index) {
              final module = moduleProvider.allModules[index];
              final isPinned = moduleProvider.pinnedModules
                  .any((pinned) => pinned.id == module.id);
              return ListTile(
                leading: Text(module.icon, style: const TextStyle(fontSize: 24)),
                title: Text(module.title),
                trailing: Icon(
                  isPinned ? Icons.check : Icons.add,
                  color: isPinned ? AppTheme.primaryGreen : AppTheme.grey,
                ),
                onTap: () {
                  if (!isPinned) {
                    moduleProvider.togglePin(module.id);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

