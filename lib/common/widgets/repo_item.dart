import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ghclient/models/repo.dart';

class RepoItem extends StatelessWidget {
  final Repo repo;
  const RepoItem({super.key, required this.repo});

  Color getLanguageColor(String? laungage) {
    if (laungage == null) return Colors.grey;
    switch (laungage.toLowerCase()) {
      case 'dart':
        return Colors.green.shade400;
      case 'java':
        return Colors.brown;
      case 'javascript':
        return Colors.yellow.shade700;
      case 'html':
        return Colors.deepOrange;
      case 'css':
        return Colors.purpleAccent;
      case 'vue':
        return Colors.green;
      case 'c++':
        return Colors.redAccent;
      case 'kotlin':
        return Colors.deepPurpleAccent;
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
          print('Tapped on...');
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
