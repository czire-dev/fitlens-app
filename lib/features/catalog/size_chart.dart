import 'package:flutter/material.dart';

const sevnChartSizes = ['XS', 'S', 'M', 'L', 'XL'];

Future<void> showSevnSizeChart(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('SEVN size chart'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Garment measurements in centimeters (cm).'),
        const SizedBox(height: 8),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              children: [
                Text('Size'),
                Text('Chest width'),
                Text('Body length'),
              ],
            ),
            for (final size in sevnChartSizes)
              TableRow(
                children: [
                  Text(size),
                  const Text('Pending'),
                  const Text('Pending'),
                ],
              ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);
