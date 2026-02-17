# راهنمای نوتیفیکیشن‌های دسکتاپ - Desktop Notifications Guide

## 🎯 هدف

این راهنما نحوه استفاده از نوتیفیکیشن‌های دسکتاپ در پکیج `notification_master` را با استفاده از `local_notifier` توضیح می‌دهد.

---

## 📋 فهرست مطالب

1. [نصب و راه‌اندازی](#نصب-و-راه‌اندازی)
2. [پلتفرم‌های پشتیبانی شده](#پلتفرمهای-پشتیبانی-شده)
3. [نحوه استفاده](#نحوه-استفاده)
4. [مثال‌های کاربردی](#مثالهای-کاربردی)
5. [محدودیت‌ها و نکات](#محدودیتها-و-نکات)
6. [سوالات متداول](#سوالات-متداول)

---

## نصب و راه‌اندازی

### 1. اضافه کردن وابستگی

به فایل `pubspec.yaml` اضافه کنید:

```yaml
dependencies:
  notification_master: ^0.0.3
  local_notifier: ^0.1.6  # برای دسکتاپ
```

### 2. نصب نیازمندی‌های سیستم

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install libnotify-dev
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install libnotify-devel
```

#### Linux (Arch)
```bash
sudo pacman -S libnotify
```

#### macOS
بدون نیازمندی اضافی - از سیستم بومی macOS استفاده می‌کند

#### Windows
بدون نیازمندی اضافی - از Windows Toast Notifications استفاده می‌کند

### 3. راه‌اندازی در کد

```dart
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی نوتیفیکیشن‌های دسکتاپ
  await localNotifier.setup(
    appName: 'notification_master_example',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
  
  runApp(MyApp());
}
```

---

## پلتفرم‌های پشتیبانی شده

| پلتفرم | وضعیت | سیستم نوتیفیکیشن | کاستومایز UI |
|--------|-------|------------------|---------------|
| 🐧 Linux | ✅ کامل | libnotify | محدود (تم سیستم) |
| 🍎 macOS | ✅ کامل | Notification Center | محدود (تم سیستم) |
| 🪟 Windows | ✅ کامل | Toast Notifications | محدود (تم سیستم) |
| 🤖 Android | ➖ | از notification_master | کامل |
| 🍏 iOS | ➖ | از notification_master | کامل |
| 🌐 Web | ➖ | از notification_master | محدود |

---

## نحوه استفاده

### نوتیفیکیشن ساده

```dart
LocalNotification notification = LocalNotification(
  title: 'عنوان نوتیفیکیشن',
  body: 'متن اصلی نوتیفیکیشن',
);

// نمایش نوتیفیکیشن
await notification.show();
```

### نوتیفیکیشن با زیرعنوان (فقط macOS)

```dart
LocalNotification notification = LocalNotification(
  title: 'پیام جدید',
  subtitle: 'از احمد رضایی',
  body: 'سلام! چطوری؟',
);

await notification.show();
```

### نوتیفیکیشن بی‌صدا

```dart
LocalNotification notification = LocalNotification(
  title: 'نوتیفیکیشن بی‌صدا',
  body: 'این نوتیفیکیشن صدا ندارد',
  silent: true,
);

await notification.show();
```

### نوتیفیکیشن با دکمه‌های اکشن

```dart
LocalNotification notification = LocalNotification(
  title: 'درخواست تایید',
  body: 'آیا می‌خواهید ادامه دهید؟',
  actions: [
    LocalNotificationAction(text: 'بله'),
    LocalNotificationAction(text: 'خیر'),
    LocalNotificationAction(text: 'بعداً'),
  ],
);

// مدیریت کلیک روی دکمه‌ها
notification.onClickAction = (actionIndex) {
  switch (actionIndex) {
    case 0:
      print('کاربر بله را انتخاب کرد');
      break;
    case 1:
      print('کاربر خیر را انتخاب کرد');
      break;
    case 2:
      print('کاربر بعداً را انتخاب کرد');
      break;
  }
};

await notification.show();
```

### مدیریت رویدادهای نوتیفیکیشن

```dart
LocalNotification notification = LocalNotification(
  title: 'نوتیفیکیشن با رویدادها',
  body: 'این نوتیفیکیشن رویدادها را مدیریت می‌کند',
);

// زمانی که نوتیفیکیشن نمایش داده می‌شود
notification.onShow = () {
  print('نوتیفیکیشن نمایش داده شد');
};

// زمانی که روی نوتیفیکیشن کلیک می‌شود
notification.onClick = () {
  print('روی نوتیفیکیشن کلیک شد');
  // می‌توانید به صفحه خاصی navigate کنید
};

// زمانی که نوتیفیکیشن بسته می‌شود
notification.onClose = (closeReason) {
  switch (closeReason) {
    case LocalNotificationCloseReason.userCanceled:
      print('کاربر نوتیفیکیشن را بست');
      break;
    case LocalNotificationCloseReason.timedOut:
      print('نوتیفیکیشن به صورت خودکار بسته شد');
      break;
    case LocalNotificationCloseReason.unknown:
      print('دلیل بسته شدن نامشخص است');
      break;
  }
};

await notification.show();
```

### بستن نوتیفیکیشن به صورت دستی

```dart
LocalNotification notification = LocalNotification(
  identifier: 'my_notification_id',
  title: 'نوتیفیکیشن',
  body: 'این نوتیفیکیشن را می‌توان بست',
);

await notification.show();

// بستن نوتیفیکیشن بعد از 5 ثانیه
await Future.delayed(Duration(seconds: 5));
await notification.close();
```

### حذف کامل نوتیفیکیشن

```dart
LocalNotification notification = LocalNotification(
  title: 'نوتیفیکیشن',
  body: 'این نوتیفیکیشن حذف خواهد شد',
);

await notification.show();

// حذف کامل نوتیفیکیشن (بستن + پاک کردن از حافظه)
await notification.destroy();
```

---

## مثال‌های کاربردی

### 1. سیستم پیام‌رسانی

```dart
class MessageNotificationService {
  static Future<void> showNewMessage({
    required String senderName,
    required String message,
  }) async {
    LocalNotification notification = LocalNotification(
      title: 'پیام جدید',
      subtitle: 'از $senderName',
      body: message,
      actions: [
        LocalNotificationAction(text: 'پاسخ'),
        LocalNotificationAction(text: 'نادیده بگیر'),
      ],
    );

    notification.onClick = () {
      // باز کردن صفحه چت
      print('Opening chat with $senderName');
    };

    notification.onClickAction = (actionIndex) {
      if (actionIndex == 0) {
        // باز کردن صفحه پاسخ
        print('Opening reply to $senderName');
      } else {
        // نادیده گرفتن پیام
        print('Message ignored');
      }
    };

    await notification.show();
  }
}

// استفاده:
await MessageNotificationService.showNewMessage(
  senderName: 'احمد رضایی',
  message: 'سلام! چطوری؟',
);
```

### 2. یادآوری وظایف

```dart
class TaskReminderService {
  static Future<void> showTaskReminder({
    required String taskTitle,
    required String taskDescription,
    required DateTime dueTime,
  }) async {
    LocalNotification notification = LocalNotification(
      title: '⏰ یادآوری وظیفه',
      subtitle: taskTitle,
      body: '$taskDescription\nموعد: ${dueTime.toString()}',
      actions: [
        LocalNotificationAction(text: 'انجام شد'),
        LocalNotificationAction(text: 'یادآوری بعدی'),
        LocalNotificationAction(text: 'حذف'),
      ],
    );

    notification.onClickAction = (actionIndex) {
      switch (actionIndex) {
        case 0:
          print('Task marked as completed');
          break;
        case 1:
          print('Snooze for 10 minutes');
          break;
        case 2:
          print('Task deleted');
          break;
      }
    };

    await notification.show();
  }
}
```

### 3. اعلان‌های سیستمی

```dart
class SystemNotificationService {
  static Future<void> showUpdateAvailable({
    required String version,
    required String changelog,
  }) async {
    LocalNotification notification = LocalNotification(
      title: '🔄 به‌روزرسانی جدید',
      subtitle: 'نسخه $version',
      body: changelog,
      actions: [
        LocalNotificationAction(text: 'دانلود'),
        LocalNotificationAction(text: 'بعداً'),
      ],
    );

    notification.onClickAction = (actionIndex) {
      if (actionIndex == 0) {
        print('Starting download...');
      }
    };

    await notification.show();
  }

  static Future<void> showDownloadComplete({
    required String fileName,
  }) async {
    LocalNotification notification = LocalNotification(
      title: '✅ دانلود کامل شد',
      body: 'فایل $fileName با موفقیت دانلود شد',
      actions: [
        LocalNotificationAction(text: 'باز کردن'),
        LocalNotificationAction(text: 'نمایش در پوشه'),
      ],
    );

    await notification.show();
  }
}
```

### 4. نوتیفیکیشن‌های چندگانه

```dart
class BatchNotificationService {
  static Future<void> showMultipleNotifications({
    required List<Map<String, String>> notifications,
  }) async {
    for (var i = 0; i < notifications.length; i++) {
      LocalNotification notification = LocalNotification(
        identifier: 'batch_notification_$i',
        title: notifications[i]['title'] ?? '',
        body: notifications[i]['body'] ?? '',
      );

      await notification.show();
      
      // تاخیر کوتاه بین نوتیفیکیشن‌ها
      if (i < notifications.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }
}

// استفاده:
await BatchNotificationService.showMultipleNotifications(
  notifications: [
    {'title': 'نوتیفیکیشن 1', 'body': 'متن اول'},
    {'title': 'نوتیفیکیشن 2', 'body': 'متن دوم'},
    {'title': 'نوتیفیکیشن 3', 'body': 'متن سوم'},
  ],
);
```

---

## محدودیت‌ها و نکات

### ✅ قابلیت‌های موجود

- ✅ عنوان (title)
- ✅ متن اصلی (body)
- ✅ زیرعنوان (subtitle) - فقط macOS
- ✅ دکمه‌های اکشن (actions)
- ✅ نوتیفیکیشن بی‌صدا (silent)
- ✅ شناسه یکتا (identifier)
- ✅ رویدادهای onClick, onShow, onClose
- ✅ استفاده خودکار از تم سیستم

### ❌ محدودیت‌ها

- ❌ کاستومایز کامل UI (رنگ، فونت، لی‌اوت)
- ❌ تصویر سفارشی در نوتیفیکیشن
- ❌ انیمیشن‌های سفارشی
- ❌ ویجت‌های Flutter سفارشی
- ❌ پیشرفت بار (progress bar)
- ❌ نوتیفیکیشن‌های گروهی

### 💡 نکات مهم

1. **تم پیش‌فرض**: نوتیفیکیشن‌ها به صورت خودکار از تم سیستم عامل استفاده می‌کنند
2. **subtitle فقط در macOS**: فیلد subtitle فقط در macOS نمایش داده می‌شود
3. **closeReason فقط در Windows**: دلیل بسته شدن فقط در Windows دقیق است
4. **راه‌اندازی اولیه**: حتماً قبل از نمایش نوتیفیکیشن، `localNotifier.setup()` را فراخوانی کنید
5. **شناسه یکتا**: برای مدیریت بهتر، از identifier یکتا استفاده کنید

---

## سوالات متداول

### چگونه می‌توانم رنگ نوتیفیکیشن را تغییر دهم؟

متأسفانه امکان تغییر مستقیم رنگ وجود ندارد. نوتیفیکیشن‌ها از تم سیستم عامل استفاده می‌کنند.

### آیا می‌توانم تصویر به نوتیفیکیشن اضافه کنم؟

در حال حاضر `local_notifier` از تصویر پشتیبانی نمی‌کند. برای موبایل می‌توانید از `notification_master` استفاده کنید.

### چگونه می‌توانم نوتیفیکیشن را برای مدت طولانی نمایش دهم؟

مدت زمان نمایش نوتیفیکیشن توسط سیستم عامل کنترل می‌شود و قابل تغییر نیست.

### آیا می‌توانم صدای سفارشی برای نوتیفیکیشن تنظیم کنم؟

در حال حاضر امکان تنظیم صدای سفارشی وجود ندارد. می‌توانید از `silent: true` برای غیرفعال کردن صدا استفاده کنید.

### چگونه می‌توانم نوتیفیکیشن را در زمان خاصی نمایش دهم؟

می‌توانید از `Timer` یا `Future.delayed` استفاده کنید:

```dart
Timer(Duration(seconds: 10), () async {
  await notification.show();
});
```

### آیا می‌توانم نوتیفیکیشن را به‌روزرسانی کنم؟

بله، با استفاده از همان `identifier` می‌توانید نوتیفیکیشن را به‌روزرسانی کنید:

```dart
LocalNotification notification = LocalNotification(
  identifier: 'my_notification',
  title: 'عنوان اولیه',
  body: 'متن اولیه',
);
await notification.show();

// به‌روزرسانی
LocalNotification updatedNotification = LocalNotification(
  identifier: 'my_notification',  // همان شناسه
  title: 'عنوان جدید',
  body: 'متن جدید',
);
await updatedNotification.show();
```

---

## 🔗 منابع مفید

- [مستندات local_notifier](https://pub.dev/packages/local_notifier)
- [مستندات notification_master](https://pub.dev/packages/notification_master)
- [مثال‌های کامل در GitHub](https://github.com/swanflutter/notification_master)

---

## 📞 پشتیبانی

اگر سوال یا مشکلی دارید:

- 📧 Email: swan.dev1993@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/swanflutter/notification_master/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/swanflutter/notification_master/discussions)

---

**نکته**: این راهنما برای استفاده از نوتیفیکیشن‌های دسکتاپ در پکیج `notification_master` طراحی شده است. برای نوتیفیکیشن‌های موبایل و وب، به مستندات اصلی پکیج مراجعه کنید.
