import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../providers/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyContactPhoneController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _medicalHistoryController = TextEditingController(text: user?.medicalHistory ?? '');
    _allergiesController = TextEditingController(
      text: user?.allergies?.join(', ') ?? '',
    );
    _emergencyContactController = TextEditingController(
      text: user?.emergencyContact ?? '',
    );
    _emergencyContactPhoneController = TextEditingController(
      text: user?.emergencyContactPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) return;

    final allergies = _allergiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updatedUser = currentUser.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim().isEmpty
          ? null
          : _medicalHistoryController.text.trim(),
      allergies: allergies.isEmpty ? null : allergies,
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim().isEmpty
          ? null
          : _emergencyContactPhoneController.text.trim(),
    );

    await userProvider.updateUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 40, color: AppTheme.white),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: TextEditingController(text: user?.email ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              if (user?.dateOfBirth != null)
                TextFormField(
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd').format(user!.dateOfBirth!),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  enabled: false,
                ),
              const SizedBox(height: 24),
              const Text(
                'Medical Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicalHistoryController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  prefixIcon: Icon(Icons.medical_information),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies (comma separated)',
                  prefixIcon: Icon(Icons.warning),
                  hintText: 'e.g., Peanuts, Penicillin',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.contact_emergency),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 32),
              if (userProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Save Profile', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

