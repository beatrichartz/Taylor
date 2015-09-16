//
//  Socket.swift
//  Taylor
//
//  Created by Jorge Izquierdo on 9/14/15.
//  Copyright © 2015 Jorge Izquierdo. All rights reserved.
//

enum SocketErrors: ErrorType {
    case ListenError
    case PortUsedError
}

protocol SocketServer {
    
    func startOnPort(p: Int) throws
    func disconnect()
    
    var receivedDataCallback: ((NSData, Socket) -> Bool)? { get set }
}

protocol Socket {
    func sendData(data: NSData)
}

// Mark: Cocoa Async Implementation of the Socket and SocketServer protocol

import CocoaAsyncSocket

struct AsyncSocket: Socket {
    let socket: GCDAsyncSocket
    
    func sendData(data: NSData) {
        self.socket.writeData(data, withTimeout: 10, tag: 1)
        self.socket.disconnectAfterWriting()
    }
}

class AsyncSocketServer: GCDAsyncSocketDelegate, SocketServer {
    
    static var sharedSocket = AsyncSocketServer() //I'm really sorry about this and really looking for a better solution. Please sumbit an issue/PR. Reason: https://github.com/robbiehanson/CocoaAsyncSocket/issues/248
    let socket = GCDAsyncSocket()
    var sockets: [GCDAsyncSocket] = []
    
    var receivedDataCallback: ((NSData, Socket) -> Bool)?
    func startOnPort(p: Int) throws {
        
        socket.setDelegate(AsyncSocketServer.sharedSocket, delegateQueue: dispatch_get_main_queue())
        AsyncSocketServer.sharedSocket.receivedDataCallback = self.receivedDataCallback
        try socket.acceptOnPort(UInt16(p))
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    // GCDAsyncSocketDelegate methods
    @objc func socket(socket: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket){
        
        sockets.append(newSocket)
        newSocket.readDataWithTimeout(10, tag: 1)
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        
        self.receivedDataCallback?(data, AsyncSocket(socket: sock))
    }
    
    @objc func socketDidDisconnect(sock: GCDAsyncSocket, withError err: NSError){
        if let i = sockets.indexOf(sock) {
            sockets.removeAtIndex(i)
        }
    }
    
    @objc func newSocketQueueForConnectionFromAddress(address: NSData!, onSocket sock: GCDAsyncSocket!) -> dispatch_queue_t! {
        
        return dispatch_get_main_queue() //Maybe change to a background queue?
    }
    
    @objc func socketDidCloseReadStream(sock: GCDAsyncSocket!) {
        
    }
}