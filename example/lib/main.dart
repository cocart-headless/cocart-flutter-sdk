import 'package:cocart/cocart.dart';

void main() async {
  // --- Guest — simplest setup ---
  final client = CoCart('https://your-store.com');

  // Restore previous session (call once on app start)
  await client.restoreSession();

  // Browse products
  final products = await client.products().all({'per_page': '12'});
  print('Products: ${products.toJson()}');

  // Add to cart — cart key captured automatically
  await client.cart().addItem(123, 2);
  print('Cart key: ${client.getCartKey()}');

  // Dot-notation response access
  final cart = await client.cart().get();
  print('Total: ${cart.get('totals.total')}');
  print('First item: ${cart.get('items.0.name')}');

  // --- Authenticated customer (Basic Auth) ---
  final authClient = CoCart(
    'https://your-store.com',
    CoCartOptions(username: 'email@example.com', password: 'pass'),
  );
  print('Authenticated: ${authClient.isAuthenticated()}');

  // --- JWT Auth ---
  final jwtClient = CoCart('https://your-store.com');
  await jwtClient.login('email@example.com', 'password');
  await jwtClient.cart().get();

  // --- Fluent config ---
  final client2 = CoCart.create('https://your-store.com')
      .setTimeout(15000)
      .setMaxRetries(2)
      .setAuthHeaderName('X-Auth-Token')
      .addHeader('X-Custom', 'value');
  print('Client2 created: ${client2.siteUrl}');

  // --- Currency formatting ---
  final fmt = CurrencyFormatter();
  final cart2 = await client.cart().get();
  final currency = cart2.getCurrency();
  if (currency != null) {
    print(fmt.format(4599, currency)); // "$45.99"
  }

  // --- Events ---
  client.on('request', (e) => print('${e['method']} ${e['url']}'));
  client.on('response', (e) => print('${e['status']} in ${e['duration']}ms'));
  client.on('error', (e) => print(e['error']));

  // Cleanup
  client.close();
}
