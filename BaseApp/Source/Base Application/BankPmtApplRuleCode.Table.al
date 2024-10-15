table 11702 "Bank Pmt. Appl. Rule Code"
{
    Caption = 'Bank Pmt. Appl. Rule Code';
#if not CLEAN19
    LookupPageID = "Bank Pmt. Appl. Rule Codes";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Match Related Party Only"; Boolean)
        {
            Caption = 'Match Related Party Only';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    trigger OnDelete()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", Code);
        BankPmtApplRule.DeleteAll();
    end;

    var
        DefaultCodeTxt: Label 'DEFAULT';
        DefaultCodeDescriptionTxt: Label 'Default Rules';

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure InsertDefaultMatchingRuleCode()
    var
        BankPmtApplRuleCode: Record "Bank Pmt. Appl. Rule Code";
    begin
        if BankPmtApplRuleCode.Get(DefaultCodeTxt) then
            exit;

        BankPmtApplRuleCode.Init();
        BankPmtApplRuleCode.Validate(Code, GetDefaultCode());
        BankPmtApplRuleCode.Validate(Description, DefaultCodeDescriptionTxt);
        BankPmtApplRuleCode.Insert(true);
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure GetDefaultCode(): Code[10]
    begin
        exit(DefaultCodeTxt);
    end;
#endif
}

