﻿namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Consolidation;
using System.Threading;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Integration.Entity;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Intrastat;
using Microsoft.Intercompany.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using System.Automation;
using System.IO;
using System.DateTime;
using System.Environment.Configuration;
using System.Utilities;

table 81 "Gen. Journal Line"
{
    Caption = 'Gen. Journal Line';
    Permissions = tabledata "Sales Invoice Header" = r,
                  tabledata Customer = R,
                  tabledata "Cust. Ledger Entry" = R,
                  tabledata "G/L Account" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Ledger Entry" = R,
                  tabledata "Data Exch. Field" = rimd;
    DataClassification = CustomerContent;

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
                                       "Account Type"::"IC Partner", "Account Type"::Employee]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner", "Bal. Account Type"::Employee])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                Validate("Account No.", '');
                OnValidateAccountTypeOnBeforeCheckKeepDescription(Rec, xRec, CurrFieldNo);
                if not "Keep Description" then
                    Validate(Description, '');
#if not CLEAN22
                Validate("IC Partner G/L Acc. No.", '');
#endif
                Validate("IC Account No.", '');
                if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account", "Account Type"::Employee] then begin
                    Validate("Gen. Posting Type", "Gen. Posting Type"::" ");
                    Validate("Gen. Bus. Posting Group", '');
                    Validate("Gen. Prod. Posting Group", '');
                end else
                    if "Bal. Account Type" in [
                                               "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Bal. Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');
                UpdateSource();

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
                        GetTemplate();
                        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                            FieldError("Account Type");
                    end;

                Validate("Deferral Code", '');
                ClearInvCrMemoTypeFields();
            end;
        }
        field(4; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("Account Type" = const(Employee)) Employee;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Account No." <> xRec."Account No.") and not (xRec."Account No." = '') then begin
                    ClearAppliedAutomatically();
                    ClearApplication("Account Type");
                    BlankJobNo(FieldNo("Account No."));
                end;

                if xRec."Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"IC Partner"] then
                    "IC Partner Code" := '';

                if "Account No." = '' then begin
                    CleanLine();
                    exit;
                end;

                OnValidateAccountNoOnBeforeAssignValue(Rec, xRec);

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        GetGLAccount();
                    "Account Type"::Customer:
                        GetCustomerAccount();
                    "Account Type"::Vendor:
                        GetVendorAccount();
                    "Account Type"::Employee:
                        GetEmployeeAccount();
                    "Account Type"::"Bank Account":
                        GetBankAccount();
                    "Account Type"::"Fixed Asset":
                        GetFAAccount();
                    "Account Type"::"IC Partner":
                        GetICPartnerAccount();
                    "Account Type"::"Allocation Account":
                        GetAllocationAccount();
                end;

                OnValidateAccountNoOnAfterAssignValue(Rec, xRec);

                Validate("Currency Code");
                Validate("VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();

                IsHandled := false;
                OnAccountNoOnValidateOnBeforeCreateDim(Rec, IsHandled);
                if IsHandled then
                    exit;

                CreateDimFromDefaultDim(FieldNo("Account No."));

#if not CLEAN22
                Validate("IC Partner G/L Acc. No.", GetDefaultICPartnerGLAccNo());
#endif
                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
                ValidateApplyRequirements(Rec);

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        UpdateAccountID();
                    "Account Type"::Customer:
                        UpdateCustomerID();
                    "Account Type"::"Bank Account":
                        UpdateBankAccountID();
                    "Account Type"::Vendor:
                        UpdateVendorID();
                end;
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;

            trigger OnValidate()
            begin
                TestField("Posting Date");
                GLSetup.Get();
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

                ValidateDocumentDateFromPostingDate();
                ValidateCurrencyCode();

                OnValidatePostingDateOnAfterValidateCurrencyCode(Rec, xRec);

                if ("Posting Date" <> xRec."Posting Date") and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);

                ValidateApplyRequirements(Rec);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;

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
                UpdateSalesPurchLCY();
                ValidateApplyRequirements(Rec);
                ClearInvCrMemoTypeFields();
            end;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
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
                GetCurrency();
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"No Taxable VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Amount" :=
                              Round(Amount * "VAT %" / (100 + "VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
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

                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
                NonDeductibleVAT.ValidateNonDedVATPctInGenJnlLine(Rec);

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY();

                if "Deferral Code" <> '' then
                    Validate("Deferral Code");
            end;
        }
        field(11; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                               Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Bal. Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Bal. Account Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("Bal. Account Type" = const(Employee)) Employee;

            trigger OnValidate()
            begin
                if "Bal. Account No." <> xRec."Bal. Account No." then begin
                    ClearApplication("Bal. Account Type");
                    BlankJobNo(FieldNo("Bal. Account No."));
                end;

                if xRec."Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor,
                                                "Bal. Account Type"::"IC Partner"]
                then
                    "IC Partner Code" := '';

                if "Bal. Account No." = '' then begin
                    UpdateLineBalance();
                    UpdateSource();
                    Clear("Balance Account Id");
                    CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                    if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
                        "Recipient Bank Account" := '';
                    if xRec."Bal. Account No." <> '' then begin
                        ClearBalancePostingGroups();
                        "Bal. Tax Area Code" := '';
                        "Bal. Tax Liable" := false;
                        "Bal. Tax Group Code" := '';
                        ClearCurrencyCode();
                    end;
                    exit;
                end;

                ReadGLSetup();
                if GLSetup."Journal Templ. Name Mandatory" then
                    if GenJnlTemplate.Name <> "Journal Template Name" then
                        GenJnlTemplate.Get("Journal Template Name");

                OnValidateBalAccountNoOnBeforeAssignValue(Rec, xRec);

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        GetGLBalAccount();
                    "Bal. Account Type"::Customer:
                        GetCustomerBalAccount();
                    "Bal. Account Type"::Vendor:
                        GetVendorBalAccount();
                    "Bal. Account Type"::Employee:
                        GetEmployeeBalAccount();
                    "Bal. Account Type"::"Bank Account":
                        GetBankBalAccount();
                    "Bal. Account Type"::"Fixed Asset":
                        GetFABalAccount();
                    "Bal. Account Type"::"IC Partner":
                        GetICPartnerBalAccount();
                end;

                OnValidateBalAccountNoOnAfterAssignValue(Rec, xRec);

                Validate("Currency Code");
                Validate("Bal. VAT Prod. Posting Group");
                UpdateLineBalance();
                UpdateSource();
                CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                UpdateBalanceAccountId();
#if not CLEAN22
                Validate("IC Partner G/L Acc. No.", GetDefaultICPartnerGLAccNo());
#endif
                if (Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account") then
                    Validate("IC Account No.", GetDefaultICPartnerGLAccNo());
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
                AccCurrencyCode: Code[10];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateCurrencyCodeOnBeforeCheckBankAccountCurrencyCode(Rec, IsHandled);
                if not IsHandled then begin
                    if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                        if BankAcc.Get("Bal. Account No.") and (BankAcc."Currency Code" <> '') then
                            BankAcc.TestField("Currency Code", "Currency Code");

                    if "Account Type" = "Account Type"::"Bank Account" then
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
                    GetCurrency();
                    AccCurrencyCode := GetAccCurrencyCode();
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0) or
                       (("Currency Code" <> AccCurrencyCode) and (AccCurrencyCode <> ''))
                    then begin
                        OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(Rec, CurrExchRate);
                        "Currency Factor" := CurrExchRate.ExchangeRate("Posting Date", "Currency Code");
                    end;
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");

                if not CustVendAccountNosModified() then
                    if ("Currency Code" <> xRec."Currency Code") and (Amount <> 0) then
                        PaymentToleranceMgt.PmtTolGenJnl(Rec);
            end;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                ValidateAmount();
            end;
        }
        field(14; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "Debit Amount" := Round("Debit Amount", Currency."Amount Rounding Precision");
                Correction := "Debit Amount" < 0;
                if ("Credit Amount" = 0) or ("Debit Amount" <> 0) then begin
                    Amount := "Debit Amount";
                    Validate(Amount);
                end;
            end;
        }
        field(15; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';

            trigger OnValidate()
            begin
                GetCurrency();
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAmountLCY(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else begin
                    if CheckFixedCurrency() then begin
                        GetCurrency();
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
                    UpdateLineBalance();
                end;

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
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
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor;

            trigger OnValidate()
            begin
                if "Bill-to/Pay-to No." <> xRec."Bill-to/Pay-to No." then
                    "Ship-to/Order Address Code" := '';
                ReadGLSetup();
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then
                    UpdateCountryCodeAndVATRegNo("Bill-to/Pay-to No.");
            end;
        }
        field(23; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group"
            else
            if ("Account Type" = const("Fixed Asset")) "FA Posting Group";

            trigger OnValidate()
            begin
                CheckPostingGroupChange();
            end;
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateSalesPersonPurchaserCode(Rec);

                CreateDimFromDefaultDim(FieldNo("Salespers./Purch. Code"));
            end;
        }
        field(28; "Pending Approval"; Boolean)
        {
            Caption = 'Pending Approval';
            Editable = false;
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
        field(31; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;
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
            end;
        }
        field(36; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                AccType: Enum "Gen. Journal Account Type";
                AccNo: Code[20];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, IsHandled);
                if IsHandled then
                    exit;

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
                    AccType::Employee:
                        LookUpAppliesToDocEmpl(AccNo);
                end;
                SetJournalLineFieldsFromApplication();

                OnLookupAppliestoDocNoOnAfterSetJournalLineFieldsFromApplication(Rec);

                if xRec.Amount <> 0 then
                    if not PaymentToleranceMgt.PmtTolGenJnl(Rec) then
                        exit;

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID();
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
                TempGenJnlLine: Record "Gen. Journal Line" temporary;
            begin
                if SuppressCommit then
                    PaymentToleranceMgt.SetSuppressCommit(true);

                if "Applies-to Doc. No." <> xRec."Applies-to Doc. No." then
                    ClearCustVendApplnEntry();

                if ("Applies-to Doc. No." = '') and (xRec."Applies-to Doc. No." <> '') then begin
                    PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");

                    TempGenJnlLine := Rec;
                    if (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer) or
                       (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor) or
                       (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Employee)
                    then
                        CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", TempGenJnlLine);

                    OnAppliesToDocNoOnValidateOnBeforeUpdAmtToEntries(Rec, TempGenJnlLine);

                    case TempGenJnlLine."Account Type" of
                        TempGenJnlLine."Account Type"::Customer:
                            begin
                                CustLedgEntry.SetCurrentKey("Document No.");
                                CustLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    CustLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                                CustLedgEntry.SetRange(Open, true);
                                OnAppliesToDocNoOnValidateOnAfterCustLedgEntrySetFilters(Rec, CustLedgEntry, TempGenJnlLine);
                                if CustLedgEntry.FindFirst() then begin
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
                                OnAppliesToDocNoOnValidateOnAfterVendLedgEntrySetFilters(Rec, VendLedgEntry);
                                if VendLedgEntry.FindFirst() then begin
                                    if VendLedgEntry."Amount to Apply" <> 0 then begin
                                        VendLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                                    end;
                                    "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                                end;
                                "Applies-to Ext. Doc. No." := '';
                            end;
                        TempGenJnlLine."Account Type"::Employee:
                            begin
                                EmplLedgEntry.SetCurrentKey("Document No.");
                                EmplLedgEntry.SetRange("Document No.", xRec."Applies-to Doc. No.");
                                if not (xRec."Applies-to Doc. Type" = "Document Type"::" ") then
                                    EmplLedgEntry.SetRange("Document Type", xRec."Applies-to Doc. Type");
                                EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                                EmplLedgEntry.SetRange(Open, true);
                                OnAppliesToDocNoValidateOnAfterEmplLedgEntrySetFilters(Rec, EmplLedgEntry);
                                if EmplLedgEntry.FindFirst() then begin
                                    if EmplLedgEntry."Amount to Apply" <> 0 then begin
                                        EmplLedgEntry."Amount to Apply" := 0;
                                        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                                    end;
                                    "Exported to Payment File" := EmplLedgEntry."Exported to Payment File";
                                end;
                            end;
                        else
                            OnAppliesToDocNoOnValidateOnCaseElse(Rec, xRec, TempGenJnlLine);
                    end;
                    OnAppliesToDocNoOnValidateOnAfterUpdAmtToEntries(Rec, TempGenJnlLine);
                end;

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (Amount <> 0) then begin
                    if xRec."Applies-to Doc. No." <> '' then begin
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(Rec, xRec."Applies-to Doc. No.");
                        OnValidateAppliesToDocNoOnAfterDelPmtToApplnDocNo(Rec, xRec);
                    end;
                    SetApplyToAmount();
                    PaymentToleranceMgt.PmtTolGenJnl(Rec);
                    xRec.ClearAppliedGenJnlLine();
                end;

                case "Account Type" of
                    "Account Type"::Customer:
                        GetCustLedgerEntry();
                    "Account Type"::Vendor:
                        GetVendLedgerEntry();
                    "Account Type"::Employee:
                        GetEmplLedgerEntry();
                end;

                OnAppliesToDocNoOnValidateOnBeforeValidateApplyRequirements(Rec);
                ValidateApplyRequirements(Rec);
                SetJournalLineFieldsFromApplication();

                if "Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice then
                    UpdateAppliesToInvoiceID();
            end;
        }
        field(38; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                if ("Document Type" = "Document Type"::Invoice) or ("Document Type" = "Document Type"::Bill) then
                    if PaymentTerms.Get("Payment Terms Code") then
                        PaymentTerms.VerifyMaxNoDaysTillDueDate("Due Date", "Document Date", FieldCaption("Due Date"));
            end;
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
            Caption = 'Project No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateJobNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Job No." = xRec."Job No." then
                    exit;

                SourceCodeSetup.Get();
                if "Source Code" <> SourceCodeSetup."Job G/L WIP" then
                    Validate("Job Task No.", '');
                if "Job No." = '' then begin
                    CreateDimFromDefaultDim(FieldNo("Job No."));
                    exit;
                end;

                CheckAccountTypeOnJobValidation();

                CheckBalAccountNoOnJobNoValidation();

                AssignJobCurrencyCode();

                CreateDimFromDefaultDim(FieldNo("Job No."));
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
            AutoFormatExpression = Rec."Currency Code";
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

                GetCurrency();
                "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

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
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
                    Error(Text013, FieldCaption("VAT Difference"), Currency."Max. VAT Difference Allowed");

                "VAT Amount (LCY)" := CalcVATAmountLCY();
                "VAT Base Amount (LCY)" := "Amount (LCY)" - "VAT Amount (LCY)";
                NonDeductibleVAT.ValidateNonDedVATPctInGenJnlLine(Rec);

                UpdateSalesPurchLCY();

                if JobTaskIsSet() then begin
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
                                AdjustDueDate(PaymentTerms.CalculateMaxDueDate("Document Date"));
                                IsHandled := false;
                                OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(Rec, PaymentTerms, IsHandled);
                                if not IsHandled then
                                    "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                                "Payment Discount %" := PaymentTerms."Discount %";
                            end else
                                "Due Date" := "Document Date";
                        "Document Type"::Bill:
                            if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                                PaymentTerms.Get("Payment Terms Code");
                                "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                                AdjustDueDate(99991231D);
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
                                    AdjustDueDate(99991231D);
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
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') and HasNoMultipleLine() then
                    ClearCustVendApplnEntry();
                SetJournalLineFieldsFromApplication();
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
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));

            trigger OnValidate()
            begin
                UpdateJournalBatchID();
            end;
        }
        field(52; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(53; "Recurring Method"; Enum "Gen. Journal Recurring Method")
        {
            BlankZero = true;
            Caption = 'Recurring Method';

            trigger OnValidate()
            begin
                if "Recurring Method" in
                   ["Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance"]
                then
                    TestField("Currency Code", '');
                UpdateSalesPurchLCY();

                CheckRecurringDimensionsAndFilters();
                ShowSetDimFiltersNotification();
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
            CalcFormula = sum("Gen. Jnl. Allocation".Amount where("Journal Template Name" = field("Journal Template Name"),
                                                                   "Journal Batch Name" = field("Journal Batch Name"),
                                                                   "Journal Line No." = field("Line No.")));
            Caption = 'Allocated Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';

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
                CheckVATInAlloc();
                if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
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
                                       "Account Type"::"IC Partner", "Account Type"::Employee]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset",
                                            "Bal. Account Type"::"IC Partner", "Bal. Account Type"::Employee])
                then
                    Error(
                      Text000,
                      FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));

                ReadGLSetup();
                if GLSetup."Journal Templ. Name Mandatory" then
                    if GenJnlTemplate.Name <> "Journal Template Name" then
                        GenJnlTemplate.Get("Journal Template Name");

                OnValidateBalAccountTypeOnBeforeSetBalAccountNo(Rec, xRec);

                Validate("Bal. Account No.", '');
#if not CLEAN22
                Validate("IC Partner G/L Acc. No.", '');
