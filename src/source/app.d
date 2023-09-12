import std.stdio;
import client;

void main()
{
  Client client = new Client("localhost", 47593);
  client.MainApplicationLoop();
}
