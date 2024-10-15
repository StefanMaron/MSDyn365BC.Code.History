namespace Microsoft.Service.Contract;

enum 6057 "Contract Line Selection"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "All Service Items") { Caption = 'All Service Items'; }
    value(1; "Service Items without Contract") { Caption = 'Service Items without Contract'; }
}