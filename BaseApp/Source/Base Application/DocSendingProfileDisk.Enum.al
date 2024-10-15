namespace Microsoft.Foundation.Reporting;

enum 65 "Doc. Sending Profile Disk"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "No") { Caption = 'No'; }
    value(1; "PDF") { Caption = 'PDF'; }
    value(2; "Electronic Document") { Caption = 'Electronic Document'; }
    value(3; "PDF & Electronic Document") { Caption = 'PDF & Electronic Document'; }
}