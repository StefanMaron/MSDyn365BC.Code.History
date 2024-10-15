namespace Microsoft.Inventory.Item;

enum 28 "Costing Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "FIFO") { Caption = 'FIFO'; }
    value(1; "LIFO") { Caption = 'LIFO'; }
    value(2; "Specific") { Caption = 'Specific'; }
    value(3; "Average") { Caption = 'Average'; }
    value(4; "Standard") { Caption = 'Standard'; }
}