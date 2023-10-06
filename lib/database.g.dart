// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVertretungCollection on Isar {
  IsarCollection<Vertretung> get vertretungs => this.collection();
}

const VertretungSchema = CollectionSchema(
  name: r'Vertretung',
  id: -3664050377336799535,
  properties: {
    r'art': PropertySchema(
      id: 0,
      name: r'art',
      type: IsarType.string,
    ),
    r'bemerkung': PropertySchema(
      id: 1,
      name: r'bemerkung',
      type: IsarType.string,
    ),
    r'eva': PropertySchema(
      id: 2,
      name: r'eva',
      type: IsarType.string,
    ),
    r'hervorgehoben': PropertySchema(
      id: 3,
      name: r'hervorgehoben',
      type: IsarType.longList,
    ),
    r'klasse': PropertySchema(
      id: 4,
      name: r'klasse',
      type: IsarType.string,
    ),
    r'kurs': PropertySchema(
      id: 5,
      name: r'kurs',
      type: IsarType.string,
    ),
    r'lehrkraft': PropertySchema(
      id: 6,
      name: r'lehrkraft',
      type: IsarType.string,
    ),
    r'raum': PropertySchema(
      id: 7,
      name: r'raum',
      type: IsarType.string,
    ),
    r'stunden': PropertySchema(
      id: 8,
      name: r'stunden',
      type: IsarType.longList,
    ),
    r'tag': PropertySchema(
      id: 9,
      name: r'tag',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _vertretungEstimateSize,
  serialize: _vertretungSerialize,
  deserialize: _vertretungDeserialize,
  deserializeProp: _vertretungDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _vertretungGetId,
  getLinks: _vertretungGetLinks,
  attach: _vertretungAttach,
  version: '3.1.0+1',
);

int _vertretungEstimateSize(
  Vertretung object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.art.length * 3;
  {
    final value = object.bemerkung;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.eva;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.hervorgehoben.length * 8;
  bytesCount += 3 + object.klasse.length * 3;
  bytesCount += 3 + object.kurs.length * 3;
  bytesCount += 3 + object.lehrkraft.length * 3;
  bytesCount += 3 + object.raum.length * 3;
  bytesCount += 3 + object.stunden.length * 8;
  return bytesCount;
}

void _vertretungSerialize(
  Vertretung object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.art);
  writer.writeString(offsets[1], object.bemerkung);
  writer.writeString(offsets[2], object.eva);
  writer.writeLongList(offsets[3], object.hervorgehoben);
  writer.writeString(offsets[4], object.klasse);
  writer.writeString(offsets[5], object.kurs);
  writer.writeString(offsets[6], object.lehrkraft);
  writer.writeString(offsets[7], object.raum);
  writer.writeLongList(offsets[8], object.stunden);
  writer.writeDateTime(offsets[9], object.tag);
}

Vertretung _vertretungDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Vertretung();
  object.art = reader.readString(offsets[0]);
  object.bemerkung = reader.readStringOrNull(offsets[1]);
  object.eva = reader.readStringOrNull(offsets[2]);
  object.hervorgehoben = reader.readLongList(offsets[3]) ?? [];
  object.id = id;
  object.klasse = reader.readString(offsets[4]);
  object.kurs = reader.readString(offsets[5]);
  object.lehrkraft = reader.readString(offsets[6]);
  object.raum = reader.readString(offsets[7]);
  object.stunden = reader.readLongList(offsets[8]) ?? [];
  object.tag = reader.readDateTime(offsets[9]);
  return object;
}

P _vertretungDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongList(offset) ?? []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLongList(offset) ?? []) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _vertretungGetId(Vertretung object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _vertretungGetLinks(Vertretung object) {
  return [];
}

void _vertretungAttach(IsarCollection<dynamic> col, Id id, Vertretung object) {
  object.id = id;
}

extension VertretungQueryWhereSort
    on QueryBuilder<Vertretung, Vertretung, QWhere> {
  QueryBuilder<Vertretung, Vertretung, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VertretungQueryWhere
    on QueryBuilder<Vertretung, Vertretung, QWhereClause> {
  QueryBuilder<Vertretung, Vertretung, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VertretungQueryFilter
    on QueryBuilder<Vertretung, Vertretung, QFilterCondition> {
  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'art',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'art',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'art',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'art',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> artIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'art',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bemerkung',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bemerkung',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bemerkung',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bemerkung',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      bemerkungIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bemerkung',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eva',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eva',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eva',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'eva',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'eva',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eva',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> evaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'eva',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hervorgehoben',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hervorgehoben',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hervorgehoben',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hervorgehoben',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      hervorgehobenLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'hervorgehoben',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'klasse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'klasse',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'klasse',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> klasseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'klasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      klasseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'klasse',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kurs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kurs',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kurs',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kurs',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> kursIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kurs',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      lehrkraftGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lehrkraft',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      lehrkraftStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lehrkraft',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> lehrkraftMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lehrkraft',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      lehrkraftIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lehrkraft',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      lehrkraftIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lehrkraft',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'raum',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'raum',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'raum',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'raum',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> raumIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'raum',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stunden',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundenLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> tagEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> tagGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> tagLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> tagBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VertretungQueryObject
    on QueryBuilder<Vertretung, Vertretung, QFilterCondition> {}

extension VertretungQueryLinks
    on QueryBuilder<Vertretung, Vertretung, QFilterCondition> {}

extension VertretungQuerySortBy
    on QueryBuilder<Vertretung, Vertretung, QSortBy> {
  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByArt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'art', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByArtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'art', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByEva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eva', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByEvaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eva', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByKlasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'klasse', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByKlasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'klasse', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByKurs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kurs', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByKursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kurs', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByLehrkraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lehrkraft', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByLehrkraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lehrkraft', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByRaum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'raum', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByRaumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'raum', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }
}

extension VertretungQuerySortThenBy
    on QueryBuilder<Vertretung, Vertretung, QSortThenBy> {
  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByArt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'art', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByArtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'art', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByBemerkung() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByBemerkungDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bemerkung', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByEva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eva', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByEvaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eva', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByKlasse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'klasse', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByKlasseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'klasse', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByKurs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kurs', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByKursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kurs', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByLehrkraft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lehrkraft', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByLehrkraftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lehrkraft', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByRaum() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'raum', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByRaumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'raum', Sort.desc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }
}

extension VertretungQueryWhereDistinct
    on QueryBuilder<Vertretung, Vertretung, QDistinct> {
  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByArt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'art', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByBemerkung(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bemerkung', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByEva(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eva', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByHervorgehoben() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hervorgehoben');
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByKlasse(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'klasse', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByKurs(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kurs', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByLehrkraft(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lehrkraft', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByRaum(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'raum', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByStunden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stunden');
    });
  }

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tag');
    });
  }
}

extension VertretungQueryProperty
    on QueryBuilder<Vertretung, Vertretung, QQueryProperty> {
  QueryBuilder<Vertretung, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Vertretung, String, QQueryOperations> artProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'art');
    });
  }

  QueryBuilder<Vertretung, String?, QQueryOperations> bemerkungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bemerkung');
    });
  }

  QueryBuilder<Vertretung, String?, QQueryOperations> evaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eva');
    });
  }

  QueryBuilder<Vertretung, List<int>, QQueryOperations>
      hervorgehobenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hervorgehoben');
    });
  }

  QueryBuilder<Vertretung, String, QQueryOperations> klasseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'klasse');
    });
  }

  QueryBuilder<Vertretung, String, QQueryOperations> kursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kurs');
    });
  }

  QueryBuilder<Vertretung, String, QQueryOperations> lehrkraftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lehrkraft');
    });
  }

  QueryBuilder<Vertretung, String, QQueryOperations> raumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'raum');
    });
  }

  QueryBuilder<Vertretung, List<int>, QQueryOperations> stundenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stunden');
    });
  }

  QueryBuilder<Vertretung, DateTime, QQueryOperations> tagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tag');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStundeCollection on Isar {
  IsarCollection<Stunde> get stundes => this.collection();
}

