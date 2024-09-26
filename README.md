# 什么是 V2Hiddify（[View this document in English](./README_en.md)）

V2Hiddify 是基于 [Hiddify-Next](https://github.com/hiddify/hiddify-next) 开发的一个衍生项目。该项目的目的是开发一个跨平台客户端，可以直接与 V2board（Xboard）集成。用户可以使用 VPN 服务提供商的相应账户登录，自动订阅并购买套餐。  

## 功能

- [x] **使用面板账户登录**：允许用户使用面板账户登录。
- [x] **注册功能**：提供用户注册功能。
- [x] **忘记密码**：提供密码恢复功能。
- [x] **自动订阅**：购买套餐后自动添加订阅。
- [x] **显示套餐信息**：显示用户当前的套餐信息。
- [ ] **支付集成**：提供与支付平台的集成功能。
- [ ] **套餐购买**：允许用户购买不同的套餐。
- [x] **购买后自动订阅**：购买套餐后自动添加订阅。
- [x] **退出登录**：允许用户退出登录。
- [x] **语言本地化支持**：支持中英文本地化。
## 安装步骤

### 1. 克隆仓库

首先，将项目仓库克隆到本地：

```bash
git clone https://github.com/GalenBlabla/Hiddify-with-V2board.git
cd Hiddify-with-V2board
```

### 2. 依赖准备

根据不同的操作系统，执行以下命令以准备依赖环境：

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

### 3. 运行项目

在准备好依赖后，可以使用 Flutter 运行项目：

```bash
flutter run
```

### 4. 替换面板域名和机场名字

在 `lib` 目录下进行以下替换操作：

1. **替换面板域名**：

   打开```lib/features/panel/v2board/service/auth_service.dart``` 替换_baseUrl为目标面板地址。
   ~~搜索项目中所有 `https://tomato.galen.life` 的地方，并替换为你的面板域名。例如，如果你的面板域名是 `https://example.com`，你可以用以下命令快速替换：~~

   ~~grep -rl 'https://tomato.galen.life' lib/ | xargs sed -i 's#https://tomato.galen.life#https://example.com#g'~~

2. **替换机场名字**：

   应用内，找到语言包```assets/translations/strings_zh-CN.i18n.json```（中文举例），修改第三行```"appTitle": "V2Hiddify"```。V2Hiddify就是程序应用内的名字以及欢迎界面的名字。
   应用外，也就是应用本身的名字，需要在对应平台文件中修改，安卓示例：
    #### 修改 `AndroidManifest.xml`

    在 `android/app/src/main/AndroidManifest.xml` 文件中，找到 `<application>` 标签中的 `android:label` 属性并修改它：

    ```xml
    <application
        android:name=".Application"
        android:banner="@mipmap/ic_banner"
        android:icon="@mipmap/ic_launcher"
        android:label="V2Hiddify"
    ```
   你仍然可以使用全局替换的方式更改你看到的目标文字，虽然这样可能会带来未知的错误。

   ~~搜索项目中所有 `Hiddify VPN` 的地方，并替换为你的机场名称。例如，如果你的机场名字是 `SuperVPN`，可以用以下命令替换：~~


   ~~grep -rl 'Hiddify VPN' lib/ | xargs sed -i 's/Hiddify VPN/SuperVPN/g'~~

### 5. 打包应用

根据需要打包相应平台的应用：  
在打包之前我们需要进入 `android` 目录下，找到 `gradle.properties` 文件，修改里面的代理 IP 和端口为自己的：

  ```properties
  org.gradle.jvmargs=-Xmx4048m -Dfile.encoding=UTF-8
  android.useAndroidX=true
  android.enableJetifier=true

  # HTTP 代理设置
  systemProp.http.proxyHost=192.168.28.36
  systemProp.http.proxyPort=7890

  # HTTPS 代理设置
  systemProp.https.proxyHost=192.168.28.36
  systemProp.https.proxyPort=7890

  # 不使用代理的主机（可选）
  systemProp.http.nonProxyHosts=localhost|127.0.0.1
  ```

- Android 打包：

  ```bash
  flutter build apk
  ```

- iOS 打包：

  ```bash
  flutter build ios
  ```

- macOS 打包：

  ```bash
  flutter build macos
  ```

- Windows 打包：

  ```bash
  flutter build windows
  ```

---

通过以上步骤，你可以定制并打包适合自己面板的 V2Hiddify 客户端，方便用户使用 VPN 服务。

## V2Hiddify 示例图片

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

## 打包平台需求介绍

V2Hiddify 项目目前存在一个问题：对于不同的域名，需要分别打包客户端。为了简化这个过程，我计划开发一个自动打包平台。用户可以通过该平台输入目标面板的域名（如 "tomato.vpn.com"）和面板名称（如 "Hiddify"），平台会自动为该面板生成配置文件并完成打包。

### 实现思路

1. **前端用户输入**：用户在平台上输入域名和面板名称。
2. **生成配置文件**：后端根据用户输入生成对应的配置文件（例如 `config.toml`）。
3. **触发打包脚本**：后端调用打包脚本（如 `build.sh`），根据配置文件进行打包。
4. **下载链接**：打包完成后，生成下载链接供用户下载。