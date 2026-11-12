package faultdetection.engine;

import java.time.Instant;
import java.util.UUID;

/**
 * A fault signal: one rule said "faulty" for one piece of equipment, without interruption,
 * for at least the rule's minimum duration.
 *
 * @param ruleId      the rule that found it, e.g. "ahu-heating-and-cooling-at-once"
 * @param equipmentId the equipment it was found on, as in the platform's data
 * @param start       the first moment the rule said "faulty"
 * @param end         the moment it said "OK" again, or the last moment seen if the fault was still going on
 */
public record Signal(String ruleId, UUID equipmentId, Instant start, Instant end) {
}
