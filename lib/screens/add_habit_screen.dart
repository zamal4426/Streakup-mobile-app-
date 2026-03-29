import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? editHabit;

  const AddHabitScreen({super.key, this.editHabit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _iconSearchController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();

  late String _category;
  late int _selectedIconIndex;
  late int _selectedColorIndex;
  int? _reminderHour;
  int? _reminderMinute;
  late List<int> _repeatDays;
  int _difficulty = 1;
  List<String> _tags = [];
  bool _useTargetPerWeek = false;
  int _targetPerWeek = 3;

  String _iconSearchQuery = '';
  bool _showCustomCategoryInput = false;
  List<String> _customCategories = [];
  List<String> _customTags = [];

  String _selectedIconCategory = 'All';
  bool _showAllIcons = false;

  bool get _isEditing => widget.editHabit != null;

  static const List<String> _tagSuggestions = [
    'morning', 'evening', 'quick', 'outdoor', 'indoor', 'solo', 'social',
  ];

  // --- Default Categories ---
  static const List<String> _defaultCategories = [
    'Health',
    'Fitness',
    'Mindfulness',
    'Productivity',
    'Learning',
    'Finance',
    'Social',
    'Creative',
    'General',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Health': Icons.favorite_outline,
    'Fitness': Icons.fitness_center_rounded,
    'Mindfulness': Icons.self_improvement_rounded,
    'Productivity': Icons.rocket_launch_rounded,
    'Learning': Icons.school_outlined,
    'Finance': Icons.savings_outlined,
    'Social': Icons.people_outline,
    'Creative': Icons.brush_outlined,
    'General': Icons.star_outline_rounded,
  };

  static const Map<String, List<String>> _iconCategories = {
    'All': [],
    'Health': ['health', 'heart', 'medicine', 'hospital', 'monitor', 'vaccine', 'medication'],
    'Fitness': ['fitness', 'gym', 'run', 'swim', 'bike', 'hike', 'sport', 'exercise', 'yoga', 'stretch', 'martial', 'gymnastics'],
    'Study': ['book', 'read', 'study', 'school', 'learn', 'library', 'education', 'science', 'math', 'calculate', 'history'],
    'Work': ['work', 'office', 'code', 'programming', 'engineering', 'architecture', 'career'],
    'Personal': ['meditation', 'mindfulness', 'sleep', 'journal', 'diary', 'write', 'mood', 'brain', 'think', 'breathe'],
    'Lifestyle': ['cook', 'food', 'coffee', 'clean', 'home', 'shopping', 'grocery', 'laundry', 'garden'],
    'Creative': ['art', 'paint', 'draw', 'music', 'piano', 'photo', 'camera', 'palette', 'design', 'creative'],
    'Nature': ['nature', 'plant', 'flower', 'garden', 'outdoor', 'forest', 'park', 'water', 'sun', 'mountain'],
    'Social': ['social', 'call', 'phone', 'email', 'volunteer', 'handshake', 'groups', 'community'],
  };

  List<String> get _allCategories =>
      [..._defaultCategories, ..._customCategories];

  // --- Searchable Icons ---
  static const List<_IconEntry> _allIcons = [
    _IconEntry(Icons.fitness_center_rounded, 'fitness gym workout exercise weight'),
    _IconEntry(Icons.auto_stories_rounded, 'book read study stories library'),
    _IconEntry(Icons.water_drop_rounded, 'water drop drink hydrate'),
    _IconEntry(Icons.self_improvement_rounded, 'meditation yoga mindfulness zen calm'),
    _IconEntry(Icons.directions_run_rounded, 'run jog sprint cardio'),
    _IconEntry(Icons.bedtime_rounded, 'sleep bed rest night moon'),
    _IconEntry(Icons.restaurant_rounded, 'food eat restaurant meal diet cook'),
    _IconEntry(Icons.code_rounded, 'code programming developer tech'),
    _IconEntry(Icons.music_note_rounded, 'music note song sing listen'),
    _IconEntry(Icons.brush_rounded, 'art brush paint draw creative'),
    _IconEntry(Icons.favorite_rounded, 'heart health love care'),
    _IconEntry(Icons.savings_rounded, 'money savings finance piggy bank'),
    _IconEntry(Icons.school_rounded, 'school education learn graduate'),
    _IconEntry(Icons.local_cafe_rounded, 'coffee cafe morning drink tea'),
    _IconEntry(Icons.pets_rounded, 'pet animal dog cat walk'),
    _IconEntry(Icons.flight_rounded, 'travel flight airplane trip vacation'),
    _IconEntry(Icons.psychology_rounded, 'brain mind think psychology focus'),
    _IconEntry(Icons.spa_rounded, 'spa relax wellness beauty skincare'),
    _IconEntry(Icons.sports_basketball_rounded, 'basketball sports ball game'),
    _IconEntry(Icons.volunteer_activism_rounded, 'volunteer charity kindness give help'),
    _IconEntry(Icons.timer_rounded, 'timer clock stopwatch time pomodoro'),
    _IconEntry(Icons.emoji_nature_rounded, 'nature plant flower garden outdoor'),
    _IconEntry(Icons.photo_camera_rounded, 'camera photo picture capture'),
    _IconEntry(Icons.language_rounded, 'language globe world translate foreign'),
    _IconEntry(Icons.directions_walk_rounded, 'walk hike step outdoor stroll'),
    _IconEntry(Icons.directions_bike_rounded, 'bike bicycle cycling ride'),
    _IconEntry(Icons.pool_rounded, 'swim pool water sports aqua'),
    _IconEntry(Icons.cleaning_services_rounded, 'clean house tidy sweep mop'),
    _IconEntry(Icons.edit_note_rounded, 'write journal note pen diary'),
    _IconEntry(Icons.phone_rounded, 'call phone contact talk'),
    _IconEntry(Icons.email_rounded, 'email mail send message inbox'),
    _IconEntry(Icons.shopping_cart_rounded, 'shopping cart buy store groceries'),
    _IconEntry(Icons.movie_rounded, 'movie film watch cinema video'),
    _IconEntry(Icons.sports_esports_rounded, 'gaming play controller game'),
    _IconEntry(Icons.smoke_free_rounded, 'smoke free quit smoking no'),
    _IconEntry(Icons.no_drinks_rounded, 'no drinks alcohol sober quit'),
    _IconEntry(Icons.local_hospital_rounded, 'hospital medicine health doctor checkup'),
    _IconEntry(Icons.emoji_events_rounded, 'trophy award goal achievement win'),
    _IconEntry(Icons.lightbulb_rounded, 'idea lightbulb think innovation'),
    _IconEntry(Icons.star_rounded, 'star favorite best goal'),
    _IconEntry(Icons.rocket_launch_rounded, 'rocket launch productivity startup'),
    _IconEntry(Icons.home_rounded, 'home house chores domestic'),
    _IconEntry(Icons.work_rounded, 'work office job career briefcase'),
    _IconEntry(Icons.child_care_rounded, 'child baby kids family parent'),
    _IconEntry(Icons.sports_soccer_rounded, 'soccer football sports ball kick'),
    _IconEntry(Icons.sports_tennis_rounded, 'tennis sports racket ball'),
    _IconEntry(Icons.hiking_rounded, 'hiking mountain trail outdoor adventure'),
    _IconEntry(Icons.piano_rounded, 'piano keyboard instrument practice'),
    _IconEntry(Icons.headphones_rounded, 'headphones music listen podcast audio'),
    _IconEntry(Icons.local_library_rounded, 'library book reading quiet study'),
    _IconEntry(Icons.palette_rounded, 'palette color art design'),
    _IconEntry(Icons.grass_rounded, 'grass garden nature outdoor green'),
    _IconEntry(Icons.wb_sunny_rounded, 'sun sunny morning wake early'),
    _IconEntry(Icons.nightlife_rounded, 'night social party friends evening'),
    _IconEntry(Icons.recycling_rounded, 'recycle green eco environment sustainable'),
    _IconEntry(Icons.visibility_rounded, 'eye vision see screen break'),
    _IconEntry(Icons.mood_rounded, 'mood happy smile grateful positive'),
    _IconEntry(Icons.task_alt_rounded, 'task check done complete todo'),
    _IconEntry(Icons.alarm_rounded, 'alarm wake morning early clock'),
    _IconEntry(Icons.local_fire_department_rounded, 'fire streak hot burn calories'),
    _IconEntry(Icons.kitchen_rounded, 'kitchen cooking chef recipe'),
    _IconEntry(Icons.blender_rounded, 'blender smoothie juice blend'),
    _IconEntry(Icons.dry_cleaning_rounded, 'laundry clothes clean dry'),
    _IconEntry(Icons.mosque_rounded, 'mosque prayer islamic worship'),
    _IconEntry(Icons.church_rounded, 'church prayer christian worship'),
    _IconEntry(Icons.temple_buddhist_rounded, 'temple prayer buddhist worship'),
    _IconEntry(Icons.translate_rounded, 'translate language learn foreign'),
    _IconEntry(Icons.drive_eta_rounded, 'drive car commute transport'),
    _IconEntry(Icons.local_grocery_store_rounded, 'grocery shopping food store'),
    _IconEntry(Icons.yard_rounded, 'yard garden plants outdoor green'),
    _IconEntry(Icons.cruelty_free_rounded, 'pet animal bunny care'),
    _IconEntry(Icons.camera_alt_rounded, 'camera photography picture capture'),
    _IconEntry(Icons.videogame_asset_rounded, 'gaming video game play controller'),
    _IconEntry(Icons.sports_martial_arts_rounded, 'martial arts karate combat'),
    _IconEntry(Icons.sports_gymnastics_rounded, 'gymnastics stretching flexibility'),
    _IconEntry(Icons.sports_handball_rounded, 'handball sports ball throw'),
    _IconEntry(Icons.sports_golf_rounded, 'golf sports outdoor club'),
    _IconEntry(Icons.sports_rugby_rounded, 'rugby sports ball team'),
    _IconEntry(Icons.skateboarding_rounded, 'skateboard skate extreme sport'),
    _IconEntry(Icons.surfing_rounded, 'surfing surf water ocean sport'),
    _IconEntry(Icons.snowboarding_rounded, 'snowboard snow winter sport'),
    _IconEntry(Icons.rowing_rounded, 'rowing boat water sport exercise'),
    _IconEntry(Icons.scuba_diving_rounded, 'diving scuba underwater ocean'),
    _IconEntry(Icons.paragliding_rounded, 'paragliding adventure extreme sky'),
    _IconEntry(Icons.downhill_skiing_rounded, 'skiing snow winter mountain sport'),
    _IconEntry(Icons.ice_skating_rounded, 'ice skating winter sport'),
    _IconEntry(Icons.anchor_rounded, 'anchor boat sailing nautical'),
    _IconEntry(Icons.air_rounded, 'air breathe breathing fresh'),
    _IconEntry(Icons.wb_twilight_rounded, 'twilight evening sunset dusk'),
    _IconEntry(Icons.draw_rounded, 'draw sketch art pencil creative'),
    _IconEntry(Icons.auto_fix_high_rounded, 'magic creative inspire sparkle'),
    _IconEntry(Icons.celebration_rounded, 'celebration party event festive'),
    _IconEntry(Icons.handshake_rounded, 'handshake meeting social networking'),
    _IconEntry(Icons.groups_rounded, 'groups team community social'),
    _IconEntry(Icons.elderly_rounded, 'elderly care family visit'),
    _IconEntry(Icons.monitor_heart_rounded, 'heart monitor health vitals'),
    _IconEntry(Icons.vaccines_rounded, 'vaccine medicine health doctor'),
    _IconEntry(Icons.medication_rounded, 'medication pills medicine health'),
    _IconEntry(Icons.science_rounded, 'science experiment lab research'),
    _IconEntry(Icons.biotech_rounded, 'biotech biology science research'),
    _IconEntry(Icons.engineering_rounded, 'engineering build create make'),
    _IconEntry(Icons.architecture_rounded, 'architecture design build plan'),
    _IconEntry(Icons.podcasts_rounded, 'podcast listen audio show'),
    _IconEntry(Icons.radio_rounded, 'radio listen audio news'),
    _IconEntry(Icons.newspaper_rounded, 'newspaper news read article'),
    _IconEntry(Icons.menu_book_rounded, 'menu book reading study literature'),
    _IconEntry(Icons.history_edu_rounded, 'history writing journal essay'),
    _IconEntry(Icons.calculate_rounded, 'calculate math numbers budget'),
    _IconEntry(Icons.account_balance_rounded, 'bank finance money account'),
    _IconEntry(Icons.trending_up_rounded, 'trending up growth progress invest'),
    _IconEntry(Icons.battery_charging_full_rounded, 'energy battery charge recharge'),
    _IconEntry(Icons.bolt_rounded, 'bolt energy power quick fast'),
    _IconEntry(Icons.shield_rounded, 'shield protect safety security'),
    _IconEntry(Icons.lock_rounded, 'lock security privacy safe'),
    _IconEntry(Icons.key_rounded, 'key access unlock open'),
    _IconEntry(Icons.backpack_rounded, 'backpack travel school hike'),
    _IconEntry(Icons.luggage_rounded, 'luggage travel trip vacation pack'),
    _IconEntry(Icons.map_rounded, 'map travel explore navigate'),
    _IconEntry(Icons.explore_rounded, 'explore compass adventure discover'),
    _IconEntry(Icons.forest_rounded, 'forest nature trees outdoor hike'),
    _IconEntry(Icons.park_rounded, 'park nature outdoor walk relax'),
    _IconEntry(Icons.water_rounded, 'water ocean sea nature'),
    _IconEntry(Icons.ac_unit_rounded, 'snowflake cold winter ice'),
    _IconEntry(Icons.whatshot_rounded, 'fire hot streak flame'),
  ];

  List<_IconEntry> get _filteredIcons {
    List<_IconEntry> result = _allIcons;

    // Filter by category
    if (_selectedIconCategory != 'All') {
      final categoryKeywords = _iconCategories[_selectedIconCategory] ?? [];
      if (categoryKeywords.isNotEmpty) {
        result = result.where((e) {
          return categoryKeywords.any((keyword) => e.keywords.contains(keyword));
        }).toList();
      }
    }

    // Filter by search query
    if (_iconSearchQuery.isNotEmpty) {
      final q = _iconSearchQuery.toLowerCase();
      result = result.where((e) => e.keywords.contains(q)).toList();
    }

    return result;
  }

  // --- Colors ---
  static const List<Color> _colors = [
    Color(0xFFFF6B35),
    Color(0xFFE94560),
    Color(0xFF6C63FF),
    Color(0xFF00C9A7),
    Color(0xFFFFB74D),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF5C6BC0),
  ];

  @override
  void initState() {
    super.initState();
    _customCategories = List.from(StorageService.customCategories);
    _customTags = List.from(StorageService.customTags);

    if (_isEditing) {
      final h = widget.editHabit!;
      _nameController.text = h.name;
      _notesController.text = h.notes;
      _category = h.category;
      _selectedIconIndex =
          _allIcons.indexWhere((e) => e.icon.codePoint == h.iconCodePoint);
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
      _selectedColorIndex =
          _colors.indexWhere((c) => c.toARGB32() == h.colorValue);
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;
      _reminderHour = h.reminderHour;
      _reminderMinute = h.reminderMinute;
      _repeatDays = List.from(h.repeatDays);
      _difficulty = h.difficulty;
      _tags = List.from(h.tags);
      if (h.targetPerWeek != null) {
        _useTargetPerWeek = true;
        _targetPerWeek = h.targetPerWeek!;
      }
    } else {
      _category = 'General';
      _selectedIconIndex = 0;
      _selectedColorIndex = 0;
      _repeatDays = [1, 2, 3, 4, 5, 6, 7];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _iconSearchController.dispose();
    _customCategoryController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  Color get _activeColor => _colors[_selectedColorIndex];

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a habit name'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (!_useTargetPerWeek && _repeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one repeat day'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final habit = Habit(
      id: _isEditing
          ? widget.editHabit!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: _category,
      iconCodePoint: _allIcons[_selectedIconIndex].icon.codePoint,
      colorValue: _activeColor.toARGB32(),
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      repeatDays: _useTargetPerWeek ? [1, 2, 3, 4, 5, 6, 7] : _repeatDays,
      createdAt: _isEditing ? widget.editHabit!.createdAt : DateTime.now(),
      completedDates: _isEditing ? widget.editHabit!.completedDates : [],
      notes: _notesController.text.trim(),
      difficulty: _difficulty,
      tags: _tags,
      skippedDates: _isEditing ? widget.editHabit!.skippedDates : [],
      streakFreezes: _isEditing ? widget.editHabit!.streakFreezes : 2,
      targetPerWeek: _useTargetPerWeek ? _targetPerWeek : null,
    );

    Navigator.of(context).pop(habit);
  }

  Future<void> _pickReminder() async {
    FocusScope.of(context).unfocus();

    final time = await showTimePicker(
      context: context,
      initialTime: _reminderHour != null
          ? TimeOfDay(hour: _reminderHour!, minute: _reminderMinute!)
          : const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: _activeColor,
                      surface: AppTheme.surface(context),
                    )
                  : ColorScheme.light(
                      primary: _activeColor,
                      surface: AppTheme.surface(context),
                      onSurface: AppTheme.lightTextPrimary,
                    ),
              dialogTheme: DialogThemeData(
                backgroundColor: isDark
                    ? AppTheme.background(context)
                    : AppTheme.lightSurfaceColor,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    // Prevent focus from jumping to any text field after dialog closes
    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (time != null) {
      // Only allow PM times (12:00 PM to 11:59 PM, i.e., hour 12–23)
      if (time.hour < 12) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Please select a time between 12:00 PM and 11:59 PM'),
              backgroundColor: AppTheme.accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
    }
  }

  void _addCustomCategory() {
    final name = _customCategoryController.text.trim();
    if (name.isEmpty) return;
    if (_allCategories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      // Already exists, just select it
      setState(() {
        _category = _allCategories.firstWhere(
            (c) => c.toLowerCase() == name.toLowerCase());
        _showCustomCategoryInput = false;
        _customCategoryController.clear();
      });
      return;
    }
    setState(() {
      _customCategories.add(name);
      _category = name;
      _showCustomCategoryInput = false;
      _customCategoryController.clear();
    });
    StorageService.setCustomCategories(_customCategories);
  }

  void _removeCustomCategory(String cat) {
    setState(() {
      _customCategories.remove(cat);
      if (_category == cat) {
        _category = 'General';
      }
    });
    StorageService.setCustomCategories(_customCategories);
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;
    setState(() {
      _tags.add(trimmed);
      _tagController.clear();
    });
    // Save to custom tags if not a suggestion
    if (!_tagSuggestions.contains(trimmed) && !_customTags.contains(trimmed)) {
      _customTags.add(trimmed);
      StorageService.setCustomTags(_customTags);
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Habit Name'),
                    const SizedBox(height: 10),
                    _buildNameField(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Category'),
                    const SizedBox(height: 10),
                    _buildCategoryPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Tags'),
                    const SizedBox(height: 10),
                    _buildTagInput(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Icon'),
                    const SizedBox(height: 10),
                    _buildIconPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Color'),
                    const SizedBox(height: 10),
                    _buildColorPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Difficulty'),
                    const SizedBox(height: 10),
                    _buildDifficultyPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Repeat Days'),
                    const SizedBox(height: 10),
                    _buildRepeatDays(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Reminder'),
                    const SizedBox(height: 10),
                    _buildReminderPicker(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Notes'),
                    const SizedBox(height: 10),
                    _buildNotesField(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Bar ---
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textPrimaryColor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _isEditing ? 'Edit Habit' : 'New Habit',
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Preview Card ---
  Widget _buildPreviewCard() {
    final name = _nameController.text.trim().isEmpty
        ? 'Habit Name'
        : _nameController.text.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _activeColor.withValues(alpha: 0.15),
            _activeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _activeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _activeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _allIcons[_selectedIconIndex].icon,
              color: _activeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _category,
                        style: TextStyle(
                          color: _activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.repeat_rounded,
                        color: AppTheme.textSecondaryColor(context), size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _getRepeatText(),
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRepeatText() {
    if (_useTargetPerWeek) return '$_targetPerWeek times/week';
    if (_repeatDays.length == 7) return 'Every day';
    final weekdays = [1, 2, 3, 4, 5];
    if (_repeatDays.length == 5 &&
        weekdays.every((d) => _repeatDays.contains(d))) {
      return 'Weekdays';
    }
    if (_repeatDays.length == 2 &&
        _repeatDays.contains(6) &&
        _repeatDays.contains(7)) {
      return 'Weekends';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = _repeatDays.toList()..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  // --- Section Label ---
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSecondaryColor(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  // --- Name Field ---
  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 16),
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'e.g., Morning Exercise, Read 30 mins',
        hintStyle:
            TextStyle(color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4)),
        filled: true,
        fillColor: AppTheme.surface(context),
        prefixIcon:
            Icon(Icons.edit_rounded, color: AppTheme.textSecondaryColor(context), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.cardBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _activeColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // --- Category Picker ---
  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Default categories
            ..._defaultCategories.map((cat) => _buildCategoryChip(cat, false)),
            // Custom categories
            ..._customCategories.map((cat) => _buildCategoryChip(cat, true)),
            // Add custom button
            GestureDetector(
              onTap: () => setState(() {
                _showCustomCategoryInput = !_showCustomCategoryInput;
                if (!_showCustomCategoryInput) {
                  _customCategoryController.clear();
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _showCustomCategoryInput
                      ? _activeColor.withValues(alpha: 0.15)
                      : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showCustomCategoryInput
                        ? _activeColor
                        : AppTheme.textSecondaryColor(context).withValues(alpha: 0.15),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showCustomCategoryInput
                          ? Icons.close_rounded
                          : Icons.add_rounded,
                      color: _showCustomCategoryInput
                          ? _activeColor
                          : AppTheme.textSecondaryColor(context),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Custom',
                      style: TextStyle(
                        color: _showCustomCategoryInput
                            ? _activeColor
                            : AppTheme.textSecondaryColor(context),
                        fontSize: 13,
                        fontWeight: _showCustomCategoryInput
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Custom category input
        if (_showCustomCategoryInput) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCategoryController,
                  autofocus: true,
                  style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addCustomCategory(),
                  decoration: InputDecoration(
                    hintText: 'Enter category name',
                    hintStyle: TextStyle(
                        color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: AppTheme.surface(context),
                    prefixIcon: Icon(Icons.label_outline_rounded,
                        color: AppTheme.textSecondaryColor(context), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _activeColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addCustomCategory,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _activeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(String cat, bool isCustom) {
    final isSelected = _category == cat;
    return GestureDetector(
      onTap: () => setState(() => _category = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? _activeColor.withValues(alpha: 0.15)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _activeColor
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcons[cat] ?? Icons.label_outline_rounded,
              color: isSelected ? _activeColor : AppTheme.textSecondaryColor(context),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              cat,
              style: TextStyle(
                color: isSelected ? _activeColor : AppTheme.textSecondaryColor(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeCustomCategory(cat),
                child: Icon(
                  Icons.close_rounded,
                  color: isSelected
                      ? _activeColor.withValues(alpha: 0.6)
                      : AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Tag Input ---
  Widget _buildTagInput() {
    final allSuggestions = {..._tagSuggestions, ..._customTags}
        .where((t) => !_tags.contains(t))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        color: _activeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Icon(
                        Icons.close_rounded,
                        color: _activeColor.withValues(alpha: 0.7),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        // Input field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                focusNode: _tagFocusNode,
                style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
                onSubmitted: _addTag,
                decoration: InputDecoration(
                  hintText: 'Add a tag...',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: AppTheme.surface(context),
                  prefixIcon: Icon(Icons.tag_rounded,
                      color: AppTheme.textSecondaryColor(context), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _activeColor, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _addTag(_tagController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _activeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        // Suggestions
        if (allSuggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allSuggestions.map((tag) {
              return GestureDetector(
                onTap: () => _addTag(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.textSecondaryColor(context)
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          color: AppTheme.textSecondaryColor(context),
                          size: 12),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- Difficulty Picker ---
  Widget _buildDifficultyPicker() {
    const difficulties = [
      (1, 'Easy', Icons.eco_rounded),
      (2, 'Medium', Icons.local_fire_department_rounded),
      (3, 'Hard', Icons.bolt_rounded),
    ];

    return Row(
      children: difficulties.map((entry) {
        final (level, label, icon) = entry;
        final isSelected = _difficulty == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: level < 3 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _activeColor.withValues(alpha: 0.15)
                    : AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _activeColor
                      : AppTheme.textSecondaryColor(context)
                          .withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? _activeColor
                        : AppTheme.textSecondaryColor(context),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? _activeColor
                          : AppTheme.textSecondaryColor(context),
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Icon Picker ---
  Widget _buildIconPicker() {
    if (!_showAllIcons) {
      // Compact initial view: show first 10 popular icons + "More" button
      final popularIcons = _allIcons.take(10).toList();
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Compact grid: 5 columns
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: popularIcons.length,
              itemBuilder: (context, index) {
                final entry = popularIcons[index];
                final fullIndex = _allIcons.indexOf(entry);
                final isSelected = _selectedIconIndex == fullIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconIndex = fullIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _activeColor.withValues(alpha: 0.2)
                          : AppTheme.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: _activeColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      entry.icon,
                      color: isSelected
                          ? _activeColor
                          : AppTheme.textSecondaryColor(context),
                      size: 22,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // "More" button
            GestureDetector(
              onTap: () => setState(() => _showAllIcons = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _activeColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apps_rounded, color: _activeColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'More Icons (${_allIcons.length})',
                      style: TextStyle(
                        color: _activeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Expanded view: categories + search + full grid
    final filtered = _filteredIcons;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Category chips - horizontal scrollable row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconCategories.keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final category = _iconCategories.keys.elementAt(index);
                final isSelected = _selectedIconCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _activeColor.withValues(alpha: 0.15)
                          : AppTheme.background(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _activeColor
                            : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? _activeColor
                              : AppTheme.textSecondaryColor(context),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Search field
          TextField(
            controller: _iconSearchController,
            style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
            onChanged: (val) => setState(() => _iconSearchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search icons... (e.g., book, run, music)',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                  fontSize: 13),
              filled: true,
              fillColor: AppTheme.background(context),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppTheme.textSecondaryColor(context), size: 20),
              suffixIcon: _iconSearchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _iconSearchController.clear();
                        setState(() => _iconSearchQuery = '');
                      },
                      child: Icon(Icons.close_rounded,
                          color: AppTheme.textSecondaryColor(context), size: 18),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _activeColor.withValues(alpha: 0.5), width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Icon grid or empty state
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
                      size: 36),
                  const SizedBox(height: 8),
                  Text(
                    _iconSearchQuery.isNotEmpty
                        ? 'No icons found for "$_iconSearchQuery"'
                        : 'No icons in this category',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((entry) {
                final fullIndex = _allIcons.indexOf(entry);
                final isSelected = _selectedIconIndex == fullIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconIndex = fullIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _activeColor.withValues(alpha: 0.2)
                          : AppTheme.background(context),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: _activeColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      entry.icon,
                      color:
                          isSelected ? _activeColor : AppTheme.textSecondaryColor(context),
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

          // Show result count when searching or filtering
          if ((_iconSearchQuery.isNotEmpty || _selectedIconCategory != 'All') && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${filtered.length} icon${filtered.length == 1 ? '' : 's'} found',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 12),
          // "Less" button to collapse back
          GestureDetector(
            onTap: () => setState(() {
              _showAllIcons = false;
              _iconSearchQuery = '';
              _iconSearchController.clear();
              _selectedIconCategory = 'All';
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.expand_less_rounded,
                      color: AppTheme.textSecondaryColor(context), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Less',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Color Picker ---
  Widget _buildColorPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_colors.length, (index) {
        final isSelected = _selectedColorIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colors[index],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                    : AppTheme.textSecondaryColor(context).withValues(alpha: 0.15),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _colors[index].withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }),
    );
  }

  // --- Repeat Days ---
  Widget _buildRepeatDays() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Toggle: Specific Days vs X times per week
        Row(
          children: [
            _buildFrequencyToggle('Specific Days', !_useTargetPerWeek),
            const SizedBox(width: 8),
            _buildFrequencyToggle('X times/week', _useTargetPerWeek),
          ],
        ),
        const SizedBox(height: 12),

        if (_useTargetPerWeek) ...[
          // Frequency slider
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _activeColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target frequency',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_targetPerWeek days/week',
                        style: TextStyle(
                          color: _activeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _activeColor,
                    inactiveTrackColor:
                        _activeColor.withValues(alpha: 0.15),
                    thumbColor: _activeColor,
                    overlayColor: _activeColor.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    onChanged: (val) =>
                        setState(() => _targetPerWeek = val.round()),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Original day picker
          Row(
            children: [
              _buildQuickSelect('Every day', [1, 2, 3, 4, 5, 6, 7]),
              const SizedBox(width: 8),
              _buildQuickSelect('Weekdays', [1, 2, 3, 4, 5]),
              const SizedBox(width: 8),
              _buildQuickSelect('Weekends', [6, 7]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = _repeatDays.contains(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _repeatDays.remove(day);
                      } else {
                        _repeatDays.add(day);
                        _repeatDays.sort();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isSelected ? _activeColor : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _activeColor
                            : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppTheme.textSecondaryColor(context),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencyToggle(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() {
        _useTargetPerWeek = label == 'X times/week';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _activeColor.withValues(alpha: 0.15)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? _activeColor
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _activeColor : AppTheme.textSecondaryColor(context),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSelect(String label, List<int> days) {
    final isActive = _repeatDays.length == days.length &&
        days.every((d) => _repeatDays.contains(d));
    return GestureDetector(
      onTap: () => setState(() {
        _repeatDays = List.from(days);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _activeColor.withValues(alpha: 0.15)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? _activeColor
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _activeColor : AppTheme.textSecondaryColor(context),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // --- Reminder Picker ---
  Widget _buildReminderPicker() {
    return GestureDetector(
      onTap: _pickReminder,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _reminderHour != null
                ? _activeColor.withValues(alpha: 0.3)
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _reminderHour != null
                    ? _activeColor.withValues(alpha: 0.15)
                    : AppTheme.background(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: _reminderHour != null
                    ? _activeColor
                    : AppTheme.textSecondaryColor(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reminderHour != null ? 'Reminder Set' : 'Set Reminder',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _reminderHour != null
                        ? _formatTime(_reminderHour!, _reminderMinute!)
                        : 'Tap to set reminder (PM only)',
                    style: TextStyle(
                      color: _reminderHour != null
                          ? _activeColor
                          : AppTheme.textSecondaryColor(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_reminderHour != null)
              GestureDetector(
                onTap: () => setState(() {
                  _reminderHour = null;
                  _reminderMinute = null;
                }),
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondaryColor(context),
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor(context),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$m $period';
  }

  // --- Notes Field ---
  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
      textCapitalization: TextCapitalization.sentences,
      maxLines: 3,
      minLines: 2,
      decoration: InputDecoration(
        hintText: 'Add notes, goals, or details about this habit...',
        hintStyle:
            TextStyle(color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4)),
        filled: true,
        fillColor: AppTheme.surface(context),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Icon(Icons.note_alt_outlined, color: AppTheme.textSecondaryColor(context), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _activeColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // --- Save Button ---
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _activeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isEditing ? Icons.check_rounded : Icons.add_rounded,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              _isEditing ? 'Save Changes' : 'Create Habit',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Icon Entry helper ---
class _IconEntry {
  final IconData icon;
  final String keywords;

  const _IconEntry(this.icon, this.keywords);
}
