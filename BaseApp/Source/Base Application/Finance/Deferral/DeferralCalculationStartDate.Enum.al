namespace Microsoft.Finance.Deferral;

#pragma warning disable AL0659
enum 1701 "Deferral Calculation Start Date"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Posting Date") { Caption = 'Posting Date'; }
    value(1; "Beginning of Period") { Caption = 'Beginning of Period'; }
    value(2; "End of Period") { Caption = 'End of Period'; }
    value(3; "Beginning of Next Period") { Caption = 'Beginning of Next Period'; }
    value(4; "Beginning of Next Calendar Year") { Caption = 'Beginning of Next Calendar Year'; }
}