const StundeSchema = CollectionSchema(
  name: r'Stunde',
  id: 5085109979897971483,
  properties: {
    r'geradeWoche': PropertySchema(
      id: 0,
      name: r'geradeWoche',
      type: IsarType.bool,
    ),
    r'gueltigAb': PropertySchema(
      id: 1,
      name: r'gueltigAb',
      type: IsarType.dateTime,
    ),
    r'gueltigBis': PropertySchema(
      id: 2,
      name: r'gueltigBis',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'stunden': PropertySchema(
      id: 4,
      name: r'stunden',
      type: IsarType.longList,
    ),
    r'tag': PropertySchema(
      id: 5,
      name: r'tag',
      type: IsarType.long,
    )
  },
  estimateSize: _stundeEstimateSize,
  serialize: _stundeSerialize,
  deserialize: _stundeDeserialize,
  deserializeProp: _stundeDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'vertretung': LinkSchema(
      id: 2386278722145345199,
      name: r'vertretung',
      target: r'Vertretung',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _stundeGetId,
  getLinks: _stundeGetLinks,
  attach: _stundeAttach,
  version: '3.1.0+1',
);

int _stundeEstimateSize(
  Stunde object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.stunden.length * 8;
  return bytesCount;
}

void _stundeSerialize(
  Stunde object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.geradeWoche);
  writer.writeDateTime(offsets[1], object.gueltigAb);
  writer.writeDateTime(offsets[2], object.gueltigBis);
  writer.writeString(offsets[3], object.name);
  writer.writeLongList(offsets[4], object.stunden);
  writer.writeLong(offsets[5], object.tag);
}

Stunde _stundeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Stunde();
  object.geradeWoche = reader.readBool(offsets[0]);
  object.gueltigAb = reader.readDateTime(offsets[1]);
  object.gueltigBis = reader.readDateTimeOrNull(offsets[2]);
  object.id = id;
  object.name = reader.readString(offsets[3]);
  object.stunden = reader.readLongList(offsets[4]) ?? [];
  object.tag = reader.readLong(offsets[5]);
  return object;
}

