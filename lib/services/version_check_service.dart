import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:truelovebiker/services/api.dart';

class VersionCheckService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> checkVersion() async {
    try {
      // 1. Obtener la versión actual de la app
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Obtener la versión mínima requerida desde el backend
      final response = await _apiService.getAppVersion('motorizado');

      if (response['status'] == 200) {
        final data = response['data'];
        String minVersion = data['min_version'];
        String latestVersion = data['latest_version'];
        bool forceUpdate =
            data['force_update'] == 1 || data['force_update'] == true;

        String updateUrl = '';
        if (Platform.isAndroid) {
          updateUrl = data['url_android'] ?? '';
        } else if (Platform.isIOS) {
          updateUrl = data['url_ios'] ?? '';
        }

        // 3. Comparar versiones
        bool needsUpdate = _compareVersions(currentVersion, minVersion) < 0;
        bool hasNewerVersion =
            _compareVersions(currentVersion, latestVersion) < 0;

        return {
          'needsUpdate': needsUpdate,
          'hasNewerVersion': hasNewerVersion,
          'forceUpdate': forceUpdate,
          'updateUrl': updateUrl,
          'currentVersion': currentVersion,
          'latestVersion': latestVersion,
        };
      }
      return {'needsUpdate': false};
    } catch (e) {
      return {'needsUpdate': false};
    }
  }

  /// Compara dos versiones semánticas (x.y.z)
  /// Retorna:
  ///   -1 si v1 < v2
  ///    0 si v1 == v2
  ///    1 si v1 > v2
  int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int p1 = i < v1Parts.length ? v1Parts[i] : 0;
      int p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }
}
