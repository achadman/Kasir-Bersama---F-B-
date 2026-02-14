// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_transaction.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalTransactionCollection on Isar {
  IsarCollection<LocalTransaction> get localTransactions => this.collection();
}

const LocalTransactionSchema = CollectionSchema(
  name: r'LocalTransaction',
  id: 7379932157198425088,
  properties: {
    r'cashReceived': PropertySchema(
      id: 0,
      name: r'cashReceived',
      type: IsarType.double,
    ),
    r'cashierId': PropertySchema(
      id: 1,
      name: r'cashierId',
      type: IsarType.string,
    ),
    r'change': PropertySchema(id: 2, name: r'change', type: IsarType.double),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isSynced': PropertySchema(id: 4, name: r'isSynced', type: IsarType.bool),
    r'items': PropertySchema(
      id: 5,
      name: r'items',
      type: IsarType.objectList,
      target: r'LocalTransactionItemData',
    ),
    r'paymentMethod': PropertySchema(
      id: 6,
      name: r'paymentMethod',
      type: IsarType.string,
    ),
    r'storeId': PropertySchema(id: 7, name: r'storeId', type: IsarType.string),
    r'supabaseId': PropertySchema(
      id: 8,
      name: r'supabaseId',
      type: IsarType.string,
    ),
    r'totalAmount': PropertySchema(
      id: 9,
      name: r'totalAmount',
      type: IsarType.double,
    ),
  },
  estimateSize: _localTransactionEstimateSize,
  serialize: _localTransactionSerialize,
  deserialize: _localTransactionDeserialize,
  deserializeProp: _localTransactionDeserializeProp,
  idName: r'id',
  indexes: {
    r'storeId': IndexSchema(
      id: 2730892149058446336,
      name: r'storeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'storeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isSynced': IndexSchema(
      id: -39763503327887512,
      name: r'isSynced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isSynced',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'LocalTransactionItemData': LocalTransactionItemDataSchema,
  },
  getId: _localTransactionGetId,
  getLinks: _localTransactionGetLinks,
  attach: _localTransactionAttach,
  version: '3.1.0+1',
);

int _localTransactionEstimateSize(
  LocalTransaction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cashierId.length * 3;
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[LocalTransactionItemData]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += LocalTransactionItemDataSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.paymentMethod.length * 3;
  bytesCount += 3 + object.storeId.length * 3;
  {
    final value = object.supabaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _localTransactionSerialize(
  LocalTransaction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.cashReceived);
  writer.writeString(offsets[1], object.cashierId);
  writer.writeDouble(offsets[2], object.change);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeObjectList<LocalTransactionItemData>(
    offsets[5],
    allOffsets,
    LocalTransactionItemDataSchema.serialize,
    object.items,
  );
  writer.writeString(offsets[6], object.paymentMethod);
  writer.writeString(offsets[7], object.storeId);
  writer.writeString(offsets[8], object.supabaseId);
  writer.writeDouble(offsets[9], object.totalAmount);
}

LocalTransaction _localTransactionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalTransaction();
  object.cashReceived = reader.readDouble(offsets[0]);
  object.cashierId = reader.readString(offsets[1]);
  object.change = reader.readDouble(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.items =
      reader.readObjectList<LocalTransactionItemData>(
        offsets[5],
        LocalTransactionItemDataSchema.deserialize,
        allOffsets,
        LocalTransactionItemData(),
      ) ??
      [];
  object.paymentMethod = reader.readString(offsets[6]);
  object.storeId = reader.readString(offsets[7]);
  object.supabaseId = reader.readStringOrNull(offsets[8]);
  object.totalAmount = reader.readDouble(offsets[9]);
  return object;
}

P _localTransactionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readObjectList<LocalTransactionItemData>(
                offset,
                LocalTransactionItemDataSchema.deserialize,
                allOffsets,
                LocalTransactionItemData(),
              ) ??
              [])
          as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localTransactionGetId(LocalTransaction object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localTransactionGetLinks(LocalTransaction object) {
  return [];
}

void _localTransactionAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalTransaction object,
) {
  object.id = id;
}

extension LocalTransactionQueryWhereSort
    on QueryBuilder<LocalTransaction, LocalTransaction, QWhere> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhere> anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }
}

