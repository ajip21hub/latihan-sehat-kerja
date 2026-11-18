// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SnapshotCacheTable extends SnapshotCache
    with TableInfo<$SnapshotCacheTable, SnapshotCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nomorMeta = const VerificationMeta('nomor');
  @override
  late final GeneratedColumn<String> nomor = GeneratedColumn<String>(
    'nomor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isiMeta = const VerificationMeta('isi');
  @override
  late final GeneratedColumn<String> isi = GeneratedColumn<String>(
    'isi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [nomor, isi];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshot_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('nomor')) {
      context.handle(
        _nomorMeta,
        nomor.isAcceptableOrUnknown(data['nomor']!, _nomorMeta),
      );
    } else if (isInserting) {
      context.missing(_nomorMeta);
    }
    if (data.containsKey('isi')) {
      context.handle(
        _isiMeta,
        isi.isAcceptableOrUnknown(data['isi']!, _isiMeta),
      );
    } else if (isInserting) {
      context.missing(_isiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nomor};
  @override
  SnapshotCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotCacheData(
      nomor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nomor'],
      )!,
      isi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isi'],
      )!,
    );
  }

  @override
  $SnapshotCacheTable createAlias(String alias) {
    return $SnapshotCacheTable(attachedDatabase, alias);
  }
}

