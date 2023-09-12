import std.stdio;
import std.socket;
import std.conv;
import std.array;

class Server {
    string address;
    ushort port;
    int[] clients;

    this(string address, ushort port) {
        this.address = address;
        this.port = port;
    }

    void run() {
        // Create a listening socket
        auto listener = new TcpSocket(AddressFamily.INET);
        listener.bind(new InternetAddress(address, port));
        listener.listen(10);

        writeln("Server running on ", address, ":", port);

        while (true) {
            // Wait for incoming connections
            auto client = listener.accept();

            // Read the first message
            auto msg = receiveMessage(client);
            if (msg["type"] == "hello") {
                // Add the new client to the list
                auto clientId = to!int(msg["src"]);
                clients ~= clientId;
                writeln("New client ", clientId, " connected");
            } else if (msg["type"] == "data") {
                // Broadcast the message to all clients except the sender
                auto senderId = to!int(msg["src"]);
                auto pixel = to!int(msg["pixel"]);

                for (auto clientId : clients) {
                    if (clientId != senderId) {
                        auto dst = [to!string(clientId)];
                        auto response = json([("src", to!string(senderId)),
                                               ("dst", dst),
                                               ("type", "data"),
                                               ("pixel", pixel)]);
                        sendMessage(clientById(clientId), response);
                    }
                }
            }

            // Close the connection
            client.close();
        }
    }

    Json receiveMessage(TcpSocket client) {
        // Read the message length
        auto lenBuf = new ubyte[4];
        client.receive(lenBuf);
        auto msgLen = to!int(unpack!(uint)(lenBuf));
        auto msgBuf = new ubyte[msgLen];

        // Read the message content
        client.receive(msgBuf);
        auto msgStr = to!string(msgBuf);
        return json(msgStr);
    }

    void sendMessage(TcpSocket client, Json msg) {
        // Serialize the message and add a length header
        auto msgStr = json(msg).toString();
        auto len = pack!uint(msgStr.length);
        auto lenBuf = new ubyte[4];
        pack!(uint)(len, lenBuf);

        // Send the message
        client.send(lenBuf);
        client.send(cast(ubyte[])msgStr);
    }

    TcpSocket clientById(int clientId) {
        foreach (client; clients) {
            if (client.fd == clientId) {
                return client;
        }
    }
    throw new Exception("Client not found");
}

void main() {
    // Prompt the user for the server address and port
    write("Enter server address: ");
    auto address = readln().strip();
    write("Enter server port: ");
    auto port = to!ushort(readln().strip());

    auto server = new Server(address, port);
    server.run();
}