/// Standardized view states for all ViewModels across the application.
enum ViewState {
  initial,
  loading,
  success,
  empty,
  error,
}

/// Base class or mixin helper for ViewModels handling state transitions.
mixin ViewStateMixin {
  ViewState _state = ViewState.initial;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isInitial => _state == ViewState.initial;
  bool get isLoading => _state == ViewState.loading;
  bool get isSuccess => _state == ViewState.success;
  bool get isEmpty => _state == ViewState.empty;
  bool get isError => _state == ViewState.error;

  void setState(ViewState state, {String? errorMessage}) {
    _state = state;
    _errorMessage = errorMessage;
  }
}
