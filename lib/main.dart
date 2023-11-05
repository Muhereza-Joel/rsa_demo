import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pointycastle/export.dart' as pointyexport;

final TextEditingController decryptedTextController = TextEditingController();
final TextEditingController controller = TextEditingController();
final TextEditingController encryptedTextController = TextEditingController();

const storage = FlutterSecureStorage();

Future<void> generateAndStoreKeys() async {
  final rsaKeyHelper = RsaKeyHelper();
  final rsaKeyPair =
      await rsaKeyHelper.computeRSAKeyPair(rsaKeyHelper.getSecureRandom());

  final publicKey = rsaKeyPair.publicKey as pointyexport.RSAPublicKey;
  final privateKey = rsaKeyPair.privateKey as pointyexport.RSAPrivateKey;

  final publicKeyPEM = rsaKeyHelper.encodePublicKeyToPemPKCS1(publicKey);
  final privateKeyPEM = rsaKeyHelper.encodePrivateKeyToPemPKCS1(privateKey);

  await storage.write(key: 'publicKey', value: publicKeyPEM);
  await storage.write(key: 'privateKey', value: privateKeyPEM);
}



Future<pointyexport.RSAPublicKey?> getPublicKey() async {
  final publicKeyPEM = await storage.read(key: 'publicKey');
  if (publicKeyPEM != null) {
    return RsaKeyHelper().parsePublicKeyFromPem(publicKeyPEM);
  }
  return null;
}

Future<pointyexport.RSAPrivateKey?> getPrivateKey() async {
  final privateKeyPEM = await storage.read(key: 'privateKey');
  if (privateKeyPEM != null) {
    return RsaKeyHelper().parsePrivateKeyFromPem(privateKeyPEM);
  }
  return null;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encryption App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Encryption App Using RSA'),
          centerTitle: false,
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextEntryWidgetEncryptMessage(),
              TextArea()
            ],
          ),
        ),
      ),
    );
  }
}

class TextEntryWidgetEncryptMessage extends StatefulWidget {
  const TextEntryWidgetEncryptMessage({super.key});

  @override
  _TextEntryWidgetEncryptMessageState createState() =>
      _TextEntryWidgetEncryptMessageState();
}

class _TextEntryWidgetEncryptMessageState
    extends State<TextEntryWidgetEncryptMessage> {


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter message to encrypt',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
              onPressed: () async {
                // Encrypt the text here and update the TextArea
                final messageToEncrypt = controller.text;
                final publicKey = await getPublicKey();
                final privateKey = await getPrivateKey();

                if (privateKey == null || publicKey == null) {
                  Fluttertoast.showToast(
                      msg: 'keys not found. Please generate keys first.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.red
                  );
                  return;
                }

                if(messageToEncrypt == ""){
                  Fluttertoast.showToast(
                      msg: 'Please Enter a message to encrypt',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      backgroundColor: Colors.red
                  );
                  return;
                }

                final encrypter = Encrypter(
                    RSA(publicKey: publicKey, privateKey: privateKey));

                final encryptedMessage = encrypter.encrypt(messageToEncrypt);

                encryptedTextController.text = encryptedMessage.base64;

                Fluttertoast.showToast(
                  msg: 'Message Encrypted Successfully',
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.black,
                  textColor: Colors.white, //
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Click To Encrypt The Message')),
          const SizedBox(height: 16.0),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: encryptedTextController,
                maxLines: 4,
                enabled: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
              onPressed: () async {
                // Decrypt the text here and update the TextArea
                String encryptedText = encryptedTextController.text;
                if(encryptedText == ""){
                  Fluttertoast.showToast(
                      msg: 'Please Enter a message to encrypt',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.TOP,
                      backgroundColor: Colors.red
                  );
                  return;
                }

                final privateKey = await getPrivateKey();

                if (privateKey == null) {
                  Fluttertoast.showToast(
                    msg: 'Private key not found. Please generate keys first.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    backgroundColor: Colors.red
                  );
                return;
                }

                final decrypter = Encrypter(RSA(privateKey: privateKey));
                final decryptedMessage = decrypter.decrypt(Encrypted.fromBase64(encryptedText));
                
                decryptedTextController.text = decryptedMessage;

                Fluttertoast.showToast(
                  msg: 'Message Decrypted Successfully',
                  gravity: ToastGravity.TOP,
                  backgroundColor: Colors.black,
                  textColor: Colors.white, //
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Click To Decrypt The Message')
          ),

        ],
      ),
    );
    
  }

}

class TextArea extends StatelessWidget {
  const TextArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: decryptedTextController,
                  maxLines: 4,
                  enabled: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await generateAndStoreKeys();

                      // Display a toast message to indicate that keys were generated
                      Fluttertoast.showToast(
                        msg: 'Keys were generated and stored',
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.black,
                        textColor: Colors.white, //
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('Generate And Store Keys')
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Call the resetTextFields function to clear text fields
                    resetTextFields();
                  },
                  child: const Text('Reset'),
                ),

              ],
            ),
          ],
        )
    );
  }
  void resetTextFields(){
    controller.text = '';
    encryptedTextController.text = '';
    decryptedTextController.text = '';
  }
}
