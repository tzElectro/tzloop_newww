import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/wled_device.dart';
import '../../../core/services/device_discovery_service.dart';
import '../../../core/services/wled_api_service.dart';
// Events
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object> get props => [];
}

class LoadDevices extends DeviceEvent {}

class AddDevice extends DeviceEvent {
  final WledDevice device;

  const AddDevice(this.device);

  @override
  List<Object> get props => [device];
}

class UpdateDevice extends DeviceEvent {
  final WledDevice device;

  const UpdateDevice(this.device);

  @override
  List<Object> get props => [device];
}

class RemoveDevice extends DeviceEvent {
  final String ipAddress;

  const RemoveDevice(this.ipAddress);

  @override
  List<Object> get props => [ipAddress];
}

// State
class DeviceState extends Equatable {
  final List<WledDevice> devices;
  final bool isLoading;
  final String? error;

  const DeviceState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  DeviceState copyWith({
    List<WledDevice>? devices,
    bool? isLoading,
    String? error,
  }) {
    return DeviceState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [devices, isLoading, error];
}

// Bloc
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceDiscoveryService _discoveryService;
  final UnifiedWledService _apiService;

  DeviceBloc()
      : _discoveryService = DeviceDiscoveryService(),
        _apiService = UnifiedWledService(),
        super(const DeviceState()) {
    on<LoadDevices>(_onLoadDevices);
    on<AddDevice>(_onAddDevice);
    on<UpdateDevice>(_onUpdateDevice);
    on<RemoveDevice>(_onRemoveDevice);
  }

  Future<void> _onLoadDevices(
    LoadDevices event,
    Emitter<DeviceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final devices = await _discoveryService.discoverDevices();
      emit(state.copyWith(
        devices: devices,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load devices: $e',
      ));
    }
  }

  void _onAddDevice(
    AddDevice event,
    Emitter<DeviceState> emit,
  ) {
    final devices = List<WledDevice>.from(state.devices)..add(event.device);
    emit(state.copyWith(devices: devices));
  }

  void _onUpdateDevice(
    UpdateDevice event,
    Emitter<DeviceState> emit,
  ) {
    final devices = List<WledDevice>.from(state.devices);
    final index = devices.indexWhere((d) => d.info.ip == event.device.info.ip);
    
    if (index != -1) {
      devices[index] = event.device;
      emit(state.copyWith(devices: devices));
    }
  }

  void _onRemoveDevice(
    RemoveDevice event,
    Emitter<DeviceState> emit,
  ) {
    final devices = List<WledDevice>.from(state.devices)
      ..removeWhere((d) => d.info.ip == event.ipAddress);
    emit(state.copyWith(devices: devices));
  }
} 