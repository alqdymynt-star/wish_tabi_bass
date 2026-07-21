import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../widgets/shared_widgets.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  GoogleMapController? _mapController;
  Order? _order;
  bool _isLoading = true;
  String? _error;

  LatLng? _customerLocation;
  LatLng? _providerLocation;
  LatLng? _currentLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  StreamSubscription? _locationSubscription;
  StreamSubscription? _orderSubscription;
  Timer? _locationTimer;

  static const Color _primaryColor = AppColors.primary;
  static const Color _routeColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _orderSubscription?.cancel();
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, provider:profiles!provider_id(full_name, phone, avatar_url), order_locations(provider_lat, provider_lng, updated_at)')
          .eq('id', widget.orderId)
          .single();

      setState(() {
        _order = Order.fromJson(response);
        _customerLocation = _order!.customerLocation;
        _providerLocation = _order!.providerLocation;
        _isLoading = false;
      });

      _setupMarkers();
      _startLocationTracking();
      _subscribeToOrderUpdates();
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل بيانات الطلب';
        _isLoading = false;
      });
    }
  }

  void _setupMarkers() {
    if (_customerLocation == null) return;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '📍 موقعك', snippet: 'نقطة الاستلام'),
      ),
    };

    if (_providerLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('provider'),
          position: _providerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚚 ${_order?.providerName ?? 'مقدم الخدمة'}',
            snippet: 'جاري التوصيل',
          ),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });

    _fitBounds();
  }

  void _startLocationTracking() {
    _locationSubscription = _supabase
        .from('order_locations')
        .stream(primaryKey: ['id'])
        .eq('order_id', widget.orderId)
        .listen((data) {
          if (data.isNotEmpty) {
            final latest = data.first;
            final newLocation = LatLng(
              latest['provider_lat'] as double,
              latest['provider_lng'] as double,
            );
            _updateProviderLocation(newLocation);
          }
        });

    _simulateProviderMovement();
  }

  void _updateProviderLocation(LatLng newLocation) {
    setState(() {
      _providerLocation = newLocation;
      _markers.removeWhere((m) => m.markerId.value == 'provider');
      _markers.add(
        Marker(
          markerId: const MarkerId('provider'),
          position: newLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚚 ${_order?.providerName ?? 'مقدم الخدمة'}',
            snippet: _getDistanceText(),
          ),
        ),
      );
      _updatePolyline();
    });
    _animateCameraToProvider();
  }

  void _updatePolyline() {
    if (_customerLocation == null || _providerLocation == null) return;
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_providerLocation!, _customerLocation!],
          color: _routeColor,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });
  }

  void _subscribeToOrderUpdates() {
    _orderSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.orderId)
        .listen((data) {
          if (data.isNotEmpty) {
            setState(() {
              _order = Order.fromJson(data.first);
            });
          }
        });
  }

  void _fitBounds() {
    if (_mapController == null || _customerLocation == null) return;
    if (_providerLocation == null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_customerLocation!, 15),
      );
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(
        _customerLocation!.latitude < _providerLocation!.latitude
            ? _customerLocation!.latitude
            : _providerLocation!.latitude,
        _customerLocation!.longitude < _providerLocation!.longitude
            ? _customerLocation!.longitude
            : _providerLocation!.longitude,
      ),
      northeast: LatLng(
        _customerLocation!.latitude > _providerLocation!.latitude
            ? _customerLocation!.latitude
            : _providerLocation!.latitude,
        _customerLocation!.longitude > _providerLocation!.longitude
            ? _customerLocation!.longitude
            : _providerLocation!.longitude,
      ),
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _animateCameraToProvider() {
    if (_mapController == null || _providerLocation == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(_providerLocation!),
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) *
            cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  String _getDistanceText() {
    if (_customerLocation == null || _providerLocation == null) return '';
    final distance = _calculateDistance(_customerLocation!, _providerLocation!);
    if (distance < 1) {
      return 'المسافة: ${(distance * 1000).toStringAsFixed(0)} متر';
    }
    return 'المسافة: ${distance.toStringAsFixed(1)} كم';
  }

  void _simulateProviderMovement() {
    if (_providerLocation == null || _customerLocation == null) return;
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final latDiff = _customerLocation!.latitude - _providerLocation!.latitude;
      final lngDiff = _customerLocation!.longitude - _providerLocation!.longitude;
      final newLat = _providerLocation!.latitude + latDiff * 0.1;
      final newLng = _providerLocation!.longitude + lngDiff * 0.1;
      final distance = _calculateDistance(
        LatLng(newLat, newLng),
        _customerLocation!,
      );
      if (distance < 0.05) {
        timer.cancel();
        _showArrivalNotification();
      }
      _updateProviderLocation(LatLng(newLat, newLng));
    });
  }

  void _showArrivalNotification() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'وصل مقدم الخدمة! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_order?.providerName ?? 'مقدم الخدمة'} وصل إلى موقعك',
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'تم الاستلام',
              onPressed: () {
                Navigator.pop(context);
                _markAsDelivered();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsDelivered() async {
    try {
      await _supabase.from('orders').update({
        'status': OrderStatus.delivered.name,
        'delivered_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تأكيد استلام الطلب'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل تحديث الحالة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _callProvider() {
    if (_order?.providerPhone != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📞 الاتصال بمقدم الخدمة'),
          content: Text('رقم الهاتف: ${_order!.providerPhone}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            PrimaryButton(
              text: 'اتصال',
              width: 100,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  int _getProgressStep() {
    switch (_order?.status) {
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.onTheWay:
        return 2;
      case OrderStatus.delivered:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: AppLoader()),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: ErrorState(message: _error!, onRetry: _loadOrder),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _customerLocation ?? const LatLng(24.7136, 46.6753),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _order?.status.label ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          image: _order?.providerImage != null
                              ? DecorationImage(
                                  image: NetworkImage(_order!.providerImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _order?.providerImage == null
                            ? const Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order?.providerName ?? 'مقدم الخدمة',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDistanceText(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButtonCircle(
                        icon: Icons.phone,
                        onPressed: _callProvider,
                        backgroundColor: AppColors.success.withOpacity(0.1),
                        iconColor: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      IconButtonCircle(
                        icon: Icons.chat_bubble_outline,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  InfoRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'الطلب',
                    value: _order?.title ?? '',
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'العنوان',
                    value: _order?.customerAddress ?? 'لم يتم تحديد العنوان',
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    icon: Icons.access_time,
                    label: 'الوقت المتوقع',
                    value: '15 - 20 دقيقة',
                    iconColor: AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                  OrderProgressBar(
                    currentStep: _getProgressStep(),
                    steps: const ['تم القبول', 'جاري التحضير', 'في الطريق', 'تم التوصيل'],
                    icons: const [
                      Icons.check_circle,
                      Icons.restaurant,
                      Icons.delivery_dining,
                      Icons.home,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _fitBounds,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: AppColors.primary),
      ),
    );
  }
}

