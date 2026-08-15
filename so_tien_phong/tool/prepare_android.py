#!/usr/bin/env python3
"""
Chuẩn bị phần Android cho project "Sổ tiền phòng".

Chạy được cả trên GitHub Actions lẫn máy cá nhân:

    python3 tool/prepare_android.py

Việc nó làm:
  1. Nếu chưa có thư mục android/  -> chạy `flutter create --platforms=android .`
     (giữ nguyên lib/, pubspec.yaml, analysis_options.yaml của mình)
  2. Chép android_config/AndroidManifest.xml đè lên manifest vừa sinh ra
  3. Bật core library desugaring trong android/app/build.gradle(.kts)
     -- bắt buộc, nếu không flutter_local_notifications sẽ báo lỗi build
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_NAME = "so_tien_phong"
ORG = os.environ.get("APP_ORG", "com.example")
DESUGAR_LIB = os.environ.get("DESUGAR_LIB", "com.android.tools:desugar_jdk_libs:2.1.4")

KEEP = ("lib", "pubspec.yaml", "analysis_options.yaml")


def log(message):
    print(f"[prepare_android] {message}", flush=True)


def run(cmd):
    log("$ " + " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)


def _copy(src, dst):
    if os.path.isdir(src):
        shutil.copytree(src, dst)
    else:
        shutil.copy2(src, dst)


def ensure_android_folder():
    if os.path.isdir(os.path.join(ROOT, "android")):
        log("Đã có thư mục android/, bỏ qua flutter create.")
        return

    log("Chưa có android/, sinh khung project bằng flutter create...")
    backup = tempfile.mkdtemp(prefix="so_tien_phong_backup_")
    for item in KEEP:
        src = os.path.join(ROOT, item)
        if os.path.exists(src):
            _copy(src, os.path.join(backup, item))

    run([
        "flutter", "create",
        "--org", ORG,
        "--project-name", PROJECT_NAME,
        "--platforms=android",
        ".",
    ])

    # flutter create ghi đè lib/main.dart và pubspec.yaml -> khôi phục bản của mình
    for item in KEEP:
        src = os.path.join(backup, item)
        if not os.path.exists(src):
            continue
        dst = os.path.join(ROOT, item)
        if os.path.isdir(dst):
            shutil.rmtree(dst)
        elif os.path.exists(dst):
            os.remove(dst)
        _copy(src, dst)
        log(f"Khôi phục {item}")

    shutil.rmtree(backup, ignore_errors=True)


def copy_manifest():
    src = os.path.join(ROOT, "android_config", "AndroidManifest.xml")
    dst = os.path.join(ROOT, "android", "app", "src", "main", "AndroidManifest.xml")
    if not os.path.exists(src):
        log("CẢNH BÁO: không thấy android_config/AndroidManifest.xml, bỏ qua.")
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
    log("Đã chép AndroidManifest.xml (quyền thông báo + receiver nhắc nhở).")


def patch_gradle():
    groovy = os.path.join(ROOT, "android", "app", "build.gradle")
    kts = groovy + ".kts"

    if os.path.exists(kts):
        _patch_file(kts, is_kts=True)
    elif os.path.exists(groovy):
        _patch_file(groovy, is_kts=False)
    else:
        sys.exit("LỖI: không tìm thấy android/app/build.gradle hoặc build.gradle.kts")


def _patch_file(path, is_kts):
    with open(path, encoding="utf-8") as f:
        text = f.read()

    if "coreLibraryDesugaring" in text:
        log(f"{os.path.basename(path)} đã bật desugaring, không sửa gì.")
        return

    flag = (
        "        isCoreLibraryDesugaringEnabled = true\n"
        if is_kts
        else "        coreLibraryDesugaringEnabled true\n"
    )

    match = re.search(r"compileOptions\s*\{\s*\n", text)
    if match:
        text = text[: match.end()] + flag + text[match.end():]
        log("Đã thêm cờ desugaring vào khối compileOptions sẵn có.")
    else:
        android_match = re.search(r"\nandroid\s*\{\s*\n", text)
        if not android_match:
            sys.exit("LỖI: không tìm thấy khối android { } trong build.gradle")
        if is_kts:
            block = (
                "    compileOptions {\n"
                "        isCoreLibraryDesugaringEnabled = true\n"
                "        sourceCompatibility = JavaVersion.VERSION_11\n"
                "        targetCompatibility = JavaVersion.VERSION_11\n"
                "    }\n"
            )
        else:
            block = (
                "    compileOptions {\n"
                "        coreLibraryDesugaringEnabled true\n"
                "        sourceCompatibility JavaVersion.VERSION_11\n"
                "        targetCompatibility JavaVersion.VERSION_11\n"
                "    }\n"
            )
        text = text[: android_match.end()] + block + text[android_match.end():]
        log("Đã thêm mới khối compileOptions.")

    if is_kts:
        deps = (
            "\ndependencies {\n"
            f'    coreLibraryDesugaring("{DESUGAR_LIB}")\n'
            "}\n"
        )
    else:
        deps = (
            "\ndependencies {\n"
            f"    coreLibraryDesugaring '{DESUGAR_LIB}'\n"
            "}\n"
        )

    text = text.rstrip() + "\n" + deps

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)

    log(f"Đã thêm thư viện desugaring vào {os.path.basename(path)}.")


def main():
    log(f"Thư mục project: {ROOT}")
    ensure_android_folder()
    copy_manifest()
    patch_gradle()
    log("Xong. Giờ chạy: flutter pub get && flutter build apk --release")


if __name__ == "__main__":
    main()
