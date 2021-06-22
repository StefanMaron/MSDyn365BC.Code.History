enum 5496 "Purchase Order Entity Buffer Status"
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
}