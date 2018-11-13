//
//  SocketUDPListener.swift
//  NetworkingDemoReceiver
//

import Foundation
import Darwin
import Dispatch

final class SocketUDPListener {

    private var bufferFrame: Data?
    var isConnected = false
    private var handle: Int32?
    private var addrpointer: UnsafeMutablePointer<sockaddr>?
    private let syncQueue = DispatchQueue(label: "syncQueue")
    var serverSources:[Int32:DispatchSourceRead] = [:]

    deinit {
        stop()
        print("Echo UDP Server deinit")
    }

    func start() {
        var temp = [CChar](repeating: 0, count: 255)
        gethostname(&temp, temp.count)

        // create addrinfo based on hints
        // if host name is nil or "" we can connect on localhost
        // if host name is specified ( like "computer.domain" ... "My-MacBook.local" )
        // than localhost is not aviable.
        // if port is 0, bind will assign some free port for us

        var port: UInt16 = 50010
        let hosts = ["localhost"]
        var addrInfo = addrinfo()
        addrInfo.ai_flags = 0
        addrInfo.ai_family = PF_UNSPEC
        addrInfo.ai_socktype = SOCK_DGRAM
        addrInfo.ai_protocol = IPPROTO_UDP

        for host in hosts {

            print("\t\(host)")
            print()

            // retrieve the info
            // getaddrinfo will allocate the memory, we are responsible to free it!

            var info: UnsafeMutablePointer<addrinfo>?
            defer {
                if info != nil
                {
                    freeaddrinfo(info)
                }
            }

            let status: Int32 = getaddrinfo(host, String(port), nil, &info)
            guard status == 0 else {
                print(errno, String(cString: gai_strerror(errno)))
                return
            }

            var p = info
            var serverSocket: Int32 = 0
            var i = 0
            var ipFamily = ""

            // for each address avaiable

            while p != nil {

                i += 1

                // use local copy of info

                var _info = p!.pointee
                p = _info.ai_next
                // (1) create server socket

                serverSocket = socket(_info.ai_family, _info.ai_socktype, _info.ai_protocol)
                if serverSocket < 0 {
                    continue
                }

                // set port is tricky, because we need to remap ai_addr differently
                // for inet and for inet6 family

                switch _info.ai_family {
                case PF_INET:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { p in
                        p.pointee.sin_port = port.bigEndian
                    })
                case PF_INET6:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1, { p in
                        p.pointee.sin6_port = port.bigEndian
                    })
                default:
                    continue
                }

                // (2) bind
                //
                // associates a socket with a socket address structure, i.e. a specified local port number and IP address
                // if port is set to 0, bind will set first free port for us and update

                if bind(serverSocket, _info.ai_addr, _info.ai_addrlen) < 0 {
                    close(serverSocket)
                    continue
                }

                // (3) we need to know an actual address and port number after bind

                if getsockname(serverSocket, _info.ai_addr, &_info.ai_addrlen) < 0 {
                    close(serverSocket)
                    continue
                }

                // (4) retrieve the address and port from updated _info

                switch _info.ai_family {
                case PF_INET:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { p in
                        inet_ntop(AF_INET, &p.pointee.sin_addr, &temp, socklen_t(temp.count))
                        ipFamily = "IPv4"
                        port = p.pointee.sin_port.bigEndian
                    })
                case PF_INET6:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1, { p in
                        inet_ntop(AF_INET6, &p.pointee.sin6_addr, &temp, socklen_t(temp.count))
                        ipFamily = "IPv6"
                        port = p.pointee.sin6_port.bigEndian
                    })
                default:
                    break
                }

                // !!!!! refuze all listening sockets !!!

                if listen(serverSocket, 5) < 0 {} else {
                    close(serverSocket)
                    continue
                }

                print("\tsocket \(serverSocket)\t\(ipFamily)\t\(String(cString: temp))/\(port)")

                // (6) enable receiving data
                // by installing event handler for a socket

                let serverSource = DispatchSource.makeReadSource(fileDescriptor: serverSocket)
                serverSource.setEventHandler {

                    var info = sockaddr_storage()
                    var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

                    let s = Int32(serverSource.handle)
                    var buffer = [UInt8](repeating:0, count: 1024)

                    withUnsafeMutablePointer(to: &info, { (pinfo) -> () in

                        let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to: sockaddr.self)

                        let received = recvfrom(s, &buffer, buffer.count, 0, paddr, &len)

                        if received < 0 {
                            return
                        }
                        while true {
                            guard let frame = self.bufferFrame else { continue }
                            let _ = frame.withUnsafeBytes { data in
                                sendto(s, data, frame.count, 0, paddr, len)
                            }
                            self.bufferFrame = nil
                        }
                    })
                }
                serverSources[serverSocket] = serverSource
                serverSource.resume()

            }
        }

    }

    func send(_ frame: Data) {
        bufferFrame = frame
    }

    func stop() {
        for (socket, source) in serverSources {
            source.cancel()
            close(socket)
            print(socket,"\tclosed")

        }
        serverSources.removeAll()
    }
}
