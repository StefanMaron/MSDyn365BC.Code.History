table 31051 "Credit Line"
{
    Caption = 'Credit Line';
    DrillDownPageID = "Credit Lines";
    LookupPageID = "Credit Lines";

    fields
    {
        field(5; "Credit No."; Code[20])
        {
            Caption = 'Credit No.';
            TableRelation = "Credit Header";
        }
        field(10; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(15; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;

            trigger OnValidate()
            begin
                Clear("Source Entry No.");
                Validate("Source Entry No.");
            end;
        }
        field(20; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor."No.";
        }
        field(22; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = IF ("Source Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Source Type" = CONST(Vendor)) "Vendor Posting Group";

            trigger OnValidate()
            var
                PostingGroupManagement: Codeunit "Posting Group Management";
            begin
                if CurrFieldNo = FieldNo("Posting Group") then
                    PostingGroupManagement.CheckPostingGroupChange("Posting Group", xRec."Posting Group", Rec);
            end;
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(25; "Source Entry No."; Integer)
        {
            Caption = 'Source Entry No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) "Cust. Ledger Entry"."Entry No." WHERE(Open = CONST(true))
            ELSE
            IF ("Source Type" = CONST(Vendor)) "Vendor Ledger Entry"."Entry No." WHERE(Open = CONST(true));

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            if "Source Entry No." <> 0 then
                                if CustLedgEntry.Get("Source Entry No.") then;
                            CustLedgEntry.SetCurrentKey(Open);
                            CustLedgEntry.SetRange(Open, true);
                            CustLedgEntry.SetRange(Prepayment, false);
                            if ACTION::LookupOK = PAGE.RunModal(0, CustLedgEntry) then
                                Validate("Source Entry No.", CustLedgEntry."Entry No.");
                        end;
                    "Source Type"::Vendor:
                        begin
                            if "Source Entry No." <> 0 then
                                if not VendLedgEntry.Get("Source Entry No.") then;
                            VendLedgEntry.SetCurrentKey(Open);
                            VendLedgEntry.SetRange(Open, true);
                            VendLedgEntry.SetRange(Prepayment, false);
                            if ACTION::LookupOK = PAGE.RunModal(0, VendLedgEntry) then
                                Validate("Source Entry No.", VendLedgEntry."Entry No.");
                        end;
                end;
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            if not CustLedgEntry.Get("Source Entry No.") then
                                Clear(CustLedgEntry);
                            CustLedgEntry.CalcFields(Amount, "Remaining Amount", "Amount (LCY)", "Remaining Amt. (LCY)", "Amount on Credit (LCY)");
                            if CustLedgEntry."Entry No." <> 0 then begin
                                CustLedgEntry.TestField(Open, true);
                                CustLedgEntry.TestField(Prepayment, false);
                                CustLedgEntry.TestField("Prepayment Type", CustLedgEntry."Prepayment Type"::" ");
                            end;
                            CustLedgEntry.TestField("Amount on Credit (LCY)", 0);
                            "Source No." := CustLedgEntry."Customer No.";
                            "Posting Group" := CustLedgEntry."Customer Posting Group";
                            Description := CustLedgEntry.Description;
                            "Currency Code" := CustLedgEntry."Currency Code";
                            "Ledg. Entry Original Amount" := CustLedgEntry.Amount;
                            "Ledg. Entry Remaining Amount" := CustLedgEntry."Remaining Amount";
                            "Ledg. Entry Original Amt.(LCY)" := CustLedgEntry."Amount (LCY)";
                            "Ledg. Entry Rem. Amt. (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
                            Amount := CustLedgEntry."Remaining Amount";
                            "Amount (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
                            "Posting Date" := CustLedgEntry."Posting Date";
                            "Document Type" := CustLedgEntry."Document Type";
                            "Document No." := CustLedgEntry."Document No.";
                            "Variable Symbol" := CustLedgEntry."Variable Symbol";
                        end;
                    "Source Type"::Vendor:
                        begin
                            if not VendLedgEntry.Get("Source Entry No.") then
                                Clear(VendLedgEntry);
                            VendLedgEntry.CalcFields(Amount, "Remaining Amount", "Amount (LCY)", "Remaining Amt. (LCY)", "Amount on Credit (LCY)");
                            if VendLedgEntry."Entry No." <> 0 then begin
                                VendLedgEntry.TestField(Open, true);
                                VendLedgEntry.TestField(Prepayment, false);
                                VendLedgEntry.TestField("Prepayment Type", VendLedgEntry."Prepayment Type"::" ");
                            end;
                            VendLedgEntry.TestField("Amount on Credit (LCY)", 0);
                            "Source No." := VendLedgEntry."Vendor No.";
                            "Posting Group" := VendLedgEntry."Vendor Posting Group";
                            Description := VendLedgEntry.Description;
                            "Currency Code" := VendLedgEntry."Currency Code";
                            "Ledg. Entry Original Amount" := VendLedgEntry.Amount;
                            "Ledg. Entry Remaining Amount" := VendLedgEntry."Remaining Amount";
                            "Ledg. Entry Original Amt.(LCY)" := VendLedgEntry."Amount (LCY)";
                            "Ledg. Entry Rem. Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
                            Amount := VendLedgEntry."Remaining Amount";
                            "Amount (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
                            "Posting Date" := VendLedgEntry."Posting Date";
                            "Document Type" := VendLedgEntry."Document Type";
                            "Document No." := VendLedgEntry."Document No.";
                            "Variable Symbol" := VendLedgEntry."Variable Symbol";
                        end;
                end;
                CheckPostingDate;
                if "Line No." <> 0 then begin
                    CopyLEDimensions;
                    GetCurrencyFactor;
                end;
            end;
        }
        field(30; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(35; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(40; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(45; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(50; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(75; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(77; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(80; "Ledg. Entry Original Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Original Amount';
            Editable = false;
        }
        field(85; "Ledg. Entry Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Remaining Amount';
        }
        field(87; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestField(Amount);
                if Abs(Amount) > Abs("Ledg. Entry Remaining Amount") then
                    Error(Text001Err, FieldCaption(Amount), FieldCaption("Ledg. Entry Remaining Amount"));
                if (Amount > 0) and ("Ledg. Entry Remaining Amount" < 0) or
                   (Amount < 0) and ("Ledg. Entry Remaining Amount" > 0)
                then
                    Error(Text002Err, FieldCaption(Amount), FieldCaption("Ledg. Entry Remaining Amount"));

                "Remaining Amount" := "Ledg. Entry Remaining Amount" - Amount;
                ConvertLCYAmounts;
            end;
        }
        field(88; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';

            trigger OnValidate()
            begin
                if (Abs("Remaining Amount") >= Abs("Ledg. Entry Remaining Amount")) and ("Remaining Amount" <> 0) then
                    Error(Text003Err, FieldCaption("Remaining Amount"), FieldCaption("Ledg. Entry Remaining Amount"));
                if ("Remaining Amount" > 0) and ("Ledg. Entry Remaining Amount" < 0) or
                   ("Remaining Amount" < 0) and ("Ledg. Entry Remaining Amount" > 0)
                then
                    Error(Text002Err, FieldCaption("Remaining Amount"), FieldCaption("Ledg. Entry Remaining Amount"));

                Amount := "Ledg. Entry Remaining Amount" - "Remaining Amount";
                ConvertLCYAmounts;
            end;
        }
        field(90; "Ledg. Entry Original Amt.(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Original Amt.(LCY)';
            Editable = false;
        }
        field(95; "Ledg. Entry Rem. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Ledg. Entry Rem. Amt. (LCY)';
        }
        field(97; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                TestField("Amount (LCY)");
                if Abs("Amount (LCY)") > Abs("Ledg. Entry Rem. Amt. (LCY)") then
                    Error(Text001Err, FieldCaption("Amount (LCY)"), FieldCaption("Ledg. Entry Rem. Amt. (LCY)"));
                if ("Amount (LCY)" > 0) and ("Ledg. Entry Rem. Amt. (LCY)" < 0) or
                   ("Amount (LCY)" < 0) and ("Ledg. Entry Rem. Amt. (LCY)" > 0)
                then
                    Error(Text002Err, FieldCaption("Amount (LCY)"), FieldCaption("Ledg. Entry Rem. Amt. (LCY)"));

                ConvertAmounts;
                Validate(Amount);
            end;
        }
        field(98; "Remaining Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Amount (LCY)';

            trigger OnValidate()
            begin
                if (Abs("Remaining Amount (LCY)") >= Abs("Ledg. Entry Rem. Amt. (LCY)")) and ("Remaining Amount (LCY)" <> 0) then
                    Error(Text003Err, FieldCaption("Remaining Amount (LCY)"), FieldCaption("Ledg. Entry Rem. Amt. (LCY)"));
                if ("Remaining Amount (LCY)" > 0) and ("Ledg. Entry Rem. Amt. (LCY)" < 0) or
                   ("Remaining Amount (LCY)" < 0) and ("Ledg. Entry Rem. Amt. (LCY)" > 0)
                then
                    Error(Text002Err, FieldCaption("Remaining Amount (LCY)"), FieldCaption("Ledg. Entry Rem. Amt. (LCY)"));

                ConvertAmounts;
                Validate("Remaining Amount");
            end;
        }
        field(100; "Manual Change Only"; Boolean)
        {
            Caption = 'Manual Change Only';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Credit No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Ledg. Entry Rem. Amt. (LCY)", "Amount (LCY)";
        }
        key(Key2; "Source Type", "Source No.")
        {
            SumIndexFields = "Ledg. Entry Rem. Amt. (LCY)", "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
        TestField("Source Entry No.");
        CopyLEDimensions;
        GetCurrencyFactor;
    end;

    trigger OnModify()
    begin
        TestStatusOpen;
    end;

    var
        CreditHeader: Record "Credit Header";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        DimMgt: Codeunit DimensionManagement;
        Text001Err: Label '%1 must be less or equal to %2.', Comment = '%1=fieldcaption1;%2=fieldcaption2';
        Text002Err: Label '%1 must have the same sign as %2.', Comment = '%1=fieldcaption1;%2=fieldcaption2';
        Text003Err: Label '%1 must be less than %2.', Comment = '%1=fieldcaption1;%2=fieldcaption2';
        Text008Err: Label '%1 %2.', Comment = '%1=creditnumber;%2=linenumber';
        StatusCheckSuspend: Boolean;
        MustBeLessOrEqualErr: Label 'must be less or equal to %1', Comment = '%1 = Posting Date';

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo(Text008Err, "Credit No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure CopyLEDimensions()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        "Dimension Set ID" := 0;
        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';

        if "Source Entry No." = 0 then
            exit;
        case "Source Type" of
            "Source Type"::Customer:
                begin
                    CustLedgEntry.Get("Source Entry No.");
                    "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                    "Global Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
                    "Global Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
                end;
            "Source Type"::Vendor:
                begin
                    VendLedgEntry.Get("Source Entry No.");
                    "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                    "Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
                    "Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
                end;
        end;
    end;

    local procedure TestStatusOpen()
    begin
        if StatusCheckSuspend then
            exit;
        GetCreditHeader;
        CreditHeader.TestField(Status, CreditHeader.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspend := Suspend;
    end;

    local procedure GetCurrency()
    begin
        if "Currency Code" = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision;
        end else
            if "Currency Code" <> Currency.Code then begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure GetCurrencyFactor()
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GetCreditHeader;
        CreditHeader.TestField("Posting Date");
        if "Currency Code" = '' then
            "Currency Factor" := 1
        else
            "Currency Factor" := CurrExchRate.ExchangeRate(CreditHeader."Posting Date", "Currency Code");
        ConvertLCYAmounts;
    end;

    [Scope('OnPrem')]
    procedure SetCreditHeader(NewCreditHeader: Record "Credit Header")
    begin
        CreditHeader := NewCreditHeader;
    end;

    local procedure GetCreditHeader()
    begin
        TestField("Credit No.");
        if "Credit No." <> CreditHeader."No." then
            CreditHeader.Get("Credit No.");
    end;

    [Scope('OnPrem')]
    procedure ConvertLCYAmounts()
    begin
        GetCreditHeader;
        GetCurrency;
        if "Currency Code" = '' then begin
            "Amount (LCY)" := Amount;
            "Remaining Amount (LCY)" := "Remaining Amount";
        end else begin
            "Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  CreditHeader."Posting Date", "Currency Code",
                  Amount, "Currency Factor"));
            "Remaining Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  CreditHeader."Posting Date", "Currency Code",
                  "Remaining Amount", "Currency Factor"));
        end;
        Amount := Round(Amount, Currency."Amount Rounding Precision");
        "Remaining Amount" := Round("Remaining Amount", Currency."Amount Rounding Precision");
    end;

    [Scope('OnPrem')]
    procedure ConvertAmounts()
    begin
        GetCreditHeader;
        GetCurrency;
        if "Currency Code" = '' then begin
            Amount := "Amount (LCY)";
            "Remaining Amount" := "Remaining Amount (LCY)";
        end else begin
            Amount := Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  CreditHeader."Posting Date", "Currency Code",
                  "Amount (LCY)", "Currency Factor"),
                Currency."Amount Rounding Precision");
            "Remaining Amount" := Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  CreditHeader."Posting Date", "Currency Code",
                  "Remaining Amount (LCY)", "Currency Factor"),
                Currency."Amount Rounding Precision");
        end;

        Clear(Currency);
        Currency.InitRoundingPrecision;
        "Amount (LCY)" := Round("Amount (LCY)", Currency."Amount Rounding Precision");
        "Remaining Amount (LCY)" := Round("Remaining Amount (LCY)", Currency."Amount Rounding Precision");
    end;

    [Scope('OnPrem')]
    procedure CheckPostingDate()
    begin
        TestField("Credit No.");
        CreditHeader.Get("Credit No.");
        if (CreditHeader."Posting Date" <> 0D) and ("Posting Date" <> 0D) then
            if CreditHeader."Posting Date" < "Posting Date" then
                FieldError("Posting Date", StrSubstNo(MustBeLessOrEqualErr, CreditHeader."Posting Date"));
    end;
}

