//
//  WebsocketWarpper.swift
//  Buddy_2dx-mobile
//
//  Created by Rock on 2021/3/15.
//

import UIKit
import KakaJSON

//path: /wss
//Params: systemId=10001

protocol WebsocketWarpperMmoRoomDelegate: NSObject {
    func WebsocketWarpper(didReciveMessgae data: [String: Any])
}

@objcMembers class WebsocketWarpper: NSObject, SRWebSocketDelegate {

    let defaultInterval: TimeInterval = 25
    let roomInterval: TimeInterval = 2
    let gWebsocketWarpperPath = "wss://test.pointone.tech/app/ws"
//    systemId=10001&UID=xx
    var clientId: String?
    
    var pingParameter: [String: Any]?
    
    weak var mmoRoomDelegate: WebsocketWarpperMmoRoomDelegate?
    
    // MARK: life cycle
    private static let sharedManager: WebsocketWarpper = {
        let shared = WebsocketWarpper.init()
        return shared
    }()
       
    private override init() {
    }
   
    // Accessors
    class func shared() -> WebsocketWarpper {
        return sharedManager
    }
    
    //
    var socket: SRWebSocket?
    
    var reConnectTime: TimeInterval = 0
    var heartBeat: Timer?
    var urlStr: String?
    
    /// 开启链接
    func openSocket() {
        // Noti: ios暂时不需要websocket 需求，注释以下代码
//        guard let uid = BudSignInUserServer.sharedManager().loginInfo?.userId else { return  }
//        let budSocketPath = gWebsocketWarpperPath + "?systemId=10001&" + "UID=" + uid
//        self.openSocket(for: budSocketPath)
    }
    
    private func openSocket(for urlStr: String) {
        if urlStr.count == 0 {
            return
        }
    
        if self.socket != nil {
            return
        }
        guard let url = URL(string: urlStr) else { return  }
        self.urlStr = urlStr

        // SRWebSocketUrlString 就是websocket的地址 写入自己后台的地址
        if let socket = SRWebSocket.init(url: url) {
            socket.delegate = self // SRWebSocketDelegate 协议
            socket.open()    // 开始连接
            self.socket = socket
        }
    }
    
    /// 关闭连接
    func closeSocket() {
        print("[websocket] closeSocket")
        self.socket?.close()
        self.socket = nil
        
        self.destoryHeartBeat()
    }
    
    /// 重连
    func reConnect() {
        print("[websocket] reConnect")
        self.closeSocket()
        
        //超过一分钟就不再重连 所以只会重连5次 2^5 = 64
        if (reConnectTime > 64) {
            return;
        }
        
        guard let url = self.urlStr else { return  }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+reConnectTime) {
            self.socket = nil
            self.openSocket(for: url)
        }
        
