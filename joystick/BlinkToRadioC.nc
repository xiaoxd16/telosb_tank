#include <Timer.h>
#include "../BlinkToRadio.h"
#include "printf.h"

module BlinkToRadioC {
    uses interface Boot;
    uses interface Timer<TMilli> as Timer;
    uses interface Packet as PacketJoystick;
    uses interface Packet as PacketInitialize;
    uses interface AMSend as AMSendJoystick;
    uses interface AMSend as AMSendInitialize;
    uses interface SplitControl as AMControl;

    uses interface Button;
    uses interface Read<uint16_t> as ReadJoyStickX;
    uses interface Read<uint16_t> as ReadJoyStickY;

    uses interface Leds;
}

implementation {
    message_t pktJoystick;
    message_t pktInitialize;

    JoyStickMsg* msgJoystick = NULL;
    InitializeMsg* msgInitialize = NULL;

    bool busy = FALSE;
    bool initialSend = FALSE;
    uint16_t initialCD = 10;

    uint16_t joyX;
    uint16_t joyY;
    uint16_t btA;
    uint16_t btB;
    uint16_t btC;
    uint16_t btD;
    uint16_t btE;
    uint16_t btF;

    event void Boot.booted() {
        call AMControl.start();
    }

    event void AMControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call Button.start();
        }
        else {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err) {

    }

    event void Button.startDone() {
        call Timer.startPeriodic(TIMER_PERIOD_MILLI);
    }

    event void Timer.fired() {
        call Leds.led0Toggle();
        if (!busy)
        {
            if (!initialSend) {
                // reset
                do {
                    msgInitialize = (InitializeMsg*)(call PacketInitialize.getPayload(&pktInitialize, sizeof(InitializeMsg)));
                } while (msgInitialize == NULL);
                msgInitialize->Steer1Angle = STEER_ANGLE_DEFAULT;
                msgInitialize->Steer2Angle = STEER_ANGLE_DEFAULT;
                msgInitialize->Steer3Angle = STEER_ANGLE_DEFAULT;
                if (call AMSendInitialize.send(CAR_ID, &pktInitialize, sizeof(InitializeMsg)) == SUCCESS) {
                    initialCD = 10;
                    busy = TRUE;
                    call Leds.led1Toggle();
                }
            }
            else {
                if (initialCD != 0) {
                    --initialCD;
                }
                else {
                    msgJoystick = (JoyStickMsg*)(call PacketJoystick.getPayload(&pktJoystick, sizeof(JoyStickMsg)));
                    if (msgJoystick == NULL) {
                        return;
                    }
                    call ReadJoyStickX.read();
                }
            }
        }
    }

    event void ReadJoyStickX.readDone(error_t err, uint16_t val) {
        if (err == SUCCESS) {
            joyX = val;
            call ReadJoyStickY.read();
        }
        else
        {
            call ReadJoyStickX.read();
        }
    }

    event void ReadJoyStickY.readDone(error_t err, uint16_t val) {
        if (err == SUCCESS) {
            joyY = val;
            call Button.getButtonA();
        }
        else
        {
            call ReadJoyStickY.read();
        }
    }

    event void Button.getButtonADone(bool isHighPin) {
        btA = isHighPin;
        call Button.getButtonB();
    }

    event void Button.getButtonBDone(bool isHighPin) {
        btB = isHighPin;
        call Button.getButtonC();
    }

    event void Button.getButtonCDone(bool isHighPin) {
        btC = isHighPin;
        call Button.getButtonD();
    }

    event void Button.getButtonDDone(bool isHighPin) {
        btD = 1 - isHighPin;
        call Button.getButtonE();
    }

    event void Button.getButtonEDone(bool isHighPin) {
        btE = isHighPin;
        call Button.getButtonF();
    }

    event void Button.getButtonFDone(bool isHighPin) {
        btF = isHighPin;
        //printf("%u %u %u %u %u %u.\n", btA, btB, btC, btD, btE, btF);

        if (!btA && !btB) {
            // reset
            do {
                msgInitialize = (InitializeMsg*)(call PacketInitialize.getPayload(&pktInitialize, sizeof(InitializeMsg)));
            } while (msgInitialize == NULL);
            msgInitialize->Steer1Angle = STEER_ANGLE_DEFAULT;
            msgInitialize->Steer2Angle = STEER_ANGLE_DEFAULT;
            msgInitialize->Steer3Angle = STEER_ANGLE_DEFAULT;
            if (call AMSendInitialize.send(CAR_ID, &pktInitialize, sizeof(InitializeMsg)) == SUCCESS) {
                initialCD = 10;
                busy = TRUE;
                call Leds.led1Toggle();
            }
            return;
        }

        if (btA ^ btB) {
            if (!btA) {
                msgJoystick->Steer1Status = STEER_TURN_DOWN;
            }
            else {
                msgJoystick->Steer1Status = STEER_TURN_UP;
            }
        }
        else {
            msgJoystick->Steer1Status = STEER_TURN_NOOP;
        }

        if (btE ^ btF) {
            if (!btE) {
                msgJoystick->Steer2Status = STEER_TURN_DOWN;
            }
            else {
                msgJoystick->Steer2Status = STEER_TURN_UP;
            }
        }
        else {
            msgJoystick->Steer2Status = STEER_TURN_NOOP;
        }

        if (btC ^ btD) {
            if (!btC) {
                msgJoystick->Steer3Status = STEER_TURN_DOWN;
            }
            else {
                msgJoystick->Steer3Status = STEER_TURN_UP;
            }
        }
        else {
            msgJoystick->Steer3Status = STEER_TURN_NOOP;
        }

        if (joyX > joyY) {
            if (joyX <= 0xA00 && joyY >= 0x600) {
                msgJoystick->JoyStickOp = JOYSTICK_STOP;
            }
            else if (joyX + joyY >= 0x1000) {
                msgJoystick->JoyStickOp = JOYSTICK_DOWN;
            }
            else {
                msgJoystick->JoyStickOp = JOYSTICK_LEFT;
            }
        }
        else {
            if (joyX >= 0x600 && joyY <= 0xA00) {
                msgJoystick->JoyStickOp = JOYSTICK_STOP;
            }
            else if (joyX + joyY >= 0x1000) {
                msgJoystick->JoyStickOp = JOYSTICK_RIGHT;
            }
            else {
                msgJoystick->JoyStickOp = JOYSTICK_UP;
            }
        }

        if (call AMSendJoystick.send(CAR_ID, &pktJoystick, sizeof(JoyStickMsg)) == SUCCESS) {
            busy = TRUE;
            call Leds.led2Toggle();
        }
    }

    event void AMSendJoystick.sendDone(message_t* msg, error_t err)
    {
        if (&pktJoystick == msg) {
            busy = FALSE;
            call Leds.led2Toggle();
        }
    }

    event void AMSendInitialize.sendDone(message_t* msg, error_t err)
    {
        if (&pktInitialize == msg) {
            busy = FALSE;
            initialSend = TRUE;
            call Leds.led1Toggle();
        }
    }
}
