table 10603 "VAT Period"
{
    Caption = 'VAT Period';
    LookupPageID = "VAT Periods";

    fields
    {
        field(1; "Period No."; Integer)
        {
            Caption = 'Period No.';
        }
        field(2; "Start Day"; Integer)
        {
            Caption = 'Start Day';
            MaxValue = 31;
            MinValue = 1;
        }
        field(3; "Start Month"; Integer)
        {
            Caption = 'Start Month';
            MaxValue = 12;
            MinValue = 1;
        }
        field(4; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Period No.")
        {
            Clustered = true;
        }
        key(Key2; "Start Month", "Start Day")
        {
        }
    }

    fieldgroups
    {
    }

    var
        VATPeriod: Record "VAT Period";
        VATTools: Codeunit "Norwegian VAT Tools";

    [Scope('OnPrem')]
    procedure CheckPeriods()
    begin
        if VATPeriod.IsEmpty() then
            VATTools.CreateStdVATPeriods(false);
    end;
}

