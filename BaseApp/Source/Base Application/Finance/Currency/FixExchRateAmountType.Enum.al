namespace Microsoft.Finance.Currency;

enum 330 "Fix Exch. Rate Amount Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Currency") { Caption = 'Currency'; }
    value(1; "Relational Currency") { Caption = 'Relational Currency'; }
    value(2; "Both") { Caption = 'Both'; }
}