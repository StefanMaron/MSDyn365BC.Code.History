namespace Microsoft.Sales.Peppol;

enum 1610 "PEPPOL Processing Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sale") { Caption = 'Sale'; }
    value(1; "Service") { Caption = 'Service'; }
}