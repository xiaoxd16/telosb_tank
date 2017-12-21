// $Id: BlinkToRadio.h,v 1.4 2006/12/12 18:22:52 vlahan Exp $

#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
    AM_BLINKTORADIO = 6,
    TIMER_PERIOD_MILLI = 250,

    JOYSTICK_STOP  = 0,
    JOYSTICK_UP    = 1,
    JOYSTICK_DOWN  = 2,
    JOYSTICK_LEFT  = 3,
    JOYSTICK_RIGHT = 4,

    STEER_ANGLE_NOOP    = 0,
    STEER_ANGLE_MIN     = 1800,
    STEER_ANGLE_DEFAULT = 3000,
    STEER_ANGLE_MAX     = 5000
};

typedef nx_struct JoyStickMsg {
    nx_uint16_t JoyStickOp;
    nx_uint16_t Steer1Angle;
    nx_uint16_t Steer2Angle;
    nx_uint16_t Steer3Angle;
}

#endif
