import 'package:flutter/foundation.dart';
import '../models/module_config.dart';
import '../services/cache_service.dart';
import '../utils/constants.dart';

class ModuleProvider with ChangeNotifier {
  final CacheService _cacheService = CacheService();

  List<ModuleConfig> _allModules = [];
  List<ModuleConfig> _pinnedModules = [];

  List<ModuleConfig> get allModules => _allModules;
  List<ModuleConfig> get pinnedModules => _pinnedModules;

  ModuleProvider() {
    _init();
  }

  Future<void> _init() async {
    await CacheService.init();
    _initializeModules();
    await loadPinnedModules();
  }

  void _initializeModules() {
    _allModules = [
      ModuleConfig(
        id: AppConstants.moduleSubmitReport,
        title: 'Submit Report',
        icon: '📄',
        pinned: false,
        order: 0,
      ),
      ModuleConfig(
        id: AppConstants.moduleViewReports,
        title: 'View Reports',
        icon: '📋',
        pinned: false,
        order: 1,
      ),
      ModuleConfig(
        id: AppConstants.moduleAISummary,
        title: 'AI Summary',
        icon: '🤖',
        pinned: false,
        order: 2,
      ),
      ModuleConfig(
        id: AppConstants.moduleSuggestions,
        title: 'Suggestions',
        icon: '💡',
        pinned: false,
        order: 3,
      ),
      ModuleConfig(
        id: AppConstants.moduleBookAppointment,
        title: 'Book Appointment',
        icon: '📅',
        pinned: false,
        order: 4,
      ),
      ModuleConfig(
        id: AppConstants.moduleMyAppointments,
        title: 'My Appointments',
        icon: '🗓️',
        pinned: false,
        order: 5,
      ),
      ModuleConfig(
        id: AppConstants.moduleShareReports,
        title: 'Share Reports',
        icon: '🔗',
        pinned: false,
        order: 6,
      ),
      ModuleConfig(
        id: AppConstants.moduleExportReports,
        title: 'Export Reports',
        icon: '📤',
        pinned: false,
        order: 7,
      ),
      ModuleConfig(
        id: AppConstants.moduleProfile,
        title: 'Profile',
        icon: '👤',
        pinned: false,
        order: 8,
      ),
    ];
  }

  Future<void> loadPinnedModules() async {
    final cached = await _cacheService.getPinnedModules();
    if (cached.isNotEmpty) {
      _pinnedModules = cached;
    } else {
      // Set default pinned modules
      _pinnedModules = _allModules
          .where((m) => AppConstants.defaultPinnedModules.contains(m.id))
          .toList();
      await savePinnedModules();
    }
    notifyListeners();
  }

  Future<void> togglePin(String moduleId) async {
    final module = _allModules.firstWhere((m) => m.id == moduleId);
    final updatedModule = module.copyWith(pinned: !module.pinned);

    // Update in all modules
    final index = _allModules.indexWhere((m) => m.id == moduleId);
    _allModules[index] = updatedModule;

    // Update pinned list
    if (updatedModule.pinned) {
      _pinnedModules.add(updatedModule);
    } else {
      _pinnedModules.removeWhere((m) => m.id == moduleId);
    }

    await savePinnedModules();
    notifyListeners();
  }

  Future<void> reorderPinnedModules(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _pinnedModules.removeAt(oldIndex);
    _pinnedModules.insert(newIndex, item);

    // Update order
    for (int i = 0; i < _pinnedModules.length; i++) {
      _pinnedModules[i] = _pinnedModules[i].copyWith(order: i);
    }

    await savePinnedModules();
    notifyListeners();
  }

  Future<void> savePinnedModules() async {
    await _cacheService.savePinnedModules(_pinnedModules);
  }

  ModuleConfig? getModuleById(String moduleId) {
    try {
      return _allModules.firstWhere((m) => m.id == moduleId);
    } catch (e) {
      return null;
    }
  }
}

