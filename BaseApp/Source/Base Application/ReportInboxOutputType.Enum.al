namespace Microsoft.EServices.EDocument;

enum 477 "Report Inbox Output Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "PDF") { Caption = 'PDF'; }
    value(1; "Word") { Caption = 'Word'; }
    value(2; "Excel") { Caption = 'Excel'; }
    value(3; "Zip") { Caption = 'Zip'; }
}