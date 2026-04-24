// providers/child_provider.dart
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:flutter/material.dart';

class ChildProvider with ChangeNotifier {
  List<Child> _children = [];
  Child? _selectedChild;

  List<Child> get children => _children;
  Child? get selectedChild => _selectedChild;

  final FirestoreService _childService;

  ChildProvider(this._childService);

  Future<void> loadChildren() async {
    _children = await _childService.getChildrenByParent();
    notifyListeners();
  }

  void selectChild(Child child) {
    _selectedChild = child;
    notifyListeners();  
  } 

  void clearSelection() {
    _selectedChild = null;
    notifyListeners();
  }

    // Add this dispose function
  void disposeProvider() {
    _children.clear();
    _selectedChild = null;
    // If you need to dispose any controllers or streams in FirestoreService:
    // _childService.dispose(); 
    notifyListeners();
  }
}