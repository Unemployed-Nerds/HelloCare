import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/user_provider.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  const DoctorAvailabilityPage({super.key});

  @override
  State<DoctorAvailabilityPage> createState() => _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState extends State<DoctorAvailabilityPage> {
  Map<String, Map<String, dynamic>> _availability = {
    'monday': {'start': '09:00', 'end': '17:00', 'available': true},
    'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
    'friday': {'start': '09:00', 'end': '17:00', 'available': true},
    'saturday': {'start': null, 'end': null, 'available': false},
    'sunday': {'start': null, 'end': null, 'available': false},
  };
  bool _isLoading = true;
  String? _editingDay; // Track which day is currently being edited

  // Generate time slots for dropdown (every 30 minutes from 00:00 to 23:30)
  List<String> _getTimeSlots() {
    final List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(timeStr);
      }
    }
    return times;
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Get user ID - try from UserProvider first, then Firebase Auth
    String? userId;
    var currentUser = userProvider.currentUser;
    if (currentUser != null) {
      userId = currentUser.userId;
    } else {
      // If user data not loaded, try to get from Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
        // Try to load user data
        await userProvider.loadUserData(userId);
        currentUser = userProvider.currentUser;
      }
    }
    
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await doctorProvider.loadDoctor(userId);
      final doctor = doctorProvider.selectedDoctor;
      
      if (doctor != null && doctor.availability.isNotEmpty) {
        setState(() {
          // Convert DoctorAvailability objects to the format expected by the UI
          _availability = {
            'monday': {
              'start': doctor.availability['monday']?.start,
              'end': doctor.availability['monday']?.end,
              'available': doctor.availability['monday']?.available ?? false,
            },
            'tuesday': {
              'start': doctor.availability['tuesday']?.start,
              'end': doctor.availability['tuesday']?.end,
              'available': doctor.availability['tuesday']?.available ?? false,
            },
            'wednesday': {
              'start': doctor.availability['wednesday']?.start,
              'end': doctor.availability['wednesday']?.end,
              'available': doctor.availability['wednesday']?.available ?? false,
            },
            'thursday': {
              'start': doctor.availability['thursday']?.start,
              'end': doctor.availability['thursday']?.end,
              'available': doctor.availability['thursday']?.available ?? false,
            },
            'friday': {
              'start': doctor.availability['friday']?.start,
              'end': doctor.availability['friday']?.end,
              'available': doctor.availability['friday']?.available ?? false,
            },
            'saturday': {
              'start': doctor.availability['saturday']?.start,
              'end': doctor.availability['saturday']?.end,
              'available': doctor.availability['saturday']?.available ?? false,
            },
            'sunday': {
              'start': doctor.availability['sunday']?.start,
              'end': doctor.availability['sunday']?.end,
              'available': doctor.availability['sunday']?.available ?? false,
            },
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Manage Availability'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
          ..._availability.entries.map((entry) {
            final day = entry.key;
            final schedule = entry.value;
            final isAvailable = schedule['available'] == true;
            final timeSlots = _getTimeSlots();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              day[0].toUpperCase() + day.substring(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _editingDay = _editingDay == day ? null : day;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isAvailable
                                        ? [
                                            AppTheme.primaryGreen,
                                            AppTheme.primaryGreenDark,
                                          ]
                                        : [
                                            AppTheme.darkGrey,
                                            AppTheme.darkGrey.withOpacity(0.8),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isAvailable
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryGreen.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: AppTheme.darkGrey.withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isAvailable
                                          ? '${schedule['start'] ?? '09:00'} - ${schedule['end'] ?? '17:00'}'
                                          : 'Not available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isAvailable
                                            ? AppTheme.white
                                            : AppTheme.white.withOpacity(0.7),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: isAvailable
                                          ? AppTheme.white.withOpacity(0.9)
                                          : AppTheme.white.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _availability[day] = {
                                'start': value ? (schedule['start'] ?? '09:00') : null,
                                'end': value ? (schedule['end'] ?? '17:00') : null,
                                'available': value,
                              };
                              // Clear editing state if disabling the day
                              if (!value && _editingDay == day) {
                                _editingDay = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (isAvailable) ...[
                      const SizedBox(height: 16),
                      if (_editingDay == day) ...[
                        // Show time dropdowns when editing
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'From',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: schedule['start'] ?? '09:00',
                                        isExpanded: true,
                                        items: timeSlots.map((String time) {
                                          return DropdownMenuItem<String>(
                                            value: time,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(time),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              final currentEnd = schedule['end'] ?? '17:00';
                                              // Ensure end time is after start time
                                              if (newValue.compareTo(currentEnd) >= 0) {
                                                // If start time is after or equal to end time, adjust end time
                                                final startIndex = timeSlots.indexOf(newValue);
                                                final endIndex = startIndex + 16; // 8 hours later (16 * 30 min)
                                                final adjustedEnd = endIndex < timeSlots.length
                                                    ? timeSlots[endIndex]
                                                    : '23:30';
                                                _availability[day] = {
                                                  'start': newValue,
                                                  'end': adjustedEnd,
                                                  'available': true,
                                                };
                                              } else {
                                                _availability[day] = {
                                                  'start': newValue,
                                                  'end': currentEnd,
                                                  'available': true,
                                                };
                                              }
                                            });
                                          }
                                        },
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'To',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: () {
                                          final currentStart = schedule['start'] ?? '09:00';
                                          final currentEnd = schedule['end'] ?? '17:00';
                                          // Ensure the selected end time is valid (after start time)
                                          if (currentEnd.compareTo(currentStart) > 0) {
                                            return currentEnd;
                                          }
                                          // If invalid, find the next valid time after start
                                          final startIndex = timeSlots.indexOf(currentStart);
                                          if (startIndex >= 0 && startIndex < timeSlots.length - 1) {
                                            return timeSlots[startIndex + 1];
                                          }
                                          return '17:00';
                                        }(),
                                        isExpanded: true,
                                        items: () {
                                          final currentStart = schedule['start'] ?? '09:00';
                                          return timeSlots
                                              .where((time) => time.compareTo(currentStart) > 0)
                                              .map((String time) {
                                            return DropdownMenuItem<String>(
                                              value: time,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(time),
                                              ),
                                            );
                                          }).toList();
                                        }(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _availability[day] = {
                                                'start': schedule['start'] ?? '09:00',
                                                'end': newValue,
                                                'available': true,
                                              };
                                            });
                                          }
                                        },
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _editingDay = null; // Cancel editing
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              // Get user ID - try from UserProvider first, then Firebase Auth
              String? userId;
              var currentUser = userProvider.currentUser;
              if (currentUser != null) {
                userId = currentUser.userId;
              } else {
                // If user data not loaded, try to get from Firebase Auth
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser != null) {
                  userId = firebaseUser.uid;
                  // Try to load user data
                  await userProvider.loadUserData(userId);
                }
              }
              
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User data not loaded. Please try again.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              
              final success = await doctorProvider.updateAvailability(
                doctorId: userId,
                availability: _availability,
              );
              if (success && mounted) {
                setState(() {
                  _editingDay = null; // Clear editing state after saving
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Availability updated successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Save Availability'),
            ),
          ),
        ],
      ),
    );
  }
}

