table 232 "Gen. Journal Batch"
{
    Caption = 'Gen. Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "General Journal Batches";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    ModifyLines(FieldNo("Reason Code"));
                    Modify;
                end;
            end;
        }
        field(5; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
                Clear(BalAccountId);
                if "Bal. Account Type" <> "Bal. Account Type"::"G/L Account" then
                    "Bank Statement Import Format" := '';
            end;
        }
        field(6; "Bal. Account No."; Code[20])
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
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"G/L Account" then begin
                    CheckGLAcc("Bal. Account No.");
                    UpdateBalAccountId;
                end;
                CheckJnlIsNotRecurring;
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    GenJnlTemplate.Get("Journal Template Name");
                    if GenJnlTemplate.Recurring then
                        Error(
                          Text000,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(8; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
                ModifyLines(FieldNo("Posting No. Series"));
                Modify;
            end;
        }
        field(9; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            InitValue = true;
        }
        field(10; "Allow VAT Difference"; Boolean)
        {
            Caption = 'Allow VAT Difference';

            trigger OnValidate()
            begin
                if "Allow VAT Difference" then begin
                    GenJnlTemplate.Get("Journal Template Name");
                    GenJnlTemplate.TestField("Allow VAT Difference", true);
                end;
            end;
        }
        field(11; "Allow Payment Export"; Boolean)
        {
            Caption = 'Allow Payment Export';
        }
        field(12; "Bank Statement Import Format"; Code[20])
        {
            Caption = 'Bank Statement Import Format';
            TableRelation = "Bank Export/Import Setup".Code WHERE(Direction = CONST(Import));

            trigger OnValidate()
            begin
                if ("Bank Statement Import Format" <> '') and ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") then
                    FieldError("Bank Statement Import Format", BankStmtImpFormatBalAccErr);
            end;
        }
        field(21; "Template Type"; Option)
        {
            CalcFormula = Lookup ("Gen. Journal Template".Type WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'General,Sales,Purchases,Cash Receipts,Payments,Assets,Intercompany,Jobs';
            OptionMembers = General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,Jobs;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = Lookup ("Gen. Journal Template".Recurring WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Suggest Balancing Amount"; Boolean)
        {
            Caption = 'Suggest Balancing Amount';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
        }
        field(8001; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8002; BalAccountId; Guid)
        {
            Caption = 'BalAccountId';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if not IsNullGuid(BalAccountId) then begin
                    GLAccount.SetRange(Id, BalAccountId);
                    if not GLAccount.FindFirst then
                        Error(BalAccountIdDoesNotMatchAGLAccountErr);

                    CheckGLAcc(GLAccount."No.");
                end;

                Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
                Validate("Bal. Account No.", GLAccount."No.");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ApprovalsMgmt.OnCancelGeneralJournalBatchApprovalRequest(Rec);

        GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", Name);
        GenJnlAlloc.DeleteAll;
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", Name);
        GenJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable;
        GenJnlTemplate.Get("Journal Template Name");
        if not GenJnlTemplate."Copy VAT Setup to Jnl. Lines" then
            "Copy VAT Setup to Jnl. Lines" := false;
        "Allow Payment Export" := GenJnlTemplate.Type = GenJnlTemplate.Type::Payments;

        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    begin
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);

        SetLastModifiedDateTime;
    end;

    var
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        BankStmtImpFormatBalAccErr: Label 'must be blank. When Bal. Account Type = Bank Account, then Bank Statement Import Format on the Bank Account card will be used', Comment = 'FIELDERROR ex: Bank Statement Import Format must be blank. When Bal. Account Type = Bank Account, then Bank Statement Import Format on the Bank Account card will be used in Gen. Journal Batch Journal Template Name=''GENERAL'',Name=''CASH''.';
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        CannotBeSpecifiedForRecurrJnlErr: Label 'cannot be specified when using recurring journals';
        BalAccountIdDoesNotMatchAGLAccountErr: Label 'The "balancingAccountNumber" does not match to a G/L Account.', Locked = true;

    procedure SetupNewBatch()
    begin
        GenJnlTemplate.Get("Journal Template Name");
        "Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
        "Bal. Account No." := GenJnlTemplate."Bal. Account No.";
        "No. Series" := GenJnlTemplate."No. Series";
        "Posting No. Series" := GenJnlTemplate."Posting No. Series";
        "Reason Code" := GenJnlTemplate."Reason Code";
        "Copy VAT Setup to Jnl. Lines" := GenJnlTemplate."Copy VAT Setup to Jnl. Lines";
        "Allow VAT Difference" := GenJnlTemplate."Allow VAT Difference";
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc;
            GLAcc.TestField("Direct Posting", true);
        end;
    end;

    local procedure CheckJnlIsNotRecurring()
    begin
        if "Bal. Account No." = '' then
            exit;

        GenJnlTemplate.Get("Journal Template Name");
        if GenJnlTemplate.Recurring then
            FieldError("Bal. Account No.", CannotBeSpecifiedForRecurrJnlErr);
    end;

    local procedure ModifyLines(i: Integer)
    begin
        GenJnlLine.LockTable;
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", Name);
        if GenJnlLine.Find('-') then
            repeat
                case i of
                    FieldNo("Reason Code"):
                        GenJnlLine.Validate("Reason Code", "Reason Code");
                    FieldNo("Posting No. Series"):
                        GenJnlLine.Validate("Posting No. Series", "Posting No. Series");
                end;
                GenJnlLine.Modify(true);
            until GenJnlLine.Next = 0;
    end;

    procedure LinesExist(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", Name);
        exit(not GenJournalLine.IsEmpty);
    end;

    procedure GetBalance(): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", Name);
        GenJournalLine.CalcSums("Balance (LCY)");
        exit(GenJournalLine."Balance (LCY)");
    end;

    procedure CheckBalance() Balance: Decimal
    begin
        Balance := GetBalance;

        if Balance = 0 then
            OnGeneralJournalBatchBalanced
        else
            OnGeneralJournalBatchNotBalanced;
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnGeneralJournalBatchBalanced()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnGeneralJournalBatchNotBalanced()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLineExportRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnMoveGenJournalBatch(ToRecordID: RecordID)
    begin
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;

    procedure UpdateBalAccountId()
    var
        GLAccount: Record "G/L Account";
    begin
        if "Bal. Account No." = '' then begin
            Clear(BalAccountId);
            exit;
        end;

        if not GLAccount.Get("Bal. Account No.") then
            exit;

        BalAccountId := GLAccount.Id;
    end;
}

