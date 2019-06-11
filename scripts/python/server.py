mport sys
import socket


def start_server(address, port):
    serv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    serv.bind((address, port))
    serv.listen(5)

    while True:
        conn, addr = serv.accept()
        from_client = ''

        #while True:
        #    data = conn.recv(4096)
        #    if not data: break
        #    from_client += data
        #    print("Message from client: %s" % from_client)
        print("Client %s was connected" % str(addr))

        from_client = conn.recv(4096)
        print("Message from client: %s" % from_client)

        conn.send("I am SERVER\n")
        conn.close()

        print("client disconnected")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Error in input parameters")
        print("Type %s <server IP address> <server port>" % sys.argv[0])
        exit(127)

    addr = sys.argv[1]
    port = int(sys.argv[2])

    print("Server was started")
    start_server(addr, port)
    print("Server was finished")

