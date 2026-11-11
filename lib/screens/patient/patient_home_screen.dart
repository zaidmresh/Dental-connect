/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/patient_portal_provider.dart';
import '../../services/patient_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openAppointmentSheet() async {
    final doctors = context.read<AuthProvider>().dentists;

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No doctors are available yet'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppointmentSheet(doctors: doctors),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment request created'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openFeedbackSheet() async {
    final doctors = context.read<AuthProvider>().dentists;

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No doctors are available yet'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSheet(doctors: doctors),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final portal = context.watch<PatientPortalProvider>();
    final appointments = portal.appointmentsForPatient(user.id);
    final feedback = portal.feedbackForPatient(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Portal'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PatientHeader(name: user.fullName),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _PortalAction(
                        icon: Icons.calendar_month_outlined,
                        title: 'Book Appointment',
                        subtitle: 'Choose doctor and time',
                        onTap: _openAppointmentSheet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PortalAction(
                        icon: Icons.rate_review_outlined,
                        title: 'Doctor Feedback',
                        subtitle: 'Named or anonymous',
                        onTap: _openFeedbackSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(
              title: 'My Appointments',
              subtitle: '${appointments.length} upcoming request(s)',
            ),
            if (appointments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.event_available_outlined,
                  message: 'No appointments yet.\nBook your first visit.',
                ),
              )
            else
              ...appointments.map(
                  (appointment) => _AppointmentCard(appointment: appointment)),
            SectionHeader(
              title: 'My Feedback',
              subtitle: '${feedback.length} submitted review(s)',
            ),
            if (feedback.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: 'No feedback submitted yet.',
                ),
              )
            else
              ...feedback.map((item) => _FeedbackCard(feedback: item)),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAppointmentSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  final String name;

  const _PatientHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage visits and share your experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PortalAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 28),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.doctorName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('MMM dd, yyyy').format(appointment.date)} at ${appointment.timeSlot}',
              style: const TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              appointment.reason,
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final DoctorFeedbackModel feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feedback.doctorName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${feedback.rating}/5',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'By ${feedback.displayName}',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.feedback,
              style: const TextStyle(color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentSheet extends StatefulWidget {
  final List<UserModel> doctors;

  const _AppointmentSheet({required this.doctors});

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  UserModel? _doctor;
  String _timeSlot = '09:00 AM';

  static const _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctors.first;
    _timeSlot = _timeSlotsForDoctor().first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );

    if (date != null) setState(() => _selectedDate = date);
  }

  List<String> _timeSlotsForDoctor() {
    if (_doctor != null) {
      if (_doctor!.availabilityTimes.isNotEmpty) {
        return _doctor!.availabilityTimes;
      }
    }
    return _timeSlots;
  }

  void _selectDoctor(String doctorId) {
    final selected =
        widget.doctors.firstWhere((doctor) => doctor.id == doctorId);
    final times = selected.availabilityTimes;
    setState(() {
      _doctor = selected;
      if (times.isNotEmpty) {
        _timeSlot = times.first;
      } else {
        _timeSlot = _timeSlots.first;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser!;
    final doctor = _doctor!;
    final reason = _reasonController.text.trim();

    context.read<PatientPortalProvider>().bookAppointment(
          patientId: user.id,
          patientName: user.fullName,
          doctorId: doctor.id,
          doctorEmail: doctor.email,
          doctorName: doctor.displayName,
          date: _selectedDate,
          timeSlot: _timeSlot,
          reason: reason,
        );
    context.read<PatientProvider>().addAppointmentPatient(
          dentistId: doctor.id,
          fullName: user.fullName,
          phone: _phoneController.text.trim(),
          reason: reason,
        );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final availableTimes = _timeSlotsForDoctor();

    return _SheetFrame(
      title: 'Book Appointment',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _doctor?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Doctor',
                prefixIcon:
                    Icon(Icons.medical_services, color: AppColors.primary),
              ),
              items: widget.doctors
                  .map((doctor) => DropdownMenuItem(
                        value: doctor.id,
                        child: Text('${doctor.displayName} (${doctor.email})'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _selectDoctor(value);
                }
              },
            ),
            const SizedBox(height: 8),
            if (_doctor != null && _doctor!.availabilityTimes.isNotEmpty)
              Text(
                'Doctor availability: ${_doctor!.availabilityTimes.join(', ')}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('MMM dd').format(_selectedDate),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _timeSlot,
                    decoration: const InputDecoration(labelText: 'Time'),
                    items: availableTimes
                        .map((slot) =>
                            DropdownMenuItem(value: slot, child: Text(slot)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _timeSlot = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone',
              hint: 'Your phone number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.call_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Phone number is required'
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Reason',
              hint: 'Checkup, pain, cleaning, consultation...',
              controller: _reasonController,
              maxLines: 3,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Reason is required'
                  : null,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final List<UserModel> doctors;

  const _FeedbackSheet({required this.doctors});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  UserModel? _doctor;
  int _rating = 5;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctors.first;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().currentUser!;
    final doctor = _doctor!;
    context.read<PatientPortalProvider>().addFeedback(
          patientId: user.id,
          patientName: user.fullName,
          doctorId: doctor.id,
          doctorEmail: doctor.email,
          doctorName: doctor.displayName,
          rating: _rating,
          feedback: _feedbackController.text.trim(),
          isAnonymous: _isAnonymous,
        );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Doctor Feedback',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _doctor?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Doctor',
                prefixIcon:
                    Icon(Icons.medical_services, color: AppColors.primary),
              ),
              items: widget.doctors
                  .map((doctor) => DropdownMenuItem(
                        value: doctor.id,
                        child: Text('${doctor.displayName} (${doctor.email})'),
                      ))
                  .toList(),
              onChanged: (value) => setState(
                () => _doctor =
                    widget.doctors.firstWhere((doctor) => doctor.id == value),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _rating,
              decoration: const InputDecoration(
                labelText: 'Rating',
                prefixIcon: Icon(Icons.star, color: AppColors.warning),
              ),
              items: [1, 2, 3, 4, 5]
                  .map((rating) => DropdownMenuItem(
                        value: rating,
                        child: Text('$rating / 5'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _rating = value ?? _rating),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Feedback',
              hint: 'Tell us about your experience with the doctor...',
              controller: _feedbackController,
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Feedback is required'
                  : null,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Submit feedback anonymously',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) => setState(() => _isAnonymous = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}*/
