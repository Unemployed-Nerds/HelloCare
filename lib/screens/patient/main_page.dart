import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../providers/module_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/module_block.dart';

class _DelayedAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const _DelayedAnimation({
    required this.child,
    required this.delay,
    required this.duration,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<_DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<_DelayedAnimation> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _show = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) {
      return Opacity(
        opacity: 0,
        child: Transform.translate(
          offset: const Offset(-30, 0),
          child: widget.child,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-30 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.9),
                AppTheme.primaryGreenDark.withOpacity(0.9),
                AppTheme.darkGreen.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'HelloCare',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
      drawer: _buildDrawer(context, moduleProvider, userProvider),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.backgroundGreen,
              AppTheme.backgroundDark,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh data if needed
          },
          child: CustomScrollView(
            slivers: [
              // Greeting Section
              SliverToBoxAdapter(
                child: _buildGreetingSection(context, userProvider),
              ),
              
              // Divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(
                    color: AppTheme.divider.withOpacity(0.5),
                    thickness: 1,
                    height: 1,
                  ),
                ),
              ),
              
              // Modules Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryGreen.withOpacity(0.3),
                                  AppTheme.primaryGreenDark.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.apps,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Quick Access',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen.withOpacity(0.2),
                              AppTheme.primaryGreenDark.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.primaryGreen,
                          ),
                          onPressed: () => _showAddModuleDialog(context, moduleProvider),
                          tooltip: 'Add Module',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Modules Grid
              moduleProvider.pinnedModules.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.primaryGreen.withOpacity(0.3),
                                  AppTheme.primaryGreenDark.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.dashboard_outlined,
                              size: 64,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No modules pinned',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the + button to add modules',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final module = moduleProvider.pinnedModules[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 80)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: ModuleBlock(
                              module: module,
                              onTap: () => _navigateToModule(context, module.id),
                            ),
                          );
                        },
                        childCount: moduleProvider.pinnedModules.length,
                      ),
                    ),
                  ),
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection(BuildContext context, UserProvider userProvider) {
    final username = userProvider.currentUser?.name ?? 'User';
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $username! 👋',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.15),
                    AppTheme.primaryGreenDark.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen.withOpacity(0.3),
                              AppTheme.primaryGreenDark.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.wb_sunny_outlined,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "What's up today?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ready to take care of your health? Explore your modules below and stay on top of your wellness journey.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreenDark,
                  AppTheme.darkGreen,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.webp',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    userProvider.currentUser?.name ?? 'User',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    userProvider.currentUser?.email ?? '',
                    style: TextStyle(
                      color: AppTheme.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ...moduleProvider.allModules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            final isPinned = moduleProvider.pinnedModules
                .any((pinned) => pinned.id == module.id);
              return _DelayedAnimation(
                delay: Duration(milliseconds: index * 120),
                duration: const Duration(milliseconds: 350),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPinned
                          ? [
                              AppTheme.primaryGreen.withOpacity(0.2),
                              AppTheme.primaryGreenDark.withOpacity(0.1),
                            ]
                          : [
                              AppTheme.surfaceVariant.withOpacity(0.3),
                              AppTheme.surfaceDark.withOpacity(0.2),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPinned
                          ? AppTheme.primaryGreen.withOpacity(0.5)
                          : AppTheme.white.withOpacity(0.1),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen.withOpacity(0.3),
                            AppTheme.primaryGreenDark.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: module.icon.startsWith('assets/')
                          ? Image.asset(
                              module.icon,
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            )
                          : Text(module.icon, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text(
                      module.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isPinned
                            ? AppTheme.primaryGreen
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPinned
                                ? [
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreenDark,
                                  ]
                                : [
                                    AppTheme.lightGrey,
                                    AppTheme.darkGrey,
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isPinned
                                      ? AppTheme.primaryGreen
                                      : AppTheme.lightGrey)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: isPinned ? AppTheme.white : AppTheme.grey,
                          size: 18,
                        ),
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
                  ),
                ),
              );
          }),
          const Divider(height: 32),
          _DelayedAnimation(
            delay: Duration(milliseconds: moduleProvider.allModules.length * 120),
            duration: const Duration(milliseconds: 350),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.errorRed.withOpacity(0.2),
                    AppTheme.errorRed.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.errorRed.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorRed.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.errorRed.withOpacity(0.3),
                        AppTheme.errorRed.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppTheme.errorRed,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorRed,
                  ),
                ),
                onTap: () async {
                  await userProvider.signOut();
                  if (context.mounted) {
                    context.go('/role-selection');
                  }
                },
              ),
            ),
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
        title: const Text(
          'Add Module',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moduleProvider.allModules.length,
            itemBuilder: (context, index) {
              final module = moduleProvider.allModules[index];
              final isPinned = moduleProvider.pinnedModules
                  .any((pinned) => pinned.id == module.id);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPinned
                        ? [
                            AppTheme.primaryGreen.withOpacity(0.2),
                            AppTheme.primaryGreenDark.withOpacity(0.1),
                          ]
                        : [
                            AppTheme.surfaceVariant.withOpacity(0.3),
                            AppTheme.surfaceDark.withOpacity(0.2),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPinned
                        ? AppTheme.primaryGreen.withOpacity(0.5)
                        : AppTheme.white.withOpacity(0.1),
                    width: isPinned ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.3),
                          AppTheme.primaryGreenDark.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: module.icon.startsWith('assets/')
                        ? Image.asset(
                            module.icon,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          )
                        : Text(module.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  title: Text(
                    module.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPinned
                          ? AppTheme.primaryGreen
                          : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPinned
                            ? [
                                AppTheme.primaryGreen,
                                AppTheme.primaryGreenDark,
                              ]
                            : [
                                AppTheme.lightGrey,
                                AppTheme.darkGrey,
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPinned
                                  ? AppTheme.primaryGreen
                                  : AppTheme.lightGrey)
                              .withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPinned ? Icons.check : Icons.add,
                      color: isPinned ? AppTheme.white : AppTheme.grey,
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    moduleProvider.togglePin(module.id);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

