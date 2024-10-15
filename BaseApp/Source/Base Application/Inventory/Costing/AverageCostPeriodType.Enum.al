namespace Microsoft.Inventory.Costing;

enum 5806 "Average Cost Period Type"
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Day") { Caption = 'Day'; }
    value(2; "Week") { Caption = 'Week'; }
    value(3; "Month") { Caption = 'Month'; }
    value(4; "Quarter") { Caption = 'Quarter'; }
    value(5; "Year") { Caption = 'Year'; }
    value(6; "Accounting Period") { Caption = 'Accounting Period'; }
}