table 11708 "Payment Order Header"
{
    Caption = 'Payment Order Header';
#if not CLEAN19
    DataCaptionFields = "No.", "Bank Account No.", "Bank Account Name";
    LookupPageID = "Payment Order List";
    ObsoleteState = Pending;
#else
    ObsoleteState = Removed;
#endif
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
#if not CLEAN19

            trigger OnValidate()
            begin
                if ("No." <> xRec."No.") and ("Bank Account No." <> '') then begin
                    BankAccount.Get("Bank Account No.");
                    NoSeriesMgt.TestManual(BankAccount."Payment Order Nos.");
                    "No. Series" := '';
                end;
            end;
#endif
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
            NotBlank = true;
#if CLEAN17
            TableRelation = "Bank Account";
#else
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Bank Account"));
#endif
#if not CLEAN19

            trigger OnValidate()
            var
                BankAccount: Record "Bank Account";
            begin
                TestStatusOpen;
                if not BankAccount.Get("Bank Account No.") then
                    BankAccount.Init();
                "Account No." := BankAccount."Bank Account No.";
                BankAccount.TestField(Blocked, false);
                IBAN := BankAccount.IBAN;
                "SWIFT Code" := BankAccount."SWIFT Code";
                Validate("Currency Code", BankAccount."Currency Code");

                CalcFields("Bank Account Name");

                if BankAccount."Bank Account No." <> "Bank Account No." then
                    BankAccount.Get("Bank Account No.");
                "Foreign Payment Order" := BankAccount."Foreign Payment Orders";
            end;
#endif
        }
#if not CLEAN19
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(5; "Account No."; Text[30])
        {
            Caption = 'Account No.';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
#endif
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor;
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmUpdateCurrencyFactor;
                end;
            end;
#endif
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then begin
                        UpdateCurrencyFactor;
                        UpdatePayOrderLine(FieldCaption("Currency Code"));
                    end else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;

                Validate("Payment Order Currency Code", "Currency Code");
            end;
#endif
        }
        field(8; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Currency Code" = "Payment Order Currency Code" then
                    "Payment Order Currency Factor" := "Currency Factor";
                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdatePayOrderLine(FieldCaption("Currency Factor"));
            end;
#endif
        }
#if not CLEAN19
        field(9; Amount; Decimal)
        {
            CalcFormula = Sum("Payment Order Line"."Amount to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                          "Skip Payment" = CONST(false)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum("Payment Order Line"."Amount (LCY) to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                                "Skip Payment" = CONST(false)));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; Debit; Decimal)
        {
            CalcFormula = Sum("Payment Order Line"."Amount to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                          Positive = CONST(true),
                                                                          "Skip Payment" = CONST(false)));
            Caption = 'Debit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Debit (LCY)"; Decimal)
        {
            CalcFormula = Sum("Payment Order Line"."Amount (LCY) to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                                Positive = CONST(true),
                                                                                "Skip Payment" = CONST(false)));
            Caption = 'Debit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Credit; Decimal)
        {
            CalcFormula = - Sum("Payment Order Line"."Amount to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                           Positive = CONST(false),
                                                                           "Skip Payment" = CONST(false)));
            Caption = 'Credit';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Credit (LCY)"; Decimal)
        {
            CalcFormula = - Sum("Payment Order Line"."Amount (LCY) to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                                 Positive = CONST(false),
                                                                                 "Skip Payment" = CONST(false)));
            Caption = 'Credit (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "No. of Lines"; Integer)
        {
            CalcFormula = Count("Payment Order Line" WHERE("Payment Order No." = FIELD("No.")));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
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
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
                if CurrFieldNo <> FieldNo("Payment Order Currency Code") then
                    UpdateOrderCurrencyFactor
                else
                    if "Payment Order Currency Code" <> xRec."Payment Order Currency Code" then begin
                        UpdateOrderCurrencyFactor;
                        UpdatePayOrderLine(FieldCaption("Payment Order Currency Code"));
                    end else
                        if "Payment Order Currency Code" <> '' then begin
                            UpdateOrderCurrencyFactor;
                            if "Payment Order Currency Factor" <> xRec."Payment Order Currency Factor" then
                                ConfUpdateOrderCurrencyFactor;
                        end;
            end;
#endif
        }
        field(21; "Payment Order Currency Factor"; Decimal)
        {
            Caption = 'Payment Order Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Currency Code" = "Payment Order Currency Code" then
                    "Currency Factor" := "Payment Order Currency Factor";
                if "Payment Order Currency Factor" <> xRec."Payment Order Currency Factor" then
                    UpdatePayOrderLine(FieldCaption("Payment Order Currency Factor"));
            end;
#endif
        }
