// // lib/pages/home_page.dart

// import 'package:buzzify/common/app_colors.dart';
// import 'package:buzzify/pages/albums.dart';
// import 'package:buzzify/pages/library.dart';
// import 'package:buzzify/pages/play_song.dart'; // <-- Sử dụng lại trang gốc
// import 'package:buzzify/mock_data.dart';
// import 'package:buzzify/pages/search.dart';
// import 'package:buzzify/supabase/auth_controller.dart';
// import 'package:buzzify/supabase/user_service.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int selectedIndex = 0;
//   User? currentUser;

//   late List<Map<String, dynamic>> songsState;
//   final List<Map<String, dynamic>> albumsState = mockAlbums;

//   @override
//   void initState() {
//     super.initState();
//     currentUser = UserService.getCurrentUser();
//     songsState = List.from(mockSongs);
//   }

//   // ===== HÀM ĐỂ HIỂN THỊ DIALOG TOÀN MÀN HÌNH =====
//   void _showPlayerAsModal(
//       {required List<Map<String, dynamic>> playlist,
//       required int initialIndex}) {
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false, // Ngăn việc tắt dialog khi chạm bên ngoài
//       barrierLabel: 'Player',
//       // Thời gian hiệu ứng
//       transitionDuration: const Duration(milliseconds: 400),
//       pageBuilder: (context, animation, secondaryAnimation) {
//         // Trả về chính widget PlaySongPage của bạn
//         return PlaySongPage(
//           playlist: playlist,
//           initialIndex: initialIndex,
//         );
//       },
//       // Hiệu ứng trượt từ dưới lên mượt mà
//       transitionBuilder: (context, animation, secondaryAnimation, child) {
//         const begin = Offset(0.0, 1.0);
//         const end = Offset.zero;
//         final tween = Tween(begin: begin, end: end)
//             .chain(CurveTween(curve: Curves.easeInOutCubic));
//         return SlideTransition(
//           position: animation.drive(tween),
//           child: child,
//         );
//       },
//     );
//   }
  
//   void _showRightSideMenu(BuildContext context) {
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: 'Menu',
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (context, animation, secondaryAnimation) {
//         return Align(
//           alignment: Alignment.centerRight,
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               width: MediaQuery.of(context).size.width * 0.8,
//               height: MediaQuery.of(context).size.height,
//               padding: const EdgeInsets.all(24),
//               decoration: const BoxDecoration(
//                 color: AppColors.darkGrey,
//                 borderRadius: BorderRadius.horizontal(
//                   left: Radius.circular(10),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 30,
//                         backgroundImage:
//                             currentUser!.userMetadata?['avatar_url'] != null
//                                 ? NetworkImage(
//                                     currentUser!.userMetadata!['avatar_url'],
//                                   )
//                                 : null,
//                         child: currentUser!.userMetadata?['avatar_url'] == null
//                             ? const Icon(Icons.person, size: 50)
//                             : null,
//                       ),
//                       const SizedBox(width: 15),
//                       Expanded(
//                         child: Text(
//                           currentUser?.userMetadata?['full_name'] ??
//                               'Không có tên',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.primaryText,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 32, color: AppColors.grey),
//                   ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     leading: const Icon(Icons.person, color: AppColors.primaryText),
//                     title: const Text('Xem hồ sơ', style: TextStyle(color: AppColors.primaryText)),
//                     onTap: () {},
//                   ),
//                   ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     leading: const Icon(Icons.settings, color: AppColors.primaryText),
//                     title: const Text('Cài đặt', style: TextStyle(color: AppColors.primaryText)),
//                     onTap: () {},
//                   ),
//                   ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     leading: const Icon(Icons.logout, color: AppColors.primaryText),
//                     title: const Text('Đăng xuất', style: TextStyle(color: AppColors.primaryText)),
//                     onTap: () {
//                       Navigator.pop(context);
//                       AuthController.signOut(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (context, animation, secondaryAnimation, child) {
//         final tween = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
//         return SlideTransition(position: animation.drive(tween), child: child);
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (currentUser == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     final List<Widget> pages = [
//       buildHomeContent(),
//       const SearchPage(),
//       LibraryPage(songs: songsState, albums: albumsState),
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Text(
//           selectedIndex == 0
//               ? 'Trang chủ'
//               : selectedIndex == 1
//                   ? 'Tìm kiếm'
//                   : 'Thư viện',
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
//         ),
//         backgroundColor: Colors.transparent,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 IconButton(
//                   onPressed: () {},
//                   icon: const Icon(Icons.notifications_none, color: AppColors.primaryText),
//                 ),
//                 const SizedBox(width: 8),
//                 GestureDetector(
//                   onTap: () => _showRightSideMenu(context),
//                   child: CircleAvatar(
//                     backgroundImage:
//                         currentUser!.userMetadata?['avatar_url'] != null
//                             ? NetworkImage(currentUser!.userMetadata!['avatar_url'])
//                             : null,
//                     child: currentUser!.userMetadata?['avatar_url'] == null
//                         ? const Icon(Icons.person)
//                         : null,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: IndexedStack(index: selectedIndex, children: pages),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: selectedIndex,
//         onTap: (index) => setState(() => selectedIndex = index),
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: AppColors.grey,
//         backgroundColor: Colors.transparent,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
//           BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_music),
//             label: 'Thư viện',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildHomeContent() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Albums
//           const Padding(
//             padding: EdgeInsets.only(left: 20.0, top: 16),
//             child: Text(
//               'Albums',
//               style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.primaryText),
//             ),
//           ),
//           SizedBox(
//             height: 230,
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               scrollDirection: Axis.horizontal,
//               itemCount: albumsState.length,
//               itemBuilder: (context, index) {
//                 final album = albumsState[index];
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             AlbumPage(album: album, allSongs: songsState),
//                       ),
//                     );
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.asset(
//                             album['cover'],
//                             width: 140,
//                             height: 140,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         SizedBox(width: 140, child: Text(album['title'], overflow: TextOverflow.ellipsis)),
//                         SizedBox(width: 140, child: Text(album['artist'], style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Songs
//           const Padding(
//             padding: EdgeInsets.only(left: 20.0, top: 10),
//             child: Text(
//               'Bài hát',
//               style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.primaryText),
//             ),
//           ),
//           ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 12.0),
//             itemCount: songsState.length,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               final song = songsState[index];
//               final bool isLiked = song['isLiked'] as bool? ?? false;
//               return ListTile(
//                 leading: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.asset(
//                     song['cover'] ?? '',
//                     width: 50,
//                     height: 50,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 title: Text(song['title'] ?? 'Không có tiêu đề'),
//                 subtitle: Text(song['artist'] ?? 'Không rõ ca sĩ'),
//                 trailing: IconButton(
//                   icon: Icon(
//                     isLiked ? Icons.favorite : Icons.favorite_border,
//                     color: isLiked ? Colors.red : Colors.grey,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       songsState[index]['isLiked'] = !isLiked;
//                     });
//                   },
//                 ),
//                 onTap: () {
//                   // ===== GỌI DIALOG TẠI ĐÂY =====
//                   _showPlayerAsModal(
//                     playlist: songsState,
//                     initialIndex: index,
//                   );
//                   // ===============================
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }