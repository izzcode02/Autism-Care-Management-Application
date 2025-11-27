import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Approval.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:flutter/material.dart';

class CaretakerApproval extends StatefulWidget {
  const CaretakerApproval({super.key});

  @override
  State<CaretakerApproval> createState() => _CaretakerApprovalState();
}

class _CaretakerApprovalState extends State<CaretakerApproval>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CaretakerController _controller = CaretakerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerLayout(
      title: 'Approvement Management',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Approval Pending'),
          Tab(text: 'Approval History'),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          PendingApprovalsTab(controller: _controller),
          ApprovalHistoryTab(controller: _controller),
        ],
      ),
    );
  }
}

class PendingApprovalsTab extends StatefulWidget {
  final CaretakerController controller;

  const PendingApprovalsTab({super.key, required this.controller});

  @override
  State<PendingApprovalsTab> createState() => _PendingApprovalsTabState();
}

class _PendingApprovalsTabState extends State<PendingApprovalsTab> {
  late Future<List<Approval>> _pendingApprovalsFuture;
  final parentController = FirestoreService();

  @override
  void initState() {
    super.initState();
    _refreshPendingApprovals();
  }

  Future<void> _approveRequest(String applyId) async {
    try {
      await widget.controller.approveRequest(applyId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved successfully')),
      );
      _refreshPendingApprovals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request: ${e.toString()}')),
      );
    }
  }

  Future<void> _declineRequest(String applyId) async {
    try {
      await widget.controller.declineRequest(applyId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined successfully')),
      );
      _refreshPendingApprovals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline request: ${e.toString()}')),
      );
    }
  }

  void _refreshPendingApprovals() {
    setState(() {
      _pendingApprovalsFuture = widget.controller.getPendingApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Approval>>(
      future: _pendingApprovalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoader());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load pending approvals: ${snapshot.error}'),
          );
        }

        final pendingApprovals = snapshot.data ?? [];

        if (pendingApprovals.isEmpty) {
          return const Center(child: Text('No pending approvals'));
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: SingleChildScrollView(
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
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: const [
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Apply Id ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Parent Id ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Parent Name ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Child Id',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Child Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Request Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...pendingApprovals.map((approval) {
                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.applyId ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.parentInfo?.id ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.parentInfo?.name ?? 'No Name',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.childInfo?.id ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.childInfo?.name ?? 'No Name',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.requestDate != null
                                      ? approval.requestDate!
                                          .toDate()
                                          .toString()
                                          .split(' ')[0]
                                      : 'No Date',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _approveRequest(
                                            approval.applyId ?? '',
                                          );

                                          await parentController.insertMessageP(
                                              'Child Approved',
                                              'Your child application for ${approval.childInfo?.id} has been approved to ${approval.childInfo?.name}.',
                                              approval.parentInfo!.id);
                                        },
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _declineRequest(
                                            approval.applyId ?? '',
                                          );

                                          await parentController.insertMessageP(
                                              'Child Decline',
                                              'Your child application for ${approval.childInfo?.id} has been decline to ${approval.childInfo?.name} due not fulfill our criteria or bad information given, please contact us for more info.',
                                              approval.parentInfo!.id);
                                        },
                                        child: const Text('Decline'),
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
        );
      },
    );
  }
}

class ApprovalHistoryTab extends StatefulWidget {
  final CaretakerController controller;

  const ApprovalHistoryTab({super.key, required this.controller});

  @override
  State<ApprovalHistoryTab> createState() => _ApprovalHistoryTabState();
}

class _ApprovalHistoryTabState extends State<ApprovalHistoryTab> {
  late Future<List<Approval>> _approvalHistoryFuture;

  @override
  void initState() {
    super.initState();
    _approvalHistoryFuture = widget.controller.getApprovalHistory();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.yellow;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Approval>>(
      future: _approvalHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoader());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load approval history: ${snapshot.error}'),
          );
        }

        final approvalHistory = snapshot.data ?? [];

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: SingleChildScrollView(
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
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: const [
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Apply Id',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Parent Id',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Parent Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Child Id',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Child Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Request Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...approvalHistory.map((approval) {
                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.applyId ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.parentInfo?.id ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.parentInfo?.name ?? 'No Name',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(approval.childInfo?.id ?? 'No ID'),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.childInfo?.name ?? 'No Name',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  approval.requestDate != null
                                      ? approval.requestDate!
                                          .toDate()
                                          .toString()
                                          .split(' ')[0]
                                      : 'No Date',
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Chip(
                                  label: Text(
                                    (approval.applyStatus ?? 'unknown')
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    approval.applyStatus ?? 'unknown',
                                  ),
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
        );
      },
    );
  }
}
