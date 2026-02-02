// ============================================
// 10. lib/screens/payroll_screen.dart
// ============================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  bool _isLoading = true;
  String? _appKey;
  int? _employeeId;

  String? _payslipName;
  String? _dateFrom;
  String? _dateTo;
  String? _state;
  double _basicSalary = 0;
  double _grossSalary = 0;
  double _netSalary = 0;
  List<Map<String, dynamic>> _lines = [];

  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _appKey = await StorageService.getAppKey();
    _employeeId = await StorageService.getEmployeeId();

    if (_appKey != null && _employeeId != null) {
      await _loadPayroll();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadPayroll() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getPayrollSalary(
      _appKey!,
      _employeeId!,
      month: _selectedMonth,
    );

    if (result['success'] == true && result['payslip'] != null) {
      final payslip = result['payslip'];

      setState(() {
        _payslipName = payslip['name'];
        _dateFrom = payslip['date_from'];
        _dateTo = payslip['date_to'];
        _state = payslip['state'];
        _basicSalary = (payslip['basic_salary'] ?? 0).toDouble();
        _grossSalary = (payslip['gross_salary'] ?? 0).toDouble();
        _netSalary = (payslip['net_salary'] ?? 0).toDouble();
        _lines = List<Map<String, dynamic>>.from(payslip['lines'] ?? []);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'No payslip found'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return {
        'label': '${_getMonthName(date.month)} ${date.year}',
        'value': '${date.year}-${date.month.toString().padLeft(2, '0')}',
      };
    });

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('Select Month'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = _selectedMonth == month['value'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    month['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue.shade700 : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle, color: Colors.blue.shade700) : null,
                  onTap: () => Navigator.pop(context, month['value']),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _selectedMonth = selected);
      _loadPayroll();
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, size: isWeb ? 28 : 24),
            const SizedBox(width: 12),
            const Text('Payroll'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedMonth != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _selectedMonth!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayroll,
            tooltip: 'Refresh',
          ),
          if (isWeb) const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue.shade700),
                  const SizedBox(height: 16),
                  Text(
                    'Loading payroll data...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
          : _payslipName == null
              ? Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Payslip Available',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payslip found for the selected period. Try searching for other months.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _selectMonth,
                          icon: const Icon(Icons.search),
                          label: const Text('Search Other Months'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayroll,
                  color: Colors.blue.shade700,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isWeb ? 32 : 16),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                        child: Column(
                          children: [
                            _buildHeader(isWeb, isTablet),
                            const SizedBox(height: 24),
                            _buildSummaryCards(isWeb, isTablet),
                            const SizedBox(height: 24),
                            _buildDetailsSection(isWeb, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader(bool isWeb, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.white.withOpacity(0.9), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _payslipName ?? '',
                                style: TextStyle(
                                  fontSize: isWeb ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.white.withOpacity(0.8), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Period: $_dateFrom to $_dateTo',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isWeb ? 14 : 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _state == 'paid' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_state == 'paid' ? Colors.green : Colors.orange).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _state == 'paid' ? Icons.check_circle : Icons.pending,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _state?.toUpperCase() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isWeb, bool isTablet) {
    if (isWeb) {
      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard('Basic Salary', _basicSalary, Icons.account_balance_wallet, 
                Colors.blue.shade700, Colors.blue.shade50),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildSummaryCard('Gross Salary', _grossSalary, Icons.trending_up, 
                Colors.green.shade700, Colors.green.shade50),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildSummaryCard('Net Salary', _netSalary, Icons.payments, 
                Colors.purple.shade700, Colors.purple.shade50),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Basic', _basicSalary, Icons.account_balance_wallet, 
                    Colors.blue.shade700, Colors.blue.shade50),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard('Gross', _grossSalary, Icons.trending_up, 
                    Colors.green.shade700, Colors.green.shade50),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard('Net Salary', _netSalary, Icons.payments, 
              Colors.purple.shade700, Colors.purple.shade50, isLarge: true),
        ],
      );
    }
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color, Color bgColor, {bool isLarge = false}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [bgColor, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isLarge ? 24 : 20),
          child: Column(
            crossAxisAlignment: isLarge ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isLarge ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: isLarge ? 28 : 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isLarge ? 16 : 12),
              Text(
                'PKR ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isLarge ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(bool isWeb, bool isTablet) {
    if (_lines.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Salary Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isWeb)
              _buildDetailsTable()
            else
              _buildDetailsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTable() {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade200),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          children: [
            _buildTableHeader('Description'),
            _buildTableHeader('Code'),
            _buildTableHeader('Amount', align: TextAlign.right),
          ],
        ),
        ..._lines.map((line) {
          final amount = (line['amount'] ?? 0).toDouble();
          final isDeduction = amount < 0;

          return TableRow(
            children: [
              _buildTableCell(line['name'] ?? ''),
              _buildTableCell(line['code'] ?? 'N/A'),
              _buildTableCell(
                '${isDeduction ? '-' : ''}PKR ${amount.abs().toStringAsFixed(2)}',
                align: TextAlign.right,
                color: isDeduction ? Colors.red : Colors.green,
                bold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {TextAlign align = TextAlign.left, Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 14,
          color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDetailsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lines.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 24),
      itemBuilder: (context, index) {
        final line = _lines[index];
        final amount = (line['amount'] ?? 0).toDouble();
        final isDeduction = amount < 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDeduction ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line['name'] ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          line['code'] ?? 'N/A',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDeduction ? '-' : '+'}PKR ${amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDeduction ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}