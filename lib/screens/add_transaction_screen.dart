import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../services/currency_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  final int? preselectedCategoryId;
  const AddTransactionScreen({super.key, this.existing, this.preselectedCategoryId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountCtrl  = TextEditingController();
  final _commentCtrl = TextEditingController();
  String   _type          = 'expense';
  int?     _categoryId;
  DateTime _date          = DateTime.now();
  String   _currency      = 'KGS';
  String?  _receiptBase64;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _type           = t.type;
      _categoryId     = t.categoryId;
      _date           = t.date;
      _currency       = t.currency;
      _receiptBase64  = t.receiptBase64;
      _amountCtrl.text  = t.amount.toString();
      _commentCtrl.text = t.comment ?? '';
    } else if (widget.preselectedCategoryId != null) {
      _categoryId = widget.preselectedCategoryId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 60, maxWidth: 1200);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _receiptBase64 = base64Encode(bytes));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Сфотографировать чек'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Выбрать из галереи'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите корректную сумму')));
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите категорию')));
      return;
    }
    final provider = context.read<BudgetProvider>();
    final tx = Transaction(
      id:             widget.existing?.id,
      type:           _type,
      amount:         amount,
      currency:       _currency,
      categoryId:     _categoryId!,
      date:           _date,
      comment:        _commentCtrl.text.isEmpty ? null : _commentCtrl.text,
      receiptBase64:  _receiptBase64,
    );
    if (widget.existing != null) {
      await provider.updateTransaction(tx);
    } else {
      await provider.addTransaction(tx);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BudgetProvider>();
    final cats      = provider.categories.where((c) => c.type == _type).toList();
    final dateFmt   = DateFormat('dd MMMM yyyy', 'ru_RU');
    final isExpense = _type == 'expense';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Изменить операцию' : 'Новая операция'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Тип ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                Expanded(child: _typeBtn('expense', 'Расход', const Color(0xFFF44336))),
                Expanded(child: _typeBtn('income',  'Доход',  const Color(0xFF4CAF50))),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── Сумма + Валюта ──
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Text(
                      CurrencyService.flags[_currency] ?? '💰',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(
                  labelText: 'Валюта',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: CurrencyService.supported.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${CurrencyService.flags[c]} $c',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ),
          ]),
          // Показываем эквивалент в сомах если валюта != KGS
          if (_currency != 'KGS') Builder(builder: (context) {
            final rates = context.watch<BudgetProvider>().rates;
            final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
            final kgs = amount * (rates[_currency] ?? 1);
            final fmt = NumberFormat('#,##0.##', 'ru_RU');
            return Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('≈ ${fmt.format(kgs)} KGS',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            );
          }),
          const SizedBox(height: 12),

          // ── Категория (выпадающий список) ──
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(
              labelText: 'Категория',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: cats.map((c) => DropdownMenuItem<int>(
              value: c.id,
              child: Row(children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: c.color.withAlpha(40),
                  child: Icon(c.icon, size: 14, color: c.color),
                ),
                const SizedBox(width: 10),
                Text(c.name),
              ]),
            )).toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),

          // ── Дата ──
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const Icon(Icons.calendar_today),
            title: Text(dateFmt.format(_date)),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // ── Комментарий ──
          TextFormField(
            controller: _commentCtrl,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Фото чека (только для расходов) ──
          if (isExpense) ...[
            Row(children: [
              const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Фото чека', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_receiptBase64 != null)
                TextButton.icon(
                  onPressed: () => setState(() => _receiptBase64 = null),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Удалить', style: TextStyle(color: Colors.red)),
                ),
            ]),
            const SizedBox(height: 8),
            if (_receiptBase64 != null)
              GestureDetector(
                onTap: () => _showFullImage(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_receiptBase64!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                      SizedBox(height: 6),
                      Text('Прикрепить чек', style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(_receiptBase64!)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() { _type = type; _categoryId = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color,
          )),
        ),
      ),
    );
  }
}
