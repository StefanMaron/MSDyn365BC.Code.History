namespace Microsoft.CRM.Interaction;

#pragma warning disable AL0659
enum 5082 "Interaction Template Wizard Action"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Open)
    {
        Caption = 'Open';
    }
    value(2; Import)
    {
        Caption = 'Import';
    }
    value(3; Merge)
    {
        Caption = 'Merge';
    }
}