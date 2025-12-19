import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class SelectMediaScreen extends StatefulWidget {
  const SelectMediaScreen({super.key});

  @override
  State<SelectMediaScreen> createState() => _SelectMediaScreenState();
}

class _SelectMediaScreenState extends State<SelectMediaScreen> {
  // Mock data for "Recent" photos
  final List<String> _recentPhotos = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBgC13PhyNtHq5SG-HmFzgZgoyt9FHuj1eEApjDavZCLJTcrkLZwXKO__dA1gP-9lmvDsFOKOYXParkdOaUu00TaKg6_2_3_heXi4iPGGwLeuMmjGI6mXndy-9W4efb7NEEy6Rgzvq4wNfN_HkgYROi8M7oe10_CcO1HZij7oaTsykvwxQxre-j_2_SUx0IjVecZXazh2wK6uchJttU4QzuYvpT-DR_18t98BAYqbmISrv8tdP8kzuDy1U8W1xHkfCVKAXCMJbx3JI',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDbHgtR02DGZa2glOKf7FTScl7tR3WPjXcYt12Vmu8KUiN7ai6IVX5Ut4M3yFcSacNZMhJyJarwcq_8BXU-T50o45PI0V8qbK_wKiPlTucHcdRH8t5g0EGewToos12T9oJD8FGn5wsAkzSEDtfVh4FCIqaLJq4k4FBTpNnH_KOpLtTENeBAqTPOPW3c_yqpsbZ_ATLNXdOVcNN7UwUi6Bit6o9rw90lqP2zkrbG6JAZ7o_07pAWOQ1A6kR1OIXS_CG3fo7IJ4QVCRU',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDsTOvZB2qeKFz8cwa5PVsXpHZ4pJT5LeI3sRvziimLBOeIJ-3FCzHrF_X97bR1yaKiZRDQ4qRDWIYpt3rvymV22rXU3WZEgryFp3GbMJtferXGkjqk3PEV6TxmZaEWLtcHh9HbNfB_HJ3Nbb23KnAj7OJdsZBnXZM2HGmeIlzWyGfGFMNlOBoogBCQOmTaQmLfc-tgdKxw2_8Vi53O-lJ3SqCC0edS5LvpT7PsK9kaR3GZlc5w0b9E-HCfKs60_h4z1daWgpW-YMk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBXbhfUVCWf4sPbSrSHzvlpUVMgrhJvYpOW2nDCZEaIst1O_GBiASrGLEOc1GgLhynoCmsjvnLwj8GpZwdivgaUBr5TWuLwXiTLEFzOpLgxr8tyF0Xoy_LZTwRUHRejxmu1r7SbhYQUQkqHjUdIK5oDvhLs9DaqV1QbuBqCCR2r-cD43WhyYq_TIljhEkSPuSqBLUJbJhm1tJlDS5tBtXzgh2TJzHoNpAj5Udg_h-i0K51myXv_JkSPqvz5CZMnHphaHqQj8uBr_Qk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCJ3Lh4PtuXHLVGB5ZArzsL5diotKoQUAVuQGLtc0Z6KeQv4kofYCMp4fNV6s1HGfhqw2tAtVdUeQD3ISo7J3HRX6L9mfjgmzTulGMS2LDCncS7hNWWsT7ruwK2Or0BculEGF2bmOeKzkzEhinB1MO3gqwCeIa8mfuKKfhj4Z6B9Fo-o8hzIt5XBDavWzUzVR2Zyj31XoUfVo1SAxpBXfJA_B9khK-qx0ipz7R7XjzHBK0nmdD_JTWF5Z04zx3YGqnrxUYyYoSG_VU',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCfCl36Ua1cvgLHVuwUq_E4humgTyfwc0Ac1pGB9hwY7aarRmk50-JVBUuVOOWLIxcVCZYyAXAamxeFWPPlujhGAHCEcO49euJlegruAo219exX_OnNpkyBycbBjtIWfhjEHSbATrtqAv1Wcfn1GFfDu-0sdRh_8lhZfiE-PcHjzED7WTWA-VphN32_LChtM6NijaGQMFdYqZ3FnpSjkSHUNsOE2LXHR8Cil6llYWwd0yhl1oPRMk5gWhOvAkboyFZ6Nh3Bu0w9eZM',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC4-Bkw-7C_SEOT9xjurzRQIZ4BwKCWf5V-kj14d9BZYedAhOx4GeAnNPcScrBEQ5NYKzqmCuXvQdQFW_oVjzbKSe6kTOVihP_O6yttTpgKCb-RdmmMMZ9liu1vVwKSkn0_XS2DgkaN5SvYUcRErN18IMfEO7d05a9ujSIeXPR2KXssC6bJ3ZjeAJS6KMU9lSVR4j95dmYeHjNr7wGcGT5X5IJ2QNFlkD5h_bEJ2NyZnMOPz75AuyBinT39E4iuJnPvKBsoRfrkM94',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDmYRMT6kbhO4UmpW6EfzQokReW46HZsFGhGlr7ZF2kPoICdt2BTls2QFZag_7c09GKRgETCxWKfO7qNwfKEx3JMBzFCxLHzm53C_TyuiIt2RAxJK_tIB5NeZ-YPNpl-UQe-rUtb-6hUan2HXB51D-595UtukNomryD_sqPaLhGPcTBBSI911E1gZODF3l7I9BInFfdULJ8ZGZVZHkpjbzAe_CAjGygPmFPrPr_4I_CMG2YwEBFqfyRnApg0Zh8YlqNYsz3zYdIAbU',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3WiOk6YAhJ8uHlT6oFXD0zZzm5bxMlmvW0grg6GMAfA_23I3AMT9dQ5ThRe9jNdDuehvd3Vqf2y5OMJZzCdYBXlSOu73o17MJMfqe3xmDqzGTSSpmahCBXoBtaFt-fxLCGO85njflx406xjK6IdsUb65JFOHoJoxHObLRhUqa74obYgAlGVauvkhY9x89GEZjXCZA-s5X461FGuMqWuSPzZuLYY8rG5FuZp-w_1_KCsmr1G2tJpD6EEzHqSKP4msAGq3ngwDK4E',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTa7LhmTil547R4YsLMFQhhHhImYo7oI_1xZ5wn7wnkExcKmi4hIDRW6rB5OpwzSwUQ4I0E1is-LxCgPsy9XcBENs9vuqWe86N4QXL_kOHLjDsPzpZyVU_PzOKh__taexPyLht868JCAB7QKHJn03X8zBAA24A_amLmsZdDXdu6iFqMNOaF9YK1uPbzTYR8J9XJEEX5NtJGvbj_doPRW_dy3a-H5WmloSMm5HUlZtGEzOJYP9vqu7YT4Y2IpLfxTn8y31HcnEnkz4',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAlM-0QggbiHCDXwVjeeSoB-9BWA47mRZ3B5hVkJicus9fiAa1SmfAE5y5nIkgi5shD5xxIgMPp3c1vTUgUp7Ph_p3T0_Uon47n3kviD3i799YYI7gCGCrc9f4RBkK_8N4RDs5p3Rc-FQPoe7Y-evM0e-muJZoMUboQvKDxVTh3zshKasOL41fFewVhoPvrUWBgYIkehEp1lwsggLxopPZM2LelaZd66WkeAOcWXFjWYIbsfglm01Lm3Vt-8s6vbEJ8oLnEya0cxhk',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAUnmQtci98ygdcxnBMmOWWhXqc7KJJm4wxvvPJRe2XKkSBbSwQOtmCOc6jxFEheHB0J74Rh9O7-A1CONb6wFR3cpeQpgsWSwuErboO-oaATiGZJeJdbwF-DX3saGbnwkpgRCGfsePF3Yoegz9dxx9vdrI3Ea51FPKbXlRjCTY_oUC2FJ0GHi81djrRDcRNQLDU6S_Yrek-3-rVsZsfgrSzHJhuW1NKwuTE5hv5KgU_pF4NrU_zBmUG_1qKviOTlKgiSjbMpsuTnyg',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creationProvider = Provider.of<CreationProvider>(context);
    final selectedMedia = creationProvider.selectedMedia;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      Text(
                        'Select Media',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(), // Or clear selection
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Platform Tabs (Mock)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildTab('Instagram', true),
                    _buildTab('Facebook', false),
                    _buildTab('Twitter', false),
                    _buildTab('LinkedIn', false),
                  ],
                ),
              ),

              // Grid Content
              Expanded(
                child: Column(
                  children: [
                    // Recents Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Recents',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const Icon(Icons.expand_more, color: Colors.grey),
                            ],
                          ),
                          Row(
                            children: [
                              _buildCircleButton(Icons.camera_alt, isDark),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.copy_all,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: _recentPhotos.length,
                        itemBuilder: (context, index) {
                          final url = _recentPhotos[index];
                          final isSelected = selectedMedia.contains(url);
                          final selectionIndex = selectedMedia.indexOf(url) + 1;

                          return GestureDetector(
                            onTap: () =>
                                creationProvider.toggleMediaSelection(url),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  color: isSelected
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : null,
                                  colorBlendMode: isSelected
                                      ? BlendMode.darken
                                      : null,
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: isSelected
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$selectionIndex',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight)
                        .withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: selectedMedia.isNotEmpty
                    ? () {
                        // Check mode to decide destination
                        final mode = creationProvider.mode;
                        if (mode == 'manual') {
                          context.push('/create/edit-media');
                        } else {
                          // Auto or Review mode -> AI Generation
                          context.push('/create/ai-generation');
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  disabledForegroundColor: isDark
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: selectedMedia.isNotEmpty ? 4 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selectedMedia.isNotEmpty
                          ? 'Next (${selectedMedia.length} selected)'
                          : 'Select media to continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedMedia.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // AI Assist Button
          Positioned(
            bottom: 100,
            right: 16,
            child:
                FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: isDark
                      ? AppColors.surfaceDark
                      : Colors.white,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.auto_awesome),
                ).animate().scale(
                  delay: 500.ms,
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.grey[300] : Colors.grey[600],
      ),
    );
  }
}
