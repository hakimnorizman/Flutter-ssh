//MUHAMMAD NUR HAKIM BIN NORIZMAN
//CS245
//2017283278
//FYP PROJECT TEST1

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:ssh/ssh.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = '';
  List _array;

  Future<void> onClickCmd() async {
    var client = new SSHClient(
      host: "192.168.8.102",
      port: 22,
      username: "admin",
      passwordOrKey: "pfsense",
    );

    String result;
    try {
      result = await client.connect();
      if (result == "session_connected") result = await client.execute("ls");
      client.disconnect();
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }

    setState(() {
      _result = result;
      _array = null;
    });
  }

//private key tak boleh guna for now
  Future<void> onClickShell() async {
    var client = new SSHClient(
      host: "192.168.8.102",
      port: 22,
      username: "hakim",
      passwordOrKey: {
        "privateKey": """-----BEGIN RSA PRIVATE KEY-----
AAAAB3NzaC1yc2EAAAABJQAAAQEA3WoHFYtAv/pgA0VRxsroIy4VzRK0+SGRvCNh
MwMvuLHLVkrNPnKW0HyPup8ygxFXXIsREM5ZzsiIh0qe3NwX82oT3HMyt+Ef4Aej
rk+QW/PBLbDERZ36EaLd+8pFLn2MxM6p1asGVrwgAUmndoyYDmUJba38xGKU/+EC
ZMpVYn3eV+/IvuwX+m5TMvQyNeug1VXRGpoHi7EjCKnET1xG0QKX0gHtUXKlAGAT
9esidEnOMvv5L52BMxkRvyUrgd6IO3FmCaiRKFc0T12ZdGh5RemdztcGB3rgcqvS
VhpY85fOcDVFBQTvnxKpgxKJccXusVyhJ1hMxB9wZU9dogAk6w==
-----END RSA PRIVATE KEY-----""",
      },
    );

    setState(() {
      _result = "";
      _array = null;
    });

    try {
      String result = await client.connect();
      if (result == "session_connected") {
        result = await client.startShell(
            ptyType: "xterm",
            callback: (dynamic res) {
              setState(() {
                _result += res;
              });
            });

        if (result == "shell_started") {
          print(await client.writeToShell("echo hello > world\n"));
          print(await client.writeToShell("cat world\n"));
          new Future.delayed(
            const Duration(seconds: 5),
            () async => await client.closeShell(),
          );
        }
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  Future<void> onClickSFTP() async {
    var client = new SSHClient(
      host: "192.168.8.102",
      port: 22,
      username: "admin",
      passwordOrKey: "pfsense",
    );

    try {
      String result = await client.connect();
      if (result == "session_connected") {
        result = await client.connectSFTP();
        if (result == "sftp_connected") {
          var array = await client.sftpLs();
          setState(() {
            _result = result;
            _array = array;
          });

          print(await client.sftpMkdir("testsftp"));
          print(await client.sftpRename(
            oldPath: "testsftp",
            newPath: "testsftprename",
          ));
          print(await client.sftpRmdir("testsftprename"));

          Directory tempDir = await getTemporaryDirectory();
          String tempPath = tempDir.path;
          var filePath = await client.sftpDownload(
            path: "testupload",
            toPath: tempPath,
            callback: (progress) async {
              print(progress);
              // if (progress == 20) await client.sftpCancelDownload();
            },
          );

          print(await client.sftpRm("testupload"));

          print(await client.sftpUpload(
            path: filePath,
            toPath: ".",
            callback: (progress) async {
              print(progress);
              // if (progress == 30) await client.sftpCancelUpload();
            },
          ));

          print(await client.disconnectSFTP());

          client.disconnect();
        }
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget renderButtons() {
      return ButtonTheme(
        padding: EdgeInsets.all(5.0),
        child: ButtonBar(
          children: <Widget>[
            FlatButton(
              child: Text(
                'Test command',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickCmd,
              color: Colors.blue,
            ),
            FlatButton(
              child: Text(
                'Test shell',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickShell,
              color: Colors.blue,
            ),
            FlatButton(
              child: Text(
                'Test SFTP',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickSFTP,
              color: Colors.blue,
            ),
          ],
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ssh plugin example app'),
        ),
        body: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(15.0),
          children: <Widget>[
            Text(
                "Please edit the connection setting in the source code before clicking the test buttons"),
            renderButtons(),
            Text(_result),
            _array != null && _array.length > 0
                ? Column(
                    children: _array.map((f) {
                      return Text(
                          "${f["filename"]} ${f["isDirectory"]} ${f["modificationDate"]} ${f["lastAccess"]} ${f["fileSize"]} ${f["ownerUserID"]} ${f["ownerGroupID"]} ${f["permissions"]} ${f["flags"]}");
                    }).toList(),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
