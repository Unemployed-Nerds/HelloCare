import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/appointment.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String _selectedStatus = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Listen to UserProvider changes
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.addListener(_onUserChanged);
    
    // Try to load immediately if user is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadAppointments();
    });
  }

  @override
  void dispose() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (!_hasLoadedOnce) {
      _checkAndLoadAppointments();
    }
  }

  void _checkAndLoadAppointments() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser != null && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) {
      return;
    }

    setState(() {
      if (_isInitialLoad) {
        _isInitialLoad = true;
      } else {
        _isRefreshing = true;
      }
    });
    
    try {
      await appointmentProvider.loadDoctorAppointments(currentUser.userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _isRefreshing = false;
        });
      }
    }
  }

  List<Appointment> _getFilteredAppointments(List<Appointment> appointments) {
    var filtered = appointments;

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((apt) => apt.status == _selectedStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((apt) {
        return apt.patientName.toLowerCase().contains(query) ||
            apt.patientId.toLowerCase().contains(query) ||
            (apt.notes?.toLowerCase().contains(query) ?? false) ||
            (apt.doctorNotes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Map<String, int> _getAppointmentStats(List<Appointment> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return {
      'total': appointments.length,
      'pending': appointments.where((a) => a.status == 'pending').length,
      'confirmed': appointments.where((a) => a.status == 'confirmed').length,
      'completed': appointments.where((a) => a.status == 'completed').length,
      'cancelled': appointments.where((a) => a.status == 'cancelled').length,
      'upcoming': appointments.where((a) {
        final aptDate = DateTime(a.date.year, a.date.month, a.date.day);
        return aptDate.isAfter(today) || aptDate.isAtSameMomentAs(today);
      }).length,
      'today': appointments.where((a) {
        final aptDate = DateTime(a.date.year, a.date.month, a.date.day);
        return aptDate.isAtSameMomentAs(today);
      }).length,
    };
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    final success = await appointmentProvider.updateAppointmentStatus(
      appointmentId: appointmentId,
      status: status,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment ${status} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload appointments
        await _loadAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update appointment: ${appointmentProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddNotesDialog(Appointment appointment) {
    final notesController = TextEditingController(text: appointment.doctorNotes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Add Doctor Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter notes about this appointment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.trim().isNotEmpty) {
                final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
                final success = await appointmentProvider.addDoctorNotes(
                  appointmentId: appointment.appointmentId,
                  doctorNotes: notesController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notes added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadAppointments();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add notes: ${appointmentProvider.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    // Handle case where user data hasn't loaded yet
    if (currentUser == null) {
      // If user provider is still loading, show loading indicator
      if (userProvider.isLoading) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGreen,
          appBar: AppBar(
            title: const Text('My Appointments'),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // If user is not loading and still null, show error
      return Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        appBar: AppBar(
          title: const Text('My Appointments'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load user data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.error ?? 'Please try logging in again',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppTheme.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading indicator on initial load
    if (_isInitialLoad && appointmentProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        appBar: AppBar(
          title: const Text('My Appointments'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get appointments list
    final appointments = appointmentProvider.appointments;
    final stats = _getAppointmentStats(appointments);
    final filteredAppointments = _getFilteredAppointments(appointments);

    // Handle error state
    if (appointmentProvider.error != null && !_isInitialLoad) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        appBar: AppBar(
          title: const Text('My Appointments'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadAppointments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading appointments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointmentProvider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Statistics Cards
                  if (appointments.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatCard('Total', stats['total']!, Icons.calendar_today, AppTheme.primaryGreen),
                            const SizedBox(width: 12),
                            _buildStatCard('Pending', stats['pending']!, Icons.pending, AppTheme.accentPink),
                            const SizedBox(width: 12),
                            _buildStatCard('Today', stats['today']!, Icons.today, AppTheme.accentBlue),
                            const SizedBox(width: 12),
                            _buildStatCard('Upcoming', stats['upcoming']!, Icons.upcoming, AppTheme.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by patient name...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant.withOpacity(0.5),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Filter Chips
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildStatusChip('all', 'All', stats['total']!),
                        const SizedBox(width: 8),
                        _buildStatusChip('pending', 'Pending', stats['pending']!),
                        const SizedBox(width: 8),
                        _buildStatusChip('confirmed', 'Confirmed', stats['confirmed']!),
                        const SizedBox(width: 8),
                        _buildStatusChip('completed', 'Completed', stats['completed']!),
                        const SizedBox(width: 8),
                        _buildStatusChip('cancelled', 'Cancelled', stats['cancelled']!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Appointments List
                  Expanded(
                    child: filteredAppointments.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 400,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 64, color: AppTheme.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      appointments.isEmpty
                                          ? 'No appointments scheduled'
                                          : 'No appointments match your filters',
                                      style: const TextStyle(fontSize: 18, color: AppTheme.grey),
                                    ),
                                    if (appointmentProvider.error != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        appointmentProvider.error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14, color: AppTheme.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = filteredAppointments[index];
                              return _buildDoctorAppointmentCard(appointment);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, int count) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDoctorAppointmentCard(Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Main appointment info
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to appointment detail page
                // TODO: Create doctor appointment detail page
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('MMM dd, yyyy').format(appointment.date)} at ${appointment.time}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Patient notes: ${appointment.notes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor,
                                  statusColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              appointment.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Quick action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (appointment.status == 'pending')
                  _buildActionButton(
                    'Confirm',
                    Icons.check_circle,
                    AppTheme.primaryGreen,
                    () => _updateAppointmentStatus(appointment.appointmentId, 'confirmed'),
                  ),
                if (appointment.status == 'confirmed')
                  _buildActionButton(
                    'Complete',
                    Icons.done_all,
                    AppTheme.accentBlue,
                    () => _updateAppointmentStatus(appointment.appointmentId, 'completed'),
                  ),
                if (appointment.status != 'cancelled' && appointment.status != 'completed')
                  _buildActionButton(
                    'Cancel',
                    Icons.cancel,
                    AppTheme.errorRed,
                    () => _updateAppointmentStatus(appointment.appointmentId, 'cancelled'),
                  ),
                _buildActionButton(
                  appointment.doctorNotes != null && appointment.doctorNotes!.isNotEmpty
                      ? 'Edit Notes'
                      : 'Add Notes',
                  Icons.note_add,
                  AppTheme.accentPink,
                  () => _showAddNotesDialog(appointment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryGreen;
      case 'pending':
        return AppTheme.accentPink;
      case 'completed':
        return AppTheme.grey;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.grey;
    }
  }
}
