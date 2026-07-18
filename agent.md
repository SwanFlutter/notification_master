Prompt for AI:

فارسی:
من یک پلاگین نوتیفیکیشن دارم که فقط در پلتفرم ویندوز پیاده‌سازی شده است. لطفاً این ویژگی‌ها و رفتارهای موجود را بررسی کن و برای من مشابه آن‌ها را در سایر پلتفرم‌ها (Android، iOS، macOS، Linux و هر پلتفرم دیگر لازم) پیشنهاد بده و طراحی کن.


• نوتیفیکیشن heads-up یا alarm-style با صدا و مدت طولانی
• نوتیفیکیشن full-screen / incoming-call style
• زمان‌بندی نوتیفیکیشن: OS-level scheduled notifications و fallback داخلی در صورت نیاز
• سرویس پس‌زمینه polling: فرآیند/daemon جداگانه که HTTP می‌خواند و حتی وقتی اپ بسته است نوتیفیکیشن نمایش می‌دهد
• ذخیره پیکربندی در رجیستری ویندوز برای daemon و اپلیکیشن
• کانال‌های موضوعی (topic subscription): subscribe/unsubscribe/getSubscribedTopics
• دریافت توکن دستگاه با شناسه یکتا از ماشین
• بررسی و اجازه نوتیفیکیشن برای ویندوز به صورت همیشگی true (بدون permission خاص)


Also mention platform-specific implementation notes such as:
- using AppUserModelId / AUMI and toast registration on Windows
- handling native notification APIs on each platform

