namespace Microsoft.Service.Item;

enum 5940 "Service Item Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Own Service Item") { Caption = 'Own Service Item'; }
    value(2; Installed) { Caption = 'Installed'; }
    value(3; "Temporarily Installed") { Caption = 'Temporarily Installed'; }
    value(4; "Defective") { Caption = 'Defective'; }

}