        // 重连时间2的指数级增长
        if reConnectTime == 0 {
            reConnectTime = 2
        } else {
            reConnectTime *= 2
        }
    }
    
    /// 销毁心跳定时器
    func destoryHeartBeat() {
        DispatchQueue.main.async {
            if let _ = self.heartBeat {
                self.heartBeat?.invalidate()
                self.heartBeat = nil
            }
        }
    }
    
    /// 初始化心跳包
    /// - Parameter timeInterval: 时间间隔
    func initHeartBeat(with timeInterval: TimeInterval ) {
        DispatchQueue.main.async { [self] in
            
            self.heartBeat?.invalidate()
            self.heartBeat = nil
            // 心跳设置为25s，NAT超时一般为5分钟
            self.heartBeat = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(sendPingToServer), userInfo: nil, repeats: true)
        }
    }
    
    lazy var socketSerialQueue: DispatchQueue = {
        let queue = DispatchQueue.init(label: "budSocket")
        return queue
    }()
    
    /// 发送数据统一接口 Send a  String or Data
    @objc func onSendData(heart: Any) {
        self.socketSerialQueue.async {
            if let socket = self.socket {
                if socket.readyState == .OPEN {
                    // 发送数据
                    socket.send(heart)
                } else if socket.readyState == .CONNECTING {
                    // 正在连接中，重连后其他方法会去自动同步数据
                    // 每隔2秒检测一次 socket.readyState 状态，检测 10 次左右
                    // 只要有一次状态是 SR_OPEN 的就调用 [ws.socket send:data] 发送数据
                    // 如果 10 次都还是没连上的，那这个发送请求就丢失了，这种情况是服务器的问题了，小概率的
                    self.reConnect()
                } else if socket.readyState == .CLOSING ||  socket.readyState == .CLOSED {
                    // websocket 断开了，调用 reConnect 方法重连
                    self.reConnect()
                } else {
                    // 没有网络
                }
            }
        }
    }
    
    /// pingPong机制
    @objc func sendPingToServer() {
        
        var parmas: [String: Any] = [:]
        
        var message: [String: Any] = [:]
        if let parameter = self.pingParameter {
            message = parameter
        }
        message["clientId"] = self.clientId
        message["systemId"] = "10001"
        message["uid"] = BudSignInUserServer.sharedManager().loginInfo?.userId
    
        parmas["type"] = 0
        parmas["message"] = message.toString()
        
        if let jsonStr = parmas.toString() {
            self.onSendData(heart: jsonStr)
        }
        
//        print("[webSocket] send ping")
    }

    // MARK: - SRWebSocketDelegate
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        print("[webSocket] 连接成功，可以与服务器交流了,同时需要开启心跳")
        
        //每次正常连接的时候清零重连时间
        reConnectTime = 0;
        //开启心跳 心跳是发送pong的消息 我这里根据后台的要求发送data给后台
        
        if let _ = self.pingParameter {
            self.initHeartBeat(with: roomInterval)
        } else {
            self.initHeartBeat(with: defaultInterval)
        }
        
    }
    
    /// 当服务器拒绝，或者发生错误的时候回调
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        
        /*
         连接失败，这里可以实现掉线自动重连，要注意以下几点
         "1.判断当前网络环境，如果断网了就不要连了，等待网络到来，在发起重连"
         2.判断调用层是否需要连接，例如用户都没在聊天界面，连接上去浪费流量
         3.连接次数限制，如果连接失败了，重试10次左右就可以了，不然就死循环了
         */
        print("[webSocket] 连接失败，这里实现掉线自动重连")
        //连接失败就重连
        self.reConnect()
        #if BETA
        UIApplication.shared.keyWindow?.makeToast("[BETA]收到服务器fail, 重新连接")
        #endif
    }
    
    /// 服务器关闭的时候回调 断开连接 同时销毁心跳
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        
//        self.closeSocket()
        #if BETA
        UIApplication.shared.keyWindow?.makeToast("[BETA]收到服务器关闭的时候回调")
        #endif
    }
    
    /*
     该函数是接收服务器发送的pong消息，其中最后一个是接受pong消息的
     用于每隔一段时间通知一次服务端，客户端还是在线，这个心跳包其实就是一个ping消息，
     我的理解就是建立一个定时器，每隔十秒或者十五秒向服务端发送一个ping消息，这个消息可是是空的
     */
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
//        print("[webSocket] didReceivePong")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        // 收到服务器发过来的数据 这里的数据可以和后台约定一个格式
//        print("[webSocket] message:\(String(describing: message))")

        var data: Data?
        if message is String {
            guard let jsonStr = message as? String else { return  }
            data = jsonStr.data(using: .utf8)
        } else if message is Data {
            data = message as? Data
        }
        
        guard let jsonData = data else { return  }
        guard let resObj = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) else { return  }
        
        if let response = resObj as? [String: Any] {
            let resultCode = response[gResponseResultKey] as? Int ?? -1
            if resultCode == gResponseSuccesCode {
                
                guard let data = response[gResponseDataKey] else { return  }
                var json: [String: Any]?
                if let jsonStr = data as? String {
                    json = jsonStr.toJson() as? [String: Any]
                } else if let jData = data as? [String: Any] {
                    json = jData
                }
                guard let jData = json else { return  }
                self.onHandleSocketMessage(for: jData)
            } else {
                if let failMsg = response[gResponseMessageKey] as? String {
                    print("[webSocket] fail message :\(failMsg)")
                }
            }
        }
    }
    
    enum WebsocketType: Int {
        case setUpSuccess = 0    // 建立连接，保存clientId
        case mmoMessage   = 1    // mmo房间消息
    }
    
    // MARK: - BudHandle
    
    func onHandleSocketMessage(for data: [String: Any]) {
        let type = data["type"] as? Int ?? 0
        if type == 0 {
            if let clientId = data["clientId"] as? String {
                self.clientId = clientId
            }
        } else if type == 1 {
            // mmo房间消息，给具体
            self.mmoRoomDelegate?.WebsocketWarpper(didReciveMessgae: data)
        }
    }
    

}


extension WebsocketWarpper {
    
    // 进入房间 timer 间隔变成2s
    func joinMmoRoomChat(for parameter: [String: Any]) {
        self.pingParameter = parameter
        
        self.initHeartBeat(with: roomInterval)
    }
    
    func quitMmoRoomChat() {
        self.pingParameter = nil
        
        self.initHeartBeat(with: defaultInterval)
    }
}
