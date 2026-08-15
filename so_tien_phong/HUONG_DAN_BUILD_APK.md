# Hướng dẫn build app "Sổ tiền phòng" ra file APK

App Flutter ghi sổ tiền điện / tiền phòng / tiền quản lý hàng tháng.
Dữ liệu lưu offline bằng SQLite ngay trên điện thoại.

---

## 0. Tóm tắt 6 dòng lệnh (nếu bạn đã có Flutter)

```bash
flutter create --org com.example --project-name so_tien_phong so_tien_phong
# chép lib/, pubspec.yaml, analysis_options.yaml từ bộ code vào thư mục so_tien_phong (ghi đè)
# chép android_config/AndroidManifest.xml đè lên android/app/src/main/AndroidManifest.xml
# sửa android/app/build.gradle theo android_config/build.gradle.snippet.txt
cd so_tien_phong
flutter pub get
flutter build apk --release
```

File APK nằm ở: `build/app/outputs/flutter-apk/app-release.apk`

Phần dưới là hướng dẫn chi tiết từng bước cho người chưa từng cài Flutter.

---

## 1. Chuẩn bị máy tính

| Thứ cần cài | Ghi chú |
|---|---|
| **Flutter SDK** | Nên dùng bản **3.24 → 3.32** (bộ code này viết cho các bản đó) |
| **Android Studio** | Để lấy Android SDK + công cụ build |
| **Java JDK 17** | Android Studio thường cài sẵn |
| Ổ cứng trống | Khoảng 15 GB |

### 1.1. Cài Flutter

**Windows**

1. Tải Flutter SDK tại <https://docs.flutter.dev/get-started/install/windows>
2. Giải nén vào `C:\src\flutter` (đừng để trong `C:\Program Files`, có dấu cách sẽ lỗi)
3. Thêm `C:\src\flutter\bin` vào biến môi trường `Path`
4. Mở **PowerShell mới**, gõ `flutter --version` để kiểm tra

**macOS / Linux**

```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc   # hoặc ~/.bashrc
source ~/.zshrc
flutter --version
```

### 1.2. Cài Android Studio

1. Tải và cài <https://developer.android.com/studio>
2. Mở Android Studio → **More Actions → SDK Manager**
   - Tab **SDK Platforms**: tick **Android 14 (API 34)**
   - Tab **SDK Tools**: tick **Android SDK Command-line Tools**, **Android SDK Build-Tools**, **Android SDK Platform-Tools**
3. Chấp nhận giấy phép:

```bash
flutter doctor --android-licenses
```

### 1.3. Kiểm tra tổng thể

```bash
flutter doctor
```

Cần thấy dấu ✓ ở dòng **Flutter** và **Android toolchain**.
Các dòng về Chrome / Visual Studio / Xcode không quan trọng nếu bạn chỉ build Android.

---

## 2. Tạo project và đưa code vào

### Bước 2.1 — Tạo khung project

```bash
flutter create --org com.example --project-name so_tien_phong so_tien_phong
```

Lệnh này tạo thư mục `so_tien_phong` với đầy đủ phần Android/iOS.

> `--org com.example` quyết định package name là `com.example.so_tien_phong`.
> Muốn tên riêng thì đổi thành ví dụ `--org com.huy`.

### Bước 2.2 — Chép code

Từ bộ code đã tải, chép **ghi đè** vào thư mục `so_tien_phong` vừa tạo:

| Chép cái này | Vào đây |
|---|---|
| `lib/` (cả thư mục) | `so_tien_phong/lib/` — xoá file `main.dart` cũ trước |
| `pubspec.yaml` | `so_tien_phong/pubspec.yaml` |
| `analysis_options.yaml` | `so_tien_phong/analysis_options.yaml` |
| `android_config/AndroidManifest.xml` | `so_tien_phong/android/app/src/main/AndroidManifest.xml` |

Trên macOS/Linux có thể chạy nhanh:

```bash
cp -r <thu-muc-code>/lib so_tien_phong/
cp <thu-muc-code>/pubspec.yaml so_tien_phong/
cp <thu-muc-code>/analysis_options.yaml so_tien_phong/
cp <thu-muc-code>/android_config/AndroidManifest.xml \
   so_tien_phong/android/app/src/main/AndroidManifest.xml
```

### Bước 2.3 — Bật core library desugaring (BẮT BUỘC)