extension LocalTransactionQueryWhere
    on QueryBuilder<LocalTransaction, LocalTransaction, QWhereClause> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  storeIdEqualTo(String storeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'storeId', value: [storeId]),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  storeIdNotEqualTo(String storeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'storeId',
                lower: [],
                upper: [storeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'storeId',
                lower: [storeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'storeId',
                lower: [storeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'storeId',
                lower: [],
                upper: [storeId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  isSyncedEqualTo(bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isSynced', value: [isSynced]),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterWhereClause>
  isSyncedNotEqualTo(bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isSynced',
                lower: [],
                upper: [isSynced],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isSynced',
                lower: [isSynced],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isSynced',
                lower: [isSynced],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isSynced',
                lower: [],
                upper: [isSynced],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalTransactionQueryFilter
    on QueryBuilder<LocalTransaction, LocalTransaction, QFilterCondition> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashReceivedEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cashReceived',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashReceivedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cashReceived',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashReceivedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cashReceived',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashReceivedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cashReceived',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cashierId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cashierId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cashierId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cashierId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  cashierIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cashierId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  changeEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'change',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  changeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'change',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  changeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'change',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  changeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'change',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSynced', value: value),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentMethod',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paymentMethod',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paymentMethod',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  paymentMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paymentMethod', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'storeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'storeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'storeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'storeId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  storeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'storeId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'supabaseId'),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'supabaseId'),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'supabaseId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'supabaseId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'supabaseId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'supabaseId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  supabaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'supabaseId', value: ''),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  totalAmountEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalAmount',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalAmount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }
}

extension LocalTransactionQueryObject
    on QueryBuilder<LocalTransaction, LocalTransaction, QFilterCondition> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterFilterCondition>
  itemsElement(FilterQuery<LocalTransactionItemData> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

extension LocalTransactionQueryLinks
    on QueryBuilder<LocalTransaction, LocalTransaction, QFilterCondition> {}

extension LocalTransactionQuerySortBy
    on QueryBuilder<LocalTransaction, LocalTransaction, QSortBy> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCashReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashReceived', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCashReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashReceived', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCashierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCashierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByStoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByStoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortBySupabaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabaseId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortBySupabaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabaseId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  sortByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }
}

extension LocalTransactionQuerySortThenBy
    on QueryBuilder<LocalTransaction, LocalTransaction, QSortThenBy> {
  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCashReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashReceived', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCashReceivedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashReceived', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCashierId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCashierIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashierId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByChangeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'change', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByStoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByStoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenBySupabaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabaseId', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenBySupabaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabaseId', Sort.desc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.asc);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QAfterSortBy>
  thenByTotalAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAmount', Sort.desc);
    });
  }
}

extension LocalTransactionQueryWhereDistinct
    on QueryBuilder<LocalTransaction, LocalTransaction, QDistinct> {
  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByCashReceived() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashReceived');
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByCashierId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashierId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByChange() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'change');
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByPaymentMethod({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'paymentMethod',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByStoreId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctBySupabaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supabaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalTransaction, LocalTransaction, QDistinct>
  distinctByTotalAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAmount');
    });
  }
}

