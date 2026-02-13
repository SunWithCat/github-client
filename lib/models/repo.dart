import 'package:json_annotation/json_annotation.dart';

part 'repo.g.dart';

@JsonSerializable()
class Repo {
  String name;
  String? description;
  String? language;
  @JsonKey(name: 'private', defaultValue: false)
  bool isPrivate;
  @JsonKey(name: 'stargazers_count')
  int starCount;
  @JsonKey(name: 'forks_count')
  int forkCount;
  @JsonKey(name: 'owner')
  Map<String, dynamic> ownerData;
  @JsonKey(name: 'default_branch')
  String? defaultBranch;

  String get owner => ownerData['login'];

  Repo({
    required this.name,
    this.description,
    this.language,
    required this.isPrivate,
    required this.starCount,
    required this.forkCount,
    required this.ownerData,
    this.defaultBranch,
  });

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}
