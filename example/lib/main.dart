import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telebirr_inapp_purchase_plus/telebirr_inapp_purchase_plus.dart';

void main() {
  runApp(const TelebirrExampleApp());
}

class TelebirrExampleApp extends StatelessWidget {
  const TelebirrExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const PaymentDemoPage(),
    );
  }
}

class PaymentDemoPage extends StatefulWidget {
  const PaymentDemoPage({super.key});

  @override
  State<PaymentDemoPage> createState() => _PaymentDemoPageState();
}

class _PaymentDemoPageState extends State<PaymentDemoPage> {
  final _backendUrl = TextEditingController(
    text: 'http://YOUR_LAN_IP:8001/api/telebirr/create-order',
  );
  final _appId = TextEditingController(text: 'YOUR_MERCHANT_APP_ID');
  final _shortCode = TextEditingController(text: 'YOUR_SHORT_CODE');
  final _returnApp = TextEditingController(text: 'yourappscheme');
  final _receiveCode = TextEditingController();
  final _amount = TextEditingController(text: '12.00');
  final _title = TextEditingController(text: 'Example order');

  StreamSubscription<TelebirrPaymentResult>? _subscription;
  TelebirrEnvironment _environment = TelebirrEnvironment.test;
  TelebirrPaymentResult? _lastResult;
  String? _merchantOrderId;
  String? _error;
  bool _creatingOrder = false;
  bool _paying = false;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
    _subscription = TelebirrInAppPurchasePlus.paymentResultStream.listen(
      (result) => setState(() => _lastResult = result),
      onError: (Object error) => setState(() => _error = error.toString()),
    );
  }

  Future<void> _checkInstalled() async {
    final installed = await TelebirrInAppPurchasePlus.isTelebirrInstalled();
    if (mounted) {
      setState(() => _installed = installed);
    }
  }

  Future<void> _createOrder() async {
    setState(() {
      _creatingOrder = true;
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl.text.trim()),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'title': _title.text.trim(),
              'amount': _amount.text.trim(),
              'environment': _environment.name,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(body['message']?.toString() ?? response.body);
      }
      if (body['success'] == false) {
        final code = body['code']?.toString();
        final message = body['message']?.toString();
        final rawMessage = body['raw'] is Map<String, dynamic>
            ? (body['raw'] as Map<String, dynamic>)['errorMsg']?.toString()
            : null;
        throw StateError([
          if (code != null && code.isNotEmpty) code,
          if (message != null && message.isNotEmpty) message,
          if ((message == null || message.isEmpty) &&
              rawMessage != null &&
              rawMessage.isNotEmpty)
            rawMessage,
        ].join(': '));
      }

      setState(() {
        _merchantOrderId = body['merchantOrderId']?.toString();
        _receiveCode.text = body['receiveCode']?.toString() ?? '';
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      await Telebirr.initialize(
        appId: _appId.text.trim(),
        shortCode: _shortCode.text.trim(),
        returnScheme: _returnApp.text.trim(),
        environment: _environment,
      );

      final result = await Telebirr.pay(
        receiveCode: _receiveCode.text.trim(),
      );
      setState(() => _lastResult = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _backendUrl.dispose();
    _appId.dispose();
    _shortCode.dispose();
    _returnApp.dispose();
    _receiveCode.dispose();
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telebirr InApp Purchase Plus'),
        actions: [
          IconButton(
            onPressed: _checkInstalled,
            tooltip: 'Check Telebirr app',
            icon: Icon(_installed ? Icons.verified : Icons.error_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TelebirrEnvironment>(
              segments: const [
                ButtonSegment(
                  value: TelebirrEnvironment.test,
                  label: Text('Test'),
                  icon: Icon(Icons.science_outlined),
                ),
                ButtonSegment(
                  value: TelebirrEnvironment.production,
                  label: Text('Production'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {_environment},
              onSelectionChanged: (value) {
                setState(() => _environment = value.first);
              },
            ),
            const SizedBox(height: 16),
            _field(_backendUrl, 'Backend create-order URL', Icons.link),
            _field(_appId, 'App ID', Icons.apps),
            _field(_shortCode, 'Short code', Icons.storefront),
            _field(_returnApp, 'Return app scheme', Icons.keyboard_return),
            _field(_amount, 'Amount', Icons.payments, decimal: true),
            _field(_title, 'Title', Icons.title),
            _field(_receiveCode, 'Receive code', Icons.qr_code_2, maxLines: 3),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _creatingOrder ? null : _createOrder,
              icon: _creatingOrder
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: const Text('Create Order From Backend'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.account_balance_wallet),
              label: const Text('Pay With Telebirr'),
            ),
            const SizedBox(height: 16),
            if (_merchantOrderId != null)
              _StatusTile(
                icon: Icons.tag,
                title: 'Merchant order',
                body: _merchantOrderId!,
              ),
            if (_error != null)
              _StatusTile(
                icon: Icons.error_outline,
                title: 'Error',
                body: _error!,
                color: Colors.red,
              ),
            if (_lastResult != null)
              _StatusTile(
                icon: _lastResult!.isSuccess
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                title: 'SDK callback result',
                body: jsonEncode(_lastResult!.toMap()),
                color: _lastResult!.isSuccess ? Colors.green : Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool decimal = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.body,
    this.color = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                SelectableText(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
