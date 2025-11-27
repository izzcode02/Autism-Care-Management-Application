import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ToyyibPayService {
  static final String _baseUrl = dotenv.env['TOYYIBPAY_DEV_BASE_URL'] as String;
  static final String _userSecretKey = dotenv.env['TOYYIBPAY_DEV_KEY'] as String; // Replace with your actual secret key
  static final String _categoryCode = dotenv.env['TOYYIBPAY_CATEGORY_CODE'] as String; // Replace with your category code

  // Test credentials (remove these and use your real credentials)
  static const bool _useTestMode = true; // Set to false for production

  // Create bill for payment
  Future<Map<String, dynamic>> createBill({
    required double amount,
    required String userEmail,
    required String userName,
    required String userPhone,
    String? billName,
    String? billDescription,
  }) async {
    try {
      // Validate required fields
      if (_userSecretKey == 'YOUR_SECRET_KEY_HERE' ||
          _categoryCode == 'YOUR_CATEGORY_CODE_HERE') {
        return {
          'success': false,
          'error':
              'Please configure your ToyyibPay credentials (userSecretKey and categoryCode)',
        };
      }

      if (userEmail.isEmpty || userName.isEmpty) {
        return {
          'success': false,
          'error': 'User email and name are required',
        };
      }

      final url = Uri.parse('$_baseUrl/index.php/api/createBill');

      final billNameFinal = billName ?? 'Monthly Payment';
      final billDescriptionFinal =
          billDescription ?? 'Autism Care Management Payment';

      final requestBody = {
        'userSecretKey': _userSecretKey,
        'categoryCode': _categoryCode,
        'billName': billNameFinal,
        'billDescription': billDescriptionFinal,
        'billPriceSetting': '1', // 1 = fixed price
        'billPayorInfo': '1', // 1 = required
        'billAmount': (amount * 100).toInt().toString(), // Amount in cents
        'billReturnUrl': '', // Optional return URL
        'billCallbackUrl': '', // Leave empty since we're using webview
        'billExternalReferenceNo':
            DateTime.now().millisecondsSinceEpoch.toString(),
        'billTo': userName,
        'billEmail': userEmail,
        'billPhone':
            userPhone.isNotEmpty ? userPhone : '0123456789', // Fallback phone
        'billSplitPayment': '0',
        'billSplitPaymentArgs': '',
        'billPaymentChannel': '0', // 0 = FPX, 1 = Credit Card, 2 = Both
        // 'billContentEmail': _generateEmailReceipt(
        //   userName: userName,
        //   userEmail: userEmail,
        //   amount: amount,
        //   billName: billNameFinal,
        //   billDescription: billDescriptionFinal,
        // ),
        'billChargeToCustomer': '1', // 1 = charge to customer
        'billExpiryDate': _getExpiryDate(),
      };

      print('ToyyibPay Request URL: $url');
      print('ToyyibPay Request Body: $requestBody');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      print('ToyyibPay API Response Status: ${response.statusCode}');
      print('ToyyibPay API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if response contains error
        if (responseData is List && responseData.isNotEmpty) {
          final firstItem = responseData[0];
          if (firstItem.containsKey('BillCode')) {
            return {
              'success': true,
              'data': responseData,
            };
          } else if (firstItem.containsKey('error')) {
            return {
              'success': false,
              'error': 'ToyyibPay Error: ${firstItem['error']}',
            };
          } else {
            return {
              'success': false,
              'error': 'Invalid response format: ${responseData.toString()}',
            };
          }
        } else if (responseData is Map) {
          if (responseData.containsKey('BillCode')) {
            return {
              'success': true,
              'data': [responseData], // Wrap in array for consistency
            };
          } else if (responseData.containsKey('error')) {
            return {
              'success': false,
              'error': 'ToyyibPay Error: ${responseData['error']}',
            };
          } else {
            return {
              'success': false,
              'error': 'Invalid response format: ${responseData.toString()}',
            };
          }
        } else {
          return {
            'success': false,
            'error': 'Unexpected response format: ${responseData.toString()}',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating bill: $e',
      };
    }
  }

  // Get bill transactions (to check payment status)
  Future<Map<String, dynamic>> getBillTransactions(String billCode) async {
    try {
      final url = Uri.parse('$_baseUrl/index.php/api/getBillTransactions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'userSecretKey': _userSecretKey,
          'billCode': billCode,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get transactions: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting transactions: $e',
      };
    }
  }

  // Get payment URL for webview
  String getPaymentUrl(String billCode) {
    return '$_baseUrl/$billCode';
  }

  // Helper method to get expiry date (30 days from now)
  String _getExpiryDate() {
    final expiryDate = DateTime.now().add(const Duration(days: 30));
    return '${expiryDate.day.toString().padLeft(2, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.year}';
  }

  bool isPaymentCompleted(String url) {
    // Enhanced success indicators based on ToyyibPay receipt page
    final successPatterns = [
      'status_id=1',
      'payment_status=1',
      'successful',
      'success',
      'Payment Successful',
      'Payment Approved',
      'payment approved',
      'thank you',
      'receipt',
      'bill code',
      'reference no',
      'transaction',
      'tp2506', // ToyyibPay transaction reference pattern
      'status : payment successful',
      'payment receipt',
      'powered by toyyibpay',
    ];

    final lowercaseUrl = url.toLowerCase();
    return successPatterns
        .any((pattern) => lowercaseUrl.contains(pattern.toLowerCase()));
  }

  bool isPaymentFailed(String url) {
    final failurePatterns = [
      'status_id=3',
      'payment_status=0',
      'failed',
      'error',
      'Payment Failed',
      'declined',
      'cancelled',
      'unsuccessful',
      'payment not successful',
    ];

    final lowercaseUrl = url.toLowerCase();
    return failurePatterns
        .any((pattern) => lowercaseUrl.contains(pattern.toLowerCase()));
  }

  bool isPaymentPending(String url) {
    final pendingPatterns = [
      'status_id=2',
      'pending',
      'processing',
      'in progress',
    ];

    final lowercaseUrl = url.toLowerCase();
    return pendingPatterns
        .any((pattern) => lowercaseUrl.contains(pattern.toLowerCase()));
  }

  // Enhanced: Check if we're on the receipt page
  bool isReceiptPage(String url) {
    final receiptPatterns = [
      'payment receipt',
      'receipt',
      'thank you',
      'bill code',
      'reference no',
      'transaction',
      'tp2506', // ToyyibPay transaction reference pattern
      'payment successful',
      'payment approved',
      'powered by toyyibpay',
      'total payment',
      'status : payment',
    ];

    final lowercaseUrl = url.toLowerCase();
    bool isReceipt = receiptPatterns
        .any((pattern) => lowercaseUrl.contains(pattern.toLowerCase()));

    print('Checking if receipt page: $url -> $isReceipt');
    return isReceipt;
  }

  // Enhanced: Extract payment details from receipt page using JavaScript
  String getReceiptExtractionScript() {
    return '''
      function extractPaymentDetails() {
        try {
          // Get all text content from the page
          const bodyText = document.body.innerText.toLowerCase();
          let paymentStatus = 'unknown';
          let referenceNo = '';
          let billCode = '';
          
          console.log('Page content:', bodyText);
          
          // Check for success indicators with more specific patterns
          if (bodyText.includes('payment successful') || 
              bodyText.includes('payment approved') ||
              bodyText.includes('status : payment successful') ||
              bodyText.includes('success') ||
              bodyText.includes('thank you')) {
            paymentStatus = 'success';
          }
          
          // Check for failure indicators
          if (bodyText.includes('payment failed') || 
              bodyText.includes('failed') ||
              bodyText.includes('declined') ||
              bodyText.includes('unsuccessful')) {
            paymentStatus = 'failed';
          }
          
          // Extract reference number (ToyyibPay format: TP followed by numbers)
          const refMatch = bodyText.match(/tp\\d{13,}/);
          if (refMatch) {
            referenceNo = refMatch[0].toUpperCase();
          }
          
          // Extract bill code (usually lowercase alphanumeric)
          const billMatch = bodyText.match(/bill code[:\\s]*([a-z0-9]{6,})/);
          if (billMatch) {
            billCode = billMatch[1];
          }
          
          // If we found bill code or reference, and no explicit failure, assume success
          if ((referenceNo || billCode) && paymentStatus === 'unknown') {
            paymentStatus = 'success';
          }
          
          return JSON.stringify({
            status: paymentStatus,
            referenceNo: referenceNo,
            billCode: billCode,
            url: window.location.href,
            hasReceipt: bodyText.includes('receipt') || bodyText.includes('bill code') || bodyText.includes('reference no')
          });
        } catch (e) {
          console.error('Error extracting payment details:', e);
          return JSON.stringify({
            status: 'error',
            error: e.message,
            url: window.location.href
          });
        }
      }
      
      extractPaymentDetails();
    ''';
  }

  // New method to verify payment status via API
  Future<Map<String, dynamic>> verifyPaymentStatus(String billCode) async {
    try {
      final result = await getBillTransactions(billCode);
      if (result['success']) {
        final transactions = result['data'];
        if (transactions is List && transactions.isNotEmpty) {
          final latestTransaction = transactions.first;
          return {
            'success': true,
            'status': latestTransaction['billpaymentStatus'] ?? 'unknown',
            'data': latestTransaction,
          };
        }
      }
      return {
        'success': false,
        'error': 'No transaction data found',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error verifying payment: $e',
      };
    }
  }
}
