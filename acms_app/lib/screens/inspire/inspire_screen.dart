import 'package:flutter/material.dart';
import 'package:acms_app/theme/app_theme.dart';

class InspireScreen extends StatefulWidget {
  const InspireScreen({super.key});

  @override
  State<InspireScreen> createState() => _InspireScreenState();
}

class _InspireScreenState extends State<InspireScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'For You',
    'Following',
    'Trending',
    'Design',
    'AI Art',
  ];

  // Mock posts data
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'Sarah Chen',
      'handle': '@sarahdesign',
      'time': '2h',
      'isVerified': true,
      'avatarUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDwOJzcxSNHnglxDT2qHzkcWOc6PbRqYD4qt_zO7gz3rlHN6Z0dNLWSJhUZgX9lSVUsH1m83JYCLzx88eeKVqZ4kAV_xftyN758y9Z_NAAbebQ56WSIdiuxzE8d-24bM3W3yZfcZyKouWJuuzSuY7zOl4q3-wHT7aP5DHwXsVvu48yhVkgRH2PUljqzo1FYJn1L2rIWb8urJDTzgy2hmsqpNF0ZrDdm3zy7ERNw-nDOnhuz6nFJX1tZM1W0XKA5mNQtJM0syjRhkJU',
      'content':
          'Just generated these amazing abstract patterns for the new campaign using the AI tool. The color blending is incredible! 🎨✨ #AIart #DesignInspo',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCQe9xTdd5QEKj1sYcln5gNaJ0Jt8svJWPtqbtRgrP5pi0MJ0vh4fMis3xubV37vfALXete49F_xximC-1yWM2AhEMPQi112UXfv_Zjp7O80zo-24cFtZRNjPtNJ4l0RKlaR6ENx7nsIFRcfnPsGVUEjOBzjuTnAU2bh2wqEK2xIx3myw87-MLRj3pTOjVYkbLmeGtvdHAVx1U_EBIEkuqaB2oj9TDzcF25v6xtYIM5eqLGK-1py3a74sNREYMjsl_be6U_2H7b6ro',
      'likes': '2.4k',
      'comments': '84',
      'isLiked': false,
      'isBookmarked': false,
    },
    {
      'username': 'Marcus Flow',
      'handle': '@marcus_dev',
      'time': '5h',
      'isVerified': false,
      'avatarUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAVuKUxQZoi0KnGUCtydYnLSTFZrWnDUQW3nQcYQ8HKgGPwMp0d7o9dx6yETZiVFg16dbGn7IOhtsbhiDKP2s07xVZdNmZ-POmDpel6g6KP68muUIVZhBXIU8JG4wLkj9u_U8ICnHZVY7Kcty4plhQprpk6Ma9d_kGTJilAPZ463zG9ELOe2TzyMijvy2ND2d81WVdvyt9488-uD6ftQxqSvdAsTSDo3vERrGHqshuu5ITsmlaEv8T8xepr4Nnv2ZNhcyFNvx6xxd0',
      'content':
          'Workflow automation saved me 10 hours this week. Here is a snapshot of the new dashboard layout I\'m working on.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCQe9xTdd5QEKj1sYcln5gNaJ0Jt8svJWPtqbtRgrP5pi0MJ0vh4fMis3xubV37vfALXete49F_xximC-1yWM2AhEMPQi112UXfv_Zjp7O80zo-24cFtZRNjPtNJ4l0RKlaR6ENx7nsIFRcfnPsGVUEjOBzjuTnAU2bh2wqEK2xIx3myw87-MLRj3pTOjVYkbLmeGtvdHAVx1U_EBIEkuqaB2oj9TDzcF25v6xtYIM5eqLGK-1py3a74sNREYMjsl_be6U_2H7b6ro',
      'likes': '10.2k',
      'comments': '342',
      'isLiked': true,
      'isBookmarked': false,
      'isVideo': true,
    },
    {
      'username': 'Elena Light',
      'handle': '@elena_creates',
      'time': '8h',
      'isVerified': false,
      'avatarUrl': null,
      'avatarInitials': 'EL',
      'content':
          'Testing the new voice-to-post feature. It\'s surprisingly accurate! 🎤📝',
      'quote': {
        'text': '"Creativity is intelligence having fun."',
        'author': '— Albert Einstein',
      },
      'likes': '856',
      'comments': '42',
      'isLiked': false,
      'isBookmarked': false,
    },
    {
      'username': 'Alex Ryder',
      'handle': '@alexryder_art',
      'time': '12h',
      'isVerified': true,
      'avatarUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDwOJzcxSNHnglxDT2qHzkcWOc6PbRqYD4qt_zO7gz3rlHN6Z0dNLWSJhUZgX9lSVUsH1m83JYCLzx88eeKVqZ4kAV_xftyN758y9Z_NAAbebQ56WSIdiuxzE8d-24bM3W3yZfcZyKouWJuuzSuY7zOl4q3-wHT7aP5DHwXsVvu48yhVkgRH2PUljqzo1FYJn1L2rIWb8urJDTzgy2hmsqpNF0ZrDdm3zy7ERNw-nDOnhuz6nFJX1tZM1W0XKA5mNQtJM0syjRhkJU',
      'content':
          'Finally finished my portfolio redesign using Vextra\'s AI tools! The generated color schemes are absolutely stunning 💜 #Portfolio #AIDesign',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAVuKUxQZoi0KnGUCtydYnLSTFZrWnDUQW3nQcYQ8HKgGPwMp0d7o9dx6yETZiVFg16dbGn7IOhtsbhiDKP2s07xVZdNmZ-POmDpel6g6KP68muUIVZhBXIU8JG4wLkj9u_U8ICnHZVY7Kcty4plhQprpk6Ma9d_kGTJilAPZ463zG9ELOe2TzyMijvy2ND2d81WVdvyt9488-uD6ftQxqSvdAsTSDo3vERrGHqshuu5ITsmlaEv8T8xepr4Nnv2ZNhcyFNvx6xxd0',
      'likes': '5.1k',
      'comments': '203',
      'isLiked': false,
      'isBookmarked': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Sticky Header
          _buildHeader(isDark),

          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: _posts.length + 1, // +1 for loading indicator
              itemBuilder: (context, index) {
                if (index == _posts.length) {
                  return _buildLoadingIndicator();
                }
                return _buildPostCard(_posts[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.surfaceLight)
            .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inspire',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderIcon(Icons.search, isDark),
                    const SizedBox(width: 4),
                    Stack(
                      children: [
                        _buildHeaderIcon(Icons.notifications_outlined, isDark),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.surfaceLight,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.grey[900])
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.grey[900] : Colors.white)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Icon(
            icon,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(post),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post['username'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          if (post['isVerified'] == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${post['handle']} • ${post['time']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // More Button or Follow Button
                if (post['isVerified'] == true)
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                  )
                else
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Follow',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildContentText(post['content'], isDark),
          ),
          const SizedBox(height: 12),

          // Image or Quote
          if (post['imageUrl'] != null) _buildMediaContent(post, isDark),
          if (post['quote'] != null) _buildQuoteCard(post['quote'], isDark),

          // Action Buttons
          _buildActionButtons(post, isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> post) {
    if (post['avatarUrl'] != null) {
      return Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: DecorationImage(
                image: NetworkImage(post['avatarUrl']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (post['isVerified'] == true)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 8),
              ),
            ),
        ],
      );
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        ),
        child: Center(
          child: Text(
            post['avatarInitials'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContentText(String content, bool isDark) {
    // Simple hashtag highlighting
    final words = content.split(' ');
    return Text.rich(
      TextSpan(
        children: words.map((word) {
          if (word.startsWith('#')) {
            return TextSpan(
              text: '$word ',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            );
          }
          return TextSpan(
            text: '$word ',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[800],
              fontSize: 14,
              height: 1.4,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMediaContent(Map<String, dynamic> post, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: post['isVideo'] == true ? 1 : 4 / 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              image: DecorationImage(
                image: NetworkImage(post['imageUrl']),
                fit: BoxFit.cover,
                colorFilter: post['isVideo'] == true
                    ? ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.3),
                        BlendMode.darken,
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (post['isVideo'] == true)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.black87,
              size: 36,
            ),
          ),
      ],
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [const Color(0xFFFEF2F2), const Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          Text(
            quote['text'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              quote['author'],
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildActionButton(
                icon: post['isLiked'] == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: post['likes'],
                color: post['isLiked'] == true ? AppColors.primary : null,
                isDark: isDark,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: post['comments'],
                isDark: isDark,
              ),
              _buildActionButton(icon: Icons.send_outlined, isDark: isDark),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              post['isBookmarked'] == true
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: post['isBookmarked'] == true
                  ? (isDark ? Colors.white : Colors.grey[900])
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    Color? color,
    required bool isDark,
  }) {
    final defaultColor = isDark ? Colors.grey[500] : Colors.grey[600];
    return TextButton.icon(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, color: color ?? defaultColor, size: 22),
      label: label != null
          ? Text(
              label,
              style: TextStyle(
                color: color ?? defaultColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }
}
