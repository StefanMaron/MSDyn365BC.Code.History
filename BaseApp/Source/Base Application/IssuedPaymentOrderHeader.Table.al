table 11710 "Issued Payment Order Header"
{
    Caption = 'Issued Payment Order Header';
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
    DrillDownPageID = "Issued Payment Order List";
    LookupPageID = "Issued Payment Order List";
    Permissions = TableData "Issued Payment Order Header" = m,
                  TableData "Issued Payment Order Line" = md;

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
            Editable = true;
            NotBlank = true;
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Bank Account"));
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup ("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
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
            CalcFormula = Sum ("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                        Status = CONST(" ")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                Status = CONST(" ")));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = Sum ("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                        Positive = CONST(true),
                                                                        Status = CONST(" ")));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                Positive = CONST(true),
                                                                                Status = CONST(" ")));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = - Sum ("Issued Payment Order Line".Amount WHERE("Payment Order No." = FIELD("No."),
                                                                         Positive = CONST(false),
                                                                         Status = CONST(" ")));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = - Sum ("Issued Payment Order Line"."Amount (LCY)" WHERE("Payment Order No." = FIELD("No."),
                                                                                 Positive = CONST(false),
                                                                                 Status = CONST(" ")));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = Count ("Issued Payment Order Line" WHERE("Payment Order No." = FIELD("No.")));
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
        field(20; "Payment Order Currency Code"; Code[10])
        {
            Caption = 'Payment Order Currency Code';
            TableRelation = Currency;
        }
        field(21; "Payment Order Currency Factor"; Decimal)
        {
            Caption = 'Payment Order Currency Factor';
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
        field(50; "No. exported"; Integer)
        {
            Caption = 'No. exported';
            Editable = false;
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Foreign Payment Order"; Boolean)
        {
            Caption = 'Foreign Payment Order';
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
        }
        field(100; "Uncertainty Pay.Check DateTime"; DateTime)
        {
            Caption = 'Uncertainty Pay.Check DateTime';
            Editable = false;
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

    trigger OnDelete()
    var
        IssuedPaymentOrderLine: Record "Issued Payment Order Line";
    begin
        IssuedPaymentOrderLine.SetRange("Payment Order No.", "No.");
        IssuedPaymentOrderLine.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        NothingToExportErr: Label 'There is nothing to export.';

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
    begin
        IssuedPmtOrdHdr.Copy(Rec);
        REPORT.RunModal(REPORT::"Payment Order", ShowRequestForm, false, IssuedPmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure PrintDomesticPmtOrd(ShowRequestForm: Boolean)
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bank Account No.");
        BankAcc.TestField("Domestic Payment Order");

        IssuedPmtOrdHdr.Copy(Rec);
        REPORT.Run(BankAcc."Domestic Payment Order", ShowRequestForm, false, IssuedPmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure PrintForeignPmtOrd(ShowRequestForm: Boolean)
    var
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bank Account No.");
        BankAcc.TestField("Foreign Payment Order");

        IssuedPmtOrdHdr.Copy(Rec);
        REPORT.Run(BankAcc."Foreign Payment Order", ShowRequestForm, false, IssuedPmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Document Date", "No.");
        NavigatePage.Run;
    end;

    [Scope('OnPrem')]
    procedure IncreaseNoExported()
    begin
        "No. exported" += 1;
        Modify;
    end;

    [Scope('OnPrem')]
    procedure ExportPmtOrd()
    var
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
        BankAcc: Record "Bank Account";
        CodeunitID: Integer;
    begin
        IssuedPmtOrdLn.SetRange("Payment Order No.", "No.");
        if IssuedPmtOrdLn.IsEmpty then
            Error(NothingToExportErr);

        BankAcc.Get("Bank Account No.");
        if "Foreign Payment Order" then
            CodeunitID := BankAcc.GetForeignPaymentExportCodeunitID
        else
            CodeunitID := BankAcc.GetPaymentExportCodeunitID;

        if CodeunitID > 0 then
            CODEUNIT.Run(CodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Payment Order", Rec);

        if Find then
            IncreaseNoExported;
    end;

    [Scope('OnPrem')]
    procedure CreatePmtJnl(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLn: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        IssuedPmtOrdLn.SetRange("Payment Order No.", "No.");
        if IssuedPmtOrdLn.IsEmpty then
            exit;

        GenJnlBatch.Get(JnlTemplateName, JnlBatchName);
        GenJnlBatch.TestField("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.TestField("Bal. Account No.", "Bank Account No.");
        GenJnlBatch.TestField("Allow Payment Export");
        GenJnlBatch.TestField("No. Series", '');

        GenJnlLn.Reset();
        GenJnlLn.FilterGroup(2);
        GenJnlLn.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLn.SetRange("Journal Batch Name", GenJnlBatch.Name);
        if GenJnlLn.FindLast then
            LineNo := GenJnlLn."Line No.";

        GenJnlLn.SetRange("Document No.", "No.");
        GenJnlLn.FilterGroup(0);

        if GenJnlLn.IsEmpty then begin
            IssuedPmtOrdLn.FindSet;
            repeat
                IssuedPmtOrdLn.TestField(Type);

                LineNo += 10000;
                GenJnlLn.Init();
                GenJnlLn."Journal Template Name" := GenJnlBatch."Journal Template Name";
                GenJnlLn."Journal Batch Name" := GenJnlBatch.Name;
                GenJnlLn."Line No." := LineNo;
                GenJnlLn.Insert();

                GenJnlLn."Posting Date" := "Document Date";
                GenJnlLn."Document Date" := "Document Date";
                GenJnlLn."VAT Date" := "Document Date";

                case IssuedPmtOrdLn.Type of
                    IssuedPmtOrdLn.Type::Vendor,
                  IssuedPmtOrdLn.Type::"Bank Account":
                        GenJnlLn."Document Type" := GenJnlLn."Document Type"::Payment;
                    IssuedPmtOrdLn.Type::Customer:
                        GenJnlLn."Document Type" := GenJnlLn."Document Type"::Refund;
                end;

                GenJnlLn."Document No." := "No.";
                GenJnlLn.Validate("Account Type", IssuedPmtOrdLn.ConvertTypeToGenJnlLineType);
                GenJnlLn.Validate("Account No.", IssuedPmtOrdLn."No.");
                GenJnlLn.Validate("Recipient Bank Account", IssuedPmtOrdLn."Cust./Vendor Bank Account Code");
                GenJnlLn.Validate(Amount, IssuedPmtOrdLn.Amount);
                GenJnlLn.Validate("Currency Code", "Payment Order Currency Code");
                GenJnlLn.Validate("Currency Factor", "Payment Order Currency Factor");
                GenJnlLn.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type");
                GenJnlLn.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                GenJnlLn.Validate("Payment Method Code", IssuedPmtOrdLn."Payment Method Code");
                GenJnlLn."Variable Symbol" := IssuedPmtOrdLn."Variable Symbol";
                GenJnlLn."Constant Symbol" := IssuedPmtOrdLn."Constant Symbol";
                GenJnlLn."Specific Symbol" := IssuedPmtOrdLn."Specific Symbol";
                GenJnlLn.Modify();
            until IssuedPmtOrdLn.Next = 0;
        end;
    end;
}

