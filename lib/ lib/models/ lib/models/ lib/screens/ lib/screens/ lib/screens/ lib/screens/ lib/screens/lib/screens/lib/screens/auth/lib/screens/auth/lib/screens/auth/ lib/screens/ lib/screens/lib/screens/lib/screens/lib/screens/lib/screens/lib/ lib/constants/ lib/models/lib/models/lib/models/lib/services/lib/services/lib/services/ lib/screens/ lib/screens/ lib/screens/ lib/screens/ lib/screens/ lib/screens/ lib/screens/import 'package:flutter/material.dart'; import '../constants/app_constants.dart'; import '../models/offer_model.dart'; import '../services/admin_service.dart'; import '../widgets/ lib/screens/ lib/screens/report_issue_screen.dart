import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/report_model.dart';
import '../services/supabase_service.dart';
import '../widgets/shared_widgets.dart';

class ReportIssueScreen extends StatefulWidget {
  final String orderId;
  const ReportIssueScreen({super.key, required this.orderId});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _reasonCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final report = ReportModel(
        id: '',
        orderId: widget.orderId,
        userId: SupabaseService.currentUserId!,
        reason: _reasonCtrl.text,
        details: _detailsCtrl.text.isEmpty ? null : _detailsCtrl.text,
        createdAt: DateTime.now(),
      );
      await SupabaseService.client.from('reports').insert(report.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإبلاغ')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإبلاغ عن مشكلة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(label: 'سبب الإبلاغ', controller: _reasonCtrl),
            const SizedBox(height: 16),
            CustomTextField(label: 'تفاصيل إضافية (اختياري)', controller: _detailsCtrl, maxLines: 4),
            const SizedBox(height: 24),
            CustomButton(text: 'إرسال الإبلاغ', onPressed: _submit, isLoading: _loading),
          ],
        ),
      ),
    );
  }
}

