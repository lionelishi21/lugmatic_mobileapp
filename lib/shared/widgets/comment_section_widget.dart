import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/comment_model.dart';
import '../../data/services/comment_service.dart';
import '../../data/services/socket_service.dart';
import '../../core/network/token_storage.dart';
import '../../core/theme/neumorphic_theme.dart';

class CommentSectionWidget extends StatefulWidget {
  final String contentType;
  final String contentId;
  final bool showHeader;
  final double horizontalPadding;

  const CommentSectionWidget({
    Key? key,
    required this.contentType,
    required this.contentId,
    this.showHeader = true,
    this.horizontalPadding = 16,
  }) : super(key: key);

  @override
  _CommentSectionWidgetState createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isPosting = false;
  String? _error;
  List<CommentModel> _comments = [];
  // Ids that arrived (or were posted) this session — drives the entrance animation.
  final Set<String> _animatedIds = {};

  SocketService? _socketService;
  StreamSubscription? _newCommentSub;
  StreamSubscription? _likedSub;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToLiveUpdates());
  }

  void _subscribeToLiveUpdates() {
    if (!mounted) return;
    final socketService = SocketService.getInstance(tokenStorage: context.read<TokenStorage>());
    _socketService = socketService;
    socketService.joinCommentThread(widget.contentType, widget.contentId);

    _newCommentSub = socketService.onCommentNew.listen((data) {
      if (data['contentType'] != widget.contentType || data['contentId'] != widget.contentId) return;
      final comment = CommentModel.fromJson(data);
      if (!mounted || _comments.any((c) => c.id == comment.id)) return;
      setState(() {
        _comments.insert(0, comment);
        _animatedIds.add(comment.id);
      });
    });

    _likedSub = socketService.onCommentLiked.listen((data) {
      final commentId = data['commentId']?.toString();
      final likeCount = (data['likeCount'] as num?)?.toInt();
      if (commentId == null || likeCount == null || !mounted) return;
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return;
      setState(() {
        _comments[index] = _comments[index].copyWith(likes: likeCount);
      });
    });
  }

  @override
  void dispose() {
    _socketService?.leaveCommentThread(widget.contentType, widget.contentId);
    _newCommentSub?.cancel();
    _likedSub?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.contentId.isEmpty) {
        throw Exception('Invalid content ID for ${widget.contentType}');
      }
      final commentService = context.read<CommentService>();
      final comments = await commentService.getComments(widget.contentType, widget.contentId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isPosting = true);
    try {
      if (widget.contentId.isEmpty) {
        throw Exception('Cannot post comment to invalid content');
      }
      final commentService = context.read<CommentService>();
      final newComment = await commentService.postComment(
        widget.contentType,
        widget.contentId,
        _commentController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _animatedIds.add(newComment.id);
          _commentController.clear();
          _isPosting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike(CommentModel comment) async {
    final startIndex = _comments.indexWhere((c) => c.id == comment.id);
    if (startIndex == -1) return;
    final optimistic = comment.copyWith(
      isLiked: !comment.isLiked,
      likes: comment.isLiked ? comment.likes - 1 : comment.likes + 1,
    );
    setState(() => _comments[startIndex] = optimistic);
    try {
      final commentService = context.read<CommentService>();
      final (likeCount, isLiked) = await commentService.toggleLike(comment.id);
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (mounted && index != -1) {
        setState(() => _comments[index] = _comments[index].copyWith(likes: likeCount, isLiked: isLiked));
      }
    } catch (e) {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (mounted && index != -1) setState(() => _comments[index] = comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding, vertical: 8),
            child: const Text(
              'Comments',
              style: TextStyle(
                color: NeumorphicTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Post Comment Area
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding, vertical: 12),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(6),
            isConcave: true,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    style: const TextStyle(color: NeumorphicTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: NeumorphicTheme.textTertiary.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                _isPosting
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: NeumorphicTheme.primaryAccent),
                        onPressed: _postComment,
                      ),
              ],
            ),
          ),
        ),

        // Comments List
        _isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Comments unavailable ($_error)',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchComments,
                            style: ElevatedButton.styleFrom(backgroundColor: NeumorphicTheme.primaryAccent),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _comments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No comments yet. Be the first to say something!',
                        style: const TextStyle(color: NeumorphicTheme.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final shouldAnimate = _animatedIds.remove(comment.id);
                      final item = _buildCommentItem(comment);
                      if (!shouldAnimate) return item;
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(comment.id),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        builder: (context, t, child) => Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.85 + (0.15 * t.clamp(0.0, 1.0)),
                            alignment: Alignment.topCenter,
                            child: child,
                          ),
                        ),
                        child: item,
                      );
                    },
                  ),
      ],
    );
  }

  static const List<int> _reactionTiers = [5, 20, 50];

  Widget _buildCommentItem(CommentModel comment) {
    final isHot = _reactionTiers.any((t) => comment.likes >= t);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(left: widget.horizontalPadding, right: widget.horizontalPadding, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: isHot
          ? NeumorphicTheme.flatNeumorphicDecoration().copyWith(
              border: Border.all(color: NeumorphicTheme.primaryAccent.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: NeumorphicTheme.primaryAccent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            )
          : NeumorphicTheme.flatNeumorphicDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.userAvatar.isNotEmpty
                    ? NetworkImage(comment.userAvatar)
                    : null,
                child: comment.userAvatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: NeumorphicTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(comment.createdAt),
                      style: const TextStyle(
                        color: NeumorphicTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _toggleLike(comment),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: comment.isLiked ? Colors.red : NeumorphicTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: const TextStyle(
                          color: NeumorphicTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
            style: const TextStyle(
              color: NeumorphicTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
