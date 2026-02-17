# تحلیل پکیج local_notifier برای لینوکس و مک

## خلاصه بررسی

پکیج `local_notifier` نسخه 0.1.6 یک پکیج Flutter برای نمایش نوتیفیکیشن‌های دسکتاپ است که از **لینوکس، مک و ویندوز** پشتیبانی می‌کند.

## ✅ پشتیبانی از پلتفرم‌ها

| پلتفرم | وضعیت | توضیحات |
|--------|-------|---------|
| Linux | ✅ کامل | از libnotify استفاده می‌کند |
| macOS | ✅ کامل | از سیستم نوتیفیکیشن بومی macOS |
| Windows | ✅ کامل | از Toast Notifications |

## 🎨 قابلیت‌های کاستومایز UI

### محدودیت‌های مهم:

**❌ local_notifier اجازه کاستومایز کامل UI نوتیفیکیشن را نمی‌دهد**

این پکیج از سیستم نوتیفیکیشن بومی هر پلتفرم استفاده می‌کند، بنابراین:

1. **لینوکس**: از `libnotify` استفاده می‌کند - ظاهر نوتیفیکیشن بستگی به تم دسکتاپ محیط کاربر دارد (GNOME, KDE, XFCE و غیره)
2. **macOS**: از Notification Center بومی macOS - ظاهر مطابق با استایل سیستم macOS
3. **Windows**: از Windows Toast Notifications - ظاهر مطابق با تم ویندوز

### ✅ چیزهایی که می‌توان کاستومایز کرد:

```dart
LocalNotification notification = LocalNotification(
  identifier: 'unique_id',      // شناسه یکتا
  title: 'عنوان نوتیفیکیشن',    // عنوان
  subtitle: 'زیرعنوان',         // زیرعنوان (فقط macOS)
  body: 'متن اصلی نوتیفیکیشن',  // متن اصلی
  silent: false,                 // نوتیفیکیشن بی‌صدا
  actions: [                     // دکمه‌های اکشن
    LocalNotificationAction(
      text: 'بله',
    ),
    LocalNotificationAction(
      text: 'خیر',
    ),
  ],
);
```

### ❌ چیزهایی که نمی‌توان کاستومایز کرد:

- رنگ پس‌زمینه نوتیفیکیشن
- فونت و اندازه متن
- لی‌اوت و چیدمان المان‌ها
- انیمیشن‌های سفارشی
- ویجت‌های Flutter سفارشی

## 📋 نحوه استفاده

### نصب

```yaml
dependencies:
  local_notifier: ^0.1.6
```

### نیازمندی‌های لینوکس

```bash
sudo apt-get install libnotify-dev
```

### کد نمونه کامل

```dart
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی اولیه (فقط برای ویندوز الزامی است)
  await localNotifier.setup(
    appName: 'notification_master_example',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationDemo(),
    );
  }
}

class NotificationDemo extends StatefulWidget {
  @override
  _NotificationDemoState createState() => _NotificationDemoState();
}

class _NotificationDemoState extends State<NotificationDemo> {
  
  // نمایش نوتیفیکیشن ساده
  Future<void> showSimpleNotification() async {
    LocalNotification notification = LocalNotification(
      title: 'نوتیفیکیشن ساده',
      body: 'این یک نوتیفیکیشن تستی است',
    );
    
    // رویدادها
    notification.onShow = () {
      print('نوتیفیکیشن نمایش داده شد');
    };
    
    notification.onClick = () {
      print('روی نوتیفیکیشن کلیک شد');
    };
    
    notification.onClose = (closeReason) {
      print('نوتیفیکیشن بسته شد: $closeReason');
    };
    
    await notification.show();
  }
  
  // نوتیفیکیشن با اکشن‌ها
  Future<void> showNotificationWithActions() async {
    LocalNotification notification = LocalNotification(
      title: 'درخواست تایید',
      body: 'آیا می‌خواهید ادامه دهید؟',
      actions: [
        LocalNotificationAction(text: 'بله'),
        LocalNotificationAction(text: 'خیر'),
      ],
    );
    
    notification.onClickAction = (actionIndex) {
      if (actionIndex == 0) {
        print('کاربر بله را انتخاب کرد');
      } else {
        print('کاربر خیر را انتخاب کرد');
      }
    };
    
    await notification.show();
  }
  
  // نوتیفیکیشن بی‌صدا
  Future<void> showSilentNotification() async {
    LocalNotification notification = LocalNotification(
      title: 'نوتیفیکیشن بی‌صدا',
      body: 'این نوتیفیکیشن صدا ندارد',
      silent: true,
    );
    
    await notification.show();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نمونه local_notifier'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: showSimpleNotification,
              child: Text('نوتیفیکیشن ساده'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: showNotificationWithActions,
              child: Text('نوتیفیکیشن با اکشن'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: showSilentNotification,
              child: Text('نوتیفیکیشن بی‌صدا'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 مقایسه با notification_master

| ویژگی | local_notifier | notification_master |
|-------|----------------|---------------------|
| پشتیبانی Android | ❌ | ✅ |
| پشتیبانی iOS | ❌ | ✅ |
| پشتیبانی Web | ❌ | ✅ |
| پشتیبانی Desktop | ✅ | ✅ |
| HTTP Polling | ❌ | ✅ |
| کاستومایز UI | محدود | محدود |
| نوتیفیکیشن با تصویر | ❌ | ✅ (Android/iOS) |
| Big Text | ❌ | ✅ (Android) |

## 💡 توصیه‌ها

### برای پروژه notification_master:

1. **ادغام local_notifier**: می‌توانید local_notifier را برای پلتفرم‌های دسکتاپ به پروژه اضافه کنید
2. **استراتژی ترکیبی**: 
   - برای موبایل و وب: از کد فعلی notification_master
   - برای دسکتاپ: از local_notifier

### نمونه کد ادغام:

```dart
class NotificationMasterDesktop {
  static Future<void> showNotification({
    required String title,
    required String message,
    List<Map<String, String>>? actions,
  }) async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      // استفاده از local_notifier برای دسکتاپ
      LocalNotification notification = LocalNotification(
        title: title,
        body: message,
        actions: actions?.map((action) => 
          LocalNotificationAction(text: action['title'] ?? '')
        ).toList(),
      );
      await notification.show();
    } else {
      // استفاده از notification_master برای موبایل
      await NotificationMaster().showNotification(
        title: title,
        message: message,
      );
    }
  }
}
```

## ⚠️ نکات مهم

1. **تم پیش‌فرض**: نوتیفیکیشن‌ها به صورت خودکار از تم سیستم عامل استفاده می‌کنند
2. **محدودیت UI**: امکان کاستومایز کامل UI وجود ندارد
3. **رفتار بومی**: هر پلتفرم رفتار خاص خود را دارد
4. **subtitle فقط در macOS**: فیلد subtitle فقط در macOS کار می‌کند

## 🎯 نتیجه‌گیری

پکیج `local_notifier` برای لینوکس و مک **به خوبی کار می‌کند** اما:

- ✅ از تم پیش‌فرض سیستم عامل استفاده می‌کند (زیبا و بومی)
- ❌ امکان کاستومایز کامل UI را ندارد
- ✅ برای نوتیفیکیشن‌های ساده و استاندارد عالی است
- ❌ برای UI های پیچیده و سفارشی مناسب نیست

اگر نیاز به کاستومایز کامل UI دارید، باید از راه‌حل‌های دیگری مثل overlay window یا custom rendering استفاده کنید.
