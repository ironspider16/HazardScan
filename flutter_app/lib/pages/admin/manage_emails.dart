import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:kkhazardscan/supabase_client.dart';
import 'package:kkhazardscan/widgets/App_Textfield.dart';
import 'package:kkhazardscan/widgets/Universal_appbar.dart';
import 'package:kkhazardscan/Design/style_constant.dart';
import '../../widgets/Menu_button.dart';

class ManageEmailsPage extends StatefulWidget {
  const ManageEmailsPage({super.key});

  @override
  State<ManageEmailsPage> createState() => _ManageEmailsPageState();
}

class _ManageEmailsPageState extends State<ManageEmailsPage> {
  List<Map<String, dynamic>> _emails = [];
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _selectedGroups = [];
  bool _isLoading = true;

  // Track selected rows by id for stable unique identification during modifications
  final Set<int> _selectedIds = {};

  // Verify whether the app bar should switch to batch actions view
  bool get _isSelectionMode => _selectedIds.isNotEmpty;
  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$",
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _fetchEmails();
    _fetchAllGroups();
  }

  Future<void> _fetchAllGroups() async {
    try {
      final data = await supabase
          .from("email_groups")
          .select("id, name")
          .order('name', ascending: true);
      setState(() {
        _allGroups = (data as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching groups : $e");
    }
  }

  // Fetch email rows ordered alphabetically from the database
  Future<void> _fetchEmails() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('emails')
          .select('''
          id,
          email,
          is_immediate,
          email_group_join_table (
            email_groups (
              id,
              name
            )
          )
        ''')
          .order('email', ascending: true);
      setState(() => _emails = List<Map<String, dynamic>>.from(data));
      debugPrint(_emails.toString());
    } catch (e) {
      debugPrint("Error fetching emails: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Handle individual row clicks depending on the active layout state
  void _handleRowTap(int id) {
    if (_isSelectionMode) {
      _toggleSelection(id);
    }
  }

  // Change individual row selection status with tactile haptic feedback
  void _toggleSelection(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Cancel multi-select state safely
  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  // Change immediate status for a single email row using optimistic UI updates
  Future<void> _toggleSingleImmediate(int id, bool currentStatus) async {
    final bool targetStatus = !currentStatus;

    setState(() {
      final index = _emails.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        _emails[index]['is_immediate'] = targetStatus;
      }
    });

    try {
      await supabase
          .from('emails')
          .update({'is_immediate': targetStatus})
          .eq('id', id);
    } catch (e) {
      debugPrint("Error updating row status: $e");
      _fetchEmails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update notification setting: $e")),
        );
      }
    }
  }

  // Modify immediate configuration flags across all selected rows simultaneously
  Future<void> _bulkUpdateImmediate(bool targetStatus) async {
    if (_selectedIds.isEmpty) return;
    debugPrint(_selectedIds.toString());

    setState(() => _isLoading = true);
    final List<int> targets = _selectedIds.toList();
    _clearSelection();

    try {
      await supabase
          .from('emails')
          .update({'is_immediate': targetStatus})
          .inFilter('id', targets);

      await _fetchEmails();
    } catch (e) {
      debugPrint("Bulk status update exception: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to execute bulk update: $e")),
        );
      }
    }
  }

  Future<void> _bulkAddGroupToEmails(int groupId) async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isLoading = true);

    final List<int> targets = _selectedIds.toList();

    final List<Map<String, dynamic>> rowsToInsert = targets
        .map(
          (emailId) => <String, dynamic>{
            'email_id': emailId,
            'group_id': groupId,
          },
        )
        .toList();

    try {
      await supabase.from('email_group_join_table').upsert(rowsToInsert);

      _clearSelection();
      await _fetchEmails();
    } catch (e) {
      debugPrint("Bulk status update exception: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to execute bulk update: $e")),
        );
      }
    }
  }

  Future<void> _deleteGroup(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Verification"),
        content: Text(
          "Are you sure you want to permanently delete this group?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('email_groups').delete().eq('id', id);
      _selectedGroups.removeWhere((group) => group['id'] == id);
      await _fetchEmails();
      await _fetchAllGroups();
    } catch (e) {
      debugPrint("Bulk deletion operation failure: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process bulk erasure: $e")),
        );
      }
    }
  }

  // Erase all selected email entities matching active selection lists
  Future<void> _bulkDeleteEmails() async {
    if (_selectedIds.isEmpty) return;

    // FIXED: Restored missing confirmation dialogue logic
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Verification"),
        content: Text(
          "Are you sure you want to permanently clear ${_selectedIds.length} selected address records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final List<int> targets = _selectedIds.toList();
    _clearSelection();

    try {
      await supabase.from('emails').delete().inFilter('id', targets);
      await _fetchEmails();
    } catch (e) {
      debugPrint("Bulk deletion operation failure: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process bulk erasure: $e")),
        );
      }
    }
  }

  Future<void> _removeGroupFromEmail(int emailId, int groupId) async {
    setState(() => _isLoading = true);

    try {
      await supabase
          .from('email_group_join_table')
          .delete()
          .eq('email_id', emailId)
          .eq('group_id', groupId);
      await _fetchEmails();
    } catch (e) {
      debugPrint("Error removing group association: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove group link: $e")),
        );
      }
    }
  }

  // Open overlay dialog form to create a new supervisor record
  void _showAddEmailDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Add Email",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextfield(
              hint: "Enter valid supervisor email",
              label: "Email Address",
              controller: controller,
              islabel: false,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: MenuButton(
                  onTap: () => Navigator.pop(context, false),
                  label: "Cancel",
                  height: 44,
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  isPrimary: true,
                  onTap: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty || !(emailRegex.hasMatch(text))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a valid email."),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      await supabase.from('emails').insert({
                        'email': text,
                        'is_immediate': false,
                      });
                      await _fetchEmails();
                    } catch (e) {
                      debugPrint("Database storage failure: $e");
                      setState(() => _isLoading = false);
                    }
                  },
                  label: 'Save',
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Open overlay dialogue configured to edit a target row record
  void _showEditEmailDialog(Map<String, dynamic> emailItem) {
    final int id = emailItem['id'];
    final String initialEmail = emailItem['email'] ?? '';
    final TextEditingController controller = TextEditingController(
      text: initialEmail,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Edit email",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextfield(
              hint: "Update email",
              label: "Email Address",
              islabel: false,
              controller: controller,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: MenuButton(
                  onTap: () => Navigator.pop(context, false),
                  label: "Cancel",
                  height: 44,
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  isPrimary: true,
                  onTap: () async {
                    final updatedText = controller.text.trim();
                    if (updatedText.isEmpty ||
                        !(emailRegex.hasMatch(updatedText))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a valid email."),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    try {
                      await supabase
                          .from('emails')
                          .update({'email': updatedText})
                          .eq('id', id);
                      _fetchEmails();
                    } catch (e) {
                      debugPrint("Database update transactional failure: $e");
                      setState(() => _isLoading = false);
                    }
                  },
                  label: 'Save',
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEmailGroupDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Add Email Group",
          style: AppTypography.Blackheading.copyWith(fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextfield(
              hint: "Enter Group Name",
              label: "Group Name",
              controller: controller,
              islabel: false,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: MenuButton(
                  onTap: () => Navigator.pop(context, false),
                  label: "Cancel",
                  height: 44,
                ),
              ),
              const SizedBox(width: AppPadding.tight),
              Expanded(
                child: MenuButton(
                  isPrimary: true,
                  onTap: () async {
                    final text = controller.text.trim();
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      await supabase.from('email_groups').insert({
                        'name': text,
                      });
                      await _fetchAllGroups();
                      _fetchEmails();
                    } catch (e) {
                      debugPrint("Database storage failure: $e");
                      setState(() => _isLoading = false);
                    }
                  },
                  label: 'Save',
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filteredEmails = _selectedGroups.isEmpty
        ? _emails
        : _emails.where((email) {
            final joinTable = email['email_group_join_table'] as List?;
            if (joinTable == null) return false;
            return joinTable.any((join) {
              final group = join['email_groups'];
              if (group == null) return false;
              final groupId = group['id'];
              return _selectedGroups.any(
                (selected) => selected['id'] == groupId,
              );
            });
          }).toList();
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: AppColors.primaryBlue,
              elevation: 2,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearSelection,
              ),
              title: Text(
                "${_selectedIds.length} Selected",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: "Set Selected to Immediate",
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  onPressed: () => _bulkUpdateImmediate(true),
                ),
                IconButton(
                  tooltip: "Remove Immediate Flag",
                  icon: const Icon(Icons.flash_off, color: Colors.white70),
                  onPressed: () => _bulkUpdateImmediate(false),
                ),
                IconButton(
                  tooltip: "Delete Selected Records",
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _bulkDeleteEmails,
                ),
                const SizedBox(width: 8),
              ],
            )
          : (UniversalAppBar(
                  title: "Manage Emails",
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      iconSize: 20,
                      color: AppColors.primaryBlue,
                      tooltip: 'Explain',
                      onPressed: () => _showExplanation(context),
                    ),
                  ],
                )
                as PreferredSizeWidget),
      body: SafeArea(
        child: Padding(
          padding: isMobile(context)
              ? EdgeInsets.symmetric(
                  vertical: AppPadding.tight,
                  horizontal: AppPadding.page,
                )
              : EdgeInsetsGeometry.all(AppPadding.page),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _emails.isEmpty
                    ? const Center(
                        child: Text(
                          "No administrator contacts discovered.",
                          style: AppTypography.Blacksubheading,
                        ),
                      )
                    : Column(
                        children: [
                          if (!_isSelectionMode) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Filter via Group:",
                                  style: AppTypography.faintbody.copyWith(
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: AppPadding.tight),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    spacing: AppPadding.tight,
                                    children: _allGroups.map((group) {
                                      final String groupName =
                                          group['name'] ?? '';
                                      final int groupId = group['id'] ?? 0;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FilterChip(
                                            label: Text(groupName),
                                            selected: _selectedGroups.any(
                                              (group) => group['id'] == groupId,
                                            ),
                                            onSelected: (bool selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedGroups.add({
                                                    'id': groupId,
                                                    'name': groupName,
                                                  });
                                                } else {
                                                  _selectedGroups.removeWhere(
                                                    (group) =>
                                                        group['id'] == groupId,
                                                  );
                                                }
                                              });
                                              debugPrint(
                                                _selectedGroups.toString(),
                                              );
                                            },
                                            onDeleted: () =>
                                                _deleteGroup(groupId),
                                            deleteIcon: const Icon(
                                              Icons.delete,
                                            ),
                                            deleteIconColor: Colors.redAccent,
                                          ),
                                          const SizedBox(
                                            width: AppPadding.tight / 4,
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppPadding.medium),
                          ],
                          Expanded(
                            child: filteredEmails.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No matching emails found for selected filters",
                                      style: AppTypography.body,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredEmails.length,
                                    itemBuilder: (context, index) {
                                      final currentItem = filteredEmails[index];
                                      final int currentId =
                                          currentItem['id'] ?? 0;
                                      final bool isMarked = _selectedIds
                                          .contains(currentId);

                                      return _EmailCard(
                                        emailData: currentItem,
                                        isSelected: isMarked,
                                        isSelectionMode: _isSelectionMode,
                                        onTap: () => _handleRowTap(currentId),
                                        onLongPress: () =>
                                            _toggleSelection(currentId),
                                        onEdit: () =>
                                            _showEditEmailDialog(currentItem),
                                        onToggleImmediate: (value) {
                                          final bool status =
                                              currentItem['is_immediate'] ??
                                              false;
                                          _toggleSingleImmediate(
                                            currentId,
                                            status,
                                          );
                                        },
                                        onRemoveGroup: (groupId) =>
                                            _removeGroupFromEmail(
                                              currentId,
                                              groupId,
                                            ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
              if (_isSelectionMode) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "Assign Selected to Group:",
                        style: AppTypography.Bluesubheading,
                      ),
                    ),
                    Wrap(
                      spacing: AppPadding.tight,
                      runSpacing: AppPadding.tight,
                      children: _allGroups.map((group) {
                        final String groupName = group['name'] ?? '';
                        final int groupId = group['id'] ?? 0;
                        return ActionChip(
                          avatar: const Icon(
                            Icons.add,
                            size: AppPadding.medium,
                          ),
                          label: Text(groupName),
                          onPressed: () => _bulkAddGroupToEmails(groupId),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      floatingActionButton: _isSelectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: SpeedDial(
                spacing: AppPadding.medium,
                icon: Icons.add,
                foregroundColor: AppColors.backgroundWhite,
                activeIcon: Icons.close,
                // 2. Control deployment direction and label orientation
                direction: SpeedDialDirection.up,
                switchLabelPosition: false,
                backgroundColor: AppColors.primaryBlue,
                childMargin: EdgeInsets.symmetric(horizontal: AppPadding.tight),
                children: [
                  SpeedDialChild(
                    elevation: 0,
                    label: "Add Email Group",
                    child: const Icon(Icons.group_add_outlined),
                    onTap: () => _showAddEmailGroupDialog(),
                    backgroundColor: Color.fromARGB(255, 236, 242, 253),
                    foregroundColor: AppColors.primaryBlue,
                    labelBackgroundColor: Color.fromARGB(255, 236, 242, 253),
                    labelShadow: [],
                  ),
                  SpeedDialChild(
                    elevation: 0,
                    child: const Icon(Icons.email_outlined),
                    label: "Add Email",
                    backgroundColor: Color.fromARGB(255, 236, 242, 253),
                    foregroundColor: AppColors.primaryBlue,
                    labelBackgroundColor: Color.fromARGB(255, 236, 242, 253),
                    labelShadow: [],
                    onTap: () => _showAddEmailDialog(),
                  ),
                ],
              ),
            ),
    );
  }

  void _showExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "How to manage emails?",
            style: AppTypography.Bluesubheading,
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What does toggling each email on and off do?',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'Toggling an email on, makes it an immediate email. An immediate email will receive the report immediately when a technician submits a report from the technician checklist page.',
                ),
                const SizedBox(height: AppPadding.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Switch(
                      value: true,
                      onChanged: (bool value) {},
                      activeThumbColor: AppColors.primaryBlue,
                      activeTrackColor: AppColors.primaryBlueLight.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(width: AppPadding.tight),
                    Expanded(
                      child: Text(
                        "Means it's an immediate email",
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.medium),
                Text(
                  'What is an email group?',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'An email group is the group of emails that will receive reports when you go into the reports list page, manually choose the reports via long clicking each report, and select the email group.',
                ),
                const SizedBox(height: AppPadding.medium),
                Text(
                  'How do I add emails to groups, and delete emails?',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                const Text(
                  'By long pressing an email, you can select multiple emails. After long pressing, there will be an option at the bottom of the page to add selected emails to a group. at the top right of the page, there will also be an option to delete emails.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _EmailCard extends StatelessWidget {
  final Map<String, dynamic> emailData;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final ValueChanged<bool?> onToggleImmediate;
  final Function(int) onRemoveGroup;

  const _EmailCard({
    required this.emailData,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onToggleImmediate,
    required this.onRemoveGroup,
  });

  @override
  Widget build(BuildContext context) {
    final String email = emailData['email'] ?? '';
    final bool isImmediate = emailData['is_immediate'] ?? false;
    final List<Map<String, dynamic>> emailGroups =
        List<Map<String, dynamic>>.from(
          emailData['email_group_join_table'] ?? [],
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlue.withValues(alpha : 0.08)
            : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            onLongPress: onLongPress,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppPadding.medium,
              vertical: 2.0,
            ),
            leading: (isMobile(context) && !isSelectionMode)
                ? null
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: isSelectionMode
                        ? Checkbox(
                            key: ValueKey('checkbox_$email'),
                            activeColor: AppColors.primaryBlue,
                            value: isSelected,
                            onChanged: (_) => onTap(),
                          )
                        : CircleAvatar(
                            key: ValueKey('avatar_$email'),
                            backgroundColor: isImmediate
                                ? Colors.yellow
                                : AppColors.backgroundWhite,
                            child: Icon(
                              Icons.mail_outline,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                          ),
                  ),
            title: Text(
              email,
              overflow: TextOverflow.fade,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.body.copyWith(
                fontWeight: isImmediate ? FontWeight.w600 : FontWeight.normal,
                fontSize: isMobile(context) ? 13 : null,
              ),
            ),
            trailing: isSelectionMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: AppColors.textMain,
                        ),
                        tooltip: "Edit Email",
                        onPressed: onEdit,
                      ),
                      Switch(
                        activeThumbColor: AppColors.primaryBlue,
                        activeTrackColor: AppColors.primaryBlueLight.withValues(
                          alpha: 0.3,
                        ),
                        value: isImmediate,
                        onChanged: onToggleImmediate,
                      ),
                    ],
                  ),
          ),
          if (emailGroups.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: _EmailGroupChips(
                    emailGroups: emailGroups,
                    onRemoveGroup: onRemoveGroup,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmailGroupChips extends StatefulWidget {
  const _EmailGroupChips({
    required this.emailGroups,
    required this.onRemoveGroup,
  });

  final List<Map<String, dynamic>> emailGroups;
  final Function(int) onRemoveGroup;

  @override
  State<_EmailGroupChips> createState() => _EmailGroupChipsState();
}

class _EmailGroupChipsState extends State<_EmailGroupChips> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppDimensions.radiusMedium),
      padding: EdgeInsets.only(left: AppPadding.medium),
      child: Wrap(
        spacing: AppPadding.tight,
        runSpacing: AppPadding.tight,
        children: widget.emailGroups.map((group) {
          final String groupName = group['email_groups']['name'] ?? '';
          final int groupId = group['email_groups']['id'] ?? 0;
          return Chip(
            label: Text(groupName),
            backgroundColor: AppColors.primaryTint,
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () => widget.onRemoveGroup(groupId),
          );
        }).toList(),
      ),
    );
  }
}

bool isMobile(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 500;
}
