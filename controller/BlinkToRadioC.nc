
#include <Timer.h>
#include "BlinkToRadio.h"

module BlinkToRadioC {
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface Receive;
    uses interface SplitControl as AMControl;

    uses interface Car;
}
implementation {
    event void AMControl.startDone(error_t error)
    {

    }
    event void AMControl.stopDone(error_t error)
    {

    }
    event void Boot.booted()
    {

    }
    event void Timer.fired()
    {

    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
    {
        return NULL;
    }
}