class SnapshotCacheData extends DataClass
    implements Insertable<SnapshotCacheData> {
  final String nomor;
  final String isi;
  const SnapshotCacheData({required this.nomor, required this.isi});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['nomor'] = Variable<String>(nomor);
    map['isi'] = Variable<String>(isi);
    return map;
  }

  SnapshotCacheCompanion toCompanion(bool nullToAbsent) {
    return SnapshotCacheCompanion(nomor: Value(nomor), isi: Value(isi));
  }

  factory SnapshotCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotCacheData(
      nomor: serializer.fromJson<String>(json['nomor']),
      isi: serializer.fromJson<String>(json['isi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nomor': serializer.toJson<String>(nomor),
      'isi': serializer.toJson<String>(isi),
    };
  }

  SnapshotCacheData copyWith({String? nomor, String? isi}) =>
      SnapshotCacheData(nomor: nomor ?? this.nomor, isi: isi ?? this.isi);
  SnapshotCacheData copyWithCompanion(SnapshotCacheCompanion data) {
    return SnapshotCacheData(
      nomor: data.nomor.present ? data.nomor.value : this.nomor,
      isi: data.isi.present ? data.isi.value : this.isi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotCacheData(')
          ..write('nomor: $nomor, ')
          ..write('isi: $isi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nomor, isi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotCacheData &&
          other.nomor == this.nomor &&
          other.isi == this.isi);
}

class SnapshotCacheCompanion extends UpdateCompanion<SnapshotCacheData> {
  final Value<String> nomor;
  final Value<String> isi;
  final Value<int> rowid;
  const SnapshotCacheCompanion({
    this.nomor = const Value.absent(),
    this.isi = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotCacheCompanion.insert({
    required String nomor,
    required String isi,
    this.rowid = const Value.absent(),
  }) : nomor = Value(nomor),
       isi = Value(isi);
  static Insertable<SnapshotCacheData> custom({
    Expression<String>? nomor,
    Expression<String>? isi,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nomor != null) 'nomor': nomor,
      if (isi != null) 'isi': isi,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotCacheCompanion copyWith({
    Value<String>? nomor,
    Value<String>? isi,
    Value<int>? rowid,
  }) {
    return SnapshotCacheCompanion(
      nomor: nomor ?? this.nomor,
      isi: isi ?? this.isi,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nomor.present) {
      map['nomor'] = Variable<String>(nomor.value);
    }
    if (isi.present) {
      map['isi'] = Variable<String>(isi.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotCacheCompanion(')
          ..write('nomor: $nomor, ')
          ..write('isi: $isi, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRowsTable extends OutboxRows
    with TableInfo<$OutboxRowsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomorMeta = const VerificationMeta('nomor');
  @override
  late final GeneratedColumn<String> nomor = GeneratedColumn<String>(
    'nomor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sidikMeta = const VerificationMeta('sidik');
  @override
  late final GeneratedColumn<String> sidik = GeneratedColumn<String>(
    'sidik',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _batalMeta = const VerificationMeta('batal');
  @override
  late final GeneratedColumn<bool> batal = GeneratedColumn<bool>(
    'batal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("batal" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dibuatMeta = const VerificationMeta('dibuat');
  @override
  late final GeneratedColumn<int> dibuat = GeneratedColumn<int>(
    'dibuat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    nomor,
    payload,
    sidik,
    synced,
    batal,
    dibuat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('nomor')) {
      context.handle(
        _nomorMeta,
        nomor.isAcceptableOrUnknown(data['nomor']!, _nomorMeta),
      );
    } else if (isInserting) {
      context.missing(_nomorMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('sidik')) {
      context.handle(
        _sidikMeta,
        sidik.isAcceptableOrUnknown(data['sidik']!, _sidikMeta),
      );
    } else if (isInserting) {
      context.missing(_sidikMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('batal')) {
      context.handle(
        _batalMeta,
        batal.isAcceptableOrUnknown(data['batal']!, _batalMeta),
      );
    }
    if (data.containsKey('dibuat')) {
      context.handle(
        _dibuatMeta,
        dibuat.isAcceptableOrUnknown(data['dibuat']!, _dibuatMeta),
      );
    } else if (isInserting) {
      context.missing(_dibuatMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      nomor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nomor'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      sidik: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sidik'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      batal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}batal'],
      )!,
      dibuat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dibuat'],
      )!,
    );
  }

  @override
  $OutboxRowsTable createAlias(String alias) {
    return $OutboxRowsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String clientId;
  final String nomor;
  final String payload;
  final String sidik;
  final bool synced;
  final bool batal;
  final int dibuat;
  const OutboxRow({
    required this.clientId,
    required this.nomor,
    required this.payload,
    required this.sidik,
    required this.synced,
    required this.batal,
    required this.dibuat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['nomor'] = Variable<String>(nomor);
    map['payload'] = Variable<String>(payload);
    map['sidik'] = Variable<String>(sidik);
    map['synced'] = Variable<bool>(synced);
    map['batal'] = Variable<bool>(batal);
    map['dibuat'] = Variable<int>(dibuat);
    return map;
  }

  OutboxRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxRowsCompanion(
      clientId: Value(clientId),
      nomor: Value(nomor),
      payload: Value(payload),
      sidik: Value(sidik),
      synced: Value(synced),
      batal: Value(batal),
      dibuat: Value(dibuat),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      clientId: serializer.fromJson<String>(json['clientId']),
      nomor: serializer.fromJson<String>(json['nomor']),
      payload: serializer.fromJson<String>(json['payload']),
      sidik: serializer.fromJson<String>(json['sidik']),
      synced: serializer.fromJson<bool>(json['synced']),
      batal: serializer.fromJson<bool>(json['batal']),
      dibuat: serializer.fromJson<int>(json['dibuat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'nomor': serializer.toJson<String>(nomor),
      'payload': serializer.toJson<String>(payload),
      'sidik': serializer.toJson<String>(sidik),
      'synced': serializer.toJson<bool>(synced),
      'batal': serializer.toJson<bool>(batal),
      'dibuat': serializer.toJson<int>(dibuat),
    };
  }

  OutboxRow copyWith({
    String? clientId,
    String? nomor,
    String? payload,
    String? sidik,
    bool? synced,
    bool? batal,
    int? dibuat,
  }) => OutboxRow(
    clientId: clientId ?? this.clientId,
    nomor: nomor ?? this.nomor,
    payload: payload ?? this.payload,
    sidik: sidik ?? this.sidik,
    synced: synced ?? this.synced,
    batal: batal ?? this.batal,
    dibuat: dibuat ?? this.dibuat,
  );
  OutboxRow copyWithCompanion(OutboxRowsCompanion data) {
    return OutboxRow(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      nomor: data.nomor.present ? data.nomor.value : this.nomor,
      payload: data.payload.present ? data.payload.value : this.payload,
      sidik: data.sidik.present ? data.sidik.value : this.sidik,
      synced: data.synced.present ? data.synced.value : this.synced,
      batal: data.batal.present ? data.batal.value : this.batal,
      dibuat: data.dibuat.present ? data.dibuat.value : this.dibuat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('clientId: $clientId, ')
          ..write('nomor: $nomor, ')
          ..write('payload: $payload, ')
          ..write('sidik: $sidik, ')
          ..write('synced: $synced, ')
          ..write('batal: $batal, ')
          ..write('dibuat: $dibuat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(clientId, nomor, payload, sidik, synced, batal, dibuat);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.clientId == this.clientId &&
          other.nomor == this.nomor &&
          other.payload == this.payload &&
          other.sidik == this.sidik &&
          other.synced == this.synced &&
          other.batal == this.batal &&
          other.dibuat == this.dibuat);
}

class OutboxRowsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> clientId;
  final Value<String> nomor;
  final Value<String> payload;
  final Value<String> sidik;
  final Value<bool> synced;
  final Value<bool> batal;
  final Value<int> dibuat;
  final Value<int> rowid;
  const OutboxRowsCompanion({
    this.clientId = const Value.absent(),
    this.nomor = const Value.absent(),
    this.payload = const Value.absent(),
    this.sidik = const Value.absent(),
    this.synced = const Value.absent(),
    this.batal = const Value.absent(),
    this.dibuat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxRowsCompanion.insert({
    required String clientId,
    required String nomor,
    required String payload,
    required String sidik,
    this.synced = const Value.absent(),
    this.batal = const Value.absent(),
    required int dibuat,
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       nomor = Value(nomor),
       payload = Value(payload),
       sidik = Value(sidik),
       dibuat = Value(dibuat);
  static Insertable<OutboxRow> custom({
    Expression<String>? clientId,
    Expression<String>? nomor,
    Expression<String>? payload,
    Expression<String>? sidik,
    Expression<bool>? synced,
    Expression<bool>? batal,
    Expression<int>? dibuat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (nomor != null) 'nomor': nomor,
      if (payload != null) 'payload': payload,
      if (sidik != null) 'sidik': sidik,
      if (synced != null) 'synced': synced,
      if (batal != null) 'batal': batal,
      if (dibuat != null) 'dibuat': dibuat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxRowsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? nomor,
    Value<String>? payload,
    Value<String>? sidik,
    Value<bool>? synced,
    Value<bool>? batal,
    Value<int>? dibuat,
    Value<int>? rowid,
  }) {
    return OutboxRowsCompanion(
      clientId: clientId ?? this.clientId,
      nomor: nomor ?? this.nomor,
      payload: payload ?? this.payload,
      sidik: sidik ?? this.sidik,
      synced: synced ?? this.synced,
      batal: batal ?? this.batal,
      dibuat: dibuat ?? this.dibuat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (nomor.present) {
      map['nomor'] = Variable<String>(nomor.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (sidik.present) {
      map['sidik'] = Variable<String>(sidik.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (batal.present) {
      map['batal'] = Variable<bool>(batal.value);
    }
    if (dibuat.present) {
      map['dibuat'] = Variable<int>(dibuat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRowsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('nomor: $nomor, ')
          ..write('payload: $payload, ')
          ..write('sidik: $sidik, ')
          ..write('synced: $synced, ')
          ..write('batal: $batal, ')
          ..write('dibuat: $dibuat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SnapshotCacheTable snapshotCache = $SnapshotCacheTable(this);
  late final $OutboxRowsTable outboxRows = $OutboxRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    snapshotCache,
    outboxRows,
  ];
}

typedef $$SnapshotCacheTableCreateCompanionBuilder =
    SnapshotCacheCompanion Function({
      required String nomor,
      required String isi,
      Value<int> rowid,
    });
typedef $$SnapshotCacheTableUpdateCompanionBuilder =
    SnapshotCacheCompanion Function({
      Value<String> nomor,
      Value<String> isi,
      Value<int> rowid,
    });

class $$SnapshotCacheTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotCacheTable> {
  $$SnapshotCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nomor => $composableBuilder(
    column: $table.nomor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isi => $composableBuilder(
    column: $table.isi,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotCacheTable> {
  $$SnapshotCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nomor => $composableBuilder(
    column: $table.nomor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isi => $composableBuilder(
    column: $table.isi,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotCacheTable> {
  $$SnapshotCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nomor =>
      $composableBuilder(column: $table.nomor, builder: (column) => column);

  GeneratedColumn<String> get isi =>
      $composableBuilder(column: $table.isi, builder: (column) => column);
}

class $$SnapshotCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotCacheTable,
          SnapshotCacheData,
          $$SnapshotCacheTableFilterComposer,
          $$SnapshotCacheTableOrderingComposer,
          $$SnapshotCacheTableAnnotationComposer,
          $$SnapshotCacheTableCreateCompanionBuilder,
          $$SnapshotCacheTableUpdateCompanionBuilder,
          (
            SnapshotCacheData,
            BaseReferences<
              _$AppDatabase,
              $SnapshotCacheTable,
              SnapshotCacheData
            >,
          ),
          SnapshotCacheData,
          PrefetchHooks Function()
        > {
  $$SnapshotCacheTableTableManager(_$AppDatabase db, $SnapshotCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> nomor = const Value.absent(),
            Value<String> isi = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SnapshotCacheCompanion(nomor: nomor, isi: isi, rowid: rowid),
          createCompanionCallback:
              ({
                required String nomor,
                required String isi,
                Value<int> rowid = const Value.absent(),
              }) => SnapshotCacheCompanion.insert(
                nomor: nomor,
                isi: isi,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotCacheTable, SnapshotCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SnapshotCacheTable,
                    SnapshotCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotCacheTable,
      SnapshotCacheData,
      $$SnapshotCacheTableFilterComposer,
      $$SnapshotCacheTableOrderingComposer,
      $$SnapshotCacheTableAnnotationComposer,
      $$SnapshotCacheTableCreateCompanionBuilder,
      $$SnapshotCacheTableUpdateCompanionBuilder,
      (
        SnapshotCacheData,
        BaseReferences<_$AppDatabase, $SnapshotCacheTable, SnapshotCacheData>,
      ),
      SnapshotCacheData,
      PrefetchHooks Function()
    >;
typedef $$OutboxRowsTableCreateCompanionBuilder = OutboxRowsCompanion Function({
  required String clientId,
  required String nomor,
  required String payload,
  required String sidik,
  Value<bool> synced,
  Value<bool> batal,
  required int dibuat,
  Value<int> rowid,
});
typedef $$OutboxRowsTableUpdateCompanionBuilder = OutboxRowsCompanion Function({
  Value<String> clientId,
  Value<String> nomor,
  Value<String> payload,
  Value<String> sidik,
  Value<bool> synced,
  Value<bool> batal,
  Value<int> dibuat,
  Value<int> rowid,
});

class $$OutboxRowsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomor => $composableBuilder(
    column: $table.nomor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sidik => $composableBuilder(
    column: $table.sidik,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get batal => $composableBuilder(
    column: $table.batal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dibuat => $composableBuilder(
    column: $table.dibuat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomor => $composableBuilder(
    column: $table.nomor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sidik => $composableBuilder(
    column: $table.sidik,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get batal => $composableBuilder(
    column: $table.batal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dibuat => $composableBuilder(
    column: $table.dibuat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get nomor =>
      $composableBuilder(column: $table.nomor, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get sidik =>
      $composableBuilder(column: $table.sidik, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<bool> get batal =>
      $composableBuilder(column: $table.batal, builder: (column) => column);

  GeneratedColumn<int> get dibuat =>
      $composableBuilder(column: $table.dibuat, builder: (column) => column);
}

class $$OutboxRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxRowsTable,
          OutboxRow,
          $$OutboxRowsTableFilterComposer,
          $$OutboxRowsTableOrderingComposer,
          $$OutboxRowsTableAnnotationComposer,
          $$OutboxRowsTableCreateCompanionBuilder,
          $$OutboxRowsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxRowsTableTableManager(_$AppDatabase db, $OutboxRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> nomor = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> sidik = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> batal = const Value.absent(),
                Value<int> dibuat = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxRowsCompanion(
                clientId: clientId,
                nomor: nomor,
                payload: payload,
                sidik: sidik,
                synced: synced,
                batal: batal,
                dibuat: dibuat,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String nomor,
                required String payload,
                required String sidik,
                Value<bool> synced = const Value.absent(),
                Value<bool> batal = const Value.absent(),
                required int dibuat,
                Value<int> rowid = const Value.absent(),
              }) => OutboxRowsCompanion.insert(
                clientId: clientId,
                nomor: nomor,
                payload: payload,
                sidik: sidik,
                synced: synced,
                batal: batal,
                dibuat: dibuat,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxRowsTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxRowsTable,
      OutboxRow,
      $$OutboxRowsTableFilterComposer,
      $$OutboxRowsTableOrderingComposer,
      $$OutboxRowsTableAnnotationComposer,
      $$OutboxRowsTableCreateCompanionBuilder,
      $$OutboxRowsTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SnapshotCacheTableTableManager get snapshotCache =>
      $$SnapshotCacheTableTableManager(_db, _db.snapshotCache);
  $$OutboxRowsTableTableManager get outboxRows =>
      $$OutboxRowsTableTableManager(_db, _db.outboxRows);
}
