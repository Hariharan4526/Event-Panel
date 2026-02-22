import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/registration_service.dart';
import '../../../services/attendance_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/date_formatter.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final RegistrationService _registrationService = RegistrationService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isProcessing = false;
  bool _flashOn = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
        _isCheckingPermission = false;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrToken) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Debug: Print scanned token
      print('DEBUG: Scanned QR Token: $qrToken');
      print('DEBUG: Token length: ${qrToken.length}');
      print('DEBUG: Token type: ${qrToken.runtimeType}');

      // Get registration by QR token
      final registration = await _registrationService.getRegistrationByQRToken(qrToken);

      print('DEBUG: Registration found: ${registration != null}');
      if (registration != null) {
        print('DEBUG: Registration ID: ${registration.id}');
        print('DEBUG: User ID: ${registration.userId}');
        print('DEBUG: Event ID: ${registration.eventId}');
        print('DEBUG: Payment Status: ${registration.paymentStatus}');
      }

      if (registration == null) {
        _showResultDialog(
          success: false,
          title: 'Invalid QR Code',
          message: 'This QR code is not recognized in the system. Please ensure the user has registered and completed payment.',
        );
        return;
      }

      // Check if payment is completed
      if (!registration.isPaid) {
        _showResultDialog(
          success: false,
          title: 'Payment Pending',
          message: 'Payment has not been completed for this registration. Ask the participant to complete their payment.',
        );
        return;
      }

      // Check if already scanned
      final existingAttendance = await _attendanceService.checkAttendance(
        userId: registration.userId,
        eventId: registration.eventId,
      );

      if (existingAttendance != null) {
        _showDuplicateDialog(
          userName: registration.userName ?? 'Participant',
          eventTitle: registration.eventTitle ?? 'Event',
          firstScanTime: existingAttendance.scannedAt,
        );
        return;
      }

      // Mark attendance
      await _attendanceService.markAttendance(
        userId: registration.userId,
        eventId: registration.eventId,
        scannedBy: authProvider.currentUser!.id,
      );

      _showSuccessDialog(
        userName: registration.userName ?? 'Participant',
        eventTitle: registration.eventTitle ?? 'Event',
      );
    } catch (e) {
      print('DEBUG: QR Scan Error: $e');
      _showResultDialog(
        success: false,
        title: 'Error',
        message: 'Failed to process QR code: $e',
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog({
    required String userName,
    required String eventTitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacing3),
              Text(
                'Entry Confirmed',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.success,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing2),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatTime(DateTime.now()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Continue Scanning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDuplicateDialog({
    required String userName,
    required String eventTitle,
    required DateTime firstScanTime,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning,
                  size: 48,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: AppTheme.spacing3),
              Text(
                'Entry Already Granted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing1),
              Text(
                'Duplicate scan detected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing3),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventTitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing2),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing2),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'First Entry: ${DateFormatter.formatDateTime(firstScanTime)}',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Dismiss Warning'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? AppTheme.success : AppTheme.error,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance'),
        actions: _hasPermission ? [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _flashOn = !_flashOn;
              });
              _scannerController.toggleTorch();
            },
          ),
        ] : null,
      ),
      body: _isCheckingPermission
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !_hasPermission
              ? _buildPermissionDenied()
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _handleQRCode(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                          ),
                          // Scanning overlay
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.primaryBlue,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            ),
                            margin: const EdgeInsets.all(AppTheme.spacing4),
                          ),
                          // Corner decorations
                          Positioned(
                            top: AppTheme.spacing4,
                            left: AppTheme.spacing4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                  left: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: AppTheme.spacing4,
                            right: AppTheme.spacing4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                  right: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: AppTheme.spacing4,
                            left: AppTheme.spacing4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                  left: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: AppTheme.spacing4,
                            right: AppTheme.spacing4,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                  right: BorderSide(color: AppTheme.primaryBlue, width: 4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacing4),
                        decoration: const BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusXLarge),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, color: AppTheme.primaryBlue),
                                SizedBox(width: 12),
                                Text(
                                  'Ready to scan...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Flexible(
                              child: Text(
                                'Align the student\'s QR code within the frame to verify attendance.',
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
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

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppTheme.spacing3),
            Text(
              'Camera Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              'This app needs camera access to scan QR codes for attendance verification. Please grant camera permission in your device settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing4),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
            const SizedBox(height: AppTheme.spacing2),
            TextButton(
              onPressed: () {
                _checkCameraPermission();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

