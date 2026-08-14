using namespace CometEngine;

/// <summary>
/// Collects the results of one Tweeny test run. Checks never abort: a failing check is recorded and
/// execution continues, so a single run reports every problem instead of only the first one.
/// </summary>
class TweenyTestContext
{
    private array<string> failureLines;
    private array<string> suiteLines;
    private int checkCount = 0;
    private int failureCount = 0;
    private int suiteCount = 0;
    private string suiteName = "";
    private string caseName = "";
    private int suiteFailuresAtStart = 0;
    private int suiteChecksAtStart = 0;

    /// <summary>
    /// The total number of checks executed so far.
    /// </summary>
    int checks { get const { return checkCount; } }

    /// <summary>
    /// The total number of failed checks so far.
    /// </summary>
    int failures { get const { return failureCount; } }

    /// <summary>
    /// Starts a named suite. Closes the previous one if there was any.
    /// </summary>
    /// <param name="name">The suite name.</param>
    void Suite(const string&in name)
    {
        EndSuite();
        suiteName = name;
        caseName = "";
        suiteFailuresAtStart = failureCount;
        suiteChecksAtStart = checkCount;
        suiteCount++;
    }

    /// <summary>
    /// Starts a named case inside the current suite. Purely for error messages.
    /// </summary>
    /// <param name="name">The case name.</param>
    void Case(const string&in name)
    {
        caseName = name;
    }

    /// <summary>
    /// Records a boolean check.
    /// </summary>
    /// <param name="condition">The condition that must hold.</param>
    /// <param name="what">A description of what was being verified.</param>
    void Check(bool condition, const string&in what)
    {
        checkCount++;
        if (!condition) {
            failureCount++;
            failureLines.insertLast("FAIL  " + Where() + " : " + what);
        }
    }

    /// <summary>
    /// Records a float comparison with a tolerance.
    /// </summary>
    /// <param name="actual">The produced value.</param>
    /// <param name="expected">The value that was expected.</param>
    /// <param name="what">A description of what was being verified.</param>
    /// <param name="epsilon">The maximum accepted absolute difference.</param>
    void CheckApprox(float actual, float expected, const string&in what, float epsilon = 0.0001f)
    {
        checkCount++;
        if (!(Math::Abs(actual - expected) <= epsilon)) {
            failureCount++;
            failureLines.insertLast("FAIL  " + Where() + " : " + what
                + " (expected " + formatFloat(expected, "", 0, 6)
                + ", got " + formatFloat(actual, "", 0, 6) + ")");
        }
    }

    /// <summary>
    /// Records an integer equality check.
    /// </summary>
    /// <param name="actual">The produced value.</param>
    /// <param name="expected">The value that was expected.</param>
    /// <param name="what">A description of what was being verified.</param>
    void CheckEqualInt(int actual, int expected, const string&in what)
    {
        checkCount++;
        if (actual != expected) {
            failureCount++;
            failureLines.insertLast("FAIL  " + Where() + " : " + what
                + " (expected " + expected + ", got " + actual + ")");
        }
    }

    /// <summary>
    /// Records a string equality check.
    /// </summary>
    /// <param name="actual">The produced value.</param>
    /// <param name="expected">The value that was expected.</param>
    /// <param name="what">A description of what was being verified.</param>
    void CheckEqualString(const string&in actual, const string&in expected, const string&in what)
    {
        checkCount++;
        if (actual != expected) {
            failureCount++;
            failureLines.insertLast("FAIL  " + Where() + " : " + what
                + " (expected '" + expected + "', got '" + actual + "')");
        }
    }

    /// <summary>
    /// Records that a float lies inside an inclusive range.
    /// </summary>
    /// <param name="actual">The produced value.</param>
    /// <param name="minimum">The lowest accepted value.</param>
    /// <param name="maximum">The highest accepted value.</param>
    /// <param name="what">A description of what was being verified.</param>
    void CheckInRange(float actual, float minimum, float maximum, const string&in what)
    {
        checkCount++;
        if (actual < minimum || actual > maximum) {
            failureCount++;
            failureLines.insertLast("FAIL  " + Where() + " : " + what
                + " (expected within [" + formatFloat(minimum, "", 0, 6) + ", " + formatFloat(maximum, "", 0, 6)
                + "], got " + formatFloat(actual, "", 0, 6) + ")");
        }
    }

    /// <summary>
    /// Closes the current suite and records its one-line summary.
    /// </summary>
    void EndSuite()
    {
        if (suiteName.isEmpty()) {
            return;
        }
        int suiteChecks = checkCount - suiteChecksAtStart;
        int suiteFailures = failureCount - suiteFailuresAtStart;
        string status = suiteFailures == 0 ? "PASS" : "FAIL";
        suiteLines.insertLast("[" + status + "] " + suiteName
            + " -- checks=" + suiteChecks + " failures=" + suiteFailures);
        suiteName = "";
        caseName = "";
    }

    /// <summary>
    /// Builds the full report text: one line per suite, then every failure, then the totals.
    /// </summary>
    /// <returns>Returns the report text.</returns>
    string Report()
    {
        EndSuite();

        string text = "=== Tweeny test run ===\n";
        for (uint i = 0; i < suiteLines.length(); i++) {
            text += suiteLines[i] + "\n";
        }
        if (failureLines.length() > 0) {
            text += "\n--- failures ---\n";
            for (uint i = 0; i < failureLines.length(); i++) {
                text += failureLines[i] + "\n";
            }
        }
        text += "\n=== DONE: suites=" + suiteCount
            + " checks=" + checkCount
            + " failures=" + failureCount + " ===\n";
        return text;
    }

    private string Where() const
    {
        return caseName.isEmpty() ? suiteName : (suiteName + " / " + caseName);
    }
}
