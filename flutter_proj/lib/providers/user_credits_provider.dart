import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class UserCreditsState {
  final int freeCredits;
  final int paidCredits;
  final int totalCredits;
  final bool isLoading;
  final String? errorMessage;

  const UserCreditsState({
    this.freeCredits = 0,
    this.paidCredits = 0,
    this.isLoading = false,
    this.errorMessage,
  }) : totalCredits = freeCredits + paidCredits;

  UserCreditsState copyWith({
    int? freeCredits,
    int? paidCredits,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserCreditsState(
      freeCredits: freeCredits ?? this.freeCredits,
      paidCredits: paidCredits ?? this.paidCredits,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class UserCreditsNotifier extends StateNotifier<UserCreditsState> {
  UserCreditsNotifier() : super(const UserCreditsState()) {
    loadUserCredits();
  }

  Future<void> loadUserCredits() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await supabase
          .from('users_credits')
          .select('free_credits, paid_credits')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          freeCredits: response['free_credits'] ?? 0,
          paidCredits: response['paid_credits'] ?? 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '재화 정보 로딩 오류: $error',
      );
    }
  }

  Future<void> refreshCredits() async {
    await loadUserCredits();
  }
}

final userCreditsProvider = StateNotifierProvider<UserCreditsNotifier, UserCreditsState>((ref) {
  return UserCreditsNotifier();
});