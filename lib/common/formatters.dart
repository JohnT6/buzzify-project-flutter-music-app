String buildArtistString(Map<String, dynamic> song) {
  // Lấy tên nghệ sĩ chính một cách an toàn
  final String mainArtist = song['artists']?['name'] ?? 'Không rõ nghệ sĩ';

  // Lấy chuỗi các nghệ sĩ hợp tác
  final String? featuredArtists = song['featured_artists'];

  // Nếu có nghệ sĩ hợp tác, ghép chuỗi theo định dạng "Nghệ sĩ chính (feat. Nghệ sĩ hợp tác)"
  if (featuredArtists != null && featuredArtists.isNotEmpty) {
    return '$mainArtist , $featuredArtists';
  }

  // Nếu không, chỉ trả về tên nghệ sĩ chính
  return mainArtist;
}