extension LocalTransactionQueryProperty
    on QueryBuilder<LocalTransaction, LocalTransaction, QQueryProperty> {
  QueryBuilder<LocalTransaction, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalTransaction, double, QQueryOperations>
  cashReceivedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashReceived');
    });
  }

  QueryBuilder<LocalTransaction, String, QQueryOperations> cashierIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashierId');
    });
  }

  QueryBuilder<LocalTransaction, double, QQueryOperations> changeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'change');
    });
  }

  QueryBuilder<LocalTransaction, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LocalTransaction, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<
    LocalTransaction,
    List<LocalTransactionItemData>,
    QQueryOperations
  >
  itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<LocalTransaction, String, QQueryOperations>
  paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<LocalTransaction, String, QQueryOperations> storeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storeId');
    });
  }

  QueryBuilder<LocalTransaction, String?, QQueryOperations>
  supabaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supabaseId');
    });
  }

  QueryBuilder<LocalTransaction, double, QQueryOperations>
  totalAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAmount');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const LocalTransactionItemDataSchema = Schema(
  name: r'LocalTransactionItemData',
  id: 8327423631315254272,
  properties: {
    r'name': PropertySchema(id: 0, name: r'name', type: IsarType.string),
    r'notes': PropertySchema(id: 1, name: r'notes', type: IsarType.string),
    r'productId': PropertySchema(
      id: 2,
      name: r'productId',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(id: 3, name: r'quantity', type: IsarType.long),
    r'selectedOptionsJson': PropertySchema(
      id: 4,
      name: r'selectedOptionsJson',
      type: IsarType.string,
    ),
    r'totalPrice': PropertySchema(
      id: 5,
      name: r'totalPrice',
      type: IsarType.double,
    ),
    r'unitPrice': PropertySchema(
      id: 6,
      name: r'unitPrice',
      type: IsarType.double,
    ),
  },
  estimateSize: _localTransactionItemDataEstimateSize,
  serialize: _localTransactionItemDataSerialize,
  deserialize: _localTransactionItemDataDeserialize,
  deserializeProp: _localTransactionItemDataDeserializeProp,
);

int _localTransactionItemDataEstimateSize(
  LocalTransactionItemData object,
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
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.productId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedOptionsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _localTransactionItemDataSerialize(
  LocalTransactionItemData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.name);
  writer.writeString(offsets[1], object.notes);
  writer.writeString(offsets[2], object.productId);
  writer.writeLong(offsets[3], object.quantity);
  writer.writeString(offsets[4], object.selectedOptionsJson);
  writer.writeDouble(offsets[5], object.totalPrice);
  writer.writeDouble(offsets[6], object.unitPrice);
}

LocalTransactionItemData _localTransactionItemDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalTransactionItemData();
  object.name = reader.readStringOrNull(offsets[0]);
  object.notes = reader.readStringOrNull(offsets[1]);
  object.productId = reader.readStringOrNull(offsets[2]);
  object.quantity = reader.readLongOrNull(offsets[3]);
  object.selectedOptionsJson = reader.readStringOrNull(offsets[4]);
  object.totalPrice = reader.readDoubleOrNull(offsets[5]);
  object.unitPrice = reader.readDoubleOrNull(offsets[6]);
  return object;
}

P _localTransactionItemDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension LocalTransactionItemDataQueryFilter
    on
        QueryBuilder<
          LocalTransactionItemData,
          LocalTransactionItemData,
          QFilterCondition
        > {
  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'name'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'name'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameGreaterThan(
    String? value, {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameLessThan(
    String? value, {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'notes'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'notes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'notes',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'notes',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'notes', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'productId'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'productId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'productId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'productId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'quantity'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'quantity'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantity', value: value),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantity',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  quantityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'selectedOptionsJson'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'selectedOptionsJson'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'selectedOptionsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'selectedOptionsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'selectedOptionsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'selectedOptionsJson', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  selectedOptionsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'selectedOptionsJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'totalPrice'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'totalPrice'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'totalPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  totalPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'unitPrice'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'unitPrice'),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'unitPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unitPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unitPrice',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    LocalTransactionItemData,
    LocalTransactionItemData,
    QAfterFilterCondition
  >
  unitPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unitPrice',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }
}

extension LocalTransactionItemDataQueryObject
    on
        QueryBuilder<
          LocalTransactionItemData,
          LocalTransactionItemData,
          QFilterCondition
        > {}
