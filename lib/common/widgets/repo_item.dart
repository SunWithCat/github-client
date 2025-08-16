import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/repo_page.dart';
import 'package:ghclient/profile_change.dart';
import 'package:provider/provider.dart';

class RepoItem extends StatelessWidget {
  final Repo repo;
  const RepoItem({super.key, required this.repo});

  Color getLanguageColor(String? language) {
    if (language == null) return Colors.grey;
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF00B4AB); // Dart
      case 'java':
        return const Color(0xFFB07219); // Java
      case 'javascript':
        return const Color(0xFFF1E05A); // JavaScript
      case 'typescript':
        return const Color(0xFF3178c6); // TypeScript
      case 'html':
        return const Color(0xFFe34c26); // HTML
      case 'css':
        return const Color(0xFF563d7c); // CSS
      case 'vue':
        return const Color(0xFF41b883); // Vue
      case 'c++':
        return const Color(0xFFf34b7d); // C++
      case 'c':
        return const Color(0xFF555555); // C
      case 'c#':
        return const Color(0xFF178600); // C#
      case 'python':
        return const Color(0xFF3572A5); // Python
      case 'php':
        return const Color(0xFF4F5D95); // PHP
      case 'ruby':
        return const Color(0xFF701516); // Ruby
      case 'go':
        return const Color(0xFF00ADD8); // Go
      case 'rust':
        return const Color(0xFFdea584); // Rust
      case 'swift':
        return const Color(0xFFF05138); // Swift
      case 'kotlin':
        return const Color(0xFFA97BFF); // Kotlin
      case 'scala':
        return const Color(0xFFc22d40); // Scala
      case 'shell':
        return const Color(0xFF89E051); // Shell
      case 'dockerfile':
        return const Color(0xFF384D54); // Dockerfile
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          final profileChange = Provider.of<ProfileChange>(
            context,
            listen: false,
          );
          final token = profileChange.profile.token;
          if (token != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RepoPage(repo: repo, token: token),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bookBookmark,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repo.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (repo.description != null && repo.description!.isNotEmpty)
                Text(
                  repo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              const SizedBox(height: 16),

              Row(
                children: [
                  if (repo.language != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: getLanguageColor(repo.language),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(repo.language!),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.star, size: 16, color: Colors.yellow.shade700),
                  const SizedBox(width: 4),
                  Text(repo.starCount.toString()),
                  const SizedBox(width: 16),
                  const FaIcon(
                    FontAwesomeIcons.codeFork,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(repo.forkCount.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
