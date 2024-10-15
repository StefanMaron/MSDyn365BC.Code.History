table 12181 "Vendor Bill Header"
{
    Caption = 'Vendor Bill Header';
    LookupPageID = "List of Open Vendor Bills";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    PurchSetup.Get;
                    NoSeriesMgt.TestManual(PurchSetup."Temporary Bill List No.");
                    "No. Series" := '';
                end;
            end;
        }
        field(5; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";

            trigger OnValidate()
            begin
                BankAccount.Get("Bank Account No.");
                if BankAccount.Blocked then
                    Error(Text1130006,
                      FieldCaption("Bank Account No."),
                      "Bank Account No.");

                Validate("Currency Code", BankAccount."Currency Code");
            end;
        }
        field(10; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method" WHERE("Bill Code" = FILTER(<> ''));

            trigger OnValidate()
            begin
                if "Payment Method Code" = xRec."Payment Method Code" then
                    exit;

                PaymentMethod.Get("Payment Method Code");
                PaymentMethod.TestField("Bill Code");

                GetLines;
                if VendorBillLine.FindFirst then
                    Error(PaymentMethodCodeErr);

                "Report Header" := PaymentMethod.Description;
            end;
        }
        field(12; "Vendor Bill List No."; Code[20])
        {
            Caption = 'Vendor Bill List No.';
        }
        field(19; "List Status"; Option)
        {
            Caption = 'List Status';
            OptionCaption = 'Open,Sent';
            OptionMembers = Open,Sent;
        }
        field(20; "List Date"; Date)
        {
            Caption = 'List Date';

            trigger OnValidate()
            begin
                if "Posting Date" = 0D then
                    "Posting Date" := "List Date";

                if "List Date" > "Posting Date" then
                    Error(Text1130010,
                      FieldCaption("List Date"),
                      FieldCaption("Posting Date"));

                if "Currency Code" <> '' then
                    UpdateCurrencyFactor;
            end;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Beneficiary Value Date"; Date)
        {
            Caption = 'Beneficiary Value Date';

            trigger OnValidate()
            begin
                if "Beneficiary Value Date" = xRec."Beneficiary Value Date" then
                    exit;

                GetLines;
                if VendorBillLine.FindFirst then
                    Error(BeneficiaryValueDateErr);
            end;
        }
        field(30; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;

                GetLines;
                if VendorBillLine.FindFirst then
                    Error(CurrencyCodeErr);

                UpdateCurrencyFactor;
            end;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(50; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(60; "Total Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Vendor Bill Line"."Amount to Pay" WHERE("Vendor Bill List No." = FIELD("No.")));
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Bank Expense"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bank Expense';
            MinValue = 0;
        }
        field(70; "Report Header"; Text[30])
        {
            Caption = 'Report Header';
        }
        field(71; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(72; "Exported to File"; Boolean)
        {
            Caption = 'Exported to File';
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
    begin
        GetLines;
        if VendorBillLine.FindFirst then
            VendorBillLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            PurchSetup.Get;
            PurchSetup.TestField("Temporary Bill List No.");
            NoSeriesMgt.InitSeries(PurchSetup."Temporary Bill List No.",
              "No. Series", 0D, "No.", "No. Series");
        end;

        "List Date" := WorkDate;
        "Posting Date" := WorkDate;
        "User ID" := UserId;
    end;

    trigger OnRename()
    begin
        Error(Text1130004, TableCaption);
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        CurrExchRate: Record "Currency Exchange Rate";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text1130004: Label 'You cannot rename a %1.';
        Text1130006: Label '%1 %2 is blocked.';
        PaymentMethodCodeErr: Label 'You cannot change the Payment Method Code because there are vendor bill lines associated to this vendor bill header.';
        BeneficiaryValueDateErr: Label 'You cannot change the Beneficiary Value Date because there are vendor bill lines associated to this vendor bill header.';
        CurrencyCodeErr: Label 'You cannot change the Currency Code because there are vendor bill lines associated to this vendor bill header.';
        Text1130010: Label '%1 must not be greater than %2.';
        ExportAgainQst: Label 'The selected vendor bill list has already been exported. Do you want to export again?';

    [Scope('OnPrem')]
    procedure AssistEdit(OldVendorBillHeader: Record "Vendor Bill Header"): Boolean
    begin
        with VendorBillHeader do begin
            VendorBillHeader := Rec;
            PurchSetup.Get;
            PurchSetup.TestField("Temporary Bill List No.");
            if NoSeriesMgt.SelectSeries(PurchSetup."Temporary Bill List No.",
                 OldVendorBillHeader."No. Series", "No. Series")
            then begin
                PurchSetup.Get;
                PurchSetup.TestField("Temporary Bill List No.");
                NoSeriesMgt.SetSeries("No.");
                Rec := VendorBillHeader;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then
            "Currency Factor" := CurrExchRate.ExchangeRate("List Date", "Currency Code")
        else
            "Currency Factor" := 0;
    end;

    [Scope('OnPrem')]
    procedure GetLines()
    begin
        VendorBillLine.Reset;
        VendorBillLine.SetRange("Vendor Bill List No.", "No.");
    end;

    [Scope('OnPrem')]
    procedure ExportToFile()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        SetRecFilter;

        if "Exported to File" then
            if not Confirm(ExportAgainQst) then
                exit;

        BankAccount.Get("Bank Account No.");
        GenJnlLine.SetRange("Journal Template Name", '');
        GenJnlLine.SetRange("Journal Batch Name", '');
        GenJnlLine.SetRange("Document No.", "No.");
        GenJnlLine."Bal. Account No." := BankAccount."No.";
        CODEUNIT.Run(BankAccount.GetPaymentExportCodeunitID, GenJnlLine);
        "Exported to File" := true;
        Modify;
    end;
}

