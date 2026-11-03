import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

class RecipeRepository {
  RecipeRepository(this.uid, {FirebaseFirestore? database})
    : db = database ?? FirebaseFirestore.instance;
  final String uid;
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get collection =>
      db.collection('recipes');
  Stream<List<Recipe>> watch() => collection
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Recipe.fromMap(d.data())).toList());
  Future<void> save(Recipe recipe, {Recipe? previous}) async {
    final target = collection.doc(recipe.id);
    // Returning an outcome avoids native SDKs replacing callback exceptions
    // with an opaque "unknown" error. All conflict reads remain transactional.
    final failure = await db.runTransaction<String?>((tx) async {
      final exists = await tx.get(target);
      if ((previous == null || previous.id != recipe.id) && exists.exists) {
        return 'already-exists';
      }
      if (previous != null) {
        final old = previous.id == recipe.id
            ? exists
            : await tx.get(collection.doc(previous.id));
        if (!old.exists) {
          return 'not-found';
        }
        final data = recipe.toMap();
        data['favorite'] = old.data()!['favorite'];
        data['createdAt'] = old.data()!['createdAt'];
        if (previous.id != recipe.id) tx.delete(collection.doc(previous.id));
        tx.set(target, data);
      } else {
        tx.set(target, recipe.toMap());
      }
      return null;
    });
    if (failure != null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: failure,
        message: failure == 'already-exists'
            ? 'A recipe with this name already exists.'
            : 'This recipe no longer exists.',
      );
    }
  }

  Future<void> favorite(Recipe r) =>
      collection.doc(r.id).update({'favorite': !r.favorite});
  Future<void> delete(Recipe r) => collection.doc(r.id).delete();
}

String backendMessage(Object error) => error is FirebaseException
    ? (error.message ?? error.code)
    : error.toString();