#if not CLEAN19
        field(25; "Amount (Pay.Order Curr.)"; Decimal)
        {
            CalcFormula = Sum("Payment Order Line"."Amount(Pay.Order Curr.) to Pay" WHERE("Payment Order No." = FIELD("No."),
                                                                                           "Skip Payment" = CONST(false)));
            Caption = 'Amount (Pay.Order Curr.)';
            Editable = false;
            FieldClass = FlowField;
        }
#endif
        field(30; "Last Issuing No."; Code[20])
        {
            Caption = 'Last Issuing No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
#endif
        }
        field(55; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(60; "Foreign Payment Order"; Boolean)
        {
            Caption = 'Foreign Payment Order';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
#endif
        }
        field(90; IBAN; Code[50])
        {
            Caption = 'IBAN';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
#endif
        }
        field(95; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
#if not CLEAN19

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
#endif
        }
        field(100; "Uncertainty Pay.Check DateTime"; DateTime)
        {
            Caption = 'Uncertainty Pay.Check DateTime';
            Editable = false;
        }
        field(120; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Approved,Pending Approval';
            OptionMembers = Open,Approved,"Pending Approval";
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
    begin
        ApprovalsMgmt.DeleteApprovalEntryForRecord(Rec);

        DeleteLines;
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            BankAccount.Get("Bank Account No.");
            BankAccount.TestField("Payment Order Nos.");
            NoSeriesMgt.InitSeries(BankAccount."Payment Order Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Last Date Modified" := Today;
        "User ID" := UserId;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := UserId;
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        BankAccount: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        UpdateCurrFactorQst: Label 'Do you want to update the exchange rate?';
        UpdateOrderLineQst: Label 'You have modified %1.\\Do you want to update the lines?', Comment = '%1=ChangedFieldName';
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        StatusCheckSuspended: Boolean;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure AssistEdit(OldPaymentOrderHeader: Record "Payment Order Header"): Boolean
    var
        PaymentOrderHeader: Record "Payment Order Header";
    begin
        with PaymentOrderHeader do begin
            PaymentOrderHeader := Rec;
            BankAccount.Get("Bank Account No.");
            BankAccount.TestField("Payment Order Nos.");
            if NoSeriesMgt.SelectSeries(BankAccount."Payment Order Nos.", OldPaymentOrderHeader."No. Series", "No. Series") then begin
                BankAccount.Get("Bank Account No.");
                BankAccount.TestField("Bank Account No.");
                NoSeriesMgt.SetSeries("No.");
                Rec := PaymentOrderHeader;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then
            "Currency Factor" := CurrExchRate.ExchangeRate("Document Date", "Currency Code")
        else
            "Currency Factor" := 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        if Confirm(UpdateCurrFactorQst, false) then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure UpdatePayOrderLine(ChangedFieldName: Text[30])
    var
        PaymentOrderLine: Record "Payment Order Line";
        Question: Text[250];
    begin
        Modify;
        if PaymentOrderLinesExist then begin
            Question := StrSubstNo(UpdateOrderLineQst, ChangedFieldName);
            if DIALOG.Confirm(Question, true) then begin
                PaymentOrderLine.LockTable();
                Modify;

                PaymentOrderLine.Reset();
                PaymentOrderLine.SetRange("Payment Order No.", "No.");
                if PaymentOrderLine.Find('-') then
                    repeat
                        case ChangedFieldName of
                            FieldCaption("Currency Code"):
                                begin
                                    PaymentOrderLine.Validate("Currency Code", "Currency Code");
                                    PaymentOrderLine.Validate("Amount(Pay.Order Curr.) to Pay");
                                end;
                            FieldCaption("Currency Factor"):
                                begin
                                    if "Currency Code" = "Payment Order Currency Code" then
                                        PaymentOrderLine."Payment Order Currency Factor" := "Payment Order Currency Factor";
                                    PaymentOrderLine.Validate("Amount(Pay.Order Curr.) to Pay");
                                end;
                            FieldCaption("Payment Order Currency Code"):
                                begin
                                    PaymentOrderLine."Payment Order Currency Factor" := "Payment Order Currency Factor";
                                    PaymentOrderLine."Payment Order Currency Code" := "Payment Order Currency Code";
                                    case true of
                                        (PaymentOrderLine."Applies-to C/V/E Entry No." <> 0):
                                            begin
                                                PaymentOrderLine."Amount to Pay" := 0;
                                                PaymentOrderLine.Validate("Applies-to C/V/E Entry No.");
                                            end
                                        else
                                            PaymentOrderLine.Validate("Amount (LCY) to Pay");
                                    end;
                                end;
                            FieldCaption("Payment Order Currency Factor"):
                                begin
                                    PaymentOrderLine."Payment Order Currency Factor" := "Payment Order Currency Factor";
                                    if PaymentOrderLine."Payment Order Currency Code" = PaymentOrderLine."Applied Currency Code" then
                                        PaymentOrderLine.Validate("Amount(Pay.Order Curr.) to Pay")
                                    else
                                        PaymentOrderLine.Validate("Amount (LCY) to Pay");
                                end;
                        end;
                        PaymentOrderLine.Modify(true);
                    until PaymentOrderLine.Next() = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure PaymentOrderLinesExist(): Boolean
    var
        PaymentOrderLine: Record "Payment Order Line";
    begin
        PaymentOrderLine.Reset();
        PaymentOrderLine.SetRange("Payment Order No.", "No.");
        exit(PaymentOrderLine.FindFirst);
    end;

    local procedure UpdateOrderCurrencyFactor()
    begin
        if "Payment Order Currency Code" <> '' then
            "Payment Order Currency Factor" := CurrExchRate.ExchangeRate("Document Date", "Payment Order Currency Code")
        else
            "Payment Order Currency Factor" := 0;

        if "Currency Code" = "Payment Order Currency Code" then
            "Currency Factor" := "Payment Order Currency Factor";
    end;

    local procedure ConfUpdateOrderCurrencyFactor()
    begin
        if Confirm(UpdateCurrFactorQst, false) then
            Validate("Payment Order Currency Factor")
        else
            "Payment Order Currency Factor" := xRec."Payment Order Currency Factor";
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure ImportPaymentOrder()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bank Account No.");
        if BankAcc.GetPaymentImportCodeunitID > 0 then
            CODEUNIT.Run(BankAcc.GetPaymentImportCodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Imp. Launcher Payment Order", Rec);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure TestPrintRecords(ShowRequestForm: Boolean)
    var
        PmtOrdHdr: Record "Payment Order Header";
    begin
        PmtOrdHdr.Copy(Rec);
        REPORT.RunModal(REPORT::"Payment Order - Test", ShowRequestForm, false, PmtOrdHdr);
    end;

    local procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        TestField(Status, Status::Open);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    local procedure IsApprovedForIssuing(): Boolean
    begin
        if ApprovalsMgmt.PreIssueApprovalCheckPaymentOrder(Rec) then
            exit(true);
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure SendToIssuing(IssuingCodeunitID: Integer)
    begin
        if not IsApprovedForIssuing then
            exit;
        CODEUNIT.Run(IssuingCodeunitID, Rec);
    end;

    local procedure DeleteLines()
    var
        PaymentOrderLine: Record "Payment Order Line";
    begin
        PaymentOrderLine.SetRange("Payment Order No.", "No.");
        if PaymentOrderLine.FindSet then
            repeat
                PaymentOrderLine.SuspendStatusCheck(StatusCheckSuspended);
                PaymentOrderLine.Delete(true);
            until PaymentOrderLine.Next() = 0;
    end;

#endif
#if not CLEAN17
    [Obsolete('Moved to Core Localization Pack for Czech.', '17.5')]
    procedure ImportUncPayerStatus()
    var
        PaymentOrderLine: Record "Payment Order Line";
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
    begin
        ClearLastError;
        if not UncPayerMgt.ImportUncPayerStatusForPaymentOrder(Rec) then begin
            if GetLastErrorText <> '' then
                Error(GetLastErrorText);
            exit;
        end;

        "Uncertainty Pay.Check DateTime" := CurrentDateTime;
        Modify;

        PaymentOrderLine.SetRange("Payment Order No.", "No.");
        PaymentOrderLine.SetRange(Type, PaymentOrderLine.Type::Vendor);
        PaymentOrderLine.SetRange("Skip Payment", false);
        if PaymentOrderLine.FindSet then
            repeat
                if PaymentOrderLine.IsUncertaintyPayerCheckPossible then begin
                    PaymentOrderLine."VAT Uncertainty Payer" := PaymentOrderLine.HasUncertaintyPayer;
                    PaymentOrderLine."Public Bank Account" := PaymentOrderLine.HasPublicBankAccount;
                    PaymentOrderLine.Modify();
                end;
            until PaymentOrderLine.Next() = 0;
    end;

#endif
#if not CLEAN19
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure UncertaintyPayerCheckExpired(): Boolean
    begin
        if "Uncertainty Pay.Check DateTime" = 0DT then
            exit(true);

        exit(Today - DT2Date("Uncertainty Pay.Check DateTime") >= 2);
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    [Obsolete('Moved to Banking Documents Localization for Czech.', '19.0')]
    procedure OnCheckPaymentOrderIssueRestrictions()
    begin
    end;
#endif
}

