import 'package:flutter/foundation.dart';
import '../core/api_exception.dart';
import '../models/trader.dart';
import '../services/trader_service.dart';

class TradersProvider extends ChangeNotifier {
  final TraderService service;
  TradersProvider({required this.service});

  List<Trader> traders = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load({String? query}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      traders = await service.list(query: query);
    } on ApiException catch (e) {
      errorMessage = e.displayMessage;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
