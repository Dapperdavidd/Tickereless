import 'package:equatable/equatable.dart';

/// A signed-in account as the app knows it, independent of how the user got
/// here (email or Google).
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.email,
    required this.userId,
  });

  final String accessToken;
  final String email;
  final String userId;

  @override
  List<Object?> get props => [accessToken, email, userId];
}