P _stundeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _stundeGetId(Stunde object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _stundeGetLinks(Stunde object) {
  return [object.vertretung];
}

void _stundeAttach(IsarCollection<dynamic> col, Id id, Stunde object) {
  object.id = id;
  object.vertretung
      .attach(col, col.isar.collection<Vertretung>(), r'vertretung', id);
}

extension StundeQueryWhereSort on QueryBuilder<Stunde, Stunde, QWhere> {
  QueryBuilder<Stunde, Stunde, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StundeQueryWhere on QueryBuilder<Stunde, Stunde, QWhereClause> {
  QueryBuilder<Stunde, Stunde, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension StundeQueryFilter on QueryBuilder<Stunde, Stunde, QFilterCondition> {
  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> geradeWocheEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'geradeWoche',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigAbEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gueltigAb',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigAbGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gueltigAb',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigAbLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gueltigAb',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigAbBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gueltigAb',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gueltigBis',
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gueltigBis',
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gueltigBis',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gueltigBis',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gueltigBis',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> gueltigBisBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gueltigBis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenElementEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stunden',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stunden',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> stundenLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'stunden',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> tagEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> tagGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> tagLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tag',
        value: value,
      ));
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> tagBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension StundeQueryObject on QueryBuilder<Stunde, Stunde, QFilterCondition> {}

extension StundeQueryLinks on QueryBuilder<Stunde, Stunde, QFilterCondition> {
  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> vertretung(
      FilterQuery<Vertretung> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'vertretung');
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterFilterCondition> vertretungIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'vertretung', 0, true, 0, true);
    });
  }
}

extension StundeQuerySortBy on QueryBuilder<Stunde, Stunde, QSortBy> {
  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGeradeWoche() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geradeWoche', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGeradeWocheDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geradeWoche', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGueltigAb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigAb', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGueltigAbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigAb', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGueltigBis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigBis', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByGueltigBisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigBis', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> sortByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }
}

extension StundeQuerySortThenBy on QueryBuilder<Stunde, Stunde, QSortThenBy> {
  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGeradeWoche() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geradeWoche', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGeradeWocheDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'geradeWoche', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGueltigAb() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigAb', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGueltigAbDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigAb', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGueltigBis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigBis', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByGueltigBisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gueltigBis', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.asc);
    });
  }

  QueryBuilder<Stunde, Stunde, QAfterSortBy> thenByTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tag', Sort.desc);
    });
  }
}

extension StundeQueryWhereDistinct on QueryBuilder<Stunde, Stunde, QDistinct> {
  QueryBuilder<Stunde, Stunde, QDistinct> distinctByGeradeWoche() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'geradeWoche');
    });
  }

  QueryBuilder<Stunde, Stunde, QDistinct> distinctByGueltigAb() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gueltigAb');
    });
  }

  QueryBuilder<Stunde, Stunde, QDistinct> distinctByGueltigBis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gueltigBis');
    });
  }

  QueryBuilder<Stunde, Stunde, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Stunde, Stunde, QDistinct> distinctByStunden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stunden');
    });
  }

  QueryBuilder<Stunde, Stunde, QDistinct> distinctByTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tag');
    });
  }
}

