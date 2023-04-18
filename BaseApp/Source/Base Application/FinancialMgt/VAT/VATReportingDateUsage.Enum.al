enum 259 "VAT Reporting Date Usage"
{
    Extensible = false;
    Access = Internal;
    
    value(0; Enabled)
    {
        Caption = 'Enabled';
    }
    value(1; "Enabled (Prevent modification)")
    {
        Caption = 'Enabled (Prevent modification)';
    }
    value(2; Disabled) 
    {
        Caption = 'Disabled';
    }
}