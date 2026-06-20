import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  List<Map<String, dynamic>>? _comments;

  @override
  void initState() {
    super.initState();
    SB.commentsStream(widget.post.id).listen((data) {
      if (mounted) setState(() => _comments = data);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    // Clear input immediately — feels instant
    _commentCtrl.clear();
    setState(() {}); // refresh send-button disabled state if any

    // Fire and forget — stream will push the new comment in automatically
    SB.addComment(
      postId: widget.post.id,
      text: text,
      userInfo: {'name': user.name, 'photo_url': user.photoUrl, 'uid': user.id},
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send comment'),
              backgroundColor: AppColors.error),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = widget.post.userInfo['name'] as String? ?? 'User';
    final photoUrl = widget.post.userInfo['photo_url'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Post')),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Post card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        UserAvatar(photoUrl: photoUrl, name: name, radius: 22),
                        const SizedBox(width: 12),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text(timeago.format(widget.post.createdAt),
                                  style: AppTextStyles.caption),
                            ]),
                      ]),
                      const SizedBox(height: 12),
                      Text(widget.post.text,
                          style: AppTextStyles.bodyLarge.copyWith(height: 1.5)),
                      if (widget.post.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.post.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 200,
                                color: AppColors.bgElevated,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.favorite_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text('${widget.post.likes.length} likes',
                            style: AppTextStyles.caption),
                      ]),
                    ]),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 20),
              Text('Comments', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),

              if (_comments == null)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              else if (_comments!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text('No comments yet. Be the first!',
                          style: TextStyle(color: AppColors.textMuted))),
                )
              else
                ..._comments!.asMap().entries.map((e) {
                  final d = e.value;
                  final ui = d['user_info'] as Map<String, dynamic>? ?? {};
                  return _CommentTile(
                    name: ui['name'] ?? 'User',
                    photoUrl: ui['photo_url'] ?? '',
                    text: d['text'] ?? '',
                    index: e.key,
                  );
                }),
            ],
          ),
        ),

        // Comment input bar
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.bgSurface)),
          ),
          child: Row(children: [
            UserAvatar(
                photoUrl: user?.photoUrl, name: user?.name ?? '', radius: 18),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                  fillColor: AppColors.bgElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendComment,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.bgDark, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String name, photoUrl, text;
  final int index;
  const _CommentTile(
      {required this.name,
      required this.photoUrl,
      required this.text,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(photoUrl: photoUrl, name: name, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(text, style: AppTextStyles.bodyMedium),
            ]),
          ),
        ),
      ]),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
