// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserAssessmentsTable extends UserAssessments
    with TableInfo<$UserAssessmentsTable, UserAssessment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAssessmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<int> percentage = GeneratedColumn<int>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedPlanIdMeta = const VerificationMeta(
    'recommendedPlanId',
  );
  @override
  late final GeneratedColumn<String> recommendedPlanId =
      GeneratedColumn<String>(
        'recommended_plan_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalScore,
    percentage,
    level,
    recommendedPlanId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserAssessment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_totalScoreMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('recommended_plan_id')) {
      context.handle(
        _recommendedPlanIdMeta,
        recommendedPlanId.isAcceptableOrUnknown(
          data['recommended_plan_id']!,
          _recommendedPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedPlanIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAssessment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAssessment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_score'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percentage'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      recommendedPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_plan_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserAssessmentsTable createAlias(String alias) {
    return $UserAssessmentsTable(attachedDatabase, alias);
  }
}

class UserAssessment extends DataClass implements Insertable<UserAssessment> {
  final int id;
  final int totalScore;
  final int percentage;
  final String level;
  final String recommendedPlanId;
  final DateTime createdAt;
  const UserAssessment({
    required this.id,
    required this.totalScore,
    required this.percentage,
    required this.level,
    required this.recommendedPlanId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_score'] = Variable<int>(totalScore);
    map['percentage'] = Variable<int>(percentage);
    map['level'] = Variable<String>(level);
    map['recommended_plan_id'] = Variable<String>(recommendedPlanId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserAssessmentsCompanion toCompanion(bool nullToAbsent) {
    return UserAssessmentsCompanion(
      id: Value(id),
      totalScore: Value(totalScore),
      percentage: Value(percentage),
      level: Value(level),
      recommendedPlanId: Value(recommendedPlanId),
      createdAt: Value(createdAt),
    );
  }

  factory UserAssessment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAssessment(
      id: serializer.fromJson<int>(json['id']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      percentage: serializer.fromJson<int>(json['percentage']),
      level: serializer.fromJson<String>(json['level']),
      recommendedPlanId: serializer.fromJson<String>(json['recommendedPlanId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalScore': serializer.toJson<int>(totalScore),
      'percentage': serializer.toJson<int>(percentage),
      'level': serializer.toJson<String>(level),
      'recommendedPlanId': serializer.toJson<String>(recommendedPlanId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserAssessment copyWith({
    int? id,
    int? totalScore,
    int? percentage,
    String? level,
    String? recommendedPlanId,
    DateTime? createdAt,
  }) => UserAssessment(
    id: id ?? this.id,
    totalScore: totalScore ?? this.totalScore,
    percentage: percentage ?? this.percentage,
    level: level ?? this.level,
    recommendedPlanId: recommendedPlanId ?? this.recommendedPlanId,
    createdAt: createdAt ?? this.createdAt,
  );
  UserAssessment copyWithCompanion(UserAssessmentsCompanion data) {
    return UserAssessment(
      id: data.id.present ? data.id.value : this.id,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      level: data.level.present ? data.level.value : this.level,
      recommendedPlanId: data.recommendedPlanId.present
          ? data.recommendedPlanId.value
          : this.recommendedPlanId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAssessment(')
          ..write('id: $id, ')
          ..write('totalScore: $totalScore, ')
          ..write('percentage: $percentage, ')
          ..write('level: $level, ')
          ..write('recommendedPlanId: $recommendedPlanId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalScore,
    percentage,
    level,
    recommendedPlanId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAssessment &&
          other.id == this.id &&
          other.totalScore == this.totalScore &&
          other.percentage == this.percentage &&
          other.level == this.level &&
          other.recommendedPlanId == this.recommendedPlanId &&
          other.createdAt == this.createdAt);
}

class UserAssessmentsCompanion extends UpdateCompanion<UserAssessment> {
  final Value<int> id;
  final Value<int> totalScore;
  final Value<int> percentage;
  final Value<String> level;
  final Value<String> recommendedPlanId;
  final Value<DateTime> createdAt;
  const UserAssessmentsCompanion({
    this.id = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.percentage = const Value.absent(),
    this.level = const Value.absent(),
    this.recommendedPlanId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserAssessmentsCompanion.insert({
    this.id = const Value.absent(),
    required int totalScore,
    required int percentage,
    required String level,
    required String recommendedPlanId,
    required DateTime createdAt,
  }) : totalScore = Value(totalScore),
       percentage = Value(percentage),
       level = Value(level),
       recommendedPlanId = Value(recommendedPlanId),
       createdAt = Value(createdAt);
  static Insertable<UserAssessment> custom({
    Expression<int>? id,
    Expression<int>? totalScore,
    Expression<int>? percentage,
    Expression<String>? level,
    Expression<String>? recommendedPlanId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalScore != null) 'total_score': totalScore,
      if (percentage != null) 'percentage': percentage,
      if (level != null) 'level': level,
      if (recommendedPlanId != null) 'recommended_plan_id': recommendedPlanId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserAssessmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? totalScore,
    Value<int>? percentage,
    Value<String>? level,
    Value<String>? recommendedPlanId,
    Value<DateTime>? createdAt,
  }) {
    return UserAssessmentsCompanion(
      id: id ?? this.id,
      totalScore: totalScore ?? this.totalScore,
      percentage: percentage ?? this.percentage,
      level: level ?? this.level,
      recommendedPlanId: recommendedPlanId ?? this.recommendedPlanId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<int>(percentage.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (recommendedPlanId.present) {
      map['recommended_plan_id'] = Variable<String>(recommendedPlanId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('totalScore: $totalScore, ')
          ..write('percentage: $percentage, ')
          ..write('level: $level, ')
          ..write('recommendedPlanId: $recommendedPlanId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BlockingSettingsTable extends BlockingSettings
    with TableInfo<$BlockingSettingsTable, BlockingSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockingSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: () => 1,
  );
  static const VerificationMeta _protectionEnabledMeta = const VerificationMeta(
    'protectionEnabled',
  );
  @override
  late final GeneratedColumn<bool> protectionEnabled = GeneratedColumn<bool>(
    'protection_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("protection_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _strictnessLevelMeta = const VerificationMeta(
    'strictnessLevel',
  );
  @override
  late final GeneratedColumn<String> strictnessLevel = GeneratedColumn<String>(
    'strictness_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('basic'),
  );
  static const VerificationMeta _searchFilteringEnabledMeta =
      const VerificationMeta('searchFilteringEnabled');
  @override
  late final GeneratedColumn<bool> searchFilteringEnabled =
      GeneratedColumn<bool>(
        'search_filtering_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("search_filtering_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _socialModeMeta = const VerificationMeta(
    'socialMode',
  );
  @override
  late final GeneratedColumn<String> socialMode = GeneratedColumn<String>(
    'social_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reelsAndShorts'),
  );
  static const VerificationMeta _blockReelsMeta = const VerificationMeta(
    'blockReels',
  );
  @override
  late final GeneratedColumn<bool> blockReels = GeneratedColumn<bool>(
    'block_reels',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_reels" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockShortsMeta = const VerificationMeta(
    'blockShorts',
  );
  @override
  late final GeneratedColumn<bool> blockShorts = GeneratedColumn<bool>(
    'block_shorts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_shorts" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockTikTokMeta = const VerificationMeta(
    'blockTikTok',
  );
  @override
  late final GeneratedColumn<bool> blockTikTok = GeneratedColumn<bool>(
    'block_tik_tok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_tik_tok" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockSnapchatStoriesMeta =
      const VerificationMeta('blockSnapchatStories');
  @override
  late final GeneratedColumn<bool> blockSnapchatStories = GeneratedColumn<bool>(
    'block_snapchat_stories',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_snapchat_stories" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reelsLimitMinutesMeta = const VerificationMeta(
    'reelsLimitMinutes',
  );
  @override
  late final GeneratedColumn<int> reelsLimitMinutes = GeneratedColumn<int>(
    'reels_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _shortsLimitMinutesMeta =
      const VerificationMeta('shortsLimitMinutes');
  @override
  late final GeneratedColumn<int> shortsLimitMinutes = GeneratedColumn<int>(
    'shorts_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _tiktokLimitMinutesMeta =
      const VerificationMeta('tiktokLimitMinutes');
  @override
  late final GeneratedColumn<int> tiktokLimitMinutes = GeneratedColumn<int>(
    'tiktok_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _snapchatLimitMinutesMeta =
      const VerificationMeta('snapchatLimitMinutes');
  @override
  late final GeneratedColumn<int> snapchatLimitMinutes = GeneratedColumn<int>(
    'snapchat_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _blockShoppingMeta = const VerificationMeta(
    'blockShopping',
  );
  @override
  late final GeneratedColumn<bool> blockShopping = GeneratedColumn<bool>(
    'block_shopping',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_shopping" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockGamblingMeta = const VerificationMeta(
    'blockGambling',
  );
  @override
  late final GeneratedColumn<bool> blockGambling = GeneratedColumn<bool>(
    'block_gambling',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_gambling" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blockImageVideoSearchMeta =
      const VerificationMeta('blockImageVideoSearch');
  @override
  late final GeneratedColumn<bool> blockImageVideoSearch =
      GeneratedColumn<bool>(
        'block_image_video_search',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("block_image_video_search" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _appTimeLimitsEnabledMeta =
      const VerificationMeta('appTimeLimitsEnabled');
  @override
  late final GeneratedColumn<bool> appTimeLimitsEnabled = GeneratedColumn<bool>(
    'app_time_limits_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("app_time_limits_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customAppsBlocklistEnabledMeta =
      const VerificationMeta('customAppsBlocklistEnabled');
  @override
  late final GeneratedColumn<bool> customAppsBlocklistEnabled =
      GeneratedColumn<bool>(
        'custom_apps_blocklist_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("custom_apps_blocklist_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _blockInAppBrowsersMeta =
      const VerificationMeta('blockInAppBrowsers');
  @override
  late final GeneratedColumn<bool> blockInAppBrowsers = GeneratedColumn<bool>(
    'block_in_app_browsers',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("block_in_app_browsers" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _preventUninstallMeta = const VerificationMeta(
    'preventUninstall',
  );
  @override
  late final GeneratedColumn<bool> preventUninstall = GeneratedColumn<bool>(
    'prevent_uninstall',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("prevent_uninstall" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _accountabilityPartnerEnabledMeta =
      const VerificationMeta('accountabilityPartnerEnabled');
  @override
  late final GeneratedColumn<bool> accountabilityPartnerEnabled =
      GeneratedColumn<bool>(
        'accountability_partner_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("accountability_partner_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _customBlockScreenMeta = const VerificationMeta(
    'customBlockScreen',
  );
  @override
  late final GeneratedColumn<bool> customBlockScreen = GeneratedColumn<bool>(
    'custom_block_screen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("custom_block_screen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customWebsitesBlocklistEnabledMeta =
      const VerificationMeta('customWebsitesBlocklistEnabled');
  @override
  late final GeneratedColumn<bool> customWebsitesBlocklistEnabled =
      GeneratedColumn<bool>(
        'custom_websites_blocklist_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("custom_websites_blocklist_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _commitmentCycleMeta = const VerificationMeta(
    'commitmentCycle',
  );
  @override
  late final GeneratedColumn<int> commitmentCycle = GeneratedColumn<int>(
    'commitment_cycle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commitmentLockUntilMeta =
      const VerificationMeta('commitmentLockUntil');
  @override
  late final GeneratedColumn<DateTime> commitmentLockUntil =
      GeneratedColumn<DateTime>(
        'commitment_lock_until',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _commitmentModeMeta = const VerificationMeta(
    'commitmentMode',
  );
  @override
  late final GeneratedColumn<String> commitmentMode = GeneratedColumn<String>(
    'commitment_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commitmentTotalDaysMeta =
      const VerificationMeta('commitmentTotalDays');
  @override
  late final GeneratedColumn<int> commitmentTotalDays = GeneratedColumn<int>(
    'commitment_total_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commitmentBreakCountMeta =
      const VerificationMeta('commitmentBreakCount');
  @override
  late final GeneratedColumn<int> commitmentBreakCount = GeneratedColumn<int>(
    'commitment_break_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commitmentStartedAtMeta =
      const VerificationMeta('commitmentStartedAt');
  @override
  late final GeneratedColumn<DateTime> commitmentStartedAt =
      GeneratedColumn<DateTime>(
        'commitment_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _protectionStartedAtMeta =
      const VerificationMeta('protectionStartedAt');
  @override
  late final GeneratedColumn<DateTime> protectionStartedAt =
      GeneratedColumn<DateTime>(
        'protection_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activePlanMeta = const VerificationMeta(
    'activePlan',
  );
  @override
  late final GeneratedColumn<String> activePlan = GeneratedColumn<String>(
    'active_plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termsAcceptedMeta = const VerificationMeta(
    'termsAccepted',
  );
  @override
  late final GeneratedColumn<bool> termsAccepted = GeneratedColumn<bool>(
    'terms_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("terms_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customBlocklistMeta = const VerificationMeta(
    'customBlocklist',
  );
  @override
  late final GeneratedColumn<String> customBlocklist = GeneratedColumn<String>(
    'custom_blocklist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customAllowlistMeta = const VerificationMeta(
    'customAllowlist',
  );
  @override
  late final GeneratedColumn<String> customAllowlist = GeneratedColumn<String>(
    'custom_allowlist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    protectionEnabled,
    strictnessLevel,
    searchFilteringEnabled,
    socialMode,
    blockReels,
    blockShorts,
    blockTikTok,
    blockSnapchatStories,
    reelsLimitMinutes,
    shortsLimitMinutes,
    tiktokLimitMinutes,
    snapchatLimitMinutes,
    blockShopping,
    blockGambling,
    blockImageVideoSearch,
    appTimeLimitsEnabled,
    customAppsBlocklistEnabled,
    blockInAppBrowsers,
    preventUninstall,
    accountabilityPartnerEnabled,
    customBlockScreen,
    customWebsitesBlocklistEnabled,
    commitmentCycle,
    commitmentLockUntil,
    commitmentMode,
    commitmentTotalDays,
    commitmentBreakCount,
    commitmentStartedAt,
    protectionStartedAt,
    activePlan,
    termsAccepted,
    customBlocklist,
    customAllowlist,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocking_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockingSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('protection_enabled')) {
      context.handle(
        _protectionEnabledMeta,
        protectionEnabled.isAcceptableOrUnknown(
          data['protection_enabled']!,
          _protectionEnabledMeta,
        ),
      );
    }
    if (data.containsKey('strictness_level')) {
      context.handle(
        _strictnessLevelMeta,
        strictnessLevel.isAcceptableOrUnknown(
          data['strictness_level']!,
          _strictnessLevelMeta,
        ),
      );
    }
    if (data.containsKey('search_filtering_enabled')) {
      context.handle(
        _searchFilteringEnabledMeta,
        searchFilteringEnabled.isAcceptableOrUnknown(
          data['search_filtering_enabled']!,
          _searchFilteringEnabledMeta,
        ),
      );
    }
    if (data.containsKey('social_mode')) {
      context.handle(
        _socialModeMeta,
        socialMode.isAcceptableOrUnknown(data['social_mode']!, _socialModeMeta),
      );
    }
    if (data.containsKey('block_reels')) {
      context.handle(
        _blockReelsMeta,
        blockReels.isAcceptableOrUnknown(data['block_reels']!, _blockReelsMeta),
      );
    }
    if (data.containsKey('block_shorts')) {
      context.handle(
        _blockShortsMeta,
        blockShorts.isAcceptableOrUnknown(
          data['block_shorts']!,
          _blockShortsMeta,
        ),
      );
    }
    if (data.containsKey('block_tik_tok')) {
      context.handle(
        _blockTikTokMeta,
        blockTikTok.isAcceptableOrUnknown(
          data['block_tik_tok']!,
          _blockTikTokMeta,
        ),
      );
    }
    if (data.containsKey('block_snapchat_stories')) {
      context.handle(
        _blockSnapchatStoriesMeta,
        blockSnapchatStories.isAcceptableOrUnknown(
          data['block_snapchat_stories']!,
          _blockSnapchatStoriesMeta,
        ),
      );
    }
    if (data.containsKey('reels_limit_minutes')) {
      context.handle(
        _reelsLimitMinutesMeta,
        reelsLimitMinutes.isAcceptableOrUnknown(
          data['reels_limit_minutes']!,
          _reelsLimitMinutesMeta,
        ),
      );
    }
    if (data.containsKey('shorts_limit_minutes')) {
      context.handle(
        _shortsLimitMinutesMeta,
        shortsLimitMinutes.isAcceptableOrUnknown(
          data['shorts_limit_minutes']!,
          _shortsLimitMinutesMeta,
        ),
      );
    }
    if (data.containsKey('tiktok_limit_minutes')) {
      context.handle(
        _tiktokLimitMinutesMeta,
        tiktokLimitMinutes.isAcceptableOrUnknown(
          data['tiktok_limit_minutes']!,
          _tiktokLimitMinutesMeta,
        ),
      );
    }
    if (data.containsKey('snapchat_limit_minutes')) {
      context.handle(
        _snapchatLimitMinutesMeta,
        snapchatLimitMinutes.isAcceptableOrUnknown(
          data['snapchat_limit_minutes']!,
          _snapchatLimitMinutesMeta,
        ),
      );
    }
    if (data.containsKey('block_shopping')) {
      context.handle(
        _blockShoppingMeta,
        blockShopping.isAcceptableOrUnknown(
          data['block_shopping']!,
          _blockShoppingMeta,
        ),
      );
    }
    if (data.containsKey('block_gambling')) {
      context.handle(
        _blockGamblingMeta,
        blockGambling.isAcceptableOrUnknown(
          data['block_gambling']!,
          _blockGamblingMeta,
        ),
      );
    }
    if (data.containsKey('block_image_video_search')) {
      context.handle(
        _blockImageVideoSearchMeta,
        blockImageVideoSearch.isAcceptableOrUnknown(
          data['block_image_video_search']!,
          _blockImageVideoSearchMeta,
        ),
      );
    }
    if (data.containsKey('app_time_limits_enabled')) {
      context.handle(
        _appTimeLimitsEnabledMeta,
        appTimeLimitsEnabled.isAcceptableOrUnknown(
          data['app_time_limits_enabled']!,
          _appTimeLimitsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('custom_apps_blocklist_enabled')) {
      context.handle(
        _customAppsBlocklistEnabledMeta,
        customAppsBlocklistEnabled.isAcceptableOrUnknown(
          data['custom_apps_blocklist_enabled']!,
          _customAppsBlocklistEnabledMeta,
        ),
      );
    }
    if (data.containsKey('block_in_app_browsers')) {
      context.handle(
        _blockInAppBrowsersMeta,
        blockInAppBrowsers.isAcceptableOrUnknown(
          data['block_in_app_browsers']!,
          _blockInAppBrowsersMeta,
        ),
      );
    }
    if (data.containsKey('prevent_uninstall')) {
      context.handle(
        _preventUninstallMeta,
        preventUninstall.isAcceptableOrUnknown(
          data['prevent_uninstall']!,
          _preventUninstallMeta,
        ),
      );
    }
    if (data.containsKey('accountability_partner_enabled')) {
      context.handle(
        _accountabilityPartnerEnabledMeta,
        accountabilityPartnerEnabled.isAcceptableOrUnknown(
          data['accountability_partner_enabled']!,
          _accountabilityPartnerEnabledMeta,
        ),
      );
    }
    if (data.containsKey('custom_block_screen')) {
      context.handle(
        _customBlockScreenMeta,
        customBlockScreen.isAcceptableOrUnknown(
          data['custom_block_screen']!,
          _customBlockScreenMeta,
        ),
      );
    }
    if (data.containsKey('custom_websites_blocklist_enabled')) {
      context.handle(
        _customWebsitesBlocklistEnabledMeta,
        customWebsitesBlocklistEnabled.isAcceptableOrUnknown(
          data['custom_websites_blocklist_enabled']!,
          _customWebsitesBlocklistEnabledMeta,
        ),
      );
    }
    if (data.containsKey('commitment_cycle')) {
      context.handle(
        _commitmentCycleMeta,
        commitmentCycle.isAcceptableOrUnknown(
          data['commitment_cycle']!,
          _commitmentCycleMeta,
        ),
      );
    }
    if (data.containsKey('commitment_lock_until')) {
      context.handle(
        _commitmentLockUntilMeta,
        commitmentLockUntil.isAcceptableOrUnknown(
          data['commitment_lock_until']!,
          _commitmentLockUntilMeta,
        ),
      );
    }
    if (data.containsKey('commitment_mode')) {
      context.handle(
        _commitmentModeMeta,
        commitmentMode.isAcceptableOrUnknown(
          data['commitment_mode']!,
          _commitmentModeMeta,
        ),
      );
    }
    if (data.containsKey('commitment_total_days')) {
      context.handle(
        _commitmentTotalDaysMeta,
        commitmentTotalDays.isAcceptableOrUnknown(
          data['commitment_total_days']!,
          _commitmentTotalDaysMeta,
        ),
      );
    }
    if (data.containsKey('commitment_break_count')) {
      context.handle(
        _commitmentBreakCountMeta,
        commitmentBreakCount.isAcceptableOrUnknown(
          data['commitment_break_count']!,
          _commitmentBreakCountMeta,
        ),
      );
    }
    if (data.containsKey('commitment_started_at')) {
      context.handle(
        _commitmentStartedAtMeta,
        commitmentStartedAt.isAcceptableOrUnknown(
          data['commitment_started_at']!,
          _commitmentStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('protection_started_at')) {
      context.handle(
        _protectionStartedAtMeta,
        protectionStartedAt.isAcceptableOrUnknown(
          data['protection_started_at']!,
          _protectionStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('active_plan')) {
      context.handle(
        _activePlanMeta,
        activePlan.isAcceptableOrUnknown(data['active_plan']!, _activePlanMeta),
      );
    }
    if (data.containsKey('terms_accepted')) {
      context.handle(
        _termsAcceptedMeta,
        termsAccepted.isAcceptableOrUnknown(
          data['terms_accepted']!,
          _termsAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('custom_blocklist')) {
      context.handle(
        _customBlocklistMeta,
        customBlocklist.isAcceptableOrUnknown(
          data['custom_blocklist']!,
          _customBlocklistMeta,
        ),
      );
    }
    if (data.containsKey('custom_allowlist')) {
      context.handle(
        _customAllowlistMeta,
        customAllowlist.isAcceptableOrUnknown(
          data['custom_allowlist']!,
          _customAllowlistMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockingSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockingSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      protectionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}protection_enabled'],
      )!,
      strictnessLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strictness_level'],
      )!,
      searchFilteringEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}search_filtering_enabled'],
      )!,
      socialMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}social_mode'],
      )!,
      blockReels: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_reels'],
      )!,
      blockShorts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_shorts'],
      )!,
      blockTikTok: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_tik_tok'],
      )!,
      blockSnapchatStories: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_snapchat_stories'],
      )!,
      reelsLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reels_limit_minutes'],
      )!,
      shortsLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shorts_limit_minutes'],
      )!,
      tiktokLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tiktok_limit_minutes'],
      )!,
      snapchatLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapchat_limit_minutes'],
      )!,
      blockShopping: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_shopping'],
      )!,
      blockGambling: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_gambling'],
      )!,
      blockImageVideoSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_image_video_search'],
      )!,
      appTimeLimitsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}app_time_limits_enabled'],
      )!,
      customAppsBlocklistEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom_apps_blocklist_enabled'],
      )!,
      blockInAppBrowsers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}block_in_app_browsers'],
      )!,
      preventUninstall: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prevent_uninstall'],
      )!,
      accountabilityPartnerEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}accountability_partner_enabled'],
      )!,
      customBlockScreen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom_block_screen'],
      )!,
      customWebsitesBlocklistEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom_websites_blocklist_enabled'],
      )!,
      commitmentCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commitment_cycle'],
      )!,
      commitmentLockUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}commitment_lock_until'],
      ),
      commitmentMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commitment_mode'],
      ),
      commitmentTotalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commitment_total_days'],
      )!,
      commitmentBreakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commitment_break_count'],
      )!,
      commitmentStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}commitment_started_at'],
      ),
      protectionStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}protection_started_at'],
      ),
      activePlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_plan'],
      ),
      termsAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}terms_accepted'],
      )!,
      customBlocklist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_blocklist'],
      ),
      customAllowlist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_allowlist'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BlockingSettingsTable createAlias(String alias) {
    return $BlockingSettingsTable(attachedDatabase, alias);
  }
}

class BlockingSetting extends DataClass implements Insertable<BlockingSetting> {
  final int id;
  final bool protectionEnabled;
  final String strictnessLevel;
  final bool searchFilteringEnabled;
  final String socialMode;
  final bool blockReels;
  final bool blockShorts;
  final bool blockTikTok;
  final bool blockSnapchatStories;
  final int reelsLimitMinutes;
  final int shortsLimitMinutes;
  final int tiktokLimitMinutes;
  final int snapchatLimitMinutes;
  final bool blockShopping;
  final bool blockGambling;
  final bool blockImageVideoSearch;
  final bool appTimeLimitsEnabled;
  final bool customAppsBlocklistEnabled;
  final bool blockInAppBrowsers;
  final bool preventUninstall;
  final bool accountabilityPartnerEnabled;
  final bool customBlockScreen;
  final bool customWebsitesBlocklistEnabled;
  final int commitmentCycle;
  final DateTime? commitmentLockUntil;
  final String? commitmentMode;
  final int commitmentTotalDays;
  final int commitmentBreakCount;
  final DateTime? commitmentStartedAt;
  final DateTime? protectionStartedAt;
  final String? activePlan;
  final bool termsAccepted;
  final String? customBlocklist;
  final String? customAllowlist;
  final DateTime updatedAt;
  const BlockingSetting({
    required this.id,
    required this.protectionEnabled,
    required this.strictnessLevel,
    required this.searchFilteringEnabled,
    required this.socialMode,
    required this.blockReels,
    required this.blockShorts,
    required this.blockTikTok,
    required this.blockSnapchatStories,
    required this.reelsLimitMinutes,
    required this.shortsLimitMinutes,
    required this.tiktokLimitMinutes,
    required this.snapchatLimitMinutes,
    required this.blockShopping,
    required this.blockGambling,
    required this.blockImageVideoSearch,
    required this.appTimeLimitsEnabled,
    required this.customAppsBlocklistEnabled,
    required this.blockInAppBrowsers,
    required this.preventUninstall,
    required this.accountabilityPartnerEnabled,
    required this.customBlockScreen,
    required this.customWebsitesBlocklistEnabled,
    required this.commitmentCycle,
    this.commitmentLockUntil,
    this.commitmentMode,
    required this.commitmentTotalDays,
    required this.commitmentBreakCount,
    this.commitmentStartedAt,
    this.protectionStartedAt,
    this.activePlan,
    required this.termsAccepted,
    this.customBlocklist,
    this.customAllowlist,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['protection_enabled'] = Variable<bool>(protectionEnabled);
    map['strictness_level'] = Variable<String>(strictnessLevel);
    map['search_filtering_enabled'] = Variable<bool>(searchFilteringEnabled);
    map['social_mode'] = Variable<String>(socialMode);
    map['block_reels'] = Variable<bool>(blockReels);
    map['block_shorts'] = Variable<bool>(blockShorts);
    map['block_tik_tok'] = Variable<bool>(blockTikTok);
    map['block_snapchat_stories'] = Variable<bool>(blockSnapchatStories);
    map['reels_limit_minutes'] = Variable<int>(reelsLimitMinutes);
    map['shorts_limit_minutes'] = Variable<int>(shortsLimitMinutes);
    map['tiktok_limit_minutes'] = Variable<int>(tiktokLimitMinutes);
    map['snapchat_limit_minutes'] = Variable<int>(snapchatLimitMinutes);
    map['block_shopping'] = Variable<bool>(blockShopping);
    map['block_gambling'] = Variable<bool>(blockGambling);
    map['block_image_video_search'] = Variable<bool>(blockImageVideoSearch);
    map['app_time_limits_enabled'] = Variable<bool>(appTimeLimitsEnabled);
    map['custom_apps_blocklist_enabled'] = Variable<bool>(
      customAppsBlocklistEnabled,
    );
    map['block_in_app_browsers'] = Variable<bool>(blockInAppBrowsers);
    map['prevent_uninstall'] = Variable<bool>(preventUninstall);
    map['accountability_partner_enabled'] = Variable<bool>(
      accountabilityPartnerEnabled,
    );
    map['custom_block_screen'] = Variable<bool>(customBlockScreen);
    map['custom_websites_blocklist_enabled'] = Variable<bool>(
      customWebsitesBlocklistEnabled,
    );
    map['commitment_cycle'] = Variable<int>(commitmentCycle);
    if (!nullToAbsent || commitmentLockUntil != null) {
      map['commitment_lock_until'] = Variable<DateTime>(commitmentLockUntil);
    }
    if (!nullToAbsent || commitmentMode != null) {
      map['commitment_mode'] = Variable<String>(commitmentMode);
    }
    map['commitment_total_days'] = Variable<int>(commitmentTotalDays);
    map['commitment_break_count'] = Variable<int>(commitmentBreakCount);
    if (!nullToAbsent || commitmentStartedAt != null) {
      map['commitment_started_at'] = Variable<DateTime>(commitmentStartedAt);
    }
    if (!nullToAbsent || protectionStartedAt != null) {
      map['protection_started_at'] = Variable<DateTime>(protectionStartedAt);
    }
    if (!nullToAbsent || activePlan != null) {
      map['active_plan'] = Variable<String>(activePlan);
    }
    map['terms_accepted'] = Variable<bool>(termsAccepted);
    if (!nullToAbsent || customBlocklist != null) {
      map['custom_blocklist'] = Variable<String>(customBlocklist);
    }
    if (!nullToAbsent || customAllowlist != null) {
      map['custom_allowlist'] = Variable<String>(customAllowlist);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BlockingSettingsCompanion toCompanion(bool nullToAbsent) {
    return BlockingSettingsCompanion(
      id: Value(id),
      protectionEnabled: Value(protectionEnabled),
      strictnessLevel: Value(strictnessLevel),
      searchFilteringEnabled: Value(searchFilteringEnabled),
      socialMode: Value(socialMode),
      blockReels: Value(blockReels),
      blockShorts: Value(blockShorts),
      blockTikTok: Value(blockTikTok),
      blockSnapchatStories: Value(blockSnapchatStories),
      reelsLimitMinutes: Value(reelsLimitMinutes),
      shortsLimitMinutes: Value(shortsLimitMinutes),
      tiktokLimitMinutes: Value(tiktokLimitMinutes),
      snapchatLimitMinutes: Value(snapchatLimitMinutes),
      blockShopping: Value(blockShopping),
      blockGambling: Value(blockGambling),
      blockImageVideoSearch: Value(blockImageVideoSearch),
      appTimeLimitsEnabled: Value(appTimeLimitsEnabled),
      customAppsBlocklistEnabled: Value(customAppsBlocklistEnabled),
      blockInAppBrowsers: Value(blockInAppBrowsers),
      preventUninstall: Value(preventUninstall),
      accountabilityPartnerEnabled: Value(accountabilityPartnerEnabled),
      customBlockScreen: Value(customBlockScreen),
      customWebsitesBlocklistEnabled: Value(customWebsitesBlocklistEnabled),
      commitmentCycle: Value(commitmentCycle),
      commitmentLockUntil: commitmentLockUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(commitmentLockUntil),
      commitmentMode: commitmentMode == null && nullToAbsent
          ? const Value.absent()
          : Value(commitmentMode),
      commitmentTotalDays: Value(commitmentTotalDays),
      commitmentBreakCount: Value(commitmentBreakCount),
      commitmentStartedAt: commitmentStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(commitmentStartedAt),
      protectionStartedAt: protectionStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(protectionStartedAt),
      activePlan: activePlan == null && nullToAbsent
          ? const Value.absent()
          : Value(activePlan),
      termsAccepted: Value(termsAccepted),
      customBlocklist: customBlocklist == null && nullToAbsent
          ? const Value.absent()
          : Value(customBlocklist),
      customAllowlist: customAllowlist == null && nullToAbsent
          ? const Value.absent()
          : Value(customAllowlist),
      updatedAt: Value(updatedAt),
    );
  }

  factory BlockingSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockingSetting(
      id: serializer.fromJson<int>(json['id']),
      protectionEnabled: serializer.fromJson<bool>(json['protectionEnabled']),
      strictnessLevel: serializer.fromJson<String>(json['strictnessLevel']),
      searchFilteringEnabled: serializer.fromJson<bool>(
        json['searchFilteringEnabled'],
      ),
      socialMode: serializer.fromJson<String>(json['socialMode']),
      blockReels: serializer.fromJson<bool>(json['blockReels']),
      blockShorts: serializer.fromJson<bool>(json['blockShorts']),
      blockTikTok: serializer.fromJson<bool>(json['blockTikTok']),
      blockSnapchatStories: serializer.fromJson<bool>(
        json['blockSnapchatStories'],
      ),
      reelsLimitMinutes: serializer.fromJson<int>(json['reelsLimitMinutes']),
      shortsLimitMinutes: serializer.fromJson<int>(json['shortsLimitMinutes']),
      tiktokLimitMinutes: serializer.fromJson<int>(json['tiktokLimitMinutes']),
      snapchatLimitMinutes: serializer.fromJson<int>(
        json['snapchatLimitMinutes'],
      ),
      blockShopping: serializer.fromJson<bool>(json['blockShopping']),
      blockGambling: serializer.fromJson<bool>(json['blockGambling']),
      blockImageVideoSearch: serializer.fromJson<bool>(
        json['blockImageVideoSearch'],
      ),
      appTimeLimitsEnabled: serializer.fromJson<bool>(
        json['appTimeLimitsEnabled'],
      ),
      customAppsBlocklistEnabled: serializer.fromJson<bool>(
        json['customAppsBlocklistEnabled'],
      ),
      blockInAppBrowsers: serializer.fromJson<bool>(json['blockInAppBrowsers']),
      preventUninstall: serializer.fromJson<bool>(json['preventUninstall']),
      accountabilityPartnerEnabled: serializer.fromJson<bool>(
        json['accountabilityPartnerEnabled'],
      ),
      customBlockScreen: serializer.fromJson<bool>(json['customBlockScreen']),
      customWebsitesBlocklistEnabled: serializer.fromJson<bool>(
        json['customWebsitesBlocklistEnabled'],
      ),
      commitmentCycle: serializer.fromJson<int>(json['commitmentCycle']),
      commitmentLockUntil: serializer.fromJson<DateTime?>(
        json['commitmentLockUntil'],
      ),
      commitmentMode: serializer.fromJson<String?>(json['commitmentMode']),
      commitmentTotalDays: serializer.fromJson<int>(
        json['commitmentTotalDays'],
      ),
      commitmentBreakCount: serializer.fromJson<int>(
        json['commitmentBreakCount'],
      ),
      commitmentStartedAt: serializer.fromJson<DateTime?>(
        json['commitmentStartedAt'],
      ),
      protectionStartedAt: serializer.fromJson<DateTime?>(
        json['protectionStartedAt'],
      ),
      activePlan: serializer.fromJson<String?>(json['activePlan']),
      termsAccepted: serializer.fromJson<bool>(json['termsAccepted']),
      customBlocklist: serializer.fromJson<String?>(json['customBlocklist']),
      customAllowlist: serializer.fromJson<String?>(json['customAllowlist']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'protectionEnabled': serializer.toJson<bool>(protectionEnabled),
      'strictnessLevel': serializer.toJson<String>(strictnessLevel),
      'searchFilteringEnabled': serializer.toJson<bool>(searchFilteringEnabled),
      'socialMode': serializer.toJson<String>(socialMode),
      'blockReels': serializer.toJson<bool>(blockReels),
      'blockShorts': serializer.toJson<bool>(blockShorts),
      'blockTikTok': serializer.toJson<bool>(blockTikTok),
      'blockSnapchatStories': serializer.toJson<bool>(blockSnapchatStories),
      'reelsLimitMinutes': serializer.toJson<int>(reelsLimitMinutes),
      'shortsLimitMinutes': serializer.toJson<int>(shortsLimitMinutes),
      'tiktokLimitMinutes': serializer.toJson<int>(tiktokLimitMinutes),
      'snapchatLimitMinutes': serializer.toJson<int>(snapchatLimitMinutes),
      'blockShopping': serializer.toJson<bool>(blockShopping),
      'blockGambling': serializer.toJson<bool>(blockGambling),
      'blockImageVideoSearch': serializer.toJson<bool>(blockImageVideoSearch),
      'appTimeLimitsEnabled': serializer.toJson<bool>(appTimeLimitsEnabled),
      'customAppsBlocklistEnabled': serializer.toJson<bool>(
        customAppsBlocklistEnabled,
      ),
      'blockInAppBrowsers': serializer.toJson<bool>(blockInAppBrowsers),
      'preventUninstall': serializer.toJson<bool>(preventUninstall),
      'accountabilityPartnerEnabled': serializer.toJson<bool>(
        accountabilityPartnerEnabled,
      ),
      'customBlockScreen': serializer.toJson<bool>(customBlockScreen),
      'customWebsitesBlocklistEnabled': serializer.toJson<bool>(
        customWebsitesBlocklistEnabled,
      ),
      'commitmentCycle': serializer.toJson<int>(commitmentCycle),
      'commitmentLockUntil': serializer.toJson<DateTime?>(commitmentLockUntil),
      'commitmentMode': serializer.toJson<String?>(commitmentMode),
      'commitmentTotalDays': serializer.toJson<int>(commitmentTotalDays),
      'commitmentBreakCount': serializer.toJson<int>(commitmentBreakCount),
      'commitmentStartedAt': serializer.toJson<DateTime?>(commitmentStartedAt),
      'protectionStartedAt': serializer.toJson<DateTime?>(protectionStartedAt),
      'activePlan': serializer.toJson<String?>(activePlan),
      'termsAccepted': serializer.toJson<bool>(termsAccepted),
      'customBlocklist': serializer.toJson<String?>(customBlocklist),
      'customAllowlist': serializer.toJson<String?>(customAllowlist),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BlockingSetting copyWith({
    int? id,
    bool? protectionEnabled,
    String? strictnessLevel,
    bool? searchFilteringEnabled,
    String? socialMode,
    bool? blockReels,
    bool? blockShorts,
    bool? blockTikTok,
    bool? blockSnapchatStories,
    int? reelsLimitMinutes,
    int? shortsLimitMinutes,
    int? tiktokLimitMinutes,
    int? snapchatLimitMinutes,
    bool? blockShopping,
    bool? blockGambling,
    bool? blockImageVideoSearch,
    bool? appTimeLimitsEnabled,
    bool? customAppsBlocklistEnabled,
    bool? blockInAppBrowsers,
    bool? preventUninstall,
    bool? accountabilityPartnerEnabled,
    bool? customBlockScreen,
    bool? customWebsitesBlocklistEnabled,
    int? commitmentCycle,
    Value<DateTime?> commitmentLockUntil = const Value.absent(),
    Value<String?> commitmentMode = const Value.absent(),
    int? commitmentTotalDays,
    int? commitmentBreakCount,
    Value<DateTime?> commitmentStartedAt = const Value.absent(),
    Value<DateTime?> protectionStartedAt = const Value.absent(),
    Value<String?> activePlan = const Value.absent(),
    bool? termsAccepted,
    Value<String?> customBlocklist = const Value.absent(),
    Value<String?> customAllowlist = const Value.absent(),
    DateTime? updatedAt,
  }) => BlockingSetting(
    id: id ?? this.id,
    protectionEnabled: protectionEnabled ?? this.protectionEnabled,
    strictnessLevel: strictnessLevel ?? this.strictnessLevel,
    searchFilteringEnabled:
        searchFilteringEnabled ?? this.searchFilteringEnabled,
    socialMode: socialMode ?? this.socialMode,
    blockReels: blockReels ?? this.blockReels,
    blockShorts: blockShorts ?? this.blockShorts,
    blockTikTok: blockTikTok ?? this.blockTikTok,
    blockSnapchatStories: blockSnapchatStories ?? this.blockSnapchatStories,
    reelsLimitMinutes: reelsLimitMinutes ?? this.reelsLimitMinutes,
    shortsLimitMinutes: shortsLimitMinutes ?? this.shortsLimitMinutes,
    tiktokLimitMinutes: tiktokLimitMinutes ?? this.tiktokLimitMinutes,
    snapchatLimitMinutes: snapchatLimitMinutes ?? this.snapchatLimitMinutes,
    blockShopping: blockShopping ?? this.blockShopping,
    blockGambling: blockGambling ?? this.blockGambling,
    blockImageVideoSearch: blockImageVideoSearch ?? this.blockImageVideoSearch,
    appTimeLimitsEnabled: appTimeLimitsEnabled ?? this.appTimeLimitsEnabled,
    customAppsBlocklistEnabled:
        customAppsBlocklistEnabled ?? this.customAppsBlocklistEnabled,
    blockInAppBrowsers: blockInAppBrowsers ?? this.blockInAppBrowsers,
    preventUninstall: preventUninstall ?? this.preventUninstall,
    accountabilityPartnerEnabled:
        accountabilityPartnerEnabled ?? this.accountabilityPartnerEnabled,
    customBlockScreen: customBlockScreen ?? this.customBlockScreen,
    customWebsitesBlocklistEnabled:
        customWebsitesBlocklistEnabled ?? this.customWebsitesBlocklistEnabled,
    commitmentCycle: commitmentCycle ?? this.commitmentCycle,
    commitmentLockUntil: commitmentLockUntil.present
        ? commitmentLockUntil.value
        : this.commitmentLockUntil,
    commitmentMode: commitmentMode.present
        ? commitmentMode.value
        : this.commitmentMode,
    commitmentTotalDays: commitmentTotalDays ?? this.commitmentTotalDays,
    commitmentBreakCount: commitmentBreakCount ?? this.commitmentBreakCount,
    commitmentStartedAt: commitmentStartedAt.present
        ? commitmentStartedAt.value
        : this.commitmentStartedAt,
    protectionStartedAt: protectionStartedAt.present
        ? protectionStartedAt.value
        : this.protectionStartedAt,
    activePlan: activePlan.present ? activePlan.value : this.activePlan,
    termsAccepted: termsAccepted ?? this.termsAccepted,
    customBlocklist: customBlocklist.present
        ? customBlocklist.value
        : this.customBlocklist,
    customAllowlist: customAllowlist.present
        ? customAllowlist.value
        : this.customAllowlist,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BlockingSetting copyWithCompanion(BlockingSettingsCompanion data) {
    return BlockingSetting(
      id: data.id.present ? data.id.value : this.id,
      protectionEnabled: data.protectionEnabled.present
          ? data.protectionEnabled.value
          : this.protectionEnabled,
      strictnessLevel: data.strictnessLevel.present
          ? data.strictnessLevel.value
          : this.strictnessLevel,
      searchFilteringEnabled: data.searchFilteringEnabled.present
          ? data.searchFilteringEnabled.value
          : this.searchFilteringEnabled,
      socialMode: data.socialMode.present
          ? data.socialMode.value
          : this.socialMode,
      blockReels: data.blockReels.present
          ? data.blockReels.value
          : this.blockReels,
      blockShorts: data.blockShorts.present
          ? data.blockShorts.value
          : this.blockShorts,
      blockTikTok: data.blockTikTok.present
          ? data.blockTikTok.value
          : this.blockTikTok,
      blockSnapchatStories: data.blockSnapchatStories.present
          ? data.blockSnapchatStories.value
          : this.blockSnapchatStories,
      reelsLimitMinutes: data.reelsLimitMinutes.present
          ? data.reelsLimitMinutes.value
          : this.reelsLimitMinutes,
      shortsLimitMinutes: data.shortsLimitMinutes.present
          ? data.shortsLimitMinutes.value
          : this.shortsLimitMinutes,
      tiktokLimitMinutes: data.tiktokLimitMinutes.present
          ? data.tiktokLimitMinutes.value
          : this.tiktokLimitMinutes,
      snapchatLimitMinutes: data.snapchatLimitMinutes.present
          ? data.snapchatLimitMinutes.value
          : this.snapchatLimitMinutes,
      blockShopping: data.blockShopping.present
          ? data.blockShopping.value
          : this.blockShopping,
      blockGambling: data.blockGambling.present
          ? data.blockGambling.value
          : this.blockGambling,
      blockImageVideoSearch: data.blockImageVideoSearch.present
          ? data.blockImageVideoSearch.value
          : this.blockImageVideoSearch,
      appTimeLimitsEnabled: data.appTimeLimitsEnabled.present
          ? data.appTimeLimitsEnabled.value
          : this.appTimeLimitsEnabled,
      customAppsBlocklistEnabled: data.customAppsBlocklistEnabled.present
          ? data.customAppsBlocklistEnabled.value
          : this.customAppsBlocklistEnabled,
      blockInAppBrowsers: data.blockInAppBrowsers.present
          ? data.blockInAppBrowsers.value
          : this.blockInAppBrowsers,
      preventUninstall: data.preventUninstall.present
          ? data.preventUninstall.value
          : this.preventUninstall,
      accountabilityPartnerEnabled: data.accountabilityPartnerEnabled.present
          ? data.accountabilityPartnerEnabled.value
          : this.accountabilityPartnerEnabled,
      customBlockScreen: data.customBlockScreen.present
          ? data.customBlockScreen.value
          : this.customBlockScreen,
      customWebsitesBlocklistEnabled:
          data.customWebsitesBlocklistEnabled.present
          ? data.customWebsitesBlocklistEnabled.value
          : this.customWebsitesBlocklistEnabled,
      commitmentCycle: data.commitmentCycle.present
          ? data.commitmentCycle.value
          : this.commitmentCycle,
      commitmentLockUntil: data.commitmentLockUntil.present
          ? data.commitmentLockUntil.value
          : this.commitmentLockUntil,
      commitmentMode: data.commitmentMode.present
          ? data.commitmentMode.value
          : this.commitmentMode,
      commitmentTotalDays: data.commitmentTotalDays.present
          ? data.commitmentTotalDays.value
          : this.commitmentTotalDays,
      commitmentBreakCount: data.commitmentBreakCount.present
          ? data.commitmentBreakCount.value
          : this.commitmentBreakCount,
      commitmentStartedAt: data.commitmentStartedAt.present
          ? data.commitmentStartedAt.value
          : this.commitmentStartedAt,
      protectionStartedAt: data.protectionStartedAt.present
          ? data.protectionStartedAt.value
          : this.protectionStartedAt,
      activePlan: data.activePlan.present
          ? data.activePlan.value
          : this.activePlan,
      termsAccepted: data.termsAccepted.present
          ? data.termsAccepted.value
          : this.termsAccepted,
      customBlocklist: data.customBlocklist.present
          ? data.customBlocklist.value
          : this.customBlocklist,
      customAllowlist: data.customAllowlist.present
          ? data.customAllowlist.value
          : this.customAllowlist,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockingSetting(')
          ..write('id: $id, ')
          ..write('protectionEnabled: $protectionEnabled, ')
          ..write('strictnessLevel: $strictnessLevel, ')
          ..write('searchFilteringEnabled: $searchFilteringEnabled, ')
          ..write('socialMode: $socialMode, ')
          ..write('blockReels: $blockReels, ')
          ..write('blockShorts: $blockShorts, ')
          ..write('blockTikTok: $blockTikTok, ')
          ..write('blockSnapchatStories: $blockSnapchatStories, ')
          ..write('reelsLimitMinutes: $reelsLimitMinutes, ')
          ..write('shortsLimitMinutes: $shortsLimitMinutes, ')
          ..write('tiktokLimitMinutes: $tiktokLimitMinutes, ')
          ..write('snapchatLimitMinutes: $snapchatLimitMinutes, ')
          ..write('blockShopping: $blockShopping, ')
          ..write('blockGambling: $blockGambling, ')
          ..write('blockImageVideoSearch: $blockImageVideoSearch, ')
          ..write('appTimeLimitsEnabled: $appTimeLimitsEnabled, ')
          ..write('customAppsBlocklistEnabled: $customAppsBlocklistEnabled, ')
          ..write('blockInAppBrowsers: $blockInAppBrowsers, ')
          ..write('preventUninstall: $preventUninstall, ')
          ..write(
            'accountabilityPartnerEnabled: $accountabilityPartnerEnabled, ',
          )
          ..write('customBlockScreen: $customBlockScreen, ')
          ..write(
            'customWebsitesBlocklistEnabled: $customWebsitesBlocklistEnabled, ',
          )
          ..write('commitmentCycle: $commitmentCycle, ')
          ..write('commitmentLockUntil: $commitmentLockUntil, ')
          ..write('commitmentMode: $commitmentMode, ')
          ..write('commitmentTotalDays: $commitmentTotalDays, ')
          ..write('commitmentBreakCount: $commitmentBreakCount, ')
          ..write('commitmentStartedAt: $commitmentStartedAt, ')
          ..write('protectionStartedAt: $protectionStartedAt, ')
          ..write('activePlan: $activePlan, ')
          ..write('termsAccepted: $termsAccepted, ')
          ..write('customBlocklist: $customBlocklist, ')
          ..write('customAllowlist: $customAllowlist, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    protectionEnabled,
    strictnessLevel,
    searchFilteringEnabled,
    socialMode,
    blockReels,
    blockShorts,
    blockTikTok,
    blockSnapchatStories,
    reelsLimitMinutes,
    shortsLimitMinutes,
    tiktokLimitMinutes,
    snapchatLimitMinutes,
    blockShopping,
    blockGambling,
    blockImageVideoSearch,
    appTimeLimitsEnabled,
    customAppsBlocklistEnabled,
    blockInAppBrowsers,
    preventUninstall,
    accountabilityPartnerEnabled,
    customBlockScreen,
    customWebsitesBlocklistEnabled,
    commitmentCycle,
    commitmentLockUntil,
    commitmentMode,
    commitmentTotalDays,
    commitmentBreakCount,
    commitmentStartedAt,
    protectionStartedAt,
    activePlan,
    termsAccepted,
    customBlocklist,
    customAllowlist,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockingSetting &&
          other.id == this.id &&
          other.protectionEnabled == this.protectionEnabled &&
          other.strictnessLevel == this.strictnessLevel &&
          other.searchFilteringEnabled == this.searchFilteringEnabled &&
          other.socialMode == this.socialMode &&
          other.blockReels == this.blockReels &&
          other.blockShorts == this.blockShorts &&
          other.blockTikTok == this.blockTikTok &&
          other.blockSnapchatStories == this.blockSnapchatStories &&
          other.reelsLimitMinutes == this.reelsLimitMinutes &&
          other.shortsLimitMinutes == this.shortsLimitMinutes &&
          other.tiktokLimitMinutes == this.tiktokLimitMinutes &&
          other.snapchatLimitMinutes == this.snapchatLimitMinutes &&
          other.blockShopping == this.blockShopping &&
          other.blockGambling == this.blockGambling &&
          other.blockImageVideoSearch == this.blockImageVideoSearch &&
          other.appTimeLimitsEnabled == this.appTimeLimitsEnabled &&
          other.customAppsBlocklistEnabled == this.customAppsBlocklistEnabled &&
          other.blockInAppBrowsers == this.blockInAppBrowsers &&
          other.preventUninstall == this.preventUninstall &&
          other.accountabilityPartnerEnabled ==
              this.accountabilityPartnerEnabled &&
          other.customBlockScreen == this.customBlockScreen &&
          other.customWebsitesBlocklistEnabled ==
              this.customWebsitesBlocklistEnabled &&
          other.commitmentCycle == this.commitmentCycle &&
          other.commitmentLockUntil == this.commitmentLockUntil &&
          other.commitmentMode == this.commitmentMode &&
          other.commitmentTotalDays == this.commitmentTotalDays &&
          other.commitmentBreakCount == this.commitmentBreakCount &&
          other.commitmentStartedAt == this.commitmentStartedAt &&
          other.protectionStartedAt == this.protectionStartedAt &&
          other.activePlan == this.activePlan &&
          other.termsAccepted == this.termsAccepted &&
          other.customBlocklist == this.customBlocklist &&
          other.customAllowlist == this.customAllowlist &&
          other.updatedAt == this.updatedAt);
}

class BlockingSettingsCompanion extends UpdateCompanion<BlockingSetting> {
  final Value<int> id;
  final Value<bool> protectionEnabled;
  final Value<String> strictnessLevel;
  final Value<bool> searchFilteringEnabled;
  final Value<String> socialMode;
  final Value<bool> blockReels;
  final Value<bool> blockShorts;
  final Value<bool> blockTikTok;
  final Value<bool> blockSnapchatStories;
  final Value<int> reelsLimitMinutes;
  final Value<int> shortsLimitMinutes;
  final Value<int> tiktokLimitMinutes;
  final Value<int> snapchatLimitMinutes;
  final Value<bool> blockShopping;
  final Value<bool> blockGambling;
  final Value<bool> blockImageVideoSearch;
  final Value<bool> appTimeLimitsEnabled;
  final Value<bool> customAppsBlocklistEnabled;
  final Value<bool> blockInAppBrowsers;
  final Value<bool> preventUninstall;
  final Value<bool> accountabilityPartnerEnabled;
  final Value<bool> customBlockScreen;
  final Value<bool> customWebsitesBlocklistEnabled;
  final Value<int> commitmentCycle;
  final Value<DateTime?> commitmentLockUntil;
  final Value<String?> commitmentMode;
  final Value<int> commitmentTotalDays;
  final Value<int> commitmentBreakCount;
  final Value<DateTime?> commitmentStartedAt;
  final Value<DateTime?> protectionStartedAt;
  final Value<String?> activePlan;
  final Value<bool> termsAccepted;
  final Value<String?> customBlocklist;
  final Value<String?> customAllowlist;
  final Value<DateTime> updatedAt;
  const BlockingSettingsCompanion({
    this.id = const Value.absent(),
    this.protectionEnabled = const Value.absent(),
    this.strictnessLevel = const Value.absent(),
    this.searchFilteringEnabled = const Value.absent(),
    this.socialMode = const Value.absent(),
    this.blockReels = const Value.absent(),
    this.blockShorts = const Value.absent(),
    this.blockTikTok = const Value.absent(),
    this.blockSnapchatStories = const Value.absent(),
    this.reelsLimitMinutes = const Value.absent(),
    this.shortsLimitMinutes = const Value.absent(),
    this.tiktokLimitMinutes = const Value.absent(),
    this.snapchatLimitMinutes = const Value.absent(),
    this.blockShopping = const Value.absent(),
    this.blockGambling = const Value.absent(),
    this.blockImageVideoSearch = const Value.absent(),
    this.appTimeLimitsEnabled = const Value.absent(),
    this.customAppsBlocklistEnabled = const Value.absent(),
    this.blockInAppBrowsers = const Value.absent(),
    this.preventUninstall = const Value.absent(),
    this.accountabilityPartnerEnabled = const Value.absent(),
    this.customBlockScreen = const Value.absent(),
    this.customWebsitesBlocklistEnabled = const Value.absent(),
    this.commitmentCycle = const Value.absent(),
    this.commitmentLockUntil = const Value.absent(),
    this.commitmentMode = const Value.absent(),
    this.commitmentTotalDays = const Value.absent(),
    this.commitmentBreakCount = const Value.absent(),
    this.commitmentStartedAt = const Value.absent(),
    this.protectionStartedAt = const Value.absent(),
    this.activePlan = const Value.absent(),
    this.termsAccepted = const Value.absent(),
    this.customBlocklist = const Value.absent(),
    this.customAllowlist = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BlockingSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.protectionEnabled = const Value.absent(),
    this.strictnessLevel = const Value.absent(),
    this.searchFilteringEnabled = const Value.absent(),
    this.socialMode = const Value.absent(),
    this.blockReels = const Value.absent(),
    this.blockShorts = const Value.absent(),
    this.blockTikTok = const Value.absent(),
    this.blockSnapchatStories = const Value.absent(),
    this.reelsLimitMinutes = const Value.absent(),
    this.shortsLimitMinutes = const Value.absent(),
    this.tiktokLimitMinutes = const Value.absent(),
    this.snapchatLimitMinutes = const Value.absent(),
    this.blockShopping = const Value.absent(),
    this.blockGambling = const Value.absent(),
    this.blockImageVideoSearch = const Value.absent(),
    this.appTimeLimitsEnabled = const Value.absent(),
    this.customAppsBlocklistEnabled = const Value.absent(),
    this.blockInAppBrowsers = const Value.absent(),
    this.preventUninstall = const Value.absent(),
    this.accountabilityPartnerEnabled = const Value.absent(),
    this.customBlockScreen = const Value.absent(),
    this.customWebsitesBlocklistEnabled = const Value.absent(),
    this.commitmentCycle = const Value.absent(),
    this.commitmentLockUntil = const Value.absent(),
    this.commitmentMode = const Value.absent(),
    this.commitmentTotalDays = const Value.absent(),
    this.commitmentBreakCount = const Value.absent(),
    this.commitmentStartedAt = const Value.absent(),
    this.protectionStartedAt = const Value.absent(),
    this.activePlan = const Value.absent(),
    this.termsAccepted = const Value.absent(),
    this.customBlocklist = const Value.absent(),
    this.customAllowlist = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<BlockingSetting> custom({
    Expression<int>? id,
    Expression<bool>? protectionEnabled,
    Expression<String>? strictnessLevel,
    Expression<bool>? searchFilteringEnabled,
    Expression<String>? socialMode,
    Expression<bool>? blockReels,
    Expression<bool>? blockShorts,
    Expression<bool>? blockTikTok,
    Expression<bool>? blockSnapchatStories,
    Expression<int>? reelsLimitMinutes,
    Expression<int>? shortsLimitMinutes,
    Expression<int>? tiktokLimitMinutes,
    Expression<int>? snapchatLimitMinutes,
    Expression<bool>? blockShopping,
    Expression<bool>? blockGambling,
    Expression<bool>? blockImageVideoSearch,
    Expression<bool>? appTimeLimitsEnabled,
    Expression<bool>? customAppsBlocklistEnabled,
    Expression<bool>? blockInAppBrowsers,
    Expression<bool>? preventUninstall,
    Expression<bool>? accountabilityPartnerEnabled,
    Expression<bool>? customBlockScreen,
    Expression<bool>? customWebsitesBlocklistEnabled,
    Expression<int>? commitmentCycle,
    Expression<DateTime>? commitmentLockUntil,
    Expression<String>? commitmentMode,
    Expression<int>? commitmentTotalDays,
    Expression<int>? commitmentBreakCount,
    Expression<DateTime>? commitmentStartedAt,
    Expression<DateTime>? protectionStartedAt,
    Expression<String>? activePlan,
    Expression<bool>? termsAccepted,
    Expression<String>? customBlocklist,
    Expression<String>? customAllowlist,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (protectionEnabled != null) 'protection_enabled': protectionEnabled,
      if (strictnessLevel != null) 'strictness_level': strictnessLevel,
      if (searchFilteringEnabled != null)
        'search_filtering_enabled': searchFilteringEnabled,
      if (socialMode != null) 'social_mode': socialMode,
      if (blockReels != null) 'block_reels': blockReels,
      if (blockShorts != null) 'block_shorts': blockShorts,
      if (blockTikTok != null) 'block_tik_tok': blockTikTok,
      if (blockSnapchatStories != null)
        'block_snapchat_stories': blockSnapchatStories,
      if (reelsLimitMinutes != null) 'reels_limit_minutes': reelsLimitMinutes,
      if (shortsLimitMinutes != null)
        'shorts_limit_minutes': shortsLimitMinutes,
      if (tiktokLimitMinutes != null)
        'tiktok_limit_minutes': tiktokLimitMinutes,
      if (snapchatLimitMinutes != null)
        'snapchat_limit_minutes': snapchatLimitMinutes,
      if (blockShopping != null) 'block_shopping': blockShopping,
      if (blockGambling != null) 'block_gambling': blockGambling,
      if (blockImageVideoSearch != null)
        'block_image_video_search': blockImageVideoSearch,
      if (appTimeLimitsEnabled != null)
        'app_time_limits_enabled': appTimeLimitsEnabled,
      if (customAppsBlocklistEnabled != null)
        'custom_apps_blocklist_enabled': customAppsBlocklistEnabled,
      if (blockInAppBrowsers != null)
        'block_in_app_browsers': blockInAppBrowsers,
      if (preventUninstall != null) 'prevent_uninstall': preventUninstall,
      if (accountabilityPartnerEnabled != null)
        'accountability_partner_enabled': accountabilityPartnerEnabled,
      if (customBlockScreen != null) 'custom_block_screen': customBlockScreen,
      if (customWebsitesBlocklistEnabled != null)
        'custom_websites_blocklist_enabled': customWebsitesBlocklistEnabled,
      if (commitmentCycle != null) 'commitment_cycle': commitmentCycle,
      if (commitmentLockUntil != null)
        'commitment_lock_until': commitmentLockUntil,
      if (commitmentMode != null) 'commitment_mode': commitmentMode,
      if (commitmentTotalDays != null)
        'commitment_total_days': commitmentTotalDays,
      if (commitmentBreakCount != null)
        'commitment_break_count': commitmentBreakCount,
      if (commitmentStartedAt != null)
        'commitment_started_at': commitmentStartedAt,
      if (protectionStartedAt != null)
        'protection_started_at': protectionStartedAt,
      if (activePlan != null) 'active_plan': activePlan,
      if (termsAccepted != null) 'terms_accepted': termsAccepted,
      if (customBlocklist != null) 'custom_blocklist': customBlocklist,
      if (customAllowlist != null) 'custom_allowlist': customAllowlist,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BlockingSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? protectionEnabled,
    Value<String>? strictnessLevel,
    Value<bool>? searchFilteringEnabled,
    Value<String>? socialMode,
    Value<bool>? blockReels,
    Value<bool>? blockShorts,
    Value<bool>? blockTikTok,
    Value<bool>? blockSnapchatStories,
    Value<int>? reelsLimitMinutes,
    Value<int>? shortsLimitMinutes,
    Value<int>? tiktokLimitMinutes,
    Value<int>? snapchatLimitMinutes,
    Value<bool>? blockShopping,
    Value<bool>? blockGambling,
    Value<bool>? blockImageVideoSearch,
    Value<bool>? appTimeLimitsEnabled,
    Value<bool>? customAppsBlocklistEnabled,
    Value<bool>? blockInAppBrowsers,
    Value<bool>? preventUninstall,
    Value<bool>? accountabilityPartnerEnabled,
    Value<bool>? customBlockScreen,
    Value<bool>? customWebsitesBlocklistEnabled,
    Value<int>? commitmentCycle,
    Value<DateTime?>? commitmentLockUntil,
    Value<String?>? commitmentMode,
    Value<int>? commitmentTotalDays,
    Value<int>? commitmentBreakCount,
    Value<DateTime?>? commitmentStartedAt,
    Value<DateTime?>? protectionStartedAt,
    Value<String?>? activePlan,
    Value<bool>? termsAccepted,
    Value<String?>? customBlocklist,
    Value<String?>? customAllowlist,
    Value<DateTime>? updatedAt,
  }) {
    return BlockingSettingsCompanion(
      id: id ?? this.id,
      protectionEnabled: protectionEnabled ?? this.protectionEnabled,
      strictnessLevel: strictnessLevel ?? this.strictnessLevel,
      searchFilteringEnabled:
          searchFilteringEnabled ?? this.searchFilteringEnabled,
      socialMode: socialMode ?? this.socialMode,
      blockReels: blockReels ?? this.blockReels,
      blockShorts: blockShorts ?? this.blockShorts,
      blockTikTok: blockTikTok ?? this.blockTikTok,
      blockSnapchatStories: blockSnapchatStories ?? this.blockSnapchatStories,
      reelsLimitMinutes: reelsLimitMinutes ?? this.reelsLimitMinutes,
      shortsLimitMinutes: shortsLimitMinutes ?? this.shortsLimitMinutes,
      tiktokLimitMinutes: tiktokLimitMinutes ?? this.tiktokLimitMinutes,
      snapchatLimitMinutes: snapchatLimitMinutes ?? this.snapchatLimitMinutes,
      blockShopping: blockShopping ?? this.blockShopping,
      blockGambling: blockGambling ?? this.blockGambling,
      blockImageVideoSearch:
          blockImageVideoSearch ?? this.blockImageVideoSearch,
      appTimeLimitsEnabled: appTimeLimitsEnabled ?? this.appTimeLimitsEnabled,
      customAppsBlocklistEnabled:
          customAppsBlocklistEnabled ?? this.customAppsBlocklistEnabled,
      blockInAppBrowsers: blockInAppBrowsers ?? this.blockInAppBrowsers,
      preventUninstall: preventUninstall ?? this.preventUninstall,
      accountabilityPartnerEnabled:
          accountabilityPartnerEnabled ?? this.accountabilityPartnerEnabled,
      customBlockScreen: customBlockScreen ?? this.customBlockScreen,
      customWebsitesBlocklistEnabled:
          customWebsitesBlocklistEnabled ?? this.customWebsitesBlocklistEnabled,
      commitmentCycle: commitmentCycle ?? this.commitmentCycle,
      commitmentLockUntil: commitmentLockUntil ?? this.commitmentLockUntil,
      commitmentMode: commitmentMode ?? this.commitmentMode,
      commitmentTotalDays: commitmentTotalDays ?? this.commitmentTotalDays,
      commitmentBreakCount: commitmentBreakCount ?? this.commitmentBreakCount,
      commitmentStartedAt: commitmentStartedAt ?? this.commitmentStartedAt,
      protectionStartedAt: protectionStartedAt ?? this.protectionStartedAt,
      activePlan: activePlan ?? this.activePlan,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      customBlocklist: customBlocklist ?? this.customBlocklist,
      customAllowlist: customAllowlist ?? this.customAllowlist,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (protectionEnabled.present) {
      map['protection_enabled'] = Variable<bool>(protectionEnabled.value);
    }
    if (strictnessLevel.present) {
      map['strictness_level'] = Variable<String>(strictnessLevel.value);
    }
    if (searchFilteringEnabled.present) {
      map['search_filtering_enabled'] = Variable<bool>(
        searchFilteringEnabled.value,
      );
    }
    if (socialMode.present) {
      map['social_mode'] = Variable<String>(socialMode.value);
    }
    if (blockReels.present) {
      map['block_reels'] = Variable<bool>(blockReels.value);
    }
    if (blockShorts.present) {
      map['block_shorts'] = Variable<bool>(blockShorts.value);
    }
    if (blockTikTok.present) {
      map['block_tik_tok'] = Variable<bool>(blockTikTok.value);
    }
    if (blockSnapchatStories.present) {
      map['block_snapchat_stories'] = Variable<bool>(
        blockSnapchatStories.value,
      );
    }
    if (reelsLimitMinutes.present) {
      map['reels_limit_minutes'] = Variable<int>(reelsLimitMinutes.value);
    }
    if (shortsLimitMinutes.present) {
      map['shorts_limit_minutes'] = Variable<int>(shortsLimitMinutes.value);
    }
    if (tiktokLimitMinutes.present) {
      map['tiktok_limit_minutes'] = Variable<int>(tiktokLimitMinutes.value);
    }
    if (snapchatLimitMinutes.present) {
      map['snapchat_limit_minutes'] = Variable<int>(snapchatLimitMinutes.value);
    }
    if (blockShopping.present) {
      map['block_shopping'] = Variable<bool>(blockShopping.value);
    }
    if (blockGambling.present) {
      map['block_gambling'] = Variable<bool>(blockGambling.value);
    }
    if (blockImageVideoSearch.present) {
      map['block_image_video_search'] = Variable<bool>(
        blockImageVideoSearch.value,
      );
    }
    if (appTimeLimitsEnabled.present) {
      map['app_time_limits_enabled'] = Variable<bool>(
        appTimeLimitsEnabled.value,
      );
    }
    if (customAppsBlocklistEnabled.present) {
      map['custom_apps_blocklist_enabled'] = Variable<bool>(
        customAppsBlocklistEnabled.value,
      );
    }
    if (blockInAppBrowsers.present) {
      map['block_in_app_browsers'] = Variable<bool>(blockInAppBrowsers.value);
    }
    if (preventUninstall.present) {
      map['prevent_uninstall'] = Variable<bool>(preventUninstall.value);
    }
    if (accountabilityPartnerEnabled.present) {
      map['accountability_partner_enabled'] = Variable<bool>(
        accountabilityPartnerEnabled.value,
      );
    }
    if (customBlockScreen.present) {
      map['custom_block_screen'] = Variable<bool>(customBlockScreen.value);
    }
    if (customWebsitesBlocklistEnabled.present) {
      map['custom_websites_blocklist_enabled'] = Variable<bool>(
        customWebsitesBlocklistEnabled.value,
      );
    }
    if (commitmentCycle.present) {
      map['commitment_cycle'] = Variable<int>(commitmentCycle.value);
    }
    if (commitmentLockUntil.present) {
      map['commitment_lock_until'] = Variable<DateTime>(
        commitmentLockUntil.value,
      );
    }
    if (commitmentMode.present) {
      map['commitment_mode'] = Variable<String>(commitmentMode.value);
    }
    if (commitmentTotalDays.present) {
      map['commitment_total_days'] = Variable<int>(commitmentTotalDays.value);
    }
    if (commitmentBreakCount.present) {
      map['commitment_break_count'] = Variable<int>(commitmentBreakCount.value);
    }
    if (commitmentStartedAt.present) {
      map['commitment_started_at'] = Variable<DateTime>(
        commitmentStartedAt.value,
      );
    }
    if (protectionStartedAt.present) {
      map['protection_started_at'] = Variable<DateTime>(
        protectionStartedAt.value,
      );
    }
    if (activePlan.present) {
      map['active_plan'] = Variable<String>(activePlan.value);
    }
    if (termsAccepted.present) {
      map['terms_accepted'] = Variable<bool>(termsAccepted.value);
    }
    if (customBlocklist.present) {
      map['custom_blocklist'] = Variable<String>(customBlocklist.value);
    }
    if (customAllowlist.present) {
      map['custom_allowlist'] = Variable<String>(customAllowlist.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockingSettingsCompanion(')
          ..write('id: $id, ')
          ..write('protectionEnabled: $protectionEnabled, ')
          ..write('strictnessLevel: $strictnessLevel, ')
          ..write('searchFilteringEnabled: $searchFilteringEnabled, ')
          ..write('socialMode: $socialMode, ')
          ..write('blockReels: $blockReels, ')
          ..write('blockShorts: $blockShorts, ')
          ..write('blockTikTok: $blockTikTok, ')
          ..write('blockSnapchatStories: $blockSnapchatStories, ')
          ..write('reelsLimitMinutes: $reelsLimitMinutes, ')
          ..write('shortsLimitMinutes: $shortsLimitMinutes, ')
          ..write('tiktokLimitMinutes: $tiktokLimitMinutes, ')
          ..write('snapchatLimitMinutes: $snapchatLimitMinutes, ')
          ..write('blockShopping: $blockShopping, ')
          ..write('blockGambling: $blockGambling, ')
          ..write('blockImageVideoSearch: $blockImageVideoSearch, ')
          ..write('appTimeLimitsEnabled: $appTimeLimitsEnabled, ')
          ..write('customAppsBlocklistEnabled: $customAppsBlocklistEnabled, ')
          ..write('blockInAppBrowsers: $blockInAppBrowsers, ')
          ..write('preventUninstall: $preventUninstall, ')
          ..write(
            'accountabilityPartnerEnabled: $accountabilityPartnerEnabled, ',
          )
          ..write('customBlockScreen: $customBlockScreen, ')
          ..write(
            'customWebsitesBlocklistEnabled: $customWebsitesBlocklistEnabled, ',
          )
          ..write('commitmentCycle: $commitmentCycle, ')
          ..write('commitmentLockUntil: $commitmentLockUntil, ')
          ..write('commitmentMode: $commitmentMode, ')
          ..write('commitmentTotalDays: $commitmentTotalDays, ')
          ..write('commitmentBreakCount: $commitmentBreakCount, ')
          ..write('commitmentStartedAt: $commitmentStartedAt, ')
          ..write('protectionStartedAt: $protectionStartedAt, ')
          ..write('activePlan: $activePlan, ')
          ..write('termsAccepted: $termsAccepted, ')
          ..write('customBlocklist: $customBlocklist, ')
          ..write('customAllowlist: $customAllowlist, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserAssessmentsTable userAssessments = $UserAssessmentsTable(
    this,
  );
  late final $BlockingSettingsTable blockingSettings = $BlockingSettingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userAssessments,
    blockingSettings,
  ];
}

typedef $$UserAssessmentsTableCreateCompanionBuilder =
    UserAssessmentsCompanion Function({
      Value<int> id,
      required int totalScore,
      required int percentage,
      required String level,
      required String recommendedPlanId,
      required DateTime createdAt,
    });
typedef $$UserAssessmentsTableUpdateCompanionBuilder =
    UserAssessmentsCompanion Function({
      Value<int> id,
      Value<int> totalScore,
      Value<int> percentage,
      Value<String> level,
      Value<String> recommendedPlanId,
      Value<DateTime> createdAt,
    });

class $$UserAssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $UserAssessmentsTable> {
  $$UserAssessmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedPlanId => $composableBuilder(
    column: $table.recommendedPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserAssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserAssessmentsTable> {
  $$UserAssessmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedPlanId => $composableBuilder(
    column: $table.recommendedPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserAssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserAssessmentsTable> {
  $$UserAssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get recommendedPlanId => $composableBuilder(
    column: $table.recommendedPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserAssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserAssessmentsTable,
          UserAssessment,
          $$UserAssessmentsTableFilterComposer,
          $$UserAssessmentsTableOrderingComposer,
          $$UserAssessmentsTableAnnotationComposer,
          $$UserAssessmentsTableCreateCompanionBuilder,
          $$UserAssessmentsTableUpdateCompanionBuilder,
          (
            UserAssessment,
            BaseReferences<
              _$AppDatabase,
              $UserAssessmentsTable,
              UserAssessment
            >,
          ),
          UserAssessment,
          PrefetchHooks Function()
        > {
  $$UserAssessmentsTableTableManager(
    _$AppDatabase db,
    $UserAssessmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserAssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserAssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserAssessmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> percentage = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> recommendedPlanId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserAssessmentsCompanion(
                id: id,
                totalScore: totalScore,
                percentage: percentage,
                level: level,
                recommendedPlanId: recommendedPlanId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int totalScore,
                required int percentage,
                required String level,
                required String recommendedPlanId,
                required DateTime createdAt,
              }) => UserAssessmentsCompanion.insert(
                id: id,
                totalScore: totalScore,
                percentage: percentage,
                level: level,
                recommendedPlanId: recommendedPlanId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserAssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserAssessmentsTable,
      UserAssessment,
      $$UserAssessmentsTableFilterComposer,
      $$UserAssessmentsTableOrderingComposer,
      $$UserAssessmentsTableAnnotationComposer,
      $$UserAssessmentsTableCreateCompanionBuilder,
      $$UserAssessmentsTableUpdateCompanionBuilder,
      (
        UserAssessment,
        BaseReferences<_$AppDatabase, $UserAssessmentsTable, UserAssessment>,
      ),
      UserAssessment,
      PrefetchHooks Function()
    >;
typedef $$BlockingSettingsTableCreateCompanionBuilder =
    BlockingSettingsCompanion Function({
      Value<int> id,
      Value<bool> protectionEnabled,
      Value<String> strictnessLevel,
      Value<bool> searchFilteringEnabled,
      Value<String> socialMode,
      Value<bool> blockReels,
      Value<bool> blockShorts,
      Value<bool> blockTikTok,
      Value<bool> blockSnapchatStories,
      Value<int> reelsLimitMinutes,
      Value<int> shortsLimitMinutes,
      Value<int> tiktokLimitMinutes,
      Value<int> snapchatLimitMinutes,
      Value<bool> blockShopping,
      Value<bool> blockGambling,
      Value<bool> blockImageVideoSearch,
      Value<bool> appTimeLimitsEnabled,
      Value<bool> customAppsBlocklistEnabled,
      Value<bool> blockInAppBrowsers,
      Value<bool> preventUninstall,
      Value<bool> accountabilityPartnerEnabled,
      Value<bool> customBlockScreen,
      Value<bool> customWebsitesBlocklistEnabled,
      Value<int> commitmentCycle,
      Value<DateTime?> commitmentLockUntil,
      Value<String?> commitmentMode,
      Value<int> commitmentTotalDays,
      Value<int> commitmentBreakCount,
      Value<DateTime?> commitmentStartedAt,
      Value<DateTime?> protectionStartedAt,
      Value<String?> activePlan,
      Value<bool> termsAccepted,
      Value<String?> customBlocklist,
      Value<String?> customAllowlist,
      Value<DateTime> updatedAt,
    });
typedef $$BlockingSettingsTableUpdateCompanionBuilder =
    BlockingSettingsCompanion Function({
      Value<int> id,
      Value<bool> protectionEnabled,
      Value<String> strictnessLevel,
      Value<bool> searchFilteringEnabled,
      Value<String> socialMode,
      Value<bool> blockReels,
      Value<bool> blockShorts,
      Value<bool> blockTikTok,
      Value<bool> blockSnapchatStories,
      Value<int> reelsLimitMinutes,
      Value<int> shortsLimitMinutes,
      Value<int> tiktokLimitMinutes,
      Value<int> snapchatLimitMinutes,
      Value<bool> blockShopping,
      Value<bool> blockGambling,
      Value<bool> blockImageVideoSearch,
      Value<bool> appTimeLimitsEnabled,
      Value<bool> customAppsBlocklistEnabled,
      Value<bool> blockInAppBrowsers,
      Value<bool> preventUninstall,
      Value<bool> accountabilityPartnerEnabled,
      Value<bool> customBlockScreen,
      Value<bool> customWebsitesBlocklistEnabled,
      Value<int> commitmentCycle,
      Value<DateTime?> commitmentLockUntil,
      Value<String?> commitmentMode,
      Value<int> commitmentTotalDays,
      Value<int> commitmentBreakCount,
      Value<DateTime?> commitmentStartedAt,
      Value<DateTime?> protectionStartedAt,
      Value<String?> activePlan,
      Value<bool> termsAccepted,
      Value<String?> customBlocklist,
      Value<String?> customAllowlist,
      Value<DateTime> updatedAt,
    });

class $$BlockingSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BlockingSettingsTable> {
  $$BlockingSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get protectionEnabled => $composableBuilder(
    column: $table.protectionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strictnessLevel => $composableBuilder(
    column: $table.strictnessLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get searchFilteringEnabled => $composableBuilder(
    column: $table.searchFilteringEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get socialMode => $composableBuilder(
    column: $table.socialMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockReels => $composableBuilder(
    column: $table.blockReels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockShorts => $composableBuilder(
    column: $table.blockShorts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockTikTok => $composableBuilder(
    column: $table.blockTikTok,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockSnapchatStories => $composableBuilder(
    column: $table.blockSnapchatStories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reelsLimitMinutes => $composableBuilder(
    column: $table.reelsLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shortsLimitMinutes => $composableBuilder(
    column: $table.shortsLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tiktokLimitMinutes => $composableBuilder(
    column: $table.tiktokLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snapchatLimitMinutes => $composableBuilder(
    column: $table.snapchatLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockShopping => $composableBuilder(
    column: $table.blockShopping,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockGambling => $composableBuilder(
    column: $table.blockGambling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockImageVideoSearch => $composableBuilder(
    column: $table.blockImageVideoSearch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appTimeLimitsEnabled => $composableBuilder(
    column: $table.appTimeLimitsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get customAppsBlocklistEnabled => $composableBuilder(
    column: $table.customAppsBlocklistEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockInAppBrowsers => $composableBuilder(
    column: $table.blockInAppBrowsers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get preventUninstall => $composableBuilder(
    column: $table.preventUninstall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get accountabilityPartnerEnabled => $composableBuilder(
    column: $table.accountabilityPartnerEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get customBlockScreen => $composableBuilder(
    column: $table.customBlockScreen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get customWebsitesBlocklistEnabled => $composableBuilder(
    column: $table.customWebsitesBlocklistEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commitmentCycle => $composableBuilder(
    column: $table.commitmentCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get commitmentLockUntil => $composableBuilder(
    column: $table.commitmentLockUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commitmentMode => $composableBuilder(
    column: $table.commitmentMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commitmentTotalDays => $composableBuilder(
    column: $table.commitmentTotalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commitmentBreakCount => $composableBuilder(
    column: $table.commitmentBreakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get commitmentStartedAt => $composableBuilder(
    column: $table.commitmentStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get protectionStartedAt => $composableBuilder(
    column: $table.protectionStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activePlan => $composableBuilder(
    column: $table.activePlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get termsAccepted => $composableBuilder(
    column: $table.termsAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customBlocklist => $composableBuilder(
    column: $table.customBlocklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customAllowlist => $composableBuilder(
    column: $table.customAllowlist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlockingSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BlockingSettingsTable> {
  $$BlockingSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get protectionEnabled => $composableBuilder(
    column: $table.protectionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strictnessLevel => $composableBuilder(
    column: $table.strictnessLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get searchFilteringEnabled => $composableBuilder(
    column: $table.searchFilteringEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get socialMode => $composableBuilder(
    column: $table.socialMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockReels => $composableBuilder(
    column: $table.blockReels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockShorts => $composableBuilder(
    column: $table.blockShorts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockTikTok => $composableBuilder(
    column: $table.blockTikTok,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockSnapchatStories => $composableBuilder(
    column: $table.blockSnapchatStories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reelsLimitMinutes => $composableBuilder(
    column: $table.reelsLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shortsLimitMinutes => $composableBuilder(
    column: $table.shortsLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tiktokLimitMinutes => $composableBuilder(
    column: $table.tiktokLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snapchatLimitMinutes => $composableBuilder(
    column: $table.snapchatLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockShopping => $composableBuilder(
    column: $table.blockShopping,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockGambling => $composableBuilder(
    column: $table.blockGambling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockImageVideoSearch => $composableBuilder(
    column: $table.blockImageVideoSearch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appTimeLimitsEnabled => $composableBuilder(
    column: $table.appTimeLimitsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get customAppsBlocklistEnabled => $composableBuilder(
    column: $table.customAppsBlocklistEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockInAppBrowsers => $composableBuilder(
    column: $table.blockInAppBrowsers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get preventUninstall => $composableBuilder(
    column: $table.preventUninstall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get accountabilityPartnerEnabled => $composableBuilder(
    column: $table.accountabilityPartnerEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get customBlockScreen => $composableBuilder(
    column: $table.customBlockScreen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get customWebsitesBlocklistEnabled =>
      $composableBuilder(
        column: $table.customWebsitesBlocklistEnabled,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get commitmentCycle => $composableBuilder(
    column: $table.commitmentCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get commitmentLockUntil => $composableBuilder(
    column: $table.commitmentLockUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commitmentMode => $composableBuilder(
    column: $table.commitmentMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commitmentTotalDays => $composableBuilder(
    column: $table.commitmentTotalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commitmentBreakCount => $composableBuilder(
    column: $table.commitmentBreakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get commitmentStartedAt => $composableBuilder(
    column: $table.commitmentStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get protectionStartedAt => $composableBuilder(
    column: $table.protectionStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activePlan => $composableBuilder(
    column: $table.activePlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get termsAccepted => $composableBuilder(
    column: $table.termsAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customBlocklist => $composableBuilder(
    column: $table.customBlocklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customAllowlist => $composableBuilder(
    column: $table.customAllowlist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlockingSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlockingSettingsTable> {
  $$BlockingSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get protectionEnabled => $composableBuilder(
    column: $table.protectionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strictnessLevel => $composableBuilder(
    column: $table.strictnessLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get searchFilteringEnabled => $composableBuilder(
    column: $table.searchFilteringEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get socialMode => $composableBuilder(
    column: $table.socialMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockReels => $composableBuilder(
    column: $table.blockReels,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockShorts => $composableBuilder(
    column: $table.blockShorts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockTikTok => $composableBuilder(
    column: $table.blockTikTok,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockSnapchatStories => $composableBuilder(
    column: $table.blockSnapchatStories,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reelsLimitMinutes => $composableBuilder(
    column: $table.reelsLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shortsLimitMinutes => $composableBuilder(
    column: $table.shortsLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tiktokLimitMinutes => $composableBuilder(
    column: $table.tiktokLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snapchatLimitMinutes => $composableBuilder(
    column: $table.snapchatLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockShopping => $composableBuilder(
    column: $table.blockShopping,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockGambling => $composableBuilder(
    column: $table.blockGambling,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockImageVideoSearch => $composableBuilder(
    column: $table.blockImageVideoSearch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appTimeLimitsEnabled => $composableBuilder(
    column: $table.appTimeLimitsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get customAppsBlocklistEnabled => $composableBuilder(
    column: $table.customAppsBlocklistEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockInAppBrowsers => $composableBuilder(
    column: $table.blockInAppBrowsers,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get preventUninstall => $composableBuilder(
    column: $table.preventUninstall,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get accountabilityPartnerEnabled => $composableBuilder(
    column: $table.accountabilityPartnerEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get customBlockScreen => $composableBuilder(
    column: $table.customBlockScreen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get customWebsitesBlocklistEnabled =>
      $composableBuilder(
        column: $table.customWebsitesBlocklistEnabled,
        builder: (column) => column,
      );

  GeneratedColumn<int> get commitmentCycle => $composableBuilder(
    column: $table.commitmentCycle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get commitmentLockUntil => $composableBuilder(
    column: $table.commitmentLockUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commitmentMode => $composableBuilder(
    column: $table.commitmentMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commitmentTotalDays => $composableBuilder(
    column: $table.commitmentTotalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commitmentBreakCount => $composableBuilder(
    column: $table.commitmentBreakCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get commitmentStartedAt => $composableBuilder(
    column: $table.commitmentStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get protectionStartedAt => $composableBuilder(
    column: $table.protectionStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activePlan => $composableBuilder(
    column: $table.activePlan,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get termsAccepted => $composableBuilder(
    column: $table.termsAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customBlocklist => $composableBuilder(
    column: $table.customBlocklist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customAllowlist => $composableBuilder(
    column: $table.customAllowlist,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BlockingSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlockingSettingsTable,
          BlockingSetting,
          $$BlockingSettingsTableFilterComposer,
          $$BlockingSettingsTableOrderingComposer,
          $$BlockingSettingsTableAnnotationComposer,
          $$BlockingSettingsTableCreateCompanionBuilder,
          $$BlockingSettingsTableUpdateCompanionBuilder,
          (
            BlockingSetting,
            BaseReferences<
              _$AppDatabase,
              $BlockingSettingsTable,
              BlockingSetting
            >,
          ),
          BlockingSetting,
          PrefetchHooks Function()
        > {
  $$BlockingSettingsTableTableManager(
    _$AppDatabase db,
    $BlockingSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockingSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockingSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockingSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> protectionEnabled = const Value.absent(),
                Value<String> strictnessLevel = const Value.absent(),
                Value<bool> searchFilteringEnabled = const Value.absent(),
                Value<String> socialMode = const Value.absent(),
                Value<bool> blockReels = const Value.absent(),
                Value<bool> blockShorts = const Value.absent(),
                Value<bool> blockTikTok = const Value.absent(),
                Value<bool> blockSnapchatStories = const Value.absent(),
                Value<int> reelsLimitMinutes = const Value.absent(),
                Value<int> shortsLimitMinutes = const Value.absent(),
                Value<int> tiktokLimitMinutes = const Value.absent(),
                Value<int> snapchatLimitMinutes = const Value.absent(),
                Value<bool> blockShopping = const Value.absent(),
                Value<bool> blockGambling = const Value.absent(),
                Value<bool> blockImageVideoSearch = const Value.absent(),
                Value<bool> appTimeLimitsEnabled = const Value.absent(),
                Value<bool> customAppsBlocklistEnabled = const Value.absent(),
                Value<bool> blockInAppBrowsers = const Value.absent(),
                Value<bool> preventUninstall = const Value.absent(),
                Value<bool> accountabilityPartnerEnabled = const Value.absent(),
                Value<bool> customBlockScreen = const Value.absent(),
                Value<bool> customWebsitesBlocklistEnabled =
                    const Value.absent(),
                Value<int> commitmentCycle = const Value.absent(),
                Value<DateTime?> commitmentLockUntil = const Value.absent(),
                Value<String?> commitmentMode = const Value.absent(),
                Value<int> commitmentTotalDays = const Value.absent(),
                Value<int> commitmentBreakCount = const Value.absent(),
                Value<DateTime?> commitmentStartedAt = const Value.absent(),
                Value<DateTime?> protectionStartedAt = const Value.absent(),
                Value<String?> activePlan = const Value.absent(),
                Value<bool> termsAccepted = const Value.absent(),
                Value<String?> customBlocklist = const Value.absent(),
                Value<String?> customAllowlist = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BlockingSettingsCompanion(
                id: id,
                protectionEnabled: protectionEnabled,
                strictnessLevel: strictnessLevel,
                searchFilteringEnabled: searchFilteringEnabled,
                socialMode: socialMode,
                blockReels: blockReels,
                blockShorts: blockShorts,
                blockTikTok: blockTikTok,
                blockSnapchatStories: blockSnapchatStories,
                reelsLimitMinutes: reelsLimitMinutes,
                shortsLimitMinutes: shortsLimitMinutes,
                tiktokLimitMinutes: tiktokLimitMinutes,
                snapchatLimitMinutes: snapchatLimitMinutes,
                blockShopping: blockShopping,
                blockGambling: blockGambling,
                blockImageVideoSearch: blockImageVideoSearch,
                appTimeLimitsEnabled: appTimeLimitsEnabled,
                customAppsBlocklistEnabled: customAppsBlocklistEnabled,
                blockInAppBrowsers: blockInAppBrowsers,
                preventUninstall: preventUninstall,
                accountabilityPartnerEnabled: accountabilityPartnerEnabled,
                customBlockScreen: customBlockScreen,
                customWebsitesBlocklistEnabled: customWebsitesBlocklistEnabled,
                commitmentCycle: commitmentCycle,
                commitmentLockUntil: commitmentLockUntil,
                commitmentMode: commitmentMode,
                commitmentTotalDays: commitmentTotalDays,
                commitmentBreakCount: commitmentBreakCount,
                commitmentStartedAt: commitmentStartedAt,
                protectionStartedAt: protectionStartedAt,
                activePlan: activePlan,
                termsAccepted: termsAccepted,
                customBlocklist: customBlocklist,
                customAllowlist: customAllowlist,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> protectionEnabled = const Value.absent(),
                Value<String> strictnessLevel = const Value.absent(),
                Value<bool> searchFilteringEnabled = const Value.absent(),
                Value<String> socialMode = const Value.absent(),
                Value<bool> blockReels = const Value.absent(),
                Value<bool> blockShorts = const Value.absent(),
                Value<bool> blockTikTok = const Value.absent(),
                Value<bool> blockSnapchatStories = const Value.absent(),
                Value<int> reelsLimitMinutes = const Value.absent(),
                Value<int> shortsLimitMinutes = const Value.absent(),
                Value<int> tiktokLimitMinutes = const Value.absent(),
                Value<int> snapchatLimitMinutes = const Value.absent(),
                Value<bool> blockShopping = const Value.absent(),
                Value<bool> blockGambling = const Value.absent(),
                Value<bool> blockImageVideoSearch = const Value.absent(),
                Value<bool> appTimeLimitsEnabled = const Value.absent(),
                Value<bool> customAppsBlocklistEnabled = const Value.absent(),
                Value<bool> blockInAppBrowsers = const Value.absent(),
                Value<bool> preventUninstall = const Value.absent(),
                Value<bool> accountabilityPartnerEnabled = const Value.absent(),
                Value<bool> customBlockScreen = const Value.absent(),
                Value<bool> customWebsitesBlocklistEnabled =
                    const Value.absent(),
                Value<int> commitmentCycle = const Value.absent(),
                Value<DateTime?> commitmentLockUntil = const Value.absent(),
                Value<String?> commitmentMode = const Value.absent(),
                Value<int> commitmentTotalDays = const Value.absent(),
                Value<int> commitmentBreakCount = const Value.absent(),
                Value<DateTime?> commitmentStartedAt = const Value.absent(),
                Value<DateTime?> protectionStartedAt = const Value.absent(),
                Value<String?> activePlan = const Value.absent(),
                Value<bool> termsAccepted = const Value.absent(),
                Value<String?> customBlocklist = const Value.absent(),
                Value<String?> customAllowlist = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BlockingSettingsCompanion.insert(
                id: id,
                protectionEnabled: protectionEnabled,
                strictnessLevel: strictnessLevel,
                searchFilteringEnabled: searchFilteringEnabled,
                socialMode: socialMode,
                blockReels: blockReels,
                blockShorts: blockShorts,
                blockTikTok: blockTikTok,
                blockSnapchatStories: blockSnapchatStories,
                reelsLimitMinutes: reelsLimitMinutes,
                shortsLimitMinutes: shortsLimitMinutes,
                tiktokLimitMinutes: tiktokLimitMinutes,
                snapchatLimitMinutes: snapchatLimitMinutes,
                blockShopping: blockShopping,
                blockGambling: blockGambling,
                blockImageVideoSearch: blockImageVideoSearch,
                appTimeLimitsEnabled: appTimeLimitsEnabled,
                customAppsBlocklistEnabled: customAppsBlocklistEnabled,
                blockInAppBrowsers: blockInAppBrowsers,
                preventUninstall: preventUninstall,
                accountabilityPartnerEnabled: accountabilityPartnerEnabled,
                customBlockScreen: customBlockScreen,
                customWebsitesBlocklistEnabled: customWebsitesBlocklistEnabled,
                commitmentCycle: commitmentCycle,
                commitmentLockUntil: commitmentLockUntil,
                commitmentMode: commitmentMode,
                commitmentTotalDays: commitmentTotalDays,
                commitmentBreakCount: commitmentBreakCount,
                commitmentStartedAt: commitmentStartedAt,
                protectionStartedAt: protectionStartedAt,
                activePlan: activePlan,
                termsAccepted: termsAccepted,
                customBlocklist: customBlocklist,
                customAllowlist: customAllowlist,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlockingSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlockingSettingsTable,
      BlockingSetting,
      $$BlockingSettingsTableFilterComposer,
      $$BlockingSettingsTableOrderingComposer,
      $$BlockingSettingsTableAnnotationComposer,
      $$BlockingSettingsTableCreateCompanionBuilder,
      $$BlockingSettingsTableUpdateCompanionBuilder,
      (
        BlockingSetting,
        BaseReferences<_$AppDatabase, $BlockingSettingsTable, BlockingSetting>,
      ),
      BlockingSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserAssessmentsTableTableManager get userAssessments =>
      $$UserAssessmentsTableTableManager(_db, _db.userAssessments);
  $$BlockingSettingsTableTableManager get blockingSettings =>
      $$BlockingSettingsTableTableManager(_db, _db.blockingSettings);
}
