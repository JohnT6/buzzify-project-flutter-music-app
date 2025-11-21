import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String? hoTen;
  final String? email;
  final String? anhDaiDien;

  const User({
    required this.id,
    this.hoTen,
    this.email,
    this.anhDaiDien,
  });

  @override
  List<Object?> get props => [id, hoTen, email, anhDaiDien];

  // Hàm copyWith để cập nhật
  User copyWith({
    String? id,
    String? hoTen,
    String? email,
    String? anhDaiDien,
  }) {
    return User(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      anhDaiDien: anhDaiDien ?? this.anhDaiDien,
    );
  }

  // Cần thiết cho HydratedBloc (lưu vào bộ nhớ)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      hoTen: json['ho_ten'] as String?,
      email: json['email'] as String?,
      anhDaiDien: json['anh_dai_dien'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ho_ten': hoTen,
      'email': email,
      'anh_dai_dien': anhDaiDien,
    };
  }
}