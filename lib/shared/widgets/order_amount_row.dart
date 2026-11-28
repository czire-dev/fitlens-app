import 'package:flutter/material.dart';

import '../../core/format_price.dart';

class OrderAmountRow extends StatelessWidget {
  const OrderAmountRow({
    super.key,
    required this.label,
    required this.centavos,
    this.emphasized = false,
  });

  final String label;
  final int centavos;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: EdgeInsets.only(top: emphasized ? 10 : 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatPesos(centavos),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
