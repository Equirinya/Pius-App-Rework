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
    r'klasse': PropertySchema(
      id: 2,
      name: r'klasse',
      type: IsarType.string,
    ),
    r'kurs': PropertySchema(
      id: 3,
      name: r'kurs',
      type: IsarType.string,
    ),
    r'lehrkraft': PropertySchema(
      id: 4,
      name: r'lehrkraft',
      type: IsarType.string,
    ),
    r'raum': PropertySchema(
      id: 5,
      name: r'raum',
      type: IsarType.string,
    ),
    r'stunde': PropertySchema(
      id: 6,
      name: r'stunde',
      type: IsarType.string,
    ),
    r'tag': PropertySchema(
      id: 7,
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
  bytesCount += 3 + object.bemerkung.length * 3;
  bytesCount += 3 + object.klasse.length * 3;
  bytesCount += 3 + object.kurs.length * 3;
  bytesCount += 3 + object.lehrkraft.length * 3;
  bytesCount += 3 + object.raum.length * 3;
  bytesCount += 3 + object.stunde.length * 3;
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
  writer.writeString(offsets[2], object.klasse);
  writer.writeString(offsets[3], object.kurs);
  writer.writeString(offsets[4], object.lehrkraft);
  writer.writeString(offsets[5], object.raum);
  writer.writeString(offsets[6], object.stunde);
  writer.writeDateTime(offsets[7], object.tag);
}

Vertretung _vertretungDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Vertretung();
  object.art = reader.readString(offsets[0]);
  object.bemerkung = reader.readString(offsets[1]);
  object.id = id;
  object.klasse = reader.readString(offsets[2]);
  object.kurs = reader.readString(offsets[3]);
  object.lehrkraft = reader.readString(offsets[4]);
  object.raum = reader.readString(offsets[5]);
  object.stunde = reader.readString(offsets[6]);
  object.tag = reader.readDateTime(offsets[7]);
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
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
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

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> bemerkungEqualTo(
    String value, {
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
    String value, {
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
    String value, {
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
    String lower,
    String upper, {
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

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stunde',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stunde',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stunde',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition> stundeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stunde',
        value: '',
      ));
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterFilterCondition>
      stundeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stunde',
        value: '',
      ));
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

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByStunde() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stunde', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> sortByStundeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stunde', Sort.desc);
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

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByStunde() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stunde', Sort.asc);
    });
  }

  QueryBuilder<Vertretung, Vertretung, QAfterSortBy> thenByStundeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stunde', Sort.desc);
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

  QueryBuilder<Vertretung, Vertretung, QDistinct> distinctByStunde(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stunde', caseSensitive: caseSensitive);
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

  QueryBuilder<Vertretung, String, QQueryOperations> bemerkungProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bemerkung');
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

  QueryBuilder<Vertretung, String, QQueryOperations> stundeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stunde');
    });
  }

  QueryBuilder<Vertretung, DateTime, QQueryOperations> tagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tag');
    });
  }
}
