package faultdetection.engine;

import java.time.Instant;

/**
 * The rule's answer at one time: faulty or not.
 */
record RuleResult(Instant time, boolean faulty) {
}
