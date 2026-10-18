import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/admin_theme.dart';
import '../../core/admin_api_service.dart';
import 'dashboard_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});
  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  List<dynamic> _songs = [];
  List<dynamic> _filteredSongs = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = true;
  
  Set<int> _selectedSongIds = {};
  bool _isBulkUpdating = false;
  final TextEditingController _searchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _urlController = TextEditingController();
  final _videoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAudioFile;
  XFile? _selectedVideoFile;
  bool _isUploadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    _videoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _songs;
      } else {
        _filteredSongs = _songs.where((song) {
          final title = (song['title'] ?? '').toLowerCase();
          final artist = (song['artist'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || artist.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminApiService.getSongs(_currentPage, 20);
      setState(() {
        _songs = data['songs'];
        _filteredSongs = _songs;
        _totalPages = data['totalPages'];
        _totalElements = data['totalElements'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load songs: $e')));
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, allowedExtensions: ['mp3', 'wav', 'm4a', 'aac']);
      if (result != null) {
        final file = XFile(result.files.first.path!);
        setState(() => _selectedAudioFile = file);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected audio: ${result.files.first.name}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick audio: $e')));
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) setState(() => _selectedVideoFile = file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick video: $e')));
    }
  }

  Future<void> _addSong() async {
    if (_formKey.currentState!.validate()) {
      final songData = {'title': _titleController.text.trim(), 'artist': _artistController.text.trim(), 'url': _urlController.text.trim(), 'video': _videoController.text.trim()};
      try {
        final result = await AdminApiService.createSong(songData);
        final songId = result['id'];
        if (_selectedAudioFile != null || _selectedVideoFile != null) {
          setState(() => _isUploadingFiles = true);
          await AdminApiService.uploadSongFiles(songId, audioFile: _selectedAudioFile, videoFile: _selectedVideoFile);
          setState(() => _isUploadingFiles = false);
        }
        _clearForm();
        _loadSongs();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song added successfully')));
      } catch (e) {
        setState(() => _isUploadingFiles = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add song: $e')));
      }
    }
  }

  Future<void> _editSong(Map<String, dynamic> song) async {
    _titleController.text = song['title'] ?? '';
    _artistController.text = song['artist'] ?? '';
    _urlController.text = song['url'] ?? '';
    _videoController.text = song['video'] ?? '';
    _selectedAudioFile = null;
    _selectedVideoFile = null;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('Upload Files (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _pickAudioFile, icon: const Icon(Icons.audio_file), label: Text(_selectedAudioFile != null ? '✓ ${_selectedAudioFile!.name}' : 'Select Audio', overflow: TextOverflow.ellipsis), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(140, 40)))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(onPressed: _pickVideoFile, icon: const Icon(Icons.video_file), label: Text(_selectedVideoFile != null ? '✓ ${_selectedVideoFile!.name}' : 'Select Video', overflow: TextOverflow.ellipsis), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(140, 40)))),
                ],
              ),
              if (_selectedAudioFile != null || _selectedVideoFile != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Files will be uploaded after saving', style: TextStyle(color: Colors.grey[400], fontSize: 11))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: _isUploadingFiles
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final songData = {'title': _titleController.text.trim(), 'artist': _artistController.text.trim(), 'url': _urlController.text.trim(), 'video': _videoController.text.trim()};
                      try {
                        await AdminApiService.updateSong(song['id'], songData);
                        if (_selectedAudioFile != null || _selectedVideoFile != null) {
                          setState(() => _isUploadingFiles = true);
                          await AdminApiService.uploadSongFiles(song['id'], audioFile: _selectedAudioFile, videoFile: _selectedVideoFile);
                          setState(() => _isUploadingFiles = false);
                        }
                        _clearForm();
                        _loadSongs();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song updated successfully')));
                      } catch (e) {
                        setState(() => _isUploadingFiles = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update song: $e')));
                      }
                    }
                  },
            child: _isUploadingFiles ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHideSong(Map<String, dynamic> song) async {
    final isActive = song['active'] ?? true;
    try {
      if (isActive) {
        await AdminApiService.hideSong(song['id']);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song hidden from users')));
      } else {
        await AdminApiService.unhideSong(song['id']);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song visible to users')));
      }
      _loadSongs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ✅ UPDATED: Soft Delete (Moves to Recycle Bin)
  Future<void> _deleteSong(Map<String, dynamic> song) async {
    try {
      await AdminApiService.softDeleteSong(song['id']);
      _loadSongs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moved to Recycle Bin'), backgroundColor: Colors.orange)
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move to bin: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _bulkUpdateSongs(bool makeActive) async {
    if (_selectedSongIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makeActive ? 'Unhide Selected Songs?' : 'Hide Selected Songs?'),
        content: Text('Are you sure you want to ${makeActive ? "unhide" : "hide"} ${_selectedSongIds.length} songs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: makeActive ? Colors.green : Colors.orange),
            child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isBulkUpdating = true);
      try {
        final idsToUpdate = List<int>.from(_selectedSongIds);
        if (makeActive) {
          await AdminApiService.unhideSongsBulk(idsToUpdate);
        } else {
          await AdminApiService.hideSongsBulk(idsToUpdate);
        }
        setState(() {
          _isBulkUpdating = false;
          _selectedSongIds.clear();
        });
        _loadSongs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated ${idsToUpdate.length} songs.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        setState(() => _isBulkUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update songs: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Song Title', hintText: 'Enter song title'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _artistController, decoration: const InputDecoration(labelText: 'Artist', hintText: 'Enter artist name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _urlController, decoration: const InputDecoration(labelText: 'Audio URL (Fallback)', hintText: 'https://... (kept for backup)')),
          const SizedBox(height: 12),
          TextFormField(controller: _videoController, decoration: const InputDecoration(labelText: 'Video URL (Fallback)', hintText: 'https://... (kept for backup)')),
        ],
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _artistController.clear();
    _urlController.clear();
    _videoController.clear();
    _selectedAudioFile = null;
    _selectedVideoFile = null;
  }

  void _showAddSongDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Song'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForm(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('Upload Files (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AdminTheme.textLight)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _pickAudioFile, icon: const Icon(Icons.audio_file), label: Text(_selectedAudioFile != null ? '✓ ${_selectedAudioFile!.name}' : 'Select Audio', overflow: TextOverflow.ellipsis), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(140, 40)))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(onPressed: _pickVideoFile, icon: const Icon(Icons.video_file), label: Text(_selectedVideoFile != null ? '✓ ${_selectedVideoFile!.name}' : 'Select Video', overflow: TextOverflow.ellipsis), style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(140, 40)))),
                ],
              ),
              if (_selectedAudioFile != null || _selectedVideoFile != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Files will be uploaded after saving', style: TextStyle(color: Colors.grey[400], fontSize: 11))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: _isUploadingFiles ? null : _addSong, child: _isUploadingFiles ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ADD')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()))),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showAddSongDialog, tooltip: 'Add Song')],
      ),
      body: _isLoading || _isBulkUpdating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (_isBulkUpdating) const Text('Updating selected songs...', style: TextStyle(color: AdminTheme.textLight)),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by song title or artist...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterSongs('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filterSongs,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AdminTheme.surface.withOpacity(0.5),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _filteredSongs.isNotEmpty && _selectedSongIds.length == _filteredSongs.length,
                        tristate: true,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSongIds.addAll(_filteredSongs.map((s) => s['id'] as int));
                            } else {
                              _selectedSongIds.clear();
                            }
                          });
                        },
                      ),
                      const Text('Select All', style: TextStyle(color: AdminTheme.textLight, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(color: AdminTheme.textLight)),
                    ],
                  ),
                ),
                if (_selectedSongIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.blue.withOpacity(0.2),
                    child: Row(
                      children: [
                        Text('${_selectedSongIds.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.visibility_off, color: Colors.orange, size: 28), tooltip: 'Hide Selected', onPressed: () => _bulkUpdateSongs(false)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.visibility, color: Colors.green, size: 28), tooltip: 'Unhide Selected', onPressed: () => _bulkUpdateSongs(true)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.clear, color: Colors.white70, size: 28), tooltip: 'Clear Selection', onPressed: () { setState(() { _selectedSongIds.clear(); }); }),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      final isActive = song['active'] ?? true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AdminTheme.surface,
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _selectedSongIds.contains(song['id']),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedSongIds.add(song['id'] as int);
                                    } else {
                                      _selectedSongIds.remove(song['id']);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              CircleAvatar(backgroundColor: isActive ? Colors.green : Colors.grey, child: const Icon(Icons.music_note, color: Colors.white, size: 20)),
                            ],
                          ),
                          title: Text(song['title'] ?? 'Unknown', style: const TextStyle(color: AdminTheme.textLight)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song['artist'] ?? 'Unknown', style: TextStyle(color: Colors.grey[400])),
                              if (song['audioFileUrl'] != null) Text('🎵 Audio: Uploaded', style: TextStyle(color: Colors.green[400], fontSize: 11)),
                              if (song['videoFileUrl'] != null) Text('🎬 Video: Uploaded', style: TextStyle(color: Colors.blue[400], fontSize: 11)),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editSong(song), tooltip: 'Edit'),
                              IconButton(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [Icon(Icons.remove_red_eye, color: isActive ? Colors.green : Colors.red), if (!isActive) Positioned(child: Container(width: 24, height: 2, color: Colors.red))],
                                ),
                                onPressed: () => _toggleHideSong(song),
                                tooltip: isActive ? 'Hide' : 'Unhide',
                              ),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSong(song), tooltip: 'Delete'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0) ElevatedButton(onPressed: () { setState(() { _currentPage--; _loadSongs(); }); }, child: const Text('PREVIOUS')),
                      if (_currentPage < _totalPages - 1) ElevatedButton(onPressed: () { setState(() { _currentPage++; _loadSongs(); }); }, child: const Text('NEXT')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
