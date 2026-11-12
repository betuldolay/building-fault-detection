package faultdetection.rule;

import java.time.Duration;

/**
 * A fault rule: a condition at one moment, and how long it must hold to count as a fault.
 */
public interface Rule {

    /**
     * Unique id of the rule, e.g. "ahu-heating-and-cooling-at-once". Every signal carries it, so it must never change.
     */
    String id();

    /**
     * True if the values at this moment show the fault.
     */
    boolean isFaulty(EquipmentState state);

    /**
     * How long the condition must hold without interruption, e.g. 30 minutes.
     */
    Duration minimumDuration();
}
