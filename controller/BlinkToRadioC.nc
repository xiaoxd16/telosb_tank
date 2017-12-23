#include <Timer.h>
#include "../BlinkToRadio.h"
#include "printf.h"

module BlinkToRadioC {
    uses interface Boot;
    uses interface Leds;
    uses interface Timer<TMilli> as Timer;
    uses interface Timer<TMilli> as TimerAuto;
    uses interface Packet;
    uses interface Receive as JoyStickReceive;
    uses interface Receive as InitializeReceive;
    uses interface SplitControl as AMControl;

    uses interface Car;
}
implementation {
    bool busy = FALSE;

    uint16_t car_op = JOYSTICK_STOP;
    uint16_t steer_angles[3] = {3000, 3000, 3000};
    uint16_t cur_command = 0;
    uint16_t do_op[4] = {0, 0, 0, 0};
    uint16_t auto_test = 0;

    void reset()
    {
        busy = FALSE;
        cur_command = 0;
    }

    uint16_t modify_angle(uint16_t prev, uint16_t stat)
    {
        if (stat == STEER_TURN_UP)
        {
            prev += STEER_ANGLE_DELTA;
            if (prev >= STEER_ANGLE_MAX) prev = STEER_ANGLE_MAX;
        }
        else
        {
            prev -= STEER_ANGLE_DELTA;
            if (prev <= STEER_ANGLE_MIN) prev = STEER_ANGLE_MIN;
        }
        return prev;
    }

    void deal()
    {
        while (cur_command < 4 && !do_op[cur_command]) ++cur_command;
        if (cur_command >= 4)
        {
            reset();
            return;
        }
        printf("cur_command = %u %u %u.\n", cur_command, car_op, do_op[0]);

        if (cur_command == 0)
        {
            if(car_op == JOYSTICK_STOP)
                call Car.pause();
            else if(car_op == JOYSTICK_UP)
                call Car.forward(500);
            else if(car_op == JOYSTICK_DOWN)
                call Car.back(500);
            else if(car_op == JOYSTICK_LEFT)
                call Car.left(500);
            else if(car_op == JOYSTICK_RIGHT)
                call Car.right(500);
        }
        else if (cur_command == 1)
        {
            call Car.turn(0, steer_angles[0]);
        }
        else if (cur_command == 2)
        {
            call Car.turn(1, steer_angles[1]);
        }
        else
        {
            call Car.turn(2, steer_angles[2]);
        }
    }

    event void AMControl.startDone(error_t error)
    {
        if(error == SUCCESS)
        {
            call Timer.startPeriodic(TIMER_LED_MILLI);
            call TimerAuto.startPeriodic(TIMER_LED_AUTO);
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

    event void TimerAuto.fired()
    {
        if (auto_test >= 20)
        {
            return;
        }
        ++auto_test;
        if (auto_test == 2)
        {
            car_op = JOYSTICK_UP;
            call Car.forward(500);
        }
        else if (auto_test == 4)
        {
            car_op = JOYSTICK_DOWN;
            call Car.back(500);
        }
        else if (auto_test == 5)
        {
            car_op = JOYSTICK_LEFT;
            call Car.left(500);
        }
        else if (auto_test == 6)
        {
            car_op = JOYSTICK_RIGHT;
            call Car.right(500);
        }
        else if (auto_test == 7)
        {
            car_op = JOYSTICK_STOP;
            call Car.pause();
        }
        else if (auto_test == 8)
        {
            do_op[1] = 1;
            do_op[2] = 0;
            do_op[3] = 0;
            call Car.turn(0, STEER_ANGLE_MIN);
        }
        else if (auto_test == 9)
        {
            do_op[1] = 1;
            do_op[2] = 0;
            do_op[3] = 0;
            call Car.turn(0, STEER_ANGLE_MAX);
        }
        else if (auto_test == 10)
        {
            do_op[1] = 0;
            do_op[2] = 1;
            do_op[3] = 0;
            call Car.turn(1, STEER_ANGLE_MIN);
        }
        else if (auto_test == 11)
        {
            do_op[1] = 0;
            do_op[2] = 1;
            do_op[3] = 0;
            call Car.turn(1, STEER_ANGLE_MAX);
        }
        else if (auto_test == 12)
        {
            do_op[1] = 1;
            do_op[2] = 1;
            do_op[3] = 1;
            call Car.turn(0, STEER_ANGLE_DEFAULT);
            call Car.turn(1, STEER_ANGLE_DEFAULT);
        }
    }
    event void Timer.fired()
    {
        if (do_op[1] + do_op[2] + do_op[3] == 3)
        {
            call Leds.led0On();
            call Leds.led1On();
            call Leds.led2On();
        }
        else if (do_op[1] == 1)
        {
            call Leds.led0On();
            call Leds.led1On();
            call Leds.led2Off();
        }
        else if (do_op[2] == 1)
        {
            call Leds.led0Off();
            call Leds.led1On();
            call Leds.led2On();
        }
        else if (car_op == JOYSTICK_RIGHT)
        {
            call Leds.led0Off();
            call Leds.led1On();
            call Leds.led2Off();
        }
        else if (car_op == JOYSTICK_LEFT)
        {
            call Leds.led0On();
            call Leds.led1Off();
            call Leds.led2On();
        }
        else if (car_op == JOYSTICK_UP)
        {
            call Leds.led0Toggle();
            call Leds.led1Off();
            call Leds.led2Off();
        }
        else if (car_op == JOYSTICK_DOWN)
        {
            call Leds.led0Off();
            call Leds.led1Off();
            call Leds.led2Toggle();
        }
        else
        {
            call Leds.led0Toggle();
            call Leds.led1Toggle();
            call Leds.led2Toggle();
        }
    }

    event void Car.send_done()
    {
        ++cur_command;
        if (cur_command >= 4)
        {
            reset();
        }
        else
        {
            deal();
        }
    }

    event message_t* JoyStickReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        JoyStickMsg* rcvPayload;

        if(len != sizeof(JoyStickMsg))
        {
            return msg;
        }
        if (busy || auto_test <= 12) return msg;

        rcvPayload = (JoyStickMsg*)payload;
        busy = TRUE;
        cur_command = 0;
        if (car_op == rcvPayload->JoyStickOp)
        {
            do_op[0] = 0;
        }
        else
        {
            do_op[0] = 1;
            car_op = rcvPayload->JoyStickOp;
        }
        if (rcvPayload->Steer1Status == STEER_TURN_NOOP)
        {
            do_op[1] = 0;
        }
        else
        {
            do_op[1] = 1;
            steer_angles[0] = modify_angle(steer_angles[0], rcvPayload->Steer1Status);
        }
        if (rcvPayload->Steer2Status == STEER_TURN_NOOP)
        {
            do_op[2] = 0;
        }
        else
        {
            do_op[2] = 1;
            steer_angles[1] = modify_angle(steer_angles[1], rcvPayload->Steer2Status);
        }
        if (rcvPayload->Steer3Status == STEER_TURN_NOOP)
        {
            do_op[3] = 0;
        }
        else
        {
            do_op[3] = 1;
            steer_angles[2] = modify_angle(steer_angles[2], rcvPayload->Steer3Status);
        }
        printf("angle=%u %u %u, car_op=%u %u %u.\n", steer_angles[0], steer_angles[1], steer_angles[2], car_op, do_op[0], rcvPayload->Steer3Status);
        deal();
        return msg;
    }

    event message_t* InitializeReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        InitializeMsg* rcvPayload;
        if(len != sizeof(InitializeMsg))
        {
            return msg;
        }
        if (busy || auto_test <= 12) return msg;

        rcvPayload = (InitializeMsg*) payload;
        busy = TRUE;
        cur_command = 0;
        car_op = JOYSTICK_STOP;
        do_op[0] = 0;
        do_op[1] = 1;
        do_op[2] = 1;
        do_op[3] = 1;
        steer_angles[0] = rcvPayload->Steer1Angle;
        steer_angles[1] = rcvPayload->Steer2Angle;
        steer_angles[2] = rcvPayload->Steer3Angle;
        deal();
        return msg;
    }
}
