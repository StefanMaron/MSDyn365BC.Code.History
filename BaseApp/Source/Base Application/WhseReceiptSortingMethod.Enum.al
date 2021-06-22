enum 7301 "Warehouse Receipt Sorting Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Document") { Caption = 'Document'; }
    value(3; "Shelf or Bin") { Caption = 'Shelf or Bin'; }
    value(4; "Due Date") { Caption = 'Due Date'; }
    value(5; "Ship-to") { Caption = 'Ship-to'; }
}