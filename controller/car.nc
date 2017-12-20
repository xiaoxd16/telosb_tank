// car interface

interface Car
{
    command void start();
    command uint8_t turn(uint8_t number, uint16_t angle);
    command uint8_t forward(uint16_t speed);
    command uint8_t back(uint16_t speed);
    command uint8_t left(uint16_t speed);
    command uint8_t right(uint16_t speed);
    command uint8_t pause();
}