extension StundeQueryProperty on QueryBuilder<Stunde, Stunde, QQueryProperty> {
  QueryBuilder<Stunde, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Stunde, bool, QQueryOperations> geradeWocheProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'geradeWoche');
    });
  }

  QueryBuilder<Stunde, DateTime, QQueryOperations> gueltigAbProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gueltigAb');
    });
  }

  QueryBuilder<Stunde, DateTime?, QQueryOperations> gueltigBisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gueltigBis');
    });
  }

  QueryBuilder<Stunde, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Stunde, List<int>, QQueryOperations> stundenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stunden');
    });
  }

  QueryBuilder<Stunde, int, QQueryOperations> tagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tag');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetColorPaletteCollection on Isar {
  IsarCollection<ColorPalette> get colorPalettes => this.collection();
}

const ColorPaletteSchema = CollectionSchema(
  name: r'ColorPalette',
  id: -1767037764910224385,
  properties: {
    r'errorB': PropertySchema(
      id: 0,
      name: r'errorB',
      type: IsarType.long,
    ),
    r'errorG': PropertySchema(
      id: 1,
      name: r'errorG',
      type: IsarType.long,
    ),
    r'errorR': PropertySchema(
      id: 2,
      name: r'errorR',
      type: IsarType.long,
    ),
    r'fromSeed': PropertySchema(
      id: 3,
      name: r'fromSeed',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'primaryB': PropertySchema(
      id: 5,
      name: r'primaryB',
      type: IsarType.long,
    ),
    r'primaryG': PropertySchema(
      id: 6,
      name: r'primaryG',
      type: IsarType.long,
    ),
    r'primaryR': PropertySchema(
      id: 7,
      name: r'primaryR',
      type: IsarType.long,
    ),
    r'secondaryB': PropertySchema(
      id: 8,
      name: r'secondaryB',
      type: IsarType.long,
    ),
    r'secondaryG': PropertySchema(
      id: 9,
      name: r'secondaryG',
      type: IsarType.long,
    ),
    r'secondaryR': PropertySchema(
      id: 10,
      name: r'secondaryR',
      type: IsarType.long,
    ),
    r'tertiaryB': PropertySchema(
      id: 11,
      name: r'tertiaryB',
      type: IsarType.long,
    ),
    r'tertiaryG': PropertySchema(
      id: 12,
      name: r'tertiaryG',
      type: IsarType.long,
    ),
    r'tertiaryR': PropertySchema(
      id: 13,
      name: r'tertiaryR',
      type: IsarType.long,
    )
  },
  estimateSize: _colorPaletteEstimateSize,
  serialize: _colorPaletteSerialize,
  deserialize: _colorPaletteDeserialize,
  deserializeProp: _colorPaletteDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _colorPaletteGetId,
  getLinks: _colorPaletteGetLinks,
  attach: _colorPaletteAttach,
  version: '3.1.0+1',
);

int _colorPaletteEstimateSize(
  ColorPalette object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _colorPaletteSerialize(
  ColorPalette object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.errorB);
  writer.writeLong(offsets[1], object.errorG);
  writer.writeLong(offsets[2], object.errorR);
  writer.writeBool(offsets[3], object.fromSeed);
  writer.writeString(offsets[4], object.name);
  writer.writeLong(offsets[5], object.primaryB);
  writer.writeLong(offsets[6], object.primaryG);
  writer.writeLong(offsets[7], object.primaryR);
  writer.writeLong(offsets[8], object.secondaryB);
  writer.writeLong(offsets[9], object.secondaryG);
  writer.writeLong(offsets[10], object.secondaryR);
  writer.writeLong(offsets[11], object.tertiaryB);
  writer.writeLong(offsets[12], object.tertiaryG);
  writer.writeLong(offsets[13], object.tertiaryR);
}

ColorPalette _colorPaletteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ColorPalette();
  object.errorB = reader.readLongOrNull(offsets[0]);
  object.errorG = reader.readLongOrNull(offsets[1]);
  object.errorR = reader.readLongOrNull(offsets[2]);
  object.fromSeed = reader.readBool(offsets[3]);
  object.id = id;
  object.name = reader.readStringOrNull(offsets[4]);
  object.primaryB = reader.readLongOrNull(offsets[5]);
  object.primaryG = reader.readLongOrNull(offsets[6]);
  object.primaryR = reader.readLongOrNull(offsets[7]);
  object.secondaryB = reader.readLongOrNull(offsets[8]);
  object.secondaryG = reader.readLongOrNull(offsets[9]);
  object.secondaryR = reader.readLongOrNull(offsets[10]);
  object.tertiaryB = reader.readLongOrNull(offsets[11]);
  object.tertiaryG = reader.readLongOrNull(offsets[12]);
  object.tertiaryR = reader.readLongOrNull(offsets[13]);
  return object;
}

