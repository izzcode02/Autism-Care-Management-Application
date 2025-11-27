import 'package:autism_care_management_application/screen/authentication/model/caretaker_model.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Payment.dart';
import 'package:autism_care_management_application/screen/caretaker/model/children_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CaretakerPayment extends StatefulWidget {
  const CaretakerPayment({super.key});

  @override
  State<CaretakerPayment> createState() => _CaretakerPaymentState();
}

class _CaretakerPaymentState extends State<CaretakerPayment> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Payment> _paymentList = [];
  List<Payment> _filteredPayments = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';
  Map<String, dynamic> _paymentStats = {};
  final caretakercontroller = CaretakerController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterPayments();
      });
    });
    _loadPayments();
    _loadPaymentStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);

      List<Payment> payments;
      if (_selectedStatusFilter == 'All') {
        payments = await caretakercontroller.getAllPayments();
      } else {
        payments = await caretakercontroller.getPaymentsByStatus(
          _selectedStatusFilter,
        );
      }

      setState(() {
        _paymentList = payments;
        _filterPayments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading payments: $e');
    }
  }

  Future<void> _loadPaymentStatistics() async {
    try {
      final stats = await caretakercontroller.getPaymentStatistics();
      setState(() {
        _paymentStats = stats;
      });
    } catch (e) {
      print('Error loading payment statistics: $e');
    }
  }

  void _filterPayments() {
    if (_searchQuery.isEmpty) {
      _filteredPayments = List.from(_paymentList);
    } else {
      _filteredPayments = _paymentList.where((payment) {
        final query = _searchQuery.toLowerCase();
        return payment.id.toLowerCase().contains(query) ||
            payment.parentName.toLowerCase().contains(query) ||
            payment.childName.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _updatePayment(Payment updatedPayment) async {
    try {
      await caretakercontroller.updatePayment(
        updatedPayment.id,
        updatedPayment.parentId,
        updatedPayment.parentName,
        updatedPayment.childId,
        updatedPayment.childName,
        updatedPayment.amount,
        updatedPayment.status,
        updatedPayment.dueDate,
      );

      _showSuccessSnackBar('Payment updated successfully');
      await _loadPayments();
      await _loadPaymentStatistics();
    } catch (e) {
      _showErrorSnackBar('Error updating payment: $e');
    }
  }

  Future<void> _updatePaymentStatus(String id, String newStatus) async {
    try {
      await caretakercontroller.updatePaymentStatus(id, newStatus);
      _showSuccessSnackBar('Payment status updated successfully');
      await _loadPayments();
      await _loadPaymentStatistics();
    } catch (e) {
      _showErrorSnackBar('Error updating payment status: $e');
    }
  }

  Future<void> _deletePayment(String id) async {
    try {
      await caretakercontroller.deletePayment(id);
      _showSuccessSnackBar('Payment deleted successfully');
      await _loadPayments();
      await _loadPaymentStatistics();
    } catch (e) {
      _showErrorSnackBar('Error deleting payment: $e');
    }
  }

  Future<void> _assignPaymentToAllParents(
    double amount,
    DateTime dueDate,
  ) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final childrenWithParents =
          await caretakercontroller.getChildrenWithParents();

      if (!mounted) return;
      if (childrenWithParents.isEmpty) {
        _showErrorSnackBar('No children and parents found');
        setState(() => _isLoading = false);
        return;
      }

      List<Map<String, dynamic>> paymentsData = [];

      for (var item in childrenWithParents) {
        final child = item['child'] as Child?;
        final parent = item['parent'] as Parent?;

        if (child != null && parent != null) {
          paymentsData.add({
            'caretakerId': child.caretakerId,
            'caretakerName': child.autismCentreName,
            'parentId': parent.id,
            'parentName': parent.name,
            'childId': child.id,
            'childName': child.name,
            'amount': amount,
            'status': 'Pending',
            'dueDate': dueDate,
          });
        }
      }

      if (paymentsData.isNotEmpty) {
        await caretakercontroller.addMultiplePayments(paymentsData);

        if (!mounted) return;
        _showSuccessSnackBar(
          'Successfully assigned RM${amount.toStringAsFixed(2)} payment to ${paymentsData.length} parent(s)',
        );

        await _loadPayments();
        if (!mounted) return;
        await _loadPaymentStatistics();
      } else {
        if (!mounted) return;
        _showErrorSnackBar('No valid parent-child pairs found');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error assigning payments: $e');
    }
  }

  void _showBulkPaymentDialog() {
    final amountController = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));
    final textTheme = TextTheme.of(context);

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Assign Payment to All Parents',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'How much should parents pay for this month?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: '50.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Due Date: ${DateFormat('MMM dd, yyyy').format(selectedDueDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      btnCancelText: 'Cancel',
      btnOkText: 'Assign to All',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (amountController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter payment amount'),
            ),
          );
          return;
        }

        final double amount = double.tryParse(amountController.text) ?? 0.0;
        if (amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment amount must be greater than zero'),
            ),
          );
          return;
        }

        if (mounted) {
          await _assignPaymentToAllParents(amount, selectedDueDate);
        }
      },
      buttonsBorderRadius: BorderRadius.circular(8),
      buttonsTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      dialogBackgroundColor: Colors.white,
      dismissOnTouchOutside:
          false, // Prevent accidental dismissal during form filling
      width: 400, // Set a reasonable width for the dialog
    ).show();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPaymentDialog({Payment? payment}) {
    final textTheme = TextTheme.of(context);
    final bool isEditing = payment != null;
    final parentNameController = TextEditingController(
      text: isEditing ? payment.parentName : '',
    );
    final childNameController = TextEditingController(
      text: isEditing ? payment.childName : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? payment.amount.toStringAsFixed(2) : '',
    );

    String selectedStatus = isEditing ? payment.status : 'Pending';
    DateTime selectedDueDate = isEditing
        ? payment.dueDate
        : DateTime.now().add(const Duration(days: 7));

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isEditing ? 'Edit Payment' : 'Add Payment',
                      style: textTheme.headlineMedium),
                  TextField(
                    controller: parentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Parent Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    readOnly: isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: childNameController,
                    decoration: const InputDecoration(
                      labelText: 'Child Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.child_care),
                    ),
                    readOnly: isEditing,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'Overdue',
                        child: Text('Overdue'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Due Date: ${DateFormat('MMM dd, yyyy').format(selectedDueDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDueDate = picked;
                              });
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      btnCancelText: 'Cancel',
      btnOkText: isEditing ? 'Update' : 'Add',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (parentNameController.text.isEmpty ||
            childNameController.text.isEmpty ||
            amountController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All fields are required'),
            ),
          );
          return;
        }

        final double amount = double.tryParse(amountController.text) ?? 0.0;
        if (amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment amount must be greater than zero'),
            ),
          );
          return;
        }

        if (isEditing) {
          final updatedPayment = payment.copyWith(
            parentName: parentNameController.text,
            childName: childNameController.text,
            amount: amount,
            status: selectedStatus,
            dueDate: selectedDueDate,
          );
          await _updatePayment(updatedPayment);
        } else {
          // Add logic for creating new payment if needed
          // await _createPayment(...);
        }
      },
      buttonsBorderRadius: BorderRadius.circular(8),
      buttonsTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      dialogBackgroundColor: Colors.white,
      dismissOnTouchOutside:
          false, // Prevent accidental dismissal during form filling
      width: 450, // Wider dialog to accommodate form fields
    ).show();
  }

  Widget _buildPaymentStatsCard() {
    if (_paymentStats.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    'RM${(_paymentStats['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
                    '${_paymentStats['totalCount'] ?? 0} payments',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Paid',
                    'RM${(_paymentStats['paidAmount'] ?? 0.0).toStringAsFixed(2)}',
                    '${_paymentStats['paidCount'] ?? 0} payments',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    'RM${(_paymentStats['pendingAmount'] ?? 0.0).toStringAsFixed(2)}',
                    '${_paymentStats['pendingCount'] ?? 0} payments',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Overdue',
                    'RM${(_paymentStats['overdueAmount'] ?? 0.0).toStringAsFixed(2)}',
                    '${_paymentStats['overdueCount'] ?? 0} payments',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String amount,
    String count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            count,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrawerLayout(
      title: 'Payment Management',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: const Text(
                'Payment Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Statistics Card
            _buildPaymentStatsCard(),

            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Payment',
                      hintText: 'Search by ID, parent or child name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatusFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'Overdue',
                        child: Text('Overdue'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatusFilter = value!;
                      });
                      _loadPayments();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () => _showBulkPaymentDialog(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.green,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_add, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Assign to All',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadPayments,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPayments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No payments found for "$_searchQuery"'
                                    : 'No payments found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Table(
                                columnWidths: const {
                                  0: IntrinsicColumnWidth(),
                                  1: IntrinsicColumnWidth(),
                                  2: IntrinsicColumnWidth(),
                                  3: IntrinsicColumnWidth(),
                                  4: IntrinsicColumnWidth(),
                                  5: IntrinsicColumnWidth(),
                                  6: IntrinsicColumnWidth(),
                                },
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                children: [
                                  // Header row
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                    ),
                                    children: [
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Payment ID',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Parent Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Child Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Amount',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Due Date',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            'Actions',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Data rows
                                  ..._filteredPayments.map((payment) {
                                    return TableRow(
                                      children: [
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SelectableText(payment.id),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(payment.parentName),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(payment.childName),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              'RM${payment.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Chip(
                                              label: Text(
                                                payment.status.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor: _getStatusColor(
                                                payment.status,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(payment.dueDate),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Update Status button
                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                    Icons.update,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Update Status',
                                                  onSelected: (String status) {
                                                    _updatePaymentStatus(
                                                      payment.id,
                                                      status,
                                                    );
                                                  },
                                                  itemBuilder: (BuildContext
                                                          context) =>
                                                      <PopupMenuEntry<String>>[
                                                    const PopupMenuItem<String>(
                                                      value: 'Pending',
                                                      child: Text(
                                                        'Mark as Pending',
                                                      ),
                                                    ),
                                                    const PopupMenuItem<String>(
                                                      value: 'Paid',
                                                      child: Text(
                                                        'Mark as Paid',
                                                      ),
                                                    ),
                                                    const PopupMenuItem<String>(
                                                      value: 'Overdue',
                                                      child: Text(
                                                        'Mark as Overdue',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _showPaymentDialog(
                                                    payment: payment,
                                                  ),
                                                  tooltip: 'Edit',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    AwesomeDialog(
                                                      context: context,
                                                      dialogType:
                                                          DialogType.warning,
                                                      animType: AnimType.scale,
                                                      title: 'Confirm Deletion',
                                                      titleTextStyle:
                                                          const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                      desc:
                                                          'Are you sure you want to delete payment ${payment.id}?\n\nParent: ${payment.parentName}\nChild: ${payment.childName}\nAmount: \$${payment.amount.toStringAsFixed(2)}',
                                                      descTextStyle:
                                                          const TextStyle(
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                      btnCancelText: 'Cancel',
                                                      btnOkText: 'Delete',
                                                      btnCancelOnPress: () {},
                                                      btnOkOnPress: () {
                                                        _deletePayment(
                                                            payment.id);
                                                      },
                                                      btnOkColor: Colors.red,
                                                      btnCancelColor:
                                                          Colors.grey,
                                                      buttonsBorderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      buttonsTextStyle:
                                                          const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      dialogBackgroundColor:
                                                          Colors.white,
                                                      dismissOnTouchOutside:
                                                          false, // Prevent accidental dismissal for destructive action
                                                      headerAnimationLoop:
                                                          false,
                                                      showCloseIcon: false,
                                                    ).show();
                                                  },
                                                  tooltip: 'Delete',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
