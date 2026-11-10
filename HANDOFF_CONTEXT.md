# Paperwhite OS v4.7 — Complete Project Handoff & New-Chat Reference

Upload this file (or the entire `paperwhite-os-complete-project.zip` archive) at the start of a new chat session to give full context on **Paperwhite OS v4.7**, its architecture, every resolved hardware quirk on Kindle Paperwhite 3, and how to publish or extend it.

## 1. Target Hardware & Environment

- **Device**: Kindle Paperwhite 3 (7th Generation, `wario` board, `1072×1448` resolution @ 300 PPI).
- **Firmware**: `5.16.2.1.1` jailbroken with [WinterBreak](https://hackerdude.tech/projects/2025-01-01-winterbreak/) + [KindleModding Hotfix `sh_integration`](https://github.com/KindleModding/Hotfix/issues/11).
- **Runtime**: Kindle Web Application Framework (`mesquite`, WebKit-based ES5 runtime — see [Mesquite & WAFs Reference](https://github.com/penguins184/Penguins-Kindle-Wiki/blob/main/Mesquite-WAFs.md) and [Understanding config.xml](https://kindlemodding.org/wafs-and-mesquite/understanding-config-xml.html)).

## 2. Summary of v4.7 Engineering Architecture & Fixes

1. **Chromeless Full-Screen Window & Stock Top-Bar Lockout (`PC:N`)**:
   - Launches `app://com.paperwhite.os` via [com.lab126.appmgrd](https://kindlemodding.org/kindle-apps-and-services/com.lab126.appmgrd.html).
   - Sets the [Awesome Window Manager](https://kindlemodding.org/kindle-dev/awesome-window-manager/) `WM_NAME` property to `L:A_N:application_PC:N_ID:com.paperwhite.os` (omitting `T` and `S` chrome flags so neither the stock battery bar nor the stock top settings/search drop-down bar can appear).
   - Calls [com.lab126.pillow](https://kindlemodding.org/kindle-apps-and-services/com.lab126.pillow.html) `disableEnablePillow "disable"` and `dismissChrome 1`, hides residual `topBar`/`searchBar` windows, and runs `syncBodyClasses()` on `window.onresize` so Paperwhite OS's own custom top bar renders immediately without duplication.
2. **Symlinked WAF & 1-Tap Library Scriptlet**:
   - Ships `documents/Install_Paperwhite_OS.sh` (`# Name: 1. Install Paperwhite OS 4.7`, following [Illusion Generic Scriptlet](https://github.com/forksnd/Illusion/blob/main/Getting-Started/Illusion-Generic-Scriptlet.md)) so tapping it directly in Kindle's Library executes `/mnt/us/install.sh`.
   - Symlinks `/var/local/mesquite/{com.paperwhite.os,store,browser}/index.html` to `/mnt/us/paperwhite-os/waf/index.html` so internal `/var/local` never serves stale cached versions.
3. **Live Hardware Battery Polling (`live_battery.js`)**:
   - `screensaver_watchdog.sh` queries `lipc-get-prop com.lab126.powerd battLevel` ([com.lab126.powerd Reference](https://kindlemodding.org/kindle-apps-and-services/com.lab126.powerd.html)), `gasgauge-info -s` ([Kindle Battery Percentage](https://www.mobileread.com/forums/showthread.php?t=117072)), and `/sys/devices/system/wario_charger/wario_charger0/charging` ([KPW3 Sysfs](https://bookfere.com/post/1103.html)) every 24 seconds, writing `/mnt/us/paperwhite-os/waf/live_battery.js`.
   - The WAF dynamically reloads `live_battery.js` with cache-busting timestamps and ignores stale `localStorage` battery values.
4. **Fast 1:1 Native Scrolling**:
   - Sets `enforce96DPI="no"` in `paperwhite-os/waf/config.xml` ([Understanding config.xml](https://kindlemodding.org/wafs-and-mesquite/understanding-config-xml.html)), implements `attachFastScroll()` (`2.1×` drag multiplier + `±420px` flick momentum), removes heavy scrollbar overlays, and skips `xprop` in `screensaver_watchdog.sh` whenever `WM_NAME` already matches `*PC:N*`.
5. **Hardware Frontlight Brightness (`0–24`)**:
   - Uses `interrogatePillow` plus 25 zero-UI Pillow helper files (`/mnt/us/paperwhite-os/bright/b_0.html`..`b_24.html`) invoking `nativeBridge.setIntLipcProperty("com.lab126.powerd", "flIntensity", N)` and immediately re-locking `disableEnablePillow` to `"disable"`.
6. **Reliable Boot Auto-Launch & Clean `kterm` Integration**:
   - Installs `/etc/upstart/paperwhite-os.conf` using `start on framework_ready and started lab126_gui and started kppmainapp` ([KOReader Autostart Task for PW3 5.16.2.1.1](https://gist.github.com/SuleMareVientu/822b2b51d1ea043ce2b190669c0df38b)).
   - Clears stale `/var/local/transfer*` files and opens `/mnt/us/kterm` ([kterm on MobileRead](https://www.mobileread.com/forums/showthread.php?t=280024)) cleanly on AwesomeWM Dialog Layer `D` (`L:D_N:dialog_ID:com.paperwhite.kterm`).
   - Supports emergency USB bypass by placing `/mnt/us/DISABLE_PWOS` on the USB drive.
7. **Built-In Applications & Endpoints**:
   - **Native `kterm` Launcher**: One-shot detached launch on AwesomeWM Dialog Layer `D`.
   - **Horizontal StandBy Clock**: 5 landscape (`90°`) clock faces with invisible tap-left/tap-right/top-left exit zones.
   - **Sketch Pad**: Normal & Inverted E-Ink canvas, Pen/Marker/Shapes/Grid/Undo/Save, Stroke pills, and inline Wikipedia lookup.
   - **Paginated Book Reader**: Reads `.txt`, `.epub`, `.mobi`, `.azw`, `.azw3` from `/mnt/us/documents/` via `scan_books.sh` + 4 built-in readable classics.
   - **Reading Stats & Wallpapers**: Local device/reading tally, and 46 selectable grayscale sleep screens.
   - **Cloudflare Worker deploy option**: `paperwhite-os/cloudflare-worker/worker.js` serves the whole OS over HTTPS as a single-file Worker, so it can be opened via `app://com.lab126.browser?view=<your-worker-url>` instead of installing locally.

## 3. Step-by-Step Guide to Publishing on GitHub (Beginner Friendly)

1. **Create a GitHub Account & Repository**:
   - Sign in or register at GitHub ([Creating an Account on GitHub](https://docs.github.com/en/account-and-profile/how-tos/account-management/creating-an-account-on-github)).
   - Click the **`+`** icon in the top-right corner -> **New repository** ([Creating a New Repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository)).
   - Name it `paperwhite-os`, set visibility to **Public**, leave "Add a README file" unchecked (since `README.md` is already included here), and click **Create repository**.
2. **Upload the Project Files**:
   - Unzip `paperwhite-os-complete-project.zip` on your computer.
   - Either use [GitHub Desktop](https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop) (recommended for multi-folder projects: **File -> Add Local Repository**, commit to `main`, and click **Publish repository**) OR click **uploading an existing file** on your empty repo page ([Adding a File to a Repository](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository)) and drag in `README.md`, `HANDOFF_CONTEXT.md`, `LICENSE`, `.gitignore`, `index.html`, `builder/`, `screenshots/`, and `kindle-root-bundle/`.
3. **Publish the Downloadable Kindle Installer via GitHub Releases**:
   - On your repository sidebar, click **Releases -> Create a new release** ([Managing Releases in a Repository](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)).
   - Type tag **`v4.7.0`**, title it **`Paperwhite OS v4.7 — Kindle Paperwhite 3 Bundle`**, drag and drop the standalone **`paperwhite-os-cfw-bundle.zip`** into the binary attachments box, and click **Publish release**.
4. **Turn On the Live Interactive Demo (GitHub Pages)**:
   - Go to **Settings -> Pages** in your repository ([Configuring GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)).
   - Under **Build and deployment -> Branch**, choose **`main`** and **`/ (root)`**, then click **Save**. Within 1–2 minutes, `https://<your-username>.github.io/paperwhite-os/` will serve your live interactive Paperwhite OS v4.7 demo (`index.html`).

## 4. Map of Files in `paperwhite-os-complete-project.zip`

- `README.md` — Front-page GitHub documentation ([About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)) with embedded `screenshots/*.png` previews.
- `HANDOFF_CONTEXT.md` — This complete architectural and continuation guide for new chats.
- `index.html` — Standalone browser/Canvas interactive build (`paperwhite_os_menu.html`).
- `builder/build_cfw.py` — Complete Python generator script that compiles the WAF HTML/JS/CSS, shell scripts, Upstart config, and brightness bridges into `paperwhite-os-cfw-bundle.zip`.
- `kindle-root-bundle/` — Unpacked contents of `paperwhite-os-cfw-bundle.zip` (`install.sh`, `uninstall.sh`, `apps/`, `documents/Install_Paperwhite_OS.sh`, `paperwhite-os/`) for code browsing on GitHub or direct inspection.
- `screenshots/` — UI design mockups (`ui_home.png`, `ui_home_grid.png`, `ui_home_inverted.png`, `ui_library.png`, `ui_web.png`, `ui_settings_1..4.png`, `wallpapers_*.png`).
- `wallpapers-source/` — Original full-resolution sleep screen artwork (`46` PNGs).
