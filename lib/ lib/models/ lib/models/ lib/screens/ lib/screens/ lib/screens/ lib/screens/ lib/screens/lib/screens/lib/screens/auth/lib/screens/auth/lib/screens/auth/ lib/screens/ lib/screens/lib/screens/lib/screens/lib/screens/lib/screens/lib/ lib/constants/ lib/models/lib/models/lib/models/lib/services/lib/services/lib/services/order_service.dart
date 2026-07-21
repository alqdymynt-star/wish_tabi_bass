import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'supabase_service.dart';

class OrderService {
  static final _table = SupabaseService.client.from('orders');

  static Future<List<OrderModel>> getMyOrders() async {
    final res = await _table
        .select()
        .eq('user_id', SupabaseService.currentUserId!)
        .order('created_at', ascending: false);
    return res.map((e) => OrderModel.fromJson(e)).toList();
  }

  static Future<List<OrderModel>> getAllOrders() async {
    final res = await _table.select().order('created_at', ascending: false);
    return res.map((e) => OrderModel.fromJson(e)).toList();
  }

  static Future<OrderModel> createOrder(OrderModel order) async {
    final res = await _table.insert(order.toJson()).select().single();
    return OrderModel.fromJson(res);
  }

  static Future<void> updateStatus(String id, String status) async {
    await _table.update({'status': status}).eq('id', id);
  }

  static Future<void> deleteOrder(String id) async {
    await _table.delete().eq('id', id);
  }
}

