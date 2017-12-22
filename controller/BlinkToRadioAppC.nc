
#include <Timer.h>
//#include "../BlinkToRadio.h"

configuration BlinkToRadioAppC {
}
implementation {
    components MainC, LedsC, ActiveMessageC;
    components new AMReceiverC(0);
    components new TimerMilliC() as Timer;
    components BlinkToRadioC;
    components CarC;

    BlinkToRadioC.Boot -> MainC.Boot;
    BlinkToRadioC.Leds -> LedsC.Leds;
    BlinkToRadioC.Timer -> Timer;
    BlinkToRadioC.Receive -> AMReceiverC.Receive;
    BlinkToRadioC.AMControl -> ActiveMessageC.SplitControl;
    BlinkToRadioC.Packet -> ActiveMessageC.Packet;


}
