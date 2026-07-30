import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/declaration.dart';
import '../services/declaration_service.dart';

class DeclarationsProvider extends ChangeNotifier {
  final DeclarationService service;
  DeclarationsProvider({required this.service});

  List<Declaration> declarations = [];
  bool isLoading = false;
  String? errorMessage;
  String? statusFilter;

  Future<void> load({String? status}) async {
    isLoading = true;
    errorMessage = null;
    statusFilter = status;
    notifyListeners();
    try {
      declarations = await service.list(status: status);
    } on ApiException catch (e) {
      errorMessage = e.displayMessage;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(status: statusFilter);
}
