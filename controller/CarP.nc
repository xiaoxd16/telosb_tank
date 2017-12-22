// car module
#include <msp430usart.h>

module CarP{
    provides interface Car;
    uses interface Resource;
    uses interface HplMsp430Usart;
    //uses interface HplMsp430UsartInterrupts;
}

implementation{
    // DEFINE STATES AND CONSTANTS
    enum {
        BUFFER_SIZE = 8,
    };
    msp430_uart_union_config_t config = {
        {
            utxe: 1,
            urxe: 1,
            ubr: UBR_1MHZ_115200,
            umctl: UMCTL_1MHZ_115200,
            ssel: 0x02,
            pena: 0,
            pev: 0,
            spb: 0,
            clen: 1,
            listen: 0,
            mm: 0,
            ckpl: 0,
            urxse: 0,
            urxeie: 0,
            urxwie: 0,
            utxe: 1,
            urxe: 1
        }
    };

    uint8_t busy = 0;
    uint8_t buffer[BUFFER_SIZE];
    uint8_t bufferPos = 0;

    uint8_t current_control_byte = 0;
    uint8_t current_data_byte_high = 0;
    uint8_t current_data_byte_low = 0;

    void send_buffer()
    {
        call HplMsp430Usart.tx(buffer[bufferPos]);
        while(!(call HplMsp430Usart.isTxEmpty()));
        bufferPos += 1;
    }

    void send_full_instruction()
    {
        int i = 0;
        for(i = 0; i < BUFFER_SIZE; i++)
        {
            send_buffer();
        }
        bufferPos  =  0;
    }

    void set_header_and_trailer()
    {
        atomic{
            buffer[0] = 0x01;
            buffer[1] = 0x02;
            buffer[5] = 0xff;
            buffer[6] = 0xff;
            buffer[7] = 0x00;
        }
    }

    uint8_t pre_send(uint8_t control_byte, uint8_t data_byte_high, uint8_t data_byte_low)
    {
        if(busy == 1)
            return EBUSY;

        set_header_and_trailer();
        atomic {
            busy = 1;
            current_control_byte = control_byte;
            current_data_byte_high = data_byte_high;
            current_data_byte_low = data_byte_low;
        }

        return call Resource.request();
    }

    event void Resource.granted()
    {
        call HplMsp430Usart.setModeUart(&config);
        call HplMsp430Usart.enableUart();
        atomic U0CTL &= ~SYNC;

        buffer[2] = current_control_byte;
        buffer[3] = current_data_byte_high;
        buffer[4] = current_data_byte_low;

        send_full_instruction();

        call Resource.release();
        busy = 0;
    }

    command uint8_t Car.turn(uint8_t number, uint16_t angle)
    {
        uint8_t low = angle & 0x00FF;
        uint8_t high = angle >> 8;
        if(number == 0)
            return pre_send(0x01, high, low);
        else if(number == 1)
            return pre_send(0x07, high, low);
        else if(number == 2)
            return pre_send(0x08, high, low);

    }

    command uint8_t Car.forward(uint16_t speed)
    {
        uint8_t low = speed & 0x00FF;
        uint8_t high = speed >> 8;
        return pre_send(0x02, high, low);
    }

    command uint8_t Car.back(uint16_t speed)
    {
        uint8_t low = speed & 0x00FF;
        uint8_t high = speed >> 8;
        return pre_send(0x03, high, low);
    }

    command uint8_t Car.left(uint16_t speed)
    {
        uint8_t low = speed & 0x00FF;
        uint8_t high = speed >> 8;
        return pre_send(0x04, high, low);
    }

    command uint8_t Car.right(uint16_t speed)
    {
        uint8_t low = speed & 0x00FF;
        uint8_t high = speed >> 8;
        return pre_send(0x05, high, low);
    }

    command uint8_t Car.pause()
    {
        return pre_send(0x06, 0x00, 0x00);
    }
}
