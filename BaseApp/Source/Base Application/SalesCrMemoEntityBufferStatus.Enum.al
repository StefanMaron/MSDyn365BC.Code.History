enum 5507 "Sales Cr. Memo Entity Buffer Status"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; "In Review")
    {
        Caption = 'In Review';
    }
    value(2; Open)
    {
        Caption = 'Open';
    }
    value(3; Canceled)
    {
        Caption = 'Canceled';
    }
    value(4; Corrective)
    {
        Caption = 'Corrective';
    }
    value(5; Paid)
    {
        Caption = 'Paid';
    }
}