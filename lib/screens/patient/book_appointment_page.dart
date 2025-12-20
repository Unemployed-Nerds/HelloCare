import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/doctor.dart';
import '../../widgets/payment_mock_dialog.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int _currentStep = 0;
  String? _selectedDoctorId;
  DateTime? _selectedDate;
  String? _selectedTime;
  final _notesController = TextEditingController();
  Doctor? _selectedDoctorData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
      doctorProvider.loadDoctors();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isDateAvailable(DateTime date) {
    if (_selectedDoctorData == null || _selectedDoctorData!.availability.isEmpty) {
      return false;
    }

    // Get day of week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayName = dayNames[dayOfWeek == 7 ? 6 : dayOfWeek - 1];

    final dayAvailability = _selectedDoctorData!.availability[dayName];
    
    // Date is available if the day has availability enabled and start/end times are set
    return dayAvailability != null &&
           dayAvailability.available == true &&
           dayAvailability.start != null &&
           dayAvailability.end != null &&
           dayAvailability.start!.isNotEmpty &&
           dayAvailability.end!.isNotEmpty;
  }

  DateTime? _findFirstAvailableDate(DateTime startDate, DateTime endDate) {
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (_isDateAvailable(current)) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return null;
  }

  Future<void> _selectDate() async {
    if (_selectedDoctorData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor first'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 90));
    
    // Find the first available date to use as initial date
    DateTime? initialDate = _selectedDate;
    if (initialDate == null || !_isDateAvailable(initialDate)) {
      initialDate = _findFirstAvailableDate(firstDate, lastDate);
    }
    
    // If no available dates found, show error
    if (initialDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available dates found for this doctor'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime date) {
        // Only allow dates where the doctor has availability
        return _isDateAvailable(date);
      },
      helpText: 'Select a date when the doctor is available',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null || _selectedDate == null || _selectedTime == null) {
      return;
    }

    // Show mock payment dialog
    final paymentSuccess = await showDialog<bool>(
      context: context,
      builder: (context) => const PaymentMockDialog(),
    );

    if (paymentSuccess != true) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

    final success = await appointmentProvider.bookAppointment(
      doctorId: _selectedDoctorId!,
      patientId: userProvider.currentUser!.userId,
      patientName: userProvider.currentUser!.name,
      date: _selectedDate!,
      time: _selectedTime!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.go('/patient/appointments');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appointmentProvider.error ?? 'Failed to book appointment'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedDoctorId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a doctor')),
            );
            return;
          }
          if (_currentStep == 1 && _selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a date')),
            );
            return;
          }
          if (_currentStep == 2 && _selectedTime == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a time slot')),
            );
            return;
          }
          if (_currentStep < 3) {
            setState(() {
              _currentStep++;
            });
          } else {
            _bookAppointment();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          } else {
            // Check if we can pop, otherwise navigate to a safe route
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient/main');
            }
          }
        },
        steps: [
          Step(
            title: Row(
              children: [
                const Text('Select Doctor'),
                if (_selectedDoctorId != null) ...[
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final doctor = doctorProvider.doctors
                          .where((d) => d.doctorId == _selectedDoctorId)
                          .firstOrNull;
                      if (doctor == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen,
                              AppTheme.primaryGreenDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                doctor.name,
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            content: doctorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : doctorProvider.doctors.isEmpty
                    ? const Center(child: Text('No doctors available'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: doctorProvider.doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctorProvider.doctors[index];
                          return RadioListTile<String>(
                            title: Text(doctor.name),
                            subtitle: Text(doctor.specialization),
                            value: doctor.doctorId,
                            groupValue: _selectedDoctorId,
                            onChanged: (value) async {
                              setState(() {
                                _selectedDoctorId = value;
                                _selectedDate = null; // Reset date when doctor changes
                                _selectedTime = null;
                              });
                              
                              // Load the selected doctor's full data including availability
                              if (value != null) {
                                final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
                                await doctorProvider.loadDoctor(value);
                                setState(() {
                                  _selectedDoctorData = doctorProvider.selectedDoctor;
                                });
                              }
                            },
                          );
                        },
                      ),
          ),
          Step(
            title: Row(
              children: [
                const Text('Select Date'),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreenDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate!),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            content: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: Row(
              children: [
                const Text('Select Time'),
                if (_selectedTime != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreenDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedTime!,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            content: _selectedDate == null
                ? const Text('Please select a date first')
                : FutureBuilder(
                    future: doctorProvider.getAvailableSlots(
                      doctorId: _selectedDoctorId!,
                      date: _selectedDate!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final slots = snapshot.data?['slots'] as List? ?? [];
                      if (slots.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No available slots'),
                          ),
                        );
                      }
                      
                      // Separate available and unavailable slots
                      final availableSlots = <Map<String, dynamic>>[];
                      final unavailableSlots = <Map<String, dynamic>>[];
                      
                      for (var slot in slots) {
                        if (slot['available'] == true) {
                          availableSlots.add(slot);
                        } else {
                          unavailableSlots.add(slot);
                        }
                      }
                      
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (availableSlots.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Text(
                                  'Available Times',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: availableSlots.map((slot) {
                                  final time = slot['time'];
                                  final isSelected = _selectedTime == time;
                                  return FilterChip(
                                    label: Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedTime = selected ? time : null;
                                      });
                                    },
                                    selectedColor: AppTheme.primaryGreenDark,
                                    backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                                    checkmarkColor: AppTheme.white,
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : AppTheme.border.withOpacity(0.3),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (unavailableSlots.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Text(
                                  'Unavailable Times',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: unavailableSlots.map((slot) {
                                  final time = slot['time'];
                                  return FilterChip(
                                    label: Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textDisabled,
                                      ),
                                    ),
                                    selected: false,
                                    onSelected: null,
                                    backgroundColor: AppTheme.lightGrey.withOpacity(0.3),
                                    side: BorderSide(
                                      color: AppTheme.border.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Step(
            title: const Text('Confirm'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final doctor = doctorProvider.doctors
                        .where((d) => d.doctorId == _selectedDoctorId)
                        .firstOrNull;
                    return Text('Doctor: ${doctor?.name ?? 'Unknown'}');
                  },
                ),
                Builder(
                  builder: (context) {
                    final selectedDate = _selectedDate;
                    final dateText = selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(selectedDate)
                        : 'Not selected';
                    return Text('Date: $dateText');
                  },
                ),
                Text('Time: ${_selectedTime ?? 'Not selected'}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (appointmentProvider.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

