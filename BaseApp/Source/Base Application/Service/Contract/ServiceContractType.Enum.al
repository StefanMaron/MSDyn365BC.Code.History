namespace Microsoft.Service.Contract;

enum 5965 "Service Contract Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Quote") { Caption = 'Quote'; }
    value(1; "Contract") { Caption = 'Contract'; }
    value(2; "Template") { Caption = 'Template'; }
}