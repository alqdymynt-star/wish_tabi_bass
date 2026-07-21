import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/shared_widgets.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      setState(() {
        _offers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('العروض والخصومات'),
        elevation: 0,
      ),
      body: _isLoading
          ? const SkeletonList()
          : _offers.isEmpty
              ? const EmptyState(
                  title: 'لا توجد عروض حالياً',
                  subtitle: 'تابعنا قريباً لمفاجآت جديدة!',
                  icon: Icons.local_offer_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return FadeSlideTransition(
                      index: index,
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.local_offer,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    offer['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'خصم ${offer['discount_percentage']}%',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

