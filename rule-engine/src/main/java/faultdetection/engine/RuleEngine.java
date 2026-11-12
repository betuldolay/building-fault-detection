package faultdetection.engine;

import faultdetection.rule.EquipmentState;
import faultdetection.rule.Rule;

import java.util.List;
import java.util.UUID;

/**
 * Runs a rule over the states of one piece of equipment and returns its fault signals.
 */
public class RuleEngine {

    private final SignalFinder signalFinder = new SignalFinder();

    /**
     * @param equipmentId the equipment the states belong to
     * @param states      the states of that equipment, sorted by time
     */
    public List<Signal> detectFaults(Rule rule, UUID equipmentId, List<EquipmentState> states) {
        // ask the rule at every moment
        List<RuleResult> results = states.stream()
                .map(state -> new RuleResult(state.time(), rule.isFaulty(state)))
                .toList();

        // keep the stretches that last at least as long as the rule says
        return signalFinder.find(rule, equipmentId, results);
    }
}
