import 'package:autism_care_management_application/common/widgets/datetimepicker.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:autism_care_management_application/screen/parents/views/p_payment_webview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ParentsPayment extends StatefulWidget {
  const ParentsPayment({super.key});

  @override
  State<ParentsPayment> createState() => _ParentsPaymentState();
}

class _ParentsPaymentState extends State<ParentsPayment> {
  bool _isLoading = true;
  bool _paymentProcessing = false; // New flag to track payment processing
  double _deferredAmount = 0;
  List<Map<String, dynamic>> _paymentHistory = [];
  List<Map<String, dynamic>> _unpaidPayments = [];
  final _paymentService = FirestoreService();

  // User details for payment
  String _userEmail = '';
  String _userName = '';
  String _userPhone = '';
  Parent? _currentParent;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadPaymentData();
  }

  Future<void> _loadUserDetails() async {
    try {
      _currentParent = await _paymentService.getParent();
      if (_currentParent != null) {
        setState(() {
          _userEmail = _currentParent!.email;
          _userName = _currentParent!.name;
          _userPhone = _currentParent!.phone ?? '';
        });
      } else {
        _showSnackBar('Failed to load user details', Colors.red);
      }
    } catch (e) {
      print('Error loading user details: $e');
      _showSnackBar('Error loading user details: $e', Colors.red);
    }
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _paymentService.getTotalDeferredPayment(),
        _paymentService.getPaymentHistory(),
        _paymentService.getUnpaidPayments(),
      ]);

      setState(() {
        _deferredAmount = results[0] as double;
        _paymentHistory = results[1] as List<Map<String, dynamic>>;
        _unpaidPayments = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      _showSnackBar('Failed to load payments: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePaymentWithToyyibPay() async {
    if (_deferredAmount <= 0) {
      _showSnackBar('No pending payments to process', Colors.orange);
      return;
    }

    if (_paymentProcessing) {
      _showSnackBar('Payment already in progress', Colors.orange);
      return;
    }

    // Check if user details are loaded
    if (_userEmail.isEmpty || _userName.isEmpty) {
      _showSnackBar('User details not loaded. Please try again.', Colors.red);
      await _loadUserDetails();
      return;
    }

    setState(() => _paymentProcessing = true);

    try {
      // Navigate to payment screen and wait for result
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            amount: _deferredAmount,
            userEmail: _userEmail,
            userName: _userName,
            userPhone: _userPhone,
            onPaymentSuccess: _onPaymentSuccess,
            onPaymentFailed: _onPaymentFailed,
            onPaymentCancelled: _onPaymentCancelled,
          ),
        ),
      );

      // Handle the result when user returns from payment screen
      if (result == true) {
        print('Payment completed successfully');
        await _loadPaymentData(); // Refresh payment data
      }
    } catch (e) {
      print('Error navigating to payment: $e');
      _showSnackBar('Error starting payment: $e', Colors.red);
    } finally {
      setState(() => _paymentProcessing = false);
    }
  }

  void _onPaymentSuccess() {
    print('Payment success callback triggered');

    // Show success message
    _showSnackBar('Payment completed successfully!', Colors.green);

    // Update payment status in Firebase
    _updatePaymentStatusAfterSuccess();

    // Refresh payment data
    _loadPaymentData();

    // Reset processing flag
    setState(() => _paymentProcessing = false);
  }

  void _onPaymentFailed() {
    print('Payment failed callback triggered');
    _showSnackBar('Payment failed. Please try again.', Colors.red);
    setState(() => _paymentProcessing = false);
  }

  void _onPaymentCancelled() {
    print('Payment cancelled callback triggered');
    _showSnackBar('Payment cancelled', Colors.orange);
    setState(() => _paymentProcessing = false);
  }

  Future<void> _updatePaymentStatusAfterSuccess() async {
    try {
      print('Updating payment status in Firebase...');
      final success = await _paymentService.doPayment();
      if (!success) {
        _showSnackBar(
          'Payment successful but failed to update records. Please contact support.',
          Colors.orange,
        );
      } else {
        print('Firebase payment status updated successfully');
      }
    } catch (e) {
      print('Error updating payment status: $e');
      _showSnackBar(
        'Payment successful but failed to update records. Please contact support.',
        Colors.orange,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    final statusMap = {
      'Paid': Colors.green,
      'Unpaid': Colors.orange,
      'Overdue': Colors.red,
    };

    return Chip(
      label: Text(status),
      backgroundColor: statusMap[status]?.withOpacity(0.2),
      labelStyle: TextStyle(
        color: statusMap[status] ?? Colors.black,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Payment')),
      body: RefreshIndicator(
        onRefresh: _loadPaymentData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Skeletonizer(
            enabled: _isLoading,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deferred Payment Section
                  const Text('Deferred Payment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${_isLoading ? '???.??' : _deferredAmount.toStringAsFixed(2)}',
                    style: textTheme.headlineLarge?.copyWith(
                      color: _deferredAmount > 0 ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment processing indicator
                  if (_paymentProcessing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Processing payment...'),
                        ],
                      ),
                    ),

                  // Payment buttons
                  Column(
                    children: [
                      // Primary payment button with ToyyibPay
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (_deferredAmount > 0 &&
                                  !_isLoading &&
                                  !_paymentProcessing)
                              ? _handlePaymentWithToyyibPay
                              : null,
                          icon: _paymentProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(_paymentProcessing
                              ? 'Processing...'
                              : 'Pay with Online Banking'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Payment Section
                  if (_unpaidPayments.isNotEmpty) ...[
                    const Text('Unpaid Payments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._unpaidPayments.map((payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LargeListTile(
                            leading: const Icon(Icons.payment, size: 28),
                            title: Text(
                              '${payment['id']} : RM${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: textTheme.bodyLarge,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${payment['caretakerName']}',
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  '${payment['childName']}',
                                  style: textTheme.bodyMedium,
                                ),
                                if (payment['dueDate'] != null)
                                  Text(
                                    'Due Date: ${dateFormat.format((payment['dueDate'] as Timestamp).toDate())}',
                                    style: textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                            trailing: _buildStatusChip(
                                payment['status'] == 'Pending'
                                    ? 'Unpaid'
                                    : 'Unpaid'),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Payment History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      DatePickerTextField(
                        onDateSelected: (date) {
                          _loadPaymentData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Payment History List
                  if (_paymentHistory.isEmpty && !_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child:
                          Center(child: Text('No payment history available')),
                    )
                  else
                    ..._paymentHistory.map((payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LargeListTile(
                            leading: const Icon(Icons.payment, size: 28),
                            title: Text(
                                '${payment['id']} : ${payment['caretakerName']}'),
                            subtitle: Text(
                              'RM${payment['amount']?.toStringAsFixed(2) ?? '0.00'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            bottom: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${payment['childName']}'),
                                Text(
                                  payment['updatedAt'] != null
                                      ? dateFormat.format(
                                          (payment['updatedAt'] as Timestamp)
                                              .toDate())
                                      : 'No date available',
                                ),
                              ],
                            ),
                            trailing:
                                _buildStatusChip(payment['status'] ?? 'Paid'),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
