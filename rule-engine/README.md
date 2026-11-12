# Rule engine

The core of the Building Fault Detection design, in Java: the **detection** part, where a rule finds the periods
in which a fault holds on one piece of equipment. See section 7 of [the design document](../design-document.md).

## Why this part

The rules and the engine are the core of the product. Everything else either feeds data into it or builds on the
faults it finds. It's also where a rule becomes something you can run and test.

## What it does

```
EquipmentState → Rule → RuleResult → SignalFinder → Signal
                  └───────── RuleEngine.detectFaults ─────────┘
```

1. An **`EquipmentState`** is the values of one piece of equipment at one moment, by tag.
2. A **`Rule`** has an id and says two things: whether the equipment is faulty at that moment, and how long that
   must last.
3. **`RuleEngine`** asks the rule about every state, then **`SignalFinder`** keeps the stretches that last at
   least the rule's minimum duration.
4. Each **`Signal`** says which rule found it, on which equipment, and from when to when, e.g.
   `ahu-heating-and-cooling-at-once` on AHU 17, 10:15 to 10:45. That's what synthesis needs to combine signals into an
   insight.

An example rule, as code: an AHU that heats and cools the air at the same time, wasting energy.

```java
public boolean isFaulty(EquipmentState state) {
    return state.valueByTag(HEATING_VALVE) > VALVE_OPEN_PERCENT    // 10
            && state.valueByTag(COOLING_VALVE) > VALVE_OPEN_PERCENT   // 10
            && state.isOn(FAN);
}

public Duration minimumDuration() {
    return MINIMUM_DURATION;                                  // 30 minutes
}
```

## How to run

Java 21+ and Maven:

```bash
mvn test
```

## Packages

| Package | Contents |
|---|---|
| `rule` | `Rule` and `EquipmentState`: all a developer needs to write a rule |
| `rule.ahu` | the rules for AHUs; other equipment types get their own package |
| `engine` | `RuleEngine` and the steps it uses |

## Choices

- **A rule only states its id, the condition and the duration.** The engine checks the duration, so each rule stays a few
  lines and is tested with one state at a time.
- **Thresholds are constants in the rule,** the same for every building in this version. To make them configurable
  later (e.g. per building), the rule gets its thresholds passed in instead of defining them itself, for example
  from a settings table. The engine doesn't change.
- **One state type for all equipment.** It holds values by tag, so a boiler rule uses the same `EquipmentState` with
  other tags. A new equipment type means new rules, not a new engine.
- **Booleans are stored as 1 and 0.** That keeps one value type. The platform sends `number | boolean`, which is
  converted to 1 or 0 when the states are built from the readings.
- **A fault still going on when the data ends is kept,** ending at the last moment seen.
- **Accuracy is one check.** States are 5 minutes apart, so the end of a period is accurate to 5 minutes. That's
  fine for faults that last hours.
- **No framework.** It's plain Java and JUnit.

## Designed, not built here

To keep this component small, these parts of section 7 of the design aren't in the code:

- **Rules that compare with earlier values,** e.g. "temperature rising for 2 hours" or "more energy than last week".
  This component covers a condition at one moment plus a minimum duration. In the design (section 7.1), a rule can
  also ask for an earlier state and declares how far back it looks. The engine stays the same.
- **Building the states from raw readings:** finding sensors by tag, and filling gaps.
- **Unknown values.** In the design, a moment where a value is missing or too old is *unknown*: never a fault, and
  it ends a stretch. In this component every state is complete, so each moment is just faulty or OK.
- **A rule that crashes.** In the design, it's reported for that rule and equipment, and the other rules keep
  running. In this component, the exception goes up to the caller.
- **Storing signals** and re-running safely.
