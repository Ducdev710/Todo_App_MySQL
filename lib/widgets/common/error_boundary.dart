// lib/widgets/common/error_boundary.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      if (mounted) {
        // Use addPostFrameCallback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _error = details.exception;
              _stackTrace = details.stack;
            });
            widget.onError
                ?.call(details.exception, details.stack ?? StackTrace.empty);
          }
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Đã xảy ra lỗi không mong muốn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (kDebugMode) ...[
                    Text(
                      _error.toString(),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    if (_stackTrace != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Stack Trace:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _stackTrace.toString().substring(0, 
                          _stackTrace.toString().length > 200 ? 200 : _stackTrace.toString().length),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        textAlign: TextAlign.left,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _stackTrace = null;
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
