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
  bool _hasLoadedAvailable = false;
  bool _hasLoadedSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_hasLoadedAvailable && _hasLoadedSaved) return;
    
    final provider = Provider.of<VoucherProvider>(context, listen: false);
    
    await Future.wait([
      _loadAvailableVouchers(provider),
      _loadSavedVouchers(provider),
    ]);
    
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }
  
  Future<void> _loadAvailableVouchers(VoucherProvider provider) async {
    if (_hasLoadedAvailable) return;
    await provider.loadAvailableVouchers();
    _hasLoadedAvailable = true;
  }
  
  Future<void> _loadSavedVouchers(VoucherProvider provider) async {
    if (_hasLoadedSaved) return;
    await provider.loadSavedVouchers();
    _hasLoadedSaved = true;
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
        title: const Text(
          'Ưu đãi của tôi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
          // Hiển thị loading nếu đang load lần đầu
          if (_isInitialLoad && 
              (voucherProvider.isLoading || voucherProvider.isLoadingSaved)) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Đang tải voucher...'),
                ],
              ),
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
    // Hiển thị loading nếu đang load và chưa có dữ liệu
    if (provider.isLoading && provider.availableVouchers.isEmpty && !provider.hasLoadedAvailable) {
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
              onPressed: () => provider.refreshAvailableVouchers(),
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
      onRefresh: () => provider.refreshAvailableVouchers(),
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
                    provider.refreshSavedVouchers();
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

    // Hiển thị loading nếu đang load và chưa có dữ liệu
    if (provider.isLoadingSaved && provider.savedVouchers.isEmpty && !provider.hasLoadedSaved) {
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
              onPressed: () => provider.refreshSavedVouchers(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Lọc danh sách chỉ lấy những voucher có dữ liệu và còn hiệu lực
    final validSavedVouchers = provider.getValidSavedVouchers();

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
      onRefresh: () => provider.refreshSavedVouchers(),
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