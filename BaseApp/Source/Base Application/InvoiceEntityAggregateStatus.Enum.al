enum 5477 "Invoice Entity Aggregate Status"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Draft)
    {
        Caption = 'Draft';
    }
    value(2; "In Review")
    {
        Caption = 'In Review';
    }
    value(3; Open)
    {
        Caption = 'Open';
    }
    value(4; Paid)
    {
        Caption = 'Paid';
    }
    value(5; Canceled)
    {
        Caption = 'Canceled';
    }
    value(6; Corrective)
    {
        Caption = 'Corrective';
    }
}