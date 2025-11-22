import 'package:flutter/material.dart';
import 'package:myglodengate/Providers/visitor_alert_provider.dart';
import 'package:myglodengate/Providers/guard_alert_provider.dart';
import 'package:provider/provider.dart';

class VisitorAlertInitializer extends StatefulWidget {
  final Widget child;
  const VisitorAlertInitializer({required this.child});

  @override
  State<VisitorAlertInitializer> createState() =>
      _VisitorAlertInitializerState();
}

class _VisitorAlertInitializerState extends State<VisitorAlertInitializer> {
  @override
  void initState() {
    super.initState();
    // Delay listener setup until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VisitorAlertProvider>(
        context,
        listen: false,
      ).startListening(context);

      // Also start guard alerts if the logged-in user is a guard
      Provider.of<GuardAlertProvider>(context, listen: false).startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
