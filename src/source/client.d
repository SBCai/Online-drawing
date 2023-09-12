/// Run with: 'dub'

// Import D standard libraries
import std.stdio;
import std.string;
import std.socket;
import std.json;
import std.conv;
import std.algorithm;
import std.array;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

// Load
import sdlapp;

/// client class
class Client {
    string address;
    ushort port;
    Socket socket;
    SDLApp myApp;
    this(string address, ushort port) {
        this.address = address;
        this.port = port;
        this.myApp = new SDLApp();
        // create a socket
        //this.socket = new Socket(AddressFamily.INET, SocketType.STREAM);
        this.socket = new TcpSocket(AddressFamily.INET);
        // bind the socket to address, port
        this.socket.bind(new InternetAddress(address, port));
        this.socket.listen(10);
            scope(exit) this.socket.close();
        // send hello message
        string helloMsg = `{"type": "Hello"}`;
        this.socket.send(helloMsg);
    }

    /// our main application where we will draw from here
    void MainApplicationLoop(){
    // Create an SDL window
    // Flag for determing if we are running the main application loop
    bool runApplication = true;
    // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
    //                                                but not yet released)
    bool drawing = false;

    // Main application loop that will run until a quit event has occurred.
    // This is the 'main graphics loop'
    while(runApplication){
      SDL_Event e;
      // Handle events
      // Events are pushed into an 'event queue' internally in SDL, and then
      // handled one at a time within this loop for as many events have
      // been pushed into the internal SDL queue. Thus, we poll until there
      // are '0' events or a NULL event is returned.
      while(SDL_PollEvent(&e) !=0){
        if(e.type == SDL_QUIT){
          runApplication= false;
        }
        else if(e.type == SDL_MOUSEBUTTONDOWN){
          drawing=true;
        }else if(e.type == SDL_MOUSEBUTTONUP){
          drawing=false;
        }else if(e.type == SDL_MOUSEMOTION && drawing){
          // retrieve the position
          int xPos = e.button.x;
          int yPos = e.button.y;
          // Loop through and update specific pixels
          // NOTE: No bounds checking performed --
          //       think about how you might fix this :)
          int brushSize=4;
          for(int w=-brushSize; w < brushSize; w++){
            for(int h=-brushSize; h < brushSize; h++){
              try {
                this.myApp.UpdateSurfacePixel(xPos+w,yPos+h);
                // send the pixel location to server
                this.sendMessage(xPos+w,yPos+h);
              } catch (Exception e) {
                // do nothing
              }
            }
          }
        }
      }
      // check update from server
      this.checkUpdate();

      // Blit the surface (i.e. update the window with another surfaces pixels
      //                       by copying those pixels onto the window).
      SDL_BlitSurface(this.myApp.getSurface(),null,SDL_GetWindowSurface(this.myApp.getWindow()),null);
      // Update the window surface
      SDL_UpdateWindowSurface(this.myApp.getWindow());
      // Delay for 16 milliseconds
      // Otherwise the program refreshes too quickly
      SDL_Delay(16);
    }

      // Destroy our window
      SDL_DestroyWindow(this.myApp.getWindow());
  }

  /// send pixel data to server
  void sendMessage(int xPos, int yPos) {
    int[] pixel = [xPos, yPos];
    string msg = `{"src": 000, //TODO
                   "dst": dst,
                   "type": "data",
                   "pixel": pixel}`;
    this.socket.send(msg);
  }

  /// check if there's any update from server
  void checkUpdate() {
      // Message buffer will be 1024 bytes for now
      char[1024] buffer;
      auto received = socket.receive(buffer);
      if (received != 0) {
        auto msgStr = to!string(buffer);
        // TODO uncomment here and delete for test section when server is ready to use
        //auto msgJson = parseJSON(msgStr);

        // for test
        JSONValue msgJson = [ "language": "D" ];
        msgJson.object["pixel"] = JSONValue( [250,250] );
        // for test

        int xPos = cast(int)msgJson["pixel"].array[0].integer;
        int yPos = cast(int)msgJson["pixel"].array[1].integer;

        // update surface (note that we don't need brushsize here)
        this.myApp.UpdateSurfacePixel(xPos,yPos);
      }
  }
}






