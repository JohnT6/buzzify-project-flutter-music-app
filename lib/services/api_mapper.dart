// lib/services/api_mapper.dart

Map<String, dynamic> mapApiSong(Map<String, dynamic> apiSong) {
  return {
    'id': apiSong['id'],
    'title': apiSong['tieu_de'] ?? apiSong['title'], // Hỗ trợ cả 2
    'url': apiSong['url'],
    'cover_url': apiSong['anh_bia'], 
    'duration_seconds': apiSong['thoi_luong_giay'],
    'luot_nghe': apiSong['luot_nghe'],
    'featured_artists': apiSong['nghe_si_hop_tac'],
    'track_number': apiSong['track_number'],
    'id_album': apiSong['id_album'],
    'artist_id': apiSong['artist_id'],
    'artists': {'name': apiSong['ten_nghe_si'] ?? apiSong['subtitle'] ?? 'Không rõ'},
    'album_name': apiSong['ten_album'], 
    'subtitle_text': 'Bài hát • ${apiSong['ten_nghe_si'] ?? apiSong['subtitle'] ?? 'Không rõ'}',
    '__type': 'song', 
  };
}

Map<String, dynamic> mapApiAlbum(Map<String, dynamic> apiAlbum) {
  final List<dynamic>? apiSongs = apiAlbum['songs'] as List<dynamic>?;
  final List<Map<String, dynamic>> appSongs = (apiSongs ?? [])
      .map((song) => mapApiSong(Map<String, dynamic>.from(song)))
      .toList();
  return {
    'id': apiAlbum['id'],
    'title': apiAlbum['tieu_de'] ?? apiAlbum['title'],
    'cover_url': apiAlbum['anh_bia'],
    'release_date': apiAlbum['ngay_phat_hanh'],
    'artist_id': apiAlbum['artist_id'],
    'artists': {'name': apiAlbum['ten_nghe_si'] ?? apiAlbum['subtitle'] ?? 'Không rõ'},
    'songs': appSongs,
    'genres_string': apiAlbum['ds_the_loai'] ?? '',
    'subtitle_text': 'Album • ${apiAlbum['ten_nghe_si'] ?? apiAlbum['subtitle'] ?? 'Không rõ'}',
    '__type': 'album',
  };
}

Map<String, dynamic> mapApiArtist(Map<String, dynamic> apiArtist) {
  return {
    'id': apiArtist['id'],
    'name': apiArtist['ten'] ?? apiArtist['title'],
    'avatar_url': apiArtist['anh_dai_dien'] ?? apiArtist['anh_bia'],
    'genres_string': apiArtist['ds_the_loai'] ?? '',
    'subtitle_text': 'Nghệ sĩ',
    '__type': 'artist',
  };
}

Map<String, dynamic> mapApiPlaylist(Map<String, dynamic> apiPlaylist) {
  final List<dynamic>? apiSongs = apiPlaylist['songs'] as List<dynamic>?;
  final List<Map<String, dynamic>> appSongs = (apiSongs ?? [])
      .map((song) => mapApiSong(Map<String, dynamic>.from(song)))
      .toList();

  return {
    'id': apiPlaylist['id'],
    'title': apiPlaylist['ten'] ?? apiPlaylist['title'],
    'cover_url': apiPlaylist['anh_bia'],
    'description': apiPlaylist['mo_ta'],
    'artists': { 'name': apiPlaylist['ten_nguoi_tao'] ?? 'Buzzify' },
    'songs': appSongs,
    'genres_string': apiPlaylist['ds_the_loai'] ?? '',
    'subtitle_text': apiPlaylist['subtitle'] ?? 'Playlist',
    '__type': 'playlist',
  };
}

// --- THÊM HÀM MỚI ---
Map<String, dynamic> mapApiProfile(Map<String, dynamic> apiProfile) {
  return {
    'id': apiProfile['id'],
    'name': apiProfile['ho_ten'] ?? apiProfile['title'],
    'avatar_url': apiProfile['anh_dai_dien'] ?? apiProfile['anh_bia'],
    'subtitle_text': 'Hồ sơ',
    '__type': 'profile',
  };
}