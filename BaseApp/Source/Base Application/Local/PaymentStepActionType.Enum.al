enum 10862 "Payment Step Action Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "None") { Caption = 'None'; }
    value(1; "Ledger") { Caption = 'Ledger'; }
    value(2; "Report") { Caption = 'Report'; }
    value(3; "File") { Caption = 'File'; }
    value(4; "Create New Document") { Caption = 'Create New Document'; }
    value(5; "Cancel File") { Caption = 'Cancel File'; }
}