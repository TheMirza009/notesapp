// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMediaCollection on Isar {
  IsarCollection<Media> get medias => this.collection();
}

const MediaSchema = CollectionSchema(
  name: r'Media',
  id: 6434281596432674333,
  properties: {
    r'aspectRatio': PropertySchema(
      id: 0,
      name: r'aspectRatio',
      type: IsarType.double,
    ),
    r'blurHash': PropertySchema(
      id: 1,
      name: r'blurHash',
      type: IsarType.string,
    ),
    r'duration': PropertySchema(
      id: 2,
      name: r'duration',
      type: IsarType.string,
    ),
    r'extension': PropertySchema(
      id: 3,
      name: r'extension',
      type: IsarType.string,
    ),
    r'fileSize': PropertySchema(id: 4, name: r'fileSize', type: IsarType.long),
    r'fileSizeDisplay': PropertySchema(
      id: 5,
      name: r'fileSizeDisplay',
      type: IsarType.string,
    ),
    r'hasCompleteMetadata': PropertySchema(
      id: 6,
      name: r'hasCompleteMetadata',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(id: 7, name: r'hashCode', type: IsarType.long),
    r'name': PropertySchema(id: 8, name: r'name', type: IsarType.string),
    r'path': PropertySchema(id: 9, name: r'path', type: IsarType.string),
    r'thumbnailPath': PropertySchema(
      id: 10,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.byte,
      enumMap: _MediatypeEnumValueMap,
    ),
  },

  estimateSize: _mediaEstimateSize,
  serialize: _mediaSerialize,
  deserialize: _mediaDeserialize,
  deserializeProp: _mediaDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {
    r'messagesBacklink': LinkSchema(
      id: 692095891292616884,
      name: r'messagesBacklink',
      target: r'Message',
      single: false,
      linkName: r'media',
    ),
  },
  embeddedSchemas: {},

  getId: _mediaGetId,
  getLinks: _mediaGetLinks,
  attach: _mediaAttach,
  version: '3.3.0',
);

int _mediaEstimateSize(
  Media object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.blurHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.duration;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.extension.length * 3;
  bytesCount += 3 + object.fileSizeDisplay.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.path;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mediaSerialize(
  Media object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.aspectRatio);
  writer.writeString(offsets[1], object.blurHash);
  writer.writeString(offsets[2], object.duration);
  writer.writeString(offsets[3], object.extension);
  writer.writeLong(offsets[4], object.fileSize);
  writer.writeString(offsets[5], object.fileSizeDisplay);
  writer.writeBool(offsets[6], object.hasCompleteMetadata);
  writer.writeLong(offsets[7], object.hashCode);
  writer.writeString(offsets[8], object.name);
  writer.writeString(offsets[9], object.path);
  writer.writeString(offsets[10], object.thumbnailPath);
  writer.writeByte(offsets[11], object.type.index);
}

Media _mediaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Media();
  object.aspectRatio = reader.readDoubleOrNull(offsets[0]);
  object.blurHash = reader.readStringOrNull(offsets[1]);
  object.duration = reader.readStringOrNull(offsets[2]);
  object.extension = reader.readString(offsets[3]);
  object.fileSize = reader.readLongOrNull(offsets[4]);
  object.isarId = id;
  object.name = reader.readString(offsets[8]);
  object.path = reader.readStringOrNull(offsets[9]);
  object.thumbnailPath = reader.readStringOrNull(offsets[10]);
  object.type =
      _MediatypeValueEnumMap[reader.readByteOrNull(offsets[11])] ??
      Mediatype.text;
  return object;
}

P _mediaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (_MediatypeValueEnumMap[reader.readByteOrNull(offset)] ??
              Mediatype.text)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MediatypeEnumValueMap = {
  'text': 0,
  'image': 1,
  'video': 2,
  'audio': 3,
  'document': 4,
  'link': 5,
  'contact': 6,
  'location': 7,
  'chart': 8,
  'thread': 9,
  'scan': 10,
  'unknown': 11,
};
const _MediatypeValueEnumMap = {
  0: Mediatype.text,
  1: Mediatype.image,
  2: Mediatype.video,
  3: Mediatype.audio,
  4: Mediatype.document,
  5: Mediatype.link,
  6: Mediatype.contact,
  7: Mediatype.location,
  8: Mediatype.chart,
  9: Mediatype.thread,
  10: Mediatype.scan,
  11: Mediatype.unknown,
};

