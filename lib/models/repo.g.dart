// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repo _$RepoFromJson(Map<String, dynamic> json) => Repo(
  name: json['name'] as String,
  description: json['description'] as String?,
  language: json['language'] as String?,
  starCount: (json['stargazers_count'] as num).toInt(),
  forkCount: (json['forks_count'] as num).toInt(),
  ownerData: json['owner'] as Map<String, dynamic>,
  defaultBranch: json['default_branch'] as String?,
);

Map<String, dynamic> _$RepoToJson(Repo instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'language': instance.language,
  'stargazers_count': instance.starCount,
  'forks_count': instance.forkCount,
  'owner': instance.ownerData,
  'default_branch': instance.defaultBranch,
};
