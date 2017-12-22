
#include <Timer.h>
#include "../BlinkToRadio.h"

module BlinkToRadioC {
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet;
    uses interface Receive as JoyStickReceive;
    uses interface Receive as InitializeReceive;
    uses interface SplitControl as AMControl;

    uses interface Car;
}
implementation {
    event void AMControl.startDone(error_t error)
    {
        if(error == SUCCESS)
        {

        }
        else
        {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t error)
    {
        //DO NOTHING HERE
    }

    event void Boot.booted()
    {
        call AMControl.start();
    }

    event void Timer.fired()
    {

    }

    event message_t* JoyStickReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        JoyStickMsg* rcvPayload;
        if(len != sizeof(JoyStickMsg))
        {
            return NULL;
        }

        rcvPayload = (JoyStickMsg*)payload;
        // todo;
        return msg;
    }

    event message_t* InitializeReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        InitializeMsg* rcvPayload;
        if(len != sizeof(InitializeMsg))
        {
            return NULL;
        }
        rcvPayload = (InitializeMsg*) payload;
        // todo;
        return msg;
    }
}
