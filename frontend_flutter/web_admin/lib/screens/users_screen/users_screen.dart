import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/responsive.dart';
import 'user_detail_dialog.dart';
import 'add_admin_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'Tất cả';
  final Color primaryGreen = const Color(0xFF1A5F3A);
  final Color backgroundGrey = const Color(0xFFF4F7F5);

  final Map<String, String> _roleDisplay = {
    'Tất cả': 'Tất cả',
    'admin': 'Quản trị viên',
    'customer': 'Khách hàng',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<UserProvider>().searchUsers(value);
  }

  void _onFilterRole(String roleKey) {
    setState(() => _selectedRole = roleKey);
    context.read<UserProvider>().filterByRole(roleKey == 'Tất cả' ? null : roleKey);
  }

  void _toggleStatus(User user) async {
    final provider = context.read<UserProvider>();
    bool success = await provider.toggleUserStatus(user.userId, user.status);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã cập nhật trạng thái cho ${user.fullName}"),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildToolBar(userProvider, isMobile),
          _buildRoleFilter(userProvider),
          Expanded(
            child: userProvider.isLoading && userProvider.users.isEmpty
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: [
                        Expanded(child: _buildUserTable(userProvider.users, isMobile, constraints)),
                        if (userProvider.users.isNotEmpty) _buildPagination(userProvider),
                      ],
                    );
                  }),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar(UserProvider provider, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? 200 : 350,
            height: 42,
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddAdminDialog(),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: Text(isMobile ? 'Thêm' : 'Thêm Quản trị viên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoleFilter(UserProvider provider) {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _roleDisplay.entries.map((e) {
          bool isSelected = _selectedRole == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (val) => _onFilterRole(e.key),
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserTable(List<User> users, bool isMobile, BoxConstraints constraints) {
    double minTableWidth = isMobile ? 800 : 1100;
    return RefreshIndicator(
      onRefresh: () => context.read<UserProvider>().fetchUsers(),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              width: minTableWidth,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildTableHeader(),
                  if (users.isEmpty)
                    const Padding(padding: EdgeInsets.all(40), child: Text("Không tìm thấy dữ liệu"))
                  else
                    ...users.map((user) => _buildUserRow(user)).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5F3A), fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: const BoxDecoration(color: Color(0xFFF1F8E9), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Người dùng', style: headerStyle)),
          Expanded(flex: 3, child: Text('Email & SĐT', style: headerStyle)),
          Expanded(flex: 2, child: Center(child: Text('Vai trò', style: headerStyle))),
          Expanded(flex: 2, child: Center(child: Text('Trạng thái', style: headerStyle))),
          Expanded(flex: 1, child: Center(child: Text('Xem', style: headerStyle))),
          Expanded(flex: 1, child: Center(child: Text('Khóa', style: headerStyle))),
        ],
      ),
    );
  }

  Widget _buildUserRow(User user) {
    bool isActive = user.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            if (user.phone != null) Text(user.phone!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ])),
          Expanded(flex: 2, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: (user.role == 'admin' ? Colors.purple : Colors.blue).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_roleDisplay[user.role] ?? user.role, style: TextStyle(color: user.role == 'admin' ? Colors.purple : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
          ))),
          Expanded(flex: 2, child: Center(child: Text(isActive ? "Hoạt động" : "Bị khóa", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w500)))),
          Expanded(flex: 1, child: IconButton(icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue), onPressed: () => _showUserDetail(user))),
          Expanded(flex: 1, child: user.role == 'admin' ? const SizedBox() : IconButton(icon: Icon(isActive ? Icons.lock_outline : Icons.lock_open, size: 20, color: isActive ? Colors.red : Colors.green), onPressed: () => _toggleStatus(user))),
        ],
      ),
    );
  }

  Widget _buildPagination(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left), 
            onPressed: provider.currentPage > 1 ? () => provider.goToPage(provider.currentPage - 1) : null
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(15)),
            child: Text('${provider.currentPage} / ${provider.totalPages}', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right), 
            onPressed: provider.currentPage < provider.totalPages ? () => provider.goToPage(provider.currentPage + 1) : null
          ),
        ],
      ),
    );
  }

  void _showUserDetail(User user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(
        user: user,
        roleDisplay: _roleDisplay,
        primaryGreen: primaryGreen,
        backgroundGrey: backgroundGrey,
      ),
    );
  }

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddAdminDialog(
        primaryGreen: primaryGreen,
        backgroundGrey: backgroundGrey,
      ),
    );
  }
}