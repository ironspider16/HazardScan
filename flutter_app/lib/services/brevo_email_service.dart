import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> sendEmailViaFunction() async {
  final supabase = Supabase.instance.client;

  try {
    // Invoke the edge function securely
    final response = await supabase.functions.invoke(
      'send-email',
      body: {
        'to': 'recipient@example.com',
        'subject': 'Hello from Flutter',
        'body': '<p>This email was sent via a secure edge function.</p>',
      },
    );

    if (response.status == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.data}");
    }
  } catch (e) {
    print("Error calling function: $e");
  }
}