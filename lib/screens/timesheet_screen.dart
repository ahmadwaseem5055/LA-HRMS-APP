import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _appKey;
  int? _employeeId;
  
  List<Map<String, dynamic>> _timesheets = [];
  List<Map<String, dynamic>> _projects = [];
  Map<String, dynamic>? _summary;
  
  bool _isTracking = false;
  int? _currentLineId;
  String? _currentProjectName;
  String? _currentTaskName;
  DateTime? _trackingStartTime;
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_trackingStartTime != null) {
        final duration = DateTime.now().difference(_trackingStartTime!);
        setState(() {
          _elapsedTime = _formatDuration(duration);
        });
      }
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _appKey = await StorageService.getAppKey();
    _employeeId = await StorageService.getEmployeeId();
    
    if (_appKey != null && _employeeId != null) {
      await Future.wait([
        _loadTimesheets(),
        _loadProjects(),
        _loadSummary(),
      ]);
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _loadTimesheets() async {
    final result = await ApiService.getTimesheetList(_appKey!, _employeeId!);
    
    if (result['success'] == true) {
      setState(() {
        _timesheets = List<Map<String, dynamic>>.from(result['timesheets'] ?? []);
        
        // Check for active tracking
        for (var ts in _timesheets) {
          if (ts['end_time'] == null || ts['end_time'] == 'None') {
            _isTracking = true;
            _currentLineId = ts['line_id'];
            _currentProjectName = ts['project'];
            _currentTaskName = ts['task'];
            
            try {
              _trackingStartTime = DateTime.parse(ts['start_time']);
              _startTimer();
            } catch (e) {
              print('Error parsing start time: $e');
            }
            break;
          }
        }
      });
    }
  }
  
  // FIX: Now passing employee_id
  Future<void> _loadProjects() async {
    final result = await ApiService.getProjectsWithTasks(_appKey!, _employeeId!);
    
    if (result['success'] == true) {
      setState(() {
        _projects = List<Map<String, dynamic>>.from(result['projects'] ?? []);
      });
    }
  }
  
  Future<void> _loadSummary() async {
    final result = await ApiService.getTimesheetSummary(_appKey!, _employeeId!);
    
    if (result['success'] == true) {
      setState(() {
        _summary = {
          'total_hours': result['total_worked_hours'] ?? 0.0,
          'total_entries': _timesheets.length,
          'projects': result['projects'] ?? [],
        };
      });
    }
  }
  
  Future<void> _startTimesheet() async {
    final selection = await _showProjectTaskDialog();
    if (selection == null) return;
    
    final result = await ApiService.startTimesheet(
      _appKey!,
      _employeeId!,
      projectId: selection['project_id'],
      taskId: selection['task_id'],
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      setState(() {
        _isTracking = true;
        _currentLineId = result['line_id'];
        _currentProjectName = selection['project_name'];
        _currentTaskName = selection['task_name'];
        _trackingStartTime = DateTime.now();
        _startTimer();
      });
      
      _showSuccessSnackbar('Timesheet tracking started', Colors.green);
      _loadData();
    } else {
      _showErrorSnackbar(result['error'] ?? 'Failed to start timesheet');
    }
  }
  
  Future<void> _stopTimesheet() async {
    if (_currentLineId == null) return;
    
    final confirm = await _showConfirmDialog(
      'Stop Tracking',
      'Stop tracking time for this task?',
    );
    
    if (confirm != true) return;
    
    // FIX: Using lineId parameter correctly
    final result = await ApiService.stopTimesheet(
      _appKey!,
      _employeeId!,
      lineId: _currentLineId!,
    );
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      _timer?.cancel();
      
      setState(() {
        _isTracking = false;
        _currentLineId = null;
        _currentProjectName = null;
        _currentTaskName = null;
        _trackingStartTime = null;
        _elapsedTime = '00:00:00';
      });
      
      final hours = result['worked_hours'] ?? 0.0;
      _showSuccessSnackbar('Stopped • ${hours}h recorded', Colors.blue);
      _loadData();
    } else {
      _showErrorSnackbar(result['error'] ?? 'Failed to stop timesheet');
    }
  }
  
  Future<Map<String, dynamic>?> _showProjectTaskDialog() async {
    if (_projects.isEmpty) {
      _showErrorSnackbar('No projects available');
      return null;
    }
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProjectTaskDialog(projects: _projects),
    );
  }
  
  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Timesheet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: !isWeb,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          if (isWeb) const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.blue.shade700,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Tracker'),
                    Tab(text: 'History'),
                    Tab(text: 'Summary'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrackerTab(isWeb, isTablet),
                _buildHistoryTab(isWeb, isTablet),
                _buildSummaryTab(isWeb, isTablet),
              ],
            ),
    );
  }
  
  Widget _buildTrackerTab(bool isWeb, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isWeb ? 40 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
            child: Column(
              children: [
                _buildTrackerCard(isWeb),
                const SizedBox(height: 24),
                _buildQuickStatsCard(isWeb),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrackerCard(bool isWeb) {
    return Card(
      elevation: isWeb ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 40 : 24),
        decoration: BoxDecoration(
          gradient: _isTracking
              ? LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isTracking ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isTracking ? Colors.green.shade300 : Colors.grey.shade200,
            width: _isTracking ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (_isTracking) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentProjectName ?? 'Unknown Project',
                          style: TextStyle(
                            fontSize: isWeb ? 22 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentTaskName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _currentTaskName!,
                            style: TextStyle(
                              fontSize: isWeb ? 16 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: EdgeInsets.symmetric(vertical: isWeb ? 32 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _elapsedTime,
                    style: TextStyle(
                      fontSize: isWeb ? 64 : 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: isWeb ? 60 : 56,
                child: ElevatedButton.icon(
                  onPressed: _stopTimesheet,
                  icon: const Icon(Icons.stop_circle, size: 28),
                  label: Text(
                    'Stop Tracking',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.timer_outlined,
                size: isWeb ? 100 : 80,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: isWeb ? 24 : 20),
              Text(
                'No Active Tracking',
                style: TextStyle(
                  fontSize: isWeb ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: isWeb ? 12 : 8),
              Text(
                'Start tracking time on a project task',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isWeb ? 32 : 28),
              SizedBox(
                width: double.infinity,
                height: isWeb ? 60 : 56,
                child: ElevatedButton.icon(
                  onPressed: _startTimesheet,
                  icon: const Icon(Icons.play_circle, size: 28),
                  label: Text(
                    'Start Tracking',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStatsCard(bool isWeb) {
    return Card(
      elevation: isWeb ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Hours',
                    '${_summary?['total_hours'] ?? 0.0}h',
                    Icons.timer_outlined,
                    Colors.blue,
                    isWeb,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Entries',
                    '${_summary?['total_entries'] ?? 0}',
                    Icons.list_alt,
                    Colors.green,
                    isWeb,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isWeb ? 32 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isWeb ? 13 : 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab(bool isWeb, bool isTablet) {
    if (_timesheets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: isWeb ? 80 : 64, color: Colors.grey.shade300),
            SizedBox(height: isWeb ? 20 : 16),
            Text(
              'No timesheet entries yet',
              style: TextStyle(fontSize: isWeb ? 18 : 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
          child: ListView.builder(
            padding: EdgeInsets.all(isWeb ? 40 : 16),
            itemCount: _timesheets.length,
            itemBuilder: (context, index) {
              final entry = _timesheets[index];
              final isActive = entry['end_time'] == null || entry['end_time'] == 'None';
              
              return Card(
                elevation: isWeb ? 1 : 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green.shade300 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(isWeb ? 20 : 16),
                    leading: Container(
                      padding: EdgeInsets.all(isWeb ? 14 : 12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? Icons.play_circle : Icons.check_circle,
                        color: isActive ? Colors.green : Colors.blue.shade700,
                        size: isWeb ? 28 : 24,
                      ),
                    ),
                    title: Text(
                      entry['project'] ?? 'Unknown Project',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWeb ? 16 : 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          entry['task'] ?? 'No task',
                          style: TextStyle(fontSize: isWeb ? 14 : 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry['start_time'] ?? '',
                          style: TextStyle(
                            fontSize: isWeb ? 13 : 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry['hours'] ?? 0.0}h',
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 10 : 8,
                            vertical: isWeb ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Completed',
                            style: TextStyle(
                              fontSize: isWeb ? 11 : 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryTab(bool isWeb, bool isTablet) {
    final projects = _summary?['projects'] as List<dynamic>? ?? [];
    
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: isWeb ? 80 : 64, color: Colors.grey.shade300),
            SizedBox(height: isWeb ? 20 : 16),
            Text(
              'No data to summarize yet',
              style: TextStyle(fontSize: isWeb ? 18 : 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
          child: ListView.builder(
            padding: EdgeInsets.all(isWeb ? 40 : 16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index] as Map<String, dynamic>;
              final tasks = project['tasks'] as List<dynamic>? ?? [];
              
              return Card(
                elevation: isWeb ? 1 : 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.all(isWeb ? 20 : 16),
                  childrenPadding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 20 : 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder_outlined, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    project['project_name'] ?? 'Unknown Project',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 16 : 15,
                    ),
                  ),
                  subtitle: Text(
                    '${project['total_hours'] ?? 0.0} hours total',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isWeb ? 14 : 13,
                    ),
                  ),
                  children: tasks.map<Widget>((task) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 20 : 16,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.task_alt, size: 20),
                      title: Text(
                        task['task_name'] ?? 'Unknown Task',
                        style: TextStyle(fontSize: isWeb ? 15 : 14),
                      ),
                      trailing: Text(
                        '${task['hours'] ?? 0.0}h',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 15 : 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProjectTaskDialog extends StatefulWidget {
  final List<Map<String, dynamic>> projects;
  
  const _ProjectTaskDialog({required this.projects});
  
  @override
  State<_ProjectTaskDialog> createState() => _ProjectTaskDialogState();
}

class _ProjectTaskDialogState extends State<_ProjectTaskDialog> {
  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedTask;
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final tasks = _selectedProject?['tasks'] as List<dynamic>? ?? [];
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isWeb ? 500 : size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: isWeb ? 500 : double.infinity,
          maxHeight: size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start Tracking',
                      style: TextStyle(
                        fontSize: isWeb ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Project',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isWeb ? 16 : 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedProject,
                          isExpanded: true,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Choose a project'),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          borderRadius: BorderRadius.circular(12),
                          items: widget.projects.map((project) {
                            return DropdownMenuItem(
                              value: project,
                              child: Row(
                                children: [
                                  Icon(Icons.folder_outlined, size: 20, color: Colors.blue.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      project['project_name'] ?? 'Unknown',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (project) {
                            setState(() {
                              _selectedProject = project;
                              _selectedTask = null;
                            });
                          },
                        ),
                      ),
                    ),
                    if (tasks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Select Task',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 16 : 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _selectedTask,
                            isExpanded: true,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Choose a task'),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            borderRadius: BorderRadius.circular(12),
                            items: tasks.map<DropdownMenuItem<Map<String, dynamic>>>((task) {
                              return DropdownMenuItem(
                                value: task as Map<String, dynamic>,
                                child: Row(
                                  children: [
                                    Icon(Icons.task_alt, size: 20, color: Colors.green.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        task['task_name'] ?? 'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (task) {
                              setState(() => _selectedTask = task);
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 24 : 20,
                        vertical: isWeb ? 16 : 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: isWeb ? 16 : 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedProject == null || _selectedTask == null
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'project_id': _selectedProject!['project_id'],
                              'project_name': _selectedProject!['project_name'],
                              'task_id': _selectedTask!['task_id'],
                              'task_name': _selectedTask!['task_name'],
                            });
                          },
                    icon: const Icon(Icons.play_circle, size: 20),
                    label: Text(
                      'Start',
                      style: TextStyle(fontSize: isWeb ? 16 : 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 24 : 20,
                        vertical: isWeb ? 16 : 12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}