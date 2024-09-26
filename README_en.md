# What is V2Hiddify（[查看中文版文档](./README.md)）

V2Hiddify is a derivative project developed based on [Hiddify-Next](https://github.com/hiddify/hiddify-next). The goal of this project is to develop a cross-platform client that can be directly integrated with V2board (Xboard). Users can log in with the corresponding account provided by the VPN service provider to automatically subscribe and purchase plans.  


## Features

- [x] **Login with panel account**: Allows users to log in with a panel account.
- [x] **Registration**: Provides a user registration feature.
- [x] **Forgot password**: Provides password recovery functionality.
- [x] **Automatic subscription**: Automatically adds subscription after purchasing a plan.
- [x] **Display plan information**: Displays the user's current plan information.
- [ ] **Payment integration**: Provides integration with payment platforms.
- [ ] **Plan purchase**: Allows users to purchase different plans.
- [ ] **Automatic subscription after purchase**: Automatically adds subscription after purchasing a plan.
- [x] **Logout**: Allows users to log out.
- [x] **Language localization support**: Supports Chinese and English localization.

## Installation Steps

### 1. Clone the repository

First, clone the project repository to your local machine:

```bash
git clone https://github.com/GalenBlabla/Hiddify-with-V2board.git
cd Hiddify-with-V2board
```

### 2. Prepare dependencies

Depending on the operating system, execute the following commands to prepare the dependency environment:

- **Windows**:

  ```bash
  make windows-prepare
  ```

- **Linux**:

  ```bash
  make linux-prepare
  ```

- **macOS**:

  ```bash
  make macos-prepare
  ```

- **iOS**:

  ```bash
  make ios-prepare
  ```

- **Android**:

  ```bash
  make android-prepare
  ```

### 3. Run the project

After preparing the dependencies, you can run the project with Flutter:

```bash
flutter run
```

### 4. Replace panel domain and app name

Make the following replacements under the `lib` directory:

1. **Replace panel domain**:

   Search for all occurrences of `https://tomato.galen.life` in the project and replace it with your panel domain. For example, if your panel domain is `https://example.com`, you can quickly replace it with the following command:

   ```bash
   grep -rl 'https://tomato.galen.life' lib/ | xargs sed -i 's#https://tomato.galen.life#https://example.com#g'
   ```

2. **Replace app name**:

   Search for all occurrences of `Hiddify VPN` in the project and replace it with your app name. For example, if your app name is `SuperVPN`, you can replace it with the following command:

   ```bash
   grep -rl 'Hiddify VPN' lib/ | xargs sed -i 's/Hiddify VPN/SuperVPN/g'
   ```

### 5. Package the application

Depending on the platform, package the corresponding application:  
Before packaging, enter the `android` directory, find the `gradle.properties` file, and modify the proxy IP and port to your own:

```properties
org.gradle.jvmargs=-Xmx4048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true

# HTTP proxy settings
systemProp.http.proxyHost=192.168.28.36
systemProp.http.proxyPort=7890

# HTTPS proxy settings
systemProp.https.proxyHost=192.168.28.36
systemProp.https.proxyPort=7890

# Hosts that don't use the proxy (optional)
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

- Android packaging:

  ```bash
  flutter build apk
  ```

- iOS packaging:

  ```bash
  flutter build ios
  ```

- macOS packaging:

  ```bash
  flutter build macos
  ```

- Windows packaging:

  ```bash
  flutter build windows
  ```

---

With the above steps, you can customize and package the V2Hiddify client for your panel, making it convenient for users to use the VPN service.

## V2Hiddify Example Images

### 中文界面
<p align="center">
  <img src="./images/login_zh.jpg" alt="登录示例 ZH" width="200"/>
  <img src="./images/home_zh.jpg" alt="主页示例 ZH" width="200"/>
  <img src="./images/plan_zh.jpg" alt="套餐示例 ZH" width="200"/>
  <img src="./images/connect_zh.jpg" alt="连接示例 ZH" width="200"/>
</p>

### English Interface
<p align="center">
  <img src="./images/login_en.jpg" alt="Login Example EN" width="200"/>
  <img src="./images/home_en.jpg" alt="Home Example EN" width="200"/>
  <img src="./images/plan_en.jpg" alt="Plan Example EN" width="200"/>
  <img src="./images/connect_en.jpg" alt="Connect Example EN" width="200"/>
</p>

---

## Packaging Platform Requirements Overview

There is currently an issue with the V2Hiddify project: clients need to be packaged separately for different domains. To simplify this process, I plan to develop an automatic packaging platform. Users can input the target panel's domain (e.g., "tomato.vpn.com") and panel name (e.g., "Hiddify"), and the platform will automatically generate configuration files and complete the packaging.

### Implementation Ideas

1. **Frontend user input**: Users enter the domain and panel name on the platform.
2. **Generate configuration file**: The backend generates the corresponding configuration file (e.g., `config.toml`) based on user input.
3. **Trigger packaging script**: The backend calls the packaging script (e.g., `build.sh`) and packages according to the configuration file.
4. **Download link**: After packaging is complete, a download link is generated for the user to download.