Mở `so_tien_phong/android/app/build.gradle`
(hoặc `build.gradle.kts` nếu Flutter tạo file `.kts`)
và sửa theo đúng nội dung trong **`android_config/build.gradle.snippet.txt`**.

Tóm tắt: thêm 2 khối này.

```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

Không làm bước này thì thư viện nhắc nhở sẽ báo lỗi lúc build.

### Bước 2.4 — Tải thư viện

```bash
cd so_tien_phong
flutter pub get
```

---

## 3. Chạy thử trên máy thật

1. Trên điện thoại: **Cài đặt → Giới thiệu điện thoại** → bấm **Số bản dựng** 7 lần để mở *Tuỳ chọn nhà phát triển*
2. Bật **Gỡ lỗi USB (USB debugging)**
3. Cắm cáp vào máy tính, chọn *Cho phép* khi điện thoại hỏi
4. Kiểm tra:

```bash
flutter devices
```

5. Chạy:

```bash
flutter run
```

Lần đầu build sẽ lâu (5–15 phút). Sau đó sửa code chỉ cần bấm `r` trong terminal để hot reload.

---

## 4. Build file APK

### Cách 1 — APK gộp (dễ nhất, file to hơn)

```bash
flutter build apk --release
```

Kết quả: `build/app/outputs/flutter-apk/app-release.apk`

### Cách 2 — APK tách theo CPU (file nhẹ hơn)

```bash
flutter build apk --split-per-abi
```

Kết quả có 3 file, điện thoại đời mới dùng file **arm64-v8a**:

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Cài lên điện thoại

- Chép file `.apk` vào điện thoại (USB, Zalo, Google Drive...) rồi bấm mở
- Android sẽ hỏi *Cho phép cài từ nguồn này* → bật lên
- Hoặc cài trực tiếp qua cáp:

```bash
flutter install
# hoặc
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Ký APK để phát hành (chỉ cần khi đưa lên CH Play)

Nếu chỉ cài cho riêng mình thì bỏ qua phần này — cấu hình mẫu đã dùng khoá debug.

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Tạo file `android/key.properties`:

```properties
storePassword=<mật khẩu bạn vừa đặt>
keyPassword=<mật khẩu bạn vừa đặt>
keyAlias=upload
storeFile=/duong/dan/den/upload-keystore.jks
```

Rồi sửa `android/app/build.gradle` theo hướng dẫn chính thức:
<https://docs.flutter.dev/deployment/android#signing-the-app>

---

## 6. Lỗi thường gặp

| Lỗi | Cách xử lý |
|---|---|
| `requires core library desugaring to be enabled` | Chưa làm **Bước 2.3** |
| `Could not resolve com.android.tools:desugar_jdk_libs:2.1.4` | Đổi sang `2.1.5` hoặc `2.0.4` |
| `minSdkVersion 16 cannot be smaller than version 21` | Đặt `minSdk = 21` trong `android/app/build.gradle` |
| `Execution failed for task ':app:checkDebugAarMetadata'` | Mở SDK Manager cài **API 34**, rồi `flutter clean && flutter pub get` |
| `Gradle task assembleRelease failed` không rõ lý do | Chạy `flutter clean`, xoá thư mục `build/`, chạy lại |
| Lỗi liên quan `flutter_local_notifications` khi dùng Flutter quá mới | Trong `pubspec.yaml` đổi thành `flutter_local_notifications: ^19.0.0`, rồi trong `lib/services/notification_service.dart` **xoá dòng** `uiLocalNotificationDateInterpretation: ...` |
| App cài xong không hiện thông báo nhắc | Vào *Cài đặt hệ thống → Ứng dụng → Sổ tiền phòng → Thông báo* bật lên. Máy Xiaomi/Oppo/Vivo cần bật thêm *Tự khởi động* và tắt *Tiết kiệm pin* cho app |
| Chọn ảnh bị đứng trên Android 13+ | Cập nhật `image_picker` lên bản mới: `flutter pub upgrade image_picker` |

---

## 7. Cấu trúc code

