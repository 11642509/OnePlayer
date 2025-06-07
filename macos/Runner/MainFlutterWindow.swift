import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 设置窗口初始尺寸，使用默认的16:9比例
    let screenSize = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1280, height: 720)
    let windowWidth = min(screenSize.width * 0.7, 1280) // 屏幕宽度的70%，最大1280
    let windowHeight = windowWidth * 9 / 16 // 16:9比例
    
    // 居中显示
    let windowRect = NSRect(
      x: (screenSize.width - windowWidth) / 2,
      y: (screenSize.height - windowHeight) / 2,
      width: windowWidth,
      height: windowHeight
    )
    
    self.contentViewController = flutterViewController
    self.setFrame(windowRect, display: true)

    // 添加.resizable标志以允许用户调整窗口大小
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    self.minSize = NSSize(width: 640, height: 360) // 最小尺寸保持16:9比例
    
    // 设置窗口的宽高比，确保调整大小时保持16:9
    self.aspectRatio = NSSize(width: 16, height: 9)
    
    // 设置方法通道，处理横竖屏切换
    setupMethodChannel(flutterViewController)
    
    // 确保在窗口创建完成后再进行插件注册
    DispatchQueue.main.async {
      RegisterGeneratedPlugins(registry: flutterViewController)
    }

    super.awakeFromNib()
  }
  
  // 设置方法通道以监听方向变化
  private func setupMethodChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "com.oneplayer.window/orientation",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      // 处理方向变化请求
      if call.method == "toggleOrientation" {
        if let isPortrait = call.arguments as? Bool {
          if isPortrait {
            // 切换到竖屏模式 - 9:16
            self.aspectRatio = NSSize(width: 9, height: 16)
          } else {
            // 切换到横屏模式 - 16:9
            self.aspectRatio = NSSize(width: 16, height: 9)
          }
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", 
                              message: "Arguments must be a boolean", 
                              details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
