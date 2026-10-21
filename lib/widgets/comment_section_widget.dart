import 'package:cached_network_image/cached_network_image.dart';
import 'package:chanolite/l10n/generated/app_localizations.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/comment_model.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/api/comment_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ArticleCommentsSection extends StatefulWidget {
  final String slug;
  final String? articleAuthor;
  final CommentService? commentService;

  const ArticleCommentsSection({
    super.key,
    required this.slug,
    this.articleAuthor,
    this.commentService,
  });

  @override
  State<ArticleCommentsSection> createState() => _ArticleCommentsSectionState();
}

class _ArticleCommentsSectionState extends State<ArticleCommentsSection> {
  late final CommentService _commentService;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Comment> _comments = [];
  int _commentsCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;
  int? _deletingCommentId;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _commentService = widget.commentService ?? CommentService();
    _fetchComments();
  }

  @override
  void didUpdateWidget(covariant ArticleCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _fetchComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    if (widget.slug.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _commentService.getComments(widget.slug);
      if (mounted) {
        setState(() {
          _comments = response.comments;
          _commentsCount = response.commentsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
    });

    try {
      final parentId = _replyingTo?.id;
      final created = await _commentService.createComment(
        widget.slug,
        body: text,
        parentId: parentId,
      );

      if (mounted) {
        setState(() {
          if (parentId != null) {
            _comments = _attachReplyToTree(_comments, parentId, created);
          } else {
            _comments = [created, ..._comments];
          }
          _commentsCount += 1;
          _replyingTo = null;
          _commentController.clear();
          _isSubmitting = false;
        });
        _focusNode.unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.commentPosted ?? 'Comment posted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.failedToPostComment ?? "Failed to post comment"}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteComment ?? 'Delete comment'),
        content: Text(l10n?.deleteCommentConfirm ?? 'Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteComment(comment);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _deletingCommentId = comment.id;
    });

    try {
      await _commentService.deleteComment(widget.slug, comment.id);
      if (mounted) {
        setState(() {
          _comments = _removeCommentFromTree(_comments, comment.id);
          _commentsCount = (_commentsCount - 1).clamp(0, 999999);
          _deletingCommentId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.commentDeleted ?? 'Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deletingCommentId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.failedToDeleteComment ?? "Failed to delete comment"}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  List<Comment> _attachReplyToTree(List<Comment> list, int parentId, Comment newReply) {
    return list.map((c) {
      if (c.id == parentId) {
        return c.copyWith(replies: [...c.replies, newReply]);
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _attachReplyToTree(c.replies, parentId, newReply));
      }
      return c;
    }).toList();
  }

  List<Comment> _removeCommentFromTree(List<Comment> list, int commentId) {
    final result = <Comment>[];
    for (final c in list) {
      if (c.id == commentId) {
        continue;
      }
      if (c.replies.isNotEmpty) {
        result.add(c.copyWith(replies: _removeCommentFromTree(c.replies, commentId)));
      } else {
        result.add(c);
      }
    }
    return result;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat.yMMMd().format(dt);
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final commentsTitle = l10n?.comments ?? 'Comments';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              commentsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_commentsCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _fetchComments,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputArea(context),
        const SizedBox(height: 20),
        _buildContent(context),
      ],
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authManager = Provider.of<AuthManager>(context);
    final isAuthenticated = authManager.isAuthenticated;
    final currentUser = authManager.activeAccount;

    if (!isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.loginToComment ?? 'Log in to join the conversation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(l10n?.login ?? 'Log In'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingTo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.replyingTo(_replyingTo!.author.username) ??
                        'Replying to @${_replyingTo!.author.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: currentUser?.image != null && currentUser!.image!.isNotEmpty
                    ? CachedNetworkImageProvider(currentUser.image!)
                    : null,
                child: currentUser?.image == null || currentUser!.image!.isEmpty
                    ? Text(
                        currentUser?.username.isNotEmpty == true
                            ? currentUser!.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _replyingTo != null
                        ? (l10n?.replyingTo(_replyingTo!.author.username) ??
                            'Reply to @${_replyingTo!.author.username}...')
                        : (l10n?.writeComment ?? 'Write a comment...'),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                iconSize: 20,
                onPressed: _isSubmitting ? null : _submitComment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${l10n?.failedToLoadComments ?? "Failed to load comments"}: $_errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchComments,
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 44, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                l10n?.noComments ?? 'No comments yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.beTheFirstToComment ?? 'Be the first to share your thoughts!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildCommentCard(context, _comments[index]);
      },
    );
  }

  Widget _buildCommentCard(BuildContext context, Comment comment, {int depth = 0}) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authManager = Provider.of<AuthManager>(context, listen: false);
    final currentUsername = authManager.activeAccount?.username;
    final isAuthor = comment.author.username.toLowerCase() == widget.articleAuthor?.toLowerCase();
    final isOwnComment = currentUsername != null &&
        comment.author.username.toLowerCase() == currentUsername.toLowerCase();
    final isAdmin = authManager.activeAccount?.roles.contains('admin') ?? false;
    final canDelete = isOwnComment || isAdmin;
    final isDeleting = _deletingCommentId == comment.id;

    return Container(
      margin: EdgeInsets.only(left: depth > 0 ? (depth * 20.0).clamp(0.0, 60.0) : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: depth == 0
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: depth == 0
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: depth == 0 ? 16 : 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: comment.author.image != null && comment.author.image!.isNotEmpty
                    ? CachedNetworkImageProvider(comment.author.image!)
                    : null,
                child: comment.author.image == null || comment.author.image!.isEmpty
                    ? Text(
                        comment.author.username.isNotEmpty
                            ? comment.author.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: depth == 0 ? 12 : 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Author',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _formatTime(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              comment.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.reply, size: 16),
                label: Text(l10n?.reply ?? 'Reply', style: const TextStyle(fontSize: 12)),
                onPressed: () => _startReply(comment),
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                if (isDeleting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: theme.colorScheme.error,
                    tooltip: l10n?.delete ?? 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteComment(comment),
                  ),
              ],
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...comment.replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildCommentCard(context, reply, depth: depth + 1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
