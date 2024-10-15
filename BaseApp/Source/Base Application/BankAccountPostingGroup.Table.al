table 277 "Bank Account Posting Group"
{
    Caption = 'Bank Account Posting Group';
    DrillDownPageID = "Bank Account Posting Groups";
    LookupPageID = "Bank Account Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "G/L Bank Account No."; Code[20])
        {
            Caption = 'G/L Bank Account No.';
            ObsoleteReason = 'Moved to G/L Account No.';
            ObsoleteState = Pending;
            TableRelation = "G/L Account";
            ObsoleteTag = '15.0';
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("G/L Account No.");
                CheckBankAccountBalance; // NAVCZ
            end;
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
        fieldgroup(DropDown; "Code", "G/L Account No.")
        {
        }
        fieldgroup(Brick; "Code")
        {
        }
    }

    var
        ChangeQst: Label 'Do you really want to change %1 although bank accounts with non zero %2 exist?', Comment = '%1 - G/L Account No., %2 - Balance';

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
        end;
    end;

    local procedure CheckBankAccountBalance()
    var
        BankAccount: Record "Bank Account";
    begin
        // NAVCZ
        BankAccount.SetCurrentKey("Bank Acc. Posting Group");
        BankAccount.SetRange("Bank Acc. Posting Group", Code);
        BankAccount.CalcFields(Balance);
        BankAccount.SetFilter(Balance, '<>0');
        if not BankAccount.IsEmpty then
            if not Confirm(ChangeQst, false, FieldCaption("G/L Account No."), BankAccount.FieldCaption(Balance)) then
                Error('');
        BankAccount.SetRange(Balance);
        BankAccount.CalcFields("Balance (LCY)");
        BankAccount.SetFilter("Balance (LCY)", '<>0');
        if not BankAccount.IsEmpty then
            if not Confirm(ChangeQst, false, FieldCaption("G/L Account No."), BankAccount.FieldCaption("Balance (LCY)")) then
                Error('');
    end;

    procedure GetGLBankAccountNo(): Code[20]
    begin
        TestField("G/L Account No.");
        exit("G/L Account No.");
    end;
}

