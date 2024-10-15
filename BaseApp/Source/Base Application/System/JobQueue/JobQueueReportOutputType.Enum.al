namespace System.Threading;

enum 482 "Job Queue Report Output Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "PDF") { Caption = 'PDF'; }
    value(1; "Word") { Caption = 'Word'; }
    value(2; "Excel") { Caption = 'Excel'; }
    value(3; "Print") { Caption = 'Print'; }
    value(4; "None (Processing only)") { Caption = 'None (Processing only)'; }
}