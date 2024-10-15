﻿namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
#if not CLEAN22
using Microsoft.Inventory.Intrastat;
#endif
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Environment;
using System.Globalization;
using System.IO;
using System.Security.User;
using System.Telemetry;
using System.Threading;

table 98 "General Ledger Setup"
{
    Caption = 'General Ledger Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Allow Posting From"; Date)
        {
            Caption = 'Allow Posting From';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(3; "Allow Posting To"; Date)
        {
            Caption = 'Allow Posting To';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(4; "Register Time"; Boolean)
        {
            Caption = 'Register Time';
        }
        field(5; "Allow Deferral Posting From"; Date)
        {
            Caption = 'Allow Deferral Posting From';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        field(6; "Allow Deferral Posting To"; Date)
        {
            Caption = 'Allow Deferral Posting To';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        field(7; "VAT Reporting Date"; Enum "VAT Reporting Date")
        {
            Caption = 'Default VAT Date';
        }
#pragma warning disable AL0842
        field(8; "VAT Reporting Date Usage"; Enum "VAT Reporting Date Usage")
#pragma warning restore AL0842
        {
            Caption = 'VAT Date Usage';

            trigger OnValidate()
            var
                Language: Codeunit Language;
            begin
                FeatureTelemetry.LogUsage('0000J2U', VATDateFeatureTok, StrSubstNo(VATDateFeatureUsageMsg, Language.ToDefaultLanguage("VAT Reporting Date Usage")));
            end;
        }
        field(28; "Pmt. Disc. Excl. VAT"; Boolean)
        {
            Caption = 'Pmt. Disc. Excl. VAT';

            trigger OnValidate()
            begin
                if "Pmt. Disc. Excl. VAT" then
                    TestField("Adjust for Payment Disc.", false)
                else
                    TestField("VAT Tolerance %", 0);
            end;
        }
        field(41; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(42; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Global Dimension 1 Code"));
        }
        field(43; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Global Dimension 2 Code"));
        }
        field(44; "Cust. Balances Due"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Initial Entry Due Date" = field("Date Filter")));
            Caption = 'Cust. Balances Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Vendor Balances Due"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Initial Entry Due Date" = field("Date Filter")));
            Caption = 'Vendor Balances Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Unrealized VAT"; Boolean)
        {
            Caption = 'Unrealized VAT';

            trigger OnValidate()
            begin
                if not "Unrealized VAT" then begin
                    VATPostingSetup.SetFilter(
                      "Unrealized VAT Type", '>=%1', VATPostingSetup."Unrealized VAT Type"::Percentage);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text000, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text001, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Unrealized VAT Type"),
                          TaxJurisdiction."Unrealized VAT Type");
                end;
                if "Unrealized VAT" then
                    "Prepayment Unrealized VAT" := true
                else
                    "Prepayment Unrealized VAT" := false;
            end;
        }
        field(49; "Adjust for Payment Disc."; Boolean)
        {
            Caption = 'Adjust for Payment Disc.';

            trigger OnValidate()
            begin
                if "Adjust for Payment Disc." then begin
                    TestField("Pmt. Disc. Excl. VAT", false);
                    TestField("VAT Tolerance %", 0);
                end else begin
                    VATPostingSetup.SetRange("Adjust for Payment Discount", true);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text002, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Adjust for Payment Discount"));
                    TaxJurisdiction.SetRange("Adjust for Payment Discount", true);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text003, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Adjust for Payment Discount"));
                end;
            end;
        }
        field(50; "Post with Job Queue"; Boolean)
        {
            Caption = 'Post with Job Queue';

            trigger OnValidate()
            begin
                if not "Post with Job Queue" then
                    "Post & Print with Job Queue" := false;
            end;
        }
        field(51; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code';
            TableRelation = "Job Queue Category";
        }
        field(52; "Job Queue Priority for Post"; Integer)
        {
            Caption = 'Job Queue Priority for Post';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        field(53; "Post & Print with Job Queue"; Boolean)
        {
            Caption = 'Post & Print with Job Queue';

            trigger OnValidate()
            begin
                if "Post & Print with Job Queue" then
                    "Post with Job Queue" := true;
            end;
        }
        field(54; "Job Q. Prio. for Post & Print"; Integer)
        {
            Caption = 'Job Q. Prio. for Post & Print';
            InitValue = 1000;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Job Queue Priority for Post" < 0 then
                    Error(Text001);
            end;
        }
        field(55; "Notify On Success"; Boolean)
        {
            Caption = 'Notify On Success';
        }
        field(56; "Mark Cr. Memos as Corrections"; Boolean)
        {
            Caption = 'Mark Cr. Memos as Corrections';
        }
        field(57; "Local Address Format"; Option)
        {
            Caption = 'Local Address Format';
            OptionCaption = 'Post Code+City,City+Post Code,City+County+Post Code,Blank Line+Post Code+City';
            OptionMembers = "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City";
        }
        field(58; "Inv. Rounding Precision (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Inv. Rounding Precision (LCY)';

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    if "Inv. Rounding Precision (LCY)" <> Round("Inv. Rounding Precision (LCY)", "Amount Rounding Precision") then
                        Error(
                          Text004,
                          FieldCaption("Inv. Rounding Precision (LCY)"), "Amount Rounding Precision");
            end;
        }
        field(59; "Inv. Rounding Type (LCY)"; Option)
        {
            Caption = 'Inv. Rounding Type (LCY)';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(60; "Local Cont. Addr. Format"; Option)
        {
            Caption = 'Local Cont. Addr. Format';
            InitValue = "After Company Name";
            OptionCaption = 'First,After Company Name,Last';
            OptionMembers = First,"After Company Name",Last;
        }
        field(61; "Report Output Type"; Enum "Setup Report Output Type")
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS() then
                        TestField("Report Output Type", "Report Output Type"::PDF);
            end;
        }
        field(63; "Bank Account Nos."; Code[20])
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Account Nos.';
            TableRelation = "No. Series";
        }
        field(65; "Summarize G/L Entries"; Boolean)
        {
            Caption = 'Summarize G/L Entries';
        }
        field(66; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
            InitValue = '2:2';

            trigger OnValidate()
            begin
                CheckDecimalPlacesFormat("Amount Decimal Places");
            end;
        }
        field(67; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
            InitValue = '2:5';

            trigger OnValidate()
            begin
                CheckDecimalPlacesFormat("Unit-Amount Decimal Places");
            end;
        }
        field(68; "Additional Reporting Currency"; Code[10])
        {
            Caption = 'Additional Reporting Currency';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   ("Additional Reporting Currency" <> '')
                then begin
                    AdjAddReportingCurr.SetAddCurr("Additional Reporting Currency");
                    AdjAddReportingCurr.RunModal();
                    if not AdjAddReportingCurr.IsExecuted() then
                        "Additional Reporting Currency" := xRec."Additional Reporting Currency";
                end;
#if not CLEAN22
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   AdjAddReportingCurr.IsExecuted()
                then
                    DeleteIntrastatJnl();
#endif
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   ("Additional Reporting Currency" <> '') and
                   AdjAddReportingCurr.IsExecuted()
                then
                    DeleteAnalysisView();
            end;
        }
        field(69; "VAT Tolerance %"; Decimal)
        {
            Caption = 'VAT Tolerance %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "VAT Tolerance %" <> 0 then begin
                    TestField("Adjust for Payment Disc.", false);
                    TestField("Pmt. Disc. Excl. VAT", true);
                end;
            end;
        }
        field(70; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
        }
        field(71; "LCY Code"; Code[10])
        {
            Caption = 'LCY Code';

            trigger OnValidate()
            var
                Currency: Record Currency;
            begin
                if "Local Currency Symbol" = '' then
                    "Local Currency Symbol" := Currency.ResolveCurrencySymbol("LCY Code");

                if "Local Currency Description" = '' then
                    "Local Currency Description" := CopyStr(Currency.ResolveCurrencyDescription("LCY Code"), 1, MaxStrLen("Local Currency Description"));
            end;
        }
        field(72; "VAT Exchange Rate Adjustment"; Enum "Exch. Rate Adjustment Type")
        {
            Caption = 'VAT Exchange Rate Adjustment';
        }
        field(73; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 0.01;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    "Inv. Rounding Precision (LCY)" := Round("Inv. Rounding Precision (LCY)", "Amount Rounding Precision");

                CheckRoundingError(FieldCaption("Amount Rounding Precision"));

                if HideDialog() then
                    Message(Text021);
            end;
        }
        field(74; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DecimalPlaces = 0 : 9;
            InitValue = 0.00001;

            trigger OnValidate()
            begin
                if HideDialog() then
                    Message(Text022);
            end;
        }
        field(75; "Appln. Rounding Precision"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Appln. Rounding Precision';
            MinValue = 0;
        }
        field(79; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            Editable = false;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                "Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
            end;
        }
        field(80; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            Editable = false;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                "Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
            end;
        }
        field(81; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            Editable = false;
            TableRelation = Dimension;
        }
        field(82; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            Editable = false;
            TableRelation = Dimension;
        }
        field(83; "Shortcut Dimension 3 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 3 Code", "Shortcut Dimension 3 Code", 3);
            end;
        }
        field(84; "Shortcut Dimension 4 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 4 Code", "Shortcut Dimension 4 Code", 4);
            end;
        }
        field(85; "Shortcut Dimension 5 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 5 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 5 Code", "Shortcut Dimension 5 Code", 5);
            end;
        }
        field(86; "Shortcut Dimension 6 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 6 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 6 Code", "Shortcut Dimension 6 Code", 6);
            end;
        }
        field(87; "Shortcut Dimension 7 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 7 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 7 Code", "Shortcut Dimension 7 Code", 7);
            end;
        }
        field(88; "Shortcut Dimension 8 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            Caption = 'Shortcut Dimension 8 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                UpdateDimValueGlobalDimNo(xRec."Shortcut Dimension 8 Code", "Shortcut Dimension 8 Code", 8);
            end;
        }
        field(89; "Max. VAT Difference Allowed"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Max. VAT Difference Allowed';

            trigger OnValidate()
            begin
                if "Max. VAT Difference Allowed" <> Round("Max. VAT Difference Allowed") then
                    Error(
                      Text004,
                      FieldCaption("Max. VAT Difference Allowed"), "Amount Rounding Precision");

                "Max. VAT Difference Allowed" := Abs("Max. VAT Difference Allowed");
            end;
        }
        field(90; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(92; "Pmt. Disc. Tolerance Posting"; Option)
        {
            Caption = 'Pmt. Disc. Tolerance Posting';
            OptionCaption = 'Payment Tolerance Accounts,Payment Discount Accounts';
            OptionMembers = "Payment Tolerance Accounts","Payment Discount Accounts";
        }
        field(93; "Payment Discount Grace Period"; DateFormula)
        {
            Caption = 'Payment Discount Grace Period';
        }
        field(94; "Payment Tolerance %"; Decimal)
        {
            Caption = 'Payment Tolerance %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(95; "Max. Payment Tolerance Amount"; Decimal)
        {
            Caption = 'Max. Payment Tolerance Amount';
            Editable = false;
            MinValue = 0;
        }
        field(96; "Adapt Main Menu to Permissions"; Boolean)
        {
            Caption = 'Adapt Main Menu to Permissions';
            InitValue = true;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced with UI Elements Removal feature.';
            ObsoleteTag = '24.0';
        }
        field(97; "Allow G/L Acc. Deletion Before"; Date)
        {
            Caption = 'Check G/L Acc. Deletion After';
        }
        field(98; "Check G/L Account Usage"; Boolean)
        {
            Caption = 'Check G/L Account Usage';
        }
        field(99; "Payment Tolerance Posting"; Option)
        {
            Caption = 'Payment Tolerance Posting';
            OptionCaption = 'Payment Tolerance Accounts,Payment Discount Accounts';
            OptionMembers = "Payment Tolerance Accounts","Payment Discount Accounts";
        }
        field(100; "Pmt. Disc. Tolerance Warning"; Boolean)
        {
            Caption = 'Pmt. Disc. Tolerance Warning';
        }
        field(101; "Payment Tolerance Warning"; Boolean)
        {
            Caption = 'Payment Tolerance Warning';
        }
        field(102; "Last IC Transaction No."; Integer)
        {
            Caption = 'Last IC Transaction No.';
        }
        field(103; "Bill-to/Sell-to VAT Calc."; Enum "G/L Setup VAT Calculation")
        {
            Caption = 'Bill-to/Sell-to VAT Calc.';
        }
        field(104; "Block Deletion of G/L Accounts"; Boolean)
        {
            Caption = 'Block Deletion of G/L Accounts';
            InitValue = true;
        }
        field(110; "Acc. Sched. for Balance Sheet"; Code[10])
        {
            Caption = 'Account Schedule for Balance Sheet';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
#if CLEAN22
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#endif
            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        field(111; "Acc. Sched. for Income Stmt."; Code[10])
        {
            Caption = 'Account Schedule for Income Stmt.';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
#if CLEAN22
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#endif
            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        field(112; "Acc. Sched. for Cash Flow Stmt"; Code[10])
        {
            Caption = 'Account Schedule for Cash Flow Stmt';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
#if CLEAN22
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#endif
            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        field(113; "Acc. Sched. for Retained Earn."; Code[10])
        {
            Caption = 'Account Schedule for Retained Earn.';
            TableRelation = "Acc. Schedule Name";
            ObsoleteReason = 'Financial Reporting is replacing Account Schedules for financial statements';
#if CLEAN22
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#endif
            trigger OnValidate()
            begin
                Error(AccSchedObsoleteErr);
            end;
        }
        field(114; "Fin. Rep. for Balance Sheet"; Code[10])
        {
            Caption = 'Financial Report for Balance Sheet';
            TableRelation = "Financial Report";
        }
        field(115; "Fin. Rep. for Income Stmt."; Code[10])
        {
            Caption = 'Financial Report for Income Stmt.';
            TableRelation = "Financial Report";
        }
        field(116; "Fin. Rep. for Cash Flow Stmt"; Code[10])
        {
            Caption = 'Financial Report for Cash Flow Stmt';
            TableRelation = "Financial Report";
        }
        field(117; "Fin. Rep. for Retained Earn."; Code[10])
        {
            Caption = 'Financial Report for Retained Earn.';
            TableRelation = "Financial Report";
        }
        field(120; "Tax Invoice Renaming Threshold"; Decimal)
        {
            Caption = 'Tax Invoice Renaming Threshold';
            DataClassification = SystemMetadata;
        }
        field(130; "Req.Country/Reg. Code in Addr."; Boolean)
        {
            Caption = 'Require Country/Region Code in Address';
            DataClassification = SystemMetadata;
        }
        field(150; "Print VAT specification in LCY"; Boolean)
        {
            Caption = 'Print VAT specification in LCY';
        }
        field(151; "Prepayment Unrealized VAT"; Boolean)
        {
            Caption = 'Prepayment Unrealized VAT';

            trigger OnValidate()
            begin
                if "Unrealized VAT" and xRec."Prepayment Unrealized VAT" then
                    Error(DependentFieldActivatedErr, FieldCaption("Prepayment Unrealized VAT"), FieldCaption("Unrealized VAT"));

                if not "Prepayment Unrealized VAT" then begin
                    VATPostingSetup.SetFilter(
                      "Unrealized VAT Type", '>=%1', VATPostingSetup."Unrealized VAT Type"::Percentage);
                    if VATPostingSetup.FindFirst() then
                        Error(
                          Text000, VATPostingSetup.TableCaption(),
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst() then
                        Error(
                          Text001, TaxJurisdiction.TableCaption(),
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Unrealized VAT Type"),
                          TaxJurisdiction."Unrealized VAT Type");
                end;
            end;
        }
        field(152; "Use Legacy G/L Entry Locking"; Boolean)
        {
            Caption = 'Use Legacy G/L Entry Locking';
            ObsoleteReason = 'Legacy G/L Locking is no longer supported.';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(160; "Payroll Trans. Import Format"; Code[20])
        {
            Caption = 'Payroll Trans. Import Format';
            TableRelation = "Data Exch. Def" where(Type = const("Payroll Import"));

            trigger OnValidate()
            begin
                FeatureTelemetry.LogUptake('0004H8X', 'DK payroll service', Enum::"Feature Uptake Status"::Discovered);
            end;
        }
        field(161; "VAT Reg. No. Validation URL"; Text[250])
        {
            Caption = 'VAT Reg. No. Validation URL';
            ObsoleteReason = 'This field is obsolete, it has been replaced by Table 248 VAT Reg. No. Srv Config.';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';

            trigger OnValidate()
            begin
                Error(ObsoleteErr);
            end;
        }
        field(162; "Local Currency Symbol"; Text[10])
        {
            Caption = 'Local Currency Symbol';
        }
        field(163; "Local Currency Description"; Text[60])
        {
            Caption = 'Local Currency Description';
        }
        field(164; "Show Amounts"; Option)
        {
            Caption = 'Show Amounts';
            OptionCaption = 'Amount Only,Debit/Credit Only,All Amounts';
            OptionMembers = "Amount Only","Debit/Credit Only","All Amounts";
        }
        field(169; "Posting Preview Type"; Enum "Posting Preview Type")
        {
            Caption = 'Posting Preview Type';
        }
        field(170; "SEPA Non-Euro Export"; Boolean)
        {
            Caption = 'SEPA Non-Euro Export';
        }
        field(171; "SEPA Export w/o Bank Acc. Data"; Boolean)
        {
            Caption = 'SEPA Export w/o Bank Acc. Data';
        }
        field(175; "Journal Templ. Name Mandatory"; Boolean)
        {
            Caption = 'Journal Templ. Name Mandatory';
        }
        field(176; "Hide Payment Method Code"; Boolean)
        {
            Caption = 'Hide Payment Method Code';
        }
        field(177; "Enable Data Check"; Boolean)
        {
            Caption = 'Enable Data Check';
        }
        field(178; "Document Retention Period"; Enum "Docs - Retention Period Def.")
        {
            Caption = 'Documents Retention Period';
            DataClassification = SystemMetadata;
            InitValue = 0;
        }
        field(180; "Apply Jnl. Template Name"; Code[10])
        {
            Caption = 'Apply Jnl. Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(181; "Apply Jnl. Batch Name"; Code[10])
        {
            Caption = 'Apply Jnl. Batch Name';
            TableRelation = if ("Apply Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Apply Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Apply Jnl. Template Name");
            end;
        }
        field(182; "Job WIP Jnl. Template Name"; Code[10])
        {
            Caption = 'Project WIP Jnl. Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(183; "Job WIP Jnl. Batch Name"; Code[10])
        {
            Caption = 'Project WIP Jnl. Batch Name';
            TableRelation = if ("Job WIP Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Job WIP Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Job WIP Jnl. Template Name");
            end;
        }
        field(184; "Adjust ARC Jnl. Template Name"; Code[10])
        {
            Caption = 'Adjust Add. Rep. Currency Jnl. Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(185; "Adjust ARC Jnl. Batch Name"; Code[10])
        {
            Caption = 'Adjust Add. Rep. Currency Jnl. Batch Name';
            TableRelation = if ("Adjust ARC Jnl. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Adjust ARC Jnl. Template Name"));

            trigger OnValidate()
            begin
                TestField("Adjust ARC Jnl. Template Name");
            end;
        }
        field(186; "Bank Acc. Recon. Template Name"; Code[10])
        {
            Caption = 'Bank Acc. Recon. Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(187; "Bank Acc. Recon. Batch Name"; Code[10])
        {
            Caption = 'Bank Acc. Recon. Batch Name';
            TableRelation = if ("Bank Acc. Recon. Template Name" = filter(<> '')) "Gen. Journal Batch".Name where("Journal Template Name" = field("Bank Acc. Recon. Template Name"));
        }
        field(188; "Control VAT Period"; Enum "VAT Period Control")
        {
            Caption = 'Control VAT Period';

            trigger OnValidate()
            var
                Language: Codeunit Language;
            begin
                FeatureTelemetry.LogUsage('0000JWC', VATDateFeatureTok, StrSubstNo(VATPeriodControlUsageMsg, Language.ToDefaultLanguage("Control VAT Period")));
            end;
        }
        field(189; "Allow Query From Consolid."; Boolean)
        {
            Caption = 'Enable company as subsidiary';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ImportConsolidationFromApi: Codeunit "Import Consolidation From API";
            begin
                if not Rec."Allow Query From Consolid." then
                    exit;
                if not GuiAllowed() then
                    Error(PrivacyStatementAckErr);
                if not ImportConsolidationFromApi.GetPrivacyConsentChoice() then
                    Error('');
            end;

        }
        field(190; "Acc. Receivables Category"; Integer)
        {
            TableRelation = "G/L Account Category";
            Caption = 'Account Receivables G/L Account Category';
        }
	    field(191; "App. Dimension Posting"; Enum "Exch. Rate Adjmt. Dimensions")
        {
            Caption = 'Dimension Posting';
            DataClassification = CustomerContent;
        }
        field(11730; "Cash Desk Nos."; Code[20])
        {
            Caption = 'Cash Desk Nos.';
            TableRelation = "No. Series";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11731; "Cash Payment Limit (LCY)"; Decimal)
        {
            Caption = 'Cash Payment Limit (LCY)';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11760; "Closed Period Entry Pos.Date"; Date)
        {
            Caption = 'Closed Period Entry Pos.Date';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11761; "Rounding Date"; Date)
        {
            Caption = 'Rounding Date';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11762; "Statement Templ. Name Coeff."; Code[10])
        {
            Caption = 'Statement Templ. Name Coeff.';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';

        }
        field(11763; "Statement Name Coeff."; Code[10])
        {
            Caption = 'Statement Name Coeff.';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(11764; "Statement Line No. Coeff."; Integer)
        {
            Caption = 'Statement Line No. Coeff.';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Non-deductible VAT has been removed and this field should not be used.';
            ObsoleteTag = '18.0';
        }
        field(11765; "Round VAT Coeff."; Boolean)
        {
            Caption = 'Round VAT Coeff.';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality is no longer needed.';
            ObsoleteTag = '18.0';
        }
        field(11766; "VAT Coeff. Rounding Precision"; Decimal)
        {
            Caption = 'VAT Coeff. Rounding Precision';
            DecimalPlaces = 2 : 4;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality is no longer needed.';
            ObsoleteTag = '18.0';
        }
        field(11768; "Allow VAT Posting From"; Date)
        {
            Caption = 'Allow VAT Posting From';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11769; "Allow VAT Posting To"; Date)
        {
            Caption = 'Allow VAT Posting To';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11770; "Use VAT Date"; Boolean)
        {
            Caption = 'Use VAT Date';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech. (Prolonged to support Advance Letters)';
            ObsoleteTag = '22.0';
        }
        field(11771; "Check VAT Identifier"; Boolean)
        {
            Caption = 'Check VAT Identifier';
            ObsoleteState = Removed;
            ObsoleteReason = 'The enhanced functionality of VAT Identifier will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11772; "Check Posting Debit/Credit"; Boolean)
        {
            Caption = 'Check Posting Debit/Credit';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11773; "Mark Neg. Qty as Correction"; Boolean)
        {
            Caption = 'Mark Neg. Qty as Correction';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11774; "Company Officials Nos."; Code[20])
        {
            Caption = 'Company Officials Nos.';
            TableRelation = "No. Series";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11775; "Correction As Storno"; Boolean)
        {
            Caption = 'Correction As Storno';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(11776; "Dont Check Dimension"; Boolean)
        {
            Caption = 'Dont Check Dimension';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11790; "User Checks Allowed"; Boolean)
        {
            Caption = 'User Checks Allowed';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
        field(11791; "User ID Lookup only User Check"; Boolean)
        {
            Caption = 'User ID Lookup only User Check';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of user ID Lookup only user Check has been removed and this field should not be used.';
            ObsoleteTag = '21.0';

        }
        field(11792; "Delete Card with Entries"; Boolean)
        {
            Caption = 'Delete Card with Entries';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Disable Cards Deleting will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(11793; "Reg. No. Validation URL"; Text[250])
        {
            Caption = 'Reg. No. Validation URL';
            ExtendedDatatype = URL;
            ObsoleteReason = 'This field has been replaced by Table 11757 Reg. No. Srv Config.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(31000; "Prepayment Type"; Option)
        {
            Caption = 'Prepayment Type';
            OptionCaption = ' ,Prepayments,Advances';
            OptionMembers = " ",Prepayments,Advances;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31002; "Use Adv. CM Nos for Adv. Corr."; Boolean)
        {
            Caption = 'Use Adv. CM Nos for Adv. Corr.';
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31080; "Shared Account Schedule"; Code[10])
        {
            Caption = 'Shared Account Schedule';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31081; "Acc. Schedule Results Nos."; Code[20])
        {
            Caption = 'Acc. Schedule Results Nos.';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '22.0';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Dim: Record Dimension;
        GLEntry: Record "G/L Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        AdjAddReportingCurr: Report "Adjust Add. Reporting Currency";
        UserSetupManagement: Codeunit "User Setup Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ErrorMessage: Boolean;
        RecordHasBeenRead: Boolean;

        Text000: Label '%1 %2 %3 have %4 to %5.';
        Text001: Label '%1 %2 have %3 to %4.';
        Text002: Label '%1 %2 %3 use %4.';
        Text003: Label '%1 %2 use %3.';
        Text004: Label '%1 must be rounded to the nearest %2.';
        Text016: Label 'Enter one number or two numbers separated by a colon. ';
        Text017: Label 'The online Help for this field describes how you can fill in the field.';
        Text018: Label 'You cannot change the contents of the %1 field because there are posted ledger entries.';
        Text021: Label 'You must close the program and start again in order to activate the amount-rounding feature.';
        Text022: Label 'You must close the program and start again in order to activate the unit-amount rounding feature.';
        Text023: Label '%1\You cannot use the same dimension twice in the same setup.';
        DependentFieldActivatedErr: Label 'You cannot change %1 because %2 is selected.';
        ObsoleteErr: Label 'This field is obsolete, it has been replaced by Table 248 VAT Reg. No. Srv Config.';
        AccSchedObsoleteErr: Label 'This field is obsolete and it has been replaced by Table 88 Financial Report';
        VATDateFeatureTok: Label 'VAT Date', Locked = true;
        VATPeriodControlUsageMsg: Label 'Control VAT Period set to %1', Locked = true;
        VATDateFeatureUsageMsg: Label 'VAT Reporting Date Usage set to %1', Locked = true;
        PrivacyStatementAckErr: Label 'Enabling requires privacy statement acknowledgement.';

    procedure CheckDecimalPlacesFormat(var DecimalPlaces: Text[5])
    var
        OK: Boolean;
        ColonPlace: Integer;
        DecimalPlacesPart1: Integer;
        DecimalPlacesPart2: Integer;
        Check: Text[5];
    begin
        OK := true;
        ColonPlace := StrPos(DecimalPlaces, ':');

        if ColonPlace = 0 then begin
            if not Evaluate(DecimalPlacesPart1, DecimalPlaces) then
                OK := false;
            if (DecimalPlacesPart1 < 0) or (DecimalPlacesPart1 > 9) then
                OK := false;
        end else begin
            Check := CopyStr(DecimalPlaces, 1, ColonPlace - 1);
            if Check = '' then
                OK := false;
            if not Evaluate(DecimalPlacesPart1, Check) then
                OK := false;
            Check := CopyStr(DecimalPlaces, ColonPlace + 1, StrLen(DecimalPlaces));
            if Check = '' then
                OK := false;
            if not Evaluate(DecimalPlacesPart2, Check) then
                OK := false;
            if DecimalPlacesPart1 > DecimalPlacesPart2 then
                OK := false;
            if (DecimalPlacesPart1 < 0) or (DecimalPlacesPart1 > 9) then
                OK := false;
            if (DecimalPlacesPart2 < 0) or (DecimalPlacesPart2 > 9) then
                OK := false;
        end;

        if not OK then
            Error(
              Text016 +
              Text017);

        if ColonPlace = 0 then
            DecimalPlaces := Format(DecimalPlacesPart1)
        else
            DecimalPlaces := StrSubstNo('%1:%2', DecimalPlacesPart1, DecimalPlacesPart2);
    end;

    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        case CurrencyCode of
            '':
                exit("LCY Code");
            "LCY Code":
                exit('');
            else
                exit(CurrencyCode);
        end;
    end;

    procedure GetCurrencySymbol(): Text[10]
    begin
        if "Local Currency Symbol" <> '' then
            exit("Local Currency Symbol");

        exit("LCY Code");
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure UpdateVATDate(NewDate: Date; VATDateType: Enum "VAT Reporting Date"; var VATDate: Date)
    begin
        if ("VAT Reporting Date" = VATDateType) then
            VatDate := NewDate;
    end;

    procedure GetVATDate(PostingDate: Date; DocumentDate: Date): Date
    begin
        Get();
        case "VAT Reporting Date" of
            Enum::"VAT Reporting Date"::"Posting Date":
                exit(PostingDate);
            Enum::"VAT Reporting Date"::"Document Date":
                exit(DocumentDate);
        end;
        exit(PostingDate);
    end;

    procedure CheckRoundingError(NameOfField: Text[100])
    begin
        ErrorMessage := false;
        if GLEntry.FindFirst() then
            ErrorMessage := true;
        if ItemLedgerEntry.FindFirst() then
            ErrorMessage := true;
        if JobLedgEntry.FindFirst() then
            ErrorMessage := true;
        if ResLedgEntry.FindFirst() then
            ErrorMessage := true;
        if FALedgerEntry.FindFirst() then
            ErrorMessage := true;
        if MaintenanceLedgerEntry.FindFirst() then
            ErrorMessage := true;
        if InsCoverageLedgerEntry.FindFirst() then
            ErrorMessage := true;
        OnBeforeCheckRoundingError(ErrorMessage);
        if ErrorMessage then
            Error(Text018, NameOfField);
    end;

#if not CLEAN22
    local procedure DeleteIntrastatJnl()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlBatch.SetRange(Reported, false);
        IntrastatJnlBatch.SetRange("Amounts in Add. Currency", true);
        if IntrastatJnlBatch.Find('-') then
            repeat
                IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
                IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
                IntrastatJnlLine.DeleteAll();
            until IntrastatJnlBatch.Next() = 0;
    end;
#endif

    local procedure DeleteAnalysisView()
    begin
        if AnalysisView.Find('-') then
            repeat
                if AnalysisView.Blocked = false then begin
                    AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewEntry.DeleteAll();
                    AnalysisViewBudgetEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewBudgetEntry.DeleteAll();
                    AnalysisView."Last Entry No." := 0;
                    AnalysisView."Last Budget Entry No." := 0;
                    AnalysisView."Last Date Updated" := 0D;
                    AnalysisView.Modify();
                end else begin
                    AnalysisView."Refresh When Unblocked" := true;
                    AnalysisView.Modify();
                end;
            until AnalysisView.Next() = 0;
    end;

    procedure IsPostingAllowed(PostingDate: Date) Result: Boolean
    begin
        Result := PostingDate >= "Allow Posting From";
        OnAfterIsPostingAllowed(Rec, PostingDate, Result);
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get();
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

    procedure FirstAllowedPostingDate() AllowedPostingDate: Date
    var
        InvtPeriod: Record "Inventory Period";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFirstAllowedPostingDate(Rec, AllowedPostingDate, IsHandled);
        if IsHandled then
            exit;

        AllowedPostingDate := "Allow Posting From";
        if not InvtPeriod.IsValidDate(AllowedPostingDate) then
            AllowedPostingDate := CalcDate('<+1D>', AllowedPostingDate);
    end;

    procedure UpdateDimValueGlobalDimNo(xDimCode: Code[20]; DimCode: Code[20]; ShortcutDimNo: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if Dim.CheckIfDimUsed(DimCode, ShortcutDimNo, '', '', 0) then
            Error(Text023, Dim.GetCheckDimErr());
        if xDimCode <> '' then begin
            DimensionValue.SetRange("Dimension Code", xDimCode);
            DimensionValue.ModifyAll("Global Dimension No.", 0);

            DimensionSetEntry.UpdateGlobalDimensionNo(xDimCode, 0);
        end;
        if DimCode <> '' then begin
            DimensionValue.SetRange("Dimension Code", DimCode);
            DimensionValue.ModifyAll("Global Dimension No.", ShortcutDimNo);

            DimensionSetEntry.UpdateGlobalDimensionNo(DimCode, ShortcutDimNo);
        end;
        OnAfterUpdateDimValueGlobalDimNo(ShortcutDimNo, xDimCode, DimCode);
        Modify();
    end;

    local procedure HideDialog(): Boolean
    begin
        exit((CurrFieldNo = 0) or not GuiAllowed);
    end;

    procedure UseVat(): Boolean
    var
        GeneralLedgerSetupRecordRef: RecordRef;
        UseVATFieldRef: FieldRef;
        UseVATFieldNo: Integer;
    begin
        GeneralLedgerSetupRecordRef.Open(DATABASE::"General Ledger Setup", false);

        UseVATFieldNo := 10001;

        if not GeneralLedgerSetupRecordRef.FieldExist(UseVATFieldNo) then
            exit(true);

        if not GeneralLedgerSetupRecordRef.FindFirst() then
            exit(false);

        UseVATFieldRef := GeneralLedgerSetupRecordRef.Field(UseVATFieldNo);
        exit(UseVATFieldRef.Value);
    end;

    procedure CheckAllowedPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange("Allow Posting From",
          "Allow Posting To", NotificationType, DATABASE::"General Ledger Setup");
    end;

    procedure CheckAllowedDeferralPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange(
          "Allow Deferral Posting From", "Allow Deferral Posting To", NotificationType, DATABASE::"User Setup",
          FieldCaption("Allow Deferral Posting From"), FieldCaption("Allow Deferral Posting To"));
    end;

    procedure GetPmtToleranceVisible(): Boolean
    begin
        exit(("Payment Tolerance %" > 0) or ("Max. Payment Tolerance Amount" <> 0));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRoundingError(var ErrorMessage: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsPostingAllowed(GeneralLedgerSetup: Record "General Ledger Setup"; PostingDate: Date; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFirstAllowedPostingDate(GeneralLedgerSetup: Record "General Ledger Setup"; var AllowedPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimValueGlobalDimNo(ShortCutDimNo: Integer; OldDimensionCode: Code[20]; NewDimensionCode: Code[20])
    begin
    end;
}

