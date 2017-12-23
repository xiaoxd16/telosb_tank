#include <Timer.h>
#include "../BlinkToRadio.h"
configuration BlinkToRadioAppC {
}
implementation {
    components MainC, LedsC, ActiveMessageC;
    components new AMReceiverC(AM_JOYSTICKMSG) as JoyStickeReceiver;
    components new AMReceiverC(AM_INITIALIZEMSG) as InitializeReceiver;
    components new TimerMilliC() as Timer;
    components new TimerMilliC() as TimerAuto;
    components BlinkToRadioC;
    components CarC;

    BlinkToRadioC.Boot -> MainC.Boot;
    BlinkToRadioC.Leds -> LedsC.Leds;
    BlinkToRadioC.Timer -> Timer;
    BlinkToRadioC.TimerAuto -> TimerAuto;
    BlinkToRadioC.JoyStickReceive -> JoyStickeReceiver.Receive;
    BlinkToRadioC.InitializeReceive -> InitializeReceiver.Receive;
    BlinkToRadioC.AMControl -> ActiveMessageC.SplitControl;
    BlinkToRadioC.Packet -> ActiveMessageC.Packet;

    BlinkToRadioC.Car -> CarC.Car;
}
