import 'package:flutter/material.dart';

/// TODO(port): implement from the Angular component (see ANGULAR_SOURCE_OF_TRUTH.md).
class MemberDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const MemberDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('MemberDetailPage — not yet ported')));
  }
}
