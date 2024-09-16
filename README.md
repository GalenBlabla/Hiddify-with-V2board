# 什么是 V2Hiddify

V2Hiddify 是基于 [Hiddify-Next](https://github.com/hiddify/hiddify-next) 开发的一个衍生项目。该项目的目的是开发一个跨平台客户端，可以直接与 V2board（Xboard）集成。用户可以使用 VPN 服务提供商的相应账户登录，自动订阅并购买套餐。

## 功能

- [x] **使用面板账户登录**：允许用户使用面板账户登录。
- [ ] **注册功能**：提供用户注册功能。
- [ ] **忘记密码**：提供密码恢复功能。
- [x] **自动订阅**：购买套餐后自动添加订阅。
- [x] **显示套餐信息**：显示用户当前的套餐信息。
- [ ] **支付集成**：提供与支付平台的集成功能。
- [ ] **套餐购买**：允许用户购买不同的套餐。
- [ ] **购买后自动订阅**：购买套餐后自动添加订阅。
- [x] **退出登录**：允许用户退出登录。

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

   搜索项目中所有 `https://tomato.galen.life` 的地方，并替换为你的面板域名。例如，如果你的面板域名是 `https://example.com`，你可以用以下命令快速替换：

   ```bash
   grep -rl 'https://tomato.galen.life' lib/ | xargs sed -i 's#https://tomato.galen.life#https://example.com#g'
   ```

2. **替换机场名字**：

   搜索项目中所有 `Tomato VPN` 的地方，并替换为你的机场名称。例如，如果你的机场名字是 `SuperVPN`，可以用以下命令替换：

   ```bash
   grep -rl 'Tomato VPN' lib/ | xargs sed -i 's/Tomato VPN/SuperVPN/g'
   ```

### 5. 打包应用

根据需要打包相应平台的应用：

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
