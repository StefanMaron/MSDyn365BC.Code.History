namespace Microsoft.Inventory.Transfer;

enum 5740 "Transfer Order Post"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; "Ship") { Caption = 'Ship'; }
    value(1; "Receive") { Caption = 'Receive'; }
}
