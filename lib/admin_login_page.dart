import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and Password are required!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth හරහා ලොග් වීම
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Firebase එකෙන් ඇඩ්මින් අවසර තියෙනවද කියලා චෙක් කිරීම
      // 💡 ඔයාගේ Database එකේ ඇඩ්මින්ලව සේව් කරලා තියෙන Collection එක 'admins' කියලා මෙතන හිතලා තියෙන්නේ.
      // ඒක වෙනස් නම් මෙතන 'admins' වෙනුවට අදාල නම දෙන්න.
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (adminDoc.exists) {
        // ✅ ඇඩ්මින් අවසර තියෙනවා නම් විතරක් ඇතුලට අරගෙන Home Page එකට (Dashboard එකට) යනවා.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Login Successful!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // 🚫 ඇඩ්මින් කෙනෙක් නෙමෙයි නම් ලොගවුට් කරලා එලියට දානවා
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚫 Access Denied! You don't have admin permissions."), backgroundColor: Colors.red),
        );
      }
    } on FirebaseAuthException catch (e) {
      // ❌ පාස්වර්ඩ් වැරදි නම් හරි, එකවුන්ට් එකක් නැත්නම් හරි පෙන්නන Error එක
      String errorMessage = "Login Failed";
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = "No admin found for that email.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "Wrong password provided.";
      } else {
        errorMessage = e.message ?? "An error occurred.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $errorMessage"), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🛡️ Admin Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ]
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Admin Portal",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Enter your credentials to access the dashboard",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // 📝 Login Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 10))
                      ]
                  ),
                  child: Column(
                    children: [
                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Admin Email",
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            shadowColor: Colors.blue.withValues(alpha: 0.5),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("SECURE LOGIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Text("© 2026 AIAPRTD. All rights reserved.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}