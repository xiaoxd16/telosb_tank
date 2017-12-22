#include <Timer.h>
#include "../BlinkToRadio.h"

configuration BlinkToRadioAppC {

}

implementation {
    components MainC;
    components BlinkToRadioC as App;
    components new TimerMilliC() as Timer;
    components ActiveMessageC;
    components new AMSenderC(AM_JOYSTICKMSG) as AMSenderC_1;
    components new AMSenderC(AM_INITIALIZEMSG) as AMSenderC_2;
    components ButtonC;
    components JoyStickC;

    App.Boot -> MainC;
    App.Timer -> Timer;
    App.PacketJoystick -> AMSenderC_1;
    App.PacketInitialize -> AMSenderC_2;
    App.AMControl -> ActiveMessageC;
    App.AMSendJoystick -> AMSenderC_1;
    App.AMSendInitialize -> AMSenderC_2;
    App.Button -> ButtonC;
    App.ReadJoyStickX -> JoyStickC.ReadJoyStickX;
    App.ReadJoyStickY -> JoyStickC.ReadJoyStickY;
}
