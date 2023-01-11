enum 259 "VAT Reporting Date Usage"
{
    Extensible = false;
    Access = Internal;
    
    value(0; "Complete")
    {
        Caption = 'Use full VAT Date functionality.';
    }
    value(1; "No VAT Date changes")
    {
        Caption = 'Use but do not allow modifications.';
    }
    value(2; "Disabled") 
    {
        Caption = 'Do not use VAT Date functionality';
    }
}