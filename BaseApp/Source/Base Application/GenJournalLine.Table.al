table 81 "Gen. Journal Line"
{
    Caption = 'Gen. Journal Line';
    Permissions = TableData "Sales Invoice Header" = r,
                  TableData "Data Exch. Field" = rimd;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
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
                Validate(Description, '');
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

                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if xRec."Account Type" in
                   [xRec."Account Type"::Customer, xRec."Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                    "VAT Registration No." := '';
                end;

                if "Journal Template Name" <> '' then
                    if "Account Type" = "Account Type"::"IC Partner" then begin
                        GetTemplate;
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            FieldError("Account Type");
                    end;

                Validate("Deferral Code", '');
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                          Blocked = CONST(false))
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
                if "Account No." <> xRec."Account No." then begin
                    ClearAppliedAutomatically;
                    BlankJobNo(FieldNo("Account No."));
                end;

                if xRec."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"] then
                    "IC Partner Code" := '';

                if "Account No." = '' then begin
                    CleanLine;
                    exit;
                end;

                OnValidateAccountNoOnBeforeAssignValue(Rec, xRec);

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

                OnValidateAccountNoOnAfterAssignValue(Rec, xRec);

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
                ValidateApplyRequirements(Rec);

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        UpdateAccountID;
                    "Account Type"::Customer:
                        UpdateCustomerID;
                    "Account Type"::"Bank Account":
                        UpdateBankAccountID;
                end;
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                if "Unrealized VAT Entry No." <> 0 then begin
                    if "Posting Date" < "Document Date" then
                        FieldError("Posting Date");
                    exit;
                end;

                if "Reinstatement VAT Entry No." <> 0 then
                    VATReinstMgt.CheckPostingDate(Rec);

                if not "Check Printed" then begin
                    TestField("Posting Date");
                    Validate("Document Date", "Posting Date");
                    ValidateCurrencyCode();
                end;

                if ("Posting Date" <> xRec."Posting Date") and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);

                ValidateApplyRequirements(Rec);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;

                if xRec."Posting Date" <> "Posting Date" then
                    AddPersonalDocInfo("Cash Order Including");

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if not "Check Printed" then
                    Validate("Payment Terms Code");
                if "Account No." <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                Cust.Get("Account No.");
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.Get("Account No.");
                                Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                            end;
                    end;
                if "Bal. Account No." <> '' then
                    case "Bal. Account Type" of
                        "Account Type"::Customer:
                            begin
                                Cust.Get("Bal. Account No.");
                                Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vend.Get("Bal. Account No.");
                                Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
                            end;
                    end;
                UpdateSalesPurchLCY;
                ValidateApplyRequirements(Rec);
            end;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                SetExportStatus;
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
                        begin
                            "VAT Amount" :=
                              Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                            "VAT Base Amount" :=
                              Round(Amount - "VAT Amount", Currency."Amount Rounding Precision");
                        end;
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
                                "Posting Date", Amount, Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateReverseCalculateTax(Rec, CurrFieldNo);
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

                if "Currency Code" = '' then
                    "VAT Amount (LCY)" := "VAT Amount"
                else
                    "VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "VAT Amount", "Currency Factor"));
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY;

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(11; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                               Blocked = CONST(false))
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
                BlankJobNo(FieldNo("Bal. Account No."));

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
                    if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
                        "Recipient Bank Account" := '';
                    if xRec."Bal. Account No." <> '' then begin
                        ClearBalancePostingGroups;
                        "Bal. Tax Area Code" := '';
                        "Bal. Tax Liable" := false;
                        "Bal. Tax Group Code" := '';
                        ClearCurrencyCode;
                    end;
                    exit;
                end;

                OnValidateBalAccountNoOnBeforeAssignValue(Rec, xRec);

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

                OnValidateBalAccountNoOnAfterAssignValue(Rec, xRec);

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
                ValidateApplyRequirements(Rec);
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
                if ("Recurring Method" in
                    ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]) and
                   ("Currency Code" <> '')
                then
                    Error(
                      Text001,
                      FieldCaption("Currency Code"), FieldCaption("Recurring Method"), "Recurring Method");

                if "Currency Code" <> '' then begin
                    GetCurrency;
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" :=
                          CurrExchRate.ExchangeRate("Posting Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");

                if not CustVendAccountNosModified then
                    if ("Currency Code" <> xRec."Currency Code") and (Amount <> 0) then
                        PaymentToleranceMgt.PmtTolGenJnl(Rec);
            end;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                ReadGLSetup;
                if GLSetup."Enable Russian Accounting" and ("Unrealized VAT Entry No." <> 0) then begin
                    if Amount <> 0 then begin
                        if Abs(Amount) > Abs("Paid Amount") then
                            FieldError(Amount, StrSubstNo(Text14925, "Paid Amount"));
                        if Amount * "Paid Amount" > 0 then
                            if Amount > 0 then
                                Error(Text011, FieldCaption(Amount))
                            else
                                Error(Text012, FieldCaption(Amount));
                    end;
                    ManualAmount := Amount <> xRec.Amount;
                end;

                if "Reinstatement VAT Entry No." <> 0 then
                    if Amount <> 0 then
                        VATReinstMgt.CheckAmount(Rec);

                ValidateAmount(true);

                SetExportStatus;
                UpdatePaymentVATInfo(true);
                if xRec.Amount <> Amount then
                    AddPersonalDocInfo("Cash Order Including");
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
                if ("Credit Amount" = 0) or ("Debit Amount" <> 0) then begin
                    Amount := "Debit Amount";
                    Validate(Amount);
                end;

                SetExportStatus;
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
                if ("Debit Amount" = 0) or ("Credit Amount" <> 0) then begin
                    Amount := -"Credit Amount";
                    Validate(Amount);
                end;
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
                end else begin
                    if CheckFixedCurrency then begin
                        GetCurrency;
                        Amount := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              "Amount (LCY)", "Currency Factor"),
                            Currency."Amount Rounding Precision")
                    end else begin
                        TestField("Amount (LCY)");
                        TestField(Amount);
                        "Currency Factor" := Amount / "Amount (LCY)";
                    end;

                    Validate("VAT %");
                    Validate("Bal. VAT %");
                    UpdateLineBalance;
                end;
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
            Editable = false;
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
                ReadGLSetup;
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then
                    UpdateCountryCodeAndVATRegNo("Bill-to/Pay-to No.");
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
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

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
                ValidateSalesPersonPurchaserCode(Rec);

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
        field(30; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(34; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(35; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';

            trigger OnValidate()
            begin
                if "Applies-to Doc. Type" <> xRec."Applies-to Doc. Type" then
                    Validate("Applies-to Doc. No.", '');
                if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then
                    TestField(Prepayment, false);
            end;
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
                AccNo: Code[20];
            begin
                xRec.Amount := Amount;
                xRec."Currency Code" := "Currency Code";
                xRec."Posting Date" := "Posting Date";

                GetAccTypeAndNo(Rec, AccType, AccNo);
                Clear(CustLedgEntry);
                Clear(VendLedgEntry);

                case AccType of
                    AccType::Customer:
                        LookUpAppliesToDocCust(AccNo);
                    AccType::Vendor:
                        LookUpAppliesToDocVend(AccNo);
                end;
                SetJournalLineFieldsFromApplication;

                if xRec.Amount <> 0 then
                    if not PaymentToleranceMgt.PmtTolGenJnl(Rec) then
                        exit;

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID;
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
                TempGenJnlLine: Record "Gen. Journal Line" temporary;
            begin
                if SuppressCommit then
                    PaymentToleranceMgt.SetSuppressCommit(true);

                if "Applies-to Doc. No." <> '' then
                    TestField(Prepayment, false);

                if "Applies-to Doc. No." <> xRec."Applies-to Doc. No." then
                    ClearCustVendApplnEntry;

                if ("Applies-to Doc. No." = '') and (xRec."Applies-to Doc. No." <> '') then begin
                    PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");

                    TempGenJnlLine := Rec;
                    if (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) or
                       (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor)
                    then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

                    case TempGenJnlLine."Account Type" of
                        TempGenJnlLine."Account Type"::Customer:
                            begin
                                CustLedgEntry.SetCurrentKey("Document No.");
                                CustLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    CustLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                                CustLedgEntry.SetRange(Open, true);
                                if CustLedgEntry.FindFirst then begin
                                    if CustLedgEntry."Amount to Apply" <> 0 then begin
                                        CustLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                                    end;
                                    "Exported to Payment File" := CustLedgEntry."Exported to Payment File";
                                    "Applies-to Ext. Doc. No." := '';
                                end;
                            end;
                        TempGenJnlLine."Account Type"::Vendor:
                            begin
                                VendLedgEntry.SetCurrentKey("Document No.");
                                VendLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    VendLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                                VendLedgEntry.SetRange(Open, true);
                                if VendLedgEntry.FindFirst then begin
                                    if VendLedgEntry."Amount to Apply" <> 0 then begin
                                        VendLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                                    end;
                                    "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                                end;
                                "Applies-to Ext. Doc. No." := '';
                            end;
                    end;
                end;

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (Amount <> 0) then begin
                    if xRec."Applies-to Doc. No." <> '' then
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");
                    SetApplyToAmount;
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);
                    xRec.ClearAppliedGenJnlLine;
                end;

                case "Account Type" of
                    "Account Type"::Customer:
                        GetCustLedgerEntry;
                    "Account Type"::Vendor:
                        GetVendLedgerEntry;
                end;

                ValidateApplyRequirements(Rec);
                SetJournalLineFieldsFromApplication;

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID;
            end;
        }
        field(38; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
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
            TableRelation = Job;

            trigger OnValidate()
            begin
                if "Job No." = xRec."Job No." then
                    exit;

                SourceCodeSetup.Get();
                if "Source Code" <> SourceCodeSetup."Job G/L WIP" then
                    Validate("Job Task No.", '');
                if "Job No." = '' then begin
                    CreateDim(
                      DATABASE::Job, "Job No.",
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                    exit;
                end;

                TestField("Account Type", "Account Type"::"G/L Account");

                if "Bal. Account No." <> '' then
                    if not ("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"]) then
                        Error(Text016, FieldCaption("Bal. Account Type"));

                Job.Get("Job No.");
                Job.TestBlocked;
                "Job Currency Code" := Job."Currency Code";

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
                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("Allow VAT Difference", true);
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

                if "Currency Code" = '' then
                    "VAT Amount (LCY)" := "VAT Amount"
                else
                    "VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "VAT Amount", "Currency Factor"));
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";

                UpdateSalesPurchLCY;

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(45; "VAT Posting"; Option)
        {
            Caption = 'VAT Posting';
            Editable = false;
            OptionCaption = 'Automatic VAT Entry,Manual VAT Entry';
            OptionMembers = "Automatic VAT Entry","Manual VAT Entry";
        }
        field(47; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                "Due Date" := 0D;
                "Pmt. Discount Date" := 0D;
                "Payment Discount %" := 0;
                if ("Account Type" <> "Account Type"::"G/L Account") or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                then
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                                PaymentTerms.Get("Payment Terms Code");
                                IsHandled := false;
                                OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(Rec, PaymentTerms, IsHandled);
                                if not IsHandled then
                                    "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                                IsHandled := false;
                                OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(Rec, PaymentTerms, IsHandled);
                                if not IsHandled then
                                    "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                                "Payment Discount %" := PaymentTerms."Discount %";
                            end else
                                "Due Date" := "Document Date";
                        "Document Type"::"Credit Memo":
                            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                                PaymentTerms.Get("Payment Terms Code");
                                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                                    IsHandled := false;
                                    OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(Rec, PaymentTerms, IsHandled);
                                    if not IsHandled then
                                        "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                                    IsHandled := false;
                                    OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(Rec, PaymentTerms, IsHandled);
                                    if not IsHandled then
                                        "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                                    "Payment Discount %" := PaymentTerms."Discount %";
                                end else
                                    "Due Date" := "Document Date";
                            end else
                                "Due Date" := "Document Date";
                        else
                            "Due Date" := "Document Date";
                    end;
            end;
        }
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then
                    ClearCustVendApplnEntry;
                SetJournalLineFieldsFromApplication;
            end;
        }
        field(50; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(51; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));

            trigger OnValidate()
            begin
                UpdateJournalBatchID;
            end;
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ' ,F  Fixed,V  Variable,B  Balance,RF Reversing Fixed,RV Reversing Variable,RB Reversing Balance';
            OptionMembers = " ","F  Fixed","V  Variable","B  Balance","RF Reversing Fixed","RV Reversing Variable","RB Reversing Balance";

            trigger OnValidate()
            begin
                if "Recurring Method" in
                   ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]
                then
                    TestField("Currency Code", '');
                UpdateSalesPurchLCY;
            end;
        }
        field(54; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(55; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(56; "Allocated Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Gen. Jnl. Allocation".Amount WHERE("Journal Template Name" = FIELD("Journal Template Name"),
                                                                   "Journal Batch Name" = FIELD("Journal Batch Name"),
                                                                   "Journal Line No." = FIELD("Line No.")));
            Caption = 'Allocated Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenPostingType(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Gen. Posting Type", "Gen. Posting Type"::" ");
                if ("Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Gen. Posting Type");
                CheckVATInAlloc;
                if "Gen. Posting Type" > 0 then
                    Validate("VAT Prod. Posting Group");
                if "Gen. Posting Type" <> "Gen. Posting Type"::Purchase then
                    Validate("Use Tax", false)
            end;
        }
        field(58; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenBusPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
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
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty := "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"];
                OnBeforeValidateGenProdPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
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
        field(61; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(62; "Allow Application"; Boolean)
        {
            Caption = 'Allow Application';
            InitValue = true;
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
                Validate("IC Partner G/L Acc. No.", '');
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
                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if xRec."Bal. Account Type" in
                   [xRec."Bal. Account Type"::Customer, xRec."Bal. Account Type"::Vendor]
                then begin
                    "Bill-to/Pay-to No." := '';
                    "Ship-to/Order Address Code" := '';
                    "Sell-to/Buy-from No." := '';
                    "VAT Registration No." := '';
                end;
                if ("Account Type" in [
                                       "Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]) and
                   ("Bal. Account Type" in [
                                            "Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"])
                then
                    Validate("Payment Terms Code", '');

                if "Bal. Account Type" = "Bal. Account Type"::"IC Partner" then begin
                    GetTemplate;
                    if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                        FieldError("Bal. Account Type");
                end;
            end;
        }
        field(64; "Bal. Gen. Posting Type"; Option)
        {
            Caption = 'Bal. Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenPostingType(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
                    TestField("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                if ("Bal. Gen. Posting Type" = "Gen. Posting Type"::Settlement) and (CurrFieldNo <> 0) then
                    Error(Text006, "Bal. Gen. Posting Type");
                if "Bal. Gen. Posting Type" > 0 then
                    Validate("Bal. VAT Prod. Posting Group");

                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                then begin
                    "Depreciation Book Code" := '';
                    Validate("FA Posting Type", "FA Posting Type"::" ");
                end;
                if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::Purchase then
                    Validate("Bal. Use Tax", false);
            end;
        }
        field(65; "Bal. Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Bal. Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenBusPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
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
                CheckIfFieldIsEmpty: Boolean;
            begin
                CheckIfFieldIsEmpty :=
                  "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"];
                OnBeforeValidateBalGenProdPostingGroup(Rec, CheckIfFieldIsEmpty);
                if CheckIfFieldIsEmpty then
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
                        begin
                            "Bal. VAT Amount" :=
                              Round(-Amount * "Bal. VAT %" / (100 + "Bal. VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                            "Bal. VAT Base Amount" :=
                              Round(-Amount - "Bal. VAT Amount", Currency."Amount Rounding Precision");
                        end;
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
                                  "Posting Date", Amount, Quantity, "Currency Factor"));
                            OnAfterSalesTaxCalculateReverseCalculateTax(Rec, CurrFieldNo);
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

                if "Currency Code" = '' then
                    "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                else
                    "Bal. VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", "Bal. VAT Amount", "Currency Factor"));
                OnValidateBalVATPctOnAfterAssignBalVATAmountLCY("Bal. VAT Amount (LCY)");
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY;
            end;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount';

            trigger OnValidate()
            begin
                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("Allow VAT Difference", true);
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

                if "Currency Code" = '' then
                    "Bal. VAT Amount (LCY)" := "Bal. VAT Amount"
                else
                    "Bal. VAT Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          "Bal. VAT Amount", "Currency Factor"));
                "Bal. VAT Base Amount (LCY)" := -("Amount (LCY)" + "Bal. VAT Amount (LCY)");

                UpdateSalesPurchLCY;
            end;
        }
        field(70; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            AccessByPermission = TableData "Bank Account" = R;
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
                                "Tax Area Code", "Tax Group Code", "Tax Liable", "Posting Date",
                                "VAT Base Amount", Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateCalculateTax(Rec, CurrFieldNo);
                            if "VAT Base Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" :=
                              Round("VAT Amount", Currency."Amount Rounding Precision");
                            Amount := "VAT Base Amount" + "VAT Amount";
                        end;
                end;
                OnValidateVATBaseAmountOnBeforeValidateAmount(Rec, Currency);
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
                                "Posting Date", "Bal. VAT Base Amount", Quantity, "Currency Factor");
                            OnAfterSalesTaxCalculateCalculateTax(Rec, CurrFieldNo);
                            if "Bal. VAT Base Amount" <> 0 then
                                "Bal. VAT %" := Round(100 * "Bal. VAT Amount" / "Bal. VAT Base Amount", 0.00001)
                            else
                                "Bal. VAT %" := 0;
                            "Bal. VAT Amount" :=
                              Round("Bal. VAT Amount", Currency."Amount Rounding Precision");
                            Amount := -"Bal. VAT Base Amount" - "Bal. VAT Amount";
                        end;
                end;
                OnValidateBalVATBaseAmountOnBeforeValidateAmount(Rec, Currency);
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
        field(74; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(75; "Check Printed"; Boolean)
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check Printed';
            Editable = false;
        }
        field(76; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                Validate("Payment Terms Code");
            end;
        }
        field(77; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(78; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';

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
            IF ("Source Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Source Type" = CONST(Employee)) Employee;

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

            trigger OnValidate()
            begin
                Validate("VAT %");
            end;
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

            trigger OnValidate()
            begin
                if not "Use Tax" then
                    exit;
                TestField("Gen. Posting Type", "Gen. Posting Type"::Purchase);
                Validate("VAT %");
            end;
        }
        field(86; "Bal. Tax Area Code"; Code[20])
        {
            Caption = 'Bal. Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(87; "Bal. Tax Liable"; Boolean)
        {
            Caption = 'Bal. Tax Liable';

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(88; "Bal. Tax Group Code"; Code[20])
        {
            Caption = 'Bal. Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("Bal. VAT %");
            end;
        }
        field(89; "Bal. Use Tax"; Boolean)
        {
            Caption = 'Bal. Use Tax';

            trigger OnValidate()
            begin
                if not "Bal. Use Tax" then
                    exit;
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

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end
            end;
        }
        field(91; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
                    TestField("VAT Prod. Posting Group", '');

                CheckVATInAlloc;

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Gen. Posting Type" <> 0 then begin
                        GetVATPostingSetup("VAT Bus. Posting Group", "VAT Prod. Posting Group");
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

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end
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
                    GetVATPostingSetup("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group");
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
        field(95; "Additional-Currency Posting"; Option)
        {
            Caption = 'Additional-Currency Posting';
            Editable = false;
            OptionCaption = 'None,Amount Only,Additional-Currency Amount Only';
            OptionMembers = "None","Amount Only","Additional-Currency Amount Only";
        }
        field(98; "FA Add.-Currency Factor"; Decimal)
        {
            Caption = 'FA Add.-Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(99; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(100; "Source Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            Editable = false;
        }
        field(101; "Source Curr. VAT Base Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Base Amount';
            Editable = false;
        }
        field(102; "Source Curr. VAT Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Source Curr. VAT Amount';
            Editable = false;
        }
        field(103; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(104; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(105; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(106; "Bal. VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Amount (LCY)';
            Editable = false;
        }
        field(107; "Bal. VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount (LCY)';
            Editable = false;
        }
        field(108; "Reversing Entry"; Boolean)
        {
            Caption = 'Reversing Entry';
            Editable = false;
        }
        field(109; "Allow Zero-Amount Posting"; Boolean)
        {
            Caption = 'Allow Zero-Amount Posting';
            Editable = false;
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
        field(114; "IC Direction"; Option)
        {
            Caption = 'IC Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;
        }
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";

            trigger OnValidate()
            var
                ICGLAccount: Record "IC G/L Account";
            begin
                if "Journal Template Name" <> '' then
                    if "IC Partner G/L Acc. No." <> '' then begin
                        GetTemplate;
                        GenJnlTemplate.TestField(Type, GenJnlTemplate.Type::Intercompany);
                        if ICGLAccount.Get("IC Partner G/L Acc. No.") then
                            ICGLAccount.TestField(Blocked, false);
                    end
            end;
        }
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
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

            trigger OnValidate()
            begin
                ReadGLSetup;
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No." then
                    UpdateCountryCodeAndVATRegNo("Sell-to/Buy-from No.");
            end;
        }
        field(119; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', 0);
            end;
        }
        field(120; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Validate("VAT Registration No.");
            end;
        }
        field(121; Prepayment; Boolean)
        {
            Caption = 'Prepayment';

            trigger OnValidate()
            begin
                ReadGLSetup;
                if GLSetup."Enable Russian Accounting" and Prepayment then begin
                    if not ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund]) then
                        FieldError("Document Type");
                    Clear("Applies-to Doc. Type");
                    Clear("Applies-to Doc. No.");
                    if "Prepayment Document No." <> '' then
                        Validate("Prepayment Document No.", "Prepayment Document No.")
                    else
                        GenJnlLine."Prepayment Document No." := '';
                end;
            end;
        }
        field(122; "Financial Void"; Boolean)
        {
            Caption = 'Financial Void';
            Editable = false;
        }
        field(123; "Copy VAT Setup to Jnl. Lines"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Lines';
            Editable = false;
            InitValue = true;
        }
        field(125; "VAT Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            Editable = false;
        }
        field(160; "Job Queue Status"; Option)
        {
            Caption = 'Job Queue Status';
            Editable = false;
            OptionCaption = ' ,Scheduled for Posting,Error,Posting';
            OptionMembers = " ","Scheduled for Posting",Error,Posting;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if Description = '' then
                    Description := CopyStr(IncomingDocument.Description, 1, MaxStrLen(Description));
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;

                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetGenJournalLine(Rec);
            end;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            Numeric = true;
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                UpdatePaymentMethodId;
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Bal. Account No."))
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Bal. Account No."));

            trigger OnValidate()
            begin
                if "Recipient Bank Account" = '' then
                    exit;
                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::" ", "Document Type"::"Credit Memo"]) and
                   (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) or
                    ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]))
                then
                    "Recipient Bank Account" := '';
            end;
        }
        field(289; "Message to Recipient"; Text[140])
        {
            Caption = 'Message to Recipient';
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
        }
        field(291; "Has Payment Export Error"; Boolean)
        {
            CalcFormula = Exist ("Payment Jnl. Export Error Text" WHERE("Journal Template Name" = FIELD("Journal Template Name"),
                                                                        "Journal Batch Name" = FIELD("Journal Batch Name"),
                                                                        "Journal Line No." = FIELD("Line No.")));
            Caption = 'Has Payment Export Error';
            Editable = false;
            FieldClass = FlowField;
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
        field(827; "Credit Card No."; Code[20])
        {
            Caption = 'Credit Card No.';
            ObsoleteReason = 'This field is not needed and it is not used anymore.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            begin
                if "Job Task No." <> xRec."Job Task No." then
                    Validate("Job Planning Line No.", 0);
                if "Job Task No." = '' then begin
                    "Job Quantity" := 0;
                    "Job Currency Factor" := 0;
                    "Job Currency Code" := '';
                    "Job Unit Price" := 0;
                    "Job Total Price" := 0;
                    "Job Line Amount" := 0;
                    "Job Line Discount Amount" := 0;
                    "Job Unit Cost" := 0;
                    "Job Total Cost" := 0;
                    "Job Line Discount %" := 0;

                    "Job Unit Price (LCY)" := 0;
                    "Job Total Price (LCY)" := 0;
                    "Job Line Amount (LCY)" := 0;
                    "Job Line Disc. Amount (LCY)" := 0;
                    "Job Unit Cost (LCY)" := 0;
                    "Job Total Cost (LCY)" := 0;
                    exit;
                end;

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    CopyDimensionsFromJobTaskLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1002; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            Caption = 'Job Unit Price (LCY)';
            Editable = false;
        }
        field(1003; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Total Price (LCY)';
            Editable = false;
        }
        field(1004; "Job Quantity"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    if "Job Planning Line No." <> 0 then
                        Validate("Job Planning Line No.");
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1005; "Job Unit Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 2;
            Caption = 'Job Unit Cost (LCY)';
            Editable = false;
        }
        field(1006; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Line Discount %';

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount %", "Job Line Discount %");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1007; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Job Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount Amount (LCY)", "Job Line Disc. Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1008; "Job Unit Of Measure Code"; Code[10])
        {
            Caption = 'Job Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(1009; "Job Line Type"; Option)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Line Type';
            OptionCaption = ' ,Budget,Billable,Both Budget and Billable';
            OptionMembers = " ",Budget,Billable,"Both Budget and Billable";

            trigger OnValidate()
            begin
                if "Job Planning Line No." <> 0 then
                    Error(Text019, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1010; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Price';

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Unit Price", "Job Unit Price");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1011; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Price';
            Editable = false;
        }
        field(1012; "Job Unit Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Job Unit Cost';
            Editable = false;
        }
        field(1013; "Job Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Total Cost';
            Editable = false;
        }
        field(1014; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Discount Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount Amount", "Job Line Discount Amount");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1015; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Job Line Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Amount", "Job Line Amount");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1016; "Job Total Cost (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Total Cost (LCY)';
            Editable = false;
        }
        field(1017; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Job Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Amount (LCY)", "Job Line Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1018; "Job Currency Factor"; Decimal)
        {
            Caption = 'Job Currency Factor';
        }
        field(1019; "Job Currency Code"; Code[10])
        {
            Caption = 'Job Currency Code';

            trigger OnValidate()
            begin
                if ("Job Currency Code" <> xRec."Job Currency Code") or ("Job Currency Code" <> '') then
                    if JobTaskIsSet then begin
                        CreateTempJobJnlLine();
                        UpdatePricesFromJobJnlLine();
                    end;
            end;
        }
        field(1020; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                JobPlanningLine.SetRange("No.", "Account No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                    JobPlanningLine.TestField("No.", "Account No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine."Line Type" + 1;
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - "Job Quantity");
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text018, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else begin
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                    end;
                end;
            end;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = IF ("Account Type" = CONST(Customer)) "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Account No."));

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if "Direct Debit Mandate ID" = '' then
                    exit;
                TestField("Account Type", "Account Type"::Customer);
                SEPADirectDebitMandate.Get("Direct Debit Mandate ID");
                SEPADirectDebitMandate.TestField("Customer No.", "Account No.");
                "Recipient Bank Account" := SEPADirectDebitMandate."Customer Bank Account Code";
            end;
        }
        field(1220; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(1221; "Payer Information"; Text[50])
        {
            Caption = 'Payer Information';
        }
        field(1222; "Transaction Information"; Text[100])
        {
            Caption = 'Transaction Information';
        }
        field(1223; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(1224; "Applied Automatically"; Boolean)
        {
            Caption = 'Applied Automatically';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                DeferralUtilities: Codeunit "Deferral Utilities";
            begin
                if "Deferral Code" <> '' then
                    TestField("Account Type", "Account Type"::"G/L Account");

                DeferralUtilities.DeferralCodeOnValidate("Deferral Code", DeferralDocType::"G/L", "Journal Template Name", "Journal Batch Name",
                  0, '', "Line No.", GetDeferralAmount(), "Posting Date", Description, "Currency Code");
            end;
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
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
        field(5400; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
        }
        field(5600; "FA Posting Date"; Date)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Gen. Journal Line FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';

            trigger OnValidate()
            begin
                if not (("Account Type" = "Account Type"::"Fixed Asset") or
                         ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")) and
                   ("FA Posting Type" = "FA Posting Type"::" ")
                then begin
                    "FA Posting Date" := 0D;
                    "Salvage Value" := 0;
                    "No. of Depreciation Days" := 0;
                    "Depr. until FA Posting Date" := false;
                    "Depr. Acquisition Cost" := false;
                    "Maintenance Code" := '';
                    "Insurance No." := '';
                    "Budgeted FA No." := '';
                    "Duplicate in Depreciation Book" := '';
                    "Use Duplication List" := false;
                    "FA Reclassification Entry" := false;
                    "FA Error Entry No." := 0;
                end;

                ReadGLSetup;
                if GLSetup."Enable Russian Accounting" then
                    "Depr. until FA Posting Date" := "FA Posting Type" = "FA Posting Type"::Disposal;

                if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then
                    TestField("Insurance No.", '');
                if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                    TestField("Maintenance Code", '');
                GetFAVATSetup;
                GetFAAddCurrExchRate;
            end;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "Depreciation Book Code" = '' then
                    exit;

                if ("Account No." <> '') and
                   ("Account Type" = "Account Type"::"Fixed Asset")
                then begin
                    FADeprBook.Get("Account No.", "Depreciation Book Code");
                    "Posting Group" := FADeprBook."FA Posting Group";
                end;

                if ("Bal. Account No." <> '') and
                   ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset")
                then begin
                    FADeprBook.Get("Bal. Account No.", "Depreciation Book Code");
                    "Posting Group" := FADeprBook."FA Posting Group";
                end;
                GetFAVATSetup;
                GetFAAddCurrExchRate;
            end;
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5604; "No. of Depreciation Days"; Integer)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            BlankZero = true;
            Caption = 'No. of Depreciation Days';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                if "Maintenance Code" <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::Maintenance);
            end;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;

            trigger OnValidate()
            begin
                if "Insurance No." <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
            end;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            var
                FA: Record "Fixed Asset";
            begin
                if "Budgeted FA No." <> '' then begin
                    FA.Get("Budgeted FA No.");
                    FA.TestField("Budgeted Asset", true);
                end;
            end;
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(5614; "FA Reclassification Entry"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Reclassification Entry';
        }
        field(5615; "FA Error Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'FA Error Entry No.';
            TableRelation = "FA Ledger Entry";
        }
        field(5616; "Index Entry"; Boolean)
        {
            Caption = 'Index Entry';
        }
        field(5617; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(5618; Comment; Text[250])
        {
            Caption = 'Comment';
        }
        field(5701; "Check Exported"; Boolean)
        {
            Caption = 'Check Exported';
        }
        field(5702; "Check Transmitted"; Boolean)
        {
            Caption = 'Check Transmitted';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(8001; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".Id;

            trigger OnValidate()
            begin
                UpdateAccountNo;
            end;
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.Id;

            trigger OnValidate()
            begin
                UpdateCustomerNo;
            end;
        }
        field(8003; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';
            TableRelation = "Sales Invoice Header".Id;

            trigger OnValidate()
            begin
                UpdateAppliesToInvoiceNo;
            end;
        }
        field(8004; "Contact Graph Id"; Text[250])
        {
            Caption = 'Contact Graph Id';
        }
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
        field(8006; "Journal Batch Id"; Guid)
        {
            Caption = 'Journal Batch Id';
            TableRelation = "Gen. Journal Batch".Id;

            trigger OnValidate()
            begin
                UpdateJournalBatchName;
            end;
        }
        field(8007; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".Id;

            trigger OnValidate()
            begin
                UpdatePaymentMethodCode;
            end;
        }
        field(12400; "Initial Entry No."; Integer)
        {
            Caption = 'Initial Entry No.';
        }
        field(12401; "Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Beneficiary Bank Code';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Bank Account".Code WHERE("Customer No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Account No."))
            ELSE
            IF ("Account Type" = CONST("G/L Account")) "Bank Account Details".Code WHERE("G/L Account" = FIELD("Account No."));

            trigger OnValidate()
            var
                BankAccountDetails: Record "Bank Account Details";
            begin
                if ("Account Type" = "Account Type"::"G/L Account") and
                   ("Beneficiary Bank Code" <> xRec."Beneficiary Bank Code") and
                   ("Beneficiary Bank Code" <> '')
                then begin
                    BankAccountDetails.Get("Beneficiary Bank Code");
                    BankAccountDetails.TestField("G/L Account");
                    Validate("Account No.", BankAccountDetails."G/L Account");
                    "Beneficiary Bank Code" := BankAccountDetails.Code;
                    "Bank Acc. Details VAT Reg. No." := BankAccountDetails."VAT Registration No.";
                    "Bank Acc. Dtls. Bank Acc. No." := BankAccountDetails."Bank Account No.";
                end;
                SetExportStatus;
                UpdatePaymentVATInfo(true);
            end;
        }
        field(12402; "Payment Purpose"; Text[250])
        {
            Caption = 'Payment Purpose';
            //This property is currently not supported
            //TestTableRelation = false;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, StdText) = ACTION::LookupOK then
                    "Payment Purpose" := StdText.Description;
                UpdatePaymentVATInfo(false);
            end;

            trigger OnValidate()
            begin
                UpdatePaymentVATInfo(false);
            end;
        }
        field(12403; "Cash Order Including"; Text[250])
        {
            Caption = 'Cash Order Including';

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, StdText) = ACTION::LookupOK then
                    "Cash Order Including" := StdText.Description;
                UpdatePaymentVATInfo(false);
            end;

            trigger OnValidate()
            begin
                UpdatePaymentVATInfo(false);
            end;
        }
        field(12404; "Cash Order Supplement"; Text[100])
        {
            Caption = 'Cash Order Supplement';

            trigger OnLookup()
            begin
                if PAGE.RunModal(0, StdText) = ACTION::LookupOK then
                    "Cash Order Supplement" := StdText.Description;
                UpdatePaymentVATInfo(false);
            end;

            trigger OnValidate()
            begin
                UpdatePaymentVATInfo(false);
            end;
        }
        field(12405; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionCaption = ' ,Mail,Telegraph,Through Moscow,Clearing,Electronic';
            OptionMembers = " ",Mail,Telegraph,"Through Moscow",Clearing,Electronic;
        }
        field(12406; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(12407; "Payment Subsequence"; Text[2])
        {
            Caption = 'Payment Subsequence';
        }
        field(12408; "Payment Code"; Text[20])
        {
            Caption = 'Payment Code';
        }
        field(12409; "Payment Assignment"; Text[15])
        {
            Caption = 'Payment Assignment';
        }
        field(12410; "Payment Type"; Text[5])
        {
            Caption = 'Payment Type';
        }
        field(12411; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount (LCY)';

            trigger OnValidate()
            begin
                Validate("Amount (LCY)", Round("Debit Amount (LCY)"));
            end;
        }
        field(12412; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount (LCY)';

            trigger OnValidate()
            begin
                Validate("Amount (LCY)", -Round("Credit Amount (LCY)"));
            end;
        }
        field(12413; "Prepmt. Diff."; Boolean)
        {
            Caption = 'Prepmt. Diff.';
            Editable = false;
        }
        field(12417; "VAT Transaction No."; Integer)
        {
            Caption = 'VAT Transaction No.';

            trigger OnLookup()
            var
                DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
            begin
                case "Account Type" of
                    "Account Type"::Vendor:
                        begin
                            DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
                            if "VAT Transaction No." <> 0 then
                                DtldVendLedgEntry.SetRange("Transaction No.", "VAT Transaction No.");
                            DtldVendLedgEntry.SetRange("Vendor No.", "Account No.");
                            if "VAT Settlement Part" = "VAT Settlement Part"::" " then
                                DtldVendLedgEntry.SetFilter("Entry Type", '%1|%2|%3', DtldVendLedgEntry."Entry Type"::Application,
                                                                                    DtldVendLedgEntry."Entry Type"::"Realized Loss",
                                                                                    DtldVendLedgEntry."Entry Type"::"Realized Gain");
                            PAGE.Run(0, DtldVendLedgEntry);
                        end;
                    "Account Type"::Customer:
                        begin
                            DtldCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
                            if "VAT Transaction No." <> 0 then
                                DtldCustLedgEntry.SetRange("Transaction No.", "VAT Transaction No.");
                            DtldCustLedgEntry.SetRange("Customer No.", "Account No.");
                            PAGE.Run(0, DtldCustLedgEntry);
                        end;
                end;
            end;
        }
        field(12418; "VAT Settlement Part"; Option)
        {
            Caption = 'VAT Settlement Part';
            Editable = false;
            OptionCaption = ' ,,,,,,,Custom';
            OptionMembers = " ",,,,,,,Custom;
        }
        field(12419; "Unrealized VAT Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Unrealized VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No.";

            trigger OnValidate()
            var
                VATEntry: Record "VAT Entry";
                VATPostingSetup: Record "VAT Posting Setup";
                VendLedgEntry: Record "Vendor Ledger Entry";
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                "VAT Settlement Part" := "VAT Settlement Part"::Custom;
                VATEntry.Get("Unrealized VAT Entry No.");
                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                    VATEntry.TestField("Unrealized Amount")
                else
                    VATEntry.TestField("Unrealized Base");
                "Initial Entry No." := VATEntry."CV Ledg. Entry No.";
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                case VATEntry.Type of
                    VATEntry.Type::Purchase:
                        begin
                            "Account Type" := "Account Type"::Vendor;
                            "Bal. Account No." := VATPostingSetup."Purch. VAT Unreal. Account";
                            if VendLedgEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                                Description := VendLedgEntry.Description;
                                "Posting Group" := VendLedgEntry."Vendor Posting Group";
                                "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                            end;
                        end;
                    VATEntry.Type::Sale:
                        begin
                            "Account Type" := "Account Type"::Customer;
                            "Bal. Account No." := VATPostingSetup."Sales VAT Unreal. Account";
                            if CustLedgEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                                Description := CustLedgEntry.Description;
                                "Posting Group" := CustLedgEntry."Customer Posting Group";
                                "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                            end;
                        end;
                end;
                if VATEntry."Bill-to/Pay-to No." <> '' then
                    "Account No." := VATEntry."Bill-to/Pay-to No."
                else begin
                    "Account Type" := VATEntry."Object Type";
                    "Account No." := VATEntry."Object No.";
                end;
                "Object Type" := VATEntry."Object Type";
                "Object No." := VATEntry."Object No.";
                "Document Type" := VATEntry."Document Type";
                "Document No." := VATEntry."Document No.";
                "Paid Amount" := VATEntry."Remaining Unrealized Amount"; // To rename
                "Unrealized Amount" := VATEntry."Unrealized Amount";
                "Posting Date" := VATEntry."Posting Date";
                "Document Date" := VATEntry."Posting Date";
                "Prepmt. Diff." := VATEntry."Prepmt. Diff.";
                Correction := false;
                "Currency Code" := '';
                CalcFields("Allocated VAT Amount");
                Amount := -"Allocated VAT Amount";
            end;
        }
        field(12420; "Paid Amount"; Decimal)
        {
            Caption = 'Paid Amount';
            Editable = false;
        }
        field(12421; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";
        }
        field(12422; "Initial VAT Entry No."; Integer)
        {
            Caption = 'Initial VAT Entry No.';
            TableRelation = IF ("Account Type" = CONST(Vendor)) "VAT Entry"."Entry No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                             "Document No." = FIELD("Document No."),
                                                                                             Type = CONST(Purchase),
                                                                                             "Unrealized VAT Entry No." = FILTER(<> 0),
                                                                                             "Bill-to/Pay-to No." = FIELD("Account No."),
                                                                                             "Prepmt. Diff." = CONST(false))
            ELSE
            IF ("Account Type" = CONST(Customer)) "VAT Entry"."Entry No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                                                                                                     "Document No." = FIELD("Document No."),
                                                                                                                                                                     Type = CONST(Sale),
                                                                                                                                                                     "Bill-to/Pay-to No." = FIELD("Account No."),
                                                                                                                                                                     "Unrealized VAT Entry No." = FILTER(<> 0),
                                                                                                                                                                     "Prepmt. Diff." = CONST(false));

            trigger OnValidate()
            begin
                TestField("Prepmt. Diff.");
            end;
        }
        field(12423; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;
        }
        field(12424; "Object No."; Code[20])
        {
            Caption = 'Object No.';
            TableRelation = IF ("Object Type" = CONST(Customer)) Customer
            ELSE
            IF ("Object Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Object Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Object Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Object Type" = CONST("G/L Account")) "G/L Account";
        }
        field(12425; "Prepayment Document No."; Code[20])
        {
            Caption = 'Prepayment Document No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Sales Header"."No." WHERE("Document Type" = FILTER(Order | Invoice),
                                                                                            "Bill-to Customer No." = FIELD("Account No."),
                                                                                            "Agreement No." = FIELD("Agreement No."))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Purchase Header"."No." WHERE("Document Type" = FILTER(Order | Invoice),
                                                                                                                                                                  "Buy-from Vendor No." = FIELD("Account No."),
                                                                                                                                                                  "Agreement No." = FIELD("Agreement No."));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnValidate()
            var
                Cust: Record Customer;
            begin
                TestField(Prepayment, true);
                if "Account Type" = "Account Type"::Customer then
                    Cust.CheckPrepaymentDocNo(Rec, false);
            end;
        }
        field(12426; "Prepayment Status"; Option)
        {
            Caption = 'Prepayment Status';
            OptionCaption = ' ,Set,Reset';
            OptionMembers = " ",Set,Reset;
        }
        field(12427; "Advance VAT Base Amount"; Decimal)
        {
            Caption = 'Advance VAT Base Amount';
        }
        field(12428; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(12429; "Prepmt. Diff. Appln. Entry No."; Integer)
        {
            Caption = 'Prepmt. Diff. Appln. Entry No.';
            Editable = false;
        }
        field(12430; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(12431; "Corrective Doc. Type"; Option)
        {
            Caption = 'Corrective Doc. Type';
            OptionCaption = ' ,Correction,Revision';
            OptionMembers = " ",Correction,Revision;
        }
        field(12434; "Initial Document No."; Code[20])
        {
            Caption = 'Initial Document No.';
            TableRelation = IF ("Account Type" = CONST(Vendor),
                                "Document Type" = FILTER(Payment | Refund)) "Purch. Inv. Header" WHERE("Buy-from Vendor No." = FIELD("Account No."));
        }
        field(12435; "Vendor VAT Invoice No."; Code[30])
        {
            Caption = 'Vendor VAT Invoice No.';
        }
        field(12436; "Vendor VAT Invoice Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Date';
        }
        field(12437; "Vendor VAT Invoice Rcvd Date"; Date)
        {
            Caption = 'Vendor VAT Invoice Rcvd Date';
        }
        field(12445; "VAT Entry Type"; Code[15])
        {
            Caption = 'VAT Entry Type';

            trigger OnLookup()
            var
                VATEntryType: Record "VAT Entry Type";
            begin
                VATEntryType.LookupSetOfVATEntryCodes("VAT Entry Type");
            end;

            trigger OnValidate()
            var
                VATEntryType: Record "VAT Entry Type";
            begin
                VATEntryType.ValidateSetOfVATEntryCodes("VAT Entry Type");
            end;
        }
        field(12470; "Vendor Receipts No."; Code[20])
        {
            Caption = 'Vendor Receipts No.';
        }
        field(12471; "Vendor Receipts Date"; Date)
        {
            Caption = 'Vendor Receipts Date';
        }
        field(12472; "Applies-to Doc. Date"; Date)
        {
            Caption = 'Applies-to Doc. Date';
        }
        field(12476; "FA Charge No."; Code[20])
        {
            Caption = 'FA Charge No.';
            Editable = false;
            TableRelation = "FA Charge";
        }
        field(12480; KBK; Code[20])
        {
            Caption = 'KBK';
            TableRelation = KBK;

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption(KBK),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");
            end;
        }
        field(12481; OKATO; Code[11])
        {
            Caption = 'OKATO';
            TableRelation = OKATO;

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption(OKATO),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");
            end;
        }
        field(12482; "Period Code"; Option)
        {
            Caption = 'Period Code';
            OptionCaption = ' ,0,D1-payment for the first decade of month,D2-payment for the second decade of month,D3-payment for the third decade of month,MH-monthly payments,QT-quarter payment,HY-half-year payments,YR-year payments';
            OptionMembers = " ","0",D1,D2,D3,MH,QT,HY,YR;

            trigger OnValidate()
            var
                MonthText: Text[2];
                YearText: Text[4];
                QuarterText: Text[30];
                HalfYearText: Text[30];
            begin
                case "Period Code" of
                    "Period Code"::" ":
                        "Tax Period" := '';
                    "Period Code"::"0":
                        "Tax Period" := '0';
                    "Period Code"::D1,
                  "Period Code"::D2,
                  "Period Code"::D3:
                        "Tax Period" :=
                          StrSubstNo('%1.%2',
                            CopyStr(Format("Period Code"), 1, 2), Format("Posting Date", 0, '<Month,2>.<Year4>'));

                    "Period Code"::MH:
                        "Tax Period" :=
                          StrSubstNo('%1.%2',
                            CopyStr(Format("Period Code"), 1, 2),
                            Format(CalcDate('<-1M>', "Posting Date"), 0, '<Month,2>.<Year4>'));

                    "Period Code"::QT:
                        "Tax Period" :=
                          StrSubstNo('%1.%2.%3',
                            CopyStr(Format("Period Code"), 1, 2),
                            Format("Posting Date", 0, '<Quarter,2><Filler Character,0>'),
                            Format(CalcDate('<-1Q>', "Posting Date"), 0, '<Year4>'));

                    "Period Code"::HY:
                        begin
                            if Date2DMY(CalcDate('<-2Q>', "Posting Date"), 2) > 6 then
                                HalfYearText := '02'
                            else
                                HalfYearText := '01';
                            "Tax Period" :=
                              StrSubstNo('%1.%2.%3',
                                CopyStr(Format("Period Code"), 1, 2),
                                HalfYearText,
                                Format(CalcDate('<-2Q>', "Posting Date"), 0, '<Year4>'));
                        end;

                    "Period Code"::YR:
                        "Tax Period" :=
                          StrSubstNo('%1.%2.%3',
                            CopyStr(Format("Period Code"), 1, 2),
                            '00',
                            Format(CalcDate('<-1Y>', "Posting Date"), 0, '<Year4>'));
                end;
            end;
        }
        field(12483; "Payment Reason Code"; Code[10])
        {
            Caption = 'Payment Reason Code';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Payment Reason"));

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption("Payment Reason Code"),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");

                PaymentOrderCode.Get(PaymentOrderCode.Type::"Payment Reason", "Payment Reason Code");
                "Reason Document No." := PaymentOrderCode."Reason Document No.";
                "Reason Document Type" := PaymentOrderCode."Reason Document Type";
            end;
        }
        field(12484; "Reason Document No."; Code[10])
        {
            Caption = 'Reason Document No.';

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption("Reason Document No."),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");

                PaymentOrderCode.Get(PaymentOrderCode.Type::"Payment Reason", "Payment Reason Code");
                if (PaymentOrderCode."Reason Document No." <> '') and
                 ("Reason Document No." <> PaymentOrderCode."Reason Document No.")
                then
                    Error(Text001,
                      FieldCaption("Reason Document No."),
                      FieldCaption("Payment Reason Code"),
                      "Payment Reason Code");
            end;
        }
        field(12485; "Reason Document Date"; Date)
        {
            AutoFormatType = 2;
            Caption = 'Reason Document Date';

            trigger OnValidate()
            var
                TestDate: Date;
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption("Reason Document Date"),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");

                PaymentOrderCode.Get(PaymentOrderCode.Type::"Payment Reason", "Payment Reason Code");
                if (PaymentOrderCode."Reason Document No." <> '') and
                 ("Reason Document No." <> PaymentOrderCode."Reason Document No.")
                then
                    Error(Text001,
                      FieldCaption("Reason Document Date"),
                      FieldCaption("Payment Reason Code"),
                      "Payment Reason Code");
            end;
        }
        field(12486; "Tax Payment Type"; Code[10])
        {
            Caption = 'Tax Payment Type';
            TableRelation = "Payment Order Code".Code WHERE(Type = CONST("Tax Payment Type"));

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption("Tax Payment Type"),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");
            end;
        }
        field(12487; "Tax Period"; Code[10])
        {
            Caption = 'Tax Period';

            trigger OnValidate()
            begin
                if "Taxpayer Status" = 0 then
                    Error(Text001,
                      FieldCaption("Tax Period"),
                      FieldCaption("Taxpayer Status"),
                      "Taxpayer Status");

                if ("Tax Period" <> '') and ("Tax Period" <> '0') then begin
                    if StrLen("Tax Period") <> 10 then
                        Error('');
                    if CopyStr("Tax Period", 3, 1) <> '.' then
                        Error('');
                    if CopyStr("Tax Period", 6, 1) <> '.' then
                        Error('');
                end;
            end;
        }
        field(12488; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            Editable = false;
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;

            trigger OnValidate()
            begin
                Validate("Reason Document Date");
            end;
        }
        field(12489; "Taxpayer Status"; Option)
        {
            Caption = 'Taxpayer Status';
            OptionCaption = ' ,01-taxpayer (charges payer),02-tax agent,03-collector of taxes and charges,04-tax authority,05-service of officers of justice of Department of Justice of Russian Federation,06-participant of foreign-economic activity,07-tax authority,08-payer of other mandatory payments';
            OptionMembers = " ","01","02","03","04","05","06","07","08";

            trigger OnValidate()
            var
                Vend2: Record Vendor;
            begin
                if "Taxpayer Status" = 0 then begin
                    "Period Code" := 0;
                    Validate("Payment Reason Code", '');
                    "Reason Document No." := '';
                    "Reason Document Date" := 0D;
                    "Tax Payment Type" := '';
                    "Tax Period" := '';
                    OKATO := '';
                    KBK := '';
                end else begin
                    if ("Account Type" = "Account Type"::Vendor) and Vend2.Get("Account No.") then
                        Vend2.TestField("Vendor Type", Vend2."Vendor Type"::"Tax Authority")
                    else
                        "Taxpayer Status" := "Taxpayer Status"::" ";
                    "Period Code" := 1;
                    Validate("Payment Reason Code", '0');
                    "Reason Document No." := '0';
                    "Reason Document Date" := 0D;
                    "Tax Payment Type" := '0';
                    "Tax Period" := '0';
                    OKATO := '0';
                    KBK := '0';
                end;
            end;
        }
        field(12490; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) "Customer Agreement"."No." WHERE("Customer No." = FIELD("Account No."),
                                                                                                  Active = CONST(true))
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Agreement"."No." WHERE("Vendor No." = FIELD("Account No."),
                                                                                                                                                                         Active = CONST(true));

            trigger OnValidate()
            begin
                if "Agreement No." <> '' then
                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustAgrmt.Get("Account No.", "Agreement No.");
                                CustAgrmt.TestField(Active, true);
                                Validate("Posting Group", CustAgrmt."Customer Posting Group");
                                Validate("Currency Code", CustAgrmt."Currency Code");
                                Validate("Payment Terms Code", CustAgrmt."Payment Terms Code");
                                Validate("Salespers./Purch. Code", CustAgrmt."Salesperson Code");

                                "Dimension Set ID" :=
                                  CustAgrmt.GetDefaultDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendAgrmt.Get("Account No.", "Agreement No.");
                                VendAgrmt.TestField(Active, true);
                                Validate("Posting Group", VendAgrmt."Vendor Posting Group");
                                Validate("Currency Code", VendAgrmt."Currency Code");
                                Validate("Payment Terms Code", VendAgrmt."Payment Terms Code");
                                Validate("Salespers./Purch. Code", VendAgrmt."Purchaser Code");

                                "Dimension Set ID" :=
                                  VendAgrmt.GetDefaultDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                            end;
                    end;
                if "Agreement No." <> xRec."Agreement No." then
                    "Prepayment Document No." := '';
            end;
        }
        field(12491; "Depr. Period Starting Date"; Date)
        {
            Caption = 'Depr. Period Starting Date';
            TableRelation = "Accounting Period";
        }
        field(12492; "Payer Vendor No."; Code[20])
        {
            Caption = 'Payer Vendor No.';
            TableRelation = Vendor;
        }
        field(12493; "Payer Beneficiary Bank Code"; Code[20])
        {
            Caption = 'Payer Beneficiary Bank Code';
            TableRelation = "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Payer Vendor No."));
        }
        field(12497; "Include In Other VAT Ledger"; Boolean)
        {
            Caption = 'Include In Other VAT Ledger';
        }
        field(12498; "Additional VAT Ledger Sheet"; Boolean)
        {
            Caption = 'Additional VAT Ledger Sheet';
        }
        field(12499; "Corrected Document Date"; Date)
        {
            Caption = 'Corrected Document Date';
        }
        field(14900; "Export Status"; Option)
        {
            Caption = 'Export Status';
            Editable = false;
            OptionCaption = ' ,New,Exported,Bank Statement Found';
            OptionMembers = " ",New,Exported,"Bank Statement Found";
        }
        field(14901; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        field(14902; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
        }
        field(14903; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(14904; "Bank Acc. Details VAT Reg. No."; Text[20])
        {
            Caption = 'Bank Acc. Details VAT Reg. No.';
        }
        field(14905; "Bank Acc. Dtls. Bank Acc. No."; Code[30])
        {
            Caption = 'Bank Acc. Dtls. Bank Acc. No.';
        }
        field(14910; "Acc. Schedule Name"; Code[10])
        {
            Caption = 'Acc. Schedule Name';
            TableRelation = "Acc. Schedule Name";

            trigger OnValidate()
            var
                AccScheduleName: Record "Acc. Schedule Name";
            begin
                if "Acc. Schedule Name" <> '' then
                    if AccScheduleName.Get("Acc. Schedule Name") then
                        if AccScheduleName."Default Column Layout" <> '' then
                            "Column Layout Name" := AccScheduleName."Default Column Layout";
            end;
        }
        field(14911; "Acc. Schedule Line No."; Integer)
        {
            Caption = 'Acc. Schedule Line No.';
            TableRelation = "Acc. Schedule Line"."Line No." WHERE("Schedule Name" = FIELD("Acc. Schedule Name"));
        }
        field(14912; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(14913; "Column Layout Line No."; Integer)
        {
            Caption = 'Column Layout Line No.';
            TableRelation = "Column Layout"."Line No." WHERE("Column Layout Name" = FIELD("Column Layout Name"));
        }
        field(14925; "Allocated VAT Amount"; Decimal)
        {
            CalcFormula = Sum ("VAT Allocation Line".Amount WHERE("VAT Entry No." = FIELD("Unrealized VAT Entry No.")));
            Caption = 'Allocated VAT Amount';
            Editable = false;
            FieldClass = FlowField;

            trigger OnLookup()
            var
                VATAllocLine: Record "VAT Allocation Line";
                VATAllocation: Page "VAT Allocation";
            begin
                VATAllocLine.SetRange("VAT Entry No.", "Unrealized VAT Entry No.");
                VATAllocLine.SetRange("Posting Date Filter", 0D, "Posting Date");
                VATAllocation.SetTableView(VATAllocLine);
                VATAllocation.RunModal;
            end;
        }
        field(14926; "Unrealized Amount"; Decimal)
        {
            Caption = 'Unrealized Amount';
        }
        field(14927; "VAT Allocation Type"; Option)
        {
            Caption = 'VAT Allocation Type';
            OptionCaption = 'VAT,Write-Off,Charge';
            OptionMembers = VAT,WriteOff,Charge;
        }
        field(14929; "Reinstatement VAT Entry No."; Integer)
        {
            Caption = 'Reinstatement VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No." WHERE(Amount = FILTER(<> 0),
                                                           "VAT Allocation Type" = CONST(VAT),
                                                           Type = CONST(Purchase),
                                                           Reversed = CONST(false),
                                                           "Unrealized VAT Entry No." = FILTER(<> 0),
                                                           "VAT Reinstatement" = CONST(false));

            trigger OnValidate()
            var
                VATEntry: Record "VAT Entry";
                UnrealizedVATEntry: Record "VAT Entry";
                AmountToReinstate: Decimal;
            begin
                VATEntry.Get("Reinstatement VAT Entry No.");
                if VATEntry."VAT Calculation Type" <> VATEntry."VAT Calculation Type"::"Full VAT" then
                    VATEntry.TestField(Base);
                "Initial Entry No." := VATEntry."CV Ledg. Entry No.";
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                VATPostingSetup.TestField("Trans. VAT Type", VATPostingSetup."Trans. VAT Type"::" ");
                VATPostingSetup.TestField("Trans. VAT Account", '');
                if not (VATPostingSetup."VAT Calculation Type" in
                  [VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."VAT Calculation Type"::"Full VAT"])
                then
                    VATPostingSetup.FieldError("VAT Calculation Type");
                "Account Type" := "Account Type"::Vendor;
                "Bal. Account No." := VATPostingSetup."Purch. VAT Unreal. Account";
                if VendLedgEntry.Get(VATEntry."CV Ledg. Entry No.") then begin
                    Description := VendLedgEntry.Description;
                    "Posting Group" := VendLedgEntry."Vendor Posting Group";
                    "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                    DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                end;

                if VATEntry."Bill-to/Pay-to No." <> '' then
                    "Account No." := VATEntry."Bill-to/Pay-to No."
                else begin
                    "Account Type" := VATEntry."Object Type";
                    "Account No." := VATEntry."Object No.";
                end;
                "Object Type" := VATEntry."Object Type";
                "Object No." := VATEntry."Object No.";
                "Document Type" := VATEntry."Document Type";
                "Document No." := VATEntry."Document No.";
                "Posting Date" := VATEntry."Posting Date";
                "Document Date" := VATEntry."Posting Date";
                Correction := false;
                "Currency Code" := '';
                UnrealizedVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
                AmountToReinstate := UnrealizedVATEntry."Unrealized Amount" - UnrealizedVATEntry."Remaining Unrealized Amount";
                if VATEntry.Amount < AmountToReinstate then
                    AmountToReinstate := VATEntry.Amount;
                Validate(Amount, AmountToReinstate);

                GenJnlTemplate.Get("Journal Template Name");
                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                "Source Code" := GenJnlTemplate."Source Code";
                "Reason Code" := GenJnlBatch."Reason Code";
            end;
        }
        field(17201; "Depr. Bonus"; Boolean)
        {
            Caption = 'Depr. Bonus';
        }
        field(17202; "Tax. Diff. Dtld. Entry No."; Integer)
        {
            Caption = 'Tax. Diff. Dtld. Entry No.';
        }
        field(17300; "Tax Difference Code"; Code[10])
        {
            Caption = 'Tax Difference Code';
            TableRelation = "Tax Difference" WHERE("Source Code Mandatory" = CONST(true),
                                                    "Depreciation Bonus" = CONST(false));

            trigger OnValidate()
            var
                FALedgerEntry: Record "FA Ledger Entry";
            begin
                if "Tax Difference Code" <> xRec."Tax Difference Code" then begin
                    if "FA Error Entry No." <> 0 then begin
                        FALedgerEntry.Get("FA Error Entry No.");
                        TestField("Tax Difference Code", FALedgerEntry."Tax Difference Code");
                    end;
                    if "Tax Difference Code" <> '' then begin
                        TestField("Account Type", "Account Type"::"Fixed Asset");
                        TestField("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
                    end;
                end;
            end;
        }
        field(17301; "Depr. Group Elimination"; Boolean)
        {
            Caption = 'Depr. Group Elimination';
        }
        field(17400; "Payroll Ledger Entry No."; Integer)
        {
            Caption = 'Payroll Ledger Entry No.';
            TableRelation = "Payroll Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.")
        {
            MaintainSQLIndex = false;
            SumIndexFields = "Debit Amount", "Credit Amount";
        }
        key(Key3; "Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.")
        {
        }
        key(Key4; "Document No.")
        {
            SumIndexFields = "Debit Amount", "Credit Amount";
        }
        key(Key5; "Incoming Document Entry No.")
        {
        }
        key(Key6; "Document No.", "Posting Date", "Source Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
        key(Key7; "Data Exch. Entry No.")
        {
        }
        key(Key8; "Journal Batch Name", "Journal Template Name")
        {
            SumIndexFields = "Balance (LCY)";
        }
        key(Key9; "Source Code", "Document No.", "Posting Date")
        {
            MaintainSqlIndex = false;
            SumIndexFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.OnCancelGeneralJournalLineApprovalRequest(Rec);

        // Lines are deleted 1 by 1, this actually check if this is the last line in the General journal Bach
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJournalLine.Count = 1 then
            if GenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
                ApprovalsMgmt.OnCancelGeneralJournalBatchApprovalRequest(GenJournalBatch);

        TestField("Check Printed", false);

        ClearCustVendApplnEntry;
        ClearAppliedGenJnlLine;
        DeletePaymentFileErrors;
        ClearDataExchangeEntries(false);

        GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
        if not GenJnlAlloc.IsEmpty then
            GenJnlAlloc.DeleteAll();

        DeferralUtilities.DeferralCodeOnDelete(
          DeferralDocType::"G/L",
          "Journal Template Name",
          "Journal Batch Name", 0, '', "Line No.");

        Validate("Incoming Document Entry No.", 0);
    end;

    trigger OnInsert()
    var
        BankAcc: Record "Bank Account";
    begin
        GenJnlAlloc.LockTable();
        LockTable();

        SetLastModifiedDateTime;

        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Copy VAT Setup to Jnl. Lines" := GenJnlBatch."Copy VAT Setup to Jnl. Lines";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";
        "Check Printed" := false;

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");

        if GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"Bank Account" then
            if BankAcc.Get(GenJnlBatch."Bal. Account No.") then
                "Bank Account No." := BankAcc."Bank Account No.";

        if "Export Status" <> "Export Status"::" " then
            "Export Status" := "Export Status"::New;
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        CheckJobQueueStatus(Rec);
        SetLastModifiedDateTime;

        IsHandled := false;
        OnModifyOnBeforeTestCheckPrinted(Rec, IsHandled);
        if not IsHandled then
            TestField("Check Printed", false);

        if ("Applies-to ID" = '') and (xRec."Applies-to ID" <> '') then
            ClearCustVendApplnEntry;
    end;

    trigger OnRename()
    begin
        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);

        TestField("Check Printed", false);
    end;

    var
        Text000: Label '%1 or %2 must be a G/L Account or Bank Account.', Comment = '%1=Account Type,%2=Balance Account Type';
        Text001: Label 'You must not specify %1 when %2 is %3.';
        Text002: Label 'cannot be specified without %1';
        ChangeCurrencyQst: Label 'The Currency Code in the Gen. Journal Line will be changed from %1 to %2.\\Do you want to continue?', Comment = '%1=FromCurrencyCode, %2=ToCurrencyCode';
        UpdateInterruptedErr: Label 'The update has been interrupted to respect the warning.';
        Text006: Label 'The %1 option can only be used internally in the system.';
        Text007: Label '%1 or %2 must be a bank account.', Comment = '%1=Account Type,%2=Balance Account Type';
        Text008: Label ' must be 0 when %1 is %2.';
        Text009: Label 'LCY';
        Text010: Label '%1 must be %2 or %3.';
        Text011: Label '%1 must be negative.';
        Text012: Label '%1 must be positive.';
        Text013: Label 'The %1 must not be more than %2.';
        WrongJobQueueStatus: Label 'Journal line cannot be modified because it has been scheduled for posting.';
        RenumberDocNoQst: Label 'If you have many documents it can take time to sort them, and %1 might perform slowly during the process. In those cases we suggest that you sort them during non-working hours. Do you want to continue?', Comment = '%1= Business Central';
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        PaymentTerms: Record "Payment Terms";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        GLSetup: Record "General Ledger Setup";
        Job: Record Job;
        SourceCodeSetup: Record "Source Code Setup";
        TempJobJnlLine: Record "Job Journal Line" temporary;
        StdText: Record "Standard Text";
        GLEntry: Record "G/L Entry";
        VATProdGr: Record "VAT Product Posting Group";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        VendAgrmt: Record "Vendor Agreement";
        CustAgrmt: Record "Customer Agreement";
        BankAccountDetail: Record "Bank Account Details";
        PaymentOrderCode: Record "Payment Order Code";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ApplyCustEntries: Page "Apply Customer Entries";
        ApplyVendEntries: Page "Apply Vendor Entries";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        DimMgt: Codeunit DimensionManagement;
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        Window: Dialog;
        VATReinstMgt: Codeunit "VAT Reinstatement Management";
        DeferralDocType: Option Purchase,Sales,"G/L";
        CurrencyCode: Code[10];
        Text014: Label 'The %1 %2 has a %3 %4.\\Do you still want to use %1 %2 in this journal line?', Comment = '%1=Caption of Table Customer, %2=Customer No, %3=Caption of field Bill-to Customer No, %4=Value of Bill-to customer no.';
        TemplateFound: Boolean;
        Text015: Label 'You are not allowed to apply and post an entry to an entry with an earlier posting date.\\Instead, post %1 %2 and then apply it to %3 %4.';
        CurrencyDate: Date;
        Text016: Label '%1 must be G/L Account or Bank Account.';
        HideValidationDialog: Boolean;
        Text018: Label '%1 can only be set when %2 is set.';
        Text019: Label '%1 cannot be changed when %2 is set.';
        GLSetupRead: Boolean;
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export them again?';
        NothingToExportErr: Label 'There is nothing to export.';
        NotExistErr: Label 'Document number %1 does not exist or is already closed.', Comment = '%1=Document number';
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        DueDateMsg: Label 'This posting date will cause an overdue payment.';
        CalcPostDateMsg: Label 'Processing payment journal lines #1##########';
        NoEntriesToVoidErr: Label 'There are no entries to void.';
        SuppressCommit: Boolean;
        Text14910: Label '%1 series %2 number %3 issued by %4 %5.';
        Text14925: Label 'must be less than %1';
        ManualAmount: Boolean;
        Text14700: Label 'You cannot cancel payment order export because the payment order relates to import bank statement %1.';
        Text17300: Label 'You must not specify %1 for ';
        AccTypeNotSupportedErr: Label 'You cannot specify a deferral code for this type of account.';
        SalespersonPurchPrivacyBlockErr: Label 'Privacy Blocked must not be true for Salesperson / Purchaser %1.', Comment = '%1 = salesperson / purchaser code.';
        BlockedErr: Label 'The Blocked field must not be %1 for %2 %3.', Comment = '%1=Blocked field value,%2=Account Type,%3=Account No.';

    procedure EmptyLine() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeEmptyLine(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(
          ("Account No." = '') and (Amount = 0) and
          (("Bal. Account No." = '') or not "System-Created Entry"));
    end;

    local procedure BlankJobNo(CurrentFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlankJobNo(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Job No.", '');
    end;

    procedure UpdateLineBalance()
    var
        VATAllocation: Record "VAT Allocation Line";
    begin
        "Debit Amount" := 0;
        "Credit Amount" := 0;

        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then
            "Debit Amount" := Amount
        else
            if Amount <> 0 then
                "Credit Amount" := -Amount;

        if "Currency Code" = '' then
            "Amount (LCY)" := Amount;
        if (("Amount (LCY)" > 0) and (not Correction)) or
           (("Amount (LCY)" < 0) and Correction)
        then begin
            "Debit Amount (LCY)" := "Amount (LCY)";
            "Credit Amount (LCY)" := 0
        end else begin
            "Debit Amount (LCY)" := 0;
            "Credit Amount (LCY)" := -"Amount (LCY)";
        end;
        case true of
            ("Account No." <> '') and ("Bal. Account No." <> ''):
                "Balance (LCY)" := 0;
            "Bal. Account No." <> '':
                "Balance (LCY)" := -"Amount (LCY)";
            else
                if "VAT Settlement Part" <> 0 then
                    "Balance (LCY)" := "VAT Amount (LCY)"
                else
                    "Balance (LCY)" := "Amount (LCY)";
        end;

        OnUpdateLineBalanceOnAfterAssignBalanceLCY("Balance (LCY)");

        Clear(GenJnlAlloc);
        GenJnlAlloc.UpdateAllocations(Rec);
        VATAllocation.UpdateAllocations(Rec, ManualAmount);
        ManualAmount := false;

        UpdateSalesPurchLCY;

        if ("Deferral Code" <> '') and (Amount <> xRec.Amount) and ((Amount <> 0) and (xRec.Amount <> 0)) then
            Validate("Deferral Code");
    end;

    procedure SetUpNewLine(LastGenJnlLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    begin
        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJnlLine.FindFirst then begin
            "Posting Date" := LastGenJnlLine."Posting Date";
            "Document Date" := LastGenJnlLine."Posting Date";
            "Document No." := LastGenJnlLine."Document No.";
            OnSetUpNewLineOnBeforeIncrDocNo(GenJnlLine, LastGenJnlLine);
            if BottomLine and
               (Balance - LastGenJnlLine."Balance (LCY)" = 0) and
               not LastGenJnlLine.EmptyLine
            then
                IncrementDocumentNo(GenJnlBatch, "Document No.");
        end else begin
            "Posting Date" := WorkDate;
            "Document Date" := WorkDate;
            if GenJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series", "Posting Date");
            end;
        end;
        if GenJnlTemplate.Recurring then
            "Recurring Method" := LastGenJnlLine."Recurring Method";
        case GenJnlTemplate.Type of
            GenJnlTemplate.Type::Payments:
                begin
                    "Account Type" := "Account Type"::Vendor;
                    "Document Type" := "Document Type"::Payment;
                end;
            else begin
                    "Account Type" := LastGenJnlLine."Account Type";
                    "Document Type" := LastGenJnlLine."Document Type";
                end;
        end;
        "Source Code" := GenJnlTemplate."Source Code";
        "Reason Code" := GenJnlBatch."Reason Code";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";
        "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
        if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
           ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
        then
            "Account Type" := "Account Type"::"G/L Account";
        Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
        Description := '';
        if GenJnlBatch."Suggest Balancing Amount" then
            SuggestBalancingAmount(LastGenJnlLine, BottomLine);

        UpdateJournalBatchID;

        OnAfterSetupNewLine(Rec, GenJnlTemplate, GenJnlBatch, LastGenJnlLine, Balance, BottomLine);
    end;

    procedure InitNewLine(PostingDate: Date; DocumentDate: Date; PostingDescription: Text[100]; ShortcutDim1Code: Code[20]; ShortcutDim2Code: Code[20]; DimSetID: Integer; ReasonCode: Code[10])
    begin
        Init;
        "Posting Date" := PostingDate;
        "Document Date" := DocumentDate;
        Description := PostingDescription;
        "Shortcut Dimension 1 Code" := ShortcutDim1Code;
        "Shortcut Dimension 2 Code" := ShortcutDim2Code;
        "Dimension Set ID" := DimSetID;
        "Reason Code" := ReasonCode;
        OnAfterInitNewLine(Rec);
    end;

    procedure CheckDocNoOnLines()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LastDocNo: Code[20];
    begin
        GenJnlLine.CopyFilters(Rec);

        if not GenJnlLine.FindSet then
            exit;
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."No. Series" = '' then
            exit;

        Clear(NoSeriesMgt);
        repeat
            GenJnlLine.CheckDocNoBasedOnNoSeries(LastDocNo, GenJnlBatch."No. Series", NoSeriesMgt);
            LastDocNo := GenJnlLine."Document No.";
        until GenJnlLine.Next = 0;
    end;

    procedure CheckDocNoBasedOnNoSeries(LastDocNo: Code[20]; NoSeriesCode: Code[20]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocNoBasedOnNoSeries(Rec, LastDocNo, NoSeriesCode, NoSeriesMgtInstance, IsHandled);
        if IsHandled then
            exit;

        if NoSeriesCode = '' then
            exit;

        if (LastDocNo = '') or ("Document No." <> LastDocNo) then
            if "Document No." <> NoSeriesMgtInstance.GetNextNo(NoSeriesCode, "Posting Date", false) then
                NoSeriesMgtInstance.TestManualWithDocumentNo(NoSeriesCode, "Document No.");  // allow use of manual document numbers.
    end;

    procedure RenumberDocumentNo()
    var
        GenJnlLine2: Record "Gen. Journal Line";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if GuiAllowed() and not DIALOG.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true) then
            exit;
        TestField("Check Printed", false);

        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if GenJnlBatch."No. Series" = '' then
            exit;
        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        Clear(NoSeriesMgt);
        FirstDocNo := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := 'RENUMBERED-000000001';
        // step1 - renumber to non-existing document number
        DocNo := FirstTempDocNo;
        GenJnlLine2 := Rec;
        GenJnlLine2.Reset();
        RenumberDocNoOnLines(DocNo, GenJnlLine2);
        LastTempDocNo := DocNo;

        // step2 - renumber to real document number (within Filter)
        DocNo := FirstDocNo;
        GenJnlLine2.CopyFilters(Rec);
        GenJnlLine2 := Rec;
        RenumberDocNoOnLines(DocNo, GenJnlLine2);

        // step3 - renumber to real document number (outside filter)
        DocNo := IncStr(DocNo);
        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Document No.", FirstTempDocNo, LastTempDocNo);
        RenumberDocNoOnLines(DocNo, GenJnlLine2);

        Get("Journal Template Name", "Journal Batch Name", "Line No.");
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line")
    var
        LastGenJnlLine: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        PrevDocNo: Code[20];
        FirstDocNo: Code[20];
        First: Boolean;
    begin
        FirstDocNo := DocNo;
        with GenJnlLine2 do begin
            SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.");
            SetRange("Journal Template Name", "Journal Template Name");
            SetRange("Journal Batch Name", "Journal Batch Name");
            LastGenJnlLine.Init();
            First := true;
            if FindSet then begin
                repeat
                    if "Document No." = FirstDocNo then
                        exit;
                    if not First and (("Document No." <> PrevDocNo) or ("Bal. Account No." <> '')) and not LastGenJnlLine.EmptyLine then
                        DocNo := IncStr(DocNo);
                    PrevDocNo := "Document No.";
                    if "Document No." <> '' then begin
                        if "Applies-to ID" = "Document No." then
                            RenumberAppliesToID(GenJnlLine2, "Document No.", DocNo);
                        RenumberAppliesToDocNo(GenJnlLine2, "Document No.", DocNo);
                    end;
                    GenJnlLine3.Get("Journal Template Name", "Journal Batch Name", "Line No.");
                    CheckJobQueueStatus(GenJnlLine3);
                    GenJnlLine3."Document No." := DocNo;
                    GenJnlLine3.Modify();
                    First := false;
                    LastGenJnlLine := GenJnlLine2
                until Next = 0
            end
        end
    end;

    local procedure RenumberAppliesToID(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AccType: Option;
        AccNo: Code[20];
    begin
        GetAccTypeAndNo(GenJnlLine2, AccType, AccNo);
        case AccType of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetRange("Customer No.", AccNo);
                    CustLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    if CustLedgEntry.FindSet then
                        repeat
                            CustLedgEntry2.Get(CustLedgEntry."Entry No.");
                            CustLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry2);
                        until CustLedgEntry.Next = 0;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetRange("Vendor No.", AccNo);
                    VendLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    if VendLedgEntry.FindSet then
                        repeat
                            VendLedgEntry2.Get(VendLedgEntry."Entry No.");
                            VendLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry2);
                        until VendLedgEntry.Next = 0;
                end;
            else
                exit
        end;
        GenJnlLine2."Applies-to ID" := NewAppliesToID;
        GenJnlLine2.Modify();
    end;

    local procedure RenumberAppliesToDocNo(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToDocNo: Code[20]; NewAppliesToDocNo: Code[20])
    begin
        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlLine2.SetRange("Applies-to Doc. Type", GenJnlLine2."Document Type");
        GenJnlLine2.SetRange("Applies-to Doc. No.", OriginalAppliesToDocNo);
        GenJnlLine2.ModifyAll("Applies-to Doc. No.", NewAppliesToDocNo);
    end;

    local procedure CheckVATInAlloc()
    begin
        if "Gen. Posting Type" <> 0 then begin
            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            if GenJnlAlloc.FindSet then
                repeat
                    GenJnlAlloc.CheckVAT(Rec);
                until GenJnlAlloc.Next = 0;
        end;
    end;

    local procedure SetCurrencyCode(AccType2: Option "G/L Account",Customer,Vendor,"Bank Account"; AccNo2: Code[20]): Boolean
    var
        BankAcc: Record "Bank Account";
    begin
        "Currency Code" := '';
        if AccNo2 <> '' then
            if AccType2 = AccType2::"Bank Account" then
                if BankAcc.Get(AccNo2) then
                    "Currency Code" := BankAcc."Currency Code";
        exit("Currency Code" <> '');
    end;

    procedure SetCurrencyFactor(CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    begin
        "Currency Code" := CurrencyCode;
        if "Currency Code" = '' then
            "Currency Factor" := 1
        else
            "Currency Factor" := CurrencyFactor;
    end;

    local procedure GetCurrency()
    begin
        if "Additional-Currency Posting" =
           "Additional-Currency Posting"::"Additional-Currency Amount Only"
        then begin
            if GLSetup."Additional Reporting Currency" = '' then
                ReadGLSetup;
            CurrencyCode := GLSetup."Additional Reporting Currency";
        end else
            CurrencyCode := "Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    procedure UpdateSource()
    var
        SourceExists1: Boolean;
        SourceExists2: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSource(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceExists1 := ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '');
        SourceExists2 := ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '');
        case true of
            SourceExists1 and not SourceExists2:
                begin
                    "Source Type" := "Account Type".AsInteger();
                    "Source No." := "Account No.";
                end;
            SourceExists2 and not SourceExists1:
                begin
                    "Source Type" := "Bal. Account Type".AsInteger();
                    "Source No." := "Bal. Account No.";
                end;
            else begin
                    "Source Type" := "Source Type"::" ";
                    "Source No." := '';
                end;
        end;

        OnAfterUpdateSource(Rec, CurrFieldNo);
    end;

    local procedure CheckGLAcc(GLAcc: Record "G/L Account")
    begin
        GLAcc.CheckGLAcc;
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') or "System-Created Entry" then
            exit;
        if "Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                exit;

        CheckDirectPosting(GLAcc);
    end;

    local procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"; AccountNo: Code[20])
    var
        ICPartner: Record "IC Partner";
    begin
        if ICPartnerCode <> '' then begin
            if GenJnlTemplate.Get("Journal Template Name") then;
            if (ICPartnerCode <> '') and ICPartner.Get(ICPartnerCode) then begin
                ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
                "IC Partner Code" := ICPartnerCode;
            end;
        end;
    end;

    local procedure CheckDirectPosting(var GLAccount: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDirectPosting(GLAccount, IsHandled, Rec);
        if IsHandled then
            exit;

        GLAccount.TestField("Direct Posting", true);

        OnAfterCheckDirectPosting(GLAccount, Rec);
    end;

    procedure GetFAAddCurrExchRate()
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FANo: Code[20];
        UseFAAddCurrExchRate: Boolean;
    begin
        "FA Add.-Currency Factor" := 0;
        if ("FA Posting Type" <> "FA Posting Type"::" ") and
           ("Depreciation Book Code" <> '')
        then begin
            if "Account Type" = "Account Type"::"Fixed Asset" then
                FANo := "Account No.";
            if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then
                FANo := "Bal. Account No.";
            if FANo <> '' then begin
                DeprBook.Get("Depreciation Book Code");
                case "FA Posting Type" of
                    "FA Posting Type"::"Acquisition Cost":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate - Acq. Cost";
                    "FA Posting Type"::Depreciation:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Depr.";
                    "FA Posting Type"::"Write-Down":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr Exch Rate -Write-Down";
                    "FA Posting Type"::Appreciation:
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch. Rate - Apprec.";
                    "FA Posting Type"::"Custom 1":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 1";
                    "FA Posting Type"::"Custom 2":
                        UseFAAddCurrExchRate := DeprBook."Add-Curr. Exch Rate - Custom 2";
                    "FA Posting Type"::Disposal:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Disp.";
                    "FA Posting Type"::Maintenance:
                        UseFAAddCurrExchRate := DeprBook."Add.-Curr. Exch. Rate - Maint.";
                end;
                if UseFAAddCurrExchRate then begin
                    FADeprBook.Get(FANo, "Depreciation Book Code");
                    FADeprBook.TestField("FA Add.-Currency Factor");
                    "FA Add.-Currency Factor" := FADeprBook."FA Add.-Currency Factor";
                end;
            end;
        end;
    end;

    procedure GetShowCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(Text009);
    end;

    local procedure GetVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            VATPostingSetup.Init();
        OnAfterGetVATPostingSetup(VATPostingSetup);
    end;

    procedure ClearCustVendApplnEntry()
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearCustApplnEntryFields;
                        TempCustLedgEntry.DeleteAll();
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearCustApplnEntryFields;
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
            AccType::Vendor:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearVendApplnEntryFields;
                        TempVendLedgEntry.DeleteAll();
                        VendEntrySetApplID.SetApplId(VendLedgEntry, TempVendLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearVendApplnEntryFields;
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
        end;

        OnAfterClearCustVendApplnEntry(Rec, xRec, AccType, AccNo);
    end;

    local procedure ClearCustApplnEntryFields()
    begin
        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        CustLedgEntry."Amount to Apply" := 0;

        OnAfterClearCustApplnEntryFields(CustLedgEntry);
    end;

    local procedure ClearVendApplnEntryFields()
    begin
        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        VendLedgEntry."Amount to Apply" := 0;

        OnAfterClearVendApplnEntryFields(VendLedgEntry);
    end;

    procedure CheckFixedCurrency(): Boolean
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Posting Date");

        if not CurrExchRate.FindLast then
            exit(false);

        if CurrExchRate."Relational Currency Code" = '' then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        if CurrExchRate."Fix Exchange Rate Amount" <>
           CurrExchRate."Fix Exchange Rate Amount"::Both
        then
            exit(false);

        CurrExchRate.SetRange("Currency Code", CurrExchRate."Relational Currency Code");
        if CurrExchRate.FindLast then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        exit(false);
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

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        TestField("Check Printed", false);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure ValidateAmount(ShouldCheckPaymentTolerance: Boolean)
    begin
        GetCurrency;
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount
        else
            "Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor"));
        OnValidateAmountOnAfterAssignAmountLCY("Amount (LCY)");

        Amount := Round(Amount, Currency."Amount Rounding Precision");
        if (CurrFieldNo <> 0) and
           (CurrFieldNo <> FieldNo("Applies-to Doc. No.")) and
           ((("Account Type" = "Account Type"::Customer) and
             ("Account No." <> '') and (Amount > 0) and
             (CurrFieldNo <> FieldNo("Bal. Account No."))) or
            (("Bal. Account Type" = "Bal. Account Type"::Customer) and
             ("Bal. Account No." <> '') and (Amount < 0) and
             (CurrFieldNo <> FieldNo("Account No."))))
        then
            CustCheckCreditLimit.GenJnlLineCheck(Rec);

        Validate("VAT %");
        Validate("Bal. VAT %");
        UpdateLineBalance;
        if "Deferral Code" <> '' then
            Validate("Deferral Code");

        if Amount <> xRec.Amount then begin
            if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then
                SetApplyToAmount;
            if ShouldCheckPaymentTolerance then
                if (xRec.Amount <> 0) or (xRec."Applies-to Doc. No." <> '') or (xRec."Applies-to ID" <> '') then
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);
        end;

        if JobTaskIsSet then begin
            CreateTempJobJnlLine();
            UpdatePricesFromJobJnlLine();
        end;
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        TestField("Check Printed", false);
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
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure GetFAVATSetup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FABalAcc: Boolean;
    begin
        if CurrFieldNo = 0 then
            exit;
        if ("Account Type" <> "Account Type"::"Fixed Asset") and
           ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
        then
            exit;
        FABalAcc := ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset");
        if not FABalAcc then begin
            ClearPostingGroups;
            "Tax Group Code" := '';
            Validate("VAT Prod. Posting Group");
        end;
        if FABalAcc then begin
            ClearBalancePostingGroups;
            "Bal. Tax Group Code" := '';
            Validate("Bal. VAT Prod. Posting Group");
        end;
        if CopyVATSetupToJnlLines then
            if (("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") or
                ("FA Posting Type" = "FA Posting Type"::Disposal) or
                ("FA Posting Type" = "FA Posting Type"::Maintenance)) and
               ("Posting Group" <> '')
            then
                if FAPostingGr.Get("Posting Group") then begin
                    case "FA Posting Type" of
                        "FA Posting Type"::"Acquisition Cost":
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccount);
                        "FA Posting Type"::Disposal:
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccountOnDisposal);
                        "FA Posting Type"::Maintenance:
                            LocalGLAcc.Get(FAPostingGr.GetMaintenanceExpenseAccount);
                    end;
                    OnGetFAVATSetupOnBeforeCheckGLAcc(Rec, LocalGLAcc);
                    LocalGLAcc.CheckGLAcc;
                    if not FABalAcc then begin
                        "Gen. Posting Type" := LocalGLAcc."Gen. Posting Type";
                        "Gen. Bus. Posting Group" := LocalGLAcc."Gen. Bus. Posting Group";
                        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
                        "VAT Bus. Posting Group" := LocalGLAcc."VAT Bus. Posting Group";
                        "VAT Prod. Posting Group" := LocalGLAcc."VAT Prod. Posting Group";
                        "Tax Group Code" := LocalGLAcc."Tax Group Code";
                        Validate("VAT Prod. Posting Group");
                    end else begin
                        ;
                        "Bal. Gen. Posting Type" := LocalGLAcc."Gen. Posting Type";
                        "Bal. Gen. Bus. Posting Group" := LocalGLAcc."Gen. Bus. Posting Group";
                        "Bal. Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
                        "Bal. VAT Bus. Posting Group" := LocalGLAcc."VAT Bus. Posting Group";
                        "Bal. VAT Prod. Posting Group" := LocalGLAcc."VAT Prod. Posting Group";
                        "Bal. Tax Group Code" := LocalGLAcc."Tax Group Code";
                        Validate("Bal. VAT Prod. Posting Group");
                    end;
                end;
    end;

    local procedure GetFADeprBook(FANo: Code[20])
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        DefaultFADeprBook: Record "FA Depreciation Book";
    begin
        if "Depreciation Book Code" = '' then begin
            FASetup.Get();

            DefaultFADeprBook.SetRange("FA No.", FANo);
            DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

            case true of
                DefaultFADeprBook.FindFirst:
                    "Depreciation Book Code" := DefaultFADeprBook."Depreciation Book Code";
                FADeprBook.Get(FANo, FASetup."Default Depr. Book"):
                    "Depreciation Book Code" := FASetup."Default Depr. Book";
                else
                    "Depreciation Book Code" := '';
            end;
        end;

        if "Depreciation Book Code" <> '' then begin
            FADeprBook.Get(FANo, "Depreciation Book Code");
            "Posting Group" := FADeprBook."FA Posting Group";
        end;
    end;

    procedure GetTemplate()
    begin
        if not TemplateFound then
            GenJnlTemplate.Get("Journal Template Name");
        TemplateFound := true;
    end;

    local procedure UpdateSalesPurchLCY()
    begin
        "Sales/Purch. (LCY)" := 0;
        if (not "System-Created Entry") and ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) then begin
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and
               (("Bal. Account No." <> '') or ("Recurring Method" <> "Recurring Method"::" "))
            then
                "Sales/Purch. (LCY)" := "Amount (LCY)" + "Bal. VAT Amount (LCY)";
            if ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) and ("Account No." <> '') then
                "Sales/Purch. (LCY)" := -("Amount (LCY)" - "VAT Amount (LCY)");
        end;
    end;

    procedure LookUpAppliesToDocCust(AccNo: Code[20])
    var
        ApplyCustEntries: Page "Apply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocCust(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(CustLedgEntry);
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if CustLedgEntry.IsEmpty then begin
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if CustLedgEntry.IsEmpty then
                CustLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if CustLedgEntry.IsEmpty then
                CustLedgEntry.SetRange("Document Type");
        end;
        if Amount <> 0 then begin
            CustLedgEntry.SetRange(Positive, Amount < 0);
            if CustLedgEntry.IsEmpty then
                CustLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocCustOnAfterSetFilters(CustLedgEntry, Rec);

        ApplyCustEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
            ApplyCustEntries.GetRecord(CustLedgEntry);
            if AccNo = '' then begin
                AccNo := CustLedgEntry."Customer No.";
                if "Bal. Account Type" = "Bal. Account Type"::Customer then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithCustLedgEntry;
            UpdateDocumentTypeAndAppliesTo(CustLedgEntry."Document Type", CustLedgEntry."Document No.");
            OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(Rec, CustLedgEntry);
        end;
    end;

    procedure LookUpAppliesToDocVend(AccNo: Code[20])
    var
        ApplyVendEntries: Page "Apply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocVend(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(VendLedgEntry);
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.IsEmpty then begin
                VendLedgEntry.SetRange("Document Type");
                VendLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if VendLedgEntry.IsEmpty then
                VendLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if VendLedgEntry.IsEmpty then
                VendLedgEntry.SetRange("Document Type");
        end;
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.IsEmpty then
                VendLedgEntry.SetRange("Document No.");
        end;
        if Amount <> 0 then begin
            VendLedgEntry.SetRange(Positive, Amount < 0);
            if VendLedgEntry.IsEmpty then;
            VendLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocVendOnAfterSetFilters(VendLedgEntry, Rec);

        ApplyVendEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        if ApplyVendEntries.RunModal = ACTION::LookupOK then begin
            ApplyVendEntries.GetRecord(VendLedgEntry);
            if AccNo = '' then begin
                AccNo := VendLedgEntry."Vendor No.";
                if "Bal. Account Type" = "Bal. Account Type"::Vendor then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithVendLedgEntry;
            UpdateDocumentTypeAndAppliesTo(VendLedgEntry."Document Type", VendLedgEntry."Document No.");
            OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(Rec, VendLedgEntry);
        end;
    end;

    procedure SetApplyToAmount()
    begin
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindFirst then
                        if CustLedgEntry."Amount to Apply" = 0 then begin
                            CustLedgEntry.CalcFields("Remaining Amount");
                            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Document No.");
                    VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindFirst then
                        if VendLedgEntry."Amount to Apply" = 0 then begin
                            VendLedgEntry.CalcFields("Remaining Amount");
                            VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
                end;
        end;
    end;

    procedure ValidateApplyRequirements(TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        IsHandled: Boolean;
    begin
        if (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) or
           (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor)
        then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

        OnBeforeValidateApplyRequirements(TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        case TempGenJnlLine."Account Type" of
            TempGenJnlLine."Account Type"::Customer:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
                    CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                    CustLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindSet then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.");
                        until CustLedgEntry.Next = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        CustLedgEntry.SetCurrentKey("Document No.");
                        CustLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            CustLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                        CustLedgEntry.SetRange(Open, true);
                        if CustLedgEntry.FindFirst then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.");
                    end;
            TempGenJnlLine."Account Type"::Vendor:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
                    VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                    VendLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindSet then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.");
                        until VendLedgEntry.Next = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgEntry.SetCurrentKey("Document No.");
                        VendLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            VendLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                        VendLedgEntry.SetRange(Open, true);
                        if VendLedgEntry.FindFirst then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.");
                    end;
        end;

        OnAfterValidateApplyRequirements(TempGenJnlLine);
    end;

    local procedure UpdateCountryCodeAndVATRegNo(No: Code[20])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        OnBeforeUpdateCountryCodeAndVATRegNo(Rec, xRec);

        if No = '' then begin
            "Country/Region Code" := '';
            "VAT Registration No." := '';
            exit;
        end;

        ReadGLSetup;
        case true of
            ("Account Type" = "Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Customer):
                begin
                    Cust.Get(No);
                    "Country/Region Code" := Cust."Country/Region Code";
                    "VAT Registration No." := Cust."VAT Registration No.";
                end;
            ("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor):
                begin
                    Vend.Get(No);
                    "Country/Region Code" := Vend."Country/Region Code";
                    "VAT Registration No." := Vend."VAT Registration No.";
                end;
        end;

        OnAfterUpdateCountryCodeAndVATRegNo(Rec, xRec);
    end;

    procedure JobTaskIsSet() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobTaskIsSet(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(("Job No." <> '') and ("Job Task No." <> '') and ("Account Type" = "Account Type"::"G/L Account"));
    end;

    procedure CreateTempJobJnlLine()
    var
        TmpJobJnlOverallCurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField("Posting Date");
        Clear(TempJobJnlLine);
        TempJobJnlLine.DontCheckStdCost;
        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        if CurrFieldNo <> FieldNo("Posting Date") then
            TempJobJnlLine.Validate("Posting Date", "Posting Date")
        else
            TempJobJnlLine.Validate("Posting Date", xRec."Posting Date");
        TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::"G/L Account");
        if "Job Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := "Posting Date";

            if "Currency Code" = "Job Currency Code" then
                "Job Currency Factor" := "Currency Factor"
            else
                "Job Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Job Currency Code");
            TempJobJnlLine.SetCurrencyFactor("Job Currency Factor");
        end;
        TempJobJnlLine.Validate("No.", "Account No.");
        TempJobJnlLine.Validate(Quantity, "Job Quantity");

        if "Currency Factor" = 0 then begin
            if "Job Currency Factor" = 0 then
                TmpJobJnlOverallCurrencyFactor := 1
            else
                TmpJobJnlOverallCurrencyFactor := "Job Currency Factor";
        end else begin
            if "Job Currency Factor" = 0 then
                TmpJobJnlOverallCurrencyFactor := 1 / "Currency Factor"
            else
                TmpJobJnlOverallCurrencyFactor := "Job Currency Factor" / "Currency Factor"
        end;

        if "Job Quantity" <> 0 then
            TempJobJnlLine.Validate("Unit Cost", ((Amount - "VAT Amount") * TmpJobJnlOverallCurrencyFactor) / "Job Quantity");

        if (xRec."Account No." = "Account No.") and (xRec."Job Task No." = "Job Task No.") and ("Job Unit Price" <> 0) then begin
            if TempJobJnlLine."Cost Factor" = 0 then
                TempJobJnlLine."Unit Price" := xRec."Job Unit Price";
            TempJobJnlLine."Line Amount" := xRec."Job Line Amount";
            TempJobJnlLine."Line Discount %" := xRec."Job Line Discount %";
            TempJobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
            TempJobJnlLine.Validate("Unit Price");
        end;

        OnAfterCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, CurrFieldNo);
    end;

    procedure UpdatePricesFromJobJnlLine()
    begin
        "Job Unit Price" := TempJobJnlLine."Unit Price";
        "Job Total Price" := TempJobJnlLine."Total Price";
        "Job Line Amount" := TempJobJnlLine."Line Amount";
        "Job Line Discount Amount" := TempJobJnlLine."Line Discount Amount";
        "Job Unit Cost" := TempJobJnlLine."Unit Cost";
        "Job Total Cost" := TempJobJnlLine."Total Cost";
        "Job Line Discount %" := TempJobJnlLine."Line Discount %";

        "Job Unit Price (LCY)" := TempJobJnlLine."Unit Price (LCY)";
        "Job Total Price (LCY)" := TempJobJnlLine."Total Price (LCY)";
        "Job Line Amount (LCY)" := TempJobJnlLine."Line Amount (LCY)";
        "Job Line Disc. Amount (LCY)" := TempJobJnlLine."Line Discount Amount (LCY)";
        "Job Unit Cost (LCY)" := TempJobJnlLine."Unit Cost (LCY)";
        "Job Total Cost (LCY)" := TempJobJnlLine."Total Cost (LCY)";

        OnAfterUpdatePricesFromJobJnlLine(Rec, TempJobJnlLine);
    end;

    procedure SetHideValidation(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
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

    procedure IsApplied(): Boolean
    begin
        if "Applies-to Doc. No." <> '' then
            exit(true);
        if "Applies-to ID" <> '' then
            exit(true);
        exit(false);
    end;

    procedure DataCaption(): Text[250]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if GenJnlBatch.Get("Journal Template Name", "Journal Batch Name") then
            exit(GenJnlBatch.Name + '-' + GenJnlBatch.Description);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    procedure GetCustLedgerEntry()
    begin
        if ("Account Type" = "Account Type"::Customer) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '') and (Amount = 0)
        then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            CustLedgEntry.SetRange(Open, true);
            if not CustLedgEntry.FindFirst then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", CustLedgEntry."Customer No.");
            OnGetCustLedgerEntryOnAfterAssignCustomerNo(Rec, CustLedgEntry);

            CustLedgEntry.CalcFields("Remaining Amount");

            if "Posting Date" <= CustLedgEntry."Pmt. Discount Date" then
                Amount := -(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible")
            else
                Amount := -CustLedgEntry."Remaining Amount";

            if "Currency Code" <> CustLedgEntry."Currency Code" then
                UpdateCurrencyCode(CustLedgEntry."Currency Code");

            SetAppliesToFields(
              CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry."External Document No.");

            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if GenJnlBatch."Bal. Account No." <> '' then begin
                "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
            end else
                Validate(Amount);

            OnAfterGetCustLedgerEntry(Rec, CustLedgEntry);
        end;
    end;

    procedure GetVendLedgerEntry()
    begin
        if ("Account Type" = "Account Type"::Vendor) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '') and (Amount = 0)
        then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            VendLedgEntry.SetRange(Open, true);
            if not VendLedgEntry.FindFirst then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", VendLedgEntry."Vendor No.");
            OnGetVendLedgerEntryOnAfterAssignVendorNo(Rec, VendLedgEntry);

            VendLedgEntry.CalcFields("Remaining Amount");

            if "Posting Date" <= VendLedgEntry."Pmt. Discount Date" then
                Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible")
            else
                Amount := -VendLedgEntry."Remaining Amount";

            if "Currency Code" <> VendLedgEntry."Currency Code" then
                UpdateCurrencyCode(VendLedgEntry."Currency Code");

            SetAppliesToFields(
              VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry."External Document No.");

            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            if GenJnlBatch."Bal. Account No." <> '' then begin
                "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
            end else
                Validate(Amount);

            OnAfterGetVendLedgerEntry(Rec, VendLedgEntry);
        end;
    end;

    local procedure UpdateCurrencyCode(NewCurrencyCode: Code[10])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        FromCurrencyCode: Code[10];
        ToCurrencyCode: Code[10];
    begin
        FromCurrencyCode := GetShowCurrencyCode("Currency Code");
        ToCurrencyCode := GetShowCurrencyCode(NewCurrencyCode);
        if not ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(ChangeCurrencyQst, FromCurrencyCode, ToCurrencyCode), true)
        then
            Error(UpdateInterruptedErr);
        Validate("Currency Code", NewCurrencyCode);
    end;

    local procedure ValidateCurrencyCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCurrencyCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("Currency Code");
    end;

    local procedure SetAppliesToFields(DocType: Option; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
        UpdateDocumentTypeAndAppliesTo(DocType, DocNo);

        if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice) and
           ("Document Type" = "Document Type"::Payment)
        then
            "Applies-to Ext. Doc. No." := ExtDocNo;
    end;

    local procedure CustVendAccountNosModified(): Boolean
    begin
        exit(
          (("Bal. Account No." <> xRec."Bal. Account No.") and
           ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor])) or
          (("Account No." <> xRec."Account No.") and
           ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor])))
    end;

    local procedure CheckPaymentTolerance()
    begin
        if Amount <> 0 then
            if ("Bal. Account No." <> xRec."Bal. Account No.") or ("Account No." <> xRec."Account No.") then
                PaymentToleranceMgt.PmtTolGenJnl(Rec);
    end;

    procedure IncludeVATAmount(): Boolean
    begin
        exit(
          ("VAT Posting" = "VAT Posting"::"Manual VAT Entry") and
          ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT"));
    end;

    procedure ConvertAmtFCYToLCYForSourceCurrency(Amount: Decimal): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        if (Amount = 0) or ("Source Currency Code" = '') then
            exit(Amount);

        Currency.Get("Source Currency Code");
        CurrencyFactor := CurrExchRate.ExchangeRate("Posting Date", "Source Currency Code");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              "Posting Date", "Source Currency Code", Amount, CurrencyFactor),
            Currency."Amount Rounding Precision"));
    end;

    procedure MatchSingleLedgerEntry()
    begin
        CODEUNIT.Run(CODEUNIT::"Match General Journal Lines", Rec);
    end;

    procedure GetStyle(): Text
    begin
        if "Applied Automatically" then
            exit('Favorable')
    end;

    procedure GetOverdueDateInteractions(var OverdueWarningText: Text): Text
    var
        DueDate: Date;
    begin
        DueDate := GetAppliesToDocDueDate;
        OverdueWarningText := '';
        if (DueDate <> 0D) and (DueDate < "Posting Date") then begin
            OverdueWarningText := DueDateMsg;
            exit('Unfavorable');
        end;
        exit('');
    end;

    procedure ClearDataExchangeEntries(DeleteHeaderEntries: Boolean)
    var
        DataExchField: Record "Data Exch. Field";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if "Data Exch. Entry No." = 0 then
            exit;

        DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", "Data Exch. Line No.");

        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetRange("Data Exch. Entry No.", "Data Exch. Entry No.");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        if GenJournalLine.IsEmpty or DeleteHeaderEntries then
            DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", 0);
    end;

    procedure ClearAppliedGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if "Applies-to Doc. No." = '' then
            exit;
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        GenJournalLine.SetRange("Document Type", "Applies-to Doc. Type");
        GenJournalLine.SetRange("Document No.", "Applies-to Doc. No.");
        if not GenJournalLine.IsEmpty then begin
            GenJournalLine.ModifyAll("Applied Automatically", false);
            GenJournalLine.ModifyAll("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.ModifyAll("Account No.", '');
        end;
    end;

    procedure GetIncomingDocumentURL(): Text[1024]
    var
        IncomingDocument: Record "Incoming Document";
    begin
        if "Incoming Document Entry No." = 0 then
            exit('');

        IncomingDocument.Get("Incoming Document Entry No.");
        exit(IncomingDocument.GetURL);
    end;

    procedure InsertPaymentFileError(Text: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.CreateNew(Rec, Text, '', '');
    end;

    procedure InsertPaymentFileErrorWithDetails(ErrorText: Text; AddnlInfo: Text; ExtSupportInfo: Text)
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.CreateNew(Rec, ErrorText, AddnlInfo, ExtSupportInfo);
    end;

    procedure DeletePaymentFileBatchErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlBatchErrors(Rec);
    end;

    procedure DeletePaymentFileErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlLineErrors(Rec);
    end;

    procedure HasPaymentFileErrors(): Boolean
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        exit(PaymentJnlExportErrorText.JnlLineHasErrors(Rec));
    end;

    procedure HasPaymentFileErrorsInBatch(): Boolean
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        exit(PaymentJnlExportErrorText.JnlBatchHasErrors(Rec));
    end;

    local procedure UpdateDescription(Name: Text[100])
    begin
        if not IsAdHocDescription then
            Description := Name;
    end;

    local procedure IsAdHocDescription(): Boolean
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        FixedAsset: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
    begin
        if Description = '' then
            exit(false);
        if xRec."Account No." = '' then
            exit(true);

        case xRec."Account Type" of
            xRec."Account Type"::"G/L Account":
                exit(GLAccount.Get(xRec."Account No.") and (GLAccount.Name <> Description));
            xRec."Account Type"::Customer:
                exit(Customer.Get(xRec."Account No.") and (Customer.Name <> Description));
            xRec."Account Type"::Vendor:
                exit(Vendor.Get(xRec."Account No.") and (Vendor.Name <> Description));
            xRec."Account Type"::"Bank Account":
                exit(BankAccount.Get(xRec."Account No.") and (BankAccount.Name <> Description));
            xRec."Account Type"::"Fixed Asset":
                exit(FixedAsset.Get(xRec."Account No.") and (FixedAsset.Description <> Description));
            xRec."Account Type"::"IC Partner":
                exit(ICPartner.Get(xRec."Account No.") and (ICPartner.Name <> Description));
        end;
        exit(false);
    end;

    procedure GetAppliesToDocEntryNo(): Integer
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        AccNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgEntry, AccNo);
                    exit(CustLedgEntry."Entry No.");
                end;
            AccType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendLedgEntry, AccNo);
                    exit(VendLedgEntry."Entry No.");
                end;
        end;
    end;

    procedure GetAppliesToDocDueDate(): Date
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        AccNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgEntry, AccNo);
                    exit(CustLedgEntry."Due Date");
                end;
            AccType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendLedgEntry, AccNo);
                    exit(VendLedgEntry."Due Date");
                end;
        end;
    end;

    local procedure GetAppliesToDocCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20])
    begin
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if CustLedgEntry.FindFirst then;
        end else
            if "Applies-to ID" <> '' then begin
                CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if CustLedgEntry.FindFirst then;
            end;
    end;

    local procedure GetAppliesToDocVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; AccNo: Code[20])
    begin
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.FindFirst then;
        end else
            if "Applies-to ID" <> '' then begin
                VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if VendLedgEntry.FindFirst then;
            end;
    end;


    [Scope('OnPrem')]
    procedure SetJournalLineFieldsFromApplication()
    var
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        AccNo: Code[20];
    begin
        "Exported to Payment File" := false;
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if "Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(Rec, CustLedgEntry);
                        CustLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := CustLedgEntry.FindFirst;
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            "Exported to Payment File" := CustLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := CustLedgEntry."External Document No.";
                        end;
            AccType::Vendor:
                if "Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(Rec, VendLedgEntry);
                        VendLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := VendLedgEntry.FindFirst;
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := VendLedgEntry."External Document No.";
                        end;
        end;

        OnAfterSetJournalLineFieldsFromApplication(Rec, AccType, AccNo, xRec);
    end;

    local procedure GetAccTypeAndNo(GenJnlLine2: Record "Gen. Journal Line"; var AccType: Option; var AccNo: Code[20])
    begin
        if GenJnlLine2."Bal. Account Type" in
           [GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor]
        then begin
            AccType := GenJnlLine2."Bal. Account Type";
            AccNo := GenJnlLine2."Bal. Account No.";
        end else begin
            AccType := GenJnlLine2."Account Type";
            AccNo := GenJnlLine2."Account No.";
        end;
    end;

    local procedure FindFirstCustLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange("Applies-to ID", AppliesToID);
        CustLedgEntry.SetRange(Open, true);
        exit(CustLedgEntry.FindFirst)
    end;

    local procedure FindFirstCustLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", AppliestoDocNo);
        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        exit(CustLedgEntry.FindFirst)
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange("Applies-to ID", AppliesToID);
        VendLedgEntry.SetRange(Open, true);
        exit(VendLedgEntry.FindFirst)
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", AppliestoDocNo);
        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        exit(VendLedgEntry.FindFirst)
    end;

    local procedure ClearPostingGroups()
    begin
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';

        OnAfterClearPostingGroups(Rec);
    end;

    local procedure ClearBalancePostingGroups()
    begin
        "Bal. Gen. Posting Type" := "Bal. Gen. Posting Type"::" ";
        "Bal. Gen. Bus. Posting Group" := '';
        "Bal. Gen. Prod. Posting Group" := '';
        "Bal. VAT Bus. Posting Group" := '';
        "Bal. VAT Prod. Posting Group" := '';

        OnAfterClearBalPostingGroups(Rec);
    end;

    procedure CancelBackgroundPosting()
    var
        GenJnlPostViaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
    begin
        GenJnlPostViaJobQueue.CancelQueueEntry(Rec);
        Reset;
        FilterGroup(2);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
    end;

    local procedure CleanLine()
    begin
        UpdateLineBalance;
        UpdateSource;
        CreateDim(
          DimMgt.TypeToTableID1("Account Type"), "Account No.",
          DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
          DATABASE::Job, "Job No.",
          DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
          DATABASE::Campaign, "Campaign No.");
        if not ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) then
            "Recipient Bank Account" := '';
        if xRec."Account No." <> '' then begin
            ClearPostingGroups;
            "Tax Area Code" := '';
            "Tax Liable" := false;
            "Tax Group Code" := '';
            "Bill-to/Pay-to No." := '';
            "Ship-to/Order Address Code" := '';
            "Sell-to/Buy-from No." := '';
            UpdateCountryCodeAndVATRegNo('');
            "Beneficiary Bank Code" := '';
        end;

        case "Account Type" of
            "Account Type"::"G/L Account":
                UpdateAccountID;
            "Account Type"::Customer:
                UpdateCustomerID;
            "Account Type"::"Bank Account":
                UpdateBankAccountID;
        end;
    end;

    local procedure ReplaceDescription(): Boolean
    begin
        if "Bal. Account No." = '' then
            exit(true);
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        exit(GenJnlBatch."Bal. Account No." <> '');
    end;

    local procedure AddCustVendIC(AccountType: Option; AccountNo: Code[20]): Boolean
    begin
        SetRange("Account Type", AccountType);
        SetRange("Account No.", AccountNo);
        if not IsEmpty then
            exit(false);

        Reset;
        if FindLast then;
        "Line No." += 10000;

        "Account Type" := AccountType;
        "Account No." := AccountNo;
        Insert;
        exit(true);
    end;

    procedure IsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if (GenJournalLine."Account No." <> '') and
           (GenJournalLine."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Account Type", GenJournalLine."Account No."));

        if (GenJournalLine."Bal. Account No." <> '') and
           (GenJournalLine."Bal. Account Type" in ["Bal. Account Type"::Customer,
                                                   "Bal. Account Type"::Vendor,
                                                   "Bal. Account Type"::"IC Partner"])
        then
            exit(AddCustVendIC(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No."));

        exit(false);
    end;

    procedure IsExportedToPaymentFile(): Boolean
    begin
        exit(IsPaymentJournallLineExported or IsAppliedToVendorLedgerEntryExported);
    end;

    procedure IsPaymentJournallLineExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        OldFilterGroup: Integer;
        HasExportedLines: Boolean;
    begin
        with GenJnlLine do begin
            CopyFilters(Rec);
            OldFilterGroup := FilterGroup;
            FilterGroup := 10;
            SetRange("Exported to Payment File", true);
            HasExportedLines := not IsEmpty;
            SetRange("Exported to Payment File");
            FilterGroup := OldFilterGroup;
        end;
        exit(HasExportedLines);
    end;

    procedure IsAppliedToVendorLedgerEntryExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJnlLine.CopyFilters(Rec);

        if GenJnlLine.FindSet then
            repeat
                if GenJnlLine.IsApplied then begin
                    VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                    if GenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                        VendLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                    end;
                    if GenJnlLine."Applies-to ID" <> '' then
                        VendLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendLedgerEntry.SetRange("Exported to Payment File", true);
                    if not VendLedgerEntry.IsEmpty then
                        exit(true);
                end;

                VendLedgerEntry.Reset();
                VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                VendLedgerEntry.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
                VendLedgerEntry.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");
                VendLedgerEntry.SetRange("Exported to Payment File", true);
                if not VendLedgerEntry.IsEmpty then
                    exit(true);
            until GenJnlLine.Next = 0;

        exit(false);
    end;

    local procedure ClearAppliedAutomatically()
    begin
        if CurrFieldNo <> 0 then
            "Applied Automatically" := false;
    end;

    procedure SetPostingDateAsDueDate(DueDate: Date; DateOffset: DateFormula): Boolean
    var
        NewPostingDate: Date;
    begin
        if DueDate = 0D then
            exit(false);

        NewPostingDate := CalcDate(DateOffset, DueDate);
        if NewPostingDate < WorkDate then begin
            Validate("Posting Date", WorkDate);
            exit(true);
        end;

        Validate("Posting Date", NewPostingDate);
        exit(false);
    end;

    procedure CalculatePostingDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
        EmptyDateFormula: DateFormula;
    begin
        GenJnlLine.Copy(Rec);
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");

        if GenJnlLine.FindSet then begin
            Window.Open(CalcPostDateMsg);
            repeat
                Evaluate(EmptyDateFormula, '<0D>');
                GenJnlLine.SetPostingDateAsDueDate(GenJnlLine.GetAppliesToDocDueDate, EmptyDateFormula);
                GenJnlLine.Modify(true);
                Window.Update(1, GenJnlLine."Document No.");
            until GenJnlLine.Next = 0;
            Window.Close;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePaymentVATInfo(UseDefaultPmtPurpose: Boolean)
    begin
        SetPaymentVATInfoOnField("Payment Purpose", UseDefaultPmtPurpose);
        SetPaymentVATInfoOnField("Cash Order Including", false);
        SetPaymentVATInfoOnField("Cash Order Supplement", false);
    end;

    local procedure SetPaymentVATInfoOnField(var FieldValue: Text[250]; UseDefaultPmtPurpose: Boolean)
    var
        BankAcc: Record "Bank Account";
        VendBankAcc: Record "Vendor Bank Account";
        StdRepMgt: Codeunit "Local Report Management";
        MaxDecPoints: Integer;
        VATAmount: Decimal;
        TempAmount: Decimal;
        PersonalAccountNo: Text[20];
        BankBranchNo: Text[60];
    begin
        if ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account") or ("Bal. Account No." = '') then
            exit;

        BankAcc.Get("Bal. Account No.");

        if not Currency.Get("Currency Code") then
            Currency.InitRoundingPrecision;
        StdRepMgt.RefreshDecimalPoints(MaxDecPoints, Currency."Amount Rounding Precision");

        if ("Currency Code" = '') or Currency.Conventional then
            TempAmount := "Amount (LCY)"
        else
            TempAmount := Amount;
        VATAmount := Round(
          TempAmount * (1 - 1 / (1 + BankAcc."VAT % for Document" / 100)), Currency."Amount Rounding Precision");

        BankBranchNo := '';
        PersonalAccountNo := '';
        if UseDefaultPmtPurpose then
            if BankAcc."Account Type" = BankAcc."Account Type"::"Bank Account" then
                if ("Account Type" = "Account Type"::Vendor) and ("Account No." <> '') then
                    if VendBankAcc.Get("Account No.", "Beneficiary Bank Code") then begin
                        FieldValue := VendBankAcc."Def. Payment Purpose";
                        if VendBankAcc."Bank Branch No." <> '' then begin
                            BankBranchNo := VendBankAcc."Bank Branch No.";
                            PersonalAccountNo := VendBankAcc."Personal Account No.";
                        end;
                    end;

        // Format: %1 - Amount incl. VAT, %2 - VAT Amount, %3 - Amount w/o VAT, %4 - Applied Doc. No., %5 - Applied Doc. Date
        FieldValue :=
          CopyStr(
            StrSubstNo(
              FieldValue,
              Format(TempAmount, 0, StrSubstNo('<Sign><Integer><Decimals,%1>', MaxDecPoints + 1)),
              Format(VATAmount * (-1), 0, StrSubstNo('<Sign><Integer><Decimals,%1>', MaxDecPoints + 1)),
              Format((TempAmount - VATAmount) * (-1), 0, StrSubstNo('<Sign><Integer><Decimals,%1>', MaxDecPoints + 1)),
              "Applies-to Doc. No.", "Applies-to Doc. Date", BankBranchNo, PersonalAccountNo),
            1, MaxStrLen(FieldValue));
    end;

    [Scope('OnPrem')]
    procedure AddPersonalDocInfo(var PersonalDoc: Text[250])
    var
        TaxpayerDocType: Record "Taxpayer Document Type";
        Person: Record Person;
        PersonalDocument: Record "Person Document";
        Employee: Record Employee;
        BankAcc: Record "Bank Account";
        Vend: Record Vendor;
    begin
        PersonalDoc := '';

        if ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account") or ("Bal. Account No." = '') then
            exit;

        BankAcc.Get("Bal. Account No.");
        if BankAcc."Account Type" <> BankAcc."Account Type"::"Cash Account" then
            exit;

        if ("Account Type" = "Account Type"::Vendor) and ("Account No." <> '') and ("Debit Amount" <> 0) then begin
            Vend.Get("Account No.");
            if Vend."Vendor Type" in [Vend."Vendor Type"::"Resp. Employee", Vend."Vendor Type"::Person] then begin
                case Vend."Vendor Type" of
                    Vend."Vendor Type"::"Resp. Employee":
                        begin
                            if Employee.Get(Vend."Employee No.") then
                                Person.SetRange("No.", Employee."Person No.");
                        end;
                    Vend."Vendor Type"::Person:
                        Person.SetRange("Vendor No.", Vend."No.");
                end;
                if Person.FindFirst then
                    if TaxpayerDocType.Get(Person."Identity Document Type") then begin
                        Person.GetIdentityDoc("Posting Date", PersonalDocument);
                        PersonalDoc :=
                          CopyStr(
                            StrSubstNo(
                              Text14910,
                              TaxpayerDocType."Document Name",
                              PersonalDocument."Document Series",
                              PersonalDocument."Document No.",
                              PersonalDocument."Issue Authority",
                              PersonalDocument."Issue Date"),
                            1, MaxStrLen("Cash Order Including"));
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetUnrealizedVATAmount(Remaining: Boolean) Result: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntry.Get("Unrealized VAT Entry No.") then
            if Remaining then
                Result := VATEntry."Remaining Unrealized Amount"
            else
                Result := VATEntry."Unrealized Amount";
    end;

    [Scope('OnPrem')]
    procedure SetExportStatus()
    var
        BankAcc: Record "Bank Account";
    begin
        if not ("Document Type" in ["Document Type"::" ", "Document Type"::Payment, "Document Type"::Refund]) then
            exit;

        if "Bal. Account Type" <> "Bal. Account Type"::"Bank Account" then
            exit;

        if not BankAcc.Get("Bal. Account No.") then
            exit;

        if not BankAcc."Use Client-Bank" then
            exit;

        if "Export Status" >= "Export Status"::Exported then
            exit;

        if ("Document No." <> '') and ("Account No." <> '') then begin
            if ("Beneficiary Bank Code" <> '') and (Amount <> 0) then
                "Export Status" := "Export Status"::New
            else
                "Export Status" := "Export Status"::" ";
        end else
            "Export Status" := "Export Status"::" ";
    end;

    [Scope('OnPrem')]
    procedure ExportCancel()
    begin
        if "Export Status" = "Export Status"::"Bank Statement Found" then
            Error(Text14700, "Statement No.");
        if "Export Status" = "Export Status"::Exported then begin
            "Export Status" := "Export Status"::New;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBankAccDetail(BankAccDetailLoc: Record "Bank Account Details")
    begin
        BankAccountDetail := BankAccDetailLoc;
    end;

    procedure ImportBankStatement()
    var
        ProcessGenJnlLines: Codeunit "Process Gen. Journal  Lines";
    begin
        ProcessGenJnlLines.ImportBankStatement(Rec);
    end;

    procedure ExportPaymentFile()
    var
        BankAcc: Record "Bank Account";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not FindSet then
            Error(NothingToExportErr);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
        TestField("Check Printed", false);

        CheckDocNoOnLines;
        if IsExportedToPaymentFile then
            if not ConfirmManagement.GetResponseOrDefault(ExportAgainQst, true) then
                exit;
        BankAcc.Get("Bal. Account No.");
        if BankAcc.GetPaymentExportCodeunitID > 0 then
            CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID, Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", Rec);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
        PaymentToleranceMgt.SetSuppressCommit(SuppressCommit);
    end;

    procedure TotalExportedAmount(): Decimal
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
    begin
        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            exit(0);
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);
        CreditTransferEntry.CalcSums("Transfer Amount");
        exit(CreditTransferEntry."Transfer Amount");
    end;

    procedure DrillDownExportedAmount()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
    begin
        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            exit;
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);
        PAGE.Run(PAGE::"Credit Transfer Reg. Entries", CreditTransferEntry);
    end;

    local procedure CopyDimensionsFromJobTaskLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimensionsFromJobTaskLine(TempJobJnlLine, Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        "Dimension Set ID" := TempJobJnlLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := TempJobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TempJobJnlLine."Shortcut Dimension 2 Code";
    end;

    procedure CopyDocumentFields(DocType: Option; DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure CopyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        "Document Type" := CustLedgerEntry."Document Type";
        Description := CustLedgerEntry.Description;
        "Shortcut Dimension 1 Code" := CustLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := CustLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := CustLedgerEntry."Dimension Set ID";
        "Posting Group" := CustLedgerEntry."Customer Posting Group";
        "Source Type" := "Source Type"::Customer;
        "Source No." := CustLedgerEntry."Customer No.";

        OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgEntry, Rec);
    end;

    procedure CopyFromGenJnlAllocation(GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
        "Account No." := GenJnlAlloc."Account No.";
        "Shortcut Dimension 1 Code" := GenJnlAlloc."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := GenJnlAlloc."Shortcut Dimension 2 Code";
        "Dimension Set ID" := GenJnlAlloc."Dimension Set ID";
        "Gen. Posting Type" := GenJnlAlloc."Gen. Posting Type";
        "Gen. Bus. Posting Group" := GenJnlAlloc."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GenJnlAlloc."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GenJnlAlloc."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GenJnlAlloc."VAT Prod. Posting Group";
        "Tax Area Code" := GenJnlAlloc."Tax Area Code";
        "Tax Liable" := GenJnlAlloc."Tax Liable";
        "Tax Group Code" := GenJnlAlloc."Tax Group Code";
        "Use Tax" := GenJnlAlloc."Use Tax";
        "VAT Calculation Type" := GenJnlAlloc."VAT Calculation Type";
        "VAT Amount" := GenJnlAlloc."VAT Amount";
        "VAT Base Amount" := GenJnlAlloc.Amount - GenJnlAlloc."VAT Amount";
        "VAT %" := GenJnlAlloc."VAT %";
        "Source Currency Amount" := GenJnlAlloc."Additional-Currency Amount";
        Amount := GenJnlAlloc.Amount;
        "Amount (LCY)" := GenJnlAlloc.Amount;

        OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAlloc, Rec);
    end;

    procedure CopyFromInvoicePostBuffer(InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        "Account No." := InvoicePostBuffer."G/L Account";
        "System-Created Entry" := InvoicePostBuffer."System-Created Entry";
        "Gen. Bus. Posting Group" := InvoicePostBuffer."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := InvoicePostBuffer."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := InvoicePostBuffer."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := InvoicePostBuffer."VAT Prod. Posting Group";
        "Tax Area Code" := InvoicePostBuffer."Tax Area Code";
        "Tax Liable" := InvoicePostBuffer."Tax Liable";
        "Tax Group Code" := InvoicePostBuffer."Tax Group Code";
        "Use Tax" := InvoicePostBuffer."Use Tax";
        Quantity := InvoicePostBuffer.Quantity;
        "VAT %" := InvoicePostBuffer."VAT %";
        "VAT Calculation Type" := InvoicePostBuffer."VAT Calculation Type";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "Job No." := InvoicePostBuffer."Job No.";
        "Deferral Code" := InvoicePostBuffer."Deferral Code";
        "Deferral Line No." := InvoicePostBuffer."Deferral Line No.";
        Amount := InvoicePostBuffer.Amount;
        "Source Currency Amount" := InvoicePostBuffer."Amount (ACY)";
        "VAT Base Amount" := InvoicePostBuffer."VAT Base Amount";
        "Source Curr. VAT Base Amount" := InvoicePostBuffer."VAT Base Amount (ACY)";
        "VAT Amount" := InvoicePostBuffer."VAT Amount";
        "Source Curr. VAT Amount" := InvoicePostBuffer."VAT Amount (ACY)";
        "VAT Difference" := InvoicePostBuffer."VAT Difference";
        "VAT Base Before Pmt. Disc." := InvoicePostBuffer."VAT Base Before Pmt. Disc.";

        OnAfterCopyGenJnlLineFromInvPostBuffer(InvoicePostBuffer, Rec);
    end;

    procedure CopyFromInvoicePostBufferFA(InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        "Account Type" := "Account Type"::"Fixed Asset";
        "FA Posting Date" := InvoicePostBuffer."FA Posting Date";
        "Depreciation Book Code" := InvoicePostBuffer."Depreciation Book Code";
        "Salvage Value" := InvoicePostBuffer."Salvage Value";
        "Depr. until FA Posting Date" := InvoicePostBuffer."Depr. until FA Posting Date";
        "Depr. Acquisition Cost" := InvoicePostBuffer."Depr. Acquisition Cost";
        "Maintenance Code" := InvoicePostBuffer."Maintenance Code";
        "Insurance No." := InvoicePostBuffer."Insurance No.";
        "Budgeted FA No." := InvoicePostBuffer."Budgeted FA No.";
        "Duplicate in Depreciation Book" := InvoicePostBuffer."Duplicate in Depreciation Book";
        "Use Duplication List" := InvoicePostBuffer."Use Duplication List";

        OnAfterCopyGenJnlLineFromInvPostBufferFA(InvoicePostBuffer, Rec);
    end;

    procedure CopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        "Document Date" := IssuedFinChargeMemoHeader."Document Date";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedFinChargeMemoHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
        end;
        Validate("Currency Code", IssuedFinChargeMemoHeader."Currency Code");
        Description := IssuedFinChargeMemoHeader."Posting Description";
        "Source Type" := "Source Type"::Customer;
        "Source No." := IssuedFinChargeMemoHeader."Customer No.";
        "Reason Code" := IssuedFinChargeMemoHeader."Reason Code";
        "Posting No. Series" := IssuedFinChargeMemoHeader."No. Series";
        "Country/Region Code" := IssuedFinChargeMemoHeader."Country/Region Code";
        "VAT Registration No." := IssuedFinChargeMemoHeader."VAT Registration No.";
        "Shortcut Dimension 1 Code" := IssuedFinChargeMemoHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := IssuedFinChargeMemoHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := IssuedFinChargeMemoHeader."Dimension Set ID";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedFinChargeMemoHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedFinChargeMemoHeader."VAT Bus. Posting Group";
        end;
    end;

    procedure CopyFromIssuedFinChargeMemoLine(IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line")
    begin
        "Gen. Prod. Posting Group" := IssuedFinChargeMemoLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := IssuedFinChargeMemoLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := IssuedFinChargeMemoLine."VAT Calculation Type";
        "VAT %" := IssuedFinChargeMemoLine."VAT %";
        Validate(Amount, IssuedFinChargeMemoLine.Amount + IssuedFinChargeMemoLine."VAT Amount");
        "VAT Amount" := IssuedFinChargeMemoLine."VAT Amount";
    end;

    procedure CopyFromIssuedReminderHeader(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        "Document Date" := IssuedReminderHeader."Document Date";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedReminderHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
        end;
        Validate("Currency Code", IssuedReminderHeader."Currency Code");
        Description := IssuedReminderHeader."Posting Description";
        "Source Type" := "Source Type"::Customer;
        "Source No." := IssuedReminderHeader."Customer No.";
        "Reason Code" := IssuedReminderHeader."Reason Code";
        "Posting No. Series" := IssuedReminderHeader."No. Series";
        "Country/Region Code" := IssuedReminderHeader."Country/Region Code";
        "VAT Registration No." := IssuedReminderHeader."VAT Registration No.";
        "Shortcut Dimension 1 Code" := IssuedReminderHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := IssuedReminderHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := IssuedReminderHeader."Dimension Set ID";
        if "Account Type" = "Account Type"::"G/L Account" then begin
            "Gen. Posting Type" := "Gen. Posting Type"::Sale;
            "Gen. Bus. Posting Group" := IssuedReminderHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := IssuedReminderHeader."VAT Bus. Posting Group";
        end;
    end;

    procedure CopyFromIssuedReminderLine(IssuedReminderLine: Record "Issued Reminder Line")
    begin
        "Gen. Prod. Posting Group" := IssuedReminderLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := IssuedReminderLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := IssuedReminderLine."VAT Calculation Type";
        "VAT %" := IssuedReminderLine."VAT %";
        Validate(Amount, IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount");
        "VAT Amount" := IssuedReminderLine."VAT Amount";
    end;

    procedure CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
        "Account No." := PrepmtInvLineBuffer."G/L Account No.";
        "Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        "Tax Area Code" := PrepmtInvLineBuffer."Tax Area Code";
        "Tax Liable" := PrepmtInvLineBuffer."Tax Liable";
        "Tax Group Code" := PrepmtInvLineBuffer."Tax Group Code";
        "Use Tax" := false;
        "VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        "Job No." := PrepmtInvLineBuffer."Job No.";
        Amount := PrepmtInvLineBuffer.Amount;
        "Source Currency Amount" := PrepmtInvLineBuffer."Amount (ACY)";
        "VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        "Source Curr. VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount (ACY)";
        "VAT Amount" := PrepmtInvLineBuffer."VAT Amount";
        "Source Curr. VAT Amount" := PrepmtInvLineBuffer."VAT Amount (ACY)";
        "VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        "VAT Base Before Pmt. Disc." := PrepmtInvLineBuffer."VAT Base Before Pmt. Disc.";

        OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer, Rec);
    end;

    procedure CopyFromPurchHeader(PurchHeader: Record "Purchase Header")
    begin
        "Source Currency Code" := PurchHeader."Currency Code";
        "Currency Factor" := PurchHeader."Currency Factor";
        Correction := PurchHeader.Correction;
        "VAT Base Discount %" := PurchHeader."VAT Base Discount %";
        "Sell-to/Buy-from No." := PurchHeader."Buy-from Vendor No.";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Country/Region Code" := PurchHeader."VAT Country/Region Code";
        "VAT Registration No." := PurchHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "Posting No. Series" := PurchHeader."Posting No. Series";
        "IC Partner Code" := PurchHeader."Pay-to IC Partner Code";
        "Ship-to/Order Address Code" := PurchHeader."Order Address Code";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "On Hold" := PurchHeader."On Hold";
        if "Account Type" = "Account Type"::Vendor then
            "Posting Group" := PurchHeader."Vendor Posting Group";

        OnAfterCopyGenJnlLineFromPurchHeader(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPrepmt(PurchHeader: Record "Purchase Header")
    begin
        "Source Currency Code" := PurchHeader."Currency Code";
        "VAT Base Discount %" := PurchHeader."VAT Base Discount %";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Country/Region Code" := PurchHeader."VAT Country/Region Code";
        "VAT Registration No." := PurchHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "IC Partner Code" := PurchHeader."Buy-from IC Partner Code";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "System-Created Entry" := true;
        Prepayment := true;

        OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPrepmtPost(PurchHeader: Record "Purchase Header"; UsePmtDisc: Boolean)
    begin
        "Account Type" := "Account Type"::Vendor;
        "Account No." := PurchHeader."Pay-to Vendor No.";
        SetCurrencyFactor(PurchHeader."Currency Code", PurchHeader."Currency Factor");
        "Source Currency Code" := PurchHeader."Currency Code";
        "Bill-to/Pay-to No." := PurchHeader."Pay-to Vendor No.";
        "Sell-to/Buy-from No." := PurchHeader."Buy-from Vendor No.";
        "Salespers./Purch. Code" := PurchHeader."Purchaser Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := PurchHeader."Pay-to Vendor No.";
        "IC Partner Code" := PurchHeader."Buy-from IC Partner Code";
        "System-Created Entry" := true;
        Prepayment := true;
        "Due Date" := PurchHeader."Prepayment Due Date";
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        if UsePmtDisc then begin
            "Pmt. Discount Date" := PurchHeader."Prepmt. Pmt. Discount Date";
            "Payment Discount %" := PurchHeader."Prepmt. Payment Discount %";
        end;

        OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost(PurchHeader, Rec, UsePmtDisc);
    end;

    procedure CopyFromPurchHeaderApplyTo(PurchHeader: Record "Purchase Header")
    begin
        "Applies-to Doc. Type" := PurchHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := PurchHeader."Applies-to Doc. No.";
        "Applies-to ID" := PurchHeader."Applies-to ID";
        "Allow Application" := PurchHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromPurchHeaderApplyTo(PurchHeader, Rec);
    end;

    procedure CopyFromPurchHeaderPayment(PurchHeader: Record "Purchase Header")
    begin
        "Due Date" := PurchHeader."Due Date";
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        "Pmt. Discount Date" := PurchHeader."Pmt. Discount Date";
        "Payment Discount %" := PurchHeader."Payment Discount %";
        "Creditor No." := PurchHeader."Creditor No.";
        "Payment Reference" := PurchHeader."Payment Reference";
        "Payment Method Code" := PurchHeader."Payment Method Code";

        OnAfterCopyGenJnlLineFromPurchHeaderPayment(PurchHeader, Rec);
    end;

    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Source Currency Code" := SalesHeader."Currency Code";
        "Currency Factor" := SalesHeader."Currency Factor";
        "VAT Base Discount %" := SalesHeader."VAT Base Discount %";
        Correction := SalesHeader.Correction;
        "EU 3-Party Trade" := SalesHeader."EU 3-Party Trade";
        "Sell-to/Buy-from No." := SalesHeader."Sell-to Customer No.";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Country/Region Code" := SalesHeader."VAT Country/Region Code";
        "VAT Registration No." := SalesHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "Posting No. Series" := SalesHeader."Posting No. Series";
        "Ship-to/Order Address Code" := SalesHeader."Ship-to Code";
        "IC Partner Code" := SalesHeader."Bill-to IC Partner Code";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "On Hold" := SalesHeader."On Hold";
        if "Account Type" = "Account Type"::Customer then
            "Posting Group" := SalesHeader."Customer Posting Group";

        OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header")
    begin
        "Source Currency Code" := SalesHeader."Currency Code";
        "VAT Base Discount %" := SalesHeader."VAT Base Discount %";
        "EU 3-Party Trade" := SalesHeader."EU 3-Party Trade";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Country/Region Code" := SalesHeader."VAT Country/Region Code";
        "VAT Registration No." := SalesHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
        "VAT Posting" := "VAT Posting"::"Manual VAT Entry";
        "System-Created Entry" := true;
        Prepayment := true;

        OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; UsePmtDisc: Boolean)
    begin
        "Account Type" := "Account Type"::Customer;
        "Account No." := SalesHeader."Bill-to Customer No.";
        SetCurrencyFactor(SalesHeader."Currency Code", SalesHeader."Currency Factor");
        "Source Currency Code" := SalesHeader."Currency Code";
        "Sell-to/Buy-from No." := SalesHeader."Sell-to Customer No.";
        "Bill-to/Pay-to No." := SalesHeader."Bill-to Customer No.";
        "Salespers./Purch. Code" := SalesHeader."Salesperson Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesHeader."Bill-to Customer No.";
        "IC Partner Code" := SalesHeader."Sell-to IC Partner Code";
        "System-Created Entry" := true;
        Prepayment := true;
        "Due Date" := SalesHeader."Prepayment Due Date";
        "Payment Terms Code" := SalesHeader."Prepmt. Payment Terms Code";
        if UsePmtDisc then begin
            "Pmt. Discount Date" := SalesHeader."Prepmt. Pmt. Discount Date";
            "Payment Discount %" := SalesHeader."Prepmt. Payment Discount %";
        end;

        OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost(SalesHeader, Rec, UsePmtDisc);
    end;

    procedure CopyFromSalesHeaderApplyTo(SalesHeader: Record "Sales Header")
    begin
        "Applies-to Doc. Type" := SalesHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := SalesHeader."Applies-to Doc. No.";
        "Applies-to ID" := SalesHeader."Applies-to ID";
        "Allow Application" := SalesHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromSalesHeaderApplyTo(SalesHeader, Rec);
    end;

    procedure CopyFromSalesHeaderPayment(SalesHeader: Record "Sales Header")
    begin
        "Due Date" := SalesHeader."Due Date";
        "Payment Terms Code" := SalesHeader."Payment Terms Code";
        "Payment Method Code" := SalesHeader."Payment Method Code";
        "Pmt. Discount Date" := SalesHeader."Pmt. Discount Date";
        "Payment Discount %" := SalesHeader."Payment Discount %";
        "Direct Debit Mandate ID" := SalesHeader."Direct Debit Mandate ID";

        OnAfterCopyGenJnlLineFromSalesHeaderPayment(SalesHeader, Rec);
    end;

    procedure CopyFromServiceHeader(ServiceHeader: Record "Service Header")
    begin
        "Source Currency Code" := ServiceHeader."Currency Code";
        Correction := ServiceHeader.Correction;
        "VAT Base Discount %" := ServiceHeader."VAT Base Discount %";
        "Sell-to/Buy-from No." := ServiceHeader."Customer No.";
        "Bill-to/Pay-to No." := ServiceHeader."Bill-to Customer No.";
        "Country/Region Code" := ServiceHeader."VAT Country/Region Code";
        "VAT Registration No." := ServiceHeader."VAT Registration No.";
        "Source Type" := "Source Type"::Customer;
        "Source No." := ServiceHeader."Bill-to Customer No.";
        "Posting No. Series" := ServiceHeader."Posting No. Series";
        "Ship-to/Order Address Code" := ServiceHeader."Ship-to Code";
        "EU 3-Party Trade" := ServiceHeader."EU 3-Party Trade";
        "Salespers./Purch. Code" := ServiceHeader."Salesperson Code";

        OnAfterCopyGenJnlLineFromServHeader(ServiceHeader, Rec);
    end;

    procedure CopyFromServiceHeaderApplyTo(ServiceHeader: Record "Service Header")
    begin
        "Applies-to Doc. Type" := ServiceHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := ServiceHeader."Applies-to Doc. No.";
        "Applies-to ID" := ServiceHeader."Applies-to ID";
        "Allow Application" := ServiceHeader."Bal. Account No." = '';

        OnAfterCopyGenJnlLineFromServHeaderApplyTo(ServiceHeader, Rec);
    end;

    procedure CopyFromServiceHeaderPayment(ServiceHeader: Record "Service Header")
    begin
        "Due Date" := ServiceHeader."Due Date";
        "Payment Terms Code" := ServiceHeader."Payment Terms Code";
        "Payment Method Code" := ServiceHeader."Payment Method Code";
        "Pmt. Discount Date" := ServiceHeader."Pmt. Discount Date";
        "Payment Discount %" := ServiceHeader."Payment Discount %";
        "Direct Debit Mandate ID" := ServiceHeader."Direct Debit Mandate ID";

        OnAfterCopyGenJnlLineFromServHeaderPayment(ServiceHeader, Rec);
    end;

    procedure CopyFromPaymentCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        "Document No." := CustLedgEntry."Document No.";
        "Account Type" := "Account Type"::Customer;
        "Account No." := CustLedgEntry."Customer No.";
        "Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
        "Posting Group" := CustLedgEntry."Customer Posting Group";
        "Source Type" := "Source Type"::Customer;
        "Source No." := CustLedgEntry."Customer No.";
        "Source Currency Code" := CustLedgEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;
    end;

    procedure CopyFromPaymentVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Document No." := VendLedgEntry."Document No.";
        "Account Type" := "Account Type"::Vendor;
        "Account No." := VendLedgEntry."Vendor No.";
        "Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        "Posting Group" := VendLedgEntry."Vendor Posting Group";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := VendLedgEntry."Vendor No.";
        "Source Currency Code" := VendLedgEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;
    end;

    local procedure CopyVATSetupToJnlLines(): Boolean
    begin
        if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then
            if GenJnlBatch.Get("Journal Template Name", "Journal Batch Name") then
                exit(GenJnlBatch."Copy VAT Setup to Jnl. Lines");
        exit("Copy VAT Setup to Jnl. Lines");
    end;

    local procedure SetAmountWithCustLedgEntry()
    begin
        OnBeforeSetAmountWithCustLedgEntry(Rec, CustLedgEntry);

        if "Currency Code" <> CustLedgEntry."Currency Code" then
            CheckModifyCurrencyCode(GenJnlLine."Account Type"::Customer, CustLedgEntry."Currency Code");
        if Amount = 0 then begin
            CustLedgEntry.CalcFields("Remaining Amount");
            SetAmountWithRemaining(
              PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(Rec, CustLedgEntry, 0, false),
              CustLedgEntry."Amount to Apply", CustLedgEntry."Remaining Amount", CustLedgEntry."Remaining Pmt. Disc. Possible");
        end;
    end;

    local procedure SetAmountWithVendLedgEntry()
    begin
        OnBeforeSetAmountWithVendLedgEntry(Rec, VendLedgEntry);

        if "Currency Code" <> VendLedgEntry."Currency Code" then
            CheckModifyCurrencyCode("Account Type"::Vendor, VendLedgEntry."Currency Code");
        if Amount = 0 then begin
            VendLedgEntry.CalcFields("Remaining Amount");
            SetAmountWithRemaining(
              PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(Rec, VendLedgEntry, 0, false),
              VendLedgEntry."Amount to Apply", VendLedgEntry."Remaining Amount", VendLedgEntry."Remaining Pmt. Disc. Possible");
        end;
    end;

    procedure CheckModifyCurrencyCode(AccountType: Option; CustVendLedgEntryCurrencyCode: Code[10])
    begin
        if Amount = 0 then
            UpdateCurrencyCode(CustVendLedgEntryCurrencyCode)
        else
            GenJnlApply.CheckAgainstApplnCurrency(
              "Currency Code", CustVendLedgEntryCurrencyCode, AccountType, true);
    end;

    local procedure SetAmountWithRemaining(CalcPmtDisc: Boolean; AmountToApply: Decimal; RemainingAmount: Decimal; RemainingPmtDiscPossible: Decimal)
    begin
        if AmountToApply <> 0 then
            if CalcPmtDisc and (Abs(AmountToApply) >= Abs(RemainingAmount - RemainingPmtDiscPossible)) then
                Amount := -(RemainingAmount - RemainingPmtDiscPossible)
            else
                Amount := -AmountToApply
        else
            if CalcPmtDisc then
                Amount := -(RemainingAmount - RemainingPmtDiscPossible)
            else
                Amount := -RemainingAmount;
        if "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor] then
            Amount := -Amount;

        OnAfterSetAmountWithRemaining(Rec);
        ValidateAmount(false);
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if (BatchFilter = '') and ("Journal Batch Name" <> '') then
            BatchFilter := "Journal Batch Name";

        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if (TemplateFilter = '') and ("Journal Template Name" <> '') then begin
                TemplateFilter := "Journal Template Name";
                SetFilter("Journal Template Name", TemplateFilter);
            end;
            if TemplateFilter <> '' then
                GenJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            GenJournalBatch.SetFilter(Name, BatchFilter);
            GenJournalBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure GetDeferralAmount() DeferralAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralAmount(Rec, DeferralAmount, IsHandled);
        if IsHandled then
            exit;

        if "VAT Base Amount" <> 0 then
            DeferralAmount := "VAT Base Amount"
        else
            DeferralAmount := Amount;

        OnAfterGetDeferralAmount(Rec, DeferralAmount);
    end;

    [Scope('OnPrem')]
    procedure ShowDeferrals(PostingDate: Date; CurrencyCode: Code[10]) ReturnValue: Boolean
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(
          DeferralUtilities.OpenLineScheduleEdit(
            "Deferral Code", GetDeferralDocType, "Journal Template Name", "Journal Batch Name", 0, '', "Line No.",
            GetDeferralAmount(), PostingDate, Description, CurrencyCode));
    end;

    procedure GetDeferralDocType(): Integer
    begin
        exit(DeferralDocType::"G/L");
    end;

    procedure IsForPurchase(): Boolean
    begin
        if ("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor) then
            exit(true);

        exit(false);
    end;

    procedure IsForSales(): Boolean
    begin
        if ("Account Type" = "Account Type"::Customer) or ("Bal. Account Type" = "Bal. Account Type"::Customer) then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePrintCheckRestrictions()
    begin
    end;

    procedure IncrementDocumentNo(GenJnlBatch: Record "Gen. Journal Batch"; var LastDocNumber: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if GenJnlBatch."No. Series" <> '' then begin
            NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, GenJnlBatch."No. Series", "Posting Date");
            if NoSeriesLine."Increment-by No." > 1 then
                NoSeriesMgt.IncrementNoText(LastDocNumber, NoSeriesLine."Increment-by No.")
            else
                LastDocNumber := IncStr(LastDocNumber);
        end else
            LastDocNumber := IncStr(LastDocNumber);
    end;

    procedure NeedCheckZeroAmount(): Boolean
    begin
        exit(
          ("Account No." <> '') and
          not "System-Created Entry" and
          not "Allow Zero-Amount Posting" and
          ("Account Type" <> "Account Type"::"Fixed Asset"));
    end;

    procedure IsRecurring(): Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        if "Journal Template Name" <> '' then
            if GenJournalTemplate.Get("Journal Template Name") then
                exit(GenJournalTemplate.Recurring);

        exit(false);
    end;

    local procedure SuggestBalancingAmount(LastGenJnlLine: Record "Gen. Journal Line"; BottomLine: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if "Document No." = '' then
            exit;
        if GetFilters <> '' then
            exit;

        GenJournalLine.SetRange("Journal Template Name", LastGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", LastGenJnlLine."Journal Batch Name");
        if BottomLine then
            GenJournalLine.SetFilter("Line No.", '<=%1', LastGenJnlLine."Line No.")
        else
            GenJournalLine.SetFilter("Line No.", '<%1', LastGenJnlLine."Line No.");

        if GenJournalLine.FindLast then begin
            if BottomLine then begin
                GenJournalLine.SetRange("Document No.", LastGenJnlLine."Document No.");
                GenJournalLine.SetRange("Posting Date", LastGenJnlLine."Posting Date");
            end else begin
                GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
                GenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");
            end;
            GenJournalLine.SetRange("Bal. Account No.", '');
            if GenJournalLine.FindFirst then begin
                GenJournalLine.CalcSums(Amount);
                "Document No." := GenJournalLine."Document No.";
                "Posting Date" := GenJournalLine."Posting Date";
                Validate(Amount, -GenJournalLine.Amount);
            end;
        end;
    end;

    local procedure GetGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Account No.");
        CheckGLAcc(GLAcc);
        if ReplaceDescription and (not GLAcc."Omit Default Descr. in Jnl.") then
            UpdateDescription(GLAcc.Name)
        else
            if GLAcc."Omit Default Descr. in Jnl." then
                Description := '';
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
        if CopyVATSetupToJnlLines then begin
            "Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Tax Area Code" := GLAcc."Tax Area Code";
        "Tax Liable" := GLAcc."Tax Liable";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if "Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearPostingGroups;
        Validate("Beneficiary Bank Code", '');
        Validate("Deferral Code", GLAcc."Default Deferral Template Code");

        OnAfterAccountNoOnValidateGetGLAccount(Rec, GLAcc);
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
        if CopyVATSetupToJnlLines then begin
            "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Bal. Tax Area Code" := GLAcc."Tax Area Code";
        "Bal. Tax Liable" := GLAcc."Tax Liable";
        "Bal. Tax Group Code" := GLAcc."Tax Group Code";
        if "Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearBalancePostingGroups;

        OnAfterAccountNoOnValidateGetGLBalAccount(Rec, GLAcc);
    end;

    local procedure GetCustomerAccount()
    var
        Cust: Record Customer;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Cust.Get("Account No.");
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Account Type", "Account No.");
        UpdateDescription(Cust.Name);
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Cust."Currency Code";
        ClearPostingGroups;
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Account No.") and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
        CheckPaymentTolerance;
        if ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund]) and (Cust."Default Bank Code" <> '') then
            Validate("Beneficiary Bank Code", Cust."Default Bank Code")
        else
            Validate("Beneficiary Bank Code", '');

        OnAfterAccountNoOnValidateGetCustomerAccount(Rec, Cust, CurrFieldNo);
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
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Cust."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Cust."Currency Code";
        ClearBalancePostingGroups;
        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> "Bal. Account No.") and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
        CheckPaymentTolerance;

        OnAfterAccountNoOnValidateGetCustomerBalAccount(Rec, Cust, CurrFieldNo);
    end;

    local procedure GetVendorAccount()
    var
        Vend: Record Vendor;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Vend.Get("Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Account Type", "Account No.");
        UpdateDescription(Vend.Name);
        "Payment Method Code" := Vend."Payment Method Code";
        "Creditor No." := Vend."Creditor No.";

        OnGenJnlLineGetVendorAccount(Vend);

        Validate("Recipient Bank Account", Vend."Preferred Bank Account Code");
        "Posting Group" := Vend."Vendor Posting Group";
        SetSalespersonPurchaserCode(Vend."Purchaser Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Vend."Currency Code";
        ClearPostingGroups;
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Account No.") and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
        CheckPaymentTolerance;
        if ("Document Type" in ["Document Type"::Payment, "Document Type"::Refund]) and (Vend."Default Bank Code" <> '') then
            Validate("Beneficiary Bank Code", Vend."Default Bank Code")
        else
            Validate("Beneficiary Bank Code", '');
        "Tax Period" := Vend."Tax Authority Code";

        OnAfterAccountNoOnValidateGetVendorAccount(Rec, Vend, CurrFieldNo);
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
        "Payment Method Code" := Vend."Payment Method Code";
        Validate("Recipient Bank Account", Vend."Preferred Bank Account Code");
        "Posting Group" := Vend."Vendor Posting Group";
        SetSalespersonPurchaserCode(Vend."Purchaser Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Vend."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Vend."Currency Code";
        ClearBalancePostingGroups;
        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> "Bal. Account No.") and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
        Validate("Payment Terms Code");
        CheckPaymentTolerance;

        OnAfterAccountNoOnValidateGetVendorBalAccount(Rec, Vend, CurrFieldNo);
    end;

    local procedure GetBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        BankAcc.TestField(Blocked, false);
        if ReplaceDescription then
            UpdateDescription(BankAcc.Name);
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
        ClearPostingGroups;

        OnAfterAccountNoOnValidateGetBankAccount(Rec, BankAcc, CurrFieldNo);
    end;

    local procedure GetBankBalAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bal. Account No.");
        BankAcc.TestField(Blocked, false);
        ReadGLSetup;
        if GLSetup."Enable Russian Accounting" then
            BankAcc.TestField("Bank Acc. Posting Group");
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
        if BankAcc."Currency Code" = '' then
            if "Account No." = '' then
                "Currency Code" := ''
            else
                ClearCurrencyCode
        else
            if SetCurrencyCode("Account Type", "Account No.") then begin
                if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then begin
                    BankAcc.TestField("Currency Code", "Currency Code");
                    "Currency Code" := BankAcc."Currency Code";
                end
            end else
                if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                    "Currency Code" := BankAcc."Currency Code";
        ClearBalancePostingGroups;

        OnAfterAccountNoOnValidateGetBankBalAccount(Rec, BankAcc, CurrFieldNo);
    end;

    local procedure GetFAAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        UpdateDescription(FA.Description);
        GetFADeprBook("Account No.");
        GetFAVATSetup;
        GetFAAddCurrExchRate;
        if "Employee No." = '' then
            "Employee No." := FA."Responsible Employee";
        if "FA Location Code" = '' then
            "FA Location Code" := FA."FA Location Code";

        OnAfterAccountNoOnValidateGetFAAccount(Rec, FA);
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
        GetFADeprBook("Bal. Account No.");
        GetFAVATSetup;
        GetFAAddCurrExchRate;

        OnAfterAccountNoOnValidateGetFABalAccount(Rec, FA);
    end;

    local procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner;
        UpdateDescription(ICPartner.Name);
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearPostingGroups;
        "IC Partner Code" := "Account No.";

        OnAfterAccountNoOnValidateGetICPartnerAccount(Rec, ICPartner);
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
        ClearBalancePostingGroups;
        "IC Partner Code" := "Bal. Account No.";

        OnAfterAccountNoOnValidateGetICPartnerBalAccount(Rec, ICPartner);
    end;

    procedure CreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line")
    var
        BalancingGenJnlLine: Record "Gen. Journal Line";
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
    begin
        TestField("Journal Template Name");
        TestField("Journal Batch Name");
        TestField("Posting Date");
        TestField("Account Type");
        TestField("Account No.");
        TestField("Posting Date");

        // Creating Fixed Asset Line
        FAGenJournalLine.Init();
        FAGenJournalLine.Validate("Journal Template Name", "Journal Template Name");
        FAGenJournalLine.Validate("Journal Batch Name", "Journal Batch Name");
        FAGenJournalLine.Validate("Line No.", GetNewLineNo("Journal Template Name", "Journal Batch Name"));
        FAGenJournalLine.Validate("Document Type", "Document Type");
        FAGenJournalLine.Validate("Document No.", GenerateLineDocNo("Journal Batch Name", "Posting Date", "Journal Template Name"));
        FAGenJournalLine.Validate("Account Type", "Account Type");
        FAGenJournalLine.Validate("Account No.", "Account No.");
        FAGenJournalLine.Validate(Amount, Amount);
        FAGenJournalLine.Validate("Posting Date", "Posting Date");
        FAGenJournalLine.Validate("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
        FAGenJournalLine.Validate("External Document No.", "External Document No.");
        FAGenJournalLine.Insert(true);

        // Creating Balancing Line
        BalancingGenJnlLine.Copy(FAGenJournalLine);
        BalancingGenJnlLine.Validate("Account Type", "Bal. Account Type");
        BalancingGenJnlLine.Validate("Account No.", "Bal. Account No.");
        BalancingGenJnlLine.Validate(Amount, -Amount);
        BalancingGenJnlLine.Validate("Line No.", GetNewLineNo("Journal Template Name", "Journal Batch Name"));
        BalancingGenJnlLine.Insert(true);

        FAGenJournalLine.TestField("Posting Group");

        // Inserting additional fields in Fixed Asset line required for acquisition
        if FAPostingGr.Get(FAGenJournalLine."Posting Group") then begin
            LocalGLAcc.Get(FAPostingGr."Acquisition Cost Account");
            LocalGLAcc.CheckGLAcc;
            FAGenJournalLine.Validate("Gen. Posting Type", LocalGLAcc."Gen. Posting Type");
            FAGenJournalLine.Validate("Gen. Bus. Posting Group", LocalGLAcc."Gen. Bus. Posting Group");
            FAGenJournalLine.Validate("Gen. Prod. Posting Group", LocalGLAcc."Gen. Prod. Posting Group");
            FAGenJournalLine.Validate("VAT Bus. Posting Group", LocalGLAcc."VAT Bus. Posting Group");
            FAGenJournalLine.Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");
            FAGenJournalLine.Validate("Tax Group Code", LocalGLAcc."Tax Group Code");
            FAGenJournalLine.Validate("VAT Prod. Posting Group");
            FAGenJournalLine.Modify(true)
        end;

        OnAfterCreateFAAcquisitionLines(FAGenJournalLine, Rec);

        // Inserting Source Code
        if "Source Code" = '' then begin
            GenJnlTemplate.Get("Journal Template Name");
            FAGenJournalLine.Validate("Source Code", GenJnlTemplate."Source Code");
            FAGenJournalLine.Modify(true);
            BalancingGenJnlLine.Validate("Source Code", GenJnlTemplate."Source Code");
            BalancingGenJnlLine.Modify(true);
        end;
    end;

    local procedure GenerateLineDocNo(BatchName: Code[10]; PostingDate: Date; TemplateName: Code[20]) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        if GenJournalBatch."No. Series" <> '' then
            DocumentNo := NoSeriesManagement.TryGetNextNo(GenJournalBatch."No. Series", PostingDate);
    end;

    local procedure GetFilterAccountNo(): Code[20]
    begin
        if GetFilter("Account No.") <> '' then
            if GetRangeMin("Account No.") = GetRangeMax("Account No.") then
                exit(GetRangeMax("Account No."));
    end;

    procedure SetAccountNoFromFilter()
    var
        AccountNo: Code[20];
    begin
        AccountNo := GetFilterAccountNo;
        if AccountNo = '' then begin
            FilterGroup(2);
            AccountNo := GetFilterAccountNo;
            FilterGroup(0);
        end;
        if AccountNo <> '' then
            "Account No." := AccountNo;
    end;

    procedure GetNewLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Validate("Journal Template Name", TemplateName);
        GenJournalLine.Validate("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if GenJournalLine.FindLast then
            exit(GenJournalLine."Line No." + 10000);
        exit(10000);
    end;

    procedure VoidPaymentFile()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJournalLine2: Record "Gen. Journal Line";
        VoidTransmitElecPmnts: Report "Void/Transmit Elec. Pmnts";
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine := Rec;
        TempGenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TempGenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine2.CopyFilters(TempGenJnlLine);
        GenJournalLine2.SetFilter("Document Type", 'Payment|Refund');
        GenJournalLine2.SetFilter("Bank Payment Type", 'Electronic Payment|Electronic Payment-IAT');
        GenJournalLine2.SetRange("Exported to Payment File", true);
        GenJournalLine2.SetRange("Check Transmitted", false);
        if not GenJournalLine2.FindFirst then
            Error(NoEntriesToVoidErr);

        Clear(VoidTransmitElecPmnts);
        VoidTransmitElecPmnts.SetUsageType(1);   // Void
        VoidTransmitElecPmnts.SetTableView(TempGenJnlLine);
        if "Account Type" = "Account Type"::"Bank Account" then
            VoidTransmitElecPmnts.SetBankAccountNo("Account No.")
        else
            if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                VoidTransmitElecPmnts.SetBankAccountNo("Bal. Account No.");
        VoidTransmitElecPmnts.RunModal;
    end;

    procedure TransmitPaymentFile()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        VoidTransmitElecPmnts: Report "Void/Transmit Elec. Pmnts";
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine := Rec;
        TempGenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TempGenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        Clear(VoidTransmitElecPmnts);
        VoidTransmitElecPmnts.SetUsageType(2);   // Transmit
        VoidTransmitElecPmnts.SetTableView(TempGenJnlLine);
        if "Account Type" = "Account Type"::"Bank Account" then
            VoidTransmitElecPmnts.SetBankAccountNo("Account No.")
        else
            if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                VoidTransmitElecPmnts.SetBankAccountNo("Bal. Account No.");
        VoidTransmitElecPmnts.RunModal;
    end;

    local procedure SetSalespersonPurchaserCode(SalesperPurchCodeToCheck: Code[20]; var SalesperPuchCodeToAssign: Code[20])
    begin
        if SalesperPurchCodeToCheck <> '' then
            if SalespersonPurchaser.Get(SalesperPurchCodeToCheck) then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    SalesperPuchCodeToAssign := ''
                else
                    SalesperPuchCodeToAssign := SalesperPurchCodeToCheck;
    end;

    procedure ValidateSalesPersonPurchaserCode(GenJournalLine2: Record "Gen. Journal Line")
    begin
        if GenJournalLine2."Salespers./Purch. Code" <> '' then
            if SalespersonPurchaser.Get(GenJournalLine2."Salespers./Purch. Code") then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    Error(SalespersonPurchPrivacyBlockErr, GenJournalLine2."Salespers./Purch. Code");
    end;

    procedure CheckIfPrivacyBlocked()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if FindSet then begin
            repeat
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            Customer.Get("Account No.");
                            if Customer."Privacy Blocked" then
                                Error(Customer.GetPrivacyBlockedGenericErrorText(Customer));
                            if Customer.Blocked = Customer.Blocked::All then
                                Error(BlockedErr, Customer.Blocked, Customer.TableCaption, Customer."No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vendor.Get("Account No.");
                            if Vendor."Privacy Blocked" then
                                Error(Vendor.GetPrivacyBlockedGenericErrorText(Vendor));
                            if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
                                Error(BlockedErr, Vendor.Blocked, Vendor.TableCaption, Vendor."No.");
                        end;
                end;
            until Next <= 0;
        end;
    end;

    local procedure CheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; ApplyDocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine, ApplyPostingDate, ApplyDocType, ApplyDocNo, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine."Posting Date" < ApplyPostingDate then
            Error(
              Text015, GenJournalLine."Document Type", GenJournalLine."Document No.", ApplyDocType, ApplyDocNo);
    end;

    local procedure CheckJobQueueStatus(GenJnlLine: Record "Gen. Journal Line")
    begin
        if not (GenJnlLine."Job Queue Status" in ["Job Queue Status"::" ", "Job Queue Status"::Error]) then
            Error(WrongJobQueueStatus);
    end;

    local procedure ClearCurrencyCode()
    var
        BankAccount: Record "Bank Account";
    begin
        if (xRec."Bal. Account Type" = xRec."Bal. Account Type"::"Bank Account") and (xRec."Bal. Account No." <> '') then begin
            BankAccount.Get(xRec."Bal. Account No.");
            if BankAccount."Currency Code" = "Currency Code" then
                "Currency Code" := '';
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; LastGenJournalLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustApplnEntryFields(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVendApplnEntryFields(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeader(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmt(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPrepmtPost(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderApplyTo(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromSalesHeaderPayment(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeader(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmt(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPrepmtPost(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line"; UsePmtDisc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderApplyTo(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPurchHeaderPayment(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeader(ServiceHeader: Record "Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeaderApplyTo(ServiceHeader: Record "Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromServHeaderPayment(ServiceHeader: Record "Service Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromInvPostBuffer(InvoicePostBuffer: Record "Invoice Post. Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromInvPostBufferFA(InvoicePostBuffer: Record "Invoice Post. Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetCustomerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetVendorBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Vendor: Record Vendor; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetBankBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccount: Record "Bank Account"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetFAAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetFABalAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetICPartnerBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var ICPartner: Record "IC Partner")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePricesFromJobJnlLine(var GenJournalLine: Record "Gen. Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var GenJournalLine: Record "Gen. Journal Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearPostingGroups(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearBalPostingGroups(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeferralAmount(var GenJournalLine: Record "Gen. Journal Line"; var DeferralAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
    local procedure OnAfterGetVendLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverseCalculateTax(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateApplyRequirements(TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDirectPosting(var GLAccount: Record "G/L Account"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line"; AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset"; AccNo: Code[20]; xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocumentTypeAndAppliesToFields(var GenJournalLine: Record "Gen. Journal Line"; DocType: Integer; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlankJobNo(GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; ApplyDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocNoBasedOnNoSeries(var GenJournalLine: Record "Gen. Journal Line"; LastDocNo: Code[20]; NoSeriesCode: Code[20]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimensionsFromJobTaskLine(TempJobJnlLine: Record "Job Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmptyLine(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskIsSet(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocCust(GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocVend(GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountWithCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountWithVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateApplyRequirements(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenBusPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenPostingType(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBalGenProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenBusPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenPostingType(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var CheckIfFieldIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAVATSetupOnBeforeCheckGLAcc(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterAssignCustomerNo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgerEntryOnAfterAssignVendorNo(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeTestCheckPrinted(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeIncrDocNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Employee Ledger Entry");
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnUpdateLineBalanceOnAfterAssignBalanceLCY(var BalanceLCY: Decimal)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnValidateAmountOnAfterAssignAmountLCY(var AmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnValidateBalVATPctOnAfterAssignBalVATAmountLCY(var BalVATAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculateDueDate(var GenJournalLine: Record "Gen. Journal Line"; PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(var GenJournalLine: Record "Gen. Journal Line"; PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBalVATBaseAmountOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATBaseAmountOnBeforeValidateAmount(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATPctOnBeforeUpdateSalesPurchLCY(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAccountNoOnBeforeAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountNoOnAfterAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountNoOnBeforeAssignValue(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    local procedure SetLastModifiedDateTime()
    var
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        "Last Modified DateTime" := DotNet_DateTimeOffset.ConvertToUtcDateTime(CurrentDateTime);
    end;

    local procedure UpdateDocumentTypeAndAppliesTo(DocType: Integer; DocNo: Code[20])
    begin
        "Applies-to Doc. Type" := DocType;
        "Applies-to Doc. No." := DocNo;
        "Applies-to ID" := '';

        OnAfterUpdateDocumentTypeAndAppliesToFields(Rec, DocType, DocNo);

        if "Document Type" <> "Document Type"::" " then
            exit;

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            exit;

        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Payment:
                "Document Type" := "Document Type"::Invoice;
        "Applies-to Doc. Type"::"Credit Memo":
                "Document Type" := "Document Type"::Refund;
        "Applies-to Doc. Type"::Invoice,
          "Applies-to Doc. Type"::Refund:
                "Document Type" := "Document Type"::Payment;
    end;
    end;

    procedure UpdateAccountID()
    var
        GLAccount: Record "G/L Account";
    begin
        if "Account Type" <> "Account Type"::"G/L Account" then
            exit;

        if "Account No." = '' then begin
            Clear("Account Id");
            exit;
        end;

        if not GLAccount.Get("Account No.") then
            exit;

        "Account Id" := GLAccount.Id;
    end;

    local procedure UpdateAccountNo()
    var
        GLAccount: Record "G/L Account";
    begin
        if IsNullGuid("Account Id") then
            exit;

        GLAccount.SetRange(Id, "Account Id");
        if not GLAccount.FindFirst then
            exit;

        "Account No." := GLAccount."No.";
    end;


    procedure UpdateBankAccountID()
    var
        BankAccount: Record "Bank Account";
    begin
        if "Account Type" <> "Account Type"::"Bank Account" then
            exit;

        if "Account No." = '' then begin
            Clear("Account Id");
            exit;
        end;

        if not BankAccount.Get("Account No.") then
            exit;

        "Account Id" := BankAccount.SystemId;
    end;

    local procedure UpdateBankAccountNo()
    var
        BankAccount: Record "Bank Account";
    begin
        if IsNullGuid("Account Id") then
            exit;

        if not BankAccount.GetBySystemId("Account Id") then
            exit;

        "Account No." := BankAccount."No.";
    end;

    procedure UpdateCustomerID()
    var
        Customer: Record Customer;
    begin
        if "Account Type" <> "Account Type"::Customer then
            exit;

        if "Account No." = '' then begin
            Clear("Customer Id");
            exit;
        end;

        if not Customer.Get("Account No.") then
            exit;

        "Customer Id" := Customer.Id;
    end;

    local procedure UpdateCustomerNo()
    var
        Customer: Record Customer;
    begin
        if IsNullGuid("Customer Id") then
            exit;

        Customer.SetRange(Id, "Customer Id");
        if not Customer.FindFirst then
            exit;

        "Account No." := Customer."No.";
    end;

    procedure UpdateAppliesToInvoiceID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::Invoice then
            exit;

        if "Applies-to Doc. No." = '' then begin
            Clear("Applies-to Invoice Id");
            exit;
        end;

        if not SalesInvoiceHeader.Get("Applies-to Doc. No.") then
            exit;

        "Applies-to Invoice Id" := SalesInvoiceHeader.Id;
    end;

    local procedure UpdateAppliesToInvoiceNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsNullGuid("Applies-to Invoice Id") then
            exit;

        SalesInvoiceHeader.SetRange(Id, "Applies-to Invoice Id");
        if not SalesInvoiceHeader.FindFirst then
            exit;

        "Applies-to Doc. No." := SalesInvoiceHeader."No.";
    end;

    procedure UpdateGraphContactId()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        GraphIntContact: Codeunit "Graph Int. - Contact";
        GraphID: Text[250];
    begin
        if IsNullGuid("Customer Id") then
            Clear("Contact Graph Id");

        Customer.SetRange(Id, "Customer Id");
        if not Customer.FindFirst then
            Clear("Contact Graph Id");

        if not GraphIntContact.FindGraphContactIdFromCustomer(GraphID, Customer, Contact) then
            Clear("Contact Graph Id");

        "Contact Graph Id" := GraphID;
    end;

    procedure UpdateJournalBatchID()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
            exit;

        "Journal Batch Id" := GenJournalBatch.Id;
    end;

    local procedure UpdateJournalBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange(Id, "Journal Batch Id");
        if not GenJournalBatch.FindFirst then
            exit;

        "Journal Batch Name" := GenJournalBatch.Name;
    end;

    procedure UpdatePaymentMethodId()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if "Payment Method Code" = '' then begin
            Clear("Payment Method Id");
            exit;
        end;

        if not PaymentMethod.Get("Payment Method Code") then
            exit;

        "Payment Method Id" := PaymentMethod.Id;
    end;

    local procedure UpdatePaymentMethodCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if IsNullGuid("Payment Method Id") then
            exit;

        PaymentMethod.SetRange(Id, "Payment Method Id");
        if not PaymentMethod.FindFirst then
            exit;

        "Payment Method Code" := PaymentMethod.Code;
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnGenJnlLineGetVendorAccount(Vendor: Record Vendor)
    begin
    end;

    [Obsolete('Function scope will be changed to OnPrem', '15.1')]
    procedure ShowDeferralSchedule()
    begin
        if "Account Type" = "Account Type"::"Fixed Asset" then
            Error(AccTypeNotSupportedErr);

        ShowDeferrals("Posting Date", "Currency Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var GenJournalLine: Record "Gen. Journal Line"; DeferralAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSource(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;
	
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(GenJournalLine: Record "Gen. Journal Line"; var ReturnValue: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSource(var GenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer)
    begin
    end;
}

