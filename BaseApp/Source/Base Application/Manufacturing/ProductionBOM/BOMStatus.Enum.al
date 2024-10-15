namespace Microsoft.Manufacturing.ProductionBOM;

enum 99000771 "BOM Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "New") { Caption = 'New'; }
    value(1; "Certified") { Caption = 'Certified'; }
    value(2; "Under Development") { Caption = 'Under Development'; }
    value(3; "Closed") { Caption = 'Closed'; }
}
