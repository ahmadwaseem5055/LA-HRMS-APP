// ============================================
// 9. lib/screens/leave_screen.dart
// ============================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _appKey;
  int? _employeeId;

  List<Map<String, dynamic>> _allocations = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _appKey = await StorageService.getAppKey();
    _employeeId = await StorageService.getEmployeeId();

    if (_appKey != null && _employeeId != null) {
      await Future.wait([
        _loadAllocations(),
        _loadHistory(),
      ]);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAllocations() async {
    final result = await ApiService.getLeaveAllocations(_appKey!, _employeeId!);

    if (result['success'] == true) {
      setState(() {
        _allocations = List<Map<String, dynamic>>.from(result['allocations'] ?? []);
      });
    }
  }

  Future<void> _loadHistory() async {
    final result = await ApiService.getLeaveHistory(_appKey!, _employeeId!);

    if (result['success'] == true) {
      setState(() {
        _history = List<Map<String, dynamic>>.from(result['leaves'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Allocations'),
            Tab(text: 'History'),
            Tab(text: 'Apply'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllocationsTab(),
                _buildHistoryTab(),
                _buildApplyTab(),
              ],
            ),
    );
  }

  Widget _buildAllocationsTab() {
    if (_allocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No leave allocations',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allocations.length,
      itemBuilder: (context, index) {
        final allocation = _allocations[index];
        final total = (allocation['total_allowed'] ?? 0).toDouble();
        final remaining = (allocation['remaining'] ?? 0).toDouble();
        final used = total - remaining;
        final percentage = total > 0 ? (remaining / total) : 0.0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        allocation['leave_type'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${remaining.toStringAsFixed(1)} days left',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${total.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Used: ${used.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 0.5 ? Colors.green : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No leave history',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final leave = _history[index];
        final status = leave['status'] ?? 'draft';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        leave['leave_type'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getLeaveStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${leave['from_date']} to ${leave['to_date']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${leave['days']} days',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (leave['reason'] != null && leave['reason'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          leave['reason'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplyTab() {
    return ApplyLeaveForm(
      appKey: _appKey!,
      employeeId: _employeeId!,
      allocations: _allocations,
      onSuccess: () {
        _loadHistory();
        _tabController.animateTo(1);
      },
    );
  }

  Color _getLeaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'validate': return Colors.green;
      case 'confirm': return Colors.blue;
      case 'refuse': return Colors.red;
      default: return Colors.orange;
    }
  }
}

class ApplyLeaveForm extends StatefulWidget {
  final String appKey;
  final int employeeId;
  final List<Map<String, dynamic>> allocations;
  final VoidCallback onSuccess;

  const ApplyLeaveForm({
    super.key,
    required this.appKey,
    required this.employeeId,
    required this.allocations,
    required this.onSuccess,
  });

  @override
  State<ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends State<ApplyLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  int? _selectedLeaveTypeId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave type')),
      );
      return;
    }

    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ApiService.applyLeave(
      appKey: widget.appKey,
      employeeId: widget.employeeId,
      leaveTypeId: _selectedLeaveTypeId!,
      fromDate: _fromDate!.toString().substring(0, 10),
      toDate: _toDate!.toString().substring(0, 10),
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Leave request submitted'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _reasonController.clear();
      setState(() {
        _selectedLeaveTypeId = null;
        _fromDate = null;
        _toDate = null;
      });

      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to apply leave'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply for Leave',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _selectedLeaveTypeId,
              decoration: InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category),
              ),
              items: widget.allocations.map((allocation) {
                return DropdownMenuItem<int>(
                  value: allocation['leave_type_id'],
                  child: Text(
                    '${allocation['leave_type']} (${allocation['remaining']} days)',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLeaveTypeId = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'From Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _fromDate != null
                            ? _fromDate!.toString().substring(0, 10)
                            : 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'To Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _toDate != null
                            ? _toDate!.toString().substring(0, 10)
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Submit Leave Request', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


