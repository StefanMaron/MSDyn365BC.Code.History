table 272 "Check Ledger Entry"
{
    Caption = 'Check Ledger Entry';
    DrillDownPageID = "Check Ledger Entries";
    LookupPageID = "Check Ledger Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank;
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "Check Date"; Date)
        {
            Caption = 'Check Date';
        }
        field(10; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(11; "Check Type"; Option)
        {
            Caption = 'Check Type';
            OptionCaption = 'Total Check,Partial Check';
            OptionMembers = "Total Check","Partial Check";
        }
        field(12; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
        }
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Printed,Voided,Posted,Financially Voided,Test Print,Exported,Transmitted';
            OptionMembers = ,Printed,Voided,Posted,"Financially Voided","Test Print",Exported,Transmitted;
        }
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Printed,Voided,Posted,Financially Voided,,Exported,Transmitted';
            OptionMembers = " ",Printed,Voided,Posted,"Financially Voided",,Exported,Transmitted;
        }
        field(15; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Bal. Account Type" = CONST(Employee)) Employee;
        }
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed;
        }
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
#if not CLEAN20
            TableRelation = IF ("Statement Status" = FILTER("Bank Acc. Entry Applied" | "Check Entry Applied")) "Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."))
            ELSE
            IF ("Statement Status" = CONST(Closed)) "Posted Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
#else
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
            ValidateTableRelation = false;
#endif
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
#if not CLEAN20
            TableRelation = IF ("Statement Status" = FILTER("Bank Acc. Entry Applied" | "Check Entry Applied")) "Bank Rec. Line"."Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                                                                               "Statement No." = FIELD("Statement No."))
            ELSE
            IF ("Statement Status" = CONST(Closed)) "Posted Bank Rec. Line"."Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                                                                                                                                                                    "Statement No." = FIELD("Statement No."));
