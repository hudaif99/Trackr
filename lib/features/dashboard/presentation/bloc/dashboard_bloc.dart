import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';

// ── Events ──────────────────────────────────────────────────────────────────

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

final class DashboardLoadRequested extends DashboardEvent {
  final String userId;
  const DashboardLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

final class DashboardRefreshRequested extends DashboardEvent {
  final String userId;
  const DashboardRefreshRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  final DashboardSummaryEntity summary;
  const DashboardLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

final class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardSummaryUseCase _getSummary;

  DashboardBloc(this._getSummary) : super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    final (summary, failure) = await _getSummary(event.userId);
    if (failure != null) {
      emit(DashboardError(failure.message));
      return;
    }
    emit(DashboardLoaded(summary!));
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Preserve old data while refreshing
    final current = state;
    final (summary, failure) = await _getSummary(event.userId);
    if (failure != null) {
      if (current is DashboardLoaded) return; // Keep old data silently
      emit(DashboardError(failure.message));
      return;
    }
    emit(DashboardLoaded(summary!));
  }
}
