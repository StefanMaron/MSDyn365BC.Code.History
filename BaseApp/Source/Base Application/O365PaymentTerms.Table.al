table 2153 "O365 Payment Terms"
{
    Caption = 'O365 Payment Terms';
    ReplicateData = false;

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

    var
        OneMonthTxt: Label '1M(8D)', Locked = true;
        CMTxt: Label 'CM', Locked = true;

    procedure ExcludedOneMonthPaymentTermCode(): Text[10]
    begin
        exit(OneMonthTxt);
    end;

    procedure ExcludedCurrentMonthPaymentTermCode(): Text[10]
    begin
        exit(CMTxt);
    end;

    procedure IncludePaymentTermCode(PaymentTermCode: Code[10]): Boolean
    begin
        exit(not (PaymentTermCode in [OneMonthTxt, CMTxt]));
    end;

    procedure RefreshRecords()
    var
        PaymentTerms: Record "Payment Terms";
        CurrentRecordCode: Code[10];
    begin
        CurrentRecordCode := Code;
        DeleteAll();
        if PaymentTerms.FindSet then
            repeat
                if IncludePaymentTermCode(PaymentTerms.Code) then begin
                    Code := PaymentTerms.Code;
                    Description := PaymentTerms.GetDescriptionInCurrentLanguage;
                    "Due Date Calculation" := PaymentTerms."Due Date Calculation";
                    if Insert() then;
                end;
            until PaymentTerms.Next = 0;
        if Get(CurrentRecordCode) then;
    end;
}

