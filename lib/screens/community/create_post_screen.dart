import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitness_app/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? editingPost; // null = creating new, non-null = editing
  const CreatePostScreen({super.key, this.editingPost});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final _textCtrl =
      TextEditingController(text: widget.editingPost?.text ?? '');
  File? _image;
  bool _loading = false;
  String _selectedType = 'Achievement';
  String? _existingImageUrl;

  final _postTypes = [
    ('Achievement', '🏆'),
    ('Workout', '💪'),
    ('Nutrition', '🥗'),
    ('Progress', '📈'),
    ('Motivation', '🔥'),
  ];

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.editingPost?.imageUrl;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _image = File(file.path));
  }

  Future<void> _post() async {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final user = context.read<AuthProvider>().user;
    String? imageUrl = _existingImageUrl;

    if (_image != null) {
      final uploaded = await SB.uploadPostImage(_image!);
      if (uploaded != null) imageUrl = uploaded;
    }

    if (widget.editingPost != null) {
      await SB.updatePost(
        postId: widget.editingPost!.id,
        text: _textCtrl.text.trim(),
        type: _selectedType,
        imageUrl: imageUrl,
      );
    } else {
      await SB.createPost({
        'text': _textCtrl.text.trim(),
        'image_url': imageUrl,
        'type': _selectedType,
        'user_info': {
          'name': user?.name ?? '',
          'photo_url': user?.photoUrl ?? '',
          'uid': user?.id ?? '',
        },
      });
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(widget.editingPost != null ? 'Edit Post' : 'New Post'),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _loading ? null : _post,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _textCtrl.text.trim().isEmpty
                      ? null
                      : AppColors.primaryGradient,
                  color: _textCtrl.text.trim().isEmpty
                      ? AppColors.bgSurface
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.bgDark)))
                    : Text(
                        widget.editingPost != null ? 'Save' : 'Post',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textCtrl.text.trim().isEmpty
                              ? AppColors.textMuted
                              : AppColors.bgDark,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            UserAvatar(
                photoUrl: user?.photoUrl, name: user?.name ?? '', radius: 22),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Text('Posting to Community',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ]).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),

          // Post type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _postTypes
                .map((t) => GestureDetector(
                      onTap: () => setState(() => _selectedType = t.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _selectedType == t.$1
                              ? AppColors.primaryGradient
                              : null,
                          color: _selectedType == t.$1
                              ? null
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(t.$2, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(t.$1,
                              style: TextStyle(
                                  color: _selectedType == t.$1
                                      ? AppColors.bgDark
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ]),
                      ),
                    ))
                .toList(),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Share your achievement, progress, or motivation...',
              border: InputBorder.none,
              filled: false,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const Divider(color: AppColors.bgSurface, height: 32),

          if (_image != null || _existingImageUrl != null) ...[
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _image != null
                    ? Image.file(_image!,
                        width: double.infinity, height: 220, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: _existingImageUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _image = null;
                      _existingImageUrl = null;
                    }),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18)),
                  )),
            ]).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bgSurface)),
              child: const Row(children: [
                Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 12),
                Text('Add Photo',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ]),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ]),
      ),
    );
  }
}
