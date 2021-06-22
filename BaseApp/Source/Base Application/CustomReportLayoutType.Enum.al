enum 9656 "Custom Report Layout Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; RDLC)
    {
        Caption = 'RDLC', Locked = true;
    }
    value(1; Word)
    {
        Caption = 'Word', Locked = true;
    }
}