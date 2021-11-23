enum 242 "VAT Reg. Log Details Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Verified")
    {
        Caption = 'Not Verified';
    }
    value(1; Valid)
    {
        Caption = 'Valid';
    }
    value(2; "Not Valid")
    {
        Caption = 'Not Valid';
    }
    value(3; "Partially Valid")
    {
        Caption = 'Partially Valid';
    }
    value(4; Ignored)
    {
        Caption = 'Ignored';
    }
}