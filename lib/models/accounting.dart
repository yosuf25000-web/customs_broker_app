class CashBox {
  final String id;
  final String name;
  final String type;
  final double balance;

  CashBox({required this.id, required this.name, required this.type, required this.balance});

  factory CashBox.fromJson(Map<String, dynamic> json) => CashBox(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'cash',
        balance: double.tryParse('${json['balance'] ?? 0}') ?? 0,
      );

  String get typeLabel => type == 'bank' ? 'بنكي' : 'نقدي';
}

class Driver {
  final String id;
  final String name;
  final String? phone;
  final double currentBalance;

  Driver({required this.id, required this.name, this.phone, this.currentBalance = 0});

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        currentBalance: double.tryParse('${json['current_balance'] ?? 0}') ?? 0,
      );
}

class AccountingCategory {
  final String id;
  final String name;
  AccountingCategory({required this.id, required this.name});
  factory AccountingCategory.fromJson(Map<String, dynamic> json) =>
      AccountingCategory(id: json['id'] as String, name: json['name'] as String? ?? '');
}

class Voucher {
  final String id;
  final String voucherNo;
  final String type; // receipt | payment
  final String partyType;
  final double amount;
  final DateTime? voucherDate;
  final String? description;

  Voucher({
    required this.id, required this.voucherNo, required this.type, required this.partyType,
    required this.amount, this.voucherDate, this.description,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['id'] as String,
        voucherNo: json['voucher_no'] as String? ?? '',
        type: json['type'] as String? ?? 'receipt',
        partyType: json['party_type'] as String? ?? 'other',
        amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
        voucherDate: json['voucher_date'] != null ? DateTime.tryParse(json['voucher_date']) : null,
        description: json['description'] as String?,
      );

  bool get isReceipt => type == 'receipt';
}

class Expense {
  final String id;
  final String expenseNo;
  final String? categoryName;
  final double amount;
  final DateTime? expenseDate;
  final String? description;

  Expense({required this.id, required this.expenseNo, this.categoryName, required this.amount, this.expenseDate, this.description});

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        expenseNo: json['expense_no'] as String? ?? '',
        categoryName: json['category_name'] as String?,
        amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
        expenseDate: json['expense_date'] != null ? DateTime.tryParse(json['expense_date']) : null,
        description: json['description'] as String?,
      );
}

class ServiceInvoice {
  final String id;
  final String invoiceNo;
  final String? traderName;
  final double amount;
  final String status;
  final DateTime? invoiceDate;

  ServiceInvoice({required this.id, required this.invoiceNo, this.traderName, required this.amount, required this.status, this.invoiceDate});

  factory ServiceInvoice.fromJson(Map<String, dynamic> json) => ServiceInvoice(
        id: json['id'] as String,
        invoiceNo: json['invoice_no'] as String? ?? '',
        traderName: json['trader_name'] as String?,
        amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
        status: json['status'] as String? ?? 'unpaid',
        invoiceDate: json['invoice_date'] != null ? DateTime.tryParse(json['invoice_date']) : null,
      );

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'مسدَّدة';
      case 'partially_paid':
        return 'مسدَّدة جزئياً';
      default:
        return 'غير مسدَّدة';
    }
  }
}

class StatementLine {
  final DateTime entryDate;
  final String entryNo;
  final String? description;
  final double debit;
  final double credit;
  final double runningBalance;

  StatementLine({
    required this.entryDate, required this.entryNo, this.description,
    required this.debit, required this.credit, required this.runningBalance,
  });

  factory StatementLine.fromJson(Map<String, dynamic> json) => StatementLine(
        entryDate: DateTime.parse(json['entry_date']),
        entryNo: json['entry_no'] as String? ?? '',
        description: (json['line_description'] ?? json['entry_description']) as String?,
        debit: double.tryParse('${json['debit'] ?? 0}') ?? 0,
        credit: double.tryParse('${json['credit'] ?? 0}') ?? 0,
        runningBalance: double.tryParse('${json['running_balance'] ?? 0}') ?? 0,
      );
}
