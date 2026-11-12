package faultdetection.engine;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import faultdetection.rule.EquipmentState;
import faultdetection.rule.Rule;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;

class SignalFinderTest {

    /**
     * The id of AHU 17, the equipment in these tests.
     */
    private static final UUID AHU_17_ID = UUID.fromString("a411da66-9110-4230-b8db-87f1782448b4");

    /**
     * A rule for these tests only, so they don't depend on a real rule's settings.
     * SignalFinder only uses its id and minimum duration, so the condition is never asked.
     */
    private record TestRule(String id, Duration minimumDuration) implements Rule {

        @Override
        public boolean isFaulty(EquipmentState state) {
            return false;
        }
    }

    private static final Rule TEST_RULE = new TestRule("test-rule", Duration.ofMinutes(30));

    private final SignalFinder finder = new SignalFinder();

    @Test
    void keepsOnlyStretchesOfAtLeastThirtyMinutes() {
        List<RuleResult> results = List.of(
                faulty("10:00"),
                faulty("10:05"),
                ok("10:10"),          // 10:00 - 10:10 is only 10 minutes: dropped
                faulty("10:15"),
                faulty("10:20"),
                faulty("10:25"),
                faulty("10:30"),
                faulty("10:35"),
                faulty("10:40"),
                ok("10:45"));         // 10:15 - 10:45 is 30 minutes: kept

        List<Signal> signals = finder.find(TEST_RULE, AHU_17_ID, results);

        assertEquals(List.of(signal("10:15", "10:45")), signals);
    }

    @Test
    void usesTheRulesOwnMinimumDuration() {
        List<RuleResult> results = List.of(
                faulty("10:00"),
                faulty("10:05"),
                ok("10:10"));         // a 10-minute fault

        Rule tenMinuteRule = new TestRule("ten-minute-rule", Duration.ofMinutes(10));

        List<Signal> tenMinuteSignals = finder.find(tenMinuteRule, AHU_17_ID, results);
        List<Signal> thirtyMinuteSignals = finder.find(TEST_RULE, AHU_17_ID, results);

        assertEquals(List.of(new Signal("ten-minute-rule", AHU_17_ID, at("10:00"), at("10:10"))), tenMinuteSignals);
        assertTrue(thirtyMinuteSignals.isEmpty());      // too short for the 30-minute rule
    }

    @Test
    void findsEverySeparateFault() {
        List<RuleResult> results = List.of(
                faulty("10:00"),
                faulty("10:15"),
                faulty("10:30"),
                ok("10:45"),          // first fault: 10:00 - 10:45
                faulty("11:00"),
                faulty("11:15"),
                ok("11:30"));         // second fault: 11:00 - 11:30

        List<Signal> signals = finder.find(TEST_RULE, AHU_17_ID, results);

        assertEquals(List.of(signal("10:00", "10:45"), signal("11:00", "11:30")), signals);
    }

    @Test
    void aFaultStillGoingOnWhenTheDataEndsIsKept() {
        List<RuleResult> results = List.of(
                ok("10:10"),
                faulty("10:15"),
                faulty("10:20"),
                faulty("10:25"),
                faulty("10:30"),
                faulty("10:35"),
                faulty("10:40"),
                faulty("10:45"),
                faulty("10:50"));     // the data ends here, still faulty

        List<Signal> signals = finder.find(TEST_RULE, AHU_17_ID, results);

        assertEquals(List.of(signal("10:15", "10:50")), signals);
    }

    @Test
    void neverFaultyGivesNoSignals() {
        List<RuleResult> results = List.of(ok("10:00"), ok("10:05"), ok("10:10"));

        assertTrue(finder.find(TEST_RULE, AHU_17_ID, results).isEmpty());
    }

    @Test
    void noDataGivesNoSignals() {
        assertTrue(finder.find(TEST_RULE, AHU_17_ID, List.of()).isEmpty());
    }

    private static RuleResult faulty(String time) {
        return new RuleResult(at(time), true);
    }

    private static RuleResult ok(String time) {
        return new RuleResult(at(time), false);
    }

    private static Signal signal(String start, String end) {
        return new Signal(TEST_RULE.id(), AHU_17_ID, at(start), at(end));
    }

    private static Instant at(String time) {
        return Instant.parse("2026-11-04T" + time + ":00Z");
    }
}
