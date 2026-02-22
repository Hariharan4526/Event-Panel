import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/event_provider.dart';
import '../../../services/event_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_buttons.dart';
import '../../../utils/validators.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();

  final EventService _eventService = EventService();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  String _category = 'academic';
  File? _bannerImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _createEvent(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final eventProvider = context.read<EventProvider>();

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      // Upload banner if selected
      String? bannerUrl;
      if (_bannerImage != null) {
        final eventId = const Uuid().v4();
        bannerUrl = await _eventService.uploadBanner(_bannerImage!, eventId);
      }

      // Create event data
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'banner_url': bannerUrl,
        'category': _category,
        'start_date': startDateTime.toIso8601String(),
        'venue': _venueController.text.trim(),
        'max_capacity': int.parse(_capacityController.text),
        'price': double.parse(_priceController.text),
        'created_by': authProvider.currentUser!.id,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      };

      final success = await eventProvider.createEvent(eventData);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'published'
                  ? 'Event published successfully!'
                  : 'Event saved as draft',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create event'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Upload
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                  ),
                  child: _bannerImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          child: Image.file(
                            _bannerImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload, size: 48, color: AppTheme.primaryBlue),
                            const SizedBox(height: AppTheme.spacing1),
                            Text(
                              'Upload Banner',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryBlue,
                                  ),
                            ),
                            Text(
                              'Recommended 1920x1080',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Event Title
              CustomTextField(
                controller: _titleController,
                label: 'Event Title',
                hint: 'e.g., Annual Tech Symposium',
                validator: (v) => Validators.validateRequired(v, 'Event title'),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Category
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing1),
              Wrap(
                spacing: AppTheme.spacing1,
                children: [
                  _CategoryChip(
                    label: 'Academic',
                    icon: '📚',
                    value: 'academic',
                    groupValue: _category,
                    onTap: () => setState(() => _category = 'academic'),
                  ),
                  _CategoryChip(
                    label: 'Social',
                    icon: '🎉',
                    value: 'social',
                    groupValue: _category,
                    onTap: () => setState(() => _category = 'social'),
                  ),
                  _CategoryChip(
                    label: 'Sport',
                    icon: '⚽',
                    value: 'sport',
                    groupValue: _category,
                    onTap: () => setState(() => _category = 'sport'),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing2),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Select date',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacing1),
                        GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing2),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _startTime != null
                                      ? _startTime!.format(context)
                                      : 'Select time',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Venue
              CustomTextField(
                controller: _venueController,
                label: 'Venue',
                hint: 'e.g., Main Auditorium, Building C',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => Validators.validateRequired(v, 'Venue'),
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Capacity & Price
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _capacityController,
                      label: 'Max Capacity',
                      hint: '0',
                      prefixIcon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, 'Capacity'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price (\$)',
                      hint: '0.00',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.validateNumber(v, 'Price'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing3),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What is this event about?',
                maxLines: 5,
                validator: (v) => Validators.validateRequired(v, 'Description'),
              ),

              const SizedBox(height: AppTheme.spacing4),

              // Action Buttons
              PrimaryButton(
                text: 'Publish Event',
                onPressed: () => _createEvent('published'),
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: AppTheme.spacing2),

              SecondaryButton(
                text: 'Save as Draft',
                onPressed: () => _createEvent('draft'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing2,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

