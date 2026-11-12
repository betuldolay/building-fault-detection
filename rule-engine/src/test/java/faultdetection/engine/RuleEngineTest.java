package faultdetection.engine;

import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.COOLING_VALVE;
import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.FAN;
import static faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule.HEATING_VALVE;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import faultdetection.rule.EquipmentState;
import faultdetection.rule.Rule;
import faultdetection.rule.ahu.HeatingAndCoolingAtOnceRule;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;

class RuleEngineTest {

    private static final UUID AHU_17_ID = UUID.fromString("a411da66-9110-4230-b8db-87f1782448b4");

    private final Rule rule = new HeatingAndCoolingAtOnceRule();
    private final RuleEngine engine = new RuleEngine();

    @Test
    void findsTheSignalOfTheRule() {
        // the cooling valve open and the fan on all the time; the heating valve is open from 10:15 until 10:45
        List<EquipmentState> states = List.of(
                state("10:00", 0),
                state("10:05", 0),
                state("10:10", 0),
                state("10:15", 40),
                state("10:20", 40),
                state("10:25", 40),
                state("10:30", 40),
                state("10:35", 40),
                state("10:40", 40),
                state("10:45", 0));

        List<Signal> signals = engine.detectFaults(rule, AHU_17_ID, states);

        assertEquals(List.of(new Signal(rule.id(), AHU_17_ID, at("10:15"), at("10:45"))), signals);
    }

    @Test
    void aFaultShorterThanTheRulesMinimumDurationIsNotReported() {
        // the heating valve is open from 10:15 until 10:35: 20 minutes, the rule needs 30
        List<EquipmentState> states = List.of(
                state("10:10", 0),
                state("10:15", 40),
                state("10:20", 40),
                state("10:25", 40),
                state("10:30", 40),
                state("10:35", 0));

        List<Signal> signals = engine.detectFaults(rule, AHU_17_ID, states);

        assertTrue(signals.isEmpty());
    }

    private static EquipmentState state(String time, double heatingValve) {
        return new EquipmentState(at(time), Map.of(HEATING_VALVE, heatingValve, COOLING_VALVE, 60.0, FAN, 1.0));
    }

    private static Instant at(String time) {
        return Instant.parse("2026-11-04T" + time + ":00Z");
    }
}
