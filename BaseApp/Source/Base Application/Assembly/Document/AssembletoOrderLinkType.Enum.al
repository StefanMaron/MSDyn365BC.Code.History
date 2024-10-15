namespace Microsoft.Assembly.Document;

enum 904 "Assemble-to-Order Link Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ''; }
    value(1; "Sale") { Caption = 'Sale'; }
    value(2; "Job") { Caption = 'Project'; }
}