//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/ligne_registre.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'registre_transactions.g.dart';

/// Le registre, avec son total.
///
/// Properties:
/// * [totalRegleUnites] - Somme des montants **réglés** de la sélection — ce que le fournisseur doit avoir encaissé.
/// * [transactions] - Lignes, la plus récente d'abord.
@BuiltValue()
abstract class RegistreTransactions implements Built<RegistreTransactions, RegistreTransactionsBuilder> {
  /// Somme des montants **réglés** de la sélection — ce que le fournisseur doit avoir encaissé.
  @BuiltValueField(wireName: r'total_regle_unites')
  int get totalRegleUnites;

  /// Lignes, la plus récente d'abord.
  @BuiltValueField(wireName: r'transactions')
  BuiltList<LigneRegistre> get transactions;

  RegistreTransactions._();

  factory RegistreTransactions([void updates(RegistreTransactionsBuilder b)]) = _$RegistreTransactions;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegistreTransactionsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegistreTransactions> get serializer => _$RegistreTransactionsSerializer();
}

class _$RegistreTransactionsSerializer implements PrimitiveSerializer<RegistreTransactions> {
  @override
  final Iterable<Type> types = const [RegistreTransactions, _$RegistreTransactions];

  @override
  final String wireName = r'RegistreTransactions';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegistreTransactions object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'total_regle_unites';
    yield serializers.serialize(
      object.totalRegleUnites,
      specifiedType: const FullType(int),
    );
    yield r'transactions';
    yield serializers.serialize(
      object.transactions,
      specifiedType: const FullType(BuiltList, [FullType(LigneRegistre)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegistreTransactions object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegistreTransactionsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'total_regle_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalRegleUnites = valueDes;
          break;
        case r'transactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneRegistre)]),
          ) as BuiltList<LigneRegistre>;
          result.transactions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegistreTransactions deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegistreTransactionsBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

