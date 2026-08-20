import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq/core/bloc/load_status.dart';
import 'package:sapbaq/core/network/api_exception.dart';
import 'package:sapbaq/features/marketplace/data/marketplace_repository.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';

/// Holds the three marketplace feeds. Each tab loads independently and is
/// re-loaded after a purchase (a claim removes/decrements a listing).
class MarketplaceState extends Equatable {
  final LoadStatus waterStatus;
  final List<WaterListing> water;
  final String? waterError;

  final LoadStatus maintenanceStatus;
  final List<MaintenanceListing> maintenance;
  final String? maintenanceError;

  final LoadStatus equipmentStatus;
  final List<EquipmentListing> equipment;
  final String? equipmentError;

  const MarketplaceState({
    this.waterStatus = LoadStatus.initial,
    this.water = const [],
    this.waterError,
    this.maintenanceStatus = LoadStatus.initial,
    this.maintenance = const [],
    this.maintenanceError,
    this.equipmentStatus = LoadStatus.initial,
    this.equipment = const [],
    this.equipmentError,
  });

  MarketplaceState copyWith({
    LoadStatus? waterStatus,
    List<WaterListing>? water,
    String? waterError,
    LoadStatus? maintenanceStatus,
    List<MaintenanceListing>? maintenance,
    String? maintenanceError,
    LoadStatus? equipmentStatus,
    List<EquipmentListing>? equipment,
    String? equipmentError,
  }) {
    return MarketplaceState(
      waterStatus: waterStatus ?? this.waterStatus,
      water: water ?? this.water,
      waterError: waterError,
      maintenanceStatus: maintenanceStatus ?? this.maintenanceStatus,
      maintenance: maintenance ?? this.maintenance,
      maintenanceError: maintenanceError,
      equipmentStatus: equipmentStatus ?? this.equipmentStatus,
      equipment: equipment ?? this.equipment,
      equipmentError: equipmentError,
    );
  }

  @override
  List<Object?> get props => [
    waterStatus,
    water,
    waterError,
    maintenanceStatus,
    maintenance,
    maintenanceError,
    equipmentStatus,
    equipment,
    equipmentError,
  ];
}

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final MarketplaceRepository _repo;
  MarketplaceCubit(this._repo) : super(const MarketplaceState());

  Future<void> loadWater() async {
    emit(state.copyWith(waterStatus: LoadStatus.loading));
    try {
      final list = await _repo.water();
      emit(state.copyWith(waterStatus: LoadStatus.success, water: list));
    } on ApiException catch (e) {
      emit(
        state.copyWith(waterStatus: LoadStatus.failure, waterError: e.message),
      );
    }
  }

  Future<void> loadMaintenance() async {
    emit(state.copyWith(maintenanceStatus: LoadStatus.loading));
    try {
      final list = await _repo.maintenance();
      emit(
        state.copyWith(
          maintenanceStatus: LoadStatus.success,
          maintenance: list,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          maintenanceStatus: LoadStatus.failure,
          maintenanceError: e.message,
        ),
      );
    }
  }

  Future<void> loadEquipment() async {
    emit(state.copyWith(equipmentStatus: LoadStatus.loading));
    try {
      final list = await _repo.equipment();
      emit(
        state.copyWith(equipmentStatus: LoadStatus.success, equipment: list),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          equipmentStatus: LoadStatus.failure,
          equipmentError: e.message,
        ),
      );
    }
  }
}
