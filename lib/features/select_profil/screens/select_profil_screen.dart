import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profil_masjid_provider.dart';
import '../models/profil_masjid_model.dart';
import '../widgets/profil_card_widget.dart';
import 'dart:async';

class SelectProfilScreen extends ConsumerStatefulWidget {
  const SelectProfilScreen({super.key});

  @override
  ConsumerState<SelectProfilScreen> createState() => _SelectProfilScreenState();
}

class _SelectProfilScreenState extends ConsumerState<SelectProfilScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProfilMasjidModel> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  
  int _currentPage = 1;
  bool _hasMore = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
        _error = e.toString();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Masjid'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari masjid...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Anda memilih: ${profil.name}')),
            );
          },
        );
      },
    );
  }
}
