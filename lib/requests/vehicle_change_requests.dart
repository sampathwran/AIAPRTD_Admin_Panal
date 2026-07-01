import 'package:flutter/material.dart';
import 'dashboard_stats.dart';
import 'request_list.dart';

class VehicleChangeRequests extends StatefulWidget {
  const VehicleChangeRequests({super.key});

  @override
  State<VehicleChangeRequests> createState() => _VehicleChangeRequestsState();
}

class _VehicleChangeRequestsState extends State<VehicleChangeRequests> {
  // State pipeline variables setup
  String selectedStatus = 'pending'; // Default 'pending' requests විතරක් පේන්න
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Vehicle Change Requests",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1B2735)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff1B2735), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dashboard Counter Cards Layout (Using the optimized separate widget)
              DashboardStats(
                selectedStatus: selectedStatus,
                onStatusChanged: (status) {
                  setState(() {
                    selectedStatus = status;
                  });
                },
              ),

              const SizedBox(height: 15),

              // 2. Search Bar Integration
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search by Membership Number...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => searchQuery = '');
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xff1B2735), width: 1.5),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Dynamic Section Heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "${selectedStatus.toUpperCase()} REQUESTS LIST",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.8
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 4. Isolated Dynamic Request List Stream View
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: RequestList(
                  selectedStatus: selectedStatus,
                  searchQuery: searchQuery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}