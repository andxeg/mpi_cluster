import sys
import socket


def check_server(address, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((address, port))
    sock.send("Hello from client")
    from_server = sock.recv(4096)
    sock.close()

    print("Message from server: %s" % from_server)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Error in input parameters")
        print("Type %s <server IP address> <server port>" % sys.argv[0])
        exit(127)

    addr = sys.argv[1]
    port = int(sys.argv[2])

    check_server(addr, port)

