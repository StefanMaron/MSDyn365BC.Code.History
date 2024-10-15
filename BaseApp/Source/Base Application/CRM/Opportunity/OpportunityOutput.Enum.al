namespace Microsoft.CRM.Opportunity;

enum 5095 "Opportunity Output"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "No of Opportunities") { Caption = 'No of Opportunities'; }
    value(1; "Estimated Value (LCY)") { Caption = 'Estimated Value (LCY)'; }
    value(2; "Calc. Current Value (LCY)") { Caption = 'Calc. Current Value (LCY)'; }
    value(3; "Avg. Estimated Value (LCY)") { Caption = 'Avg. Estimated Value (LCY)'; }
    value(4; "Avg. Calc. Current Value (LCY)") { Caption = 'Avg. Calc. Current Value (LCY)'; }
}