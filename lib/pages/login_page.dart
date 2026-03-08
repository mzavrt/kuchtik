import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kuchtik/main.dart';
import 'package:pinput/pinput.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    bool _isLoading = false;
    late final TextEditingController _emailController = TextEditingController();

    Future<void> _signIn() async {
      try {
        setState(() {
          _isLoading = true;
        });
        await supabase.auth.signInWithOtp(
          email: _emailController.text.trim()
        );

        if(mounted) {
          Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: _emailController.text.trim()),
        ),
      );
        }
      }
      on AuthException catch (error) {
      //if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        //context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

    @override
    Widget build(BuildContext builder){
       return Scaffold(
        appBar: AppBar(
          title: const Text('Sign In'),
        ),
        body: ListView(
          padding:  const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          children: [
            const Text('Enter your email to sign in'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'Sending...' : 'Sign in'),
          )
          ],
        ),
       );
    }

}

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _verifyOtp(String pin) async {
    setState(() => _isLoading = true);

    try {
      // Ověření zadaného OTP kódu
      await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: pin,
      );

      //Session?
      //User?

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: "HomePage")), 
        (Route<dynamic> route) => false,);
 
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neplatný kód. Zkuste to prosím znovu.')),
      );
      }
      
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ověření e-mailu'),
        // Tlačítko zpět je přidáno automaticky díky Navigator.push, 
        // ale pro jistotu ho zde necháme zmíněné z UX hlediska.
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Zadejte 6místný kód',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // UX detail: Zobrazení e-mailu a tlačítko pro rychlou úpravu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.email, style: const TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Vrátí o krok zpět
                  child: const Text('Změnit'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // OTP Políčka
            Pinput(
              length: 6,
              autofocus: true,
              keyboardType: TextInputType.number,
              onCompleted: (pin) {
                // Auto-submit: jakmile uživatel napíše 6. číslo, ověřujeme
                _verifyOtp(pin);
              },
            ),
            
            const SizedBox(height: 32),
            if (_isLoading) const CircularProgressIndicator(),
            
            const SizedBox(height: 32),
            // Zde by ideálně byl odpočet (Timer) a po jeho vypršení tlačítko "Poslat znovu"
            TextButton(
              onPressed: () {
                // Logika pro opětovné odeslání e-mailu
              },
              child: const Text('Nedostal jsem e-mail. Poslat znovu.'),
            )
          ],
        ),
      ),
    );
  }
}