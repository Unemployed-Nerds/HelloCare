import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
            context.pop();
          }
        },
        steps: [
          Step(
            title: const Text('Select Doctor'),
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
                            onChanged: (value) {
                              setState(() {
                                _selectedDoctorId = value;
                              });
                            },
                          );
                        },
                      ),
          ),
          Step(
            title: const Text('Select Date'),
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
            title: const Text('Select Time'),
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
                      return slots.isEmpty
                          ? const Text('No available slots')
                          : GridView.builder(
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2,
                              ),
                              itemCount: slots.length,
                              itemBuilder: (context, index) {
                                final slot = slots[index];
                                final isAvailable = slot['available'] == true;
                                final time = slot['time'];
                                return ElevatedButton(
                                  onPressed: isAvailable
                                      ? () {
                                          setState(() {
                                            _selectedTime = time;
                                          });
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedTime == time
                                        ? AppTheme.primaryGreen
                                        : isAvailable
                                            ? AppTheme.lightGreen
                                            : AppTheme.lightGrey,
                                  ),
                                  child: Text(time),
                                );
                              },
                            );
                    },
                  ),
          ),
          Step(
            title: const Text('Confirm'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor: ${doctorProvider.doctors.firstWhere((d) => d.doctorId == _selectedDoctorId).name}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}'),
                Text('Time: $_selectedTime'),
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

