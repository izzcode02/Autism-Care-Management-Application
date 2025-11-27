import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/parents/controllers/toyyibpayment_controller.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String userEmail;
  final String userName;
  final String userPhone;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailed;
  final VoidCallback? onPaymentCancelled;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentCancelled,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _webViewController;
  final ToyyibPayService _paymentService = ToyyibPayService();
  bool _isLoading = true;
  bool _hasError = false;
  bool _paymentStatus = false; // Track payment status from API
  bool _paymentProcessed = false;
  bool _paymentCompleted = false;
  String _errorMessage = '';
  String? _billCode;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final result = await _paymentService.createBill(
        amount: widget.amount,
        userEmail: widget.userEmail,
        userName: widget.userName,
        userPhone: widget.userPhone,
        billName: 'Autism Care Payment',
        billDescription: 'Monthly payment for autism care services',
      );

      if (result['success']) {
        final billData = result['data'];
        print('Bill creation response: $billData');

        if (billData is List && billData.isNotEmpty) {
          _billCode = billData[0]['BillCode'];
        } else if (billData is Map) {
          _billCode = billData['BillCode'];
        }

        if (_billCode != null) {
          print('Bill code received: $_billCode');
          _initializeWebView();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Failed to get bill code from response: ${result['data']}';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['error'] ?? 'Failed to create payment';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing payment: $e';
      });
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) async {
            setState(() => _isLoading = false);
            _checkPaymentStatusViaAPI();
            print('Page finished loading: $url');

            if (_isReceiptPage(url)) {
              await _extractPaymentDetailsFromReceipt();
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Web error: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation to: ${request.url}');
            // _checkPaymentStatus(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_paymentService.getPaymentUrl(_billCode!)));
  }

  bool _isReceiptPage(String url) {
    final receiptIndicators = [
      'payment receipt',
      'receipt',
      'thank you',
      'bill code',
      'reference no',
      'payment successful',
      'payment approved',
      'transaction',
      'tp25',
      'status : payment successful',
      'powered by toyyibpay',
    ];

    final lowercaseUrl = url.toLowerCase();
    return receiptIndicators
        .any((indicator) => lowercaseUrl.contains(indicator));
  }

  Future<void> _extractPaymentDetailsFromReceipt() async {
    if (_paymentProcessed) return;

    try {
      final jsResult = await _webViewController.runJavaScriptReturningResult('''
        (function() {
          try {
            const bodyText = document.body.innerText.toLowerCase();
            const successIndicators = [
              'payment successful',
              'payment approved', 
              'status : payment successful',
              'thank you',
              'bill code',
              'reference no',
              'tp25',
              'powered by toyyibpay'
            ];
            
            const failureIndicators = [
              'payment failed',
              'failed',
              'declined',
              'unsuccessful'
            ];
            
            let status = 'unknown';
            
            if (successIndicators.some(indicator => bodyText.includes(indicator))) {
              status = 'success';
            }
            else if (failureIndicators.some(indicator => bodyText.includes(indicator))) {
              status = 'failed';
            }
            else if (bodyText.includes('total payment') || 
                     bodyText.includes('payment for') ||
                     bodyText.includes('autism care')) {
              status = 'success';
            }
            
            return {
              status: status,
              url: window.location.href,
              pageContent: bodyText.substring(0, 500)
            };
          } catch (e) {
            return {
              status: 'error',
              error: e.message,
              url: window.location.href
            };
          }
        })();
      ''');

      print('JavaScript result: $jsResult');

      if (jsResult != null) {
        Map<String, dynamic> result;

        if (jsResult is Map) {
          result = Map<String, dynamic>.from(jsResult);
        } else {
          try {
            result = json.decode(jsResult.toString());
          } catch (e) {
            result = {'status': 'error', 'error': 'Failed to parse result'};
          }
        }

        if (result['status'] == 'success') {
          _handlePaymentSuccess();
        } else if (result['status'] == 'failed') {
          _handlePaymentFailed();
        } else {
          final currentUrl = await _webViewController.currentUrl();
          if (currentUrl != null && _isReceiptPage(currentUrl)) {
            _handlePaymentSuccess();
          }
        }
      }
    } catch (e) {
      print('Error extracting details: $e');
      final currentUrl = await _webViewController.currentUrl();
      if (currentUrl != null && _isReceiptPage(currentUrl)) {
        _handlePaymentSuccess();
      }
    }
  }

  // Add this method to check payment status via API
  Future<void> _checkPaymentStatusViaAPI() async {
    if (_billCode == null || _paymentProcessed) return;

    try {
      setState(() => _isLoading = true);

      final result = await _paymentService.getBillTransactions(_billCode!);

      if (result['success']) {
        final transactions = result['data'];

        if (transactions is List && transactions.isNotEmpty) {
          final latestTransaction = transactions.first;
          final status = latestTransaction['billpaymentStatus'];

          if (status == '1') {
            // Payment is successful
            setState(() => _paymentStatus = true);
            _handlePaymentSuccess();
          } else if (status == '3') {
            // Payment failed
            _handlePaymentFailed();
          } else if (status == '2') {
            // Payment pending
            _handlePaymentPending();
          }
        }
      } else {
        print('Failed to verify payment: ${result['error']}');
      }
    } catch (e) {
      print('Error verifying payment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Modify your _handlePaymentSuccess to set completion state
  void _handlePaymentSuccess() {
    if (_paymentProcessed) return;
    _paymentProcessed = true;

    setState(() {
      _paymentStatus = true;
      _paymentCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Payment completed successfully!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPaymentSuccess?.call();
      }
    });
  }

  void _handlePaymentFailed() {
    if (_paymentProcessed) return;
    _paymentProcessed = true;

    setState(() {
      _paymentCompleted = true;
    });

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'Payment Failed',
      desc: 'Your payment could not be processed. Please try again.',
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      btnOkOnPress: () {
        Navigator.of(context).pop();
        widget.onPaymentFailed?.call();
      },
    ).show();
  }

  void _handlePaymentPending() {
    if (_paymentProcessed) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'Payment Pending',
      desc: 'Your payment is being processed. Please wait for confirmation.',
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      btnOkOnPress: () {
        Navigator.of(context).pop();
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showCancelDialog,
        ),
      ),
      body: _buildBody(),
    );
  }

// Update your _buildBody method to use _paymentStatus
  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_paymentCompleted && _paymentStatus) {
      return _buildCompletionWidget();
    }

    return Stack(
      children: [
        if (_billCode != null) WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(child: CustomLoader()),
          ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomLoader(),
          SizedBox(height: 16),
          Text(
            'Preparing payment...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text('Please check your email for receipt!'),
          const SizedBox(height: 8),
          const Text('Redirecting to parents payment page...'),
          const SizedBox(height: 16),
          const CustomLoader(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Payment Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializePayment,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'Cancel Payment',
      desc: 'Are you sure you want to cancel the payment?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        Navigator.of(context).pop();
        widget.onPaymentCancelled?.call();
      },
      btnCancelText: 'No',
      btnOkText: 'Yes',
    ).show();
  }
}
