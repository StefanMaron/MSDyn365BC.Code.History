table 11706 "Issued Bank Statement Header"
{
    Caption = 'Issued Bank Statement Header';
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
#if not CLEAN19
    DrillDownPageID = "Issued Bank Statement List";
    LookupPageID = "Issued Bank Statement List";
    Permissions = TableData "Issued Bank Statement Header" = m,
                  TableData "Issued Bank Statement Line" = md;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
#endif
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(8; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(9; Amount; Decimal)
        {
            CalcFormula = Sum("Issued Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Issued Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = - Sum("Issued Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No."),
                                                                          Positive = CONST(false)));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = - Sum("Issued Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No."),
                                                                                  Positive = CONST(false)));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = Sum("Issued Bank Statement Line".Amount WHERE("Bank Statement No." = FIELD("No."),
                                                                         Positive = CONST(true)));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = Sum("Issued Bank Statement Line"."Amount (LCY)" WHERE("Bank Statement No." = FIELD("No."),
                                                                                 Positive = CONST(true)));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = Count("Issued Bank Statement Line" WHERE("Bank Statement No." = FIELD("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(17; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(20; "Bank Statement Currency Code"; Code[10])
        {
            Caption = 'Bank Statement Currency Code';
            TableRelation = Currency;
        }
        field(21; "Bank Statement Currency Factor"; Decimal)
        {
            Caption = 'Bank Statement Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
        }
        field(25; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(26; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(30; "Pre-Assigned User ID"; Code[50])
        {
            Caption = 'Pre-Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Check Amount"; Decimal)
        {
            Caption = 'Check Amount';
            Editable = false;
        }
        field(65; "Check Amount (LCY)"; Decimal)
        {
            Caption = 'Check Amount (LCY)';
            Editable = false;
        }
        field(70; "Check Debit"; Decimal)
        {
            Caption = 'Check Debit';
            Editable = false;
        }
        field(75; "Check Debit (LCY)"; Decimal)
        {
            Caption = 'Check Debit (LCY)';
            Editable = false;
        }
        field(80; "Check Credit"; Decimal)
        {
            Caption = 'Check Credit';
            Editable = false;
        }
        field(85; "Check Credit (LCY)"; Decimal)
        {
            Caption = 'Check Credit (LCY)';
            Editable = false;
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(100; "Payment Reconciliation Status"; Option)
        {
            Caption = 'Payment Reconciliation Status';
            Editable = false;
            OptionCaption = ' ,Opened,Posted';
            OptionMembers = " ",Opened,Posted;
        }
    }

    keys
    {
        key(Key1; "No.")
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
        IssuedBankStmtLine: Record "Issued Bank Statement Line";
    begin
        IssuedBankStmtLine.SetRange("Bank Statement No.", "No.");
        IssuedBankStmtLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        ExistErr: Label '%1 %2 already exist.', Comment = '%1=TABLECAPTION,%2=No.';
        NotExistErr: Label 'Payment Reconciliation Journal %1 is not exist.', Comment = '%1=No.';

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        IssuedBankStmtHdr.Copy(Rec);
        REPORT.RunModal(REPORT::"Bank Statement", ShowRequestForm, false, IssuedBankStmtHdr);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure TestPrintRecords(ShowRequestForm: Boolean)
    var
        IssuedBankStmtHdr: Record "Issued Bank Statement Header";
    begin
        IssuedBankStmtHdr.Copy(Rec);
        REPORT.RunModal(REPORT::"Issued Bank Statement - Test", ShowRequestForm, false, IssuedBankStmtHdr);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure Navigate()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc("Document Date", "No.");
        NavigateForm.Run();
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure CheckPmtReconExist()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PostedPmtReconHdr: Record "Posted Payment Recon. Hdr";
    begin
        if PmtReconExist then
            Error(ExistErr, BankAccRecon.TableCaption, "No.");
        if PostedPmtReconExist then
            Error(ExistErr, PostedPmtReconHdr.TableCaption, "No.");
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure PmtReconExist(): Boolean
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
    begin
        SetBankAccReconFilter(BankAccRecon);
        exit(not BankAccRecon.IsEmpty);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure PostedPmtReconExist(): Boolean
    var
        PostedPmtReconHdr: Record "Posted Payment Recon. Hdr";
    begin
        SetPostedPmtReconHdrFilter(PostedPmtReconHdr);
        exit(not PostedPmtReconHdr.IsEmpty);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure LinesExist(): Boolean
    var
        IssuedBankStmtLine: Record "Issued Bank Statement Line";
    begin
        IssuedBankStmtLine.Reset();
        IssuedBankStmtLine.SetRange("Bank Statement No.", "No.");
        exit(not IssuedBankStmtLine.IsEmpty);
    end;

    local procedure SetBankAccReconFilter(var BankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        BankAccRecon.Reset();
        BankAccRecon.SetRange("Statement Type", BankAccRecon."Statement Type"::"Payment Application");
        BankAccRecon.SetRange("Bank Account No.", "Bank Account No.");
        BankAccRecon.SetRange("Statement No.", "No.");
    end;

    local procedure SetBankAccReconLnFilter(var BankAccReconLn: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconLn.Reset();
        BankAccReconLn.SetRange("Statement Type", BankAccReconLn."Statement Type"::"Payment Application");
        BankAccReconLn.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconLn.SetRange("Statement No.", "No.");
    end;

    local procedure SetPostedPmtReconHdrFilter(var PostedPmtReconHdr: Record "Posted Payment Recon. Hdr")
    begin
        PostedPmtReconHdr.Reset();
        PostedPmtReconHdr.SetRange("Bank Account No.", "Bank Account No.");
        PostedPmtReconHdr.SetRange("Statement No.", "No.");
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure OpenPmtRecon()
    var
        BankAccReconLn: Record "Bank Acc. Reconciliation Line";
    begin
        SetBankAccReconLnFilter(BankAccReconLn);
        PAGE.Run(PAGE::"Payment Reconciliation Journal", BankAccReconLn);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure OpenPostedPmtRecon()
    var
        PostedPmtReconHdr: Record "Posted Payment Recon. Hdr";
    begin
        SetPostedPmtReconHdrFilter(PostedPmtReconHdr);
        PAGE.Run(PAGE::"Posted Payment Reconciliation", PostedPmtReconHdr);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure OpenPmtReconOrPostedPmtRecon()
    begin
        case true of
            PmtReconExist:
                OpenPmtRecon;
            PostedPmtReconExist:
                OpenPostedPmtRecon;
            else
                Error(NotExistErr, "No.");
        end;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure CreatePmtReconJnl(ShowRequestForm: Boolean)
    begin
        CreatePmtReconJnl(ShowRequestForm, false);
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure CreatePmtReconJnl(ShowRequestForm: Boolean; HideMessages: Boolean)
    begin
        OnBeforeCreatePmtReconJnl(Rec);

        RunPaymentReconJournalCreation(ShowRequestForm, HideMessages);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure UpdatePaymentReconciliationStatus(PaymentReconciliationStatus: Option)
    begin
        Validate("Payment Reconciliation Status", PaymentReconciliationStatus);
        Modify;
    end;

    local procedure RunPaymentReconJournalCreation(ShowRequestForm: Boolean; HideMessages: Boolean)
    var
        IssuedBankStatementHeader: Record "Issued Bank Statement Header";
        CreatePaymentReconJournal: Report "Create Payment Recon. Journal";
        IsHandled: Boolean;
    begin
        OnBeforeRunPaymentReconJournalCreation(Rec, ShowRequestForm, HideMessages, IsHandled);
        if IsHandled then
            exit;

        IssuedBankStatementHeader.Copy(Rec);
        CreatePaymentReconJournal.SetTableView(IssuedBankStatementHeader);
        CreatePaymentReconJournal.UseRequestPage(ShowRequestForm);
        CreatePaymentReconJournal.SetHideMessages(HideMessages);
        CreatePaymentReconJournal.RunModal();
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePmtReconJnl(var IssuedBankStatHeader: record "Issued Bank Statement Header")
    begin
    end;

    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPaymentReconJournalCreation(var IssuedBankStatementHeader: Record "Issued Bank Statement Header"; var ShowRequestForm: Boolean; var HideMessages: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif
}
