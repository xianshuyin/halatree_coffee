import 'package:json_annotation/json_annotation.dart';
part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id') String? id;
  @JsonKey(name: 'email') String? email;
  @JsonKey(name: 'user_name') String? user_name;
  //@JsonKey(name: 'last_name') String? last_name;
  @JsonKey(name: 'total_points') String? total_points;
  @JsonKey(name: 'password') String? password;

  UserModel();

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}