import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo/to_do_item.dart';
import 'add_item_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

void main() => runApp(MaterialApp(home: ToDo()));

class ToDo extends StatefulWidget {
  @override
  _ToDoState createState() => _ToDoState();
}

class _ToDoState extends State<ToDo> {
  User user;
  DatabaseService database;

  void addItem(String key) {
    database.setToDo(key, false);
    Navigator.pop(context);
  }

  void deleteItem(String key) {
    database.deleteToDo(key);
  }

  void toggleDone(String key, bool value) {
    database.setToDo(key, value);
  }

  void newEntry() {
    showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AddItemDialog(addItem);
        }
    );
  }

  Future<void> connectToFirebase() async {
    await Firebase.initializeApp();
    final FirebaseAuth authenticate = FirebaseAuth.instance;
    UserCredential result = await authenticate.signInAnonymously();
    user = result.user;
    database = DatabaseService(user.uid);

    if(!(await database.checkIfUserExists())){
      database.setToDo('ToDo anlegen', false);
    }
    Stream userDocumentStream = database.getToDos();
    userDocumentStream.listen((documentSnapshot) =>
      print(documentSnapshot.data)
    );
  }

/*
 void loadState() async {
    await Future.delayed(Duration(seconds: 5), (){
      print('Connect to database');
   });
   Future.delayed(Duration(seconds: 2), (){
      print('load data1');
   });
   Future.delayed(Duration(seconds: 3), (){
      print('load data2');
   });
  }
  @override
  void initState() {
    super.initState();
    loadState();
    if(products.isEmpty){
      products['ToDo erstellen'] = false;
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do-App'),
        backgroundColor: Color.fromRGBO(35, 152, 185, 100),
      ),
      body:
      FutureBuilder(
        future: connectToFirebase(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          else{
            return StreamBuilder<DocumentSnapshot>(
              stream: database.getToDos(),
              builder: (
              context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                else {
                  Map<String, dynamic> items = snapshot.data.data();
                  return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        String key = items.keys.elementAt(i);
                        return ToDoItem(
                          key,
                          items[key],
                              () => deleteItem(key),
                              () => toggleDone(key, items[key]),
                        );
                      }
                  );
                }
              }
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: newEntry,
        child: Icon(Icons.add),
        backgroundColor: Color.fromRGBO(35, 152, 185, 100),
      ),
    );
  }

  @override
  void dispose() {
    print('I was removed');
    super.dispose();
  }

}