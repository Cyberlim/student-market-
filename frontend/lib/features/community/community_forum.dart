import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class CommunityForum extends StatefulWidget {
  const CommunityForum({Key? key}) : super(key: key);

  @override
  State<CommunityForum> createState() => _CommunityForumState();
}

class _CommunityForumState extends State<CommunityForum> {
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Alok T.',
      'college': 'IIT Bombay',
      'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120',
      'subject': 'Computer Science',
      'question': 'How does process synchronization work in Chapter 3 of Operating Systems? Any easy analogies?',
      'likes': 14,
      'replies': 3,
      'isLiked': false,
    },
    {
      'author': 'Shreya P.',
      'college': 'BITS Pilani',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=120',
      'subject': 'Mathematics',
      'question': 'Can anyone share a cheatsheet for Laplace Transforms formulas? Exam is tomorrow!',
      'likes': 22,
      'replies': 8,
      'isLiked': true,
    },
  ];

  final TextEditingController _doubtController = TextEditingController();

  void _postDoubt() {
    if (_doubtController.text.isNotEmpty) {
      setState(() {
        _posts.insert(0, {
          'author': 'Alok T. (You)',
          'college': 'IIT Bombay',
          'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=120',
          'subject': 'General doubt',
          'question': _doubtController.text,
          'likes': 0,
          'replies': 0,
          'isLiked': false,
        });
        _doubtController.clear();
      });
    }
  }

  @override
  void dispose() {
    _doubtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Discussion',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Ask doubt container
              GlassCard(
                borderRadius: 16,
                opacity: 0.05,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _doubtController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a doubt or share updates...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                      onPressed: _postDoubt,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 24),

              // Forum list
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return GlassCard(
                      borderRadius: 20,
                      opacity: 0.04,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(post['avatar']),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${post['college']} • ${post['subject']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            post['question'],
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    post['isLiked'] = !post['isLiked'];
                                    post['likes'] += post['isLiked'] ? 1 : -1;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      post['isLiked'] ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: post['isLiked'] ? AppColors.error : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${post['likes']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 18),
                                  const SizedBox(width: 4),
                                  Text('${post['replies']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.share_outlined, color: Colors.grey, size: 18),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 80), // bottom bar spacing
            ],
          ),
        ),
      ),
    );
  }
}
