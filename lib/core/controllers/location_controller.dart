import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/order_service.dart';

class LocationController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();
  
  Timer? _locationTimer;
  final isTrackingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    startLocationTracking();
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    super.onClose();
  }

  Future<void> startLocationTracking() async {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      if (isTrackingLocation.value) return;
      
      isTrackingLocation.value = true;
      try {
        Position position = await _getCurrentLocation();
        await _sendLocationToServer(position);
        print('Location sent successfully: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error tracking location: $e');
      } finally {
        isTrackingLocation.value = false;
      }
    });
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permissions are denied');
      }
    }
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> _sendLocationToServer(Position position) async {
    final int? idBiker = await SecureStorage.getBikerId();
    if (idBiker != null) {
      await _orderService.updateLocation(idBiker, position.latitude, position.longitude);
    }
  }
}
