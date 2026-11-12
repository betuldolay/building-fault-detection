package faultdetection.rule;

import java.time.Instant;
import java.util.Map;

/**
 * The values of one piece of equipment at one moment, by tag.
 * Booleans are stored as numbers: 1 means true (e.g. fan on), 0 means false.
 *
 * @param time the moment these values belong to
 */
public record EquipmentState(Instant time, Map<String, Double> valuesByTag) {

    /**
     * The value of this tag. Fails if the tag has no value.
     */
    public double valueByTag(String tag) {
        Double value = valuesByTag.get(tag);
        if (value == null) {
            throw new IllegalArgumentException("No value for " + tag);
        }
        return value;
    }

    /**
     * True if this tag's value is not 0, e.g. the fan is running. Fails if the tag has no value.
     */
    public boolean isOn(String tag) {
        return valueByTag(tag) != 0;
    }
}
