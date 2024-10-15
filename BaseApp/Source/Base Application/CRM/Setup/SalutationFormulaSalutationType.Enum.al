namespace Microsoft.CRM.Setup;

#pragma warning disable AL0659
enum 5070 "Salutation Formula Salutation Type"
#pragma warning restore AL0659
{
    Extensible = true;

    value(0; Formal)
    {
        Caption = 'Formal';
    }
    value(1; Informal)
    {
        Caption = 'Informal';
    }
}