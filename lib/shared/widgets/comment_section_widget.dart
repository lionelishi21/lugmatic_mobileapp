import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/comment_model.dart';
import '../../data/services/comment_service.dart';
import '../../core/theme/neumorphic_theme.dart';

class CommentSectionWidget extends StatefulWidget {
  final String contentType;
  final String contentId;

  const CommentSectionWidget({
    Key? key,
    required this.contentType,
    required this.contentId,
  }) : super(key: key);

  @override
  _CommentSectionWidgetState createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isPosting = false;
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
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
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isPosting = true);
    try {
      final commentService = context.read<CommentService>();
      final newComment = await commentService.postComment(
        widget.contentType,
        widget.contentId,
        _commentController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
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
          padding: const EdgeInsets.all(20),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(8),
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
                      hintStyle: TextStyle(color: NeumorphicTheme.textTertiary.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                _isPosting
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
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
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ))
            : _comments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'No comments yet. Be the first to say something!',
                        style: TextStyle(color: NeumorphicTheme.textTertiary),
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
                      return _buildCommentItem(comment);
                    },
                  ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicTheme.flatNeumorphicDecoration(),
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
              Row(
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
