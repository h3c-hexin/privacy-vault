// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VaultFoldersTable extends VaultFolders
    with TableInfo<$VaultFoldersTable, VaultFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    iconName,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultFoldersTable createAlias(String alias) {
    return $VaultFoldersTable(attachedDatabase, alias);
  }
}

class VaultFolder extends DataClass implements Insertable<VaultFolder> {
  final String id;
  final String name;
  final String? colorHex;
  final String? iconName;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const VaultFolder({
    required this.id,
    required this.name,
    this.colorHex,
    this.iconName,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultFoldersCompanion toCompanion(bool nullToAbsent) {
    return VaultFoldersCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultFolder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'iconName': serializer.toJson<String?>(iconName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultFolder copyWith({
    String? id,
    String? name,
    Value<String?> colorHex = const Value.absent(),
    Value<String?> iconName = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => VaultFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    iconName: iconName.present ? iconName.value : this.iconName,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultFolder copyWithCompanion(VaultFoldersCompanion data) {
    return VaultFolder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultFolder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorHex,
    iconName,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultFolder &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.iconName == this.iconName &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VaultFoldersCompanion extends UpdateCompanion<VaultFolder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<String?> iconName;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFoldersCompanion.insert({
    required String id,
    required String name,
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VaultFolder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? iconName,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconName != null) 'icon_name': iconName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultFoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? colorHex,
    Value<String?>? iconName,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultFilesTable extends VaultFiles
    with TableInfo<$VaultFilesTable, VaultFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vault_folders (id)',
    ),
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPathMeta = const VerificationMeta(
    'encryptedPath',
  );
  @override
  late final GeneratedColumn<String> encryptedPath = GeneratedColumn<String>(
    'encrypted_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedSizeMeta = const VerificationMeta(
    'encryptedSize',
  );
  @override
  late final GeneratedColumn<int> encryptedSize = GeneratedColumn<int>(
    'encrypted_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encryptedDekMeta = const VerificationMeta(
    'encryptedDek',
  );
  @override
  late final GeneratedColumn<String> encryptedDek = GeneratedColumn<String>(
    'encrypted_dek',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dekIvMeta = const VerificationMeta('dekIv');
  @override
  late final GeneratedColumn<String> dekIv = GeneratedColumn<String>(
    'dek_iv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIvMeta = const VerificationMeta('fileIv');
  @override
  late final GeneratedColumn<String> fileIv = GeneratedColumn<String>(
    'file_iv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkCountMeta = const VerificationMeta(
    'chunkCount',
  );
  @override
  late final GeneratedColumn<int> chunkCount = GeneratedColumn<int>(
    'chunk_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalFolderIdMeta = const VerificationMeta(
    'originalFolderId',
  );
  @override
  late final GeneratedColumn<String> originalFolderId = GeneratedColumn<String>(
    'original_folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    originalName,
    fileType,
    mimeType,
    encryptedPath,
    thumbnailPath,
    fileSize,
    encryptedSize,
    width,
    height,
    durationMs,
    encryptedDek,
    dekIv,
    fileIv,
    chunkCount,
    checksum,
    isDeleted,
    deletedAt,
    originalFolderId,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('encrypted_path')) {
      context.handle(
        _encryptedPathMeta,
        encryptedPath.isAcceptableOrUnknown(
          data['encrypted_path']!,
          _encryptedPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('encrypted_size')) {
      context.handle(
        _encryptedSizeMeta,
        encryptedSize.isAcceptableOrUnknown(
          data['encrypted_size']!,
          _encryptedSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedSizeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('encrypted_dek')) {
      context.handle(
        _encryptedDekMeta,
        encryptedDek.isAcceptableOrUnknown(
          data['encrypted_dek']!,
          _encryptedDekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedDekMeta);
    }
    if (data.containsKey('dek_iv')) {
      context.handle(
        _dekIvMeta,
        dekIv.isAcceptableOrUnknown(data['dek_iv']!, _dekIvMeta),
      );
    } else if (isInserting) {
      context.missing(_dekIvMeta);
    }
    if (data.containsKey('file_iv')) {
      context.handle(
        _fileIvMeta,
        fileIv.isAcceptableOrUnknown(data['file_iv']!, _fileIvMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIvMeta);
    }
    if (data.containsKey('chunk_count')) {
      context.handle(
        _chunkCountMeta,
        chunkCount.isAcceptableOrUnknown(data['chunk_count']!, _chunkCountMeta),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('original_folder_id')) {
      context.handle(
        _originalFolderIdMeta,
        originalFolderId.isAcceptableOrUnknown(
          data['original_folder_id']!,
          _originalFolderIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      encryptedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      encryptedSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}encrypted_size'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      encryptedDek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_dek'],
      )!,
      dekIv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dek_iv'],
      )!,
      fileIv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_iv'],
      )!,
      chunkCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_count'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      originalFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_folder_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VaultFilesTable createAlias(String alias) {
    return $VaultFilesTable(attachedDatabase, alias);
  }
}

class VaultFile extends DataClass implements Insertable<VaultFile> {
  final String id;
  final String folderId;
  final String originalName;
  final String fileType;
  final String mimeType;
  final String encryptedPath;
  final String? thumbnailPath;
  final int fileSize;
  final int encryptedSize;
  final int? width;
  final int? height;
  final int? durationMs;
  final String encryptedDek;
  final String dekIv;
  final String fileIv;
  final int chunkCount;
  final String checksum;
  final bool isDeleted;
  final int? deletedAt;
  final String? originalFolderId;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const VaultFile({
    required this.id,
    required this.folderId,
    required this.originalName,
    required this.fileType,
    required this.mimeType,
    required this.encryptedPath,
    this.thumbnailPath,
    required this.fileSize,
    required this.encryptedSize,
    this.width,
    this.height,
    this.durationMs,
    required this.encryptedDek,
    required this.dekIv,
    required this.fileIv,
    required this.chunkCount,
    required this.checksum,
    required this.isDeleted,
    this.deletedAt,
    this.originalFolderId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['folder_id'] = Variable<String>(folderId);
    map['original_name'] = Variable<String>(originalName);
    map['file_type'] = Variable<String>(fileType);
    map['mime_type'] = Variable<String>(mimeType);
    map['encrypted_path'] = Variable<String>(encryptedPath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['encrypted_size'] = Variable<int>(encryptedSize);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['encrypted_dek'] = Variable<String>(encryptedDek);
    map['dek_iv'] = Variable<String>(dekIv);
    map['file_iv'] = Variable<String>(fileIv);
    map['chunk_count'] = Variable<int>(chunkCount);
    map['checksum'] = Variable<String>(checksum);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || originalFolderId != null) {
      map['original_folder_id'] = Variable<String>(originalFolderId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  VaultFilesCompanion toCompanion(bool nullToAbsent) {
    return VaultFilesCompanion(
      id: Value(id),
      folderId: Value(folderId),
      originalName: Value(originalName),
      fileType: Value(fileType),
      mimeType: Value(mimeType),
      encryptedPath: Value(encryptedPath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      fileSize: Value(fileSize),
      encryptedSize: Value(encryptedSize),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      encryptedDek: Value(encryptedDek),
      dekIv: Value(dekIv),
      fileIv: Value(fileIv),
      chunkCount: Value(chunkCount),
      checksum: Value(checksum),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originalFolderId: originalFolderId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalFolderId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VaultFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultFile(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String>(json['folderId']),
      originalName: serializer.fromJson<String>(json['originalName']),
      fileType: serializer.fromJson<String>(json['fileType']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      encryptedPath: serializer.fromJson<String>(json['encryptedPath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      encryptedSize: serializer.fromJson<int>(json['encryptedSize']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      encryptedDek: serializer.fromJson<String>(json['encryptedDek']),
      dekIv: serializer.fromJson<String>(json['dekIv']),
      fileIv: serializer.fromJson<String>(json['fileIv']),
      chunkCount: serializer.fromJson<int>(json['chunkCount']),
      checksum: serializer.fromJson<String>(json['checksum']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      originalFolderId: serializer.fromJson<String?>(json['originalFolderId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String>(folderId),
      'originalName': serializer.toJson<String>(originalName),
      'fileType': serializer.toJson<String>(fileType),
      'mimeType': serializer.toJson<String>(mimeType),
      'encryptedPath': serializer.toJson<String>(encryptedPath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'encryptedSize': serializer.toJson<int>(encryptedSize),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMs': serializer.toJson<int?>(durationMs),
      'encryptedDek': serializer.toJson<String>(encryptedDek),
      'dekIv': serializer.toJson<String>(dekIv),
      'fileIv': serializer.toJson<String>(fileIv),
      'chunkCount': serializer.toJson<int>(chunkCount),
      'checksum': serializer.toJson<String>(checksum),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'originalFolderId': serializer.toJson<String?>(originalFolderId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  VaultFile copyWith({
    String? id,
    String? folderId,
    String? originalName,
    String? fileType,
    String? mimeType,
    String? encryptedPath,
    Value<String?> thumbnailPath = const Value.absent(),
    int? fileSize,
    int? encryptedSize,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    String? encryptedDek,
    String? dekIv,
    String? fileIv,
    int? chunkCount,
    String? checksum,
    bool? isDeleted,
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> originalFolderId = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => VaultFile(
    id: id ?? this.id,
    folderId: folderId ?? this.folderId,
    originalName: originalName ?? this.originalName,
    fileType: fileType ?? this.fileType,
    mimeType: mimeType ?? this.mimeType,
    encryptedPath: encryptedPath ?? this.encryptedPath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    fileSize: fileSize ?? this.fileSize,
    encryptedSize: encryptedSize ?? this.encryptedSize,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    encryptedDek: encryptedDek ?? this.encryptedDek,
    dekIv: dekIv ?? this.dekIv,
    fileIv: fileIv ?? this.fileIv,
    chunkCount: chunkCount ?? this.chunkCount,
    checksum: checksum ?? this.checksum,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    originalFolderId: originalFolderId.present
        ? originalFolderId.value
        : this.originalFolderId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VaultFile copyWithCompanion(VaultFilesCompanion data) {
    return VaultFile(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      encryptedPath: data.encryptedPath.present
          ? data.encryptedPath.value
          : this.encryptedPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      encryptedSize: data.encryptedSize.present
          ? data.encryptedSize.value
          : this.encryptedSize,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      encryptedDek: data.encryptedDek.present
          ? data.encryptedDek.value
          : this.encryptedDek,
      dekIv: data.dekIv.present ? data.dekIv.value : this.dekIv,
      fileIv: data.fileIv.present ? data.fileIv.value : this.fileIv,
      chunkCount: data.chunkCount.present
          ? data.chunkCount.value
          : this.chunkCount,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originalFolderId: data.originalFolderId.present
          ? data.originalFolderId.value
          : this.originalFolderId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultFile(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('originalName: $originalName, ')
          ..write('fileType: $fileType, ')
          ..write('mimeType: $mimeType, ')
          ..write('encryptedPath: $encryptedPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('encryptedSize: $encryptedSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('encryptedDek: $encryptedDek, ')
          ..write('dekIv: $dekIv, ')
          ..write('fileIv: $fileIv, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('checksum: $checksum, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originalFolderId: $originalFolderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    folderId,
    originalName,
    fileType,
    mimeType,
    encryptedPath,
    thumbnailPath,
    fileSize,
    encryptedSize,
    width,
    height,
    durationMs,
    encryptedDek,
    dekIv,
    fileIv,
    chunkCount,
    checksum,
    isDeleted,
    deletedAt,
    originalFolderId,
    sortOrder,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultFile &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.originalName == this.originalName &&
          other.fileType == this.fileType &&
          other.mimeType == this.mimeType &&
          other.encryptedPath == this.encryptedPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.fileSize == this.fileSize &&
          other.encryptedSize == this.encryptedSize &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMs == this.durationMs &&
          other.encryptedDek == this.encryptedDek &&
          other.dekIv == this.dekIv &&
          other.fileIv == this.fileIv &&
          other.chunkCount == this.chunkCount &&
          other.checksum == this.checksum &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.originalFolderId == this.originalFolderId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VaultFilesCompanion extends UpdateCompanion<VaultFile> {
  final Value<String> id;
  final Value<String> folderId;
  final Value<String> originalName;
  final Value<String> fileType;
  final Value<String> mimeType;
  final Value<String> encryptedPath;
  final Value<String?> thumbnailPath;
  final Value<int> fileSize;
  final Value<int> encryptedSize;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMs;
  final Value<String> encryptedDek;
  final Value<String> dekIv;
  final Value<String> fileIv;
  final Value<int> chunkCount;
  final Value<String> checksum;
  final Value<bool> isDeleted;
  final Value<int?> deletedAt;
  final Value<String?> originalFolderId;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const VaultFilesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.originalName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.encryptedPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.encryptedSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.encryptedDek = const Value.absent(),
    this.dekIv = const Value.absent(),
    this.fileIv = const Value.absent(),
    this.chunkCount = const Value.absent(),
    this.checksum = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originalFolderId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFilesCompanion.insert({
    required String id,
    required String folderId,
    required String originalName,
    required String fileType,
    required String mimeType,
    required String encryptedPath,
    this.thumbnailPath = const Value.absent(),
    required int fileSize,
    required int encryptedSize,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMs = const Value.absent(),
    required String encryptedDek,
    required String dekIv,
    required String fileIv,
    this.chunkCount = const Value.absent(),
    required String checksum,
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originalFolderId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       folderId = Value(folderId),
       originalName = Value(originalName),
       fileType = Value(fileType),
       mimeType = Value(mimeType),
       encryptedPath = Value(encryptedPath),
       fileSize = Value(fileSize),
       encryptedSize = Value(encryptedSize),
       encryptedDek = Value(encryptedDek),
       dekIv = Value(dekIv),
       fileIv = Value(fileIv),
       checksum = Value(checksum),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VaultFile> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? originalName,
    Expression<String>? fileType,
    Expression<String>? mimeType,
    Expression<String>? encryptedPath,
    Expression<String>? thumbnailPath,
    Expression<int>? fileSize,
    Expression<int>? encryptedSize,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMs,
    Expression<String>? encryptedDek,
    Expression<String>? dekIv,
    Expression<String>? fileIv,
    Expression<int>? chunkCount,
    Expression<String>? checksum,
    Expression<bool>? isDeleted,
    Expression<int>? deletedAt,
    Expression<String>? originalFolderId,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (originalName != null) 'original_name': originalName,
      if (fileType != null) 'file_type': fileType,
      if (mimeType != null) 'mime_type': mimeType,
      if (encryptedPath != null) 'encrypted_path': encryptedPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (fileSize != null) 'file_size': fileSize,
      if (encryptedSize != null) 'encrypted_size': encryptedSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMs != null) 'duration_ms': durationMs,
      if (encryptedDek != null) 'encrypted_dek': encryptedDek,
      if (dekIv != null) 'dek_iv': dekIv,
      if (fileIv != null) 'file_iv': fileIv,
      if (chunkCount != null) 'chunk_count': chunkCount,
      if (checksum != null) 'checksum': checksum,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originalFolderId != null) 'original_folder_id': originalFolderId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? folderId,
    Value<String>? originalName,
    Value<String>? fileType,
    Value<String>? mimeType,
    Value<String>? encryptedPath,
    Value<String?>? thumbnailPath,
    Value<int>? fileSize,
    Value<int>? encryptedSize,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? durationMs,
    Value<String>? encryptedDek,
    Value<String>? dekIv,
    Value<String>? fileIv,
    Value<int>? chunkCount,
    Value<String>? checksum,
    Value<bool>? isDeleted,
    Value<int?>? deletedAt,
    Value<String?>? originalFolderId,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return VaultFilesCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      originalName: originalName ?? this.originalName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSize: fileSize ?? this.fileSize,
      encryptedSize: encryptedSize ?? this.encryptedSize,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMs: durationMs ?? this.durationMs,
      encryptedDek: encryptedDek ?? this.encryptedDek,
      dekIv: dekIv ?? this.dekIv,
      fileIv: fileIv ?? this.fileIv,
      chunkCount: chunkCount ?? this.chunkCount,
      checksum: checksum ?? this.checksum,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      originalFolderId: originalFolderId ?? this.originalFolderId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (encryptedPath.present) {
      map['encrypted_path'] = Variable<String>(encryptedPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (encryptedSize.present) {
      map['encrypted_size'] = Variable<int>(encryptedSize.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (encryptedDek.present) {
      map['encrypted_dek'] = Variable<String>(encryptedDek.value);
    }
    if (dekIv.present) {
      map['dek_iv'] = Variable<String>(dekIv.value);
    }
    if (fileIv.present) {
      map['file_iv'] = Variable<String>(fileIv.value);
    }
    if (chunkCount.present) {
      map['chunk_count'] = Variable<int>(chunkCount.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (originalFolderId.present) {
      map['original_folder_id'] = Variable<String>(originalFolderId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultFilesCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('originalName: $originalName, ')
          ..write('fileType: $fileType, ')
          ..write('mimeType: $mimeType, ')
          ..write('encryptedPath: $encryptedPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('encryptedSize: $encryptedSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMs: $durationMs, ')
          ..write('encryptedDek: $encryptedDek, ')
          ..write('dekIv: $dekIv, ')
          ..write('fileIv: $fileIv, ')
          ..write('chunkCount: $chunkCount, ')
          ..write('checksum: $checksum, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originalFolderId: $originalFolderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntrusionRecordsTable extends IntrusionRecords
    with TableInfo<$IntrusionRecordsTable, IntrusionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntrusionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedDekMeta = const VerificationMeta(
    'encryptedDek',
  );
  @override
  late final GeneratedColumn<String> encryptedDek = GeneratedColumn<String>(
    'encrypted_dek',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dekIvMeta = const VerificationMeta('dekIv');
  @override
  late final GeneratedColumn<String> dekIv = GeneratedColumn<String>(
    'dek_iv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoIvMeta = const VerificationMeta(
    'photoIv',
  );
  @override
  late final GeneratedColumn<String> photoIv = GeneratedColumn<String>(
    'photo_iv',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    photoPath,
    encryptedDek,
    dekIv,
    photoIv,
    timestamp,
    attemptCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intrusion_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntrusionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('encrypted_dek')) {
      context.handle(
        _encryptedDekMeta,
        encryptedDek.isAcceptableOrUnknown(
          data['encrypted_dek']!,
          _encryptedDekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedDekMeta);
    }
    if (data.containsKey('dek_iv')) {
      context.handle(
        _dekIvMeta,
        dekIv.isAcceptableOrUnknown(data['dek_iv']!, _dekIvMeta),
      );
    } else if (isInserting) {
      context.missing(_dekIvMeta);
    }
    if (data.containsKey('photo_iv')) {
      context.handle(
        _photoIvMeta,
        photoIv.isAcceptableOrUnknown(data['photo_iv']!, _photoIvMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIvMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntrusionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntrusionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      )!,
      encryptedDek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_dek'],
      )!,
      dekIv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dek_iv'],
      )!,
      photoIv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_iv'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
    );
  }

  @override
  $IntrusionRecordsTable createAlias(String alias) {
    return $IntrusionRecordsTable(attachedDatabase, alias);
  }
}

class IntrusionRecord extends DataClass implements Insertable<IntrusionRecord> {
  final String id;
  final String photoPath;
  final String encryptedDek;
  final String dekIv;
  final String photoIv;
  final int timestamp;
  final int attemptCount;
  const IntrusionRecord({
    required this.id,
    required this.photoPath,
    required this.encryptedDek,
    required this.dekIv,
    required this.photoIv,
    required this.timestamp,
    required this.attemptCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['photo_path'] = Variable<String>(photoPath);
    map['encrypted_dek'] = Variable<String>(encryptedDek);
    map['dek_iv'] = Variable<String>(dekIv);
    map['photo_iv'] = Variable<String>(photoIv);
    map['timestamp'] = Variable<int>(timestamp);
    map['attempt_count'] = Variable<int>(attemptCount);
    return map;
  }

  IntrusionRecordsCompanion toCompanion(bool nullToAbsent) {
    return IntrusionRecordsCompanion(
      id: Value(id),
      photoPath: Value(photoPath),
      encryptedDek: Value(encryptedDek),
      dekIv: Value(dekIv),
      photoIv: Value(photoIv),
      timestamp: Value(timestamp),
      attemptCount: Value(attemptCount),
    );
  }

  factory IntrusionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntrusionRecord(
      id: serializer.fromJson<String>(json['id']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      encryptedDek: serializer.fromJson<String>(json['encryptedDek']),
      dekIv: serializer.fromJson<String>(json['dekIv']),
      photoIv: serializer.fromJson<String>(json['photoIv']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'photoPath': serializer.toJson<String>(photoPath),
      'encryptedDek': serializer.toJson<String>(encryptedDek),
      'dekIv': serializer.toJson<String>(dekIv),
      'photoIv': serializer.toJson<String>(photoIv),
      'timestamp': serializer.toJson<int>(timestamp),
      'attemptCount': serializer.toJson<int>(attemptCount),
    };
  }

  IntrusionRecord copyWith({
    String? id,
    String? photoPath,
    String? encryptedDek,
    String? dekIv,
    String? photoIv,
    int? timestamp,
    int? attemptCount,
  }) => IntrusionRecord(
    id: id ?? this.id,
    photoPath: photoPath ?? this.photoPath,
    encryptedDek: encryptedDek ?? this.encryptedDek,
    dekIv: dekIv ?? this.dekIv,
    photoIv: photoIv ?? this.photoIv,
    timestamp: timestamp ?? this.timestamp,
    attemptCount: attemptCount ?? this.attemptCount,
  );
  IntrusionRecord copyWithCompanion(IntrusionRecordsCompanion data) {
    return IntrusionRecord(
      id: data.id.present ? data.id.value : this.id,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      encryptedDek: data.encryptedDek.present
          ? data.encryptedDek.value
          : this.encryptedDek,
      dekIv: data.dekIv.present ? data.dekIv.value : this.dekIv,
      photoIv: data.photoIv.present ? data.photoIv.value : this.photoIv,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntrusionRecord(')
          ..write('id: $id, ')
          ..write('photoPath: $photoPath, ')
          ..write('encryptedDek: $encryptedDek, ')
          ..write('dekIv: $dekIv, ')
          ..write('photoIv: $photoIv, ')
          ..write('timestamp: $timestamp, ')
          ..write('attemptCount: $attemptCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    photoPath,
    encryptedDek,
    dekIv,
    photoIv,
    timestamp,
    attemptCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntrusionRecord &&
          other.id == this.id &&
          other.photoPath == this.photoPath &&
          other.encryptedDek == this.encryptedDek &&
          other.dekIv == this.dekIv &&
          other.photoIv == this.photoIv &&
          other.timestamp == this.timestamp &&
          other.attemptCount == this.attemptCount);
}

class IntrusionRecordsCompanion extends UpdateCompanion<IntrusionRecord> {
  final Value<String> id;
  final Value<String> photoPath;
  final Value<String> encryptedDek;
  final Value<String> dekIv;
  final Value<String> photoIv;
  final Value<int> timestamp;
  final Value<int> attemptCount;
  final Value<int> rowid;
  const IntrusionRecordsCompanion({
    this.id = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.encryptedDek = const Value.absent(),
    this.dekIv = const Value.absent(),
    this.photoIv = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntrusionRecordsCompanion.insert({
    required String id,
    required String photoPath,
    required String encryptedDek,
    required String dekIv,
    required String photoIv,
    required int timestamp,
    required int attemptCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       photoPath = Value(photoPath),
       encryptedDek = Value(encryptedDek),
       dekIv = Value(dekIv),
       photoIv = Value(photoIv),
       timestamp = Value(timestamp),
       attemptCount = Value(attemptCount);
  static Insertable<IntrusionRecord> custom({
    Expression<String>? id,
    Expression<String>? photoPath,
    Expression<String>? encryptedDek,
    Expression<String>? dekIv,
    Expression<String>? photoIv,
    Expression<int>? timestamp,
    Expression<int>? attemptCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoPath != null) 'photo_path': photoPath,
      if (encryptedDek != null) 'encrypted_dek': encryptedDek,
      if (dekIv != null) 'dek_iv': dekIv,
      if (photoIv != null) 'photo_iv': photoIv,
      if (timestamp != null) 'timestamp': timestamp,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntrusionRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? photoPath,
    Value<String>? encryptedDek,
    Value<String>? dekIv,
    Value<String>? photoIv,
    Value<int>? timestamp,
    Value<int>? attemptCount,
    Value<int>? rowid,
  }) {
    return IntrusionRecordsCompanion(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      encryptedDek: encryptedDek ?? this.encryptedDek,
      dekIv: dekIv ?? this.dekIv,
      photoIv: photoIv ?? this.photoIv,
      timestamp: timestamp ?? this.timestamp,
      attemptCount: attemptCount ?? this.attemptCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (encryptedDek.present) {
      map['encrypted_dek'] = Variable<String>(encryptedDek.value);
    }
    if (dekIv.present) {
      map['dek_iv'] = Variable<String>(dekIv.value);
    }
    if (photoIv.present) {
      map['photo_iv'] = Variable<String>(photoIv.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntrusionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('photoPath: $photoPath, ')
          ..write('encryptedDek: $encryptedDek, ')
          ..write('dekIv: $dekIv, ')
          ..write('photoIv: $photoIv, ')
          ..write('timestamp: $timestamp, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VaultFoldersTable vaultFolders = $VaultFoldersTable(this);
  late final $VaultFilesTable vaultFiles = $VaultFilesTable(this);
  late final $IntrusionRecordsTable intrusionRecords = $IntrusionRecordsTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vaultFolders,
    vaultFiles,
    intrusionRecords,
    appSettings,
  ];
}

typedef $$VaultFoldersTableCreateCompanionBuilder =
    VaultFoldersCompanion Function({
      required String id,
      required String name,
      Value<String?> colorHex,
      Value<String?> iconName,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultFoldersTableUpdateCompanionBuilder =
    VaultFoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> colorHex,
      Value<String?> iconName,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$VaultFoldersTableReferences
    extends BaseReferences<_$AppDatabase, $VaultFoldersTable, VaultFolder> {
  $$VaultFoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VaultFilesTable, List<VaultFile>>
  _vaultFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vaultFiles,
    aliasName: $_aliasNameGenerator(db.vaultFolders.id, db.vaultFiles.folderId),
  );

  $$VaultFilesTableProcessedTableManager get vaultFilesRefs {
    final manager = $$VaultFilesTableTableManager(
      $_db,
      $_db.vaultFiles,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vaultFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VaultFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> vaultFilesRefs(
    Expression<bool> Function($$VaultFilesTableFilterComposer f) f,
  ) {
    final $$VaultFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vaultFiles,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultFilesTableFilterComposer(
            $db: $db,
            $table: $db.vaultFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VaultFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> vaultFilesRefs<T extends Object>(
    Expression<T> Function($$VaultFilesTableAnnotationComposer a) f,
  ) {
    final $$VaultFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vaultFiles,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.vaultFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VaultFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultFoldersTable,
          VaultFolder,
          $$VaultFoldersTableFilterComposer,
          $$VaultFoldersTableOrderingComposer,
          $$VaultFoldersTableAnnotationComposer,
          $$VaultFoldersTableCreateCompanionBuilder,
          $$VaultFoldersTableUpdateCompanionBuilder,
          (VaultFolder, $$VaultFoldersTableReferences),
          VaultFolder,
          PrefetchHooks Function({bool vaultFilesRefs})
        > {
  $$VaultFoldersTableTableManager(_$AppDatabase db, $VaultFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> iconName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFoldersCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                iconName: iconName,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> colorHex = const Value.absent(),
                Value<String?> iconName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultFoldersCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                iconName: iconName,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VaultFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vaultFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (vaultFilesRefs) db.vaultFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vaultFilesRefs)
                    await $_getPrefetchedData<
                      VaultFolder,
                      $VaultFoldersTable,
                      VaultFile
                    >(
                      currentTable: table,
                      referencedTable: $$VaultFoldersTableReferences
                          ._vaultFilesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VaultFoldersTableReferences(
                            db,
                            table,
                            p0,
                          ).vaultFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VaultFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultFoldersTable,
      VaultFolder,
      $$VaultFoldersTableFilterComposer,
      $$VaultFoldersTableOrderingComposer,
      $$VaultFoldersTableAnnotationComposer,
      $$VaultFoldersTableCreateCompanionBuilder,
      $$VaultFoldersTableUpdateCompanionBuilder,
      (VaultFolder, $$VaultFoldersTableReferences),
      VaultFolder,
      PrefetchHooks Function({bool vaultFilesRefs})
    >;
typedef $$VaultFilesTableCreateCompanionBuilder =
    VaultFilesCompanion Function({
      required String id,
      required String folderId,
      required String originalName,
      required String fileType,
      required String mimeType,
      required String encryptedPath,
      Value<String?> thumbnailPath,
      required int fileSize,
      required int encryptedSize,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      required String encryptedDek,
      required String dekIv,
      required String fileIv,
      Value<int> chunkCount,
      required String checksum,
      Value<bool> isDeleted,
      Value<int?> deletedAt,
      Value<String?> originalFolderId,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$VaultFilesTableUpdateCompanionBuilder =
    VaultFilesCompanion Function({
      Value<String> id,
      Value<String> folderId,
      Value<String> originalName,
      Value<String> fileType,
      Value<String> mimeType,
      Value<String> encryptedPath,
      Value<String?> thumbnailPath,
      Value<int> fileSize,
      Value<int> encryptedSize,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMs,
      Value<String> encryptedDek,
      Value<String> dekIv,
      Value<String> fileIv,
      Value<int> chunkCount,
      Value<String> checksum,
      Value<bool> isDeleted,
      Value<int?> deletedAt,
      Value<String?> originalFolderId,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$VaultFilesTableReferences
    extends BaseReferences<_$AppDatabase, $VaultFilesTable, VaultFile> {
  $$VaultFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VaultFoldersTable _folderIdTable(_$AppDatabase db) =>
      db.vaultFolders.createAlias(
        $_aliasNameGenerator(db.vaultFiles.folderId, db.vaultFolders.id),
      );

  $$VaultFoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<String>('folder_id')!;

    final manager = $$VaultFoldersTableTableManager(
      $_db,
      $_db.vaultFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VaultFilesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get encryptedSize => $composableBuilder(
    column: $table.encryptedSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dekIv => $composableBuilder(
    column: $table.dekIv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileIv => $composableBuilder(
    column: $table.fileIv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFolderId => $composableBuilder(
    column: $table.originalFolderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VaultFoldersTableFilterComposer get folderId {
    final $$VaultFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.vaultFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultFoldersTableFilterComposer(
            $db: $db,
            $table: $db.vaultFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaultFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get encryptedSize => $composableBuilder(
    column: $table.encryptedSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dekIv => $composableBuilder(
    column: $table.dekIv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileIv => $composableBuilder(
    column: $table.fileIv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFolderId => $composableBuilder(
    column: $table.originalFolderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VaultFoldersTableOrderingComposer get folderId {
    final $$VaultFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.vaultFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.vaultFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaultFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get encryptedSize => $composableBuilder(
    column: $table.encryptedSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dekIv =>
      $composableBuilder(column: $table.dekIv, builder: (column) => column);

  GeneratedColumn<String> get fileIv =>
      $composableBuilder(column: $table.fileIv, builder: (column) => column);

  GeneratedColumn<int> get chunkCount => $composableBuilder(
    column: $table.chunkCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originalFolderId => $composableBuilder(
    column: $table.originalFolderId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VaultFoldersTableAnnotationComposer get folderId {
    final $$VaultFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.vaultFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaultFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.vaultFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaultFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultFilesTable,
          VaultFile,
          $$VaultFilesTableFilterComposer,
          $$VaultFilesTableOrderingComposer,
          $$VaultFilesTableAnnotationComposer,
          $$VaultFilesTableCreateCompanionBuilder,
          $$VaultFilesTableUpdateCompanionBuilder,
          (VaultFile, $$VaultFilesTableReferences),
          VaultFile,
          PrefetchHooks Function({bool folderId})
        > {
  $$VaultFilesTableTableManager(_$AppDatabase db, $VaultFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> encryptedPath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> encryptedSize = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> encryptedDek = const Value.absent(),
                Value<String> dekIv = const Value.absent(),
                Value<String> fileIv = const Value.absent(),
                Value<int> chunkCount = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> originalFolderId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion(
                id: id,
                folderId: folderId,
                originalName: originalName,
                fileType: fileType,
                mimeType: mimeType,
                encryptedPath: encryptedPath,
                thumbnailPath: thumbnailPath,
                fileSize: fileSize,
                encryptedSize: encryptedSize,
                width: width,
                height: height,
                durationMs: durationMs,
                encryptedDek: encryptedDek,
                dekIv: dekIv,
                fileIv: fileIv,
                chunkCount: chunkCount,
                checksum: checksum,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                originalFolderId: originalFolderId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String folderId,
                required String originalName,
                required String fileType,
                required String mimeType,
                required String encryptedPath,
                Value<String?> thumbnailPath = const Value.absent(),
                required int fileSize,
                required int encryptedSize,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                required String encryptedDek,
                required String dekIv,
                required String fileIv,
                Value<int> chunkCount = const Value.absent(),
                required String checksum,
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> originalFolderId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion.insert(
                id: id,
                folderId: folderId,
                originalName: originalName,
                fileType: fileType,
                mimeType: mimeType,
                encryptedPath: encryptedPath,
                thumbnailPath: thumbnailPath,
                fileSize: fileSize,
                encryptedSize: encryptedSize,
                width: width,
                height: height,
                durationMs: durationMs,
                encryptedDek: encryptedDek,
                dekIv: dekIv,
                fileIv: fileIv,
                chunkCount: chunkCount,
                checksum: checksum,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                originalFolderId: originalFolderId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VaultFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (folderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.folderId,
                                referencedTable: $$VaultFilesTableReferences
                                    ._folderIdTable(db),
                                referencedColumn: $$VaultFilesTableReferences
                                    ._folderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VaultFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultFilesTable,
      VaultFile,
      $$VaultFilesTableFilterComposer,
      $$VaultFilesTableOrderingComposer,
      $$VaultFilesTableAnnotationComposer,
      $$VaultFilesTableCreateCompanionBuilder,
      $$VaultFilesTableUpdateCompanionBuilder,
      (VaultFile, $$VaultFilesTableReferences),
      VaultFile,
      PrefetchHooks Function({bool folderId})
    >;
typedef $$IntrusionRecordsTableCreateCompanionBuilder =
    IntrusionRecordsCompanion Function({
      required String id,
      required String photoPath,
      required String encryptedDek,
      required String dekIv,
      required String photoIv,
      required int timestamp,
      required int attemptCount,
      Value<int> rowid,
    });
typedef $$IntrusionRecordsTableUpdateCompanionBuilder =
    IntrusionRecordsCompanion Function({
      Value<String> id,
      Value<String> photoPath,
      Value<String> encryptedDek,
      Value<String> dekIv,
      Value<String> photoIv,
      Value<int> timestamp,
      Value<int> attemptCount,
      Value<int> rowid,
    });

class $$IntrusionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $IntrusionRecordsTable> {
  $$IntrusionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dekIv => $composableBuilder(
    column: $table.dekIv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoIv => $composableBuilder(
    column: $table.photoIv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntrusionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntrusionRecordsTable> {
  $$IntrusionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dekIv => $composableBuilder(
    column: $table.dekIv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoIv => $composableBuilder(
    column: $table.photoIv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntrusionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntrusionRecordsTable> {
  $$IntrusionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get encryptedDek => $composableBuilder(
    column: $table.encryptedDek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dekIv =>
      $composableBuilder(column: $table.dekIv, builder: (column) => column);

  GeneratedColumn<String> get photoIv =>
      $composableBuilder(column: $table.photoIv, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );
}

class $$IntrusionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntrusionRecordsTable,
          IntrusionRecord,
          $$IntrusionRecordsTableFilterComposer,
          $$IntrusionRecordsTableOrderingComposer,
          $$IntrusionRecordsTableAnnotationComposer,
          $$IntrusionRecordsTableCreateCompanionBuilder,
          $$IntrusionRecordsTableUpdateCompanionBuilder,
          (
            IntrusionRecord,
            BaseReferences<
              _$AppDatabase,
              $IntrusionRecordsTable,
              IntrusionRecord
            >,
          ),
          IntrusionRecord,
          PrefetchHooks Function()
        > {
  $$IntrusionRecordsTableTableManager(
    _$AppDatabase db,
    $IntrusionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntrusionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntrusionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntrusionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> photoPath = const Value.absent(),
                Value<String> encryptedDek = const Value.absent(),
                Value<String> dekIv = const Value.absent(),
                Value<String> photoIv = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntrusionRecordsCompanion(
                id: id,
                photoPath: photoPath,
                encryptedDek: encryptedDek,
                dekIv: dekIv,
                photoIv: photoIv,
                timestamp: timestamp,
                attemptCount: attemptCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String photoPath,
                required String encryptedDek,
                required String dekIv,
                required String photoIv,
                required int timestamp,
                required int attemptCount,
                Value<int> rowid = const Value.absent(),
              }) => IntrusionRecordsCompanion.insert(
                id: id,
                photoPath: photoPath,
                encryptedDek: encryptedDek,
                dekIv: dekIv,
                photoIv: photoIv,
                timestamp: timestamp,
                attemptCount: attemptCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntrusionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntrusionRecordsTable,
      IntrusionRecord,
      $$IntrusionRecordsTableFilterComposer,
      $$IntrusionRecordsTableOrderingComposer,
      $$IntrusionRecordsTableAnnotationComposer,
      $$IntrusionRecordsTableCreateCompanionBuilder,
      $$IntrusionRecordsTableUpdateCompanionBuilder,
      (
        IntrusionRecord,
        BaseReferences<_$AppDatabase, $IntrusionRecordsTable, IntrusionRecord>,
      ),
      IntrusionRecord,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultFoldersTableTableManager get vaultFolders =>
      $$VaultFoldersTableTableManager(_db, _db.vaultFolders);
  $$VaultFilesTableTableManager get vaultFiles =>
      $$VaultFilesTableTableManager(_db, _db.vaultFiles);
  $$IntrusionRecordsTableTableManager get intrusionRecords =>
      $$IntrusionRecordsTableTableManager(_db, _db.intrusionRecords);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
