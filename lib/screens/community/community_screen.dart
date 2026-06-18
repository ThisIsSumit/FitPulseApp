import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text('Community'),
          actions: [
            IconButton(
                icon: const Icon(Icons.add_box_outlined,
                    color: AppColors.primary),
                onPressed: () => context.push('/community/create-post'))
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Challenges'),
              Tab(text: 'Leaderboard')
            ],
          ),
        ),
        body: TabBarView(
            controller: _tabCtrl,
            children: const [_FeedTab(), _ChallengesTab(), _LeaderboardTab()]),
      );
}

// ─── Feed ────────────────────────────────────────────────────
class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  List<Post>? _posts;

  @override
  void initState() {
    super.initState();
    SB.postsStream().listen((data) {
      if (mounted) setState(() => _posts = data.map(Post.fromMap).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_posts == null)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    if (_posts!.isEmpty)
      return const EmptyState(
          emoji: '💬',
          title: 'Be the first!',
          subtitle: 'Share your workout or achievement.');
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _posts!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _PostCard(post: _posts![i], index: i),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Post post;
  final int index;
  const _PostCard({required this.post, required this.index});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool?
      _optimisticLiked; // null = use server state, true/false = optimistic override
  int _optimisticCount = 0;

  Future<void> _toggleLike() async {
    final uid = SB.uid ?? '';
    final currentlyLiked = _optimisticLiked ?? widget.post.isLikedBy(uid);
    final currentCount = widget.post.likes.length +
        (_optimisticLiked == null ? 0 : (_optimisticLiked! ? 1 : -1));

    // Instant UI flip — no waiting
    setState(() {
      _optimisticLiked = !currentlyLiked;
      _optimisticCount = currentCount + (!currentlyLiked ? 1 : -1);
    });

    // Sync to server in background — UI already updated
    try {
      await SB.toggleLike(widget.post.id, widget.post.likes);
    } catch (_) {
      // revert on failure
      if (mounted) {
        setState(() {
          _optimisticLiked = currentlyLiked;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.likes != widget.post.likes) {
      _optimisticLiked = null; // server caught up, trust it again
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final uid = SB.uid ?? '';
    final isLiked = _optimisticLiked ?? widget.post.isLikedBy(uid);
    final likeCount =
        _optimisticLiked == null ? widget.post.likes.length : _optimisticCount;
    final name = widget.post.userInfo['name'] as String? ?? 'User';
    final photoUrl = widget.post.userInfo['photo_url'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bgSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                UserAvatar(photoUrl: photoUrl, name: name, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(timeago.format(widget.post.createdAt),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),

          // Post text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(widget.post.text, style: AppTextStyles.bodyLarge),
          ),

          // Post image
          if (widget.post.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.6,
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _ActionBtn(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '$likeCount',
                  color: isLiked ? AppColors.error : AppColors.textMuted,
                  onTap: _toggleLike,
                ),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${widget.post.commentsCount}',
                  color: AppColors.textMuted,
                  onTap: () => context.push('/community/post/${widget.post.id}',
                      extra: widget.post),
                ),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.textMuted,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (widget.index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 13)),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      );
}

// ─── Challenges ───────────────────────────────────────────────
class _ChallengesTab extends StatefulWidget {
  const _ChallengesTab();
  @override
  State<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<_ChallengesTab> {
  List<Challenge>? _challenges;
  @override
  void initState() {
    super.initState();
    SB.challengesStream().listen((data) {
      if (mounted)
        setState(() => _challenges = data.map(Challenge.fromMap).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges == null)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    if (_challenges!.isEmpty)
      return const EmptyState(
          emoji: '🏆', title: 'No challenges', subtitle: 'Check back soon!');
    final uid = SB.uid ?? '';
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _challenges!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) =>
          _ChallengeCard(challenge: _challenges![i], uid: uid, index: i),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final String uid;
  final int index;
  const _ChallengeCard(
      {required this.challenge, required this.uid, required this.index});
  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final isJoined = c.isJoined(widget.uid);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isJoined
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.bgSurface)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(c.category,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ])),
          if (isJoined)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Joined ✓',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),
        Text(c.description, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        Row(children: [
          _InfoPill(
              icon: Icons.calendar_today_outlined,
              label: '${c.daysLeft} days left'),
          const SizedBox(width: 10),
          _InfoPill(
              icon: Icons.people_outline_rounded,
              label: '${c.participants.length} joined'),
          const SizedBox(width: 10),
          _InfoPill(
              icon: Icons.emoji_events_outlined,
              label: c.reward.split('+').first.trim()),
        ]),
        if (!isJoined) ...[
          const SizedBox(height: 14),
          GradientButton(
              label: 'Join Challenge',
              isLoading: _joining,
              height: 46,
              onTap: () async {
                setState(() => _joining = true);
                await SB.joinChallenge(c.id, c.participants);
                setState(() => _joining = false);
              }),
        ],
      ]),
    )
        .animate()
        .fadeIn(delay: (widget.index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]);
}

// ─── Leaderboard ──────────────────────────────────────────────
class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();
  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  List<AppUser>? _users;
  @override
  void initState() {
    super.initState();
    SB.leaderboardStream().listen((data) {
      if (mounted) setState(() => _users = data.map(AppUser.fromMap).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_users == null)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    if (_users!.isEmpty)
      return const EmptyState(
          emoji: '🥇',
          title: 'Empty',
          subtitle: 'Start working out to appear here!');
    final me = SB.uid ?? '';
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _users!.length,
      itemBuilder: (_, i) => _LeaderRow(
          user: _users![i], rank: i + 1, isMe: _users![i].id == me, index: i),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final AppUser user;
  final int rank, index;
  final bool isMe;
  const _LeaderRow(
      {required this.user,
      required this.rank,
      required this.isMe,
      required this.index});

  Color get _rankColor => rank == 1
      ? const Color(0xFFFFD700)
      : rank == 2
          ? const Color(0xFFC0C0C0)
          : rank == 3
              ? const Color(0xFFCD7F32)
              : AppColors.textMuted;
  String get _rankEmoji => rank == 1
      ? '🥇'
      : rank == 2
          ? '🥈'
          : rank == 3
              ? '🥉'
              : '#$rank';

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withOpacity(0.12) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isMe
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.bgSurface),
        ),
        child: Row(children: [
          SizedBox(
              width: 40,
              child: Text(_rankEmoji,
                  style: TextStyle(
                      fontSize: rank <= 3 ? 22 : 14,
                      color: _rankColor,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          UserAvatar(photoUrl: user.photoUrl, name: user.name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(isMe ? '${user.name} (You)' : user.name,
                    style: TextStyle(
                        color: isMe ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('Level ${user.level} · ${user.totalWorkouts} workouts',
                    style: AppTextStyles.caption),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${user.totalCaloriesBurned}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const Text('kcal',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ]),
      )
          .animate()
          .fadeIn(delay: (index * 50).ms, duration: 350.ms)
          .slideX(begin: 0.1, end: 0);
}
