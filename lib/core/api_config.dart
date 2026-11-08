class ApiConfig {
  static const String baseUrl = 'https://singsation-api-d5hd.onrender.com/api';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // TIMEOUTS
  // ---------------------------------------------------------------------------
  // The API runs on Render free tier and is kept warm by UptimeRobot, so most
  // requests are fast. These values give headroom for the cold-start case
  // without letting a dead request hang the admin UI forever.
  //
  // - standardTimeout: GET / POST / PUT / DELETE for JSON payloads
  // - uploadTimeout:   multipart uploads (video, image, splash, cover art)
  // ---------------------------------------------------------------------------
  static const Duration standardTimeout = Duration(seconds: 45);
  static const Duration uploadTimeout = Duration(minutes: 3);
}
