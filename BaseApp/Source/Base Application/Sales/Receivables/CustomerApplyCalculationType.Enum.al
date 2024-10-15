namespace Microsoft.Sales.Receivables;

#pragma warning disable AL0659
enum 232 "Customer Apply Calculation Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Direct") { }
    value(1; "Gen. Jnl. Line") { }
    value(2; "Sales Header") { }
    value(3; "Service Header") { }
}