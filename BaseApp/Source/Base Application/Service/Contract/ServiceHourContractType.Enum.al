namespace Microsoft.Service.Contract;

enum 5910 "Service Hour Contract Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Quote") { Caption = 'Quote'; }
    value(2; "Contract") { Caption = 'Contract'; }
}