// import 'package:flutter/material.dart';
// import 'package:buzzify/pages/play_song.dart';

// class AlbumPage extends StatelessWidget {
//   final Map<String, dynamic> album;
//   final List<Map<String, dynamic>> allSongs;

//   const AlbumPage({required this.album, required this.allSongs, super.key});

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = allSongs
//         .where((song) => song['artist'] == album['artist'])
//         .toList();

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: Text(
//           'Album',
//           style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon: Icon(Icons.arrow_back_ios),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Image.asset(
//               album['cover'],
//               width: 200,
//               height: 200,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               album['title'],
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             Text('Artist: ${album['artist']}'),
//             Text('Released: ${album['releaseDate']}'),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.play_arrow),
//               label: const Text('Phát tất cả'),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => PlaySongPage(
//                       playlist: filteredSongs,
//                       albumCover: album['cover'],
//                       albumTitle: album['title'],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredSongs.length,
//                 itemBuilder: (context, index) {
//                   final song = filteredSongs[index];
//                   return ListTile(
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.asset(
//                         song['cover']!,
//                         width: 50,
//                         height: 50,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     title: Text(song['title']!),
//                     subtitle: Text(song['artist']!),
//                     trailing: const Icon(Icons.more_vert),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => PlaySongPage(
//                             playlist: [song],
//                             albumCover: album['cover'],
//                             albumTitle: album['title'],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
