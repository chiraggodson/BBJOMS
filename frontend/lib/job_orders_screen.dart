import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'services/api_service.dart';

const _bg = BBTheme.canvas;
const _panel = BBTheme.panel;
const _panel2 = BBTheme.black3;
const _border = BBTheme.border;
const _muted = BBTheme.muted;
const _accent = BBTheme.red;

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final String? action;

  const _Card({
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Stat(
    this.title,
    this.value,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final String text;

  const _Status(this.text);

  @override
  Widget build(BuildContext context) {
    Color c = _muted;

    if (text == 'Running' ||
        text == 'Open' ||
        text == 'Available') {
      c = BBTheme.green;
    }

    if (text == 'Yarn Needed' ||
        text == 'Low Stock') {
      c = const Color(0xFFF87171);
    }

    if (text == 'Paused' ||
        text == 'Pending') {
      c = const Color(0xFFFBBF24);
    }

    if (text == 'Closed' ||
        text == 'Complete') {
      c = const Color(0xFFA78BFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.isEmpty ? 'Unknown' : text,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class JobOrdersPage extends StatefulWidget {
  const JobOrdersPage({
    super.key,
  });

  @override
  State<JobOrdersPage> createState() => _JobOrdersPageState();
}

class _JobOrdersPageState extends State<JobOrdersPage> {
  final ApiService _apiService = ApiService();

  final TextEditingController _searchController =
      TextEditingController();

  List<JobOrder> _jobs = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final jobs = await _apiService.getJobs();

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<JobOrder> get _filteredJobs {
    final query =
        _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _jobs;
    }

    return _jobs.where((job) {
      return job.jobNo.toLowerCase().contains(query) ||
          job.partyName.toLowerCase().contains(query) ||
          job.fabricName.toLowerCase().contains(query) ||
          job.machineNo.toLowerCase().contains(query) ||
          job.status.toLowerCase().contains(query) ||
          job.gsm.toString().contains(query);
    }).toList();
  }

  int get _activeJobs {
    return _jobs.where(
      (job) => job.status.toLowerCase() != 'closed',
    ).length;
  }

  int get _runningJobs {
    return _jobs.where(
      (job) => job.status.toLowerCase() == 'running',
    ).length;
  }

  int get _yarnNeededJobs {
    return _jobs.where(
      (job) => job.status.toLowerCase() == 'yarn needed',
    ).length;
  }

  int get _closedJobs {
    return _jobs.where(
      (job) => job.status.toLowerCase() == 'closed',
    ).length;
  }

  Future<void> _openJob(JobOrder job) async {
    try {
      final details =
          await _apiService.getJobDetails(job.id);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => _JobDetailsDialog(
          details: details,
        ),
      );

      await _loadJobs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open job: $error',
          ),
          backgroundColor: const Color(0xFF7A2525),
        ),
      );
    }
  }

Future<void> _openNewJob() async {
  final created = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NewJobOrderDialog(
      apiService: _apiService,
    ),
  );

  if (created == true && mounted) {
    await _loadJobs();
  }
}
  @override
  Widget build(BuildContext context) {
    final jobs = _filteredJobs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Orders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Create, track and manage knitting job orders',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed:
                    _loading ? null : _loadJobs,
                tooltip: 'Refresh',
                icon:
                    const Icon(Icons.refresh),
              ),

              const SizedBox(width: 8),

              FilledButton.icon(
                onPressed: _openNewJob,
                icon: const Icon(
                  Icons.add_task,
                  size: 18,
                ),
                label:
                    const Text('New Job Order'),
                style:
                    FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (_, constraints) {
              final cards = [
                _Stat(
                  'Active Jobs',
                  _activeJobs.toString(),
                  Icons.assignment_outlined,
                ),
                _Stat(
                  'Running',
                  _runningJobs.toString(),
                  Icons.play_circle_outline,
                ),
                _Stat(
                  'Yarn Needed',
                  _yarnNeededJobs.toString(),
                  Icons.warning_amber_outlined,
                ),
                _Stat(
                  'Closed',
                  _closedJobs.toString(),
                  Icons.check_circle_outline,
                ),
              ];

              if (constraints.maxWidth < 760) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width:
                              (constraints.maxWidth -
                                      12) /
                                  2,
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: cards
                    .map(
                      (card) => Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                            right: 12,
                          ),
                          child: card,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          _Card(
            title: 'Job Order Register',
            child: Column(
              children: [
                TextField(
                  controller:
                      _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Search job, party, fabric, machine or status...',
                    prefixIcon:
                        const Icon(
                      Icons.search,
                      size: 20,
                    ),
                    suffixIcon:
                        _searchController
                                .text
                                .isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController
                                      .clear();
                                  setState(() {});
                                },
                                icon:
                                    const Icon(
                                  Icons.clear,
                                  size: 18,
                                ),
                              ),
                    filled: true,
                    fillColor: _panel2,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              9),
                      borderSide:
                          const BorderSide(
                        color:
                            BBTheme.border,
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              9),
                      borderSide:
                          const BorderSide(
                        color:
                            BBTheme.border,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              9),
                      borderSide:
                          const BorderSide(
                        color: _accent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_loading)
                  const Padding(
                    padding:
                        EdgeInsets.all(50),
                    child:
                        CircularProgressIndicator(
                      color: _accent,
                    ),
                  )
                else if (_error != null)
                  _ErrorState(
                    message: _error!,
                    onRetry: _loadJobs,
                  )
                else if (jobs.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .assignment_outlined,
                          size: 42,
                          color:
                              Color(0xFF53616D),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No job orders found',
                          style: TextStyle(
                            color:
                                Color(0xFF9BA7B2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _JobTable(
                    jobs: jobs,
                    onOpen: _openJob,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTable extends StatelessWidget {
  final List<JobOrder> jobs;
  final Future<void> Function(JobOrder) onOpen;

  const _JobTable({
    required this.jobs,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: jobs.map((job) {
              return InkWell(
                onTap: () => onOpen(job),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  decoration:
                      const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            Color(0xFF1D2933),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor:
                            Color(0xFF153A38),
                        child: Icon(
                          Icons
                              .assignment_outlined,
                          color: _accent,
                          size: 17,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              job.jobNo,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                                height: 3),
                            Text(
                              job.partyName,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                                height: 3),
                            Text(
                              job.fabricName,
                              style:
                                  const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(
                                height: 3),
                            Text(
                              'Machine: ${job.machineNo.isEmpty ? '—' : job.machineNo}',
                              style:
                                  const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatNumber(job.orderQuantity)} kg',
                            style:
                                const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(
                              height: 4),
                          _Status(job.status),
                        ],
                      ),

                      const Icon(
                        Icons.chevron_right,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _panel2,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Job',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Party / Fabric',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Machine',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty / Produced',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Remaining',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style:
                          _TableHeaderStyle.style,
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),

            ...jobs.map(
              (job) => InkWell(
                onTap: () => onOpen(job),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration:
                      const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            Color(0xFF1D2933),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              job.jobNo,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                                height: 3),
                            Text(
                              _formatDateFromString(
                                  job.createdAt),
                              style:
                                  const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              job.partyName,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                                height: 3),
                            Text(
                              job.fabricName,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          job.machineNo.isEmpty
                              ? '—'
                              : job.machineNo,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_formatNumber(job.orderQuantity)} / ${_formatNumber(job.actualProduction)} kg',
                          style:
                              const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Text(
                          '${_formatNumber(job.remainingQuantity)} kg',
                          style:
                              const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child:
                            _Status(job.status),
                      ),

                      IconButton(
                        onPressed:
                            () => onOpen(job),
                        tooltip: 'Open Job',
                        icon: const Icon(
                          Icons.chevron_right,
                          color: _muted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JobDetailsDialog extends StatelessWidget {
  final JobDetails details;

  const _JobDetailsDialog({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final job = details.job;

    return Dialog(
      backgroundColor: _bg,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 980,
          maxHeight: 820,
        ),
        child: Column(
          children: [
            _buildHeader(context, job),
            const Divider(height: 1, color: _border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeading(
                      'JOB INFORMATION',
                      Icons.assignment_outlined,
                    ),
                    const SizedBox(height: 12),
                    _detailGrid([
                      _DetailItem('Job No.', job.jobNo, emphasis: true),
                      _DetailItem(
                        'Date Created',
                        _formatDateFromString(job.createdAt),
                      ),
                      _DetailItem('Party', job.partyName),
                      _DetailItem('Fabric', job.fabricName),
                      _DetailItem('GSM', _formatNumber(job.gsm)),
                      _DetailItem(
                        'Order Quantity',
                        '${_formatNumber(job.orderQuantity)} kg',
                      ),
                      _DetailItem(
                        'Machine',
                        job.machineNo.isEmpty ? '—' : job.machineNo,
                      ),
                    ]),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      'PRODUCTION',
                      Icons.factory_outlined,
                    ),
                    const SizedBox(height: 12),
                    _detailGrid([
                      _MetricItem(
                        'Produced',
                        '${_formatNumber(job.actualProduction)} kg',
                        Icons.check_circle_outline,
                      ),
                      _MetricItem(
                        'Remaining',
                        '${_formatNumber(job.remainingQuantity)} kg',
                        Icons.timelapse_outlined,
                      ),
                      _MetricItem(
                        'Average Roll Size',
                        '${_formatNumber(job.avgRollSize)} kg',
                        Icons.scale_outlined,
                      ),
                      _MetricItem(
                        'Status',
                        job.status.isEmpty ? 'Unknown' : job.status,
                        Icons.flag_outlined,
                      ),
                    ]),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      'YARN USED',
                      Icons.layers_outlined,
                    ),
                    const SizedBox(height: 12),
                    _YarnUsedCard(
                      yarns: details.yarns,
                      fallback: job.yarnsUsed,
                    ),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      'ASSIGNED MACHINES',
                      Icons.precision_manufacturing_outlined,
                    ),
                    const SizedBox(height: 12),
                    _MachineList(
                      machineIds: details.machineIds,
                    ),

                    const SizedBox(height: 26),

                    _sectionHeading(
                      'YARN REQUIREMENTS',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 12),
                    _YarnRequirements(
                      jobNo: job.jobNo,
                      yarns: details.yarns,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JobOrder job) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 18, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accent.withValues(alpha: .28),
              ),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: _accent,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobNo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.partyName.isEmpty
                      ? 'Job Order Details'
                      : job.partyName,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _Status(job.status),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 17),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: _border,
          ),
        ),
      ],
    );
  }

  Widget _detailGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 500
                ? 2
                : 1;
        final gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: item,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _DetailItem(
    this.label,
    this.value, {
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasis ? Colors.white : Colors.white,
              fontSize: 14,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem(
    this.label,
    this.value,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YarnUsedCard extends StatelessWidget {
  final List<JobYarnRequirement> yarns;
  final String fallback;

  const _YarnUsedCard({
    required this.yarns,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final names = yarns
        .map(
          (yarn) => yarn.yarnName.isEmpty
              ? 'Yarn ${yarn.yarnId}'
              : yarn.yarnName,
        )
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (names.isEmpty) {
      return _EmptyDetailCard(
        fallback.isEmpty ? 'No yarn usage recorded.' : fallback,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: names.map((name) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _accent.withValues(alpha: .24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.circle,
                  size: 6,
                  color: _accent,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MachineList extends StatelessWidget {
  final List<int> machineIds;

  const _MachineList({
    required this.machineIds,
  });

  @override
  Widget build(BuildContext context) {
    if (machineIds.isEmpty) {
      return const _EmptyDetailCard(
        'No machine assignment data.',
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: machineIds.map((id) {
        return Container(
          constraints: const BoxConstraints(minWidth: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.precision_manufacturing_outlined,
                color: _muted,
                size: 17,
              ),
              const SizedBox(width: 9),
              Text(
                'Machine $id',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _YarnRequirements extends StatefulWidget {
  final String jobNo;
  final List<JobYarnRequirement> yarns;

  const _YarnRequirements({
    required this.jobNo,
    required this.yarns,
  });

  @override
  State<_YarnRequirements> createState() => _YarnRequirementsState();
}

class _YarnRequirementsState extends State<_YarnRequirements> {
  final ApiService _apiService = ApiService();

  Map<String, double> _issuedByYarn = {};
  bool _loadingIssued = true;

  @override
  void initState() {
    super.initState();
    _loadIssued();
  }

  Future<void> _loadIssued() async {
    try {
      final history = await _apiService.getJobYarnHistory(widget.jobNo);

      final issued = <String, double>{};

      for (final entry in history) {
        final type = entry.transactionType.trim().toLowerCase();

        // The yarn history endpoint is the source of actual yarn
        // movement. Count ISSUE/ISSUED transactions as yarn issued.
        if (!type.contains('issue')) {
          continue;
        }

        final key = _yarnKey(entry.yarnName);
        if (key.isEmpty) continue;

        issued[key] = (issued[key] ?? 0) + entry.quantity;
      }

      if (!mounted) return;

      setState(() {
        _issuedByYarn = issued;
        _loadingIssued = false;
      });
    } catch (_) {
      // Keep the requirements table usable if yarn history is not
      // available. If the backend already supplies issuedQuantity,
      // that value will still be used below.
      if (!mounted) return;

      setState(() {
        _loadingIssued = false;
      });
    }
  }

  String _yarnKey(String value) {
    return value.trim().toLowerCase();
  }

  double _issuedFor(JobYarnRequirement yarn) {
    if (yarn.issuedQuantity != null) {
      return yarn.issuedQuantity!;
    }

    final name = yarn.yarnName.isEmpty
        ? 'Yarn ${yarn.yarnId}'
        : yarn.yarnName;

    return _issuedByYarn[_yarnKey(name)] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.yarns.isEmpty) {
      return const _EmptyDetailCard(
        'No yarn requirements recorded.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _panel2,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'YARN',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REQUIRED',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ISSUED',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'BALANCE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(widget.yarns.length, (index) {
            final yarn = widget.yarns[index];

            final name = yarn.yarnName.isEmpty
                ? 'Yarn ${yarn.yarnId}'
                : yarn.yarnName;

            final required = yarn.quantity ?? 0;
            final issued = _issuedFor(yarn);
            final balance = required - issued;

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _border.withValues(alpha: .75),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      required <= 0
                          ? '—'
                          : '${_formatNumber(required)} kg',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _loadingIssued
                          ? '—'
                          : '${_formatNumber(issued)} kg',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _loadingIssued
                          ? '—'
                          : '${_formatNumber(balance)} kg',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: balance < 0
                            ? const Color(0xFFF87171)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyDetailCard extends StatelessWidget {
  final String text;

  const _EmptyDetailCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFFB66A6A),
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load job orders',
            style: TextStyle(
              color: Color(0xFFE0A0A0),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NewJobOrderDialog extends StatefulWidget {
  final ApiService apiService;

  const _NewJobOrderDialog({
    required this.apiService,
  });

  @override
  State<_NewJobOrderDialog> createState() =>
      _NewJobOrderDialogState();
}

class _NewJobOrderDialogState
    extends State<_NewJobOrderDialog> {
  List<Party> _parties = [];
  List<Fabric> _fabrics = [];
  List<Machine> _machines = [];
  List<YarnMaster> _yarns = [];

  Party? _selectedParty;
  Fabric? _selectedFabric;

  final _gsmController = TextEditingController();
  final _quantityController = TextEditingController();

  final Set<int> _selectedMachineIds = {};
  final List<_SelectedJobYarn> _selectedYarns = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  @override
  void dispose() {
    _gsmController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadMasters() async {
    try {
      final results = await Future.wait([
        widget.apiService.getParties(active: true),
        widget.apiService.getFabrics(),
        widget.apiService.getMachines(),
        widget.apiService.getYarns(),
      ]);

      if (!mounted) return;

      setState(() {
        _parties = results[0] as List<Party>;
        _fabrics = results[1] as List<Fabric>;
        _machines = results[2] as List<Machine>;
        _yarns = results[3] as List<YarnMaster>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _createJob() async {
    if (_selectedParty == null) {
      _showError('Please select a party.');
      return;
    }

    if (_selectedFabric == null) {
      _showError('Please select a fabric.');
      return;
    }

    final gsm = double.tryParse(
      _gsmController.text.trim(),
    );

    if (gsm == null || gsm <= 0) {
      _showError('Enter a valid GSM.');
      return;
    }

    final quantity = double.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null || quantity <= 0) {
      _showError('Enter a valid order quantity.');
      return;
    }

    if (_selectedMachineIds.isEmpty) {
      _showError('Select at least one machine.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final fabricId = int.tryParse(_selectedFabric!.id);

      if (fabricId == null) {
        if (mounted) {
          setState(() {
            _saving = false;
          });
        }
        _showError('Selected fabric has an invalid ID.');
        return;
      }

      final jobYarns = _selectedYarns
    .where(
      (item) =>
          item.yarn != null &&
          item.quantity != null &&
          item.quantity! > 0,
    )
    .map(
      (item) => JobYarnRequirement(
        yarnId: item.yarn!.id,
        quantity: item.quantity,
      ),
    )
    .toList();

      final jobNumbers =
          await widget.apiService.createJob(
        partyId: _selectedParty!.id,
        fabricId: fabricId,
        gsm: gsm,
        orderQuantity: quantity,
        machineIds: _selectedMachineIds.toList(),
        yarns: jobYarns,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            jobNumbers.length == 1
                ? 'Job ${jobNumbers.first} created successfully.'
                : '${jobNumbers.length} job orders created successfully.',
          ),
          backgroundColor: _accent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7A2525),
      ),
    );
  }

  void _addYarn() {
  if (_yarns.isEmpty) return;

  final available = _yarns.where(
    (yarn) => !_selectedYarns.any(
      (selected) => selected.yarn?.id == yarn.id,
    ),
  );

  if (available.isEmpty) {
    _showError('All available yarns are already added.');
    return;
  }

  setState(() {
    _selectedYarns.add(
      _SelectedJobYarn(
        yarn: null,
      ),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _panel,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 820,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(
              height: 1,
              color: _border,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        16,
        18,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'New Job Order',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create a new knitting job order',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 45,
              color: Color(0xFFB66A6A),
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load job master data',
              style: TextStyle(
                color: Color(0xFFE0A0A0),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadMasters();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle('Job Information'),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth >= 650
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: _dropdown<Party>(
                      label: 'Party *',
                      value: _selectedParty,
                      items: _parties,
                      itemLabel: (party) =>
                          '${party.name} (${party.partyCode})',
                      onChanged: (value) {
                        setState(() {
                          _selectedParty = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown<Fabric>(
                      label: 'Fabric *',
                      value: _selectedFabric,
                      items: _fabrics,
                      itemLabel: (fabric) => fabric.name,
                      onChanged: (value) {
                        setState(() {
                          _selectedFabric = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _textField(
                      controller: _gsmController,
                      label: 'GSM *',
                      hint: 'Example: 180',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _textField(
                      controller: _quantityController,
                      label: 'Order Quantity (kg) *',
                      hint: 'Example: 1000',
                      
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                        
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          _sectionTitle('Machines'),
          const SizedBox(height: 6),
          const Text(
            'Select one or more machines. The backend will create the required job orders.',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          if (_machines.isEmpty)
            const Text(
              'No machines available.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _machines.map((machine) {
                final selected =
                    _selectedMachineIds.contains(machine.id);

                return FilterChip(
                  selected: selected,
                  label: Text(machine.machineNo),
                  avatar: Icon(
                    selected
                        ? Icons.check
                        : Icons.precision_manufacturing_outlined,
                    size: 16,
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedMachineIds.add(machine.id);
                      } else {
                        _selectedMachineIds.remove(machine.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _sectionTitle('Yarn Requirements'),
              ),
              OutlinedButton.icon(
                onPressed: _addYarn,
                icon: const Icon(
                  Icons.add,
                  size: 17,
                ),
                label: const Text('Add Yarn'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_selectedYarns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _panel2,
                borderRadius:
                    BorderRadius.circular(9),
                border:
                    Border.all(color: _border),
              ),
              child: const Text(
                'No yarn requirements added.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            )
                    else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._selectedYarns.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildYarnRow(item),
                  );
                }),

                Builder(
                  builder: (context) {
                    final totalYarnPercentage =
                        _selectedYarns.fold<double>(
                      0,
                      (total, item) =>
                          total + (item.percentage ?? 0),
                    );

                    final isComplete =
                        (totalYarnPercentage - 100).abs() < 0.001;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _panel2,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isComplete
                              ? BBTheme.green
                              : _border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Total Yarn %',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_formatNumber(totalYarnPercentage)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isComplete
                                  ? BBTheme.green
                                  : const Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isComplete
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_outlined,
                            size: 18,
                            color: isComplete
                                ? BBTheme.green
                                : const Color(0xFFFBBF24),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _saving
                        ? null
                        : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed:
                    _saving ? null : _createJob,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        size: 18,
                      ),
                label: Text(
                  _saving
                      ? 'Creating...'
                      : 'Create Job Order',
                ),
                style:
                    FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYarnRow(
  _SelectedJobYarn item,
) {
  final quantityController = TextEditingController(
    text: item.percentage == null
        ? ''
        : _formatNumber(item.percentage!),
  );

  final selectedYarnIds = _selectedYarns
      .where(
        (selected) =>
            selected != item && selected.yarn != null,
      )
      .map(
        (selected) => selected.yarn!.id,
      )
      .toSet();

  final orderQuantity = double.tryParse(
    _quantityController.text.trim(),
  ) ?? 0;

  final calculatedKg =
      orderQuantity > 0 && item.percentage != null
          ? orderQuantity * item.percentage! / 100
          : null;

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _panel2,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<YarnMaster>(
            value: item.yarn,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Yarn',
              isDense: true,
            ),
            hint: const Text('Select yarn'),
            items: _yarns
                .where(
                  (yarn) =>
                      !selectedYarnIds.contains(yarn.id) ||
                      yarn.id == item.yarn?.id,
                )
                .map(
                  (yarn) => DropdownMenuItem<YarnMaster>(
                    value: yarn,
                    child: Text(
                      '${yarn.yarnName} • ${yarn.yarnCount}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                item.yarn = value;
              });
            },
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 100,
          child: TextField(
            controller: quantityController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (value) {
              final percentage =
                  double.tryParse(value);

              setState(() {
                item.percentage = percentage;

                item.quantity =
                    orderQuantity > 0 &&
                            percentage != null
                        ? orderQuantity *
                            percentage /
                            100
                        : null;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Yarn %',
              suffixText: '%',
              isDense: true,
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 120,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Required kg',
              isDense: true,
            ),
            child: Text(
              calculatedKg == null
                  ? '—'
                  : '${_formatNumber(calculatedKg)} kg',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        IconButton(
          tooltip: 'Remove yarn',
          onPressed: () {
            setState(() {
              _selectedYarns.remove(item);
            });
          },
          icon: const Icon(
            Icons.delete_outline,
            color: Color(0xFFE57373),
          ),
        ),
      ],
    ),
  );
}

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _panel2,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: BBTheme.border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: BBTheme.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: _accent,
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _panel2,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: BBTheme.border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: BBTheme.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(9),
          borderSide:
              const BorderSide(
            color: _accent,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _SelectedJobYarn {
   YarnMaster? yarn;

  double? percentage;
  double? quantity;

  _SelectedJobYarn({
    required this.yarn,
        this.percentage,
        this.quantity,
  });
}

class _TableHeaderStyle {
  static const style = TextStyle(
    color: _muted,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String _formatDateFromString(
    String value) {
  if (value.isEmpty) {
    return '—';
  }

  try {
    final date =
        DateTime.parse(value);

    final day = date.day
        .toString()
        .padLeft(2, '0');

    final month = date.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${date.year}';
  } catch (_) {
    return value;
  }
}