#endif
                Validate("IC Account No.", '');
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account", "Bal. Account Type"::Employee]
                then begin
                    Validate("Bal. Gen. Posting Type", "Bal. Gen. Posting Type"::" ");
                    Validate("Bal. Gen. Bus. Posting Group", '');
                    Validate("Bal. Gen. Prod. Posting Group", '');
                end else
                    if "Account Type" in [
                                          "Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account", "Account Type"::"Fixed Asset"]
                    then
                        Validate("Payment Terms Code", '');

                UpdateSource();
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
                    GetTemplate();
                    if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
                        FieldError("Bal. Account Type");
                end;
                ClearInvCrMemoTypeFields();
            end;
        }
        field(64; "Bal. Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Bal. Gen. Posting Type';

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
                if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
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
                GetCurrency();
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                    "Bal. VAT Calculation Type"::"Reverse Charge VAT",
                    "Bal. VAT Calculation Type"::"No Taxable VAT":
                        begin
                            "Bal. VAT Amount" :=
                              Round(-Amount * "Bal. VAT %" / (100 + "Bal. VAT %"), Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
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
                NonDeductibleVAT.ValidateBalNonDedVATPctInGenJnlLine(Rec);

                OnValidateVATPctOnBeforeUpdateSalesPurchLCY(Rec, Currency);
                UpdateSalesPurchLCY();
            end;
        }
        field(69; "Bal. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
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

                GetCurrency();
                "Bal. VAT Amount" :=
                  Round("Bal. VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

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
                    Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
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
                NonDeductibleVAT.ValidateBalNonDedVATPctInGenJnlLine(Rec);

                UpdateSalesPurchLCY();
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "VAT Base Amount" := Round("VAT Base Amount", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT",
                  "VAT Calculation Type"::"No Taxable VAT":
                        Amount :=
                          Round(
                            "VAT Base Amount" * (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Bal. VAT Base Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                "Bal. VAT Base Amount" := Round("Bal. VAT Base Amount", Currency."Amount Rounding Precision");
                case "Bal. VAT Calculation Type" of
                    "Bal. VAT Calculation Type"::"Normal VAT",
                  "Bal. VAT Calculation Type"::"Reverse Charge VAT",
                  "Bal. VAT Calculation Type"::"No Taxable VAT":
                        Amount :=
                          Round(
                            -"Bal. VAT Base Amount" * (1 + "Bal. VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
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
                GLSetup.Get();
                GLSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");

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
                    UpdateSource()
                else
                    "Source No." := '';
            end;
        }
        field(79; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Source Type" = const(Employee)) Employee;

            trigger OnValidate()
            begin
                if ("Account Type" <> "Account Type"::"G/L Account") and ("Account No." <> '') or
                   ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '')
                then
                    UpdateSource();
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

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
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
                IsHandled := false;
                OnBeforeValidateVATProdPostingGroup(Rec, IsHandled);
                if IsHandled then
                    exit;

                CheckEmptyVATProdPostingGroup();

                CheckVATInAlloc();

                "VAT %" := 0;
                "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
                        GetVATPostingSetup("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                        "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Normal VAT",
                            "VAT Calculation Type"::"No Taxable VAT":
                                "VAT %" := VATPostingSetup."VAT+EC %";
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

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    UpdatePricesFromJobJnlLine();
                end;
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
            var
                IsHandled: Boolean;
            begin
                if "Bal. Account Type" in
                   ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Bank Account"]
                then
                    TestField("Bal. VAT Prod. Posting Group", '');

                "Bal. VAT %" := 0;
                "Bal. VAT Calculation Type" := "Bal. VAT Calculation Type"::"Normal VAT";
                IsHandled := false;
                OnValidateBalVATProdPostingGroupOnBeforeBalVATCalculationCheck(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then begin
                        GetVATPostingSetup("Bal. VAT Bus. Posting Group", "Bal. VAT Prod. Posting Group");
                        "Bal. VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                        case "Bal. VAT Calculation Type" of
                            "Bal. VAT Calculation Type"::"Normal VAT",
                          "Bal. VAT Calculation Type"::"No Taxable VAT":
                                "Bal. VAT %" := VATPostingSetup."VAT+EC %";
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
            TableRelation = if ("Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."));
        }
        field(111; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(112; "Bal. VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
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
        field(114; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
        field(116; "IC Partner G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner G/L Acc. No.';
            TableRelation = "IC G/L Account";
#if not CLEAN22
            ObsoleteReason = 'This field will be replaced by IC Account No.';
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteReason = 'Replaced by IC Account No.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            var
                ICGLAccount: Record "IC G/L Account";
            begin
                if "Journal Template Name" <> '' then
                    if "IC Partner G/L Acc. No." <> '' then begin
                        GetTemplate();
                        GenJnlTemplate.TestField(Type, GenJnlTemplate.Type::Intercompany);
                        if ICGLAccount.Get("IC Partner G/L Acc. No.") then
                            ICGLAccount.TestField(Blocked, false);
                    end;

                Rec."IC Account Type" := Rec."IC Account Type"::"G/L Account";
                Rec."IC Account No." := Rec."IC Partner G/L Acc. No.";
            end;
#endif
        }
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            Editable = false;
        }
        field(118; "Sell-to/Buy-from No."; Code[20])
        {
            Caption = 'Sell-to/Buy-from No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor;

            trigger OnValidate()
            begin
                ReadGLSetup();
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Before Pmt. Disc.';
            Editable = false;
        }
        field(126; "Orig. Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
        }
        field(127; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
        }
        field(128; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = true;

            trigger OnValidate()
            begin
                InitVATDateIfEmpty();
            end;
        }
        field(130; "IC Account Type"; Enum "IC Journal Account Type")
        {
            Caption = 'IC Account Type';
        }
        field(131; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
            TableRelation =
            if ("IC Account Type" = const("G/L Account")) "IC G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Account No."), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Bal. Account No."), Blocked = const(false));

#if not CLEAN22
            trigger OnValidate()
            begin
                if Rec."IC Account Type" = Rec."IC Account Type"::"G/L Account" then
                    Rec."IC Partner G/L Acc. No." := Rec."IC Account No.";
            end;
#endif
        }
        field(160; "Job Queue Status"; Enum "Document Job Queue Status")
        {
            Caption = 'Job Queue Status';
            Editable = false;
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
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                UpdatePaymentMethodId();
            end;
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
        }
        field(175; "Invoice Received Date"; Date)
        {


            trigger OnValidate()
            begin
                if (Rec."Invoice Received Date" <> 0D) and
                   (("Account Type" = "Account Type"::Vendor) or ("Bal. Account Type" = "Bal. Account Type"::Vendor))
                then
                    TestField("Document Type", "Document Type"::Invoice);
            end;
        }
        field(180; "Keep Description"; Boolean)
        {
            Caption = 'Keep Description';
            Editable = false;
        }
        field(288; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Account No."))
            else
            if ("Account Type" = const(Employee)) Employee."No." where("Employee No. Filter" = field("Account No."))
            else
            if ("Bal. Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Bal. Account No."))
            else
            if ("Bal. Account Type" = const(Vendor)) "Vendor Bank Account".Code where("Vendor No." = field("Bal. Account No."))
            else
            if ("Bal. Account Type" = const(Employee)) Employee."No." where("Employee No. Filter" = field("Bal. Account No."));
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
            CalcFormula = exist("Payment Jnl. Export Error Text" where("Journal Template Name" = field("Journal Template Name"),
                                                                        "Journal Batch Name" = field("Journal Batch Name"),
                                                                        "Journal Line No." = field("Line No.")));
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
                Rec.ShowDimensions();
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
        field(1000; "Remit-to Code"; Code[20])
        {
            Caption = 'Remit-to Code';
            TableRelation = "Remit Address".Code where("Vendor No." = field("Sell-to/Buy-from No."));
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Job Task No." <> xRec."Job Task No." then
                    Validate("Job Planning Line No.", 0);
                if "Job Task No." = '' then begin
                    ClearJobRelatedAmounts();
                    exit;
                end;

                OnValidateJobTaskNoOnBeforeJobTaskIsSet(Rec);
                if JobTaskIsSet() then begin
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
            Caption = 'Project Unit Price (LCY)';
            Editable = false;
        }
        field(1003; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Total Price (LCY)';
            Editable = false;
        }
        field(1004; "Job Quantity"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
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
            Caption = 'Project Unit Cost (LCY)';
            Editable = false;
        }
        field(1006; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Line Discount %';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount %", "Job Line Discount %");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1007; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Project Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Discount Amount (LCY)", "Job Line Disc. Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1008; "Job Unit Of Measure Code"; Code[10])
        {
            Caption = 'Project Unit Of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(1009; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Type';

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
            Caption = 'Project Unit Price';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
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
            Caption = 'Project Total Price';
            Editable = false;
        }
        field(1012; "Job Unit Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 2;
            Caption = 'Project Unit Cost';
            Editable = false;
        }
        field(1013; "Job Total Cost"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Total Cost';
            Editable = false;
        }
        field(1014; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            Caption = 'Project Line Discount Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
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
            Caption = 'Project Line Amount';

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
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
            Caption = 'Project Total Cost (LCY)';
            Editable = false;
        }
        field(1017; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            Caption = 'Project Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine();
                    TempJobJnlLine.Validate("Line Amount (LCY)", "Job Line Amount (LCY)");
                    UpdatePricesFromJobJnlLine();
                end;
            end;
        }
        field(1018; "Job Currency Factor"; Decimal)
        {
            Caption = 'Project Currency Factor';
        }
        field(1019; "Job Currency Code"; Code[10])
        {
            Caption = 'Project Currency Code';

            trigger OnValidate()
            begin
                if ("Job Currency Code" <> xRec."Job Currency Code") or ("Job Currency Code" <> '') then
                    if JobTaskIsSet() then begin
                        CreateTempJobJnlLine();
                        UpdatePricesFromJobJnlLine();
                    end;
            end;
        }
        field(1020; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';

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
                OnLookupJobPlanningLineNoOnAfterJobPlanningLineSetFilter(JobPlanningLine, Rec);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobPlanningLineNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                    JobPlanningLine.TestField("No.", "Account No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine.ConvertToJobLineType();
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - "Job Quantity");
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Remaining Qty.';
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
            TableRelation = if ("Account Type" = const(Customer)) "SEPA Direct Debit Mandate" where("Customer No." = field("Account No."));

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
        field(1300; "Linked Table ID"; Integer)
        {
            Caption = 'Linked Table ID';
            Editable = false;
        }
        field(1301; "Linked System ID"; Guid)
        {
            Caption = 'Linked System ID';
            Editable = false;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                DeferralUtilities: Codeunit "Deferral Utilities";
                DeferralPostDate: Date;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDeferralCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Deferral Code" <> '' then
                    if Rec."Account Type" = Rec."Account Type"::"Allocation Account" then begin
                        Rec.TestField("Account No.");
                        if not GenJournalAllocAccMgt.VerifyAllGLAccountsUsed(Rec) then
                            Error(MustUseAllGLAccountsAsDestinationAccountsAllocAccErr);
                    end else
                        Rec.TestField("Account Type", "Account Type"::"G/L Account");
                DeferralUtilities.CheckDeferralConditionForGenJournal(Rec);
                DeferralPostDate := GetDeferralPostDate();

                DeferralUtilities.DeferralCodeOnValidate(
                    "Deferral Code", DeferralDocType::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name",
                    0, '', "Line No.", GetDeferralAmount(), DeferralPostDate, Description, "Currency Code");
            end;
        }
        field(1701; "Deferral Line No."; Integer)
        {
            Caption = 'Deferral Line No.';
        }
        field(2676; "Selected Alloc. Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2677; "Alloc. Acc. Modified by User"; Boolean)
        {
            Caption = 'Allocation Account Distributions Modified';
            FieldClass = FlowField;
            CalcFormula = exist(Microsoft.Finance.AllocationAccount."Alloc. Acc. Manual Override" where("Parent System Id" = field(SystemId), "Parent Table Id" = const(Database::"Gen. Journal Line")));
        }
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Posting Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCampaignNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                CreateDimFromDefaultDim(FieldNo("Campaign No."));
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

                if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then
                    TestField("Insurance No.", '');
                if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                    TestField("Maintenance Code", '');
                GetFAVATSetup();
                GetFAAddCurrExchRate();
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
                GetFAVATSetup();
                GetFAAddCurrExchRate();
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
        field(5703; "Reverse Date Calculation"; DateFormula)
        {
            Caption = 'Reverse Date Calculation';

            trigger OnValidate()
            var
                GenJournalTemplate: Record "Gen. Journal Template";
            begin
                if Format("Reverse Date Calculation") = '' then
                    exit;

                GenJournalTemplate.Get("Journal Template Name");
                GenJournalTemplate.TestField(Recurring);
                if not ("Recurring Method" in ["Recurring Method"::"RF Reversing Fixed", "Recurring Method"::"RV Reversing Variable", "Recurring Method"::"RB Reversing Balance"]) then
                    FieldError("Recurring Method");
            end;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                GetCurrency();
                NonDeductibleVAT.Calculate(Rec, Currency);
            end;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Base';
            Editable = false;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6203; "Non-Deductible VAT Base LCY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Base LCY';
            Editable = false;
        }
        field(6204; "Non-Deductible VAT Amount LCY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Amount LCY';
            Editable = false;
        }
        field(6205; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Base ACY';
            Editable = false;
        }
        field(6206; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Amount ACY';
            Editable = false;
        }
        field(6207; "FA G/L Account No."; Code[20])
        {
            Caption = 'FA G/L Account No.';
            Editable = false;
        }
        field(6208; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
        field(6209; "Bal. Non-Ded. VAT %"; Decimal)
        {
            Caption = 'Bal. Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                GetCurrency();
                NonDeductibleVAT.CalculateBalAcc(Rec, Currency);
            end;
        }
        field(6210; "Bal. Non-Ded. VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Base';
            Editable = false;
        }
        field(6211; "Bal. Non-Ded. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6212; "Bal. Non-Ded. VAT Base LCY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Base LCY';
            Editable = false;
        }
        field(6213; "Bal. Non-Ded. VAT Amount LCY"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Bal. Non-Deductible VAT Amount LCY';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(8001; "Account Id"; Guid)
        {
            Caption = 'Account Id';
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                UpdateAccountNo();
            end;
        }
        field(8002; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateCustomerNo();
            end;
        }
        field(8003; "Applies-to Invoice Id"; Guid)
        {
            Caption = 'Applies-to Invoice Id';
            TableRelation = "Sales Invoice Entity Aggregate".Id;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                UpdateAppliesToInvoiceNo();
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
            TableRelation = "Gen. Journal Batch".SystemId;

            trigger OnValidate()
            begin
                UpdateJournalBatchName();
            end;
        }
        field(8007; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".SystemId;

            trigger OnValidate()
            begin
                UpdatePaymentMethodCode();
            end;
        }
        field(8008; "Balance Account Id"; Guid)
        {
            Caption = 'Balance Account Id';
            TableRelation = "G/L Account".SystemId;

            trigger OnValidate()
            begin
                UpdateBalanceAccountNo();
            end;
        }
        field(8009; "Vendor Id"; Guid)
        {
            Caption = 'Vendor Id';
            TableRelation = Vendor.SystemId;

            trigger OnValidate()
            begin
                UpdateVendorNo();
            end;
        }
        field(10700; "Transaction No."; Integer)
        {
            BlankZero = true;
            Caption = 'Transaction No.';
        }
        field(10701; "Pmt. Discount Given/Rec. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Given/Rec. (LCY)';
            Editable = true;
        }
        field(10702; "Generate AutoInvoices"; Boolean)
        {
            Caption = 'Generate AutoInvoices';
        }
        field(10703; "AutoDoc. No."; Code[20])
        {
            Caption = 'AutoDoc. No.';
        }
        field(10704; "Payment Type"; Option)
        {
            Caption = 'Payment Type';
            OptionCaption = ' ,01,02';
            OptionMembers = " ","01","02";

            trigger OnValidate()
            begin
                if ("Payment Type" = "Payment Type"::" ") or (xRec."Payment Type" <> "Payment Type") then
                    "Statistical Code" := '';
            end;
        }
        field(10705; "Statistical Code"; Code[6])
        {
            Caption = 'Statistical Code';

            trigger OnLookup()
            var
                StatisticalCode: Record "Statistical Code";
                TariffNumber: Record "Tariff Number";
                StatisticalCodes: Page "Statistical Codes";
                TariffNumbers: Page "Tariff Numbers";
                Selected: Integer;
                PmtTypeOptions: Text[100];
                Text1100000: Label 'Select the Value from Table Statistical Code,Select the Value from Table Tariff No.';
                TariffNo: Text[6];
            begin
                TestField("Payment Type");
                if "Payment Type" = "Payment Type"::"01" then begin
                    PmtTypeOptions := Text1100000;
                    Selected := DIALOG.StrMenu(PmtTypeOptions, 1);
                    if Selected = 1 then begin
                        StatisticalCodes.LookupMode(true);
                        if StatisticalCodes.RunModal() = ACTION::LookupOK then begin
                            StatisticalCodes.GetRecord(StatisticalCode);
                            "Statistical Code" := StatisticalCode.Code;
                        end;
                    end else begin
                        TariffNumbers.LookupMode(true);
                        if TariffNumbers.RunModal() = ACTION::LookupOK then begin
                            TariffNumbers.GetRecord(TariffNumber);
                            TariffNumber."No." := DelChr(Format(TariffNumber."No."), '=', ' ');
                            TariffNo := CopyStr(Format(TariffNumber."No."), StrLen(Format(TariffNumber."No.")) - 3, 4);
                            TariffNo := PadStr('', MaxStrLen(TariffNo) - StrLen(TariffNo), '0') + TariffNo;
                            "Statistical Code" := TariffNo;
                        end;
                    end;
                end else begin
                    StatisticalCodes.LookupMode(true);
                    if StatisticalCodes.RunModal() = ACTION::LookupOK then begin
                        StatisticalCodes.GetRecord(StatisticalCode);
                        "Statistical Code" := StatisticalCode.Code;
                    end;
                end;
            end;
        }
        field(10707; "Export File Name"; Text[30])
        {
            Caption = 'Export File Name';
            Editable = false;
        }
        field(10708; "Transfer Type"; Option)
        {
            Caption = 'Transfer Type';
            Editable = false;
            OptionCaption = 'National,International,Special';
            OptionMembers = National,International,Special;
        }
        field(10709; "Sales Invoice Type"; Enum "SII Sales Invoice Type")
        {
            Caption = 'Sales Invoice Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Invoice Type" <> "Sales Invoice Type"::"F1 Invoice" then begin
                    CheckAccAndBalAccType("Account Type"::Customer);
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(10710; "Sales Cr. Memo Type"; Enum "SII Sales Credit Memo Type")
        {
            Caption = 'Sales Cr. Memo Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Cr. Memo Type" <> "Sales Cr. Memo Type"::"R1 Corrected Invoice" then begin
                    CheckAccAndBalAccType("Account Type"::Customer);
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(10711; "Sales Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Sales Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Special Scheme Code" <> "Sales Special Scheme Code"::"01 General" then
                    CheckAccAndBalAccType("Account Type"::Customer);
            end;
        }
        field(10712; "Purch. Invoice Type"; Enum "SII Purch. Invoice Type")
        {
            Caption = 'Purch. Invoice Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Invoice Type" <> "Purch. Invoice Type"::"F1 Invoice" then begin
                    CheckAccAndBalAccType("Account Type"::Vendor);
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(10713; "Purch. Cr. Memo Type"; Enum "SII Purch. Credit Memo Type")
        {
            Caption = 'Purch. Cr. Memo Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Cr. Memo Type" <> "Purch. Cr. Memo Type"::"R1 Corrected Invoice" then begin
                    CheckAccAndBalAccType("Account Type"::Vendor);
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(10714; "Purch. Special Scheme Code"; Enum "SII Purch. Special Scheme Code")
        {
            Caption = 'Purch. Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Special Scheme Code" <> "Purch. Special Scheme Code"::"01 General" then
                    CheckAccAndBalAccType("Account Type"::Vendor);
            end;
        }
        field(10715; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;

            trigger OnValidate()
            begin
                if "Correction Type" <> 0 then
                    CheckDataForCorrection();
            end;
        }
        field(10716; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                InitGenJnlLineBufferWithCustVend(TempGenJournalLine);
                case true of
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                        if SalesInvoiceHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", SalesInvoiceHeader."No.");
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                        if PurchInvHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", PurchInvHeader."No.");
                end;
            end;

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                if "Corrected Invoice No." <> '' then begin
                    CheckDataForCorrection();
                    InitGenJnlLineBufferWithCustVend(TempGenJournalLine);
                    case true of
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                            SalesInvoiceHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                            PurchInvHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                    end;
                end;
            end;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
        }
        field(10722; "ID Type"; Enum "SII ID Type")
        {
            Caption = 'ID Type';
        }
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
        }
        field(10725; "Issued By Third Party"; Boolean)
        {
            Caption = 'Issued By Third Party';
        }
        field(10726; "SII First Summary Doc. No."; Blob)
        {
            Caption = 'First Summary Doc. No.';
        }
        field(10727; "SII Last Summary Doc. No."; Blob)
        {
            Caption = 'Last Summary Doc. No.';
        }
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
        }
        field(7000001; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
        }
        field(7000003; "Pmt. Address Code"; Code[10])
        {
            Caption = 'Pmt. Address Code';
            ObsoleteReason = 'Address is taken from the fields Address, City, etc. of Customer/Vendor table.';
#if CLEAN22
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#endif
            TableRelation = if ("Account Type" = const(Customer)) "Customer Pmt. Address".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Vendor Pmt. Address".Code where("Vendor No." = field("Account No."));
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
            IncludedFields = "Debit Amount", "Credit Amount", "Document Type", "Transaction No.";
        }
        key(Key3; "Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.")
        {
        }
        key(Key4; "Document No.")
        {
            IncludedFields = "Debit Amount", "Credit Amount";
        }
        key(Key5; "Incoming Document Entry No.")
        {
        }
        key(Key6; "Document No.", "Posting Date", "Source Code")
        {
            IncludedFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
        key(Key7; "Data Exch. Entry No.")
        {
        }
        key(Key8; "Journal Batch Name", "Journal Template Name")
        {
            IncludedFields = "Balance (LCY)", Amount, "Amount (LCY)", "Transfer Type";
        }
        key(Key9; "Source Code", "Document No.", "Posting Date")
        {
            IncludedFields = "VAT Amount (LCY)", "Bal. VAT Amount (LCY)";
        }
        key(Key10; "Bal. Account No.", "Bal. Account Type")
        {
            IncludedFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(Rec);

        // Lines are deleted 1 by 1, this actually check if this is the last line in the General journal Bach
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJournalLine.Count = 1 then
            if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                ApprovalsMgmt.PreventDeletingRecordWithOpenApprovalEntry(GenJournalBatch);

        TestField("Check Printed", false);
        TestField("Exported to Payment File", false);

        IsHandled := false;
        OnDeleteOnBeforeClearCustVendApplnEntry(Rec, GenJournalBatch, GenJnlAlloc, IsHandled);
        if not IsHandled then begin
            ClearCustVendApplnEntry();
            ClearAppliedGenJnlLine();
            DeleteRelatedPaymentFileErrors();
            ClearDataExchangeEntries(false);

            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            if not GenJnlAlloc.IsEmpty() then
                GenJnlAlloc.DeleteAll();
        end;

        DeferralUtilities.DeferralCodeOnDelete(
            DeferralDocType::"G/L".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, '', "Line No.");

        Rec.Validate("Incoming Document Entry No.", 0);

        RecallSetDimFiltersNotification();
        DeleteGenJnlDimFilters();
    end;

    trigger OnInsert()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJnlAlloc.LockTable();
        LockTable();

        if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            ApprovalsMgmt.PreventInsertRecIfOpenApprovalEntryExist(GenJournalBatch);

        SetLastModifiedDateTime();

        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        "Copy VAT Setup to Jnl. Lines" := GenJnlBatch."Copy VAT Setup to Jnl. Lines";
        "Posting No. Series" := GenJnlBatch."Posting No. Series";
        "Check Printed" := false;
        if "Source Code" = '' then
            "Source Code" := GenJnlTemplate."Source Code";

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");

        InitVATDateIfEmpty();

        if ("Bank Payment Type" = "Bank Payment Type"::"Electronic Payment") and ("Account Type" = "Account Type"::Vendor) then
            ElectPmtMgmt.GetTransferType("Account No.", Amount, "Transfer Type", false);
        if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
            ShowSetDimFiltersNotification();
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        CheckJobQueueStatus(Rec);

        CheckOpenApprovalEntryExistForCurrentUser();

        SetLastModifiedDateTime();

        IsHandled := false;
        OnModifyOnBeforeTestCheckPrinted(Rec, IsHandled);
        if not IsHandled then
            TestField("Check Printed", false);

        if ("Bank Payment Type" = "Bank Payment Type"::"Electronic Payment") and ("Account Type" = "Account Type"::Vendor) then begin
            ElectPmtMgmt.GetTransferType("Account No.", Amount, "Transfer Type", false);
            Modify();
        end;

        if ("Applies-to ID" = '') and (xRec."Applies-to ID" <> '') and HasNoMultipleLine() then
            ClearCustVendApplnEntry();
    end;

    trigger OnRename()
    begin
        CheckJobQueueStatus(Rec);
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);

        TestField("Check Printed", false);
        TestField("Exported to Payment File", false);
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
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlTemplate: Record "Gen. Journal Template";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlBatch: Record "Gen. Journal Batch";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        GLSetup: Record "General Ledger Setup";
        Job: Record Job;
        SourceCodeSetup: Record "Source Code Setup";
        TempJobJnlLine: Record "Job Journal Line" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
        DimMgt: Codeunit DimensionManagement;
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        DeferralDocType: Enum "Deferral Document Type";
        CurrencyCode: Code[10];
        Text014: Label 'The %1 %2 has a %3 %4.\\Do you still want to use %1 %2 in this journal line?', Comment = '%1=Caption of Table Customer, %2=Customer No, %3=Caption of field Bill-to Customer No, %4=Value of Bill-to customer no.';
        TemplateFound: Boolean;
        Text015: Label 'You are not allowed to apply and post an entry to an entry with an earlier posting date.\\Instead, post %1 %2 and then apply it to %3 %4.';
        CurrencyDate: Date;
        Text016: Label '%1 must be G/L Account or Bank Account.';
        Text018: Label '%1 can only be set when %2 is set.';
        Text019: Label '%1 cannot be changed when %2 is set.';
        GLSetupRead: Boolean;
        ElectPmtMgmt: Codeunit "Elect. Pmts Management";
        Text1100100: Label '% cannot be applied, since it is included in a payment order.';
        ExportAgainQst: Label 'One or more of the selected lines have already been exported. Do you want to export them again?';
        NothingToExportErr: Label 'There is nothing to export.';
        NotExistErr: Label 'Document number %1 does not exist or is already closed.', Comment = '%1=Document number';
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        DueDateMsg: Label 'This posting date will cause an overdue payment.';
        CalcPostDateMsg: Label 'Processing payment journal lines #1##########';
        NoEntriesToVoidErr: Label 'There are no entries to void.';
        SuppressCommit: Boolean;
        AccTypeNotSupportedErr: Label 'You cannot specify a deferral code for this type of account.';
        SalespersonPurchPrivacyBlockErr: Label 'Privacy Blocked must not be true for Salesperson / Purchaser %1.', Comment = '%1 = salesperson / purchaser code.';
        BlockedErr: Label 'The Blocked field must not be %1 for %2 %3.', Comment = '%1=Blocked field value,%2=Account Type,%3=Account No.';
        BlockedEmplErr: Label 'You cannot export file because employee %1 is blocked due to privacy.', Comment = '%1 = Employee no. ';
        InvoiceForGivenIDDoesNotExistErr: Label 'Invoice for given Applies-to Invoice Id does not exist.';
        RecurringMethodsDimFilterErr: Label 'Recurring method %1 cannot be used for the line with dimension filter setup.', Comment = '%1 - Recurring Method value';
        RecurringMethodsLineDimdErr: Label 'Recurring method %1 cannot be used for the line with dimension setup.', Comment = '%1 - Recurring Method value';
        DontShowAgainActionTxt: Label 'Don''t show again.';
        SetDimFiltersActionTxt: Label 'Set dimension filters.';
        SetDimFiltersMessageTxt: Label 'Dimension filters are not set for one or more lines that use the BD Balance by Dimension or RBD Reversing Balance by Dimension options. Do you want to set the filters?';
        IncorrectAccTypeErr: Label '%1 or %2 must be a %3.', Comment = '%1=Account Type,%2=Balance Account Type,%3=Customer or Vendor';
        OneOrAnotherTok: Label '%1 or %2', Comment = 'Customer or Vendor';
        SpecialSymbolsTok: Label '=|&@()<>', Locked = true;
        MustUseAllGLAccountsAsDestinationAccountsAllocAccErr: Label 'To use Allocation Accounts in combination with deferrals, the selected Allocation Account must have only G/L Accounts as destination types, no other types are allowed.';
        CannotChangePostingGroupForAccountTypeErr: Label 'Posting group cannot be changed for Account Type %1.', Comment = '%1 - account type';
        RestrictLineUsageDetailsTxt: Label 'The restriction was imposed because the line requires approval.';
        RestrictBatchUsageDetailsTxt: Label 'The restriction was imposed because the journal batch requires approval.';

    protected var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        HideValidationDialog: Boolean;
        SkipTaxCalculation: Boolean;

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

    procedure GetSIIFirstSummaryDocNo(): Text
    var
        InStreamObj: InStream;
        SIISummaryDocNoText: Text;
    begin
        CalcFields("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateInStream(InStreamObj, TextEncoding::UTF8);
        InStreamObj.ReadText(SIISummaryDocNoText);
        exit(SIISummaryDocNoText);
    end;

    procedure GetSIILastSummaryDocNo(): Text
    var
        InStreamObj: InStream;
        SIISummaryDocNoText: Text;
    begin
        CalcFields("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateInStream(InStreamObj, TextEncoding::UTF8);
        InStreamObj.ReadText(SIISummaryDocNoText);
        exit(SIISummaryDocNoText);
    end;

    procedure SetSIIFirstSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        Clear("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    procedure SetSIILastSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        Clear("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    local procedure InitVATDateIfEmpty()
    begin
        if "VAT Reporting Date" = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
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

#if not CLEAN22
    [Obsolete('Renaming the global procedure to GetSkipTaxCalculation():Boolean', '22.0')]
    procedure CanCalculateTax(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;
#endif

    procedure GetSkipTaxCalculation(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;

    procedure SetSkipTaxCalulation(Skip: Boolean)
    begin
        SkipTaxCalculation := Skip;
    end;

    procedure UpdateLineBalance()
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
        case true of
            ("Account No." <> '') and ("Bal. Account No." <> ''):
                "Balance (LCY)" := 0;
            "Bal. Account No." <> '':
                "Balance (LCY)" := -"Amount (LCY)";
            else
                "Balance (LCY)" := "Amount (LCY)";
        end;

        OnUpdateLineBalanceOnAfterAssignBalanceLCY("Balance (LCY)", Rec);

        Clear(GenJnlAlloc);
        GenJnlAlloc.UpdateAllocations(Rec);
        OnUpdateLineBalanceOnAfterUpdateAllocations(Rec);

        UpdateSalesPurchLCY();

        if ("Deferral Code" <> '') and (Amount <> xRec.Amount) and ((Amount <> 0) and (xRec.Amount <> 0)) then
            Validate("Deferral Code");
    end;

    procedure SetUpNewLine(LastGenJnlLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpNewLine(GenJnlTemplate, GenJnlBatch, GenJnlLine, LastGenJnlLine, GLSetupRead, Balance, BottomLine, IsHandled, Rec);
        if IsHandled then
            exit;

        GenJnlTemplate.Get("Journal Template Name");
        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if GenJnlLine.FindFirst() then begin
            "Posting Date" := LastGenJnlLine."Posting Date";
            "Document Date" := LastGenJnlLine."Posting Date";
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
            "Document No." := LastGenJnlLine."Document No.";
            "Transaction No." := LastGenJnlLine."Transaction No.";
            IsHandled := false;
            OnSetUpNewLineOnBeforeIncrDocNo(GenJnlLine, LastGenJnlLine, Balance, BottomLine, IsHandled, Rec, GenJnlBatch);
            if BottomLine and not IsHandled and (Balance - LastGenJnlLine."Balance (LCY)" = 0) and not LastGenJnlLine.EmptyLine() then
                if GenJnlTemplate."Force Doc. Balance" then
                    "Document No." := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", Rec."Posting Date", "Document No.")
                else
                    if "Transaction No." > 0 then
                        "Transaction No." := "Transaction No." + 1;
        end else begin
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
            IsHandled := false;
            OnSetUpNewLineOnBeforeSetDocumentNo(GenJnlLine, LastGenJnlLine, Balance, BottomLine, IsHandled, Rec);
            if not IsHandled then
                if GenJnlBatch."No. Series" <> '' then
                    "Document No." := NoSeries.PeekNextNo(GenJnlBatch."No. Series", "Posting Date");
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

        IsHandled := false;
        OnSetUpNewLineOnBeforeSetBalAccount(GenJnlLine, LastGenJnlLine, Balance, IsHandled, GenJnlTemplate, GenJnlBatch, BottomLine, Rec, CurrFieldNo);
        if not IsHandled then begin
            "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
               ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
            then
                "Account Type" := "Account Type"::"G/L Account";
            Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
            Description := '';
            OnSetupNewLineOnBeforeSuggestBalancingAmount(Rec, GenJnlBatch, CurrFieldNo);
            if GenJnlBatch."Suggest Balancing Amount" then
                SuggestBalancingAmount(LastGenJnlLine, BottomLine);
        end;

        UpdateJournalBatchID();

        OnAfterSetupNewLine(Rec, GenJnlTemplate, GenJnlBatch, LastGenJnlLine, Balance, BottomLine);
    end;

    procedure InitNewLine(PostingDate: Date; DocumentDate: Date; VATDate: Date; PostingDescription: Text[100]; ShortcutDim1Code: Code[20]; ShortcutDim2Code: Code[20]; DimSetID: Integer; ReasonCode: Code[10])
    begin
        Init();
        "Posting Date" := PostingDate;
        "Document Date" := DocumentDate;
        if VATDate = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date")
        else
            "VAT Reporting Date" := VATDate;
        Description := PostingDescription;
        "Shortcut Dimension 1 Code" := ShortcutDim1Code;
        "Shortcut Dimension 2 Code" := ShortcutDim2Code;
        "Dimension Set ID" := DimSetID;
        "Reason Code" := ReasonCode;
        OnAfterInitNewLine(Rec);
    end;

    local procedure InitGenJnlLineBufferWithCustVend(var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        TempGenJournalLine.Init();
        case true of
            "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Account Type";
                    TempGenJournalLine."Account No." := "Account No.";
                end;
            "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Bal. Account Type";
                    TempGenJournalLine."Account No." := "Bal. Account No.";
                end;
        end;
    end;

    local procedure CheckAccountTypeOnJobValidation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountTypeOnJobValidation(IsHandled, Rec);
        if IsHandled then
            exit;

        TestField("Account Type", "Account Type"::"G/L Account");
    end;

    procedure CheckDocNoOnLines()
    var
        GenJnlBatchLocal: Record "Gen. Journal Batch";
        GenJnlLineLocal: Record "Gen. Journal Line";
        NoSeriesBatchSim: Codeunit "No. Series - Batch";
        PrevDocNo: Code[20];
        IsHandled: Boolean;
    begin
        NoSeriesBatchSim.SetSimulationMode();

        IsHandled := false;
        OnBeforeCheckDocNoOnLines(Rec, IsHandled);
        if IsHandled then
            exit;

        GenJnlLineLocal.CopyFilters(Rec);

        if not GenJnlLineLocal.FindSet() then
            exit;
        GenJnlBatchLocal.Get(GenJnlLineLocal."Journal Template Name", GenJnlLineLocal."Journal Batch Name");
        if GenJnlBatchLocal."No. Series" = '' then
            exit;

        PrevDocNo := '';
        repeat
            if PrevDocNo <> GenJnlLineLocal."Document No." then
                if GenJnlLineLocal."Document No." <> NoSeriesBatchSim.GetNextNo(GenJnlBatchLocal."No. Series", "Posting Date") then // do not save state
                    NoSeriesBatchSim.TestManual(GenJnlBatchLocal."No. Series", GenJnlLineLocal."Document No.");
            PrevDocNo := GenJnlLineLocal."Document No.";
        until GenJnlLineLocal.Next() = 0;
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Obsolete('Do not use this procedure. It is for compatibility only.', '24.0')]
    procedure ObsoleteCheckDocNoBasedOnNoSeries(PrevDocNo: Code[20]; NoSeriesCode: Code[20]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocNoBasedOnNoSeries(Rec, PrevDocNo, NoSeriesCode, NoSeriesMgtInstance, IsHandled);
        if IsHandled then
            NoSeriesMgtInstance.SaveNoSeries();
    end;

    [Obsolete('This method is no longer used. Do the check directly in code instead.', '24.0')]
    procedure CheckDocNoBasedOnNoSeries(PrevDocNo: Code[20]; NoSeriesCode: Code[20]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        IsHandled: Boolean;
        DoDocumentNoTest: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocNoBasedOnNoSeries(Rec, PrevDocNo, NoSeriesCode, NoSeriesMgtInstance, IsHandled);
        if IsHandled then
            exit;

        if NoSeriesCode = '' then
            exit;

        if (PrevDocNo = '') or ("Document No." <> PrevDocNo) then begin
            if NoSeriesMgtInstance.FindNoSeriesLine(NoSeriesLine, NoSeriesCode, "Posting Date") then
                if not NoSeriesMgtInstance.IsCurrentNoSeriesLine(NoSeriesLine) then
                    NoSeriesMgtInstance.SaveNoSeries();

            DoDocumentNoTest := "Document No." <> NoSeriesMgtInstance.GetNextNo(NoSeriesCode, "Posting Date", false);
            if not DoDocumentNoTest then begin
                if NoSeries.Get(NoSeriesCode) then;
                if (NoSeriesMgtInstance.FindNoSeriesLine(NoSeriesLine, NoSeriesCode, "Posting Date")) then
                    DoDocumentNoTest := not NoSeries."Manual Nos." and not NoSeriesMgtInstance.IsCurrentNoSeriesLine(NoSeriesLine);
            end;

            if DoDocumentNoTest and not "Exported to Payment File" then begin
                NoSeriesMgtInstance.TestManualWithDocumentNo(NoSeriesCode, "Document No.");  // allow use of manual document numbers.
                NoSeriesMgtInstance.ClearNoSeriesLine();
            end;
        end;
    end;
#pragma warning restore AL0432
#endif
    procedure RenumberDocumentNo()
    var
        GenJnlLine2: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if SkipRenumberDocumentNo() then
            exit;
        TestField("Check Printed", false);

        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if GenJnlBatch."No. Series" = '' then
            exit;
        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        FirstDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := GetTempRenumberDocumentNo();
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

        if Get("Journal Template Name", "Journal Batch Name", "Line No.") then;
    end;

    local procedure SkipRenumberDocumentNo() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRenumberDocumentNo(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GuiAllowed() and not DIALOG.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true));
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line")
    var
        LastGenJnlLine: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        PrevDocNo: Code[20];
        FirstDocNo: Code[20];
        TempFirstDocNo: Code[20];
        PrecDocTypeInv: Boolean;
        First: Boolean;
        IsHandled: Boolean;
        PrevPostingDate: Date;
    begin
        IsHandled := false;
        OnBeforeRenumberDocNoOnLines(DocNo, GenJnlLine2, IsHandled);
        if IsHandled then
            exit;

        FirstDocNo := DocNo;
        GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.", "Bal. Account No.");
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlLine2.SetRange("Check Printed", false);
        LastGenJnlLine.Init();
        First := true;
        if GenJnlLine2.FindSet() then
            repeat
                if ((FirstDocNo <> GetTempRenumberDocumentNo()) and (GenJnlLine2.GetFilter("Document No.") = '')) then begin
                    Commit();
                    TempFirstDocNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", GenJnlLine2."Posting Date");
                    if (FirstDocNo <> TempFirstDocNo) and (FirstDocNo <> IncStr(TempFirstDocNo)) then begin
                        DocNo := TempFirstDocNo;
                        FirstDocNo := DocNo;
                        First := true;
                    end;
                end;
                if GenJnlLine2."Document No." = FirstDocNo then
                    exit;
                if not First and
                    ((GenJnlLine2."Document No." <> PrevDocNo) or
                      (GenJnlLine2."Posting Date" <> PrevPostingDate) or
                      ((GenJnlLine2."Document Type" = GenJnlLine2."Document Type"::Invoice) and PrecDocTypeInv) or
                    ((GenJnlLine2."Bal. Account No." <> '') and (GenJnlLine2."Document No." = ''))) and
                    not LastGenJnlLine.EmptyLine()
                then
                    DocNo := IncStr(DocNo);
                PrevDocNo := GenJnlLine2."Document No.";
                PrevPostingDate := GenJnlLine2."Posting Date";
                PrecDocTypeInv := GenJnlLine2."Document Type" = GenJnlLine2."Document Type"::Invoice;
                if GenJnlLine2."Document No." <> '' then begin
                    if GenJnlLine2."Applies-to ID" = GenJnlLine2."Document No." then
                        GenJnlLine2.RenumberAppliesToID(GenJnlLine2, GenJnlLine2."Document No.", DocNo);
                    GenJnlLine2.RenumberAppliesToDocNo(GenJnlLine2, GenJnlLine2."Document No.", DocNo);
                end;
                GenJnlLine3.Get(GenJnlLine2."Journal Template Name", GenJnlLine2."Journal Batch Name", GenJnlLine2."Line No.");
                CheckJobQueueStatus(GenJnlLine3);
                if GenJnlLine3."Document No." <> DocNo then begin
                    GenJnlLine3."Document No." := DocNo;
                    GenJnlLine3.Modify();
                    RestrictGenJournalLine(GenJnlLine3);
                    OnRenumberDocNoOnLinesOnAfterModifyGenJnlLine3(DocNo, GenJnlLine3);
                end;

                First := false;
                LastGenJnlLine := GenJnlLine2;
            until GenJnlLine2.Next() = 0;

        OnAfterRenumberDocNoOnLines(DocNo, GenJnlLine2);
    end;

    local procedure GetTempRenumberDocumentNo(): Code[20]
    begin
        exit('RENUMBERED-000000001');
    end;

    procedure RenumberAppliesToID(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        OnBeforeRenumberAppliesToID(GenJnlLine2, OriginalAppliesToID, NewAppliesToID, AccType, AccNo);
        GetAccTypeAndNo(GenJnlLine2, AccType, AccNo);
        case AccType of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetRange("Customer No.", AccNo);
                    CustLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    OnRenumberAppliesToIDOnAfterCustLedgEntrySetFilters(GenJnlLine2, AccNo, CustLedgEntry);
                    if CustLedgEntry.FindSet() then
                        repeat
                            CustLedgEntry2.Get(CustLedgEntry."Entry No.");
                            CustLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry2);
                        until CustLedgEntry.Next() = 0;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetRange("Vendor No.", AccNo);
                    VendLedgEntry.SetRange("Applies-to ID", OriginalAppliesToID);
                    OnRenumberAppliesToIDOnAfterVendLedgEntrySetFilters(GenJnlLine2, AccNo, VendLedgEntry);
                    if VendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry2.Get(VendLedgEntry."Entry No.");
                            VendLedgEntry2."Applies-to ID" := NewAppliesToID;
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry2);
                        until VendLedgEntry.Next() = 0;
                end;
            else
                exit
        end;
        GenJnlLine2."Applies-to ID" := NewAppliesToID;
        GenJnlLine2.Modify();

        OnAfterRenumberAppliesToID(GenJnlLine2, OriginalAppliesToID, NewAppliesToID, AccType, AccNo);
    end;

    procedure RenumberAppliesToDocNo(GenJnlLine2: Record "Gen. Journal Line"; OriginalAppliesToDocNo: Code[20]; NewAppliesToDocNo: Code[20])
    begin
        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlLine2.SetRange("Applies-to Doc. Type", GenJnlLine2."Document Type");
        GenJnlLine2.SetRange("Applies-to Doc. No.", OriginalAppliesToDocNo);
        GenJnlLine2.ModifyAll("Applies-to Doc. No.", NewAppliesToDocNo);
    end;

    local procedure CheckEmptyVATProdPostingGroup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmptyVATProdPostingGroup(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Bank Account"] then
            TestField("VAT Prod. Posting Group", '');
    end;

    local procedure CheckVATInAlloc()
    begin
        if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            if GenJnlAlloc.FindSet() then
                repeat
                    GenJnlAlloc.CheckVAT(Rec);
                until GenJnlAlloc.Next() = 0;
        end;
    end;

    protected procedure SetCurrencyCode(AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]) Result: Boolean
    var
        BankAcc: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCurrencyCode(Rec, AccType2, AccNo2, Result, IsHandled);
        if IsHandled then
            exit(Result);

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

    protected procedure GetCurrency()
    begin
        if "Additional-Currency Posting" =
           "Additional-Currency Posting"::"Additional-Currency Amount Only"
        then begin
            if GLSetup."Additional Reporting Currency" = '' then
                ReadGLSetup();
            CurrencyCode := GLSetup."Additional Reporting Currency";
        end else
            CurrencyCode := "Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            OnGetCurrencyOnBeforeInitRoundingPrecision(Rec, Currency);
            Currency.InitRoundingPrecision()
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

        OnAfterUpdateSource(Rec, CurrFieldNo);
    end;

    protected procedure CheckGLAcc(GLAcc: Record "G/L Account")
    begin
        OnBeforeCheckGLAcc(GLAcc, Rec);

        GLAcc.CheckGLAcc();
        if GLAcc."Direct Posting" or ("Journal Template Name" = '') or "System-Created Entry" then
            exit;
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                exit;

        CheckDirectPosting(GLAcc);

        OnAfterCheckGLAcc(Rec, GLAcc);
    end;

    protected procedure CheckICPartner(ICPartnerCode: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
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

    local procedure CheckAccAndBalAccType(AccType: Enum "Gen. Journal Account Type")
    begin
        if ("Account Type" <> AccType) and ("Bal. Account Type" <> AccType) then
            Error(
              IncorrectAccTypeErr,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"), Format(AccType));
    end;

    local procedure CheckDataForCorrection()
    begin
        TestField("Document Type", "Document Type"::"Credit Memo");
        if not (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) or
                ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]))
        then
            Error(IncorrectAccTypeErr,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"),
              StrSubstNo(OneOrAnotherTok, Format("Account Type"::Customer), Format("Account Type"::Vendor)));
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
                    else
                        OnGetFAAddCurrExchRateOnCaseElse(Rec, DeprBook, UseFAAddCurrExchRate);
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

    local procedure ClearJobRelatedAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearJobRelatedAmounts(Rec, IsHandled);
        if IsHandled then
            exit;

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
    end;

    procedure ClearCustVendApplnEntry()
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        TempEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
    begin
        OnBeforeClearCustVendApplnEntry(Rec, xRec, AccType, AccNo);
        if (xRec."Account No." <> "Account No.") or (xRec."Bal. Account No." <> "Bal. Account No.") then
            GetAccTypeAndNo(xRec, AccType, AccNo)
        else
            GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearCustApplnEntryFields();
                        TempCustLedgEntry.DeleteAll();
                        OnClearCustVendApplnEntryOnBeforeCustEntrySetApplIDSetApplId(Rec, CustLedgEntry);
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearCustApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
            AccType::Vendor:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearVendApplnEntryFields();
                        TempVendLedgEntry.DeleteAll();
                        VendEntrySetApplID.SetApplId(VendLedgEntry, TempVendLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearVendApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
            AccType::Employee:
                if xRec."Applies-to ID" <> '' then begin
                    if FindFirstEmplLedgEntryWithAppliesToID(AccNo, xRec."Applies-to ID") then begin
                        ClearEmplApplnEntryFields();
                        TempEmplLedgEntry.DeleteAll();
                        EmplEntrySetApplID.SetApplId(EmplLedgEntry, TempEmplLedgEntry, '');
                    end
                end else
                    if xRec."Applies-to Doc. No." <> '' then
                        if FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo, xRec."Applies-to Doc. No.") then begin
                            ClearEmplApplnEntryFields();
                            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                        end;
        end;

        OnAfterClearCustVendApplnEntry(Rec, xRec, AccType, AccNo);
    end;

    local procedure ClearCustApplnEntryFields()
    begin
        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        CustLedgEntry."Amount to Apply" := 0;
        if Rec."On Hold" = CustLedgEntry."On Hold" then begin
            CustLedgEntry."On Hold" := '';
            Rec."On Hold" := '';
        end;
        OnAfterClearCustApplnEntryFields(CustLedgEntry);
    end;

    local procedure ClearVendApplnEntryFields()
    begin
        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        VendLedgEntry."Amount to Apply" := 0;
        if Rec."On Hold" = VendLedgEntry."On Hold" then begin
            VendLedgEntry."On Hold" := '';
            Rec."On Hold" := '';
        end;
        OnAfterClearVendApplnEntryFields(VendLedgEntry);
    end;

    local procedure ClearEmplApplnEntryFields()
    begin
        EmplLedgEntry."Amount to Apply" := 0;

        OnAfterClearEmplApplnEntryFields(EmplLedgEntry);
    end;

    procedure CheckFixedCurrency(): Boolean
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Posting Date");

        if not CurrExchRate.FindLast() then
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
        if CurrExchRate.FindLast() then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        exit(false);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Check Printed", false);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, CurrFieldNo);
    end;

    local procedure ValidateAmount()
    var
        IsHandled: Boolean;
    begin
        GetCurrency();
        if "Currency Code" = '' then
            "Amount (LCY)" := Amount
        else
            "Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor"));
        OnValidateAmountOnAfterAssignAmountLCY("Amount (LCY)");

        Amount := Round(Amount, Currency."Amount Rounding Precision");

        IsHandled := false;
        OnValidateAmountOnBeforeCheckCreditLimit(Rec, CurrFieldNo, CustCheckCreditLimit, IsHandled);
        if not IsHandled then
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
        UpdateLineBalance();
        if "Deferral Code" <> '' then
            Validate("Deferral Code");

        UpdateApplyToAmount();

        if JobTaskIsSet() then begin
            CreateTempJobJnlLine();
            UpdatePricesFromJobJnlLine();
        end;

        OnAfterValidateAmount(Rec);
    end;

    local procedure UpdateApplyToAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateApplyToAmount(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Amount <> xRec.Amount then begin
            if ("Applies-to Doc. No." <> '') or ("Applies-to ID" <> '') then
                SetApplyToAmount();
            if (xRec.Amount <> 0) or (xRec."Applies-to Doc. No." <> '') or (xRec."Applies-to ID" <> '') then
                PaymentToleranceMgt.PmtTolGenJnl(Rec);
        end;
        if ((CurrFieldNo = fieldno(Amount)) or (CurrFieldNo = FieldNo("Amount (LCY)"))) and (Amount = 0) and (("Applies-to ID" <> '') or ("Applies-to Doc. No." <> '')) then begin
            if ("Applies-to ID" <> '') then
                Validate("Applies-to ID", '');
            if ("Applies-to Doc. No." <> '') then
                validate("Applies-to Doc. No.", '');
        end;
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        TestField("Check Printed", false);
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDimensionsOnAfterEditDimensionSet(Rec, OldDimSetID);

        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec, OldDimSetID, IsChanged);
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            JournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    procedure GetFAVATSetup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FABalAcc: Boolean;
        IsHandled: Boolean;
    begin
        if CurrFieldNo = 0 then
            exit;
        if ("Account Type" <> "Account Type"::"Fixed Asset") and
           ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
        then
            exit;
        FABalAcc := ("Bal. Account Type" = "Bal. Account Type"::"Fixed Asset");
        if not FABalAcc then begin
            ClearPostingGroups();
            "Tax Group Code" := '';
            Validate("VAT Prod. Posting Group");
        end;
        if FABalAcc then begin
            ClearBalancePostingGroups();
            "Bal. Tax Group Code" := '';
            Validate("Bal. VAT Prod. Posting Group");
        end;

        IsHandled := false;
        OnGetFAVATSetupOnBeforeCopyVATSetupToJnlLines(Rec, LocalGLAcc, FAPostingGr, IsHandled);
        if IsHandled then
            exit;

        if CopyVATSetupToJnlLines() then
            if (("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") or
                ("FA Posting Type" = "FA Posting Type"::Disposal) or
                ("FA Posting Type" = "FA Posting Type"::Maintenance)) and
               ("Posting Group" <> '')
            then
                if FAPostingGr.GetPostingGroup("Posting Group", "Depreciation Book Code") then begin
                    case "FA Posting Type" of
                        "FA Posting Type"::"Acquisition Cost":
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccount());
                        "FA Posting Type"::Disposal:
                            LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccountOnDisposal());
                        "FA Posting Type"::Maintenance:
                            LocalGLAcc.Get(FAPostingGr.GetMaintenanceExpenseAccount());
                    end;
                    OnGetFAVATSetupOnBeforeCheckGLAcc(Rec, LocalGLAcc);
                    LocalGLAcc.CheckGLAcc();
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
        SetFADeprBook: Record "FA Depreciation Book";
    begin
        OnBeforeGetFADeprBook(Rec, FANo);
        if "Depreciation Book Code" = '' then begin
            FASetup.Get();

            DefaultFADeprBook.SetRange("FA No.", FANo);
            DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

            SetFADeprBook.SetRange("FA No.", FANo);

            case true of
                DefaultFADeprBook.FindFirst():
                    "Depreciation Book Code" := DefaultFADeprBook."Depreciation Book Code";
                FADeprBook.Get(FANo, FASetup."Default Depr. Book"):
                    "Depreciation Book Code" := FASetup."Default Depr. Book";
                SetFADeprBook.Count = 1:
                    begin
                        SetFADeprBook.FindFirst();
                        "Depreciation Book Code" := SetFADeprBook."Depreciation Book Code";
                    end
                else
                    "Depreciation Book Code" := '';
            end;
        end;

        if "Depreciation Book Code" <> '' then begin
            FADeprBook.Get(FANo, "Depreciation Book Code");
            "Posting Group" := FADeprBook."FA Posting Group";
        end;

        OnAfterGetFADeprBook(Rec, FANo);
    end;

    procedure GetTemplate()
    begin
        if not TemplateFound then
            GenJnlTemplate.Get("Journal Template Name");
        TemplateFound := true;
    end;

    local procedure UpdateSalesPurchLCY()
    var
        VATAmount: Decimal;
        VATAmountLCY: Decimal;
    begin
        "Sales/Purch. (LCY)" := 0;
        if (not "System-Created Entry") and ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and (Amount <> 0) then begin
            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and
               (("Bal. Account No." <> '') or ("Recurring Method" <> "Recurring Method"::" "))
            then
                "Sales/Purch. (LCY)" := "Amount (LCY)" + "Bal. VAT Amount (LCY)";

            if ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) and ("Account No." <> '') then
                "Sales/Purch. (LCY)" := -("Amount (LCY)" - "VAT Amount (LCY)");

            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and ("Bal. Account No." = '') then begin
                CalculateVATAmount(VATAmount, VATAmountLCY);
                if VATAmountLCY <> 0 then
                    "Sales/Purch. (LCY)" := ("Amount (LCY)" + VATAmountLCY);
            end;
        end;

        OnAfterUpdateSalesPurchLCY(Rec);
    end;

    procedure LookUpAppliesToDocCust(AccNo: Code[20])
    var
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

        IsHandled := false;
        OnLookUpAppliesToDocCustOnBeforeCustLedgerEntrySetRangeOpen(Rec, IsHandled);
        if not IsHandled then
            CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Document Situation", '<>%1', CustLedgEntry."Document Situation"::"Posted BG/PO");
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            CustLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
            if CustLedgEntry.IsEmpty() then begin
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
                CustLedgEntry.SetRange("Bill No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange("Document Type");
        end;
        if Amount <> 0 then begin
            CustLedgEntry.SetRange(Positive, Amount < 0);
            if CustLedgEntry.IsEmpty() then
                CustLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocCustOnAfterSetFilters(CustLedgEntry, Rec, AccNo);

        if RunApplyCustEntriesPageLookupOk(AccNo) then begin
            OnLookUpAppliesToDocCustOnAfterApplyCustEntriesGetRecord(Rec, CustLedgEntry);
            if AccNo = '' then begin
                AccNo := CustLedgEntry."Customer No.";
                if "Bal. Account Type" = "Bal. Account Type"::Customer then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithCustLedgEntry();
            UpdateDocumentTypeAndAppliesTo(CustLedgEntry."Document Type", CustLedgEntry."Document No.");
            "Applies-to Bill No." := CustLedgEntry."Bill No.";
            OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(Rec, CustLedgEntry);
        end;
    end;

    local procedure RunApplyCustEntriesPageLookupOk(AccNo: Code[20]) Result: Boolean
    var
        ApplyCustEntries: Page "Apply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunApplyCustEntriesPageLookupOk(Rec, CustLedgEntry, AccNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ApplyCustEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
            ApplyCustEntries.GetRecord(CustLedgEntry);
            exit(true);
        end;

        exit(false);
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
        IsHandled := false;
        OnLookUpAppliesToDocVendOnBeforeVendLedgerEntrySetRangeOpen(Rec, IsHandled);
        if not IsHandled then
            VendLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            VendLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
            if VendLedgEntry.IsEmpty() then begin
                VendLedgEntry.SetRange("Document Type");
                VendLedgEntry.SetRange("Document No.");
                VendLedgEntry.SetRange("Bill No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Document Type");
        end;
        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if VendLedgEntry.IsEmpty() then
                VendLedgEntry.SetRange("Document No.");
        end;
        if Amount <> 0 then begin
            VendLedgEntry.SetRange(Positive, Amount < 0);
            if VendLedgEntry.IsEmpty() then;
            VendLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocVendOnAfterSetFilters(VendLedgEntry, Rec, AccNo);

        if RunApplyVendEntriesPageLookupOk(ApplyVendEntries, AccNo) then begin
            IsHandled := false;
            OnLookUpAppliesToDocVendOnAfterApplyVendEntriesGetRecord(Rec, GenJnlLine, GenJnlApply, PaymentToleranceMgt, VendLedgEntry, IsHandled);
            if IsHandled then
                exit;

            if AccNo = '' then begin
                AccNo := VendLedgEntry."Vendor No.";
                if "Bal. Account Type" = "Bal. Account Type"::Vendor then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            if VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::"Posted BG/PO" then
                Error(Text1100100, VendLedgEntry.Description);
            SetAmountWithVendLedgEntry();
            UpdateDocumentTypeAndAppliesTo(VendLedgEntry."Document Type", VendLedgEntry."Document No.");
            "Applies-to Bill No." := VendLedgEntry."Bill No.";
            OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(Rec, VendLedgEntry);
        end;

        OnAfterLookUpAppliesToDocVend(Rec, VendLedgEntry, CustLedgEntry, ApplyVendEntries);
    end;

    local procedure RunApplyVendEntriesPageLookupOk(var ApplyVendEntries: Page "Apply Vendor Entries"; AccNo: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunApplyVendEntriesPageLookupOk(Rec, VendLedgEntry, AccNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ApplyVendEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        if ApplyVendEntries.RunModal() = ACTION::LookupOK then begin
            ApplyVendEntries.GetRecord(VendLedgEntry);
            exit(true);
        end;

        exit(false);
    end;

    procedure LookUpAppliesToDocEmpl(AccNo: Code[20])
    var
        ApplyEmplEntries: Page "Apply Employee Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpAppliesToDocEmpl(Rec, AccNo, IsHandled);
        if IsHandled then
            exit;

        Clear(EmplLedgEntry);
        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        if AccNo <> '' then
            EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.IsEmpty() then begin
                EmplLedgEntry.SetRange("Document Type");
                EmplLedgEntry.SetRange("Document No.");
            end;
        end;
        if "Applies-to ID" <> '' then begin
            EmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Applies-to ID");
        end;
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Document Type");
        end;
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.IsEmpty() then
                EmplLedgEntry.SetRange("Document No.");
        end;
        if Amount <> 0 then begin
            EmplLedgEntry.SetRange(Positive, Amount < 0);
            if EmplLedgEntry.IsEmpty() then;
            EmplLedgEntry.SetRange(Positive);
        end;
        OnLookUpAppliesToDocEmplOnAfterSetFilters(EmplLedgEntry, Rec);

        ApplyEmplEntries.SetGenJnlLine(Rec, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyEmplEntries.SetTableView(EmplLedgEntry);
        ApplyEmplEntries.SetRecord(EmplLedgEntry);
        ApplyEmplEntries.LookupMode(true);
        if ApplyEmplEntries.RunModal() = ACTION::LookupOK then begin
            ApplyEmplEntries.GetRecord(EmplLedgEntry);
            if AccNo = '' then begin
                AccNo := EmplLedgEntry."Employee No.";
                if "Bal. Account Type" = "Bal. Account Type"::Employee then
                    Validate("Bal. Account No.", AccNo)
                else
                    Validate("Account No.", AccNo);
            end;
            SetAmountWithEmplLedgEntry();
            UpdateDocumentTypeAndAppliesTo(EmplLedgEntry."Document Type", EmplLedgEntry."Document No.");
            OnLookUpAppliesToDocEmplOnAfterUpdateDocumentTypeAndAppliesTo(Rec, EmplLedgEntry);
        end;
    end;

    procedure SetApplyToAmount()
    begin
        OnBeforeSetApplyToAmount(Rec);
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    CustLedgEntry.SetRange(Open, true);
                    OnSetApplyToAmountOnAfterCustLedgEntrySetFilters(Rec, CustLedgEntry);
                    if CustLedgEntry.FindFirst() then
                        if CustLedgEntry."Amount to Apply" = 0 then begin
                            CustLedgEntry.CalcFields("Remaining Amount");
                            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeCustEntryEdit(Rec, CustLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
                        end;
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Document No.");
                    VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    VendLedgEntry.SetRange(Open, true);
                    OnSetApplyToAmountOnAfterVendLedgEntrySetFilters(Rec, VendLedgEntry);
                    if VendLedgEntry.FindFirst() then
                        if VendLedgEntry."Amount to Apply" = 0 then begin
                            VendLedgEntry.CalcFields("Remaining Amount");
                            VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeVendEntryEdit(Rec, VendLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
                        end;
                end;
            "Account Type"::Employee:
                begin
                    EmplLedgEntry.SetCurrentKey("Document No.");
                    EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    EmplLedgEntry.SetRange("Employee No.", "Account No.");
                    EmplLedgEntry.SetRange(Open, true);
                    if EmplLedgEntry.FindFirst() then
                        if EmplLedgEntry."Amount to Apply" = 0 then begin
                            EmplLedgEntry.CalcFields("Remaining Amount");
                            EmplLedgEntry."Amount to Apply" := EmplLedgEntry."Remaining Amount";
                            OnSetApplyToAmountOnBeforeEmplEntryEdit(Rec, EmplLedgEntry);
                            CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmplLedgEntry);
                        end;
                end;
        end;
        OnAfterSetApplyToAmount(Rec);
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
                    OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine, CustLedgEntry);
                    if CustLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry);
                        until CustLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        CustLedgEntry.SetCurrentKey("Document No.");
                        CustLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            CustLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        CustLedgEntry.SetRange("Customer No.", TempGenJnlLine."Account No.");
                        CustLedgEntry.SetRange(Open, true);
                        OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine, CustLedgEntry);
                        if CustLedgEntry.FindFirst() then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry."Document No.", CustLedgEntry);
                    end;
            TempGenJnlLine."Account Type"::Vendor:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
                    VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                    VendLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    VendLedgEntry.SetRange(Open, true);
                    OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine, VendLedgEntry);
                    if VendLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry);
                        until VendLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgEntry.SetCurrentKey("Document No.");
                        VendLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> TempGenJnlLine."Applies-to Doc. Type"::" " then
                            VendLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        VendLedgEntry.SetRange("Vendor No.", TempGenJnlLine."Account No.");
                        VendLedgEntry.SetRange(Open, true);
                        OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine, VendLedgEntry);
                        if VendLedgEntry.FindFirst() then begin
                            if VendLedgEntry.FindFirst() then
                                CheckIfPostingDateIsEarlier(
                                  TempGenJnlLine, VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry."Document No.", VendLedgEntry);
                            if VendLedgEntry."Document Situation" = VendLedgEntry."Document Situation"::"Posted BG/PO" then
                                Error(Text1100100, VendLedgEntry.Description);
                        end;
                    end;
            TempGenJnlLine."Account Type"::Employee:
                if TempGenJnlLine."Applies-to ID" <> '' then begin
                    EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
                    EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                    EmplLedgEntry.SetRange("Applies-to ID", TempGenJnlLine."Applies-to ID");
                    EmplLedgEntry.SetRange(Open, true);
                    if EmplLedgEntry.FindSet() then
                        repeat
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, EmplLedgEntry."Posting Date", EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", EmplLedgEntry);
                        until EmplLedgEntry.Next() = 0;
                end else
                    if TempGenJnlLine."Applies-to Doc. No." <> '' then begin
                        EmplLedgEntry.SetCurrentKey("Document No.");
                        EmplLedgEntry.SetRange("Document No.", TempGenJnlLine."Applies-to Doc. No.");
                        if TempGenJnlLine."Applies-to Doc. Type" <> EmplLedgEntry."Applies-to Doc. Type"::" " then
                            EmplLedgEntry.SetRange("Document Type", TempGenJnlLine."Applies-to Doc. Type");
                        EmplLedgEntry.SetRange("Employee No.", TempGenJnlLine."Account No.");
                        EmplLedgEntry.SetRange(Open, true);
                        if EmplLedgEntry.FindFirst() then
                            CheckIfPostingDateIsEarlier(
                              TempGenJnlLine, EmplLedgEntry."Posting Date", EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", EmplLedgEntry);
                    end;
        end;

        OnAfterValidateApplyRequirements(TempGenJnlLine);
    end;

    local procedure UpdateCountryCodeAndVATRegNo(No: Code[20])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        OnBeforeUpdateCountryCodeAndVATRegNo(Rec, xRec, No);

        if No = '' then begin
            "Country/Region Code" := '';
            "VAT Registration No." := '';
            exit;
        end;

        ReadGLSetup();
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

        OnAfterUpdateCountryCodeAndVATRegNo(Rec, xRec, No);
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
        TempJobJnlLine.DontCheckStdCost();
        OnCreateTempJobJnlLimeOnBeforeValidateFields(TempJobJnlLine, Rec, XRec, CurrFieldNo);

        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        if CurrFieldNo <> FieldNo("Posting Date") then
            TempJobJnlLine.Validate("Posting Date", "Posting Date")
        else
            TempJobJnlLine.Validate("Posting Date", xRec."Posting Date");
        TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::"G/L Account");

        "Job Currency Factor" := 0;
        if "Job Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate()
            else
                CurrencyDate := "Posting Date";

            OnCreateTempJobJnlLineOnBeforeFindJobCurrencyFactor(Rec, CurrExchRate);
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

        UpdateAmountsOnTempJobJnlLine(TmpJobJnlOverallCurrencyFactor);

        OnAfterCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, CurrFieldNo);
    end;

    local procedure UpdateAmountsOnTempJobJnlLine(TmpJobJnlOverallCurrencyFactor: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsOnTempJobJnlLine(Rec, xRec, TempJobJnlLine, IsHandled);
        if IsHandled then
            exit;

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

    local procedure GetDeferralPostDate() DeferralPostDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralPostDate(Rec, DeferralPostDate, IsHandled);
        if IsHandled then
            exit(DeferralPostDate);

        DeferralPostDate := "Posting Date";
    end;

    procedure IsApplied() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsApplied(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

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
        if GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(GenJnlBatch.Name + '-' + GenJnlBatch.Description);
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure AdjustDueDate(MaxDate: Date)
    var
        DueDateAdjust: Codeunit "Due Date-Adjust";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if "Bill-to/Pay-to No." <> '' then
                    DueDateAdjust.SalesAdjustDueDate("Due Date", "Document Date", MaxDate, "Bill-to/Pay-to No.")
                else
                    DueDateAdjust.SalesAdjustDueDate("Due Date", "Document Date", MaxDate, "Account No.");
            "Account Type"::Vendor:
                DueDateAdjust.PurchAdjustDueDate("Due Date", "Document Date", MaxDate, "Account No.");
        end;
    end;

    procedure GetCustLedgerEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustLedgerEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::Customer) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            CustLedgEntry.SetRange(Open, true);
            OnGetCustLedgerEntryOnAfterSetFilters(Rec, CustLedgEntry);
            if not CustLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", CustLedgEntry."Customer No.");
            OnGetCustLedgerEntryOnAfterAssignCustomerNo(Rec, CustLedgEntry);

            if Amount = 0 then begin
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
    end;

    procedure GetVendLedgerEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendLedgerEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::Vendor) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            VendLedgEntry.SetRange(Open, true);
            if not VendLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", VendLedgEntry."Vendor No.");
            OnGetVendLedgerEntryOnAfterAssignVendorNo(Rec, VendLedgEntry);

            if Amount = 0 then begin
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
    end;

    procedure GetEmplLedgerEntry()
    begin
        if ("Account Type" = "Account Type"::Employee) and ("Account No." = '') and
           ("Applies-to Doc. No." <> '')
        then begin
            EmplLedgEntry.Reset();
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            EmplLedgEntry.SetRange(Open, true);
            if not EmplLedgEntry.FindFirst() then
                Error(NotExistErr, "Applies-to Doc. No.");

            Validate("Account No.", EmplLedgEntry."Employee No.");
            if Amount = 0 then begin
                EmplLedgEntry.CalcFields("Remaining Amount");

                Amount := -EmplLedgEntry."Remaining Amount";

                SetAppliesToFields(EmplLedgEntry."Document Type", EmplLedgEntry."Document No.", '');

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                if GenJnlBatch."Bal. Account No." <> '' then begin
                    "Bal. Account Type" := GenJnlBatch."Bal. Account Type";
                    Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                end else
                    Validate(Amount);
                OnAfterGetEmplLedgerEntry(Rec, EmplLedgEntry);
            end;
        end;
    end;

    protected procedure UpdateCurrencyCode(NewCurrencyCode: Code[10])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        FromCurrencyCode: Code[10];
        ToCurrencyCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCurrencyCode(Rec, NewCurrencyCode, IsHandled);
        if IsHandled then
            exit;

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

    local procedure ValidateDocumentDateFromPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDocumentDateFromPostingDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Validate("Document Date", "Posting Date");
    end;

    local procedure SetAppliesToFields(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Code[35])
    begin
        UpdateDocumentTypeAndAppliesTo(DocType, DocNo);

        if("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice) and ("Document Type" = "Document Type"::Payment) then
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

    protected procedure CheckPaymentTolerance()
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

    procedure GetDocumentBalance(var GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        DocGenJournalLine: Record "Gen. Journal Line";
    begin
        DocGenJournalLine.CopyFilters(GenJournalLine);
        DocGenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");
        if GenJnlTemplate.Get(GenJournalLine."Journal Template Name") and GenJnlTemplate."Force Doc. Balance" then begin
            DocGenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
            DocGenJournalLine.SetRange("Document Type", GenJournalLine."Document Type");
        end;
        OnGetDocumentBalanceOnBeforeCalcBalance(DocGenJournalLine, GenJnlTemplate);
        DocGenJournalLine.CalcSums("Balance (LCY)");
        exit(DocGenJournalLine."Balance (LCY)");
    end;

    procedure GetOverdueDateInteractions(var OverdueWarningText: Text): Text
    var
        DueDate: Date;
    begin
        DueDate := GetAppliesToDocDueDate();
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearDataExchangeEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Data Exch. Entry No." = 0 then
            exit;

        DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", "Data Exch. Line No.");

        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetRange("Data Exch. Entry No.", "Data Exch. Entry No.");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        if GenJournalLine.IsEmpty() or DeleteHeaderEntries then
            DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", 0);
    end;

    procedure ClearAppliedGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        if "Applies-to Doc. No." = '' then
            exit;

        IsHandled := false;
        OnBeforeModifyClearAppliedGenJnlLine(Rec, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '<>%1', "Line No.");
        GenJournalLine.SetRange("Document Type", "Applies-to Doc. Type");
        GenJournalLine.SetRange("Document No.", "Applies-to Doc. No.");
        if not GenJournalLine.IsEmpty() then begin
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
        exit(IncomingDocument.GetURL());
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

    protected procedure UpdateDescriptionFromBalAccount(Name: Text[100])
    begin
        if not IsAdHocBalAccDescription() then
            Description := Name;
    end;

    local procedure IsAdHocBalAccDescription() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsAdHocBalAccDescription(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Keep Description" then
            exit(true);

        if "Account No." <> '' then
            exit(true);

        exit(false);
    end;

    protected procedure UpdateDescription(Name: Text[100])
    begin
        if not IsAdHocDescription() then
            Description := Name;
    end;

    local procedure IsAdHocDescription() Result: Boolean
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        FixedAsset: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsAdHocDescription(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Description = '' then
            exit(false);
        if xRec."Account No." = '' then
            exit(true);

        if "Keep Description" then
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
            xRec."Account Type"::Employee:
                exit(Employee.Get(xRec."Account No.") and (Employee.FullName() <> Description));
        end;
        exit(false);
    end;

    procedure GetAppliesToDocEntryNo() Result: Integer
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
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
            AccType::Employee:
                begin
                    GetAppliesToDocEmplLedgEntry(EmplLedgEntry, AccNo);
                    exit(EmplLedgEntry."Entry No.");
                end;
        end;

        OnAfterGetAppliesToDocEntryNo(Rec, AccType, AccNo, Result);
    end;

    procedure GetAppliesToDocDueDate() Result: Date
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAppliesToDocDueDate(Rec, Result, IsHandled);
        if IsHandled then
            exit;

        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgEntry, AccNo);
                    Result := CustLedgEntry."Due Date";
                end;
            AccType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendLedgEntry, AccNo);
                    Result := VendLedgEntry."Due Date";
                end;
        end;

        OnAfterGetAppliesToDocDueDate(Rec, AccType, AccNo, Result);
    end;

    procedure GetAppliesToDocPmtDiscountDate() Result: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalAccountType: Enum "Gen. Journal Account Type";
        GenJournalAccountNo: Code[20];
    begin
        GetAccTypeAndNo(Rec, GenJournalAccountType, GenJournalAccountNo);
        case GenJournalAccountType of
            GenJournalAccountType::Customer:
                begin
                    GetAppliesToDocCustLedgEntry(CustLedgerEntry, GenJournalAccountNo);
                    Result := CustLedgerEntry."Pmt. Discount Date";
                end;
            GenJournalAccountType::Vendor:
                begin
                    GetAppliesToDocVendLedgEntry(VendorLedgerEntry, GenJournalAccountNo);
                    Result := VendorLedgerEntry."Pmt. Discount Date";
                end;
        end;

        OnAfterGetAppliesToDocPmtDiscountDate(Rec, GenJournalAccountType, GenJournalAccountNo, Result);
    end;

    local procedure GetAppliesToDocCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAppliesToDocCustLedgEntry(Rec, CustLedgEntry, AccNo, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            CustLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
            if CustLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if CustLedgEntry.FindFirst() then;
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
            VendLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
            if VendLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if VendLedgEntry.FindFirst() then;
            end;
    end;

    local procedure GetAppliesToDocEmplLedgEntry(var EmplLedgEntry: Record "Employee Ledger Entry"; AccNo: Code[20])
    begin
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        if "Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            EmplLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            if EmplLedgEntry.FindFirst() then;
        end else
            if "Applies-to ID" <> '' then begin
                EmplLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                if EmplLedgEntry.FindFirst() then;
            end;
    end;

    procedure SetJournalLineFieldsFromApplication()
    var
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
        RecBankAccount: Code[20];
    begin
        "Exported to Payment File" := false;
        GetAccTypeAndNo(Rec, AccType, AccNo);
        case AccType of
            AccType::Customer:
                if "Applies-to ID" <> '' then begin
                    if FindFirstCustLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(Rec, CustLedgEntry);
                        CustLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := CustLedgEntry.FindFirst();
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstCustLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToDocNo(Rec, CustLedgEntry);
                            "Exported to Payment File" := CustLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := CustLedgEntry."External Document No.";
                            RecBankAccount := CustLedgEntry."Recipient Bank Account";
                        end;
            AccType::Vendor:
                if "Applies-to ID" <> '' then begin
                    if FindFirstVendLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(Rec, VendLedgEntry);
                        VendLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := VendLedgEntry.FindFirst();
                        SetRecipientBankAccount(VendLedgEntry."Recipient Bank Account");
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstVendLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToDocNo(Rec, VendLedgEntry);
                            "Exported to Payment File" := VendLedgEntry."Exported to Payment File";
                            "Applies-to Ext. Doc. No." := VendLedgEntry."External Document No.";
                            RecBankAccount := VendLedgEntry."Recipient Bank Account";
                            SetRecipientBankAccount(VendLedgEntry."Recipient Bank Account");
                        end;
            AccType::Employee:
                if "Applies-to ID" <> '' then begin
                    if FindFirstEmplLedgEntryWithAppliesToID(AccNo, "Applies-to ID") then begin
                        OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToID(Rec, EmplLedgEntry);
                        EmplLedgEntry.SetRange("Exported to Payment File", true);
                        "Exported to Payment File" := EmplLedgEntry.FindFirst();
                    end
                end else
                    if "Applies-to Doc. No." <> '' then
                        if FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo, "Applies-to Doc. No.") then begin
                            OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToDocNo(Rec, EmplLedgEntry);
                            "Exported to Payment File" := EmplLedgEntry."Exported to Payment File";
                        end;
        end;
        SetApplnRecipientBankAccount(AccType, AccNo, "Applies-to Doc. No.", RecBankAccount);

        OnAfterSetJournalLineFieldsFromApplication(Rec, AccType, AccNo, xRec);
    end;

    procedure GetAccTypeAndNo(GenJnlLine2: Record "Gen. Journal Line"; var AccType: Enum "Gen. Journal Account Type"; var AccNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAccTypeAndNo(GenJnlLine2, AccType, AccNo, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine2."Bal. Account Type" in
           [GenJnlLine2."Bal. Account Type"::Customer, GenJnlLine2."Bal. Account Type"::Vendor, GenJnlLine2."Bal. Account Type"::Employee]
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
        OnFindFirstCustLedgEntryWithAppliesToIDOnAfterSetFilters(Rec, CustLedgEntry);
        exit(CustLedgEntry.FindFirst());
    end;

    local procedure FindFirstCustLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document No.", AppliestoDocNo);
        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        CustLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
        CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters(Rec, AccNo, CustLedgEntry);
        exit(CustLedgEntry.FindFirst());
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange("Applies-to ID", AppliesToID);
        VendLedgEntry.SetRange(Open, true);
        OnFindFirstVendLedgEntryWithAppliesToIDOnAfterSetFilters(Rec, VendLedgEntry);
        exit(VendLedgEntry.FindFirst());
    end;

    local procedure FindFirstVendLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", AppliestoDocNo);
        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        VendLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
        VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters(Rec, AccNo, VendLedgEntry);
        exit(VendLedgEntry.FindFirst());
    end;

    local procedure FindFirstEmplLedgEntryWithAppliesToID(AccNo: Code[20]; AppliesToID: Code[50]): Boolean
    begin
        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open);
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange("Applies-to ID", AppliesToID);
        EmplLedgEntry.SetRange(Open, true);
        exit(EmplLedgEntry.FindFirst());
    end;

    local procedure FindFirstEmplLedgEntryWithAppliesToDocNo(AccNo: Code[20]; AppliestoDocNo: Code[20]): Boolean
    begin
        EmplLedgEntry.Reset();
        EmplLedgEntry.SetCurrentKey("Document No.");
        EmplLedgEntry.SetRange("Document No.", AppliestoDocNo);
        EmplLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
        EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        exit(EmplLedgEntry.FindFirst());
    end;

    protected procedure ClearPostingGroups()
    begin
        "Gen. Posting Type" := "Gen. Posting Type"::" ";
        "Gen. Bus. Posting Group" := '';
        "Gen. Prod. Posting Group" := '';
        "VAT Bus. Posting Group" := '';
        "VAT Prod. Posting Group" := '';

        OnAfterClearPostingGroups(Rec);
    end;

    protected procedure ClearBalancePostingGroups()
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
        Reset();
        FilterGroup(2);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
    end;

    local procedure CleanLine()
    begin
        UpdateLineBalance();
        UpdateSource();
        CreateDimFromDefaultDim(0);
        if not ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]) then
            "Recipient Bank Account" := '';
        if xRec."Account No." <> '' then begin
            ClearPostingGroups();
            "Tax Area Code" := '';
            "Tax Liable" := false;
            "Tax Group Code" := '';
            "Bill-to/Pay-to No." := '';
            "Ship-to/Order Address Code" := '';
            "Sell-to/Buy-from No." := '';
            UpdateCountryCodeAndVATRegNo('');
        end;

        case "Account Type" of
            "Account Type"::"G/L Account":
                UpdateAccountID();
            "Account Type"::Customer:
                UpdateCustomerID();
            "Account Type"::"Bank Account":
                UpdateBankAccountID();
        end;

        OnAfterCleanLine(Rec, xRec);
    end;

    local procedure ReplaceDescription() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReplaceDescription(Rec, GenJnlTemplate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Bal. Account No." = '' then
            Result := true
        else begin
            GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
            Result := GenJnlBatch."Bal. Account No." <> '';
        end;
        OnAfterReplaceDescription(GenJnlBatch, Result);
    end;

    local procedure AddCustVendIC(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Boolean
    begin
        SetRange("Account Type", AccountType);
        SetRange("Account No.", AccountNo);
        if not IsEmpty() then
            exit(false);

        Reset();
        if FindLast() then;
        "Line No." += 10000;

        "Account Type" := AccountType;
        "Account No." := AccountNo;
        Insert();
        exit(true);
    end;

    local procedure AssignJobCurrencyCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignJobCurrencyCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Job.Get("Job No.");
        Job.TestBlocked();
        Rec."Job Currency Code" := Job."Currency Code";
    end;

    procedure IsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCustVendICAdded(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

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
        exit(IsPaymentJournallLineExported() or IsAppliedToVendorLedgerEntryExported());
    end;

    procedure IsPaymentJournallLineExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        OldFilterGroup: Integer;
        HasExportedLines: Boolean;
    begin
        GenJnlLine.CopyFilters(Rec);
        OldFilterGroup := GenJnlLine.FilterGroup;
        GenJnlLine.FilterGroup := 10;
        GenJnlLine.SetRange("Exported to Payment File", true);
        HasExportedLines := not GenJnlLine.IsEmpty();
        GenJnlLine.SetRange("Exported to Payment File");
        GenJnlLine.FilterGroup := OldFilterGroup;
        exit(HasExportedLines);
    end;

    procedure IsAppliedToVendorLedgerEntryExported(): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GenJnlLine.CopyFilters(Rec);

        if GenJnlLine.FindSet() then
            repeat
                if GenJnlLine.IsApplied() then begin
                    VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                    if GenJnlLine."Applies-to Doc. No." <> '' then begin
                        VendLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                        VendLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
                    end;
                    if GenJnlLine."Applies-to ID" <> '' then
                        VendLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    VendLedgerEntry.SetRange("Exported to Payment File", true);
                    if not VendLedgerEntry.IsEmpty() then
                        exit(true);
                end;

                VendLedgerEntry.Reset();
                VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                VendLedgerEntry.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
                VendLedgerEntry.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");
                VendLedgerEntry.SetRange("Exported to Payment File", true);
                if not VendLedgerEntry.IsEmpty() then
                    exit(true);
            until GenJnlLine.Next() = 0;

        exit(false);
    end;

    local procedure ClearAppliedAutomatically()
    begin
        if CurrFieldNo <> 0 then
            "Applied Automatically" := false;
    end;

    local procedure ClearApplication(AccountType: Enum "Gen. Journal Account Type")
    begin
        if not (AccountType in [AccountType::Customer, AccountType::Vendor, AccountType::Employee]) then
            exit;

        if "Applies-to ID" <> '' then
            Validate("Applies-to ID", '');
        if "Applies-to Doc. No." <> '' then
            Validate("Applies-to Doc. No.", '');
    end;

    procedure SetPostingDateAsDueDate(DueDate: Date; DateOffset: DateFormula): Boolean
    var
        NewPostingDate: Date;
    begin
        if DueDate = 0D then
            exit(false);

        NewPostingDate := CalcDate(DateOffset, DueDate);
        if NewPostingDate < WorkDate() then begin
            Validate("Posting Date", WorkDate());
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

        if GenJnlLine.FindSet() then begin
            Window.Open(CalcPostDateMsg);
            repeat
                Evaluate(EmptyDateFormula, '<0D>');
                GenJnlLine.SetPostingDateAsDueDate(GenJnlLine.GetAppliesToDocDueDate(), EmptyDateFormula);
                GenJnlLine.Modify(true);
                Window.Update(1, GenJnlLine."Document No.");
            until GenJnlLine.Next() = 0;
            Window.Close();
        end;
    end;

    procedure ImportBankStatement()
    var
        ProcessGenJnlLines: Codeunit "Process Gen. Journal  Lines";
    begin
        ProcessGenJnlLines.ImportBankStatement(Rec);

        OnAfterImportBankStatement(Rec);
    end;

    procedure ExportPaymentFile()
    var
        BankAcc: Record "Bank Account";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportPaymentFile(Rec, IsHandled);
        if IsHandled then
            exit;

        if not FindSet() then
            Error(NothingToExportErr);
        SetRange("Journal Template Name", "Journal Template Name");
        SetRange("Journal Batch Name", "Journal Batch Name");
        TestField("Check Printed", false);
        TestField("Document Type");

        IsHandled := false;
        OnExportPaymentFileOnBeforeCheckDocNoOnLines(Rec, IsHandled);
        if not IsHandled then
            CheckDocNoOnLines();
        if IsExportedToPaymentFile() then
            if not ConfirmManagement.GetResponseOrDefault(ExportAgainQst, true) then
                exit;

        OnExportPaymentFileOnBeforeRunExport(Rec);
        BankAcc.Get("Bal. Account No.");
        if BankAcc.GetPaymentExportCodeunitID() > 0 then
            CODEUNIT.Run(BankAcc.GetPaymentExportCodeunitID(), Rec)
        else
            CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", Rec);
        OnExportPaymentFileOnAfterRunExport(Rec);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
        PaymentToleranceMgt.SetSuppressCommit(SuppressCommit);
    end;

    procedure TotalExportedAmount() Result: Decimal
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTotalExportedAmount(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) then
            exit(0);
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);
        CreditTransferEntry.CalcSums("Transfer Amount");
        exit(CreditTransferEntry."Transfer Amount");
    end;

    procedure DrillDownExportedAmount()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownExportedAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) then
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

    procedure CopyDocumentFields(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                              ExtDocNo: Text[35];
                                              SourceCode: Code[10];
                                              NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;

        OnAfterCopyDocumentFields(Rec, DocType, DocNo, ExtDocNo, SourceCode, NoSeriesCode);
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

        OnAfterCopyGenJnlLineFromCustLedgEntry(CustLedgerEntry, Rec);
    end;

    procedure CopyVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Document Type" := VendorLedgerEntry."Document Type";
        Description := VendorLedgerEntry.Description;
        "Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
        "Posting Group" := VendorLedgerEntry."Vendor Posting Group";
        "Source Type" := "Source Type"::Vendor;
        "Source No." := VendorLedgerEntry."Vendor No.";

        OnAfterCopyGenJnlLineFromVendLedgEntry(VendorLedgerEntry, Rec);
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
        "VAT Amount (LCY)" := CalcVATAmountLCY();

        OnAfterCopyGenJnlLineFromGenJnlAllocation(GenJnlAlloc, Rec);
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

        OnAfterCopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader, Rec);
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

        OnAfterCopyFromIssuedReminderHeader(IssuedReminderHeader, Rec);
    end;

    procedure CopyFromIssuedReminderLine(IssuedReminderLine: Record "Issued Reminder Line")
    begin
        "Gen. Prod. Posting Group" := IssuedReminderLine."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := IssuedReminderLine."VAT Prod. Posting Group";
        "VAT Calculation Type" := IssuedReminderLine."VAT Calculation Type";
        "VAT %" := IssuedReminderLine."VAT %";
        Validate(Amount, IssuedReminderLine.Amount + IssuedReminderLine."VAT Amount");
        "VAT Amount" := IssuedReminderLine."VAT Amount";

        OnAfterCopyFromIssuedReminderLine(Rec, IssuedReminderLine);
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
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := PurchHeader."Journal Templ. Name";
        "Do Not Send To SII" := PurchHeader."Do Not Send To SII";

        if PurchHeader."Remit-to Code" <> '' then
            "Remit-to Code" := PurchHeader."Remit-to Code";

        if PurchHeader."Remit-to Code" <> '' then
            "Remit-to Code" := PurchHeader."Remit-to Code";

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
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        "Payment Method Code" := PurchHeader."Payment Method Code";
        "Generate AutoInvoices" := PurchHeader."Generate Autoinvoices" or PurchHeader."Generate Autocredit Memo";
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
        "Payment Method Code" := PurchHeader."Payment Method Code";
        "Recipient Bank Account" := PurchHeader."Vendor Bank Acc. Code";
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
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        "Due Date" := PurchHeader."Due Date";
        "Invoice Received Date" := PurchHeader."Invoice Received Date";
        "Payment Terms Code" := PurchHeader."Payment Terms Code";
        "Pmt. Discount Date" := PurchHeader."Pmt. Discount Date";
        "Payment Discount %" := PurchHeader."Payment Discount %";
        "Creditor No." := PurchHeader."Creditor No.";
        if PurchHeader."Payment Reference" <> '' then
            "Payment Reference" := PurchHeader."Payment Reference"
        else begin
            PurchasesPayablesSetup.Get();
            if PurchasesPayablesSetup."Copy Inv. No. To Pmt. Ref." then
                "Payment Reference" := PurchHeader."Vendor Invoice No.";
        end;
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
        "Your Reference" := SalesHeader."Your Reference";
        "On Hold" := SalesHeader."On Hold";
        if "Account Type" = "Account Type"::Customer then
            "Posting Group" := SalesHeader."Customer Posting Group";
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := SalesHeader."Journal Templ. Name";
        "Do Not Send To SII" := SalesHeader."Do Not Send To SII";
        "Issued By Third Party" := SalesHeader."Issued By Third Party";

        SetSIIFirstSummaryDocNo(SalesHeader.GetSIIFirstSummaryDocNo());
        SetSIILastSummaryDocNo(SalesHeader.GetSIILastSummaryDocNo());

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
        "Payment Terms Code" := SalesHeader."Payment Terms Code";
        "Payment Method Code" := SalesHeader."Payment Method Code";
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
        "Payment Method Code" := SalesHeader."Payment Method Code";
        "Recipient Bank Account" := SalesHeader."Cust. Bank Acc. Code";
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
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := ServiceHeader."Journal Templ. Name";
        "Payment Terms Code" := ServiceHeader."Payment Terms Code";
        "Payment Method Code" := ServiceHeader."Payment Method Code";
        "Correction Type" := ServiceHeader."Correction Type";
        "Corrected Invoice No." := ServiceHeader."Corrected Invoice No.";
        "Sales Invoice Type" := ServiceHeader."Invoice Type";
        "Sales Cr. Memo Type" := ServiceHeader."Cr. Memo Type";
        "Sales Special Scheme Code" := ServiceHeader."Special Scheme Code";
        "Succeeded Company Name" := ServiceHeader."Succeeded Company Name";
        "Succeeded VAT Registration No." := ServiceHeader."Succeeded VAT Registration No.";
        "Issued By Third Party" := ServiceHeader."Issued By Third Party";

        SetSIIFirstSummaryDocNo(ServiceHeader.GetSIIFirstSummaryDocNo());
        SetSIILastSummaryDocNo(ServiceHeader.GetSIILastSummaryDocNo());

        "Do Not Send To SII" := ServiceHeader."Do Not Send To SII";

        OnAfterCopyGenJnlLineFromServHeader(ServiceHeader, Rec);
    end;

    procedure CopyFromServiceHeaderApplyTo(ServiceHeader: Record "Service Header")
    begin
        "Applies-to Doc. Type" := ServiceHeader."Applies-to Doc. Type";
        "Applies-to Doc. No." := ServiceHeader."Applies-to Doc. No.";
        "Applies-to ID" := ServiceHeader."Applies-to ID";
        "Applies-to Bill No." := ServiceHeader."Applies-to Bill No.";
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
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := CustLedgEntry."Journal Templ. Name";

        OnAfterCopyGenJnlLineFromPaymentCustLedgEntry(CustLedgEntry, Rec);
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
        ReadGLSetup();
        if GLSetup."Journal Templ. Name Mandatory" then
            "Journal Template Name" := VendLedgEntry."Journal Templ. Name";

        OnAfterCopyGenJnlLineFromPaymentVendLedgEntry(VendLedgEntry, Rec);
    end;

    procedure CopyFromPaymentEmpLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        "Document No." := EmployeeLedgerEntry."Document No.";
        "Account Type" := "Account Type"::Employee;
        "Account No." := EmployeeLedgerEntry."Employee No.";
        "Shortcut Dimension 1 Code" := EmployeeLedgerEntry."Global Dimension 1 Code";
        "Shortcut Dimension 2 Code" := EmployeeLedgerEntry."Global Dimension 2 Code";
        "Dimension Set ID" := EmployeeLedgerEntry."Dimension Set ID";
        "Posting Group" := EmployeeLedgerEntry."Employee Posting Group";
        "Source Type" := "Source Type"::Employee;
        "Source No." := EmployeeLedgerEntry."Employee No.";
        "Source Currency Code" := EmployeeLedgerEntry."Currency Code";
        "System-Created Entry" := true;
        "Financial Void" := true;
        Correction := true;

        OnAfterCopyGenJnlLineFromPaymentEmplLedgEntry(EmployeeLedgerEntry, Rec);
    end;

    procedure CopyVATSetupToJnlLines(): Boolean
    begin
        if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then
            if GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                exit(GenJnlBatch."Copy VAT Setup to Jnl. Lines");
        exit("Copy VAT Setup to Jnl. Lines");
    end;

    local procedure SetAmountWithCustLedgEntry()
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetAmountWithCustLedgEntry(Rec, CustLedgEntry);

        if "Currency Code" <> CustLedgEntry."Currency Code" then
            CheckModifyCurrencyCode(GenJnlLine."Account Type"::Customer, CustLedgEntry."Currency Code");
        if Amount = 0 then begin
            CustLedgEntry.CalcFields("Remaining Amount");
            IsHandled := false;
            OnSetAmountWithCustLedgEntryOnBeforeSetAmountWithRemaining(Rec, CustLedgEntry, IsHandled);
            if not IsHandled then
                SetAmountWithRemaining(
                  PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(Rec, CustLedgEntry, 0, false),
                  CustLedgEntry."Amount to Apply", CustLedgEntry."Remaining Amount", CustLedgEntry.GetRemainingPmtDiscPossible(Rec."Posting Date"));
        end;
    end;

    local procedure SetAmountWithVendLedgEntry()
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetAmountWithVendLedgEntry(Rec, VendLedgEntry);

        if "Currency Code" <> VendLedgEntry."Currency Code" then
            CheckModifyCurrencyCode("Account Type"::Vendor, VendLedgEntry."Currency Code");
        if Amount = 0 then begin
            VendLedgEntry.CalcFields("Remaining Amount");
            IsHandled := false;
            OnSetAmountWithVendLedgEntryOnBeforeSetAmountWithRemaining(Rec, VendLedgEntry, IsHandled);
            if not IsHandled then
                SetAmountWithRemaining(
                  PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(Rec, VendLedgEntry, 0, false),
                  VendLedgEntry."Amount to Apply", VendLedgEntry."Remaining Amount", VendLedgEntry.GetRemainingPmtDiscPossible(Rec."Posting Date"));
        end;
    end;

    local procedure SetAmountWithEmplLedgEntry()
    begin
        if Amount = 0 then begin
            EmplLedgEntry.CalcFields("Remaining Amount");
            SetAmountWithRemaining(false, EmplLedgEntry."Amount to Apply", EmplLedgEntry."Remaining Amount", 0.0);
        end;
    end;

    procedure CheckModifyCurrencyCode(AccountType: Enum "Gen. Journal Account Type"; CustVendLedgEntryCurrencyCode: Code[10])
    begin
        if Amount = 0 then
            UpdateCurrencyCode(CustVendLedgEntryCurrencyCode)
        else begin
            OnCheckModifyCurrencyCodeOnBeforeCheckAgainstApplnCurrency(Rec, VendLedgEntry, CustLedgEntry, AccountType);
            GenJnlApply.CheckAgainstApplnCurrency(
              "Currency Code", CustVendLedgEntryCurrencyCode, AccountType, true);
        end;
    end;

    protected procedure SetAmountWithRemaining(CalcPmtDisc: Boolean; AmountToApply: Decimal; RemainingAmount: Decimal; RemainingPmtDiscPossible: Decimal)
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

        OnAfterSetAmountWithRemaining(Rec, CustLedgEntry);
        ValidateAmount();
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
            if DelChr(BatchFilter, '=', SpecialSymbolsTok) <> BatchFilter then
                BatchFilter := '''' + BatchFilter + '''';
            GenJournalBatch.SetFilter(Name, BatchFilter);
            GenJournalBatch.FindFirst();
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
            "Deferral Code", Enum::"Deferral Document Type"::"G/L".AsInteger(), "Journal Template Name", "Journal Batch Name", 0, '', "Line No.",
            GetDeferralAmount(), PostingDate, Description, CurrencyCode));
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

    procedure IsForGLAccount(): Boolean
    begin
        if "Account Type" = "Account Type"::"G/L Account" then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePostRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJournalLinePrintCheckRestrictions()
    begin
    end;

#if not CLEAN24
    [Obsolete('Use SimulateGetNextNo from "No. Series - Batch" instead', '24.0')]
    procedure IncrementDocumentNo(LocGenJnlBatch: Record "Gen. Journal Batch"; var LastDocNumber: Code[20])
    begin
        GenJnlTemplate.Get("Journal Template Name");
        if GenJnlTemplate."Force Doc. Balance" then
            LastDocNumber := NoSeriesBatch.SimulateGetNextNo(LocGenJnlBatch."No. Series", Rec."Posting Date", LastDocNumber)
        else
            if "Transaction No." > 0 then
                "Transaction No." := "Transaction No." + 1;
    end;
#endif
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
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        if "Journal Template Name" <> '' then
            if GenJournalTemplate.Get("Journal Template Name") then
                exit(GenJournalTemplate.Recurring);

        exit(false);
    end;

    local procedure SuggestBalancingAmount(LastGenJnlLine: Record "Gen. Journal Line"; BottomLine: Boolean)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
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

        if GenJournalLine.FindLast() then begin
            if BottomLine then begin
                GenJournalLine.SetRange("Document No.", LastGenJnlLine."Document No.");
                GenJournalLine.SetRange("Posting Date", LastGenJnlLine."Posting Date");
            end else begin
                GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
                GenJournalLine.SetRange("Posting Date", GenJournalLine."Posting Date");
            end;
            GenJournalLine.SetRange("Bal. Account No.", '');
            if GenJournalLine.FindFirst() then begin
                GenJournalLine.CalcSums(Amount);
                if GenJournalLine.Amount = 0 then
                    exit;

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
        SetDescriptionFromGLAcc(GLAcc);

        if ("Bal. Account No." = '') or
           ("Bal. Account Type" in
            ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
            "Payment Method Code" := '';
        end;
        if "Bal. Account No." = '' then
            "Currency Code" := '';
        if CopyVATSetupToJnlLines() then begin
            "Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Tax Area Code" := GLAcc."Tax Area Code";
        "Tax Liable" := GLAcc."Tax Liable";
        "Tax Group Code" := GLAcc."Tax Group Code";
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearPostingGroups();
        Validate("Deferral Code", GLAcc."Default Deferral Template Code");

        GLSetup.Get();
        if ("Currency Code" = '') or ("Currency Code" = GLSetup."LCY Code") then
            "Currency Code" := GLAcc."Source Currency Code";

        OnAfterAccountNoOnValidateGetGLAccount(Rec, GLAcc, CurrFieldNo);
    end;

    local procedure SetDescriptionFromGLAcc(GLAccount: Record "G/L Account")
    begin
        OnBeforeSetDescriptionFromGLAcc(Rec, GLAccount);

        if ReplaceDescription() and (not GLAccount."Omit Default Descr. in Jnl.") then
            UpdateDescription(GLAccount.Name)
        else
            if GLAccount."Omit Default Descr. in Jnl." then
                Description := '';
        OnAfterSetDescriptionFromGLAcc(Rec, GLAccount)
    end;

    local procedure GetGLBalAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Bal. Account No.");
        CheckGLAcc(GLAcc);
        UpdateDescriptionFromBalAccount(GLAcc.Name);
        if "Account No." = '' then
            "Currency Code" := '';
        OnGetGLBalAccountOnAfterSetDescription(Rec, GLAcc);
        if ("Account No." = '') or
           ("Account Type" in
            ["Account Type"::"G/L Account", "Account Type"::"Bank Account"])
        then begin
            "Posting Group" := '';
            "Salespers./Purch. Code" := '';
            "Payment Terms Code" := '';
        end;
        if CopyVATSetupToJnlLines() then begin
            "Bal. Gen. Posting Type" := GLAcc."Gen. Posting Type";
            "Bal. Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Bal. Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "Bal. VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
            "Bal. VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        end;
        "Bal. Tax Area Code" := GLAcc."Tax Area Code";
        "Bal. Tax Liable" := GLAcc."Tax Liable";
        "Bal. Tax Group Code" := GLAcc."Tax Group Code";
        if Rec."Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                ClearBalancePostingGroups();

        GLSetup.Get();
        if ("Currency Code" = '') or ("Currency Code" = GLSetup."LCY Code") then
            "Currency Code" := GLAcc."Source Currency Code";

        OnAfterAccountNoOnValidateGetGLBalAccount(Rec, GLAcc, CurrFieldNo);
    end;

    local procedure GetCustomerAccount()
    var
        Cust: Record Customer;
    begin
        Cust.Get("Account No.");
        OnGetCustomerAccountOnAfterCustGet(Rec, Cust, CurrFieldNo);
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Account Type", "Account No.");
        UpdateDescription(Cust.Name);
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        Cust.TestField("Payment Terms Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Cust."Currency Code";
        ClearPostingGroups();
        if "Document Type" = "Document Type"::"Credit Memo" then
            "Payment Method Code" := ''
        else begin
            Cust.TestField("Payment Method Code");
            "Payment Method Code" := Cust."Payment Method Code";
        end;
        CheckConfirmDifferentCustomerAndBillToCustomer(Cust, "Account No.");
        OnGetCustomerAccountOnBeforeValidatePaymentTermsCode(Rec, Cust, HideValidationDialog);
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetCustomerAccount(Rec, Cust, CurrFieldNo);
    end;

    local procedure CheckConfirmDifferentCustomerAndBillToCustomer(Cust: Record Customer; AccountNo: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckConfirmDifferentCustomerAndBillToCustomer(Rec, Cust, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> AccountNo) and not HideValidationDialog then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Cust.TableCaption(), Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                   Cust."Bill-to Customer No."), true)
            then
                Error('');
    end;

    local procedure GetCustomerBalAccount()
    var
        Cust: Record Customer;
    begin
        Cust.Get("Bal. Account No.");
        OnGetCustomerBalAccountOnAfterCustGet(Rec, Cust, CurrFieldNo);
        Cust.CheckBlockedCustOnJnls(Cust, "Document Type", false);
        CheckICPartner(Cust."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        UpdateDescriptionFromBalAccount(Cust.Name);
        "Payment Method Code" := Cust."Payment Method Code";
        Validate("Recipient Bank Account", Cust."Preferred Bank Account Code");
        "Posting Group" := Cust."Customer Posting Group";
        SetSalespersonPurchaserCode(Cust."Salesperson Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Cust."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Cust."Currency Code";
        CheckSetCurrencyCodeForBankCustLine(Cust);
        ClearBalancePostingGroups();
        CheckConfirmDifferentCustomerAndBillToCustomer(Cust, "Bal. Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetCustomerBalAccount(Rec, Cust, CurrFieldNo);
    end;

    local procedure CheckSetCurrencyCodeForBankCustLine(Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSetCurrencyCodeForBankCustLine(Rec, Cust, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Cust."Currency Code";
    end;

    local procedure GetVendorAccount()
    var
        Vend: Record Vendor;
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
        Vend.TestField("Payment Terms Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Account No.");
        Validate("Sell-to/Buy-from No.", "Account No.");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Vend."Currency Code";
        ClearPostingGroups();
        if "Document Type" = "Document Type"::"Credit Memo" then
            "Payment Method Code" := ''
        else begin
            Vend.TestField("Payment Method Code");
            "Payment Method Code" := Vend."Payment Method Code";
        end;
        CheckConfirmDifferentVendorAndPayToVendor(Vend, "Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetVendorAccount(Rec, Vend, CurrFieldNo);
    end;

    local procedure CheckConfirmDifferentVendorAndPayToVendor(Vend: Record Vendor; AccountNo: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckConfirmDifferentVendorAndPayToVendor(Rec, Vend, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> AccountNo) and
           not HideValidationDialog
        then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text014, Vend.TableCaption(), Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                   Vend."Pay-to Vendor No."), true)
            then
                Error('');
    end;

    local procedure GetEmployeeAccount()
    var
        Employee: Record Employee;
    begin
        Employee.Get("Account No.");
        Employee.CheckBlockedEmployeeOnJnls(false);
        UpdateDescriptionWithEmployeeName(Employee);
        "Posting Group" := Employee."Employee Posting Group";
        SetSalespersonPurchaserCode(Employee."Salespers./Purch. Code", "Salespers./Purch. Code");
        if not SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
            "Currency Code" := Employee."Currency Code";
        ClearPostingGroups();

        OnAfterAccountNoOnValidateGetEmployeeAccount(Rec, Employee);
    end;

    local procedure GetVendorBalAccount()
    var
        Vend: Record Vendor;
    begin
        Vend.Get("Bal. Account No.");
        Vend.CheckBlockedVendOnJnls(Vend, "Document Type", false);
        CheckICPartner(Vend."IC Partner Code", "Bal. Account Type", "Bal. Account No.");
        UpdateDescriptionFromBalAccount(Vend.Name);
        "Payment Method Code" := Vend."Payment Method Code";
        Validate("Recipient Bank Account", Vend."Preferred Bank Account Code");
        "Posting Group" := Vend."Vendor Posting Group";
        SetSalespersonPurchaserCode(Vend."Purchaser Code", "Salespers./Purch. Code");
        "Payment Terms Code" := Vend."Payment Terms Code";
        Validate("Bill-to/Pay-to No.", "Bal. Account No.");
        Validate("Sell-to/Buy-from No.", "Bal. Account No.");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Vend."Currency Code";
        CheckSetCurrencyCodeForBankVendLine(Vend);
        ClearBalancePostingGroups();
        CheckConfirmDifferentVendorAndPayToVendor(Vend, "Bal. Account No.");
        Validate("Payment Terms Code");
        CheckPaymentTolerance();

        OnAfterAccountNoOnValidateGetVendorBalAccount(Rec, Vend, CurrFieldNo);
    end;

    local procedure CheckSetCurrencyCodeForBankVendLine(Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSetCurrencyCodeForBankVendLine(Rec, Vend, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := Vend."Currency Code";
    end;

    local procedure GetEmployeeBalAccount()
    var
        Employee: Record Employee;
    begin
        Employee.Get("Bal. Account No.");
        Employee.CheckBlockedEmployeeOnJnls(false);
        if "Account No." = '' then
            UpdateDescriptionWithEmployeeName(Employee);
        "Posting Group" := Employee."Employee Posting Group";
        SetSalespersonPurchaserCode(Employee."Salespers./Purch. Code", "Salespers./Purch. Code");
        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := Employee."Currency Code";
        ClearBalancePostingGroups();

        OnAfterAccountNoOnValidateGetEmployeeBalAccount(Rec, Employee, CurrFieldNo);
    end;

    local procedure GetBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        BankAcc.TestField(Blocked, false);
        if ReplaceDescription() then
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
        ClearPostingGroups();

        OnAfterAccountNoOnValidateGetBankAccount(Rec, BankAcc, CurrFieldNo);
    end;

    local procedure GetBankBalAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bal. Account No.");
        BankAcc.TestField(Blocked, false);
        UpdateDescriptionFromBalAccount(BankAcc.Name);

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
                ClearCurrencyCode()
        else
            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                BankAcc.TestField("Currency Code", "Currency Code")
            else
                "Currency Code" := BankAcc."Currency Code";
        ClearBalancePostingGroups();

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
        GetFAVATSetup();
        GetFAAddCurrExchRate();

        OnAfterAccountNoOnValidateGetFAAccount(Rec, FA, CurrFieldNo);
    end;

    local procedure GetFABalAccount()
    var
        FA: Record "Fixed Asset";
    begin
        FA.Get("Bal. Account No.");
        FA.TestField(Blocked, false);
        FA.TestField(Inactive, false);
        FA.TestField("Budgeted Asset", false);
        UpdateDescriptionFromBalAccount(FA.Description);
        GetFADeprBook("Bal. Account No.");
        GetFAVATSetup();
        GetFAAddCurrExchRate();

        OnAfterAccountNoOnValidateGetFABalAccount(Rec, FA);
    end;

    local procedure GetICPartnerAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Account No.");
        ICPartner.CheckICPartner();
        UpdateDescription(ICPartner.Name);
        if ("Bal. Account No." = '') or ("Bal. Account Type" = "Bal. Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearPostingGroups();
        "IC Partner Code" := "Account No.";

        OnAfterAccountNoOnValidateGetICPartnerAccount(Rec, ICPartner);
    end;

    local procedure GetAllocationAccount()
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount.Get("Account No.");
        UpdateDescription(AllocationAccount.Name);
    end;

    local procedure GetICPartnerBalAccount()
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get("Bal. Account No.");
        UpdateDescriptionFromBalAccount(ICPartner.Name);

        if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
            "Currency Code" := ICPartner."Currency Code";
        if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
            "Currency Code" := ICPartner."Currency Code";
        ClearBalancePostingGroups();
        "IC Partner Code" := "Bal. Account No.";

        OnAfterAccountNoOnValidateGetICPartnerBalAccount(Rec, ICPartner);
    end;

    procedure CreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
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
        FAGenJournalLine.Validate("Currency Code", "Currency Code");
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
        if FAPostingGr.GetPostingGroup(FAGenJournalLine."Posting Group", FAGenJournalLine."Depreciation Book Code") then begin
            LocalGLAcc.Get(FAPostingGr."Acquisition Cost Account");
            LocalGLAcc.CheckGLAcc();
            FAGenJournalLine.Validate("Gen. Posting Type", LocalGLAcc."Gen. Posting Type");
            FAGenJournalLine.Validate("Gen. Bus. Posting Group", LocalGLAcc."Gen. Bus. Posting Group");
            FAGenJournalLine.Validate("Gen. Prod. Posting Group", LocalGLAcc."Gen. Prod. Posting Group");
            FAGenJournalLine.Validate("VAT Bus. Posting Group", LocalGLAcc."VAT Bus. Posting Group");
            FAGenJournalLine.Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");
            FAGenJournalLine.Validate("Tax Group Code", LocalGLAcc."Tax Group Code");
            FAGenJournalLine.Validate("VAT Prod. Posting Group");
            FAGenJournalLine.Modify(true)
        end;

        OnAfterCreateFAAcquisitionLines(FAGenJournalLine, Rec, BalancingGenJnlLine);

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
        NoSeries: Codeunit "No. Series";
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        if GenJournalBatch."No. Series" <> '' then
            DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series", PostingDate);
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
        AccountNo := GetFilterAccountNo();
        if AccountNo = '' then begin
            FilterGroup(2);
            AccountNo := GetFilterAccountNo();
            FilterGroup(0);
        end;
        if AccountNo <> '' then
            "Account No." := AccountNo;
    end;

    procedure GetNewLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Validate("Journal Template Name", TemplateName);
        GenJournalLine.Validate("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if GenJournalLine.FindLast() then
            exit(GenJournalLine."Line No." + 10000);
        exit(10000);
    end;

    procedure VoidPaymentFile()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        [SecurityFiltering(SecurityFilter::Filtered)]
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
        if not GenJournalLine2.FindFirst() then
            Error(NoEntriesToVoidErr);

        Clear(VoidTransmitElecPmnts);
        VoidTransmitElecPmnts.SetUsageType(1);   // Void
        VoidTransmitElecPmnts.SetTableView(TempGenJnlLine);
        if "Account Type" = "Account Type"::"Bank Account" then
            VoidTransmitElecPmnts.SetBankAccountNo("Account No.")
        else
            if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then
                VoidTransmitElecPmnts.SetBankAccountNo("Bal. Account No.");
        VoidTransmitElecPmnts.RunModal();
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
        VoidTransmitElecPmnts.RunModal();
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

    local procedure SetApplnRecipientBankAccount(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AppliesToDocNo: Code[20]; RecipientBankAcc: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        if AppliesToDocNo = '' then
            case AccType of
                AccType::Customer:
                    if Customer.Get(AccNo) and (Customer."Preferred Bank Account Code" <> '') then
                        Validate("Recipient Bank Account", Customer."Preferred Bank Account Code");
                AccType::Vendor:
                    if Vendor.Get(AccNo) and (Vendor."Preferred Bank Account Code" <> '') then
                        Validate("Recipient Bank Account", Vendor."Preferred Bank Account Code");
            end
        else
            if RecipientBankAcc <> '' then
                Validate("Recipient Bank Account", RecipientBankAcc);
    end;

    procedure CheckIfPrivacyBlocked()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        if FindSet() then begin
            repeat
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            Customer.Get("Account No.");
                            if Customer."Privacy Blocked" then
                                Error(Customer.GetPrivacyBlockedGenericErrorText(Customer));
                            if Customer.Blocked = Customer.Blocked::All then
                                Error(BlockedErr, Customer.Blocked, Customer.TableCaption(), Customer."No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vendor.Get("Account No.");
                            if Vendor."Privacy Blocked" then
                                Error(Vendor.GetPrivacyBlockedGenericErrorText(Vendor));
                            if Vendor.Blocked in [Vendor.Blocked::All, Vendor.Blocked::Payment] then
                                Error(BlockedErr, Vendor.Blocked, Vendor.TableCaption(), Vendor."No.");
                        end;
                    "Account Type"::Employee:
                        begin
                            Employee.Get("Account No.");
                            if Employee."Privacy Blocked" then
                                Error(BlockedEmplErr, Employee."No.");
                        end;
                    else
                        OnCheckIfPrivacyBlockedCaseElse(Rec);
                end;
            until Next() = 0;
        end;
    end;

    local procedure CheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Enum "Gen. Journal Document Type"; ApplyDocNo: Code[20];
                                                                                                                                      RecordVariant: Variant)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine, ApplyPostingDate, ApplyDocType.AsInteger(), ApplyDocNo, IsHandled, RecordVariant, CustLedgEntry);
        if IsHandled then
            exit;

        if GenJournalLine."Posting Date" < ApplyPostingDate then
            Error(
              Text015, GenJournalLine."Document Type", GenJournalLine."Document No.", ApplyDocType, ApplyDocNo);
    end;

    local procedure ClearInvCrMemoTypeFields()
    begin
        "Sales Invoice Type" := "Sales Invoice Type"::"F1 Invoice";
        "Sales Cr. Memo Type" := "Sales Cr. Memo Type"::"R1 Corrected Invoice";
        "Sales Special Scheme Code" := "Sales Special Scheme Code"::"01 General";
        "Purch. Invoice Type" := "Purch. Invoice Type"::"F1 Invoice";
        "Purch. Cr. Memo Type" := "Purch. Cr. Memo Type"::"R1 Corrected Invoice";
        "Purch. Special Scheme Code" := "Purch. Special Scheme Code"::"01 General";
        "Correction Type" := 0;
        "Corrected Invoice No." := '';
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

    local procedure CheckBalAccountNoOnJobNoValidation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountNoOnJobNoValidation(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Bal. Account No." <> '' then
            if not ("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Bal. Account Type"::"Bank Account"]) then
                Error(Text016, FieldCaption("Bal. Account Type"));
    end;

    local procedure HasNoMultipleLine(): Boolean
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine2.SetRange("Document No.", "Document No.");
        GenJnlLine2.SetRange("Account No.", xRec."Account No.");
        GenJnlLine2.SetRange("Applies-to ID", xRec."Applies-to ID");
        GenJnlLine2.SetFilter("Line No.", '<>%1', "Line No.");
        if GenJnlLine2.Count = 0 then
            exit(true);
    end;

    local procedure CheckOpenApprovalEntryExistForCurrentUser()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Rec);
        if GenJournalBatch.Get("Journal Template Name", "Journal Batch Name") then
            ApprovalsMgmt.PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(GenJournalBatch);
    end;

    local procedure SetRecipientBankAccount(RecipientBankAccount: Code[20])
    var
    begin
        if RecipientBankAccount = '' then
            exit;

        Validate("Recipient Bank Account", RecipientBankAccount);
    end;

    local procedure GetAccCurrencyCode() CurrencyCode: Code[10]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
        ICPartner: Record "IC Partner";
    begin
        if ("Account No." = '') or ("Currency Code" = '') then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    Customer.Get("Account No.");
                    CurrencyCode := Customer."Currency Code";
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.Get("Account No.");
                    CurrencyCode := Vendor."Currency Code";
                end;
            "Account Type"::Employee:
                begin
                    Employee.Get("Account No.");
                    CurrencyCode := Employee."Currency Code";
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccount.Get("Account No.");
                    CurrencyCode := BankAccount."Currency Code";
                end;
            "Account Type"::"IC Partner":
                begin
                    ICPartner.Get("Account No.");
                    CurrencyCode := ICPartner."Currency Code";
                end;
        end;

        exit(CurrencyCode);
    end;

    local procedure RestrictGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        if GenJournalLine."System-Created Entry" or GenJournalLine.IsTemporary then
            exit;

        if ApprovalsMgmt.IsGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine) then
            RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictLineUsageDetailsTxt);

        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if ApprovalsMgmt.IsGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch) then
                RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictBatchUsageDetailsTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAccountNoOnValidateOnBeforeCreateDim(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; LastGenJournalLine: Record "Gen. Journal Line"; Balance: Decimal; BottomLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDescriptionFromGLAcc(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustApplnEntryFields(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearEmplApplnEntryFields(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
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
    local procedure OnAfterCopyGenJnlLineFromVendLedgEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
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
    local procedure OnAfterCopyGenJnlLineFromPrepmtInvBuffer(PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineFromPaymentEmplLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportBankStatement(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetGLBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; CallingFieldNo: Integer)
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
    local procedure OnAfterAccountNoOnValidateGetEmployeeAccount(var GenJournalLine: Record "Gen. Journal Line"; var Employee: Record Employee)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAccountNoOnValidateGetEmployeeBalAccount(var GenJournalLine: Record "Gen. Journal Line"; var Employee: Record Employee; CallingFieldNo: Integer)
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
    local procedure OnAfterAccountNoOnValidateGetFAAccount(var GenJournalLine: Record "Gen. Journal Line"; var FixedAsset: Record "Fixed Asset"; CurrFieldNo: Integer)
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
    local procedure OnAppliesToDocNoOnValidateOnAfterVendLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnAfterCustLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnBeforeUpdAmtToEntries(var GenJournalLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnAfterUpdAmtToEntries(var GenJournalLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnBeforeValidateApplyRequirements(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignJobCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownExportedAmount(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var GLSetupRead: Boolean; Balance: Decimal; BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePricesFromJobJnlLine(var GenJournalLine: Record "Gen. Journal Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesPurchLCY(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFAAcquisitionLines(var FAGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line"; var BalancingGenJournalLine: Record "Gen. Journal Line")
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
    local procedure OnAfterGetAppliesToDocDueDate(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; var Result: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToDocPmtDiscountDate(var GenJournalLine: Record "Gen. Journal Line"; GenJournalAccountType: Enum "Gen. Journal Account Type"; GenJournalAccountNo: Code[20]; var Result: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliesToDocEntryNo(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; var Result: Integer)
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
    local procedure OnAfterGetEmplLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFADeprBook(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
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
    local procedure OnAfterSetApplyToAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAmount(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateApplyRequirements(TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDirectPosting(var GLAccount: Record "G/L Account"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20];
                                                                                                                            xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocumentTypeAndAppliesToFields(var GenJournalLine: Record "Gen. Journal Line"; DocType: Integer; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlankJobNo(var GenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAccountTypeOnJobValidation(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocNoOnLines(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfPostingDateIsEarlier(GenJournalLine: Record "Gen. Journal Line"; ApplyPostingDate: Date; ApplyDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; ApplyDocNo: Code[20]; var IsHandled: Boolean; RecordVariant: Variant; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

#if not CLEAN24
    [Obsolete('Subscribe to OnProcessBalanceOfLinesOnAfterCalcShouldCheckDocNoBasedOnNoSeries in Gen. Jnl.-Post Batch instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocNoBasedOnNoSeries(var GenJournalLine: Record "Gen. Journal Line"; LastDocNo: Code[20]; NoSeriesCode: Code[20]; var NoSeriesMgtInstance: Codeunit NoSeriesManagement; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimensionsFromJobTaskLine(TempJobJnlLine: Record "Job Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAccTypeAndNo(GenJournalLine2: Record "Gen. Journal Line"; var AccType: Enum "Gen. Journal Account Type"; var AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralPostDate(GenJournalLine: Record "Gen. Journal Line"; var DeferralPostDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFADeprBook(var GenJournalLine: Record "Gen. Journal Line"; FANo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmptyLine(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCustVendICAdded(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAdHocDescription(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAdHocBalAccDescription(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskIsSet(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocCust(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocEmpl(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpAppliesToDocVend(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberAppliesToID(GenJournalLine: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunApplyCustEntriesPageLookupOk(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunApplyVendEntriesPageLookupOk(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; AccNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTotalExportedAmount(var GenJournalLine: Record "Gen. Journal Line"; var Result: Decimal; var IsHandled: Boolean)
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
    local procedure OnBeforeSetApplyToAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsOnTempJobJnlLine(GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; TempJobJournalLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateApplyToAmount(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCountryCodeAndVATRegNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; No: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAmountLCY(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCampaignNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
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
    local procedure OnBeforeValidateDeferralCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentDateFromPostingDate(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
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
    local procedure OnBeforeValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJobJnlLineOnBeforeFindJobCurrencyFactor(var GenJournalLine: Record "Gen. Journal Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJobJnlLimeOnBeforeValidateFields(var TempJobJnlLine: Record "Job Journal Line"; var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnAfterRunExport(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnBeforeRunExport(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPaymentFileOnBeforeCheckDocNoOnLines(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFirstCustLedgEntryWithAppliesToIDOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFirstVendLedgEntryWithAppliesToIDOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAVATSetupOnBeforeCheckGLAcc(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterAssignCustomerNo(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgerEntryOnAfterAssignVendorNo(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterApplyCustEntriesGetRecord(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocEmplOnAfterSetFilters(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocEmplOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20])
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
    local procedure OnRenumberAppliesToIDOnAfterCustLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenumberAppliesToIDOnAfterVendLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnAfterCustLedgEntrySetFilters(GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnAfterVendLedgEntrySetFilters(GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeCustEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeVendEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyToAmountOnBeforeEmplEntryEdit(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeIncrDocNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var BottomLine: Boolean; var IsHandled: Boolean; var Rec: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnBeforeSetBalAccount(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var IsHandled: Boolean; GenJnlTemplate: Record "Gen. Journal Template"; GenJnlBatch: Record "Gen. Journal Batch"; BottomLine: Boolean; var Rec: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstCustLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstVendLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Employee Ledger Entry");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateLineBalanceOnAfterAssignBalanceLCY(var BalanceLCY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateAmountOnAfterAssignAmountLCY(var AmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnBeforeCheckCreditLimit(var GenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
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
    local procedure OnValidateAccountTypeOnBeforeCheckKeepDescription(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithAppliesToID(TempGenJnlLine: Record "Gen. Journal Line" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterCustLedgEntrySetFiltersWithoutAppliesToID(TempGenJnlLine: Record "Gen. Journal Line" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithAppliesToID(TempGenJournalLine: Record "Gen. Journal Line" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplyRequirementsOnAfterVendLedgEntrySetFiltersWithoutAppliesToID(TempGenJournalLine: Record "Gen. Journal Line" temporary; var VendorLedgerEntry: Record "Vendor Ledger Entry")
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

    local procedure UpdateDocumentTypeAndAppliesTo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        "Applies-to Doc. Type" := DocType;
        "Applies-to Doc. No." := DocNo;
        "Applies-to ID" := '';

        OnAfterUpdateDocumentTypeAndAppliesToFields(Rec, DocType.AsInteger(), DocNo);

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

        "Account Id" := GLAccount.SystemId;
    end;

    local procedure UpdateAccountNo()
    var
        GLAccount: Record "G/L Account";
    begin
        if IsNullGuid("Account Id") then
            exit;

        if not GLAccount.GetBySystemId("Account Id") then
            exit;

        "Account No." := GLAccount."No.";
    end;

    local procedure UpdateBalanceAccountId()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        clear("Balance Account Id");
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                begin
                    if not GLAccount.Get("Bal. Account No.") then
                        exit;
                    "Balance Account Id" := GLAccount.SystemId;
                end;
            "Bal. Account Type"::"Bank Account":
                begin
                    if not BankAccount.Get("Bal. Account No.") then
                        exit;
                    "Balance Account Id" := BankAccount.SystemId
                end;
        end;
    end;

    local procedure UpdateBalanceAccountNo()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        if IsNullGuid("Balance Account Id") then
            exit;
        case "Bal. Account Type" of
            "Bal. Account Type"::"G/L Account":
                begin
                    if not GLAccount.GetBySystemId("Balance Account Id") then
                        exit;
                    Validate("Bal. Account No.", GLAccount."No.");
                end;
            "Bal. Account Type"::"Bank Account":
                begin
                    if not BankAccount.GetBySystemId("Balance Account Id") then
                        exit;
                    validate("Bal. Account No.", BankAccount."No.");
                end;
        end;
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

        "Customer Id" := Customer.SystemId;
    end;

    procedure UpdateVendorID()
    var
        Vendor: Record Vendor;
    begin
        if "Account Type" <> "Account Type"::Vendor then
            exit;

        if "Account No." = '' then begin
            Clear("Vendor Id");
            exit;
        end;

        if not Vendor.Get("Account No.") then
            exit;

        "Vendor Id" := Vendor.SystemId;
    end;

    local procedure UpdateCustomerNo()
    var
        Customer: Record Customer;
    begin
        if IsNullGuid("Customer Id") then
            exit;

        if not Customer.GetBySystemId("Customer Id") then
            exit;

        "Account No." := Customer."No.";
    end;

    local procedure UpdateVendorNo()
    var
        Vendor: Record Vendor;
    begin
        if IsNullGuid("Vendor Id") then
            exit;

        if not Vendor.GetBySystemId("Vendor Id") then
            exit;

        "Account No." := Vendor."No.";
    end;

    procedure UpdateAppliesToInvoiceID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        AppliestoInvoiceId: Guid;
    begin
        if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::Invoice then
            exit;

        if "Applies-to Doc. No." = '' then begin
            Clear("Applies-to Invoice Id");
            exit;
        end;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if not SalesInvoiceHeader.Get("Applies-to Doc. No.") then
                        exit;

                    AppliestoInvoiceId := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
                    if Rec."Applies-to Invoice Id" <> AppliestoInvoiceId then
                        Rec."Applies-to Invoice Id" := AppliestoInvoiceId;
                end;
            "Account Type"::Vendor:
                begin
                    if not PurchInvHeader.Get("Applies-to Doc. No.") then
                        exit;

                    AppliestoInvoiceId := PurchInvAggregator.GetPurchaseInvoiceHeaderId(PurchInvHeader);
                    if Rec."Applies-to Invoice Id" <> AppliestoInvoiceId then
                        Rec."Applies-to Invoice Id" := AppliestoInvoiceId;
                end;
        end;
    end;

    local procedure UpdateAppliesToInvoiceNo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvheader: Record "Purch. Inv. Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        if IsNullGuid("Applies-to Invoice Id") then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    if not SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(Format("Applies-to Invoice Id"), SalesInvoiceHeader) then
                        Error(InvoiceForGivenIDDoesNotExistErr);

                    "Applies-to Doc. No." := SalesInvoiceHeader."No.";
                end;
            "Account Type"::Vendor:
                begin
                    if not PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(Format("Applies-to Invoice Id"), PurchInvheader) then
                        Error(InvoiceForGivenIDDoesNotExistErr);

                    "Applies-to Doc. No." := PurchInvheader."No.";
                end;
        end;
    end;

    local procedure CheckPostingGroupChange()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PostingGroupChangeInterface: Interface "Posting Group Change Method";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingGroupChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if ("Posting Group" <> xRec."Posting Group") and (xRec."Posting Group" <> '') then begin
            TestField("Account No.");
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        Customer.Get("Account No.");
                        SalesReceivablesSetup.Get();
                        if SalesReceivablesSetup."Allow Multiple Posting Groups" then begin
                            Customer.TestField("Allow Multiple Posting Groups");
                            PostingGroupChangeInterface := SalesReceivablesSetup."Check Multiple Posting Groups";
                            PostingGroupChangeInterface.ChangePostingGroup("Posting Group", xRec."Posting Group", Rec);
                        end;
                    end;
                "Account Type"::Vendor:
                    begin
                        Vendor.Get("Account No.");
                        PurchasesPayablesSetup.Get();
                        if PurchasesPayablesSetup."Allow Multiple Posting Groups" then begin
                            Vendor.TestField("Allow Multiple Posting Groups");
                            PostingGroupChangeInterface := PurchasesPayablesSetup."Check Multiple Posting Groups";
                            PostingGroupChangeInterface.ChangePostingGroup("Posting Group", xRec."Posting Group", Rec);
                        end;
                    end;
                else
                    error(CannotChangePostingGroupForAccountTypeErr, "Account Type");
            end;
        end;
    end;

    procedure UpdateJournalBatchID()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit;

        "Journal Batch Id" := GenJournalBatch.SystemId;
    end;

    local procedure UpdateJournalBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.GetBySystemId("Journal Batch Id") then
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

        "Payment Method Id" := PaymentMethod.SystemId;
    end;

    local procedure UpdatePaymentMethodCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if IsNullGuid("Payment Method Id") then
            exit;

        if not PaymentMethod.GetBySystemId("Payment Method Id") then
            exit;

        "Payment Method Code" := PaymentMethod.Code;
    end;

    local procedure UpdateDescriptionWithEmployeeName(Employee: Record Employee)
    begin
        if StrLen(Employee.FullName()) <= MaxStrLen(Description) then
            UpdateDescription(CopyStr(Employee.FullName(), 1, MaxStrLen(Description)))
        else
            UpdateDescription(Employee.Initials);
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnGenJnlLineGetVendorAccount(Vendor: Record Vendor)
    begin
    end;

    procedure ShowDeferralSchedule()
    begin
        if "Account Type" = "Account Type"::"Fixed Asset" then
            Error(AccTypeNotSupportedErr);

        ShowDeferrals("Posting Date", "Currency Code");
    end;

    procedure ShowRecurringDimFilter()
    var
        GenJnlDimFilters: Page "Gen. Jnl. Dim. Filters";
    begin
        GenJnlDimFilters.SetGenJnlLine(Rec);
        GenJnlDimFilters.RunModal();
    end;

    local procedure DimFilterExists(): Boolean
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", "Line No.");
        exit(not GenJnlDimFilter.IsEmpty);
    end;

    local procedure LineDimExists(): Boolean
    begin
        exit("Dimension Set ID" <> 0);
    end;

    procedure CheckShortcutDimCodeRecurringMethod(ShortcutDimCode: Code[20])
    begin
        if ShortcutDimCode <> '' then
            if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
                FieldError("Recurring Method");
    end;

    local procedure ShowSetDimFiltersNotification()
    begin
        if "Line No." <> 0 then
            if "Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"] then
                SendSetDimFiltersNotification()
            else
                RecallSetDimFiltersNotification();
    end;

    local procedure SendSetDimFiltersNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        GenJnlDimFilterMgt: Codeunit "Gen. Jnl. Dim. Filter Mgt.";
        SetDimFiltersNotification: Notification;
    begin
        RecallSetDimFiltersNotification();

        if not GenJnlDimFilterMgt.IsNotificationEnabled() or DimFilterExists() then
            exit;

        SetDimFiltersNotification.Id(CreateGuid());
        SetDimFiltersNotification.Message(SetDimFiltersMessageTxt);
        SetDimFiltersNotification.Scope(NotificationScope::LocalScope);
        SetDimFiltersNotification.AddAction(SetDimFiltersActionTxt, Codeunit::"Gen. Jnl. Dim. Filter Mgt.", 'SetGenJnlDimFilters');
        SetDimFiltersNotification.AddAction(DontShowAgainActionTxt, Codeunit::"Gen. Jnl. Dim. Filter Mgt.", 'HideNotification');
        SetDimFiltersNotification.SetData('JournalTemplateName', "Journal Template Name");
        SetDimFiltersNotification.SetData('JournalBatchName', "Journal Batch Name");
        SetDimFiltersNotification.SetData('JournalLineNo', Format("Line No."));
        NotificationLifecycleMgt.SendNotification(SetDimFiltersNotification, RecordId);
    end;

    procedure SendToPosting(PostingCodeunitID: Integer)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        BatchProcessingMgt.BatchProcessGenJournalLine(Rec, PostingCodeunitID);
    end;

    local procedure RecallSetDimFiltersNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordId, "Line No." = 0);
    end;

    local procedure DeleteGenJnlDimFilters()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", "Line No.");
        if not GenJnlDimFilter.IsEmpty() then
            GenJnlDimFilter.DeleteAll();
    end;

    local procedure CheckRecurringDimensionsAndFilters()
    begin
        if not ("Recurring Method" in ["Recurring Method"::"BD Balance by Dimension", "Recurring Method"::"RBD Reversing Balance by Dimension"]) then begin
            if "Line No." <> 0 then
                if DimFilterExists() then
                    Error(RecurringMethodsDimFilterErr, "Recurring Method");
        end else
            if LineDimExists() then
                Error(RecurringMethodsLineDimdErr, "Recurring Method");
    end;

    local procedure CalcVATAmountLCY(): Decimal
    var
        LCYCurrency: Record Currency;
        VATAmountLCY: Decimal;
    begin
        if "Currency Code" = '' then
            exit("VAT Amount");

        OnCalcVATAmountLCYOnBeforeInitRoundingPrecision(Rec, LCYCurrency);
        LCYCurrency.InitRoundingPrecision();

        "VAT Difference" :=
            "VAT Amount" -
            Round(
                Amount * "VAT %" / (100 + "VAT %"),
                LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());

        if "VAT Difference" = 0 then
            VATAmountLCY := Round("Amount (LCY)" * "VAT %" / (100 + "VAT %"), LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection())
        else
            VATAmountLCY :=
                Round(
                    CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", "VAT Amount", "Currency Factor"),
                    LCYCurrency."Amount Rounding Precision", LCYCurrency.VATRoundingDirection());

        exit(VATAmountLCY);
    end;

    procedure CreateDimFromDefaultDim(FromFieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FromFieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), Rec."Account No.", FromFieldNo = Rec.Fieldno("Account No."));
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Bal. Account Type".AsInteger()), Rec."Bal. Account No.", FromFieldNo = Rec.Fieldno("Bal. Account No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FromFieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FromFieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FromFieldNo = Rec.FieldNo("Campaign No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FromFieldNo);
    end;

    procedure IsAcquisitionCost(): Boolean
    var
        AcquisitionCost: Boolean;
    begin
        AcquisitionCost := "FA Posting Type" = "FA Posting Type"::"Acquisition Cost";
        OnAfterIsAcquisitionCost(Rec, AcquisitionCost);
        exit(AcquisitionCost);
    end;

    local procedure CalculateVATAmount(var VATAmount: Decimal; var VATAmountLCY: Decimal)
    var
        GenJnlLine1: Record "Gen. Journal Line";
        tempVATAmount: Decimal;
    begin
        if "Document No." = '' then
            exit;
        if ("Recurring Method" <> "Recurring Method"::" ") then begin
            CalculateVATAmountonGenJnlAllocation(Rec, VATAmount);
            tempVATAmount := "VAT Amount";
            "VAT Amount" := VATAmount;
            VATAmountLCY := CalcVATAmountLCY();
            "VAT Amount" := tempVATAmount;
        end;

        GenJnlLine1.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine1.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine1.SetRange("Document No.", "Document No.");
        GenJnlLine1.CalcSums("VAT Amount", "VAT Amount (LCY)");
        VATAmount := VATAmount + GenJnlLine1."VAT Amount";
        VATAmountLCY := VATAmountLCY + GenJnlLine1."VAT Amount (LCY)";

        if Amount < 0 then
            VATAmount := Abs(VATAmount)
        else
            VATAmount := -1 * Abs(VATAmount);

        if "Amount (LCY)" < 0 then
            VATAmountLCY := Abs(VATAmountLCY)
        else
            VATAmountLCY := -1 * Abs(VATAmountLCY);
    end;

    local procedure CalculateVATAmountonGenJnlAllocation(GenJnlLine1: Record "Gen. Journal Line"; var VATAmount: Decimal)
    var
        GenJnlAlloc1: Record "Gen. Jnl. Allocation";
    begin
        GenJnlAlloc1.SetRange("Journal Template Name", GenJnlLine1."Journal Template Name");
        GenJnlAlloc1.SetRange("Journal Batch Name", GenJnlLine1."Journal Batch Name");
        GenJnlAlloc1.SetRange("Journal Line No.", GenJnlLine1."Line No.");
        GenJnlAlloc1.CalcSums("VAT Amount");
        VATAmount := GenJnlAlloc1."VAT Amount";
    end;

    local procedure DeleteRelatedPaymentFileErrors()
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.DeleteJnlLineErrorsWhenRecDeleted(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var GenJournalLine: Record "Gen. Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanLine(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedReminderHeader(IssuedReminderHeader: Record "Issued Reminder Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgerEntryOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberAppliesToID(GenJournalLine: Record "Gen. Journal Line"; OriginalAppliesToID: Code[50]; NewAppliesToID: Code[50]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReplaceDescription(GenJnlBatch: Record "Gen. Journal Batch"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberDocNoOnLines(var DocNo: Code[20]; var GenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoValidateOnAfterEmplLedgEntrySetFilters(var GenJournalLine: Record "Gen. Journal Line"; var EmplLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var GenJournalLine: Record "Gen. Journal Line"; var DeferralAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAppliesToDocCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsApplied(var GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromIssuedReminderLine(var GenJournalLine: Record "Gen. Journal Line"; IssuedReminderLine: Record "Issued Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var GenJournalLine: Record "Gen. Journal Line"; CurrFieldNo: Integer; xGenJournalLine: Record "Gen. Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; OldDimSetID: Integer; var IsChanged: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBalAccountNoOnJobNoValidation(var IsHandled: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSkipRenumberDocumentNo(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateJobTaskNo(xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfPrivacyBlockedCaseElse(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearCustVendApplnEntryOnBeforeCustEntrySetApplIDSetApplId(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetCustomerAccountOnAfterCustGet(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetCustomerBalAccountOnAfterCustGet(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAAddCurrExchRateOnCaseElse(GenJournalLine: Record "Gen. Journal Line"; DepreciationBook: Record "Depreciation Book"; var UseFAAddCurrExchRate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBalAccountTypeOnBeforeSetBalAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterValidateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGLBalAccountOnAfterSetDescription(var GenJournalLine: Record "Gen. Journal Line"; GLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckConfirmDifferentCustomerAndBillToCustomer(var GenJorunalLine: Record "Gen. Journal Line"; Customer: Record Customer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckConfirmDifferentVendorAndPayToVendor(var GenJorunalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmptyVATProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSetCurrencyCodeForBankCustLine(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSetCurrencyCodeForBankVendLine(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearJobRelatedAmounts(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterApplyVendEntriesGetRecord(var GenJournalLine: Record "Gen. Journal Line"; GenJnlLine: Record "Gen. Journal Line"; GenJnlApply: Codeunit "Gen. Jnl.-Apply"; PaymentToleranceMgt: Codeunit "Payment Tolerance Management"; VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpAppliesToDocVend(var GenJournalLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; ApplyVendorEntries: Page "Apply Vendor Entries")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentBalanceOnBeforeCalcBalance(var GenJournalLine: Record "Gen. Journal Line"; GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBalVATProdPostingGroupOnBeforeBalVATCalculationCheck(var GenJournalLine: Record "Gen. Journal Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAcquisitionCost(var GenJournalLine: Record "Gen. Journal Line"; var AcquisitionCost: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeUpdateCurrencyFactor(var GenJournalLine: Record "Gen. Journal Line"; var CurrExchRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeClearCustVendApplnEntry(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GenJnlAlloc: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliestoDocNoOnAfterSetJournalLineFieldsFromApplication(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliesToDocNoOnAfterDelPmtToApplnDocNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobTaskNoOnBeforeJobTaskIsSet(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearDataExchangeEntries(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN24
    [IntegrationEvent(false, false)]
    [Obsolete('Currency posting for employee is now allowed, so check was removed', '24.0')]
    local procedure OnBeforeCheckCurrencyForEmployee(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var Condition: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnValidateJobNo(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingGroupChange(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupNewLineOnBeforeSuggestBalancingAmount(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDocumentFields(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20];
                                                                                                           ExtDocNo: Text[35];
                                                                                                           SourceCode: Code[10];
                                                                                                           NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJournalLineFieldsFromApplicationOnAfterFindFirstEmplLedgEntryWithAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyClearAppliedGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; NewCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckModifyCurrencyCodeOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; AccountType: Enum "Gen. Journal Account Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenumberDocNoOnLinesOnAfterModifyGenJnlLine3(var DocNo: Code[20]; var GenJournalLine3: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceDescription(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalTemplate: Record "Gen. Journal Template"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustomerAccountOnBeforeValidatePaymentTermsCode(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAppliesToDocDueDate(var GenJournalLine: Record "Gen. Journal Line"; var Result: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCurrencyCodeOnBeforeCheckBankAccountCurrencyCode(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateLineBalanceOnAfterUpdateAllocations(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCurrencyOnBeforeInitRoundingPrecision(var GenJournalLine: Record "Gen. Journal Line"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLCYOnBeforeInitRoundingPrecision(var GenJournalLine: Record "Gen. Journal Line"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppliesToDocNoOnValidateOnCaseElse(var GenJournalLine: Record "Gen. Journal Line"; var xGenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocCustOnBeforeCustLedgerEntrySetRangeOpen(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportPaymentFile(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAVATSetupOnBeforeCopyVATSetupToJnlLines(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account"; var FAPostingGroup: Record "FA Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpAppliesToDocVendOnBeforeVendLedgerEntrySetRangeOpen(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAmountWithCustLedgEntryOnBeforeSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAmountWithVendLedgEntryOnBeforeSetAmountWithRemaining(var GenJournalLine: Record "Gen. Journal Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDescriptionFromGLAcc(var GenJournalLine: Record "Gen. Journal Line"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAcc(var GLAccount: Record "G/L Account"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupJobPlanningLineNoOnAfterJobPlanningLineSetFilter(var JobPlanningLine: Record "Job Planning Line"; var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobPlanningLineNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnAfterEditDimensionSet(var GenJournalLine: Record "Gen. Journal Line"; OldDimensionSetId: Integer)
    begin
    end;
}
