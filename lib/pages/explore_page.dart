import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghclient/common/widgets/repo_item.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/profile_change.dart';
import 'package:ghclient/services/github_service.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _isLoading = true;
  List<Repo> _trendingRepos = [];
  String _selectedTimeRange = 'monthly';

  final Map<String, String> _timeRangeLabels = {
    'daily': '今日热门',
    'weekly': '本周热门',
    'monthly': '本月热门',
  };

  @override
  void initState() {
    super.initState();
    _fetchTrendingRepos();
  }

  Future<void> _fetchTrendingRepos() async {
    setState(() {
      _isLoading = true;
    });
    final token = context.read<ProfileChange>().profile.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final githubService = GithubService();
      final repos = await githubService.getTrendingRepos(
        token,
        timeRange: _selectedTimeRange,
      );
      if (mounted) {
        setState(() {
          _trendingRepos = repos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载热门仓库失败：$e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTimeRangeChanged(String timeRange) {
    if (_selectedTimeRange != timeRange) {
      setState(() {
        _selectedTimeRange = timeRange;
        _trendingRepos = []; // 清空数据
      });
      _fetchTrendingRepos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('探索热门仓库')),
      body: RefreshIndicator(
        onRefresh: _fetchTrendingRepos,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment(
                      value: 'daily',
                      label: Text('今日'),
                      icon: Icon(OctIcons.flame_16),
                    ),
                    ButtonSegment(
                      value: 'weekly',
                      label: Text('本周'),
                      icon: Icon(OctIcons.rocket_16),
                    ),
                    ButtonSegment(
                      value: 'monthly',
                      label: Text('本月'),
                      icon: Icon(OctIcons.pulse_16),
                    ),
                  ],
                  selected: {_selectedTimeRange},
                  onSelectionChanged: (Set<String> newSelection) {
                    _onTimeRangeChanged(newSelection.first);
                  },
                  style: ButtonStyle(
                    // 适配主题颜色
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.onSecondary;
                      }
                      return null;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.secondary;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Fluttertoast.showToast(
                    toastLength: Toast.LENGTH_SHORT,
                    msg: '搜索功能正在开发中~'
                  );
                },
                label: Text('搜索'),
                icon: Icon(Icons.search),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            '${_timeRangeLabels[_selectedTimeRange]}仓库',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _trendingRepos.isEmpty
                  ? Center(
                    child: Text(
                      '未能加载热门仓库，请下拉刷新重试',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                  : ListView.builder(
                    itemCount: _trendingRepos.length,
                    itemBuilder: (context, index) {
                      return RepoItem(repo: _trendingRepos[index]);
                    },
                  ),
        ),
      ],
    );
  }
}
