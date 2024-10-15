table 1251 "Text-to-Account Mapping"
{
    Caption = 'Text-to-Account Mapping';
    DataCaptionFields = "Mapping Text";

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Mapping Text"; Text[250])
        {
            Caption = 'Mapping Text';
            NotBlank = true;

            trigger OnValidate()
            begin
                "Mapping Text" := CopyStr(RecordMatchMgt.Trim("Mapping Text"), 1, 250);
            end;
        }
        field(3; "Debit Acc. No."; Code[20])
        {
            Caption = 'Debit Acc. No.';
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                 Blocked = CONST(false),
                                                 "Direct Posting" = CONST(true));
        }
        field(4; "Credit Acc. No."; Code[20])
        {
            Caption = 'Credit Acc. No.';
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                 Blocked = CONST(false),
                                                 "Direct Posting" = CONST(true));
        }
        field(5; "Bal. Source Type"; Option)
        {
            Caption = 'Bal. Source Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account";

            trigger OnValidate()
            begin
                Validate("Bal. Source No.", '');
            end;
        }
        field(6; "Bal. Source No."; Code[20])
        {
            Caption = 'Bal. Source No.';
            TableRelation = IF ("Bal. Source Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                              Blocked = CONST(false))
            ELSE
            IF ("Bal. Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Source Type" = CONST("Bank Account")) "Bank Account" WHERE("Account Type" = CONST("Bank Account"));
        }
        field(7; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(11700; "Text-to-Account Mapping Code"; Code[10])
        {
            Caption = 'Text-to-Account Mapping Code';
            TableRelation = "Text-to-Account Mapping Code";
        }
        field(11701; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(11705; Priority; Integer)
        {
            Caption = 'Priority';
            MaxValue = 1000;
            MinValue = 0;
        }
        field(11710; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(11711; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
        }
        field(11712; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
            TableRelation = "Constant Symbol";
        }
        field(11715; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(11716; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(11717; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(11720; "Bank Transaction Type"; Option)
        {
            Caption = 'Bank Transaction Type';
            OptionCaption = 'Both,+,-';
            OptionMembers = Both,"+","-";
        }
    }

    keys
    {
        key(Key1; "Text-to-Account Mapping Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Mapping Text", "Vendor No.")
        {
            Enabled = false;
        }
        key(Key3; Priority)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckMappingText;
    end;

    trigger OnModify()
    begin
        CheckMappingText;
    end;

    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        AlreadyExistErr: Label 'Entry with Mapping Text=''%1'' already exists.', Comment = '%1 is the value currently inserted.';
        BalAccountNoQst: Label 'The Bal. Account No. field must have a value if the Bal. Source Type field contains %1.\\Affected Mapping Text: %2. Do you want to quit without saving the data?', Comment = '%1 is option: Vendor or Customer and %2 is the record value in this field.';
        GLAccountNoQst: Label 'The Debit Acc. No. field or the Credit Acc. No. field must have a value if the Bal. Source Type field contains %1.\\Affected Mapping Text: %2. Do you want to quit without saving the data?', Comment = '%1 is option: G/L Account and %2 is the record value in this field.';
        FilterInvalidCharTxt: Label '(&)', Locked = true;

    procedure InsertRec(GenJnlLine: Record "Gen. Journal Line")
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        LastLineNo: Integer;
    begin
        if RecordMatchMgt.Trim(GenJnlLine.Description) <> '' then begin
            TextToAccMapping.SetRange("Text-to-Account Mapping Code", ''); // NAVCZ
            TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + RecordMatchMgt.Trim(GenJnlLine.Description));
            if TextToAccMapping.FindFirst then
                Copy(TextToAccMapping)
            else begin
                TextToAccMapping.Reset();
                TextToAccMapping.SetRange("Text-to-Account Mapping Code", ''); // NAVCZ
                if TextToAccMapping.FindLast then
                    LastLineNo := TextToAccMapping."Line No.";

                Init;
                "Line No." := LastLineNo + 10000;
                Validate("Mapping Text", GenJnlLine.Description);
                SetBalSourceType(GenJnlLine);
                if "Bal. Source Type" <> "Bal. Source Type"::"G/L Account" then
                    "Bal. Source No." := GenJnlLine."Account No."
                else begin
                    "Debit Acc. No." := GenJnlLine."Account No.";
                    "Credit Acc. No." := GenJnlLine."Account No.";
                end;

                if "Mapping Text" <> '' then
                    Insert;
            end;

            Reset;
        end;

        SetRange("Text-to-Account Mapping Code", ''); // NAVCZ
        PAGE.Run(PAGE::"Text-to-Account Mapping", Rec);
    end;

    procedure InsertRecFromBankAccReconciliationLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        LastLineNo: Integer;
    begin
        if RecordMatchMgt.Trim(BankAccReconciliationLine."Transaction Text") <> '' then begin
            // NAVCZ
            TextToAccMapping.FilterTextToAccountMapping(BankAccReconciliationLine);
            TextToAccMapping.ExtendedFilterTextToAccountMapping(BankAccReconciliationLine);
            // NAVCZ
            TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + RecordMatchMgt.Trim(BankAccReconciliationLine."Transaction Text"));
            if TextToAccMapping.FindFirst then
                Copy(TextToAccMapping)
            else begin
                TextToAccMapping.Reset();
                TextToAccMapping.FilterTextToAccountMapping(BankAccReconciliationLine); // NAVCZ
                if TextToAccMapping.FindLast then
                    LastLineNo := TextToAccMapping."Line No.";

                Init;
                "Text-to-Account Mapping Code" := BankAccReconciliationLine.GetTextToAccountMappingCode; // NAVCZ
                "Line No." := LastLineNo + 10000;
                Validate("Mapping Text", BankAccReconciliationLine."Transaction Text");
                // NAVCZ
                "Variable Symbol" := BankAccReconciliationLine."Variable Symbol";
                "Specific Symbol" := BankAccReconciliationLine."Specific Symbol";
                "Constant Symbol" := BankAccReconciliationLine."Constant Symbol";
                "Bank Account No." := BankAccReconciliationLine."Related-Party Bank Acc. No.";
                IBAN := BankAccReconciliationLine.IBAN;
                "SWIFT Code" := BankAccReconciliationLine."SWIFT Code";
                "Bank Transaction Type" := GetBankTransactionType(BankAccReconciliationLine."Statement Amount");
                // NAVCZ

                SetSourceTypeFromReconcLine(BankAccReconciliationLine);
                case "Bal. Source Type" of
                    "Bal. Source Type"::Customer,
                    "Bal. Source Type"::Vendor:
                        "Bal. Source No." := BankAccReconciliationLine."Account No.";
                    "Bal. Source Type"::"G/L Account":
                        begin
                            "Debit Acc. No." := BankAccReconciliationLine."Account No.";
                            "Credit Acc. No." := BankAccReconciliationLine."Account No.";
                        end;
                end;

                // NAVCZ
                if ("Mapping Text" <> '') or ("Variable Symbol" <> '') or
                   ("Specific Symbol" <> '') or ("Constant Symbol" <> '') or
                   ("Bank Account No." <> '') or (IBAN <> '') or
                   ("SWIFT Code" <> '')
                then
                    // NAVCZ
                    Insert;
            end;

            Reset;

            Commit();
        end;

        SetRange("Text-to-Account Mapping Code", BankAccReconciliationLine.GetTextToAccountMappingCode); // NAVCZ
        PAGE.RunModal(PAGE::"Text-to-Account Mapping", Rec);
    end;

    procedure GetAccountNo(Amount: Decimal): Code[20]
    begin
        if Amount >= 0 then
            exit("Debit Acc. No.");

        exit("Credit Acc. No.");
    end;

    procedure GetPaymentDocType(var PaymentDocType: Option; ActualSourceType: Option; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedSourceType: Option;
    begin
        if Amount >= 0 then
            ExpectedSourceType := "Bal. Source Type"::Vendor
        else
            ExpectedSourceType := "Bal. Source Type"::Customer;

        if ExpectedSourceType = ActualSourceType then
            PaymentDocType := GenJournalLine."Document Type"::Payment.AsInteger()
        else
            PaymentDocType := GenJournalLine."Document Type"::Refund.AsInteger();
    end;

    procedure GetDocTypeForPmt(var DocType: Option; PaymentDocType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case PaymentDocType of
            GenJournalLine."Document Type"::Payment.AsInteger():
                DocType := GenJournalLine."Document Type"::Invoice.AsInteger();
            GenJournalLine."Document Type"::Refund.AsInteger():
                DocType := GenJournalLine."Document Type"::"Credit Memo".AsInteger();
        end;
    end;

    local procedure SetBalSourceType(GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                "Bal. Source Type" := "Bal. Source Type"::Customer;
            GenJournalLine."Account Type"::Vendor:
                "Bal. Source Type" := "Bal. Source Type"::Vendor;
        end;
    end;

    local procedure SetSourceTypeFromReconcLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        case BankAccReconciliationLine."Account Type" of
            BankAccReconciliationLine."Account Type"::Customer:
                "Bal. Source Type" := "Bal. Source Type"::Customer;
            BankAccReconciliationLine."Account Type"::Vendor:
                "Bal. Source Type" := "Bal. Source Type"::Vendor;
            BankAccReconciliationLine."Account Type"::"Bank Account":
                "Bal. Source Type" := "Bal. Source Type"::"Bank Account";
        end;
    end;

    procedure IsBalSourceNoEnabled(): Boolean
    begin
        exit(not ("Bal. Source Type" in ["Bal. Source Type"::"G/L Account", "Bal. Source Type"::"Bank Account"]));
    end;

    local procedure CheckMappingText()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        // NAVCZ
        if DisabledCheckMappingText then
            exit;
        // NAVCZ

        TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + "Mapping Text");
        TextToAccMapping.SetRange("Vendor No.", "Vendor No.");
        TextToAccMapping.SetFilter("Line No.", '<>%1', "Line No.");
        if not TextToAccMapping.IsEmpty() then
            Error(AlreadyExistErr, "Mapping Text");
    end;

    procedure CheckEntriesAreConsistent(): Boolean
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        with TextToAccMapping do begin
            SetFilter("Bal. Source Type", '%1|%2', "Bal. Source Type"::Vendor, "Bal. Source Type"::Customer);
            SetRange("Bal. Source No.", '');
            if FindFirst then begin
                if DIALOG.Confirm(BalAccountNoQst, true, "Bal. Source Type", "Mapping Text")
                then begin
                    DeleteAll(true);
                    exit(true);
                end;
                exit(false);
            end;

            SetRange("Bal. Source Type", "Bal. Source Type"::"G/L Account");
            SetRange("Debit Acc. No.", '');
            SetRange("Credit Acc. No.", '');
            if FindFirst then begin
                if DIALOG.Confirm(GLAccountNoQst, true, "Bal. Source Type"::"G/L Account", "Mapping Text")
                then begin
                    DeleteAll(true);
                    exit(true);
                end;
                exit(false);
            end;

            SetRange("Bal. Source Type", "Bal. Source Type"::"Bank Account");
            SetRange("Debit Acc. No.", '');
            SetRange("Credit Acc. No.", '');
            if FindFirst then begin
                if DIALOG.Confirm(GLAccountNoQst, true, "Bal. Source Type"::"Bank Account", "Mapping Text")
                then begin
                    DeleteAll(true);
                    exit(true);
                end;
                exit(false);
            end;

            // Exit normally
            exit(true)
        end;
    end;

    [Scope('OnPrem')]
    procedure GetBankTransactionType(Amount: Decimal): Integer
    begin
        // NAVCZ
        case true of
            Amount < 0:
                exit("Bank Transaction Type"::"-");
            Amount > 0:
                exit("Bank Transaction Type"::"+");
        end;
    end;

    [Scope('OnPrem')]
    procedure FilterTextToAccountMapping(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        // NAVCZ
        Reset;
        SetRange("Text-to-Account Mapping Code", BankAccReconLine.GetTextToAccountMappingCode);
    end;

    [Scope('OnPrem')]
    procedure ExtendedFilterTextToAccountMapping(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        // NAVCZ
        SetRange("Variable Symbol", BankAccReconLine."Variable Symbol");
        SetRange("Specific Symbol", BankAccReconLine."Specific Symbol");
        SetRange("Constant Symbol", BankAccReconLine."Constant Symbol");
        SetRange("Bank Account No.", BankAccReconLine."Related-Party Bank Acc. No.");
        SetRange(IBAN, BankAccReconLine.IBAN);
        SetRange("SWIFT Code", BankAccReconLine."SWIFT Code");
        SetFilter("Bank Transaction Type", '%1|%2',
          "Bank Transaction Type"::Both, GetBankTransactionType(BankAccReconLine."Statement Amount"));
    end;

    [Scope('OnPrem')]
    procedure ExtendedMatching(BankAccReconLine: Record "Bank Acc. Reconciliation Line"): Boolean
    begin
        // NAVCZ
        if "Variable Symbol" <> '' then
            if "Variable Symbol" <> BankAccReconLine."Variable Symbol" then
                exit(false);
        if "Specific Symbol" <> '' then
            if "Specific Symbol" <> BankAccReconLine."Specific Symbol" then
                exit(false);
        if "Constant Symbol" <> '' then
            if "Constant Symbol" <> BankAccReconLine."Constant Symbol" then
                exit(false);
        if "Bank Account No." <> '' then
            if "Bank Account No." <> BankAccReconLine."Related-Party Bank Acc. No." then
                exit(false);
        if IBAN <> '' then
            if IBAN <> BankAccReconLine.IBAN then
                exit(false);
        if "SWIFT Code" <> '' then
            if "SWIFT Code" <> BankAccReconLine."SWIFT Code" then
                exit(false);
        exit(true);
    end;

    local procedure DisabledCheckMappingText(): Boolean
    begin
        // NAVCZ
        exit(true);
    end;

    procedure SearchEnteriesInText(var TextToAccountMapping: Record "Text-to-Account Mapping"; LineDescription: Text; VendorNo: Code[20]): Integer
    var
        TempTextToAccountMapping: Record "Text-to-Account Mapping" temporary;
        TempDefaultTextToAccountMapping: Record "Text-to-Account Mapping" temporary;
        ResultCount: Integer;
    begin
        if SearchExactMapping(TextToAccountMapping, LineDescription, VendorNo) then
            exit(1);

        TextToAccountMapping.Reset();
        TextToAccountMapping.SetRange("Vendor No.", VendorNo);
        if not TextToAccountMapping.FindSet then
            exit(ResultCount);

        repeat
            if TextToAccountMapping."Mapping Text" = '' then // Default mapping
                TempDefaultTextToAccountMapping.Copy(TextToAccountMapping)
            else
                if StrPos(UpperCase(LineDescription), UpperCase(TextToAccountMapping."Mapping Text")) > 0 then begin
                    TempTextToAccountMapping.Copy(TextToAccountMapping);
                    TempTextToAccountMapping.Insert();
                end;
        until TextToAccountMapping.Next() = 0;

        ResultCount := TempTextToAccountMapping.Count();
        if ResultCount = 0 then
            if TempDefaultTextToAccountMapping."Line No." <> 0 then begin
                TextToAccountMapping.Copy(TempDefaultTextToAccountMapping);
                exit(1);
            end;

        if ResultCount <> 1 then
            exit(ResultCount);

        TempTextToAccountMapping.FindFirst;
        TextToAccountMapping.Copy(TempTextToAccountMapping);
        exit(ResultCount);
    end;

    local procedure SearchExactMapping(var TextToAccountMapping: Record "Text-to-Account Mapping"; LineDescription: Text; VendorNo: Code[20]): Boolean
    begin
        TextToAccountMapping.Reset();
        TextToAccountMapping.SetRange("Vendor No.", VendorNo);
        TextToAccountMapping.SetFilter("Mapping Text", '%1', '@' + DelChr(LineDescription, '=', FilterInvalidCharTxt));
        exit(TextToAccountMapping.FindFirst);
    end;
}

