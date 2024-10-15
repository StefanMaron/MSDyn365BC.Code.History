namespace Microsoft.Warehouse.Activity;

enum 5701 "Put-away Bin Policy"
{
    Extensible = true;

    value(100; "Default Bin")
    {
        Caption = 'Default Bin';
    }

    value(200; "Put-away Template")
    {
        Caption = 'Put-away Template';
    }
}