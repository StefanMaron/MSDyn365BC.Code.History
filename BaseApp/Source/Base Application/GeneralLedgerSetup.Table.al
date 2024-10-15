﻿table 98 "General Ledger Setup"
{
    Caption = 'General Ledger Setup';

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
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Global Dimension 1 Code"));
        }
        field(43; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Global Dimension 2 Code"));
        }
        field(44; "Cust. Balances Due"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" WHERE("Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                 "Initial Entry Due Date" = FIELD("Date Filter")));
            Caption = 'Cust. Balances Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Vendor Balances Due"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" WHERE("Initial Entry Global Dim. 1" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Initial Entry Due Date" = FIELD("Date Filter")));
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
                    if VATPostingSetup.FindFirst then
                        Error(
                          Text000, VATPostingSetup.TableCaption,
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst then
                        Error(
                          Text001, TaxJurisdiction.TableCaption,
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
                    if VATPostingSetup.FindFirst then
                        Error(
                          Text002, VATPostingSetup.TableCaption,
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Adjust for Payment Discount"));
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
            OptionCaption = 'Post Code+City,City+Post Code,City+County+Post Code,Blank Line+Post Code+City,,City+County+New Line+Post Code,Post Code+City+County,,,,,,,,Custom';
            OptionMembers = "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City",,"City+County+New Line+Post Code","Post Code+City+County",,,,,,,,Custom;
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
        field(61; "Report Output Type"; Option)
        {
            Caption = 'Report Output Type';
            DataClassification = CustomerContent;
            OptionCaption = 'PDF,,,Print';
            OptionMembers = PDF,,,Print;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if "Report Output Type" = "Report Output Type"::Print then
                    if EnvironmentInformation.IsSaaS then
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
                    AdjAddReportingCurr.RunModal;
                    if not AdjAddReportingCurr.IsExecuted then
                        "Additional Reporting Currency" := xRec."Additional Reporting Currency";
                end;
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   AdjAddReportingCurr.IsExecuted
                then
                    DeleteIntrastatJnl;
                if ("Additional Reporting Currency" <> xRec."Additional Reporting Currency") and
                   ("Additional Reporting Currency" <> '') and
                   AdjAddReportingCurr.IsExecuted
                then
                    DeleteAnalysisView;
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
        field(72; "VAT Exchange Rate Adjustment"; Option)
        {
            Caption = 'VAT Exchange Rate Adjustment';
            OptionCaption = 'No Adjustment,Adjust Amount,Adjust Additional-Currency Amount';
            OptionMembers = "No Adjustment","Adjust Amount","Adjust Additional-Currency Amount";
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

                if HideDialog then
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
                if HideDialog then
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
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced with UI Elements Removal feature.';
            ObsoleteTag = '17.0';
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
        field(110; "Acc. Sched. for Balance Sheet"; Code[10])
        {
            Caption = 'Acc. Sched. for Balance Sheet';
            TableRelation = "Acc. Schedule Name";
        }
        field(111; "Acc. Sched. for Income Stmt."; Code[10])
        {
            Caption = 'Acc. Sched. for Income Stmt.';
            TableRelation = "Acc. Schedule Name";
        }
        field(112; "Acc. Sched. for Cash Flow Stmt"; Code[10])
        {
            Caption = 'Acc. Sched. for Cash Flow Stmt';
            TableRelation = "Acc. Schedule Name";
        }
        field(113; "Acc. Sched. for Retained Earn."; Code[10])
        {
            Caption = 'Acc. Sched. for Retained Earn.';
            TableRelation = "Acc. Schedule Name";
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
                    if VATPostingSetup.FindFirst then
                        Error(
                          Text000, VATPostingSetup.TableCaption,
                          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
                          VATPostingSetup.FieldCaption("Unrealized VAT Type"), VATPostingSetup."Unrealized VAT Type");
                    TaxJurisdiction.SetFilter(
                      "Unrealized VAT Type", '>=%1', TaxJurisdiction."Unrealized VAT Type"::Percentage);
                    if TaxJurisdiction.FindFirst then
                        Error(
                          Text001, TaxJurisdiction.TableCaption,
                          TaxJurisdiction.Code, TaxJurisdiction.FieldCaption("Unrealized VAT Type"),
                          TaxJurisdiction."Unrealized VAT Type");
                end;
            end;
        }
        field(152; "Use Legacy G/L Entry Locking"; Boolean)
        {
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            Caption = 'Use Legacy G/L Entry Locking';
            ObsoleteReason = 'Legacy G/L Locking is no longer supported.';
            ObsoleteTag = '18.0';
        }
        field(160; "Payroll Trans. Import Format"; Code[20])
        {
            Caption = 'Payroll Trans. Import Format';
            TableRelation = "Data Exch. Def" WHERE(Type = CONST("Payroll Import"));
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
        field(10001; "VAT in Use"; Boolean)
        {
            Caption = 'VAT in Use';
        }
        field(10002; "Bank Rec. Adj. Doc. Nos."; Code[20])
        {
            Caption = 'Bank Rec. Adj. Doc. Nos.';
            TableRelation = "No. Series";
        }
        field(10003; "Deposit Nos."; Code[20])
        {
            Caption = 'Deposit Nos.';
            TableRelation = "No. Series";
        }
        field(10004; "SAT Certificate Thumbprint"; Text[250])
        {
            Caption = 'SAT Certificate Thumbprint';
            ObsoleteReason = 'Using Local Certificate store is deprecated. Use SAT Certificate instead that are linked to certificate table.';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(10005; "Send PDF Report"; Boolean)
        {
            Caption = 'Send PDF Report';
        }
        field(10006; "Hash Algorithm"; Option)
        {
            Caption = 'Hash Algorithm';
            OptionCaption = ',SHA-1';
            OptionMembers = ,"SHA-1";
        }
        field(10007; "PAC Code"; Code[10])
        {
            Caption = 'PAC Code';
            TableRelation = "PAC Web Service";

            trigger OnValidate()
            begin
                if "PAC Code" = '' then
                    "PAC Environment" := "PAC Environment"::Disabled;
            end;
        }
        field(10008; "PAC Environment"; Option)
        {
            Caption = 'PAC Environment';
            OptionCaption = ' ,Test,Production';
            OptionMembers = Disabled,Test,Production;
        }
        field(10009; "CFDI Enabled"; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
            begin
                if "CFDI Enabled" THEN
                    "CFDI Enabled" := CustomerConsentMgt.ConfirmUserConsent();
            end;
        }
        field(10010; "Sim. Signature"; Boolean)
        {
            Caption = 'Sim. Signature';
        }
        field(10011; "Sim. Send"; Boolean)
        {
            Caption = 'Sim. Send';
        }
        field(10012; "Sim. Request Stamp"; Boolean)
        {
            Caption = 'Sim. Request Stamp';
        }
        field(10120; "Bank Recon. with Auto. Match"; Boolean)
        {
            Caption = 'Bank Recon. with Auto. Match';
            InitValue = true;

            trigger OnValidate()
            var
                ReportSelections: Record "Report Selections";
            begin
                if "Bank Recon. with Auto. Match" then
                    CheckSelectedReports(REPORT::"Bank Account Statement", REPORT::"Bank Acc. Recon. - Test")
                else
                    CheckSelectedReports(REPORT::"Bank Reconciliation", REPORT::"Bank Rec. Test Report");
            end;
        }
        field(10121; "SAT Certificate"; Code[20])
        {
            Caption = 'SAT Certificate';
            TableRelation = "Isolated Certificate";
        }
        field(10122; "Disable CFDI Payment Details"; Boolean)
        {
            Caption = 'Disable CFDI Payment Details';
        }
        field(10123; "USD Currency Code"; Code[10])
        {
            Caption = 'USD Currency Code';
            TableRelation = Currency;
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
        Text000: Label '%1 %2 %3 have %4 to %5.';
        Text001: Label '%1 %2 have %3 to %4.';
        Text002: Label '%1 %2 %3 use %4.';
        Text004: Label '%1 must be rounded to the nearest %2.';
        Text016: Label 'Enter one number or two numbers separated by a colon. ';
        Text017: Label 'The online Help for this field describes how you can fill in the field.';
        Text018: Label 'You cannot change the contents of the %1 field because there are posted ledger entries.';
        Text021: Label 'You must close the program and start again in order to activate the amount-rounding feature.';
        Text022: Label 'You must close the program and start again in order to activate the unit-amount rounding feature.';
        Text023: Label '%1\You cannot use the same dimension twice in the same setup.';
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
        ErrorMessage: Boolean;
        DependentFieldActivatedErr: Label 'You cannot change %1 because %2 is selected.';
        AutoSelectReportTxt: Label 'Turning auto-matching on or off changes the report layouts used for bank account reconciliation.';
        UpdatedReportLayoutsTxt: Label 'We have chosen the following report layouts: %1 for %2.', Comment = '%1 report layout Caption, %2 Report layout usage';
        ReportIsSelectedTxt: Label 'No report was selected for %1. Based on the current setup of %2, a compatible report has been selected.', Comment = '%1=OptionValue,%2=FieldCaption';
        TooManyReportsAreSelectedTxt: Label 'One or more reports selected for bank reconciliation may not be compatible with the current setup of %1. Make sure the report %2 is selected for %3.', Comment = '%1=FieldCaption,%2=ReportNumber,%3=OptionValue';
        ObsoleteErr: Label 'This field is obsolete, it has been replaced by Table 248 VAT Reg. No. Srv Config.';
        UpdatedReportsPlaceholderTxt: Label '%1\\%2\\%3', Locked = true;
        RecordHasBeenRead: Boolean;

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
        Get;
        RecordHasBeenRead := true;
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

    procedure IsPostingAllowed(PostingDate: Date): Boolean
    begin
        exit(PostingDate >= "Allow Posting From");
    end;

    procedure JobQueueActive(): Boolean
    begin
        Get;
        exit("Post with Job Queue" or "Post & Print with Job Queue");
    end;

#if not CLEAN18
    [Obsolete('Legacy G/L Locking is no longer supported.', '18.0')]
    procedure OptimGLEntLockForMultiuserEnv(): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if InventorySetup.Get then
            if InventorySetup."Automatic Cost Posting" then
                exit(false);

        exit(true);
    end;
#endif

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
            Error(Text023, Dim.GetCheckDimErr);
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
        Modify;
    end;

    local procedure HideDialog(): Boolean
    begin
        exit((CurrFieldNo = 0) or not GuiAllowed);
    end;

    local procedure CheckSelectedReports(PrintingReportID: Integer; TestingReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
        PrintingReportStatus: Text;
        TestingReportStatus: Text;
    begin
        PrintingReportStatus :=
          SelectReport(ReportSelections.Usage::"B.Stmt", Format(ReportSelections.Usage::"B.Stmt"), PrintingReportID);

        TestingReportStatus :=
          SelectReport(ReportSelections.Usage::"B.Recon.Test", Format(ReportSelections.Usage::"B.Recon.Test"), TestingReportID);

        if (PrintingReportStatus <> '') or (TestingReportStatus <> '') then
            Message(StrSubstNo(UpdatedReportsPlaceholderTxt, AutoSelectReportTxt, PrintingReportStatus, TestingReportStatus));
    end;

    local procedure SelectReport(UsageValue: Enum "Report Selection Usage"; Description: Text; ReportID: Integer): Text
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, UsageValue);

        case true of
            ReportSelections.IsEmpty:
                begin
                    ReportSelections.Reset();
                    ReportSelections.InsertRecord(UsageValue, '1', ReportID);
                    exit(StrSubstNo(ReportIsSelectedTxt, Description, FieldCaption("Bank Recon. with Auto. Match")));
                end;
            ReportSelections.Count = 1:
                begin
                    ReportSelections.FindFirst;
                    if ReportSelections."Report ID" <> ReportID then begin
                        ReportSelections.Validate("Report ID", ReportID);
                        ReportSelections.Modify();
                        exit(StrSubstNo(UpdatedReportLayoutsTxt, ReportSelections."Report Caption", Description));
                    end;
                end;
            else
                exit(StrSubstNo(TooManyReportsAreSelectedTxt, FieldCaption("Bank Recon. with Auto. Match"), ReportID, Description));
        end;
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

        if not GeneralLedgerSetupRecordRef.FindFirst then
            exit(false);

        UseVATFieldRef := GeneralLedgerSetupRecordRef.Field(UseVATFieldNo);
        exit(UseVATFieldRef.Value);
    end;

    procedure CheckAllowedPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange("Allow Posting From",
          "Allow Posting To", NotificationType, DATABASE::"General Ledger Setup");
    end;

    procedure GetPmtToleranceVisible(): Boolean
    begin
        exit(("Payment Tolerance %" > 0) or ("Max. Payment Tolerance Amount" <> 0));
    end;

    [Scope('OnPrem')]
    procedure CheckIfMissingMXEInvRequiredFields(): Boolean
    begin
        Get;
        exit(("PAC Code" = '') or ("SAT Certificate" = '') or ("PAC Environment" = "PAC Environment"::Disabled));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRoundingError(var ErrorMessage: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFirstAllowedPostingDate(GeneralLedgerSetup: Record "General Ledger Setup"; var AllowedPostingDate: Date; var IsHandled: Boolean)
    begin
    end;
}

