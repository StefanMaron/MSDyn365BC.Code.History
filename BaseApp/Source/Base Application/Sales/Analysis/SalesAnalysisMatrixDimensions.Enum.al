namespace Microsoft.Sales.Analysis;

enum 7158 "Sales Analysis Matrix Dimensions"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; "Item") { Caption = 'Item'; }
    value(1; "Period") { Caption = 'Period'; }
    value(2; "Location") { Caption = 'Location'; }
    value(3; "Dimension 1") { Caption = 'Dimension 1'; }
    value(4; "Dimension 2") { Caption = 'Dimension 2'; }
    value(5; "Dimension 3") { Caption = 'Dimension 3'; }
    value(99; "Undefined") { Caption = 'Undefined'; }
}