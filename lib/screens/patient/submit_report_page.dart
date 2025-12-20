import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key});

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _reportDateController = TextEditingController();
  
  File? _selectedFile;
  DateTime? _reportDate;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _reportDateController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectReportDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _reportDate = picked;
        _reportDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    if (_reportDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select report date'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    final success = await reportProvider.submitReport(
      userId: userProvider.currentUser!.userId,
      file: _selectedFile!,
      title: _titleController.text.trim(),
      reportDate: _reportDate!,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      doctorName: _doctorNameController.text.trim().isEmpty
          ? null
          : _doctorNameController.text.trim(),
      clinicName: _clinicNameController.text.trim().isEmpty
          ? null
          : _clinicNameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.error ?? 'Failed to submit report'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Submit Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Select File (PDF or Image)'),
                ),
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(_selectedFile!.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Report Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter report title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reportDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Report Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _selectReportDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select report date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  prefixIcon: Icon(Icons.category),
                  hintText: 'e.g., Lab Test, X-Ray, Prescription',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name (Optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clinicNameController,
                decoration: const InputDecoration(
                  labelText: 'Clinic Name (Optional)',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 32),
              if (reportProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitReport,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Submit Report', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


