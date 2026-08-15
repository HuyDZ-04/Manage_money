# Sổ tiền phòng

App Android (Flutter) ghi sổ **tiền điện – tiền phòng – tiền quản lý** hàng tháng.
Mục đích chính: nhìn vào là biết ngay **tháng này đã đóng hay chưa**.

## Có gì

- Nhập 3 loại phí mỗi tháng: tiền điện, tiền phòng, tiền quản lý (tách nước / xe / quản lý toà nhà)
- Tiền điện có thể tính tự động từ chỉ số công tơ (số cũ, số mới, đơn giá)
- Đánh dấu đã đóng → **tự sinh hoá đơn** kèm mã, ngày, giờ và hình thức (chuyển khoản / tiền mặt / ví)
- Tự thêm **ảnh hoá đơn** (chụp hoặc chọn từ thư viện), lưu trong bộ nhớ riêng của app
- **Biểu đồ so sánh** tiền theo tháng: cột 3 khoản cạnh nhau, đường tổng chi, bảng tăng/giảm so tháng trước
- Cảnh báo các tháng trước còn khoản chưa đóng
- Nhắc nhở đóng tiền hàng tháng bằng thông báo
- Chế độ Sáng / Tối
- Dữ liệu **offline hoàn toàn** bằng SQLite, không cần internet, không cần tài khoản

## Build ra APK

**Cách 1 — Không cần cài gì trên máy (khuyến nghị):**
đẩy code lên GitHub, máy chủ của GitHub tự build và trả về file APK.
Xem **[BUILD_APK_TREN_GITHUB.md](BUILD_APK_TREN_GITHUB.md)**.

**Cách 2 — Build trên máy của bạn:**
xem **[HUONG_DAN_BUILD_APK.md](HUONG_DAN_BUILD_APK.md)** — hướng dẫn chi tiết
từ lúc cài Flutter SDK.

Rút gọn cho cách 2:

```bash
flutter create --org com.example --project-name so_tien_phong so_tien_phong
# chép lib/, tool/, android_config/, pubspec.yaml, analysis_options.yaml vào
cd so_tien_phong
python3 tool/prepare_android.py     # tự chép manifest + bật desugaring
flutter pub get
flutter build apk --release
```

## Thư viện dùng

| Gói | Việc |
|---|---|
| `sqflite` + `path` | cơ sở dữ liệu SQLite |
| `path_provider` | thư mục lưu ảnh hoá đơn |
| `image_picker` | chụp / chọn ảnh |
| `provider` | quản lý trạng thái |
| `shared_preferences` | lưu cài đặt |
| `flutter_local_notifications` + `timezone` | nhắc nhở hàng tháng |
| `share_plus` | chia sẻ hoá đơn dạng chữ hoặc ảnh |
| `intl` | định dạng tiền VND và ngày giờ |

Biểu đồ **không dùng thư viện ngoài** — tự vẽ bằng `CustomPainter` để tránh lỗi
không tương thích phiên bản khi build.
