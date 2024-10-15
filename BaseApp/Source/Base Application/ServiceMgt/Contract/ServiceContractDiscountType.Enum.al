namespace Microsoft.Service.Contract;

enum 5973 "Service Contract Discount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Service Item Group") { Caption = 'Service Item Group'; }
    value(1; "Resource Group") { Caption = 'Resource Group'; }
    value(2; "Cost") { Caption = 'Cost'; }
}