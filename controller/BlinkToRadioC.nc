
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
    enum {
        NO_INSTRUCTION = 0,
        JOYSTICK_INSTRUCTION = 1,
        INITIALIZE_INSTRUCTION = 2,
    };
    enum {
        TIME_PERIOD = 100;
    }
    enum {
        STATE_STOP = 0,
        STATE_UP = 1,
        STATE_DOWN = 2,
        STATE_LEFT = 3,
        STATE_RIGHT = 4,
        STATE_NOOP = 5
    }
    // which type of instruction is now being send?
    uint8_t current_instruction_num = NO_INSTRUCTION;

    // which part of instruction is being send?
    // (Since a JoyStickMsg may lead to 4 instructions)
    uint8_t current_instruction_pos = 0;

    // save recevied message here
    nx_struct JoyStickMsg current_joystick_msg;
    nx_struct InitializeMsg current_initialize_msg;

    uint16_t steer_angles[3] = {0, 0, 0};

    uint8_t led_status = STATE_NOOP;
    uint8_t status_just_changed = 0;

    // return:
    // 1 -- if the angle is changed
    // 0 -- if the angle is not changed(so no need to send an instruction)
    uint8_t update_angle(uint8_t num, nx_uint16_t status)
    {
        uint16_t temp = steer_angles[num];
        if(status == STEER_TURN_UP)
        {
            if(temp == STEER_ANGLE_MAX)
                return 0;
            temp += STEER_ANGLE_DELTA;
            steer_angles[num] = temp > STEER_ANGLE_MAX ? STEER_ANGLE_MAX : temp;
            return 1;
        }
        else if(status == STEER_TURN_DOWN)
        {
            if(temp == STEER_ANGLE_MIN)
                return 0;
            temp -= STEER_ANGLE_DELTA;
            steer_angles[num] = temp < STEER_ANGLE_MIN ? STEER_ANGLE_MIN : temp;
            return 1;
        }
        else if(status == STEER_TURN_NOOP)
        {
            return 0;
        }
        return 0;
    }

    void after_message_processed()
    {
        atomic {
            current_instruction_pos = 0;
            current_instruction_num = NO_INSTRUCTION;
        }
    }

    void send_control_instruction(nx_uint16_t op)
    {
        if(op == JOYSTICK_STOP)
            call Car.pause();
        else if(op == JOYSTICK_UP)
            call Car.forward(500);
        else if(op == JOYSTICK_DOWN)
            call Car.back(500);
        else if(op == JOYSTICK_LEFT)
            call Car.left(500);
        else if(op == JOYSTICK_RIGHT)
            call Car.right(500);
        led_status = op;
        status_just_changed = 1;
    }

    void send_joystick_instruction()
    {
        if(current_instruction_num == JOYSTICK_INSTRUCTION)
        {
            while(current_instruction_pos < 4)
            {
                uint8_t updated = 0;
                if(current_instruction_pos == 1)
                {
                    updated = update_angle(1, current_joystick_msg.Steer1Status);
                }
                else if(current_instruction_pos == 2)
                {
                    updated = update_angle(2, current_joystick_msg.Steer2Status);
                }
                else if(current_instruction_pos == 3)
                {
                    updated = update_angle(3, current_joystick_msg.Steer3Status);
                }

                if(updated == 1)
                {
                    call Car.turn(current_instruction_pos,
                                  steer_angles[current_instruction_pos]);
                    break;
                }
                current_instruction_pos += 1;
            }
            if(current_instruction_pos == 4)
            {
                after_message_processed();
            }
        }
        else if(current_instruction_num == INITIALIZE_INSTRUCTION)
        {
            if(current_instruction_pos == 0)
                call Car.turn(1, current_initialize_msg.Steer1Angle);
            else if(current_instruction_pos == 1)
                call Car.turn(2, current_initialize_msg.Steer2Angle);
            else if(current_instruction_pos == 2)
                call Car.turn(3, current_initialize_msg.Steer2Angle);
        }
    }

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
        if(current_instruction_num != NO_INSTRUCTION)
            return;
        if(led_status == STATE_NOOP)
            return;
        else if(led_status == STATE_LEFT)
            call Leds.led0Toggle();
        else if(led_status == STATE_RIGHT)
            call Leds.led2Toggle();
        else if(led_status == STATE_UP)
        {
            if(status_just_changed == 1)
            {
                call Leds.led0On();
                call Leds.led1On();
                call Leds.led0Off();
                status_just_changed = 0;
            }
            else
            {
                call Leds.led0Toggle();
                call Leds.led2Toggle();
            }
        }
        else if(led_status == STATE_DOWN)
        {
            if(status_just_changed == 1)
            {
                call Leds.led0On();
                call Leds.led1Off();
                call Leds.led2On();
                status_just_changed = 0;
            }
            else
            {
                call Leds.led0Toggle();
                call Leds.led2Toggle();
            }
        }

    }

    event void Car.send_done()
    {
        current_instruction_pos += 1;
        if(current_instruction_num == JOYSTICK_INSTRUCTION
            && current_instruction_pos == 4)
            after_message_processed();
        else if(current_instruction_num == INITIALIZE_INSTRUCTION
            && current_instruction_pos == 3)
            after_message_processed();
        else
            send_joystick_instruction();
    }

    event message_t* JoyStickReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        JoyStickMsg* rcvPayload;
        nx_uint16_t op;
        if(len != sizeof(JoyStickMsg))
        {
            return NULL;
        }

        rcvPayload = (JoyStickMsg*)payload;
        if(current_instruction_num == NO_INSTRUCTION)
        {
            current_instruction_num = JOYSTICK_INSTRUCTION;
            atomic {
                current_joystick_msg.JoyStickOp = rcvPayload->JoyStickOp;
                current_joystick_msg.Steer1Status = rcvPayload->Steer1Status;
                current_joystick_msg.Steer2Status = rcvPayload->Steer2Status;
                current_joystick_msg.Steer3Status = rcvPayload->Steer3Status;
            }

            op = rcvPayload->JoyStickOp;
            send_control_instruction(op);
        }
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
        if(current_instruction_num == NO_INSTRUCTION)
        {
            current_instruction_num = INITIALIZE_INSTRUCTION;
            atomic {
                current_initialize_msg.Steer1Angle = rcvPayload->Steer1Angle;
                current_initialize_msg.Steer2Angle = rcvPayload->Steer2Angle;
                current_initialize_msg.Steer3Angle = rcvPayload->Steer3Angle;
            }

            send_joystick_instruction();
        }
        return msg;
    }
}
