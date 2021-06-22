#pragma warning disable AS0083 // TODO(#369362)
enum 7300 "Whse. Activity Sorting Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None) { Caption = ' '; }
    value(1; "Item") { Caption = 'Item'; }
    value(2; "Document") { Caption = 'Document'; }
    value(3; "Shelf or Bin") { Caption = 'Shelf or Bin'; }
    value(4; "Due Date") { Caption = 'Due Date'; }
    value(5; "Ship-To") { Caption = 'Ship-To'; }
    value(6; "Bin Ranking") { Caption = 'Bin Ranking'; }
    value(7; "Action Type") { Caption = 'Action Type'; }
}
#pragma warning restore AS0083 // TODO(#369362)