Id _mediaGetId(Media object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _mediaGetLinks(Media object) {
  return [object.messagesBacklink];
}

void _mediaAttach(IsarCollection<dynamic> col, Id id, Media object) {
  object.isarId = id;
  object.messagesBacklink.attach(
    col,
    col.isar.collection<Message>(),
    r'messagesBacklink',
    id,
  );
}

extension MediaQueryWhereSort on QueryBuilder<Media, Media, QWhere> {
  QueryBuilder<Media, Media, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MediaQueryWhere on QueryBuilder<Media, Media, QWhereClause> {
  QueryBuilder<Media, Media, QAfterWhereClause> isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: isarId, upper: isarId),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> isarIdGreaterThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> isarIdLessThan(
    Id isarId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerIsarId,
          includeLower: includeLower,
          upper: upperIsarId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MediaQueryFilter on QueryBuilder<Media, Media, QFilterCondition> {
  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'aspectRatio'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'aspectRatio'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'aspectRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'aspectRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'aspectRatio',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> aspectRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'aspectRatio',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'blurHash'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'blurHash'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'blurHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'blurHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'blurHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'blurHash', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> blurHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'blurHash', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'duration'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'duration'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'duration',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'duration',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'duration',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'duration', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'duration', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'extension',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'extension',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'extension', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> extensionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'extension', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fileSize'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fileSize'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSize', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSizeDisplay',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileSizeDisplay',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileSizeDisplay',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> fileSizeDisplayIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSizeDisplay', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  fileSizeDisplayIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileSizeDisplay', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hasCompleteMetadataEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasCompleteMetadata', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hashCode', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'hashCode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'hashCode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'hashCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isarId', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'isarId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'isarId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'path'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'path'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'path',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'path',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> typeEqualTo(
    Mediatype value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> typeGreaterThan(
    Mediatype value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> typeLessThan(
    Mediatype value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> typeBetween(
    Mediatype lower,
    Mediatype upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MediaQueryObject on QueryBuilder<Media, Media, QFilterCondition> {}

extension MediaQueryLinks on QueryBuilder<Media, Media, QFilterCondition> {
  QueryBuilder<Media, Media, QAfterFilterCondition> messagesBacklink(
    FilterQuery<Message> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'messagesBacklink');
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  messagesBacklinkLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messagesBacklink', length, true, length, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> messagesBacklinkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messagesBacklink', 0, true, 0, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  messagesBacklinkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messagesBacklink', 0, false, 999999, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  messagesBacklinkLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messagesBacklink', 0, true, length, include);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  messagesBacklinkLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
        r'messagesBacklink',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  messagesBacklinkLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
        r'messagesBacklink',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MediaQuerySortBy on QueryBuilder<Media, Media, QSortBy> {
  QueryBuilder<Media, Media, QAfterSortBy> sortByAspectRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aspectRatio', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByAspectRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aspectRatio', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByBlurHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHash', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByBlurHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHash', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByFileSizeDisplay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeDisplay', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByFileSizeDisplayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeDisplay', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHasCompleteMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompleteMetadata', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHasCompleteMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompleteMetadata', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension MediaQuerySortThenBy on QueryBuilder<Media, Media, QSortThenBy> {
  QueryBuilder<Media, Media, QAfterSortBy> thenByAspectRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aspectRatio', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByAspectRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aspectRatio', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByBlurHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHash', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByBlurHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blurHash', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByFileSizeDisplay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeDisplay', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByFileSizeDisplayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSizeDisplay', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHasCompleteMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompleteMetadata', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHasCompleteMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCompleteMetadata', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension MediaQueryWhereDistinct on QueryBuilder<Media, Media, QDistinct> {
  QueryBuilder<Media, Media, QDistinct> distinctByAspectRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aspectRatio');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByBlurHash({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blurHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByDuration({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duration', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByExtension({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extension', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSize');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByFileSizeDisplay({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'fileSizeDisplay',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByHasCompleteMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasCompleteMetadata');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByThumbnailPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension MediaQueryProperty on QueryBuilder<Media, Media, QQueryProperty> {
  QueryBuilder<Media, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<Media, double?, QQueryOperations> aspectRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aspectRatio');
    });
  }

  QueryBuilder<Media, String?, QQueryOperations> blurHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blurHash');
    });
  }

  QueryBuilder<Media, String?, QQueryOperations> durationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duration');
    });
  }

  QueryBuilder<Media, String, QQueryOperations> extensionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extension');
    });
  }

  QueryBuilder<Media, int?, QQueryOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSize');
    });
  }

  QueryBuilder<Media, String, QQueryOperations> fileSizeDisplayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSizeDisplay');
    });
  }

  QueryBuilder<Media, bool, QQueryOperations> hasCompleteMetadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasCompleteMetadata');
    });
  }

  QueryBuilder<Media, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<Media, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Media, String?, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }

  QueryBuilder<Media, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<Media, Mediatype, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
