# 🧱 DHF Docker Builder — Windows 11 Test Environment

This project provides a **containerized build environment** for Design History File (DHF) document generation.
It supports both **Arch Linux** and **Ubuntu** base images and is designed specifically to work on **Windows 11 with Docker Desktop + WSL 2**.

---

## 📝 Prerequisites (Windows 11)

Before using this repository, ensure you have:

1. ✅ **Docker Desktop** installed
   👉 [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

2. ✅ **WSL 2 enabled** (required by Docker Desktop)
   👉 Run this in **PowerShell as Administrator**:
```powershell
   wsl --install
```
3. ✅ (Optional) Git Bash installed — makes make commands easier
👉 https://gitforwindows.org/

4. ✅ Clone this repository:
```powershell
git clone https://github.com/Traap/dhf-docker.git
cd dhf-docker
```

## 🐳 Quick Start — Arch Linux Image

The Arch image is the primary reference build.

1.  Build the container:
```powershell
make arch.bld
```

2. Run the build
```powershell
make arch.run
```

3. List TeX files detected by docbld
```powershell
make dhf.list_files
```

4. To open an interactive shell inside the container
```powershell
make arch.shell
`
📝 Outputs are written to the ./exports folder on your Windows filesystem.


## 🐧 Ubuntu Image (Optional)
You can also build using the Ubuntu-based Dockerfile:
```powershell
make -f ubuntu.build
make -f ubuntu.run
```

## 🧪 Testing Checklist
Please run through these steps and report any issues:
* ✅ Docker Desktop starts without errors
* ✅ make arch.build completes successfully
* ✅ make arch.list_files outputs a list of .texx files
* ✅ make arch.run runs the full DHF document build
* ✅ Generated PDFs / HTML appear in ./exports

If any step fails, please provide:
* A copy of the exports/build.log
* Your Windows version and WSL status
* Which target (Arch or Ubuntu) you were using

## 🧼 Cleanup Commands
```powershell
make -f clean   # Remove containers, volumes, and images
make -f prune   # Remove dangling images and stopped containers
```

## 📚 Make Targets Reference
Run this to list all available targets:
```powershell
make -f help
```

## 🧠 Tips
* Always build first (arch.build or ubuntu.build) before running document builds.
* Use Git Bash on Windows for best results with make.
* Keep the exports/ folder clean between test runs for easier debugging.


