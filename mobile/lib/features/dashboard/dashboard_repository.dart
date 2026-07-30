import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'dashboard_dto.dart';

export 'dashboard_dto.dart';

abstract class DashboardRepositoryBase {
  Future<DashboardDto> resumo(int dias);
}

class DashboardRepository implements DashboardRepositoryBase {
  const DashboardRepository(this._client);
  final ApiClient _client;

  @override
  Future<DashboardDto> resumo(int dias) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/dashboard/resumo',
      queryParameters: {'dias': dias.toString()},
    );
    return DashboardDto.fromJson(res.data as Map<String, dynamic>);
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepositoryBase>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});
