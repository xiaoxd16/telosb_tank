interface Button {
    command void start();
    event void startDone(error_t error);
    command void stop();
    event void stopDone(errot_t error);

    command void getButtonA();
    event void getButtonADone(error_t error);
    command void getButtonB();
    event void getButtonBDone(error_t error);
    command void getButtonC();
    event void getButtonCDone(error_t error);
    command void getButtonD();
    event void getButtonDDone(error_t error);
    command void getButtonE();
    event void getButtonEDone(error_t error);
    command void getButtonF();
    event void getButtonFDone(error_t error);
}
