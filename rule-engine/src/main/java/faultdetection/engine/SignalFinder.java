package faultdetection.engine;

import faultdetection.rule.Rule;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Finds the stretches where a rule was faulty for at least its minimum duration.
 */
class SignalFinder {

    /**
     * @param results the rule's answers for one piece of equipment, sorted by time
     */
    List<Signal> find(Rule rule, UUID equipmentId, List<RuleResult> results) {
        List<Signal> signals = new ArrayList<>();
        Instant start = null;   // null = not in a faulty stretch

        for (RuleResult result : results) {
            if (result.faulty() && start == null) {
                start = result.time();                                               // a faulty stretch begins
            }
            if (!result.faulty() && start != null) {
                addIfLongEnough(signals, rule, equipmentId, start, result.time());   // the stretch ends here
                start = null;
            }
        }

        // still in a faulty stretch when the data ends?
        if (start != null) {
            addIfLongEnough(signals, rule, equipmentId, start, results.getLast().time());
        }
        return signals;
    }

    /**
     * Adds a signal for this stretch if it lasted at least the rule's minimum duration.
     */
    private static void addIfLongEnough(List<Signal> signals, Rule rule, UUID equipmentId, Instant start, Instant end) {
        if (Duration.between(start, end).compareTo(rule.minimumDuration()) >= 0) {
            signals.add(new Signal(rule.id(), equipmentId, start, end));
        }
    }
}
