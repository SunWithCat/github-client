import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/pages/repo_detail/contributor_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributorsTab extends StatefulWidget {
  final List<dynamic> contributors;
  final Future<void> Function() onRefresh;

  const ContributorsTab({
    super.key,
    required this.contributors,
    required this.onRefresh,
  });

  @override
  State<ContributorsTab> createState() => _ContributorsTabState();
}

class _ContributorsTabState extends State<ContributorsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// 获取项目总贡献数（所有贡献者贡献数之和）
  int get totalContributions {
    if (widget.contributors.isEmpty) return 0;
    int total = 0;
    for (final contributor in widget.contributors) {
      total += (contributor['contributions'] ?? 0) as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.contributors.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: OctIcons.people_16,
              title: '没有贡献者信息',
              message: '这个仓库目前没有贡献者数据',
            ),
          ),
        ),
      );
    }

    final total = totalContributions;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: widget.contributors.length,
        itemBuilder: (context, index) {
          final contributor = widget.contributors[index];

          return ContributorCard(
            contributor: contributor as Map<String, dynamic>,
            totalContributions: total,
            onTap: () async {
              final url = Uri.parse(contributor['html_url']);
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
          );
        },
      ),
    );
  }
}
