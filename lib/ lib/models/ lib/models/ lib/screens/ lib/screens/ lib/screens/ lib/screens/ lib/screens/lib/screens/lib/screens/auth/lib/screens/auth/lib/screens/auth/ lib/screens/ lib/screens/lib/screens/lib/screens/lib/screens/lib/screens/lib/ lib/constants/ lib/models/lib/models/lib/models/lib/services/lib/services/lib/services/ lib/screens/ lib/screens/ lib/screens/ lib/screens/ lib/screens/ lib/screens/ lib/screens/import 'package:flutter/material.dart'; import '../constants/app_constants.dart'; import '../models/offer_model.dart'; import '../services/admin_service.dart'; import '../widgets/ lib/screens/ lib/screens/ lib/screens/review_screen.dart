import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../constants/app_constants.dart';
import '../models/review_model.dart';
import '../services/supabase_service.dart';
import '../widgets/shared_widgets.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  const ReviewScreen({super.key, required this.orderId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final review = ReviewModel(
        id: '',
        orderId: widget.orderId,
        userId: SupabaseService.currentUserId!,
        rating: _rating,
        comment: _commentCtrl.text.isEmpty ? null : _commentCtrl.text,
        createdAt: DateTime.now(),
      );
      await SupabaseService.client.from('reviews').insert(review.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك!')));
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
      appBar: AppBar(title: const Text('تقييم الطلب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('كيف كانت تجربتك؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) => const Icon(Icons.star, color: AppColors.warning),
              onRatingUpdate: (r) => _rating = r,
            ),
            const SizedBox(height: 24),
            CustomTextField(label: 'تعليق (اختياري)', controller: _commentCtrl, maxLines: 3),
            const SizedBox(height: 32),
            CustomButton(text: 'إرسال التقييم', onPressed: _submit, isLoading: _loading),
          ],
        ),
      ),
    );
  }
}

