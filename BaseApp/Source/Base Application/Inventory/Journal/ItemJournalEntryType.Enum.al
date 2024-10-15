namespace Microsoft.Inventory.Journal;

enum 40 "Item Journal Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Purchase") { Caption = 'Purchase'; }
    value(1; "Sale") { Caption = 'Sale'; }
    value(2; "Positive Adjmt.") { Caption = 'Positive Adjmt.'; }
    value(3; "Negative Adjmt.") { Caption = 'Negative Adjmt.'; }
}