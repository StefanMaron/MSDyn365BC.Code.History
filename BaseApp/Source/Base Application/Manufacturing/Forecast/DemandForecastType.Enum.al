namespace Microsoft.Manufacturing.Forecast;

enum 9245 "Demand Forecast Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Item") { Caption = 'Sales Item'; }
    value(1; "Component") { Caption = 'Component'; }
    value(2; "Both") { Caption = 'Both'; }
}