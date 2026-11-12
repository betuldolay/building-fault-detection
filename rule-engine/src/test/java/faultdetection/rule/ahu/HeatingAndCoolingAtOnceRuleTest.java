package faultdetection.rule.ahu;

import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.COOLING_VALVE;
import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.FAN;
import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.HEATING_VALVE;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import faultdetection.rule.EquipmentState;
import faultdetection.rule.Rule;

import java.time.Instant;
import java.util.Map;

import org.junit.jupiter.api.Test;

class HeatingAndCoolingAtOnceRuleTest {

    private static final Instant TEN_O_CLOCK = Instant.parse("2026-11-04T10:00:00Z");

    private final Rule rule = new HeatingAndCoolingAtOnceRule();

    @Test
    void heatingAndCoolingWithFanOnIsFaulty() {
        EquipmentState state = state(40.0, 60.0, 1.0);

        assertTrue(rule.isFaulty(state));
    }

    @Test
    void onlyHeatingIsFine() {
        EquipmentState state = state(40.0, 0.0, 1.0);

        assertFalse(rule.isFaulty(state));
    }

    @Test
    void onlyCoolingIsFine() {
        EquipmentState state = state(0.0, 60.0, 1.0);

        assertFalse(rule.isFaulty(state));
    }

    @Test
    void heatingAndCoolingWithFanOffIsFine() {
        EquipmentState state = state(40.0, 60.0, 0.0);

        assertFalse(rule.isFaulty(state));
    }

    @Test
    void heatingValveExactlyTenPercentOpenIsFine() {
        // "more than 10%": 10 itself is not faulty
        EquipmentState state = state(10.0, 60.0, 1.0);

        assertFalse(rule.isFaulty(state));
    }

    @Test
    void coolingValveExactlyTenPercentOpenIsFine() {
        // "more than 10%": 10 itself is not faulty
        EquipmentState state = state(40.0, 10.0, 1.0);

        assertFalse(rule.isFaulty(state));
    }

    private static EquipmentState state(double heatingValve, double coolingValve, double fan) {
        Map<String, Double> valuesByTag = Map.of(HEATING_VALVE, heatingValve, COOLING_VALVE, coolingValve, FAN, fan);
        return new EquipmentState(TEN_O_CLOCK, valuesByTag);
    }
}
