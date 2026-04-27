import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

sealed class UserEvent {
  const UserEvent();
}

class OnLoadCustomerFromCache extends UserEvent {
  const OnLoadCustomerFromCache();
}

sealed class UserState {
  const UserState();
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  const UserLoaded(this.user);

  final UserEntity user;
}

class UserEmpty extends UserState {
  const UserEmpty();
}

class UserFailure extends UserState {
  const UserFailure(this.message);

  final String message;
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required AuthLocalDataSource localDataSource})
      : _localDataSource = localDataSource,
        super(const UserInitial()) {
    on<OnLoadCustomerFromCache>(_onLoadCustomerFromCache);
  }

  final AuthLocalDataSource _localDataSource;

  Future<void> _onLoadCustomerFromCache(
    OnLoadCustomerFromCache event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());

    try {
      final user = await _localDataSource.getCachedUser();

      if (user == null) {
        emit(const UserEmpty());
        return;
      }

      emit(UserLoaded(user));
    } catch (error) {
      emit(UserFailure(error.toString()));
    }
  }
}
