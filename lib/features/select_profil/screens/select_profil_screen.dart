import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';

import '../../../core/providers/storage_provider.dart';
import '../../../core/providers/selected_profil_provider.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/profil_masjid_provider.dart';
import '../models/profil_masjid_model.dart';
import '../widgets/profil_card_widget.dart';

class SelectProfilScreen extends ConsumerStatefulWidget {
  const SelectProfilScreen({super.key});

  @override
  ConsumerState<SelectProfilScreen> createState() => _SelectProfilScreenState();
}

class _SelectProfilScreenState extends ConsumerState<SelectProfilScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<ProfilMasjidModel> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  Timer? _debounce;
  
  bool _isSearchFocused = false;
  bool _isSearchEditing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
        if (!_searchFocusNode.hasFocus) {
          _isSearchEditing = false; // Keluar dari mode edit jika kehilangan fokus
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
        _hasMore = true;
        _items.clear();
      });
      _fetchPage();
    });
  }

  Future<void> _fetchPage() async {
    if (!mounted) return;
    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
      _error = null;
    });

    try {
      final service = ref.read(profilMasjidServiceProvider);
      final response = await service.getProfilMasjids(
        page: _currentPage,
        searchQuery: _searchQuery,
      );
      
      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _items = response.data;
        } else {
          _items.addAll(response.data);
        }
        _hasMore = response.currentPage < response.lastPage;
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isFetchingMore || !_hasMore) return;
    _currentPage++;
    await _fetchPage();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Arial'),
      ),
      child: AppScaffold(
        appBar: const AppTopBar(
          title: Text('Pilih Masjid'),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    if (!_isSearchEditing) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onFocusChange: (focused) {
            setState(() {
              _isSearchFocused = focused;
            });
          },
          onTap: () {
            setState(() {
              _isSearchEditing = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
              SystemChannels.textInput.invokeMethod('TextInput.show');
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isSearchFocused ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSearchFocused ? Colors.blue : Colors.grey,
                width: _isSearchFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _searchQuery.isEmpty ? 'Cari masjid...' : _searchQuery,
                    style: TextStyle(
                      color: _searchQuery.isEmpty ? Colors.grey.shade600 : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Focus(
        onKeyEvent: (node, event) {
          // Cegah TextField menahan (trap) tombol panah bawah/atas
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            FocusScope.of(context).focusInDirection(TraversalDirection.down);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            FocusScope.of(context).focusInDirection(TraversalDirection.up);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          focusNode: _searchFocusNode,
          controller: _searchController,
          onSubmitted: (_) {
            setState(() {
              _isSearchEditing = false;
            });
          },
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Cari masjid...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            fillColor: Colors.blue.shade50,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Terjadi kesalahan:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Data profil masjid tidak ditemukan.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final profil = _items[index];
        return ProfilCardWidget(
          profil: profil,
          onTap: () async {
            // Tampilkan indikator loading (opsional) atau langsung navigasi
            
            // Simpan ke safe storage
            final storage = ref.read(secureStorageProvider);
            await storage.write('selected_profil', jsonEncode(profil.toJson()));
            
            // Perbarui statenya di provider
            ref.read(selectedProfilProvider.notifier).setProfil(profil);
            
            // Navigasi ke main
            if (context.mounted) {
              context.goNamed('main');
            }
          },
        );
      },
    );
  }
}
