import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/voucher_provider.dart';
import '../widgets/voucher_card.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<VoucherProvider>(context, listen: false);
    await Future.wait([
      provider.loadAvailableVouchers(),
      provider.loadSavedVouchers(),
    ]);
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Đã xóa leading (mũi tên quay lại)
        title: const Text(
          'Ưu đãi của tôi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Căn giữa tiêu đề
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đã lưu'),
          ],
        ),
      ),
      body: Consumer2<AuthProvider, VoucherProvider>(
        builder: (context, authProvider, voucherProvider, child) {
          if (_isInitialLoad && 
              (voucherProvider.isLoading || voucherProvider.isLoadingSaved)) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableVouchers(voucherProvider),
              _buildSavedVouchers(voucherProvider, authProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableVouchers(VoucherProvider provider) {
    if (provider.isLoading && provider.availableVouchers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadAvailableVouchers(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (provider.availableVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có voucher khả dụng',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAvailableVouchers(),
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.availableVouchers.length,
        itemBuilder: (context, index) {
          final voucher = provider.availableVouchers[index];
          return VoucherCard(
            voucher: voucher,
            onSave: () => _handleSaveVoucher(voucher.voucherCode),
          );
        },
      ),
    );
  }

  Widget _buildSavedVouchers(VoucherProvider provider, AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Đăng nhập để xem voucher đã lưu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login').then((_) {
                  if (mounted) {
                    provider.loadSavedVouchers();
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
    }

    if (provider.isLoadingSaved && provider.savedVouchers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (provider.savedError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(provider.savedError!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadSavedVouchers(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (provider.savedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có voucher nào được lưu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy lưu voucher để dùng sau nhé!',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Lọc danh sách chỉ lấy những voucher có dữ liệu
    final validSavedVouchers = provider.savedVouchers
        .where((uv) => uv.voucher != null)
        .toList();

    if (validSavedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có voucher nào được lưu',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy lưu voucher để dùng sau nhé!',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSavedVouchers(),
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: validSavedVouchers.length,
        itemBuilder: (context, index) {
          final userVoucher = validSavedVouchers[index];
          return VoucherCard(
            voucher: userVoucher.voucher!,
            isSaved: true,
            showSaveButton: false,
            onUse: () => _handleUseVoucher(userVoucher.userVoucherId),
          );
        },
      ),
    );
  }

  Future<void> _handleSaveVoucher(String voucherCode) async {
    final provider = Provider.of<VoucherProvider>(context, listen: false);
    final success = await provider.saveVoucher(voucherCode);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu voucher thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lưu voucher thất bại'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleUseVoucher(String userVoucherId) async {
    final provider = Provider.of<VoucherProvider>(context, listen: false);
    final success = await provider.useSavedVoucher(userVoucherId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sử dụng voucher thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // Có thể quay lại màn hình trước đó
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Sử dụng voucher thất bại'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}