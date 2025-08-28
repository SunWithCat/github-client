import 'package:json_annotation/json_annotation.dart';

part 'my_user_model.g.dart';

@JsonSerializable() // 为User这个类生成JSON序列化和反序列化的代码
class User {
  String login; // 用户名
  String? name; // 昵称
  @JsonKey(name: 'avatar_url')
  String avatarUrl; // 头像链接
  String? bio; // 个人简介

  int followers; // 粉丝数
  int following; // 关注数
  @JsonKey(name: 'public_repos')
  int publicRepos; // 公开仓库
  String? location; // 所在地
  String? blog; // 博客链接
  @JsonKey(name: 'created_at')
  String? createdAt; // 初次加入GitHub的日期

  User({
    required this.login,
    this.name,
    required this.avatarUrl,
    this.bio,
    required this.followers,
    required this.following,
    required this.publicRepos,
    this.blog,
    this.location,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
