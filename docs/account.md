# Account API

> [!IMPORTANT]
> The Account API is supported by this SDK, but not yet available in a released version of the CoCart plugin. This documentation is ready for when it ships.

Manage the authenticated customer's profile, orders, downloads, and reviews. Access it via `client.account()`.

## Profile

```dart
// Get the authenticated user's account profile
final profile = await client.account().getProfile();

// Update profile fields
await client.account().updateProfile({
  'first_name': 'John',
  'last_name': 'Doe',
});
```

### Change Password

```dart
await client.account().changePassword(
  current: 'old-password',
  password: 'new-password',
  confirm: 'new-password',
);
```

## Orders

```dart
// List orders
final orders = await client.account().getOrders();

// Get a single order
final order = await client.account().getOrder(123);

// Get a guest order (by ID and billing email)
final guestOrder = await client.account().getGuestOrder(123, 'guest@example.com');
```

## Downloads

```dart
// Downloads for a specific order
final downloads = await client.account().getOrderDownloads(123);

// Downloads for a specific guest order
final guestDownloads =
    await client.account().getGuestOrderDownloads(123, 'guest@example.com');

// All downloads available to the authenticated user
final allDownloads = await client.account().getDownloads();
```

## Reviews

```dart
final reviews = await client.account().getReviews();
```