#else
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                                        "Statement No." = FIELD("Statement No."));
#endif
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(24; "Data Exch. Voided Entry No."; Integer)
        {
            Caption = 'Data Exch. Voided Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(25; "Positive Pay Exported"; Boolean)
        {
            Caption = 'Positive Pay Exported';
        }
        field(26; "Record ID to Print"; RecordID)
        {
            Caption = 'Record ID to Print';
            DataClassification = CustomerContent;
        }
        field(10005; "Trace No."; Code[30])
        {
            Caption = 'Trace No.';
        }
        field(10006; "Transmission File Name"; Text[30])
        {
            Caption = 'Transmission File Name';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Check Date")
        {
        }
        key(Key3; "Bank Account No.", "Entry Status", "Check No.", "Statement Status")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NothingToExportErr: Label 'There is nothing to export.';

    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    procedure CopyFromBankAccLedgEntry(BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
        "Bank Account No." := BankAccLedgEntry."Bank Account No.";
        "Bank Account Ledger Entry No." := BankAccLedgEntry."Entry No.";
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        Description := BankAccLedgEntry.Description;
        "Bal. Account Type" := BankAccLedgEntry."Bal. Account Type";
        "Bal. Account No." := BankAccLedgEntry."Bal. Account No.";
        "Entry Status" := "Entry Status"::Posted;
        Open := true;
        "User ID" := UserId;
        "Check Date" := BankAccLedgEntry."Posting Date";
        "Check No." := BankAccLedgEntry."Document No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccLedgEntry);
    end;

    procedure GetCheckAmountText(CurrencyCode: Code[10]; var CurrencySymbol: Code[5]) CheckAmountText: Text
    var
        Currency: Record Currency;
        Decimals: Decimal;
    begin
        Currency.Initialize(CurrencyCode);

        Decimals := Amount - Round(Amount, 1, '<');

        if (GetFractionPartLength(Amount) <> GetFractionPartLength(Currency."Amount Rounding Precision")) then
            if (Decimals = 0) or (GetFractionPartLength(Amount) > GetFractionPartLength(Currency."Amount Rounding Precision")) then
                CheckAmountText :=
                  Format(
                    Round(Amount, 1, '<')) +
                    GetDecimalSeparator +
                    PadStr('', StrLen(Format(Round(Currency."Amount Rounding Precision", Currency."Amount Rounding Precision"))) - 2, '0')
            else
                CheckAmountText := Format(Round(Amount, Currency."Amount Rounding Precision")) +
                  PadStr('', GetFractionPartLength(Currency."Amount Rounding Precision") - GetFractionPartLength(Amount), '0')
        else
            CheckAmountText := Format(Amount, 0, 0);

        CurrencySymbol := Currency.Symbol;
    end;

    local procedure GetFractionPartLength(DecimalValue: Decimal): Integer
    begin
        if StrPos(Format(DecimalValue), GetDecimalSeparator) = 0 then
            exit(0);

        exit(StrLen(Format(DecimalValue)) - StrPos(Format(DecimalValue), GetDecimalSeparator));
    end;

    local procedure GetDecimalSeparator(): Code[1]
    begin
        exit(CopyStr(Format(0.01), 2, 1));
    end;

    procedure ExportCheckFile()
    var
        BankAcc: Record "Bank Account";
    begin
        if not FindSet() then
            Error(NothingToExportErr);

        if not BankAcc.Get("Bank Account No.") then
            Error(NothingToExportErr);

        if BankAcc.GetPosPayExportCodeunitID > 0 then
            CODEUNIT.Run(BankAcc.GetPosPayExportCodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Pos. Pay", Rec);
    end;

    procedure GetPayee() Payee: Text[100]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
    begin
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                if "Bal. Account No." <> '' then begin
                    GLAccount.Get("Bal. Account No.");
                    Payee := GLAccount.Name;
                end;
            "Bal. Account Type"::Customer:
                if "Bal. Account No." <> '' then begin
                    Customer.Get("Bal. Account No.");
                    Payee := Customer.Name;
                end;
            "Bal. Account Type"::Vendor:
                if "Bal. Account No." <> '' then begin
                    Vendor.Get("Bal. Account No.");
                    Payee := Vendor.Name;
                end;
            "Bal. Account Type"::"Bank Account":
                if "Bal. Account No." <> '' then begin
                    BankAccount.Get("Bal. Account No.");
                    Payee := BankAccount.Name;
                end;
            "Bal. Account Type"::"Fixed Asset":
                Payee := "Bal. Account No.";
            "Bal. Account Type"::Employee:
                if "Bal. Account No." <> '' then begin
                    Employee.Get("Bal. Account No.");
                    Payee := Employee.FullName;
                end;
        end;

        OnAfterGetPayee(Rec, Payee);
    end;

    procedure SetFilterBankAccNoOpen(BankAccNo: Code[20])
    begin
        Reset;
        SetCurrentKey("Bank Account No.", Open);
        SetRange("Bank Account No.", BankAccNo);
        SetRange(Open, true);
    end;

#if NOT CLEAN20
    [Obsolete('Please use the ResetStatementFields(BankAccountNo, StatementNo, StatementType) instead, as we can have payment and bank reconciliations with the same bank account no and statement no and we might be resetting too many ledger entries with this function', '20.0')]
    procedure ResetStatementFields(BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        Reset();
        SetRange("Bank Account No.", BankAccountNo);
        SetRange("Statement No.", StatementNo);
        if FindSet() then
            repeat
                "Statement Line No." := 0;
                "Statement No." := '';
                "Statement Status" := "Statement Status"::Open;
                Open := true;
                Modify();
            until Next() = 0;
    end;
#endif

    procedure ResetStatementFields(BankAccountNo: Code[20]; StatementNo: Code[20]; StatementType: Option)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Reset();
        SetRange("Bank Account No.", BankAccountNo);
        SetRange("Statement No.", StatementNo);
        if FindSet() then
            repeat
                // we can have payment and bank reconciliations with the same bank account no and statement no, 
                // so unless we also filter by statement type we might be resetting too many ledger entries
                if BankAccReconciliationLine.Get(StatementType,
                    BankAccountNo, StatementNo, "Statement Line No.")
                then begin
                    "Statement Line No." := 0;
                    "Statement No." := '';
                    "Statement Status" := "Statement Status"::Open;
                    Open := true;
                    Modify();
                end;
            until Next() = 0;
    end;


    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromBankAccLedgEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPayee(CheckLedgerEntry: Record "Check Ledger Entry"; var Payee: Text[100])
    begin
    end;
}

