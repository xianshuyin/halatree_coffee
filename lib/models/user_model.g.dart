// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel()
  ..id = json['id'] as String?
  ..email = json['email'] as String?
  ..user_name = json['user_name'] as String?
  ..total_points = json['total_points'] as String?
  ..password = json['password'] as String?;

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'user_name': instance.user_name,
  'total_points': instance.total_points,
  'password': instance.password,
};
