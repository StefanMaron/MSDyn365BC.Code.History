namespace Microsoft.Assembly.Document;

enum 900 "Asm. Consump. Whse. Handling"
{
    Extensible = true;

    value(0; "No Warehouse Handling")
    {
        Caption = 'No Warehouse Handling';
    }
    value(10; "Warehouse Pick (optional)")
    {
        Caption = 'Warehouse Pick (optional)';
    }
    value(20; "Inventory Movement")
    {
        Caption = 'Inventory Movement';
    }
    value(30; "Warehouse Pick (mandatory)")
    {
        Caption = 'Warehouse Pick (mandatory)';
    }
}