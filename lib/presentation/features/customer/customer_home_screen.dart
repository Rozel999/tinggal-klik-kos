import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import '../shared/listing_screens.dart';
import '../shared/profile_screen.dart';
import '../shared/transaction_screens.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  String _category = 'Semua';
  int _tab = 0;
  int _maxPrice = 3000000;

  static const _categories = ['Semua', 'Putri', 'Putra', 'Campur'];

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _rupiah(int price) => 'Rp${(price / 1000).round().toString()}rb';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final user = context.watch<AuthProvider>().user;
    final customerId = user?.id ?? 'guest';
    final query = _search.text.trim().toLowerCase();
    final listings = data.approvedListings.where((listing) {
      final matchesCategory =
          _category == 'Semua' || listing.gender == _category;
      final matchesPrice = listing.price <= _maxPrice;
      final matchesFavorite =
          _tab != 2 || data.isFavorite(customerId, listing.id);
      final searchable =
          '${listing.name} ${listing.address} ${listing.description} ${listing.amenities.join(' ')}'
              .toLowerCase();
      return matchesCategory &&
          matchesPrice &&
          matchesFavorite &&
          (query.isEmpty || searchable.contains(query));
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _locationBar(context, user),
                  const SizedBox(height: 22),
                  const Text('Cari kos yang bikin',
                      style: TextStyle(
                          fontSize: 27,
                          height: 1.05,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800)),
                  const Text('betah',
                      style: TextStyle(
                          fontSize: 27,
                          height: 1.05,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _searchField(),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category == _category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _category = category),
                          selectedColor: AppTheme.teal,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : AppTheme.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                          side: BorderSide(
                              color: selected
                                  ? AppTheme.teal
                                  : const Color(0xFFE8E9E3)),
                          shape: const StadiumBorder(),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 21),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lagi hits minggu ini',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      TextButton(
                          onPressed: _showAllListings,
                          child: const Text('Lihat semua')),
                    ],
                  ),
                  if (listings.isNotEmpty)
                    _featuredCard(listings.first, data, user),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _quickFilter(
                            icon: Icons.school_outlined,
                            title: 'Area kampus',
                            subtitle: 'Cari kos sekitar UNP',
                            onTap: () {
                              _search.text = 'UNP';
                              setState(() {});
                            }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickFilter(
                            icon: Icons.payments_outlined,
                            title: 'Di bawah Rp 600rb',
                            subtitle: 'Kos hemat',
                            onTap: () => setState(() => _maxPrice = 600000)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 23),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_tab == 2 ? 'Kos favorit' : 'Paling dicari',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('${listings.length} kos',
                          style: const TextStyle(
                              color: Color(0xFF7B8580), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data.syncNotice != null && data.loadError == null)
                    Card(
                        child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.sync_problem_outlined,
                                color: Color(0xFFAF711C)),
                            title: Text(data.syncNotice!),
                            trailing: IconButton(
                                tooltip: 'Sinkronkan sekarang',
                                onPressed: data.load,
                                icon: const Icon(Icons.refresh_rounded)))),
                  if (data.loadError != null)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              const Icon(Icons.cloud_off_outlined,
                                  color: AppTheme.teal, size: 30),
                              const SizedBox(height: 8),
                              const Text('Data belum berhasil dimuat',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(data.loadError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF5F6B73))),
                              TextButton.icon(
                                  onPressed: data.load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba lagi')),
                            ]))),
                  if (listings.isEmpty && data.loadError == null)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              const Icon(Icons.search_off_rounded,
                                  color: AppTheme.teal, size: 34),
                              const SizedBox(height: 9),
                              Text(
                                  _tab == 2
                                      ? 'Belum ada kos favorit'
                                      : 'Belum ada kos yang cocok',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 5),
                              Text(
                                  _tab == 2
                                      ? 'Simpan kos dengan ikon hati untuk melihatnya di sini.'
                                      : 'Ubah kata kunci atau filter, atau cek lagi nanti.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: Color(0xFF5F6B73))),
                            ]))),
                  ...listings
                      .map((listing) => _listingCard(listing, data, user)),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => KosMapScreen(listings: listings)));
          } else if (index == 3) {
            _showAccount(context, customerId);
          } else {
            setState(() => _tab = index);
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Peta'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Favorit'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded), label: 'Akun'),
        ],
      ),
    );
  }

  Widget _locationBar(BuildContext context, AppUser? user) => Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppTheme.teal, size: 18),
          const SizedBox(width: 4),
          Expanded(
              child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => KosMapScreen(
                              listings: context
                                  .read<KosDataProvider>()
                                  .approvedListings))),
                  child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lokasi kamu',
                                style: TextStyle(
                                    color: Color(0xFF5F6B73), fontSize: 11)),
                            Row(children: [
                              Text('Padang',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              SizedBox(width: 3),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                            ]),
                          ])))),
          IconButton.filledTonal(
              tooltip: 'Notifikasi',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen())),
              icon: const Icon(Icons.notifications_none_rounded)),
          if (user != null)
            Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                    tooltip: 'Profil saya',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen())),
                    icon: CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFDCEBE1),
                        child: Text(user.name.isEmpty
                            ? 'K'
                            : user.name.characters.first.toUpperCase())))),
        ],
      );

  Widget _searchField() => TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari area, kampus, nama kos...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.teal),
          suffixIcon: IconButton(
              tooltip: 'Filter',
              onPressed: _showFilters,
              icon: const Icon(Icons.tune_rounded, color: AppTheme.teal)),
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE9EAE4))),
        ),
      );

  Widget _featuredCard(
      KosListing listing, KosDataProvider data, AppUser? user) {
    final favorite = data.isFavorite(user?.id ?? 'guest', listing.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => KosDetailScreen(listing: listing))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            _houseArtwork(height: 172, large: true),
            Positioned(
                right: 11,
                top: 11,
                child: _favoriteButton(
                    favorite,
                    () =>
                        data.toggleFavorite(user?.id ?? 'guest', listing.id))),
            Positioned(
                left: 12,
                bottom: 11,
                child: _pill(listing.gender, light: true)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(listing.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15))),
                _pill(listing.gender),
              ]),
              const SizedBox(height: 4),
              Text(listing.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF5F6B73), fontSize: 11)),
              const SizedBox(height: 8),
              Row(children: [
                Text(_rupiah(listing.price),
                    style: const TextStyle(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                const Text(' /bulan',
                    style: TextStyle(color: Color(0xFF5F6B73), fontSize: 11)),
                const Spacer(),
                _pill('${listing.roomsAvailable} kamar kosong'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _listingCard(KosListing listing, KosDataProvider data, AppUser? user) {
    final favorite = data.isFavorite(user?.id ?? 'guest', listing.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => KosDetailScreen(listing: listing))),
        child: Row(children: [
          SizedBox(
              width: 112,
              height: 118,
              child: _houseArtwork(height: 118, large: false)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 11, 9),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(listing.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13))),
                    ]),
                    const SizedBox(height: 4),
                    Text(listing.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF5F6B73))),
                    const SizedBox(height: 7),
                    Row(children: [
                      Expanded(
                          child: Text('${_rupiah(listing.price)} /bln',
                              style: const TextStyle(
                                  color: AppTheme.teal,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12))),
                      _pill('Sisa ${listing.roomsAvailable}'),
                    ]),
                    Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                            height: 28,
                            child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: favorite
                                    ? 'Hapus favorit'
                                    : 'Simpan favorit',
                                onPressed: () async {
                                  try {
                                    await data.toggleFavorite(
                                        user?.id ?? 'guest', listing.id);
                                  } catch (error) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Favorit gagal diperbarui: $error')));
                                  }
                                },
                                icon: Icon(
                                    favorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 18,
                                    color: favorite
                                        ? Colors.redAccent
                                        : AppTheme.teal)))),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _houseArtwork({required double height, required bool large}) =>
      Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFD8E8DE), Color(0xFFF0E8D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
              right: large ? 24 : 10,
              top: large ? 16 : 10,
              child: Container(
                  width: large ? 43 : 24,
                  height: large ? 43 : 24,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFD77D), shape: BoxShape.circle))),
          Icon(Icons.house_rounded,
              size: large ? 134 : 74, color: const Color(0xFF2F6B5E)),
        ]),
      );

  Widget _favoriteButton(bool active, VoidCallback onPressed) => CircleAvatar(
        radius: 19,
        backgroundColor: Colors.white,
        child: IconButton(
            tooltip: active ? 'Hapus favorit' : 'Simpan favorit',
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(active ? Icons.favorite_rounded : Icons.favorite_border,
                color: active ? Colors.redAccent : AppTheme.ink, size: 19)),
      );

  Widget _pill(String label, {bool light = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: light ? Colors.white : const Color(0xFFE8F1EC),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: light ? AppTheme.ink : AppTheme.teal,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      );

  Widget _quickFilter(
          {required IconData icon,
          required String title,
          required String subtitle,
          required VoidCallback onTap}) =>
      Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFE8F1EC),
                  child: Icon(icon, color: AppTheme.teal, size: 17)),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF5F6B73))),
                  ])),
            ]),
          ),
        ),
      );

  void _showAllListings() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic);
  }

  Future<void> _showFilters() async {
    var draftPrice = _maxPrice.toDouble();
    var draftCategory = _category;
    final selection = await showModalBottomSheet<_ListingFilter>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter pencarian',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  const Text('Tipe kos',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map((category) => ChoiceChip(
                                label: Text(category),
                                selected: draftCategory == category,
                                onSelected: (_) =>
                                    setSheet(() => draftCategory = category),
                              ))
                          .toList()),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Expanded(
                        child: Text('Batas harga per bulan',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    Text('Rp${(draftPrice / 1000).round()} ribu'),
                  ]),
                  Slider(
                    value: draftPrice.clamp(500000, 3000000).toDouble(),
                    min: 500000,
                    max: 3000000,
                    divisions: 25,
                    label: 'Rp${(draftPrice / 1000).round()} ribu',
                    onChanged: (price) => setSheet(() => draftPrice = price),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                          sheetContext,
                          const _ListingFilter(
                              category: 'Semua', maxPrice: 3000000)),
                      child: const Text('Atur ulang'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                              sheetContext,
                              _ListingFilter(
                                  category: draftCategory,
                                  maxPrice: draftPrice.round())),
                          child: const Text('Tampilkan kos'),
                        )),
                  ]),
                ]),
          ),
        ),
      ),
    );
    if (selection != null) {
      setState(() {
        _category = selection.category;
        _maxPrice = selection.maxPrice;
      });
    }
  }

  void _showAccount(BuildContext context, String customerId) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Akun saya',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800))),
                  ListTile(
                      leading: const Icon(Icons.home_work_outlined),
                      title: const Text('Sewa saya'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CustomerBookingsScreen(
                                    customerId: customerId)));
                      }),
                  ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Tagihan'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    InvoiceListScreen(customerId: customerId)));
                      }),
                  ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Keluar'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.read<AuthProvider>().signOut();
                      }),
                ]),
              ),
            ));
  }
}

class _ListingFilter {
  const _ListingFilter({required this.category, required this.maxPrice});
  final String category;
  final int maxPrice;
}
