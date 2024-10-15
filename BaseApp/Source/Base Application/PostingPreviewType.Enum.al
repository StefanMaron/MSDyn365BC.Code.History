namespace Microsoft.Finance.GeneralLedger.Preview;

enum 1570 "Posting Preview Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Standard) { Caption = 'Standard'; }
    value(1; Extended) { Caption = 'Extended'; }
}