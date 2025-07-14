import 'package:json_annotation/json_annotation.dart';

part 'repo.g.dart';

@JsonSerializable()
class Repo {
  String name;
  String? description;
  String? language;
  @JsonKey(name: 'stargazers_count')
  int starCount;
  @JsonKey(name: 'forks_count')
  int forkCount;

  Repo({
    required this.name,
    this.description,
    this.language,
    required this.starCount,
    required this.forkCount,
  });

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}
