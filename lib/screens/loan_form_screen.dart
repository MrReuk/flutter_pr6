import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/loan.dart';
import '../repositories/entity_repository.dart';
import '../state/reference_notifier.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class LoanFormScreen extends StatelessWidget {
  const LoanFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loans = context.read<LoanRepository>();
    final refs = context.read<ReferenceNotifier>();

    return EntityFormScreen<Loan>(
      title: 'Новая выдача',
      backPath: '/loans',
      notFoundMessage: 'Выдача не найдена',
      savedMessage: 'Выдача оформлена',
      needsRefs: true,
      needsLinks: true,
      loadItem: null,
      initialValues: (loan) => {'readerId': null, 'bookId': null, 'days': '14'},
      fields: (loan) => [
        FieldSpec.dropdown(
          key: 'readerId',
          label: 'Читатель',
          required: true,
          validator: mustChoose('Выберите читателя'),
          options: (values) => refs.readerOptions(),
        ),
        FieldSpec.dropdown(
          key: 'bookId',
          label: 'Книга',
          required: true,
          validator: mustChoose('Выберите книгу'),
          options: (values) => refs.bookOptions(),
        ),
        FieldSpec.text(
          key: 'days',
          label: 'Срок выдачи, дней',
          required: true,
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          validator: checks([notBlank(), integerInRange(1, 90)]),
        ),
      ],
      save: (values, existing) async {
        await loans.issue(
          readerId: values['readerId'] as int,
          bookId: values['bookId'] as int,
          days: int.parse((values['days'] as String).trim()),
        );
      },
    );
  }
}
