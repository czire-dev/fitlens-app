import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checkout_models.dart';

// Metro Manila suggestions from the Philippine Statistics Authority's PSGC.
// https://psa.gov.ph/classification/psgc/citimuni/1300000000
const _localities = [
  'Caloocan City',
  'Las Piñas City',
  'Makati City',
  'Malabon City',
  'Mandaluyong City',
  'Manila',
  'Marikina City',
  'Pasig City',
  'Quezon City',
  'San Juan City',
  'Taguig City',
  'Valenzuela City',
];

class DeliveryForm extends StatelessWidget {
  const DeliveryForm({
    super.key,
    required this.formKey,
    required this.draft,
    required this.onChanged,
    required this.onReview,
  });

  final GlobalKey<FormState> formKey;
  final Map<DeliveryField, String> draft;
  final void Function(DeliveryField field, String value) onChanged;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleLarge;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contact', style: heading),
            const SizedBox(height: 12),
            _field(DeliveryField.name),
            _field(DeliveryField.mobile),
            const SizedBox(height: 8),
            Text('Delivery address', style: heading),
            const SizedBox(height: 12),
            _field(DeliveryField.address),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Autocomplete<String>(
                initialValue: TextEditingValue(
                  text: draft[DeliveryField.city] ?? '',
                ),
                optionsViewOpenDirection: OptionsViewOpenDirection.up,
                optionsMaxHeight: 160,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  if (query.isEmpty) return const Iterable<String>.empty();
                  return _localities
                      .where((name) {
                        final normalized = name.toLowerCase();
                        return normalized.startsWith(query) &&
                            normalized != query;
                      })
                      .take(4);
                },
                onSelected: (value) => onChanged(DeliveryField.city, value),
                fieldViewBuilder: (context, controller, focus, submitOption) {
                  return CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): () {
                        submitOption();
                        focus.nextFocus();
                      },
                    },
                    child: Padding(
                      // Leave room for the floating label below the upward menu.
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: controller,
                        focusNode: focus,
                        decoration: _decoration(DeliveryField.city),
                        autofillHints: const [AutofillHints.addressCity],
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: DeliveryField.city.validate,
                        onChanged: (value) =>
                            onChanged(DeliveryField.city, value),
                      ),
                    ),
                  );
                },
              ),
            ),
            _field(DeliveryField.postalCode),
            FilledButton(
              onPressed: onReview,
              child: const Text('Review order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(DeliveryField field) {
    final hint = switch (field) {
      DeliveryField.name => AutofillHints.name,
      DeliveryField.mobile => AutofillHints.telephoneNumber,
      DeliveryField.address => AutofillHints.fullStreetAddress,
      DeliveryField.postalCode => AutofillHints.postalCode,
      DeliveryField.city => AutofillHints.addressCity,
    };
    final last = field == DeliveryField.postalCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: draft[field],
        decoration: _decoration(field),
        keyboardType: switch (field) {
          DeliveryField.mobile => TextInputType.phone,
          DeliveryField.postalCode => TextInputType.number,
          DeliveryField.address => TextInputType.streetAddress,
          _ => TextInputType.text,
        },
        autofillHints: [hint],
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        textCapitalization: field == DeliveryField.name
            ? TextCapitalization.words
            : TextCapitalization.none,
        validator: field.validate,
        onChanged: (value) => onChanged(field, value),
      ),
    );
  }

  InputDecoration _decoration(DeliveryField field) => InputDecoration(
    labelText: field.label,
    border: const OutlineInputBorder(),
    errorMaxLines: 3,
  );
}
