# Build APK tự động trên GitHub (không cần cài gì trên máy)

GitHub cho build miễn phí trên máy chủ của họ. Bạn đẩy code lên, máy chủ tự cài
Flutter + Android SDK, build ra file APK, bạn tải về cài vào điện thoại.

**Thời gian:** lần đầu ~8–12 phút. **Cần:** một tài khoản GitHub (miễn phí).

---

## Cách A — Dùng dòng lệnh git (nhanh nhất)

### 1. Tạo repo rỗng trên GitHub

Vào <https://github.com/new>

- Repository name: `so-tien-phong`
- Chọn **Private** (repo riêng tư) hoặc **Public** đều được
- **Không** tick "Add a README file"
- Bấm **Create repository**

### 2. Đẩy code lên

Giải nén bộ code, mở terminal trong thư mục `so_tien_phong` rồi chạy:

```bash
git init
git add .
git commit -m "So tien phong - phien ban dau"
git branch -M main
git remote add origin https://github.com/<TEN-GITHUB-CUA-BAN>/so-tien-phong.git
git push -u origin main
```

GitHub sẽ hỏi tài khoản. Nếu bị từ chối mật khẩu, vào
<https://github.com/settings/tokens> tạo một **Personal access token (classic)**
có quyền `repo`, rồi dán token đó thay cho mật khẩu.

### 3. Chờ build

Push xong là workflow chạy ngay. Vào tab **Actions** của repo để xem tiến độ.

---

## Cách B — Làm hoàn toàn trên trình duyệt (không cần git)

### 1. Tạo repo

Giống bước 1 ở Cách A, nhưng lần này **có tick** "Add a README file".

### 2. Tải code lên

- Trong repo, bấm **Add file → Upload files**
- Giải nén bộ code trên máy, mở thư mục `so_tien_phong`
- Chọn **tất cả** file và thư mục bên trong (`lib`, `tool`, `android_config`,
  `pubspec.yaml`, `analysis_options.yaml`, `README.md`...) rồi kéo thả vào trang
- Bấm **Commit changes**

> Thư mục `.github` bắt đầu bằng dấu chấm nên trình duyệt hay bỏ qua.
> Làm tiếp bước 3 để tạo lại nó bằng tay.

### 3. Tạo file workflow bằng tay

- Bấm **Add file → Create new file**
- Ở ô tên file, gõ đúng chuỗi này (gõ dấu `/` sẽ tự tạo thư mục):

  ```
  .github/workflows/build-apk.yml
  ```

- Mở file `.github/workflows/build-apk.yml` trong bộ code đã giải nén, copy toàn
  bộ nội dung, dán vào ô soạn thảo
- Bấm **Commit changes**

Vừa commit xong là build tự chạy.

---

## Tải file APK về

1. Vào tab **Actions** của repo
2. Bấm vào lần chạy mới nhất (dòng trên cùng). Dấu ✓ xanh là thành công
3. Kéo xuống cuối trang, mục **Artifacts** → bấm **so-tien-phong-apk** để tải file zip
4. Giải nén ra sẽ có:

| File | Dùng khi nào |
|---|---|
| `app-release.apk` | Chạy được trên mọi máy, file to nhất — **cứ dùng cái này cho chắc** |
| `app-arm64-v8a-release.apk` | Điện thoại đời từ 2017 trở lại đây, file nhẹ hơn |
| `app-armeabi-v7a-release.apk` | Điện thoại cũ 32-bit |
| `app-x86_64-release.apk` | Máy ảo giả lập |

5. Chép file `.apk` vào điện thoại (Zalo, Google Drive, cáp USB...) rồi bấm mở
6. Android hỏi *Cho phép cài đặt từ nguồn này* → bật lên → **Cài đặt**

---

## Chạy lại build bất cứ lúc nào

Tab **Actions** → chọn **Build APK** ở cột trái → nút **Run workflow** → **Run workflow**.

Ô *Phiên bản Flutter* để mặc định `3.32.x`. Nếu build lỗi vì phiên bản Flutter,
thử đổi thành `3.24.x` hoặc `stable`.

---

## Nếu build đỏ (thất bại)

Bấm vào lần chạy bị lỗi, mở bước có dấu ✗ để xem log.

| Log báo | Cách xử lý |
|---|---|
| `Unable to determine Flutter version` | Ô *Phiên bản Flutter* đổi thành `stable` rồi chạy lại |
| Lỗi cú pháp Dart ở một file nào đó | Copy nguyên đoạn log gửi cho tôi, tôi sửa |
| `flutter_local_notifications ... desugaring` | Bước `prepare_android.py` không chạy — kiểm tra thư mục `tool/` đã được tải lên chưa |
| `Could not resolve com.android.tools:desugar_jdk_libs` | Sửa `tool/prepare_android.py`, đổi `2.1.4` thành `2.1.5` |
| `if-no-files-found: error` | Build không ra file APK — xem lại bước "Build APK gộp" phía trên |

---

## Vài điều cần biết

- APK này ký bằng **khoá debug** (mặc định của Flutter). Cài vào máy dùng bình
  thường, nhưng **không đưa lên CH Play được**. Muốn phát hành thật thì xem mục 5
  trong `HUONG_DAN_BUILD_APK.md`.
- Repo Public thì Actions miễn phí không giới hạn. Repo Private được 2000 phút
  mỗi tháng — mỗi lần build tốn ~10 phút, thoải mái dùng.
- Mỗi lần bạn sửa code rồi push lên `main`, GitHub tự build lại APK mới.
- File APK trong Artifacts được giữ 30 ngày, sau đó tự xoá — tải về máy để dành.
