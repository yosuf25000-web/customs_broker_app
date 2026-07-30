import '../core/api_client.dart';
import '../models/accounting.dart';

class AccountingService {
  final ApiClient apiClient;
  AccountingService({required this.apiClient});

  Future<List<CashBox>> listCashBoxes() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/cash-boxes');
      return (res.data['cash_boxes'] as List).map((e) => CashBox.fromJson(e)).toList();
    });
  }

  Future<CashBox> createCashBox({required String name, String type = 'cash'}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/cash-boxes', data: {'name': name, 'type': type});
      return CashBox.fromJson(res.data['cash_box']);
    });
  }

  Future<List<Driver>> listDrivers() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/drivers');
      return (res.data['drivers'] as List).map((e) => Driver.fromJson(e)).toList();
    });
  }

  Future<Driver> createDriver({required String name, String? phone}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/drivers', data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      return Driver.fromJson(res.data['driver']);
    });
  }

  Future<List<AccountingCategory>> listExpenseCategories() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/expense-categories');
      return (res.data['expense_categories'] as List).map((e) => AccountingCategory.fromJson(e)).toList();
    });
  }

  Future<AccountingCategory> createExpenseCategory(String name) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/expense-categories', data: {'name': name});
      return AccountingCategory.fromJson(res.data['expense_category']);
    });
  }

  Future<List<AccountingCategory>> listRevenueCategories() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/revenue-categories');
      return (res.data['revenue_categories'] as List).map((e) => AccountingCategory.fromJson(e)).toList();
    });
  }

  Future<AccountingCategory> createRevenueCategory(String name) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/revenue-categories', data: {'name': name});
      return AccountingCategory.fromJson(res.data['revenue_category']);
    });
  }

  Future<List<Voucher>> listVouchers() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/vouchers');
      return (res.data['vouchers'] as List).map((e) => Voucher.fromJson(e)).toList();
    });
  }

  Future<Voucher> createVoucher({
    required String type, // receipt | payment
    required String partyType, // trader | driver
    required String partyId,
    required String cashBoxId,
    required double amount,
    String? description,
    String? declarationId,
  }) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/vouchers', data: {
        'type': type,
        'party_type': partyType,
        'party_id': partyId,
        'cash_box_id': cashBoxId,
        'amount': amount,
        if (description != null && description.isNotEmpty) 'description': description,
        if (declarationId != null) 'declaration_id': declarationId,
      });
      return Voucher.fromJson(res.data['voucher']);
    });
  }

  Future<List<Expense>> listExpenses() {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/expenses');
      return (res.data['expenses'] as List).map((e) => Expense.fromJson(e)).toList();
    });
  }

  Future<Expense> createExpense({
    required String categoryId,
    required double amount,
    required String cashBoxId,
    String? description,
    String? declarationId,
  }) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/expenses', data: {
        'category_id': categoryId,
        'amount': amount,
        'cash_box_id': cashBoxId,
        if (description != null && description.isNotEmpty) 'description': description,
        if (declarationId != null) 'declaration_id': declarationId,
      });
      return Expense.fromJson(res.data['expense']);
    });
  }

  Future<List<ServiceInvoice>> listServiceInvoices({String? traderId}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/service-invoices', queryParameters: {
        if (traderId != null) 'trader_id': traderId,
      });
      return (res.data['invoices'] as List).map((e) => ServiceInvoice.fromJson(e)).toList();
    });
  }

  Future<ServiceInvoice> createServiceInvoice({
    required String traderId,
    required String revenueCategoryId,
    required double amount,
    String? declarationId,
    String? description,
  }) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/service-invoices', data: {
        'trader_id': traderId,
        'revenue_category_id': revenueCategoryId,
        'amount': amount,
        if (declarationId != null) 'declaration_id': declarationId,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      return ServiceInvoice.fromJson(res.data['invoice']);
    });
  }

  Future<({List<StatementLine> lines, double closingBalance})> traderStatement(String traderId, {String? from, String? to}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/traders/$traderId/statement', queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });
      final lines = (res.data['lines'] as List).map((e) => StatementLine.fromJson(e)).toList();
      final closing = double.tryParse('${res.data['closing_balance'] ?? 0}') ?? 0;
      return (lines: lines, closingBalance: closing);
    });
  }

  Future<Map<String, dynamic>> profitLossReport({required String from, required String to}) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.get('/accounting/reports/profit-loss', queryParameters: {'from': from, 'to': to});
      return Map<String, dynamic>.from(res.data as Map);
    });
  }

  Future<Map<String, dynamic>> closeCashBoxDay({
    required String cashBoxId,
    required double actualCountedBalance,
    String? notes,
  }) {
    return apiClient.guard(() async {
      final res = await apiClient.dio.post('/accounting/cash-boxes/$cashBoxId/close-day', data: {
        'actual_counted_balance': actualCountedBalance,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Map<String, dynamic>.from(res.data['closing'] as Map);
    });
  }
}
