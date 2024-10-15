namespace Microsoft.Warehouse.Activity;

enum 5700 "Pick Bin Policy"
{
    Extensible = true;

    value(100; "Default Bin")
    {
        Caption = 'Default Bin';
    }

    value(200; "Bin Ranking")
    {
        Caption = 'Bin Ranking';
    }
}