#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
    AM_JOYSTICKMSG   = 6,
    AM_INITIALIZEMSG = 7,

    TIMER_PERIOD_MILLI = 50,
    TIMER_LED_MILLI = 100,
    TIMER_LED_AUTO = 2000,

    JOYSTICK_STOP  = 0,
    JOYSTICK_UP    = 1,
    JOYSTICK_DOWN  = 2,
    JOYSTICK_LEFT  = 3,
    JOYSTICK_RIGHT = 4,

    STEER_ANGLE_MIN     = 1500,
    STEER_ANGLE_DEFAULT = 3000,
    STEER_ANGLE_MAX     = 4800,

    STEER_ANGLE_DELTA   = 300,

    STEER_TURN_NOOP = 0,
    STEER_TURN_DOWN = 1,
    STEER_TURN_UP   = 2,

    NO_INSTRUCTION = 0,
    JOYSTICK_INSTRUCTION = 1,
    INITIALIZE_INSTRUCTION = 2,

    CAR_ID = 9
};

typedef nx_struct JoyStickMsg {
    nx_uint16_t JoyStickOp;
    nx_uint16_t Steer1Status;
    nx_uint16_t Steer2Status;
    nx_uint16_t Steer3Status;
} JoyStickMsg;

typedef nx_struct InitializeMsg {
    nx_uint16_t Steer1Angle;
    nx_uint16_t Steer2Angle;
    nx_uint16_t Steer3Angle;
} InitializeMsg;

#endif
