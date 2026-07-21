import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../widgets/shared_widgets.dart';
import 'track_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;

  OrderStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  String _sortBy = 'date_desc';

  late TabController _tabController;
  final List<OrderStatus?> _tabs = [
    null,
    OrderStatus.pending,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedStatus = _tabs[_tabController.index];
      });
      _applyFilters();
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('المستخدم غير مسجل');

      final response = await _supabase
          .from('orders')
          .select('*, provider:profiles!provider_id(full_name, avatar_url, phone)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _allOrders = response.map((json) => Order.fromJson(json)).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الطلبات: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Order>.from(_allOrders);

    if (_selectedStatus != null) {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedDateRange != null) {
      filtered = filtered.where((o) {
        return o.createdAt.isAfter(_selectedDateRange!.start) &&
            o.createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'price_asc':
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
    }

    setState(() => _filteredOrders = filtered);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'date_desc':
        return 'الأحدث';
      case 'date_asc':
        return 'الأقدم';
      case 'price_desc':
        return 'الأعلى سعراً';
      case 'price_asc':
        return 'الأقل سعراً';
      default:
        return 'الترتيب';
    }
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ترتيب حسب',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _SortOption(
                  label: 'الأحدث أولاً',
                  icon: Icons.arrow_downward,
                  isSelected: _sortBy == 'date_desc',
                  onTap: () => _setSort('date_desc'),
                ),
                _SortOption(
                  label: 'الأقدم أولاً',
                  icon: Icons.arrow_upward,
                  isSelected: _sortBy == 'date_asc',
                  onTap: () => _setSort('date_asc'),
                ),
                _SortOption(
                  label: 'الأعلى سعراً',
                  icon: Icons.trending_up,
                  isSelected: _sortBy == 'price_desc',
                  onTap: () => _setSort('price_desc'),
                ),
                _SortOption(
                  label: 'الأقل سعراً',
                  icon: Icons.trending_down,
                  isSelected: _sortBy == 'price_asc',
                  onTap: () => _setSort('price_asc'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSort(String sort) {
    Navigator.pop(context);
    setState(() => _sortBy = sort);
    _applyFilters();
  }

  void _navigateToOrderDetail(Order order) {
    if (order.status == OrderStatus.onTheWay || order.status == OrderStatus.preparing) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackOrderScreen(orderId: order.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 60, right: 16, left: 16),
                title: const Text(
                  'طلباتي',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                background: Container(color: Colors.white),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث في طلباتك...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.light,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.grey,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'الكل'),
                        Tab(text: 'قيد المراجعة'),
                        Tab(text: 'جاري التوصيل'),
                        Tab(text: 'تم التوصيل'),
                        Tab(text: 'ملغي'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  _FilterChip(
                    icon: Icons.calendar_today_outlined,
                    label: _selectedDateRange != null
                        ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                        : 'التاريخ',
                    isActive: _selectedDateRange != null,
                    onTap: _selectDateRange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    icon: Icons.sort,
                    label: _getSortLabel(),
                    isActive: _sortBy != 'date_desc',
                    onTap: _showSortDialog,
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredOrders.length} طلب',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const SkeletonList()
                  : _error != null
                      ? ErrorState(message: _error!, onRetry: _loadOrders)
                      : _filteredOrders.isEmpty
                          ? EmptyState(
                              title: 'لا توجد طلبات',
                              subtitle: _selectedStatus != null || _searchQuery.isNotEmpty
                                  ? 'جرب تغيير معايير البحث'
                                  : 'ابدأ بتقديم طلبك الأول الآن!',
                              icon: Icons.shopping_bag_outlined,
                              actionLabel: 'طلب جديد',
                              onAction: () {},
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredOrders.length,
                                itemBuilder: (context, index) {
                                  return FadeSlideTransition(
                                    index: index,
                                    child: _OrderCard(
                                      order: _filteredOrders[index],
                                      onTap: () => _navigateToOrderDetail(_filteredOrders[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: order.imageUrl != null
                    ? Image.network(
                        order.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      text: order.status.label,
                      color: Color(order.status.colorValue),
                      icon: _getStatusIcon(order.status),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.folder_open_outlined, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          order.category,
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(order.createdAt),
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (order.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${order.price!.toStringAsFixed(0)} ر.س',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          if (order.providerName != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: order.providerImage != null
                      ? NetworkImage(order.providerImage!)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: order.providerImage == null
                      ? const Icon(Icons.person, size: 14, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  order.providerName!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (order.status == OrderStatus.delivered && order.rating == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'قيّم الآن',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, color: AppColors.primary),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : AppColors.light,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.dark,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

