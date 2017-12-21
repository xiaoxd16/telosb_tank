generic module JoyStickP {
    provides {
        interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure1;
        interface AdcConfigure<const msp430adc12_channel_config_t*> as AdcConfigure2;
    }
}

implementation {
    const msp430adc12_channel_config_t config1 = {
        inch: INPUT_CHANNEL_A6,
        sref: REFERENCE_VREFplus_AVss,
        ref2_5v: REFVOLT_LEVEL_2_5,
        adc12ssel: SHT_SOURCE_ACLK,
        adc12div: SHT_CLOCK_DIV_1,
        sht: SAMPLE_HOLD_4_CYCLES,
        sampcon_ssel: SAMPCON_SOURCE_SMCLK,
        sampcon_id: SAMPCON_CLOCK_DIV_1
    }

    const msp430adc12_channel_config_t config2 = {
        inch: INPUT_CHANNEL_A7,
        sref: REFERENCE_VREFplus_AVss,
        ref2_5v: REFVOLT_LEVEL_2_5,
        adc12ssel: SHT_SOURCE_ACLK,
        adc12div: SHT_CLOCK_DIV_1,
        sht: SAMPLE_HOLD_4_CYCLES,
        sampcon_ssel: SAMPCON_SOURCE_SMCLK,
        sampcon_id: SAMPCON_CLOCK_DIV_1
    }

    async command const msp430adc12_channel_config_t* AdcConfigure1.getConfiguration() {
        return &config1;
    }

    async command const msp430adc12_channel_config_t* AdcConfigure2.getConfiguration() {
        return &config2;
    }
}
