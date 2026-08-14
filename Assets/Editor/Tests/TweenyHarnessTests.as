using namespace CometEngine;

namespace TweenyTests
{
    /// <summary>
    /// Verifies the test harness itself and that the Tweeny runtime assembly is reachable from the
    /// editor assembly. If this suite fails, every other suite's result is meaningless.
    /// </summary>
    /// <param name="t">The context collecting the results.</param>
    void RunHarnessTests(TweenyTestContext@ t)
    {
        t.Suite("harness");

        t.Case("check records outcomes");
        t.Check(true, "a true condition passes");
        t.CheckApprox(1.0f, 1.0f, "identical floats are approximately equal");
        t.CheckApprox(1.0f, 1.00001f, "floats within the default epsilon are equal");
        t.CheckEqualInt(3, 3, "identical ints are equal");
        t.CheckEqualString("tweeny", "tweeny", "identical strings are equal");
        t.CheckInRange(0.5f, 0.0f, 1.0f, "a value inside the range passes");

        t.Case("runtime assembly is reachable");
        t.CheckEqualString(Tweeny::GetVersion(), Tweeny::VERSION, "the runtime version accessor works");
        t.Check(!Tweeny::VERSION.isEmpty(), "the runtime version is not empty");
    }
}
