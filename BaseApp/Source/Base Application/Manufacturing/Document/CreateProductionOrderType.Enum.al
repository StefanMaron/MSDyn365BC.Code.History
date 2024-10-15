namespace Microsoft.Manufacturing.Document;

enum 99000884 "Create Production Order Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "ItemOrder") { Caption = 'Item Order'; }
    value(1; "ProjectOrder") { Caption = 'Project Order'; }
}