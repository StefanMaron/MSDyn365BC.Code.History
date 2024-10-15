namespace Microsoft.Foundation.Reporting;

#pragma warning disable AL0659
enum 61 "Electronic Document Format Usage"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(1; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(2; "Sales Validation") { Caption = 'Sales Validation'; }
    value(3; "Service Invoice") { Caption = 'Service Invoice'; }
    value(4; "Service Credit Memo") { Caption = 'Service Credit Memo'; }
    value(5; "Service Validation") { Caption = 'Service Validation'; }
    value(6; "Job Quote") { Caption = 'Job Quote'; }
    value(7; "Job Task Quote") { Caption = 'Job Task Quote'; }
}