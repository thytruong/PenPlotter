 class Com {
    Serial myPort;  //the Serial port object
    String val;
    ArrayList<String> buf = new ArrayList<String>();

    ArrayList<String> comPorts = new ArrayList<String>();
    long baudRate = 115200;
    int lastPort;
    int okCount = 0;

    public void listPorts() {
        //  initialize your serial port and set the baud rate to 9600

        comPorts.add("Disconnected");

        for (int i = 0; i < Serial.list().length; i++) {
            String name = Serial.list()[i];
            int dot = name.indexOf('.');
            if (dot >= 0)
                name = name.substring(dot + 1);
            if (!name.contains("luetooth")) {
                comPorts.add(name);
                println(name);
            }
        }
    }

    public void disconnect() {
        clearQueue();
        if (myPort != null)
            myPort.stop();
        myPort = null;

        //  myTextarea.setVisible(false);
    }

    public void connect(int port) {
        clearQueue();
        try {
            myPort = new Serial(applet, Serial.list()[port], (int) baudRate);
            lastPort = port;
            println("connected");
            myPort.write("\n");
        } catch (Exception exp) {
            exp.printStackTrace();
            println(exp);
        }
    }

    public void connect(String name) {
        for (int i = 0; i < Serial.list().length; i++) {
            if (Serial.list()[i].contains(name)) {
                connect(i);
                return;
            }
        }
        disconnect();
    }

    public void sendMotorOff() {
        motorsOn = false;
        send("M84\n");
    }

    public void moveDeltaX(float x) {
        send("G0 X" + x + "\n");
        updatePos(currentX + x, currentY);
    }

    public void moveDeltaY(float y) {
        send("G0 Y" + y + "\n");
        updatePos(currentX, currentY + y);
    }

    public void sendMoveG0(float x, float y) {
        send("G0 X" + x + " Y" + y + "\n");
        updatePos(x, y);
    }

    public void sendMoveG1(float x, float y) {
        send("G1 X" + x + " Y" + y + "\n");
        updatePos(x, y);
    }

    public void sendG2(float x, float y, float i, float j) {
        send("G2 X" + x + " Y" + y + " I" + i + " J" + j + "\n");
        updatePos(x, y);
    }

    public void sendG3(float x, float y, float i, float j) {
        send("G3 X" + x + " Y" + y + " I" + i + " J" + j + "\n");
        updatePos(x, y);
    }

    public void sendSpeed(int speed) {
        send("G0 F" + speed + "\n");
    }

    public void sendHome() {
        send("M1 Y" + homeY + "\n");
        updatePos(homeX, homeY);
    }

    public void sendSpeed() {
        send("G0 F" + speedValue + "\n");
    }

    public void sendPenWidth() {
        send("M4 E" + penWidth + "\n");
    }

    public void sendSpecs() {
        send("M4 X" + machineWidth + " E" + penWidth + " S" + stepsPerRev + " P" + mmPerRev + "\n");
    }

    public void sendPenUp() {
        send("G4 P250\n");
        send("M340 P3 S2350\n");
        send("G4 P250\n");
        showPenDown();
    }

    public void sendPenDown() {
        send("G4 P250\n");
        send("M340 P3 S1500\n");
        send("G4 P250\n");
        showPenUp();
    }

    public void sendAbsolute() {
        send("G90\n");
    }

    public void sendRelative() {
        send("G91\n");
    }

    public void sendPixel(float da, float db, int pixelSize, int shade, int pixelDir) {
        send("M3 X" + da + " Y" + db + " P" + pixelSize + " S" + shade + " E" + pixelDir + "\n");
    }


    public void initArduino() {
        sendHome();
        sendSpeed();
        sendSpecs();
    }

    public void clearQueue() {
        buf.clear();
        okCount = 0;
    }

    public void queue(String msg) {
        if (myPort != null) {
            // print("Q "+msg);
            buf.add(msg);
        }
    }

    public void nextMsg() {
        if (buf.size() > 0) {
            String msg = buf.get(0);
            //print("sending "+msg);
            oksend(msg);
            buf.remove(0);
        } else {

            if (currentPlot.isPlotting())
                currentPlot.nextPlot(true);

        }
    }

    public void send(String msg) {

        if (okCount >= 0)
            oksend(msg);
        else
            queue(msg);
    }

    public void oksend(String msg) {
        okCount--;
        print(msg);

        if (myPort != null) {
            myPort.write(msg);
            myTextarea.setText(" " + msg);
        }
    }

    public void serialEvent() {

     
        if (myPort == null || myPort.available() <= 0) return;


        val = myPort.readStringUntil('\n');
        if (val != null) {
            val = trim(val);

            if (val.contains("wait"))
                okCount = 0;
            else
                println(val);
            String[] tokens = val.split(" ");
            if (tokens[0].startsWith("Free")) {
                initArduino();
                okCount++;
                nextMsg();
            }

            if (tokens[0].startsWith("ok")) {
                okCount++;
                nextMsg();
            }
        }
    }
    
    public void export(File file){}
}
