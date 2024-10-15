namespace Microsoft.Purchases.Payables;

enum 233 "Vendor Apply Calculation Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Direct") { }
    value(1; "Gen. Jnl. Line") { }
    value(2; "Purchase Header") { }
}