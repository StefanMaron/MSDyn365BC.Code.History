table 2153 "O365 Payment Terms"
{
    Caption = 'O365 Payment Terms';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
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
        fieldgroup(Brick; "Code", Description, "Due Date Calculation")
        {
        }
    }
#if not CLEAN21
    var
        OneMonthTxt: Label '1M(8D)', Locked = true;
        CMTxt: Label 'CM', Locked = true;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ExcludedOneMonthPaymentTermCode(): Text[10]
    begin
        exit(OneMonthTxt);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure ExcludedCurrentMonthPaymentTermCode(): Text[10]
    begin
        exit(CMTxt);
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure IncludePaymentTermCode(PaymentTermCode: Code[10]): Boolean
    begin
        exit(not (PaymentTermCode in [OneMonthTxt, CMTxt]));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure RefreshRecords()
    var
        PaymentTerms: Record "Payment Terms";
        CurrentRecordCode: Code[10];
    begin
        CurrentRecordCode := Code;
        DeleteAll();
        if PaymentTerms.FindSet() then
            repeat
                    if IncludePaymentTermCode(PaymentTerms.Code) then begin
                        Code := PaymentTerms.Code;
                        Description := PaymentTerms.GetDescriptionInCurrentLanguageFullLength();
                        "Due Date Calculation" := PaymentTerms."Due Date Calculation";
                        if Insert() then;
                    end;
            until PaymentTerms.Next() = 0;
        if Get(CurrentRecordCode) then;
    end;
#endif
}

