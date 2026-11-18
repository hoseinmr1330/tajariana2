# تغییرات نسخه 0.1.4

- حذف گزینه قدیمی و نامعتبر `screen/orientation` از Android Export Preset؛ جهت افقی فقط از تنظیم معتبر پروژه در `project.godot` کنترل می‌شود.
- اضافه‌شدن بررسی خودکار این مورد به تست Headless و Workflow.
- حفظ بررسی واقعی ETC2/ASTC از طریق ProjectSettings در موتور Godot، نه صرفاً جست‌وجوی متن در فایل.
- حفظ پاک‌سازی کامل cache واردسازی پیش از import مجدد تصاویر.

این نسخه هنوز باید در GitHub Actions با موتور و Android SDK واقعی کامپایل شود؛ بررسی ایستا به‌تنهایی جایگزین اجرای واقعی Godot نیست.
