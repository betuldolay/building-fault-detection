package faultdetection.rule.ahu;

import faultdetection.rule.EquipmentState;
import faultdetection.rule.Rule;

import java.time.Duration;

/**
 * Example rule: an AHU heats and cools the air at the same time while it is running, for at least 30 minutes.
 * Both valves are more than 10% open, so the heating and the cooling work against each other and waste energy.
 */
public class HeatingAndCoolingAtOnceRule implements Rule {

    // Tags of the inputs (illustrative; real rules use the platform's tag vocabulary)
    public static final String HEATING_VALVE = "heatingValveCmd";
    public static final String COOLING_VALVE = "coolingValveCmd";
    public static final String FAN = "fanRunCmd";

    // Thresholds: the same for every building in this version
    private static final double VALVE_OPEN_PERCENT = 10;
    private static final Duration MINIMUM_DURATION = Duration.ofMinutes(30);

    @Override
    public String id() {
        return "ahu-heating-and-cooling-at-once";
    }

    @Override
    public boolean isFaulty(EquipmentState state) {
        return state.valueByTag(HEATING_VALVE) > VALVE_OPEN_PERCENT
                && state.valueByTag(COOLING_VALVE) > VALVE_OPEN_PERCENT
                && state.isOn(FAN);
    }

    @Override
    public Duration minimumDuration() {
        return MINIMUM_DURATION;
    }
}
