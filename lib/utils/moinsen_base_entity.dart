import 'package:moinsen_supagen/moinsen_supagen.dart';

abstract class MoinsenBaseEntity<T> {
  static const tableName = 'moinsen_base_entity';
  static const pkKey = ['id'];

  String idName() {
    return 'id';
  }

  Object? identifier() {
    return null;
  }

  String get ztableName => tableName;

  T fromJson(Map<String, Object?> json) {
    return null as T;
  }

  Map<String, Object?> toJson() {
    return {};
  }
}

extension MoinsenSupaEntityExt<T> on MoinsenBaseEntity<T> {
  Future<dynamic> upsert() async {
    final client = Supabase.instance.client;

    final response = await client.from(ztableName).upsert(
          this.toJson(),
        );

    return response.data;
  }

  Future<void> delete() async {
    if (identifier() == null) {
      return;
    }

    final client = Supabase.instance.client;

    // ignore: unused_local_variable
    final response =
        await client.from(ztableName).delete().eq(idName(), identifier);
  }

  Future<List<T>> select([String columns = '*']) async {
    final client = Supabase.instance.client;

    final response = await client.from(ztableName).select(columns);

    return response.map(fromJson).toList();
  }

  Future<T?> selectById() async {
    if (identifier() == null) {
      return null;
    }

    final client = Supabase.instance.client;

    final response = await client
        .from(ztableName)
        .select()
        .eq(idName(), identifier)
        .single();

    return fromJson(response);
  }

  Future<void> insert() async {
    final client = Supabase.instance.client;

    await client.from(ztableName).insert(this.toJson());
  }

  Future<void> update() async {
    final client = Supabase.instance.client;

    await client.from(ztableName).update(this.toJson());
  }
}