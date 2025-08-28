// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  login: json['login'] as String,
  name: json['name'] as String?,
  avatarUrl: json['avatar_url'] as String,
  bio: json['bio'] as String?,
  followers: (json['followers'] as num).toInt(),
  following: (json['following'] as num).toInt(),
  publicRepos: (json['public_repos'] as num).toInt(),
  blog: json['blog'] as String?,
  location: json['location'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'login': instance.login,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
  'bio': instance.bio,
  'followers': instance.followers,
  'following': instance.following,
  'public_repos': instance.publicRepos,
  'location': instance.location,
  'blog': instance.blog,
  'created_at': instance.createdAt,
};
