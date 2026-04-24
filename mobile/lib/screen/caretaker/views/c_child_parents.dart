import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/children_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CaretakerChildParents extends StatefulWidget {
  const CaretakerChildParents({super.key});

  @override
  State<CaretakerChildParents> createState() => _CaretakerChildParentsState();
}

class _CaretakerChildParentsState extends State<CaretakerChildParents> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _childrenWithParents = [];
  final caretakerController = CaretakerController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await caretakerController.getChildrenWithParents();
      setState(() {
        _childrenWithParents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar('Failed to load data: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteChild(String childId, String parentId) async {
    try {
      await caretakerController.deleteChild(childId, parentId);
      _showSuccessSnackbar('Child deleted successfully');
      await _loadData(); // Refresh the list
    } catch (e) {
      _showErrorSnackbar('Failed to delete child: $e');
    }
  }

  void _showChildDetails(Map<String, dynamic> data) {
    final child = data['child'] as Child;
    final parent = data['parent'] as Parent?;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.9,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              child.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('MyKid', child.myKid),
                  const SizedBox(height: 8),
                  _buildInfoRow('Age', child.age.toString()),
                  const SizedBox(height: 8),
                  _buildInfoRow('Address', child.address),
                  const SizedBox(height: 8),
                  _buildInfoRow('Autism Type', child.autismType),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parent Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (parent != null) ...[
                    _buildInfoRow('Name', parent.name),
                    const SizedBox(height: 8),
                    _buildInfoRow('Email', parent.email),
                    if (parent.phone != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Phone', parent.phone!),
                    ],
                  ] else ...[
                    Text(
                      'Parent information not available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmDelete(child.id, child.parentId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).show();
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String childId, String parentId) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Confirm Delete',
      desc: 'Are you sure you want to delete this child record?',
      btnCancelOnPress: () {
        // Dialog automatically closes
      },
      btnOkOnPress: () {
        _deleteChild(childId, parentId);
      },
      btnCancelText: 'Cancel',
      btnOkText: 'Delete',
      btnOkColor: Colors.red,
      btnCancelColor: Colors.grey,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DrawerLayout(
      title: 'Child And Parents Information',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Children and Parent Information',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Skeletonizer(
                  enabled: _isLoading,
                  child: _isLoading
                      ? _buildLoadingList()
                      : _childrenWithParents.isEmpty
                          ? Center(
                              child: Text(
                                'No children found',
                                style: textTheme.bodyLarge,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _childrenWithParents.length,
                              itemBuilder: (context, index) {
                                final data = _childrenWithParents[index];
                                final child = data['child'] as Child;
                                final parent = data['parent'] as Parent?;
                                final iteration = (index + 1).toString();

                                return LargeListTile(
                                  leading: Text(iteration),
                                  title: Text(
                                    'Child Name: ${child.name}',
                                    style: textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    'Parent Name: ${parent?.name ?? 'Unknown'}',
                                    style: textTheme.bodyMedium,
                                  ),
                                  onTap: () => _showChildDetails(data),
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) => LargeListTile(
        leading: Icon(Icons.child_care),
        title: Text('Loading...'),
        subtitle: Text('Loading...'),
        onTap: null,
      ),
    );
  }
}
