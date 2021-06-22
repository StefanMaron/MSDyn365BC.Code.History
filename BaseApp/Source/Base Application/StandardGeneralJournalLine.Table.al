table 751 "Standard General Journal Line"
{
    Caption = 'Standard General Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            NotBlank = true;
        }
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner"])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Account No.", '');
                Validate("IC Partner G/L Acc. No.", '');

                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then begin
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("Gen. Bus. Posting Group", '');
                    Validate("Gen. Prod. Posting Group", '');
                end else
                    if "Bal. Account Type" in [
                                               "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource;

                if xRec."Account Type" in
                   [xRec."Account Type"::Customer, xRec."Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                end;
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Account Type" = CONST("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if xRec."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"] then
                    "IC Partner Code" := '';

                if "Account No." = '' then begin
                    UpdateLineBalance;
                    UpdateSource;
                    CreateDim(
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                    if xRec."Account No." <> '' then begin
                        "Gen. Posting Type" := "Gen. Posting Type"::" ";
                        "Gen. Bus. Posting Group" := '';
                        "Gen. Prod. Posting Group" := '';
                        "VAT Bus. Posting Group" := '';
                        "VAT Prod. Posting Group" := '';
                        "Tax Area Code" := '';
                        "Tax Liable" := false;
                        "Tax Group Code" := '';
                    end;
                    exit;
                end;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        GetGLAccount;
                    "Account Type"::Customer:
                        GetCustomerAccount;
                    "Account Type"::Vendor:
                        GetVendorAccount;
                    "Account Type"::"Bank Account":
                        GetBankAccount;
                    "Account Type"::"Fixed Asset":
                        GetFAAccount;
                    "Account Type"::"IC Partner":
                        GetICPartnerAccount;
                end;

                Validate("Currency Code");
                Validate("VAT Prod. Posting Group");
                UpdateLineBalance;
                UpdateSource;
                CreateDim(
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, "Campaign No.");

                Validate("IC Partner G/L Acc. No.", GetDefaultICPartnerGLAccNo);
            end;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                Validate("Payment Terms Code");
                if "Account No." <> '' then
                    CheckAccount("Account Type", "Account No.");
                if "Bal. Account No." <> '' then
                    CheckAccount("Bal. Account Type", "Bal. Account No.");
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency;
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount" :=
                          Round(
                            Amount * "VAT %" / (100 + "VAT %"),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" := Amount;
                    "VAT Calculation Type"::"Sales Tax":
                        if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) and
                           "Use Tax"
                        then begin
                            "VAT Amount" := 0;
                            "VAT %" := 0;
                        end else begin
                            "VAT Amount" :=
                              Amount -
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable",
                                WorkDate, Amount, Quantity, "Currency Factor");
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / (Amount - "VAT Amount"), 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                "VAT Base Amount" := Amount - "VAT Amount";
                "VAT Difference" := 0;
            end;
        }
        field(11; "Bal. Account No."; Code[20])
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
            IF ("Bal. Account Type" = CONST("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if xRec."Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor,
                                                "Bal. Account Type"::"IC Partner"]
                then
                    "IC Partner Code" := '';

                if "Bal. Account No." = '' then begin
                    UpdateLineBalance;
                    UpdateSource;
                    CreateDim(
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                    if xRec."Bal. Account No." <> '' then begin
                        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
                        "Bal. Gen. Bus. Posting Group" := '';
                        "Bal. Gen. Prod. Posting Group" := '';
                        "Bal. VAT Bus. Posting Group" := '';
                        "Bal. VAT Prod. Posting Group" := '';
                        "Bal. Tax Area Code" := '';
                        "Bal. Tax Liable" := false;
                        "Bal. Tax Group Code" := '';
                    end;
                    exit;
                end;

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        GetGLBalAccount;
                    "Bal. Account Type"::Customer:
                        GetCustomerBalAccount;
                    "Bal. Account Type"::Vendor:
                        GetVendorBalAccount;
                    "Bal. Account Type"::"Bank Account":
                        GetBankBalAccount;
                    "Bal. Account Type"::"Fixed Asset":
                        GetFABalAccount;
                    "Bal. Account Type"::"IC Partner":
                        GetICPartnerBalAccount;
                end;

                Validate("Currency Code");
                Validate("Bal. VAT Prod. Posting Group");
                UpdateLineBalance;
                UpdateSource;
                CreateDim(
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, "Campaign No.");

                Validate("IC Partner G/L Acc. No.", GetDefaultICPartnerGLAccNo);
            end;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
            begin
                if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then begin
                    if BankAcc.Get("Bal. Account No.") and (BankAcc."Currency Code" <> '') then
                        BankAcc.TestField("Currency Code", "Currency Code");
                end;
                if "Account Type" = "Account Type"::"Bank Account" then begin
                    if BankAcc.Get("Account No.") and (BankAcc."Currency Code" <> '') then
                        BankAcc.TestField("Currency Code", "Currency Code");
                end;

                if "Currency Code" <> '' then begin
                    GetCurrency;
                    if ("Currency Code" <> xRec."Currency Code") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" :=
                          CurrExchRate.ExchangeRate(WorkDate, "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          WorkDate, "Currency Code",
                          Amount, "Currency Factor"));

                Amount := Round(Amount, Currency."Amount Rounding Precision");

                Validate("VAT %");
                Validate("Bal. VAT %");
                UpdateLineBalance;
            end;
        }
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Debit Amount" := Round("Debit Amount", Currency."Amount Rounding Precision");
                Correction := "Debit Amount" < 0;
                Amount := "Debit Amount";
                Validate(Amount);
            end;
        }
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Credit Amount" := Round("Credit Amount", Currency."Amount Rounding Precision");
                Correction := "Credit Amount" < 0;
                Amount := -"Credit Amount";
                Validate(Amount);
            end;
        }
        field(16; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end
            end;
        }
        field(17; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Balance (LCY)';
            Editable = false;
        }
        field(18; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
                Validate(Amount);
            end;
        }
        field(19; "Sales/Purch. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales/Purch. (LCY)';
        }
        field(20; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Profit (LCY)';
        }
        field(21; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Discount (LCY)';
        }
        field(22; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor;

            trigger OnValidate()
            begin
                if "Bill-to/Pay-to No." <> xRec."Bill-to/Pay-to No." then
                    "Ship-to/Order Address Code" := '';
            end;
        }
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Posting Group"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(29; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(40; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Job, "Job No.",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(43; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(44; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                if not ("VAT Calculation Type" in
                        ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])
                then
                    Error(
                      Text010, FieldCaption("VAT Calculation Type"),
                      "VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT");
                if "VAT Amount" <> 0 then begin
                    TestField("VAT %");
                    TestField(Amount);
                end;

                GetCurrency;
                "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);

                if "VAT Amount" * Amount < 0 then
                    if "VAT Amount" > 0 then
                        Error(Text011, FieldCaption("VAT Amount"))
                    else
                        Error(Text012, FieldCaption("VAT Amount"));

                "VAT Base Amount" := Amount - "VAT Amount";

                "VAT Difference" :=
                  "VAT Amount" -
                  Round(
                    Amount * "VAT %" / (100 + "VAT %"),
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
                    Error(Text013, FieldCaption("VAT Difference"), Currency."Max. VAT Difference Allowed");
            end;
        }
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "Payment Terms";
            begin
                "Payment Discount %" := 0;
                if ("Account Type" <> "Account Type"::"G/L Account") or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                then
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if "Payment Terms Code" <> '' then begin
                                PaymentTerms.Get("Payment Terms Code");
                                "Payment Discount %" := PaymentTerms."Discount %";
                            end;
                        "Document Type"::"Credit Memo":
                            if "Payment Terms Code" <> '' then begin
                                PaymentTerms.Get("Payment Terms Code");
                                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                                    "Payment Discount %" := PaymentTerms."Discount %";
                            end;
                    end;
            end;
        }
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(51; "Standard Journal Code"; Code[10])
        {
            Caption = 'Standard Journal Code';
            TableRelation = "Standard General Journal".Code;
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(57; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Posting Type", "Gen. Posting Type"::" ");
                if ("Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Gen. Posting Type");
                if "Gen. Posting Type" > 0 then
                    Validate("VAT Prod. Posting Group");
            end;
        }
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Bus. Posting Group", '');
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(59; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("Gen. Prod. Posting Group", '');
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(60; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(63; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset",
                                       "Account Type"::"IC Partner"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner"])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Bal. Account No.", '');
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then begin
                    Validate("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                    Validate("Bal. Gen. Bus. Posting Group", '');
                    Validate("Bal. Gen. Prod. Posting Group", '');
                end else
                    if "Account Type" in [
                                          "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource;

                if xRec."Bal. Account Type" in
                   [xRec."Bal. Account Type"::Customer, xRec."Bal. Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                end;
                if ("Account Type" in [
                                       "Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]) and
                   ("Bal. Account Type" in [
                                            "Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"])
                then
                    Validate("Payment Terms Code", '');
            end;
        }
        field(64; "Bal. Gen. Posting Type"; Option)
        {
            Caption = 'Bal. Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                if ("Bal. Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Bal. Gen. Posting Type");
                if "Bal. Gen. Posting Type" > 0 then
                    Validate("Bal. VAT Prod. Posting Group");
            end;
        }
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Bus. Posting Group", '');
                if xRec."Bal. Gen. Bus. Posting Group" <> "Bal. Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Bal. Gen. Bus. Posting Group") then
                        Validate("Bal. VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(66; "Bal. Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"] then
                    TestField("Bal. Gen. Prod. Posting Group", '');
                if xRec."Bal. Gen. Prod. Posting Group" <> "Bal. Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Bal. Gen. Prod. Posting Group") then
                        Validate("Bal. VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(67; "Bal. VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Bal. VAT Calculation Type';
            Editable = false;
        }
        field(68; "Bal. VAT %"; Decimal)
        {
            Caption = 'Bal. VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetCurrency;
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                        "Bal. VAT Amount" :=
                          Round(
                            -Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "Bal. VAT Calculation Type"::"Full VAT":
                        "Bal. VAT Amount" := -Amount;
                    "Bal. VAT Calculation Type"::"Sales Tax":
                        if ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) and
                           "Bal. Use Tax"
                        then begin
                            "Bal. VAT Amount" := 0;
                            "Bal. VAT %" := 0;
                        end else begin
                            "Bal. VAT Amount" :=
                              -(Amount -
                                SalesTaxCalculate.ReverseCalculateTax(
                                  "Bal. Tax Area Code", "Bal. Tax Group Code", "Bal. Tax Liable",
                                  WorkDate, Amount, Quantity, "Currency Factor"));
                            if Amount + "Bal. VAT Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * -"Bal. VAT Amount" / (Amount + "Bal. VAT Amount"), 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");
                "Bal. VAT Difference" := 0;
            end;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';

            trigger OnValidate()
            begin
                if not ("Bal. VAT Calculation Type" in
                        ["Bal. VAT Calculation Type"::"Normal VAT", "Bal. VAT Calculation Type"::"Reverse Charge VAT"])
                then
                    Error(
                      Text010, FieldCaption("Bal. VAT Calculation Type"),
                      "Bal. VAT Calculation Type"::"Normal VAT", "Bal. VAT Calculation Type"::"Reverse Charge VAT");
                if "Bal. VAT Amount" <> 0 then begin
                    TestField("Bal. VAT %");
                    TestField(Amount);
                end;

                GetCurrency;
                "Bal. VAT Amount" :=
                  Round("Bal. VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);

                if "Bal. VAT Amount" * Amount > 0 then
                    if "Bal. VAT Amount" > 0 then
                        Error(Text011, FieldCaption("Bal. VAT Amount"))
                    else
                        Error(Text012, FieldCaption("Bal. VAT Amount"));

                "Bal. VAT Base Amount" := -(Amount + "Bal. VAT Amount");

                "Bal. VAT Difference" :=
                  "Bal. VAT Amount" -
                  Round(
                    -Amount * "Bal. VAT %" / (100 + "Bal. VAT %"),
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                if Abs("Bal. VAT Difference") > Currency."Max. VAT Difference Allowed" then
                    Error(
                      Text013, FieldCaption("Bal. VAT Difference"), Currency."Max. VAT Difference Allowed");
            end;
        }
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';

            trigger OnValidate()
            begin
                if ("Bank Payment Type" <> "Bank Payment Type"::" ") and
                   ("Account Type" <> "Account Type"::"Bank Account") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
                then
                    Error(
                      Text007,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
                if ("Account Type" = "Account Type"::"Fixed Asset") and
                   ("Bank Payment Type" <> "Bank Payment Type"::" ")
                then
                    FieldError("Account Type");
            end;
        }
        field(71; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "VAT Base Amount" := Round("VAT Base Amount", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        Amount :=
                          Round(
                            "VAT Base Amount" * (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Calculation Type"::"Full VAT":
                        if "VAT Base Amount" <> 0 then
                            FieldError(
                              "VAT Base Amount",
                              StrSubstNo(
                                Text008, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        if ("Gen. Posting Type" = "Gen. Posting Type"::Purchase) and
                           "Use Tax"
                        then begin
                            "VAT Amount" := 0;
                            "VAT %" := 0;
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end else begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", WorkDate,
                                "VAT Base Amount", Quantity, "Currency Factor");
                            if "VAT Base Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end;
                end;
                Validate(Amount);
            end;
        }
        field(72; "Bal. VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency;
                "Bal. VAT Base Amount" := Round("Bal. VAT Base Amount", Currency."Amount Rounding Precision");
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT":
                        Amount :=
                          Round(
                            -"Bal. VAT Base Amount" * (1 + "Bal. VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "Bal. VAT Calculation Type"::"Full VAT":
                        if "Bal. VAT Base Amount" <> 0 then
                            FieldError(
                              "Bal. VAT Base Amount",
                              StrSubstNo(
                                Text008, FieldCaption("Bal. VAT Calculation Type"),
                                "Bal. VAT Calculation Type"));
                    "Bal. VAT Calculation Type"::"Sales Tax":
                        if ("Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::Purchase) and
                           "Bal. Use Tax"
                        then begin
                            "Bal. VAT Amount" := 0;
                            "Bal. VAT %" := 0;
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end else begin
                            "Bal. VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                "Bal. Tax Area Code", "Bal. Tax Group Code", "Bal. Tax Liable",
                                WorkDate, "Bal. VAT Base Amount", Quantity, "Currency Factor");
                            if "Bal. VAT Base Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * "Bal. VAT Amount" / "Bal. VAT Base Amount", 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end;
                end;
                Validate(Amount);
            end;
        }
        field(73; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(78; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';
            OptionMembers = " ",Customer,Vendor,"Bank Account","Fixed Asset";

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource
                else
                    "Source No." := '';
            end;
        }
        field(79; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource;
            end;
        }
        field(80; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(82; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(83; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(84; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(85; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
        }
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';

            trigger OnValidate()
            begin
                TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::Purchase);
                Validate("Bal. VAT %");
            end;
        }
        field(90; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Bus. Posting Group", '');

                Validate("VAT Prod. Posting Group");
            end;
        }
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Prod. Posting Group", '');

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                if "Gen. Posting Type" <> 0 then begin
                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        VATPostingSetup.Init();
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Normal VAT":
                            "VAT %" := VATPostingSetup."VAT %";
                        "VAT Calculation Type"::"Full VAT":
                            case "Gen. Posting Type" of
                                "Gen. Posting Type"::Sale:
                                    TestField("Account No.", VATPostingSetup.GetSalesAccount(false));
                                "Gen. Posting Type"::Purchase:
                                    TestField("Account No.", VATPostingSetup.GetPurchAccount(false));
                            end;
                    end;
                end;
                Validate("VAT %");
            end;
        }
        field(92; "Bal. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then
                    TestField("Bal. VAT Bus. Posting Group", '');

                Validate("Bal. VAT Prod. Posting Group");
            end;
        }
        field(93; "Bal. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Bal. VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then
                    TestField("Bal. VAT Prod. Posting Group", '');

                "Bal. VAT %" := 0;
                "Bal. VAT Calculation Type" := "Bal. VAT Calculation Type"::"Normal VAT";
                if "Bal. Gen. Posting Type" <> 0 then begin
                    if not VATPostingSetup.Get("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group") then
                        VATPostingSetup.Init();
                    "Bal. VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    case "Bal. VAT Calculation Type" of
                        "Bal. VAT Calculation Type"::"Normal VAT":
                            "Bal. VAT %" := VATPostingSetup."VAT %";
                        "Bal. VAT Calculation Type"::"Full VAT":
                            case "Bal. Gen. Posting Type" of
                                "Bal. Gen. Posting Type"::Sale:
                                    TestField("Bal. Account No.", VATPostingSetup.GetSalesAccount(false));
                                "Bal. Gen. Posting Type"::Purchase:
                                    TestField("Bal. Account No.", VATPostingSetup.GetPurchAccount(false));
                            end;
                    end;
                end;
                Validate("Bal. VAT %");
            end;
        }
        field(110; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Ship-to Address".Code WHERE("Customer No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Order Address".Code WHERE("Vendor No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) "Ship-to Address".Code WHERE("Customer No." = FIELD("Bill-to/Pay-to No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Order Address".Code WHERE("Vendor No." = FIELD("Bill-to/Pay-to No."));
        }
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Difference';
            Editable = false;
        }
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";

            trigger OnValidate()
            var
                ICGLAccount: Record "IC G/L Account";
                GenJnlTemplate: Record "Gen. Journal Template";
            begin
                if "IC Partner G/L Acc. No." <> '' then begin
                    GenJnlTemplate.Get("Journal Template Name");
                    GenJnlTemplate.TestField(Type, GenJnlTemplate.Type::Intercompany);
                    if ICGLAccount.Get("IC Partner G/L Acc. No.") then
                        ICGLAccount.TestField(Blocked, false);
                end
            end;
        }
        field(118; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor;
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
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Campaign, "Campaign No.",
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");
            end;
        }
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Standard Journal Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Text000: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'cannot be specified without %1';
        Text006: Label 'The %1 option can only be used internally in the system.';
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        DimMgt: Codeunit DimensionManagement;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        CurrencyCode: Code[10];
        Text007: Label '%1 or %2 must be a Bank Account.';
        Text008: Label ' must be 0 when %1 is %2.';
        Text010: Label '%1 must be %2 or %3.';
        Text011: Label '%1 must be negative.';
        Text012: Label '%1 must be positive.';
        Text013: Label 'The %1 must not be more than %2.';
        Text014: Label 'The %1 %2 has a %3 %4.\Do you still want to use %1 %2 in this journal line?';

    local procedure UpdateLineBalance()
    begin
        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then begin
            "Debit Amount" := Amount;
            "Credit Amount" := 0
        end else begin
            "Debit Amount" := 0;
            "Credit Amount" := -Amount;
        end;
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Standard Journal Code", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure CheckGLAcc(GLAcc: Record "G/L Account")
    begin
        GLAcc.CheckGLAcc;
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') then
            exit;
        GLAcc.TestField("Direct Posting", true);
    end;

    local procedure CheckAccount(AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"; AccountNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        ICPartner: Record "IC Partner";
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
    begin
        case AccountType of
            AccountType::"G/L Account":
                begin
                    GLAcc.Get(AccountNo);
                    CheckGLAcc(GLAcc);
                end;
            AccountType::Customer:
                begin
                    Cust.Get(AccountNo);
                    Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                end;
            AccountType::Vendor:
                begin
                    Vend.Get(AccountNo);
                    Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                end;
            AccountType::"Bank Account":
                begin
                    BankAcc.Get(AccountNo);
                    BankAcc.TestField(Blocked, false);
                end;
            AccountType::"Fixed Asset":
                begin
                    FA.Get(AccountNo);
                    FA.TestField(Blocked, false);
                    FA.TestField(Inactive, false);
                    FA.TestField("Budgeted Asset", false);
                end;
            AccountType::"IC Partner":
                begin
                    ICPartner.Get(AccountNo);
                    ICPartner.CheckICPartner;
                end;
        end;
    end;

    local procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if ICPartnerCode <> '' then
            if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
                ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                "IC Partner Code" := ICPartnerCode;
            end;
    end;

    local procedure SetCurrencyCode(AccType2: Option "G/L Account",Customer,Vendor,"Bank Account"; AccNo2: Code[20]): Boolean
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
    begin
        "Currency Code" := '';
        if AccNo2 <> '' then
            case AccType2 of
                AccType2::Customer:
                    if Cust.Get(AccNo2) then
                        "Currency Code" := Cust."Currency Code";
                AccType2::Vendor:
                    if Vend.Get(AccNo2) then
                        "Currency Code" := Vend."Currency Code";
                AccType2::"Bank Account":
                    if BankAcc.Get(AccNo2) then
                        "Currency Code" := BankAcc."Currency Code";
            end;
        exit("Currency Code" <> '');
    end;

    local procedure GetCurrency()
    begin
        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    local procedure UpdateSource()
    var
        SourceExists1: Boolean;
        SourceExists2: Boolean;
    begin
        SourceExists1 := ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '');
        SourceExists2 := ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '');
        case true of
            SourceExists1 and not SourceExists2:
                begin
                    "Source Type" := "Account Type";
                    "Source No." := "Account No.";
                end;
            SourceExists2 and not SourceExists1:
                begin
                    "Source Type" := "Bal. Account Type";
                    "Source No." := "Bal. Account No.";
                end;
            else begin
                    "Source Type" := "Source Type"::" ";
                    "Source No." := '';
                end;
        end;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    local procedure GetDefaultICPartnerGLAccNo(): Code[20]
    var
        GLAcc: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        if "IC Partner Code" <> '' then begin
            if "Account Type" = "Account Type"::"G/L Account" then
                GLAccNo := "Account No."
            else
                GLAccNo := "Bal. Account No.";
            if GLAcc.Get(GLAccNo) then
                exit(GLAcc."Default IC Partner G/L Acc. No")
        end;
    end;

    local procedure GetGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Account No.");
        CheckGLAcc(GLAcc);
        if "Bal. Account No." = '' then
            Description := GLAcc.Name;

        if ("Bal. Account No." = '') or
           ("Bal. Account Type" in
            ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if "Bal. Account No." = '' then
            "Currency Code" := '';
        "Gen. Posting Type" := GLAcc."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Area Code" := GLAcc."Tax Area Code";
        "Tax Liable" := GLAcc."Tax Liable";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if WorkDate = ClosingDate(WorkDate) then begin
            "Gen. Posting Type" := 0;
            "Gen. Bus. Posting Group" := '';
            "Gen. Prod. Posting Group" := '';
            "VAT Bus. Posting Group" := '';
            "VAT Prod. Posting Group" := '';
        end;
    end;

    local procedure GetGLBalAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Bal. Account No.");
        CheckGLAcc(GLAcc);
        if "Account No." = '' then begin
            Description := GLAcc.Name;
            "Currency Code" := '';
        end;
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
        "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
        "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
        "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Bal. Tax Area Code" := GLAcc."Tax Area Code";
        "Bal. Tax Liable" := GLAcc."Tax Liable";
        "Bal. Tax Group Code" := GLAcc."Tax Group Code";
        if WorkDate = ClosingDate(WorkDate) then begin
            "Bal. Gen. Bus. Posting Group" := '';
            "Bal. Gen. Prod. Posting Group" := '';
            "Bal. VAT Bus. Posting Group" := '';
            "Bal. VAT Prod. Posting Group" := '';
            "Bal. Gen. Posting Type" := 0;
        end;
    end;

    local procedure GetCustomerAccount()
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Cust.Get("Account No.");
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Account Type", "Account No.");
        Description := Cust.Name;
        "Posting Group" := Cust."Customer Posting Group";
        "Salespers./Purch. Code" := Cust."Salesperson Code";
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            Cust.TestField("Currency Code", "Currency Code")
        else
            "Currency Code" := Cust."Currency Code";
        "Gen. Posting Type" := 0;
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Account No.") then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        end;
        Validate("Payment Terms Code");
    end;

    local procedure GetCustomerBalAccount()
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Cust.Get("Bal. Account No.");
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        if "Account No." = '' then
            Description := Cust.Name;
        "Posting Group" := Cust."Customer Posting Group";
        "Salespers./Purch. Code" := Cust."Salesperson Code";
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Cust."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Cust."Currency Code";
        "Bal. Gen. Posting Type" := 0;
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Bal. Account No.") then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        end;
        Validate("Payment Terms Code");
    end;

    local procedure GetVendorAccount()
    var
        Vend: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Vend.Get("Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Account Type", "Account No.");
        Description := Vend.Name;
        "Posting Group" := Vend."Vendor Posting Group";
        "Salespers./Purch. Code" := Vend."Purchaser Code";
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            Vend.TestField("Currency Code", "Currency Code")
        else
            "Currency Code" := Vend."Currency Code";
        "Gen. Posting Type" := 0;
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Account No.") then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        end;
        Validate("Payment Terms Code");
    end;

    local procedure GetVendorBalAccount()
    var
        Vend: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Vend.Get("Bal. Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        if "Account No." = '' then
            Description := Vend.Name;
        "Posting Group" := Vend."Vendor Posting Group";
        "Salespers./Purch. Code" := Vend."Purchaser Code";
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Vend."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Vend."Currency Code";
        "Bal. Gen. Posting Type" := 0;
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Bal. Account No.") then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        end;
        Validate("Payment Terms Code");
    end;

    local procedure GetBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        BankAcc.TestField(Blocked, false);
        if "Bal. Account No." = '' then
            Description := BankAcc.Name;
        if ("Bal. Account No." = '') or
           ("Bal. Account Type" in
            ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if BankAcc."Currency Code" = '' then begin
            if "Bal. Account No." = '' then
                "Currency Code" := '';
        end else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        "Gen. Posting Type" := 0;
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
    end;

    local procedure GetBankBalAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bal. Account No.");
        BankAcc.TestField(Blocked, false);
        if "Account No." = '' then
            Description := BankAcc.Name;
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if BankAcc."Currency Code" = '' then begin
            if "Account No." = '' then
                "Currency Code" := '';
        end else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        "Bal. Gen. Posting Type" := 0;
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
    end;

    local procedure GetFAAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        Description := FA.Description;
    end;

    local procedure GetFABalAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Bal. Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        if "Account No." = '' then
            Description := FA.Description;
    end;

    local procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner;
        Description := ICPartner.Name;
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        "Gen. Posting Type" := 0;
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        "IC Partner Code" := "Account No.";
    end;

    local procedure GetICPartnerBalAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Bal. Account No.");
        if "Account No." = '' then
            Description := ICPartner.Name;

        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        "Bal. Gen. Posting Type" := 0;
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';
        "IC Partner Code" := "Bal. Account No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var StandardGenJournalLine: Record "Standard General Journal Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var StandardGenJournalLine: Record "Standard General Journal Line"; var xStandardGenJournalLine: Record "Standard General Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var StandardGenJournalLine: Record "Standard General Journal Line"; var xStandardGenJournalLine: Record "Standard General Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