P _colorPaletteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _colorPaletteGetId(ColorPalette object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _colorPaletteGetLinks(ColorPalette object) {
  return [];
}

void _colorPaletteAttach(
    IsarCollection<dynamic> col, Id id, ColorPalette object) {
  object.id = id;
}

extension ColorPaletteQueryWhereSort
    on QueryBuilder<ColorPalette, ColorPalette, QWhere> {
  QueryBuilder<ColorPalette, ColorPalette, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ColorPaletteQueryWhere
    on QueryBuilder<ColorPalette, ColorPalette, QWhereClause> {
  QueryBuilder<ColorPalette, ColorPalette, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ColorPaletteQueryFilter
    on QueryBuilder<ColorPalette, ColorPalette, QFilterCondition> {
  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorBIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorBIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorBEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorBGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorBLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorBBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorGEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorGGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorGLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorGBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorRIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorRIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorREqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorRGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      errorRLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> errorRBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorR',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      fromSeedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromSeed',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'primaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'primaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryBBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primaryB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'primaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'primaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryGBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primaryG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryRIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'primaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryRIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'primaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryREqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryRGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryRLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      primaryRBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primaryR',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'secondaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'secondaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryBBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondaryB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'secondaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'secondaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryGBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondaryG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryRIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'secondaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryRIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'secondaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryREqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryRGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryRLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      secondaryRBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondaryR',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tertiaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tertiaryB',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tertiaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tertiaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tertiaryB',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryBBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tertiaryB',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tertiaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tertiaryG',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tertiaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tertiaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tertiaryG',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryGBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tertiaryG',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryRIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tertiaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryRIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tertiaryR',
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryREqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tertiaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryRGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tertiaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryRLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tertiaryR',
        value: value,
      ));
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterFilterCondition>
      tertiaryRBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tertiaryR',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ColorPaletteQueryObject
    on QueryBuilder<ColorPalette, ColorPalette, QFilterCondition> {}

extension ColorPaletteQueryLinks
    on QueryBuilder<ColorPalette, ColorPalette, QFilterCondition> {}

extension ColorPaletteQuerySortBy
    on QueryBuilder<ColorPalette, ColorPalette, QSortBy> {
  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByErrorRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByFromSeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromSeed', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByFromSeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromSeed', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByPrimaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortBySecondaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      sortBySecondaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortBySecondaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      sortBySecondaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortBySecondaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      sortBySecondaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> sortByTertiaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryR', Sort.desc);
    });
  }
}

extension ColorPaletteQuerySortThenBy
    on QueryBuilder<ColorPalette, ColorPalette, QSortThenBy> {
  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByErrorRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByFromSeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromSeed', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByFromSeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromSeed', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByPrimaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenBySecondaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      thenBySecondaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenBySecondaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      thenBySecondaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenBySecondaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy>
      thenBySecondaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondaryR', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryB', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryBDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryB', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryG', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryGDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryG', Sort.desc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryR', Sort.asc);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QAfterSortBy> thenByTertiaryRDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiaryR', Sort.desc);
    });
  }
}

extension ColorPaletteQueryWhereDistinct
    on QueryBuilder<ColorPalette, ColorPalette, QDistinct> {
  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByErrorB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorB');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByErrorG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorG');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByErrorR() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorR');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByFromSeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromSeed');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByPrimaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primaryB');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByPrimaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primaryG');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByPrimaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primaryR');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctBySecondaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondaryB');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctBySecondaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondaryG');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctBySecondaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondaryR');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByTertiaryB() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tertiaryB');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByTertiaryG() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tertiaryG');
    });
  }

  QueryBuilder<ColorPalette, ColorPalette, QDistinct> distinctByTertiaryR() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tertiaryR');
    });
  }
}

extension ColorPaletteQueryProperty
    on QueryBuilder<ColorPalette, ColorPalette, QQueryProperty> {
  QueryBuilder<ColorPalette, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> errorBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorB');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> errorGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorG');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> errorRProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorR');
    });
  }

  QueryBuilder<ColorPalette, bool, QQueryOperations> fromSeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromSeed');
    });
  }

  QueryBuilder<ColorPalette, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> primaryBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryB');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> primaryGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryG');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> primaryRProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryR');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> secondaryBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondaryB');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> secondaryGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondaryG');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> secondaryRProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondaryR');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> tertiaryBProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tertiaryB');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> tertiaryGProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tertiaryG');
    });
  }

  QueryBuilder<ColorPalette, int?, QQueryOperations> tertiaryRProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tertiaryR');
    });
  }
}
