namespace Microsoft.Projects.Project.Planning;

#pragma warning disable AL0659
enum 1022 "Job Planning Line Invoice Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Invoice)
    {
        Caption = 'Invoice';
    }
    value(2; "Credit Memo")
    {
        Caption = 'Credit Memo';
    }
    value(3; "Posted Invoice")
    {
        Caption = 'Posted Invoice';
    }
    value(4; "Posted Credit Memo")
    {
        Caption = 'Posted Credit Memo';
    }
}
