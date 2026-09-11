import 'package:pos_billing/core/money/money.dart';

class LineCalcInput {
  const LineCalcInput({
    required this.unitPricePaise,
    required this.quantity,
    this.itemDiscountPaise = 0,
    this.taxRateBp = 0,
  });

  final int unitPricePaise;
  final int quantity;
  final int itemDiscountPaise;
  /// Basis points. 18% = 1800.
  final int taxRateBp;
}

class LineCalcResult {
  const LineCalcResult({
    required this.grossPaise,
    required this.itemDiscountPaise,
    required this.netPaise,
    required this.billDiscountSharePaise,
    required this.taxablePaise,
    required this.taxPaise,
    required this.totalPaise,
  });

  final int grossPaise;
  final int itemDiscountPaise;
  final int netPaise;
  final int billDiscountSharePaise;
  final int taxablePaise;
  final int taxPaise;
  final int totalPaise;
}

class BillCalcResult {
  const BillCalcResult({
    required this.lines,
    required this.subtotalPaise,
    required this.itemDiscountPaise,
    required this.billDiscountPaise,
    required this.discountPaise,
    required this.taxPaise,
    required this.roundOffPaise,
    required this.grandTotalPaise,
  });

  final List<LineCalcResult> lines;
  final int subtotalPaise;
  final int itemDiscountPaise;
  final int billDiscountPaise;
  final int discountPaise;
  final int taxPaise;
  /// Difference applied so [grandTotalPaise] is a whole rupee (0.25 rule).
  final int roundOffPaise;
  final int grandTotalPaise;

  Money get grandTotal => Money(grandTotalPaise);

  static BillCalcResult fromParts({
    required List<LineCalcResult> lines,
    required int subtotalPaise,
    required int itemDiscountPaise,
    required int billDiscountPaise,
    required int discountPaise,
    required int taxPaise,
  }) {
    final raw = (subtotalPaise - billDiscountPaise) + taxPaise;
    final rounded = roundPaiseToRupeeAt25(raw);
    return BillCalcResult(
      lines: lines,
      subtotalPaise: subtotalPaise,
      itemDiscountPaise: itemDiscountPaise,
      billDiscountPaise: billDiscountPaise,
      discountPaise: discountPaise,
      taxPaise: taxPaise,
      roundOffPaise: rounded - raw,
      grandTotalPaise: rounded,
    );
  }
}

class BillingCalculationService {
  const BillingCalculationService();

  BillCalcResult calculate({
    required List<LineCalcInput> lines,
    int billDiscountPaise = 0,
  }) {
    if (lines.isEmpty) {
      return const BillCalcResult(
        lines: [],
        subtotalPaise: 0,
        itemDiscountPaise: 0,
        billDiscountPaise: 0,
        discountPaise: 0,
        taxPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 0,
      );
    }

    final nets = <int>[];
    final grosses = <int>[];
    var itemDiscountTotal = 0;
    for (final line in lines) {
      final qty = line.quantity < 0 ? 0 : line.quantity;
      final gross = line.unitPricePaise * qty;
      final itemDiscount = line.itemDiscountPaise.clamp(0, gross);
      grosses.add(gross);
      nets.add(gross - itemDiscount);
      itemDiscountTotal += itemDiscount;
    }

    final subtotal = nets.fold<int>(0, (a, b) => a + b);
    final billDiscount = billDiscountPaise.clamp(0, subtotal);

    final shares = _allocate(billDiscount, nets);
    final results = <LineCalcResult>[];
    var taxTotal = 0;
    for (var i = 0; i < lines.length; i++) {
      final taxable = nets[i] - shares[i];
      final tax = _tax(taxable, lines[i].taxRateBp);
      taxTotal += tax;
      results.add(
        LineCalcResult(
          grossPaise: grosses[i],
          itemDiscountPaise: grosses[i] - nets[i],
          netPaise: nets[i],
          billDiscountSharePaise: shares[i],
          taxablePaise: taxable,
          taxPaise: tax,
          totalPaise: taxable + tax,
        ),
      );
    }

    return BillCalcResult.fromParts(
      lines: results,
      subtotalPaise: subtotal,
      itemDiscountPaise: itemDiscountTotal,
      billDiscountPaise: billDiscount,
      discountPaise: itemDiscountTotal + billDiscount,
      taxPaise: taxTotal,
    );
  }

  /// Replaces calculated tax with [taxOverridePaise] and reallocates it across lines.
  BillCalcResult applyTaxOverride(BillCalcResult calc, int taxOverridePaise) {
    final tax = taxOverridePaise < 0 ? 0 : taxOverridePaise;
    if (calc.lines.isEmpty) {
      return BillCalcResult.fromParts(
        lines: const [],
        subtotalPaise: calc.subtotalPaise,
        itemDiscountPaise: calc.itemDiscountPaise,
        billDiscountPaise: calc.billDiscountPaise,
        discountPaise: calc.discountPaise,
        taxPaise: tax,
      );
    }

    final weights = calc.lines.map((l) => l.taxablePaise).toList();
    final shares = _allocate(tax, weights);
    final lines = <LineCalcResult>[];
    for (var i = 0; i < calc.lines.length; i++) {
      final line = calc.lines[i];
      lines.add(
        LineCalcResult(
          grossPaise: line.grossPaise,
          itemDiscountPaise: line.itemDiscountPaise,
          netPaise: line.netPaise,
          billDiscountSharePaise: line.billDiscountSharePaise,
          taxablePaise: line.taxablePaise,
          taxPaise: shares[i],
          totalPaise: line.taxablePaise + shares[i],
        ),
      );
    }

    return BillCalcResult.fromParts(
      lines: lines,
      subtotalPaise: calc.subtotalPaise,
      itemDiscountPaise: calc.itemDiscountPaise,
      billDiscountPaise: calc.billDiscountPaise,
      discountPaise: calc.discountPaise,
      taxPaise: tax,
    );
  }

  int calculatePaidAmount(List<int> paymentAmounts) =>
      paymentAmounts.fold<int>(0, (a, b) => a + b);

  int calculateBalance({required int grandTotalPaise, required int paidPaise}) {
    final balance = grandTotalPaise - paidPaise;
    return balance < 0 ? 0 : balance;
  }

  int calculateChange({required int grandTotalPaise, required int receivedPaise}) {
    final change = receivedPaise - grandTotalPaise;
    return change < 0 ? 0 : change;
  }

  int _tax(int taxablePaise, int taxRateBp) {
    if (taxablePaise <= 0 || taxRateBp <= 0) return 0;
    return roundHalfUp(taxablePaise * taxRateBp / 10000);
  }

  List<int> _allocate(int amount, List<int> weights) {
    if (amount == 0 || weights.isEmpty) {
      return List<int>.filled(weights.length, 0);
    }
    final totalWeight = weights.fold<int>(0, (a, b) => a + b);
    if (totalWeight <= 0) return List<int>.filled(weights.length, 0);

    final shares = List<int>.filled(weights.length, 0);
    var allocated = 0;
    var remainderIndex = 0;
    var maxWeight = -1;
    for (var i = 0; i < weights.length; i++) {
      shares[i] = (amount * weights[i]) ~/ totalWeight;
      allocated += shares[i];
      if (weights[i] > maxWeight) {
        maxWeight = weights[i];
        remainderIndex = i;
      }
    }
    shares[remainderIndex] += amount - allocated;
    return shares;
  }
}