```
lib/
├── main.dart                       khởi động app, ngôn ngữ tiếng Việt, theme
├── app_state.dart                  trạng thái chung (Provider): dữ liệu + cài đặt
├── theme.dart                      màu sáng/tối, bảng màu 3 loại phí, AppCard
├── models/
│   ├── fee_type.dart               3 loại phí, các khoản nhỏ của phí quản lý,
│   │                               hình thức thanh toán
│   └── payment.dart                model một khoản phí + gộp theo tháng (MonthBook)
├── db/
│   └── database_helper.dart        SQLite: bảng payments, receipt_images
├── services/
│   ├── image_service.dart          chọn/chụp ảnh, chép vào bộ nhớ riêng của app
│   └── notification_service.dart   nhắc đóng tiền hàng tháng
├── screens/
│   ├── root_screen.dart            thanh điều hướng 4 tab
│   ├── home_screen.dart            "Tháng này" + cảnh báo tháng trước còn nợ
│   ├── months_screen.dart          danh sách sổ theo tháng
│   ├── month_detail_screen.dart    chi tiết một tháng bất kỳ
│   ├── invoice_screen.dart         hoá đơn tự sinh, chia sẻ chữ / ảnh
│   ├── receipt_photos_screen.dart  quản lý ảnh hoá đơn
│   ├── photo_viewer_screen.dart    xem ảnh toàn màn hình
│   ├── chart_screen.dart           biểu đồ so sánh + bảng số liệu
│   └── settings_screen.dart        giao diện, nhắc nhở, mức mặc định, xoá dữ liệu
├── widgets/
│   ├── charts.dart                 biểu đồ cột & đường tự vẽ (CustomPainter)
│   ├── fee_card.dart               thẻ một khoản phí
│   ├── fee_editor_sheet.dart       bảng nhập số tiền
│   ├── pay_sheet.dart              bảng xác nhận đóng tiền
│   ├── month_body.dart             phần thân dùng chung cho màn hình tháng
│   └── status_pill.dart            nhãn "Đã đóng / Chưa đóng"
└── utils/
    └── formatters.dart             định dạng tiền VND, ngày giờ, mã hoá đơn
```

---

## 8. Cách dùng app

**Tab "Tháng này"**

- Thẻ trên cùng trả lời ngay: *đã đóng đủ 3 khoản chưa*, còn thiếu bao nhiêu
- Chạm vào từng khoản để nhập số tiền
  - **Tiền điện**: gõ thẳng số tiền, hoặc bật *Tính theo chỉ số công tơ* rồi nhập số cũ / số mới / đơn giá — app tự nhân ra
  - **Tiền quản lý**: nhập tách nước / xe / quản lý toà nhà / khoản khác, app tự cộng
  - **Tiền phòng**: gõ số tiền, hoặc bấm nút dùng mức mặc định đã lưu ở Cài đặt
- Bấm **Đánh dấu đã đóng** → chọn ngày, giờ, hình thức (chuyển khoản / tiền mặt / ví) → app tự sinh **mã hoá đơn**
- Nút **Ảnh** để chụp hoặc chọn ảnh biên lai, ảnh lưu trong bộ nhớ riêng của app

**Tab "Sổ"**

- Danh sách các tháng, mỗi tháng hiện 3 ô Điện / Phòng / Quản lý, ô nào có dấu ✓ là đã đóng
- Nút **Tháng khác** để mở một tháng bất kỳ (tháng cũ hoặc tháng sau)

**Tab "Biểu đồ"**

- Chọn khoảng 3 / 6 / 12 tháng
- Biểu đồ cột so sánh 3 khoản theo tháng — **chạm vào một tháng** để đọc số chi tiết
- Biểu đồ đường tổng chi mỗi tháng
- Bảng "tháng này so với tháng trước": tăng / giảm bao nhiêu, bao nhiêu phần trăm
- Bảng số liệu để đọc con số chính xác

**Tab "Cài đặt"**

- Giao diện Sáng / Tối / Theo hệ thống
- Bật nhắc nhở: chọn ngày trong tháng + giờ, có nút gửi thử thông báo
- Lưu mức mặc định cho tiền phòng, tiền quản lý, đơn giá điện
- Xoá toàn bộ dữ liệu

---

## 9. Vài điều cần biết

- Dữ liệu nằm **hoàn toàn trên máy**. Gỡ app là mất, nên khi đổi máy hãy chụp/chia sẻ hoá đơn trước.
- Nhắc nhở dùng lịch "không chính xác tuyệt đối" (inexact alarm) để không phải xin quyền báo thức đặc biệt — thông báo có thể lệch vài phút đến vài chục phút, đủ dùng cho việc nhắc đóng tiền.
- Ngày nhắc chỉ chọn được từ 1 đến 28 để tháng nào cũng có ngày đó.
- Hoá đơn app tạo ra là để bạn tự ghi nhớ và đối chiếu, không phải biên lai pháp lý.
