namespace Microsoft.Inventory.Counting.Document;

enum 5875 "Phys. Invt. Order Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Open") { Caption = 'Open'; }
    value(1; "Finished") { Caption = 'Finished'; }
}