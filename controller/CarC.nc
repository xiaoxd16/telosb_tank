// car configuration

configuration CarC{
    provides interface Car;
}

implementation{
    components CarP;
    components new Msp430Uart0C();
    components HplMsp430Usart0C;

    Car = CarP.Car;
    CarP.Resource -> Msp430Uart0C.Resource;
    CarP.HplMsp430Usart -> HplMsp430Usart0C.HplMsp430Usart;
}
