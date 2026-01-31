
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tax Calculation Logic (IGST vs CGST/SGST)', () {
    
    // Helper function to simulate the logic in POSProvider
    Map<String, double> calculate({
      required double taxableAmount,
      required String? branchState,
      required String? customerState,
      required double igstRate, 
      required double cgstRate, 
      required double sgstRate,
    }) {
      bool isInterState = false;

      if (branchState != null && 
          customerState != null && 
          branchState.isNotEmpty && 
          customerState.isNotEmpty && 
          branchState.trim().toLowerCase() != customerState.trim().toLowerCase()) {
        isInterState = true;
      }

      double cgstAmt = 0;
      double sgstAmt = 0;
      double igstAmt = 0;
      double gstRateUsed = 0;

      if (isInterState) {
        // IGST
        gstRateUsed = igstRate;
        igstAmt = (taxableAmount * igstRate) / 100;
      } else {
        // CGST + SGST
        gstRateUsed = cgstRate + sgstRate;
        cgstAmt = (taxableAmount * cgstRate) / 100;
        sgstAmt = (taxableAmount * sgstRate) / 100;
      }

      return {
        'cgst': cgstAmt,
        'sgst': sgstAmt,
        'igst': igstAmt,
        'totalTax': cgstAmt + sgstAmt + igstAmt,
      };
    }

    test('Intra-state (Same State) -> CGST + SGST', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: 'Karnataka',
        customerState: 'Karnataka',
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 90);
      expect(res['sgst'], 90);
      expect(res['igst'], 0);
      expect(res['totalTax'], 180);
    });

    test('Inter-state (Different State) -> IGST', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: 'Karnataka',
        customerState: 'Maharashtra',
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 0);
      expect(res['sgst'], 0);
      expect(res['igst'], 180);
      expect(res['totalTax'], 180);
    });

    test('Missing Customer State -> Intra-state (Default)', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: 'Karnataka',
        customerState: null,
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 90);
      expect(res['sgst'], 90);
      expect(res['igst'], 0);
    });

    test('Missing Branch State -> Intra-state (Default)', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: null,
        customerState: 'Karnataka',
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 90);
      expect(res['sgst'], 90);
      expect(res['igst'], 0);
    });

    test('Case Insensitive Check', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: 'karnataka',
        customerState: 'KARNATAKA',
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 90);
      expect(res['sgst'], 90);
      expect(res['igst'], 0);
    });
    
    test('Trim Whitespace Check', () {
      final res = calculate(
        taxableAmount: 1000,
        branchState: ' Karnataka ',
        customerState: 'Karnataka',
        igstRate: 18, cgstRate: 9, sgstRate: 9,
      );
      
      expect(res['cgst'], 90);
      expect(res['sgst'], 90);
      expect(res['igst'], 0);
    });
  });
}
