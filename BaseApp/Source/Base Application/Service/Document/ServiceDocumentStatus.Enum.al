namespace Microsoft.Service.Document;

enum 5912 "Service Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Pending) { Caption = 'Pending'; }
    value(1; "In Process") { Caption = 'In Process'; }
    value(2; Finished) { Caption = 'Finished'; }
    value(3; "On Hold") { Caption = 'On Hold'; }
}