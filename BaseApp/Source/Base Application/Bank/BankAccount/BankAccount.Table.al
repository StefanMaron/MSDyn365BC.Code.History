namespace Microsoft.Bank.BankAccount;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Intrastat;
using Microsoft.Utilities;
using System;
using System.Email;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Threading;

table 270 "Bank Account"
{
    Caption = 'Bank Account';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Bank Account List";
    LookupPageID = "Bank Account List";
    Permissions = TableData "Bank Account Ledger Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GLSetup.Get();
                    NoSeries.TestManual(GLSetup."Bank Account Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(13; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                if not LocalFunctionalityMgt.CheckBankAccNo("Bank Account No.", "Country/Region Code", "Bank Account No.") then
                    Message(Text11000000, FieldCaption("Bank Account No."), "Bank Account No.");

                OnValidateBankAccount(Rec, 'Bank Account No.');
            end;
        }
        field(14; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(18; "Chain Name"; Code[10])
        {
            Caption = 'Chain Name';
        }
        field(20; "Min. Balance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Min. Balance';
        }
        field(21; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                GeneralLedgerSetup: Record "General Ledger Setup";
                BankAccount: Record "Bank Account";
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;
                GeneralLedgerSetup.Get();
                if (("Currency Code" in ['', GeneralLedgerSetup."LCY Code"]) and (xRec."Currency Code" in ['', GeneralLedgerSetup."LCY Code"])) then
                    exit;

                BankAccount := Rec;
                BankAccount.CalcFields(Balance, "Balance (LCY)");
                BankAccount.TestField(Balance, 0);
                BankAccount.TestField("Balance (LCY)", 0);

                if not BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open) then
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.");
                BankAccLedgEntry.SetRange("Bank Account No.", "No.");
                BankAccLedgEntry.SetRange(Open, true);
                if BankAccLedgEntry.FindLast() then
                    Error(
                      Text000,
                      FieldCaption("Currency Code"));
            end;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(25; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
        }
        field(29; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(37; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(38; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("Bank Account"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(41; "Last Statement No."; Code[20])
        {
            Caption = 'Last Statement No.';
        }
        field(42; "Last Payment Statement No."; Code[20])
        {
            Caption = 'Last Payment Statement No.';

            trigger OnValidate()
            begin
                if IncStr("Last Payment Statement No.") = '' then
                    Error(UnincrementableStringErr, FieldCaption("Last Payment Statement No."));
            end;
        }
        field(43; "Pmt. Rec. No. Series"; Code[20])
        {
            Caption = 'Payment Reconciliation No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            var
                BankAccReconciliation: Record "Bank Acc. Reconciliation";
            begin
                if "Pmt. Rec. No. Series" = '' then begin
                    BankAccReconciliation.SetRange("Bank Account No.", "No.");
                    BankAccReconciliation.SetRange("Statement Type", BankAccReconciliation."Statement Type"::"Payment Application");
                    if BankAccReconciliation.FindLast() then
                        "Last Payment Statement No." := BankAccReconciliation."Statement No.";
                end;
            end;
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(55; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(56; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(57; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(58; Balance; Decimal)
        {
            AccessByPermission = TableData "Bank Account Ledger Entry" = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Balance (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Bank Account Ledger Entry" = R;
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field("Date Filter")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Total on Checks"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Check Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                 "Entry Status" = filter(Posted),
                                                                 "Statement Status" = filter(<> Closed)));
            Caption = 'Total on Checks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Use as Default for Currency"; Boolean)
        {
            Caption = 'Use as Default for Currency';
            trigger OnValidate()
            begin
                if "Use as Default for Currency" = true then
                    EnsureUniqueForCurrency();
            end;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(89; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Removed;
            SubType = Bitmap;
            ObsoleteTag = '18.0';
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(93; "Last Check No."; Code[20])
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Last Check No.';
        }
        field(94; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';
        }
        field(95; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("No."),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; "Balance at Date (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Debit Amount" where("Bank Account No." = field("No."),
                                                                                "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Credit Amount" where("Bank Account No." = field("No."),
                                                                                 "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                 "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Debit Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                      "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                      "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Bank Account Ledger Entry"."Credit Amount (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(101; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Branch No.');
            end;
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
#if not CLEAN24
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
            ObsoleteReason = 'Field length will be increased to 255.';
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
        }
#else
#pragma warning disable AS0086
        field(103; "Home Page"; Text[255])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
#pragma warning restore AS0086
#endif
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Check Report ID"; Integer)
        {
            Caption = 'Check Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(109; "Check Report Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Report),
                                                                        "Object ID" = field("Check Report ID")));
            Caption = 'Check Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(111; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(113; "Bank Statement Import Format"; Code[20])
        {
            Caption = 'Bank Statement Import Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Import));
        }
        field(115; "Credit Transfer Msg. Nos."; Code[20])
        {
            Caption = 'Credit Transfer Msg. Nos.';
            TableRelation = "No. Series";
        }
        field(116; "Direct Debit Msg. Nos."; Code[20])
        {
            Caption = 'Direct Debit Msg. Nos.';
            TableRelation = "No. Series";
        }
        field(117; "SEPA Direct Debit Exp. Format"; Code[20])
        {
            Caption = 'SEPA Direct Debit Exp. Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Export));
        }
        field(121; "Bank Stmt. Service Record ID"; RecordID)
        {
            Caption = 'Bank Stmt. Service Record ID';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Handled: Boolean;
            begin
                if Format("Bank Stmt. Service Record ID") = '' then
                    OnUnlinkStatementProviderEvent(Rec, Handled);
            end;
        }
        field(123; "Transaction Import Timespan"; Integer)
        {
            Caption = 'Transaction Import Timespan';
        }
        field(124; "Automatic Stmt. Import Enabled"; Boolean)
        {
            Caption = 'Automatic Stmt. Import Enabled';

            trigger OnValidate()
            begin
                if "Automatic Stmt. Import Enabled" then begin
                    if not IsAutoLogonPossible() then
                        Error(MFANotSupportedErr);

                    if not ("Transaction Import Timespan" in [0 .. 9999]) then
                        Error(TransactionImportTimespanMustBePositiveErr);
                    ScheduleBankStatementDownload()
                end else
                    UnscheduleBankStatementDownload();
            end;
        }
        field(130; IntercompanyEnable; Boolean)
        {
            Caption = 'Enable for Intercompany transactions';
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(170; "Creditor No."; Code[35])
        {
            Caption = 'Creditor No.';
        }
        field(1210; "Payment Export Format"; Code[20])
        {
            Caption = 'Payment Export Format';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const(Export));
        }
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        field(1213; "Bank Name - Data Conversion"; Text[50])
        {
            Caption = 'Bank Name - Data Conversion';
            ObsoleteState = Removed;
            ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
            ObsoleteTag = '15.0';
        }
        field(1250; "Match Tolerance Type"; Option)
        {
            Caption = 'Match Tolerance Type';
            OptionCaption = 'Percentage,Amount';
            OptionMembers = Percentage,Amount;

            trigger OnValidate()
            begin
                if "Match Tolerance Type" <> xRec."Match Tolerance Type" then
                    "Match Tolerance Value" := 0;
            end;
        }
        field(1251; "Match Tolerance Value"; Decimal)
        {
            Caption = 'Match Tolerance Value';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Match Tolerance Value" < 0 then
                    Error(InvalidValueErr);

                if "Match Tolerance Type" = "Match Tolerance Type"::Percentage then
                    if "Match Tolerance Value" > 99 then
                        Error(InvalidPercentageValueErr, FieldCaption("Match Tolerance Type"),
                          Format("Match Tolerance Type"::Percentage));
            end;
        }
        field(1252; "Disable Automatic Pmt Matching"; Boolean)
        {
            Caption = 'Disable Automatic Payment Matching';
        }
        field(1253; "Disable Bank Rec. Optimization"; Boolean)
        {
            Caption = 'Disable Bank Reconciliation Optimization';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not "Disable Bank Rec. Optimization" then
                    exit;
                if not GuiAllowed() then
                    exit;
                if not Confirm(DisablingMakesBankRecAutomatchSlowerWarnMsg) then
                    Error('');
            end;
        }
        field(1260; "Positive Pay Export Code"; Code[20])
        {
            Caption = 'Positive Pay Export Code';
            TableRelation = "Bank Export/Import Setup".Code where(Direction = const("Export-Positive Pay"));
        }
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Mobile Phone No.") do
                    if Char.IsLetter("Mobile Phone No."[i]) then
                        FieldError("Mobile Phone No.", PhoneNoCannotContainLettersErr);
            end;
        }
        field(11000000; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
        }
        field(11000001; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
        }
        field(11000002; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code"
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000003; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            TableRelation = if ("Acc. Hold. Country/Region Code" = const('')) "Post Code".City
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000004; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11000005; Proposal; Decimal)
        {
            CalcFormula = sum("Proposal Line".Amount where("Our Bank No." = field("No."),
                                                            Process = const(true)));
            Caption = 'Proposal';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11000006; "Payment History"; Decimal)
        {
            CalcFormula = sum("Payment History Line".Amount where("Our Bank" = field("No."),
                                                                   Status = filter(New | Transmitted | "Request for Cancellation")));
            Caption = 'Payment History';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11000007; "Creditor Identifier"; Code[19])
        {
            Caption = 'Creditor Identifier';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Bank Acc. Posting Group")
        {
        }
        key(Key4; "Currency Code")
        {
        }
        key(Key5; "Country/Region Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Bank Account No.", "Currency Code")
        {
        }
        fieldgroup(Brick; "No.", Name, "Bank Account No.", "Currency Code", Image)
        {
        }
    }

    trigger OnDelete()
    begin
        CheckDeleteBalancingBankAccount();

        MoveEntries.MoveBankAccEntries(Rec);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Bank Account");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        UpdateContFromBank.OnDelete(Rec);

        DimMgt.DeleteDefaultDim(DATABASE::"Bank Account", "No.");
    end;

    trigger OnInsert()
    var
        BankAccount: Record "Bank Account";
#if not CLEAN24
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
#endif
    begin
        if "No." = '' then begin
            GLSetup.Get();
            GLSetup.TestField("Bank Account Nos.");
#if not CLEAN24
            NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(GLSetup."Bank Account Nos.", xRec."No. Series", 0D, "No.", "No. Series", IsHandled);
            if not IsHandled then begin
                if NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := GLSetup."Bank Account Nos.";
                "No." := NoSeries.GetNextNo("No. Series");
                BankAccount.ReadIsolation(IsolationLevel::ReadUncommitted);
                BankAccount.SetLoadFields("No.");
                while BankAccount.Get("No.") do
                    "No." := NoSeries.GetNextNo("No. Series");
                NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", GLSetup."Bank Account Nos.", 0D, "No.");
            end;
#else
			if NoSeries.AreRelated(GLSetup."Bank Account Nos.", xRec."No. Series") then
				"No. Series" := xRec."No. Series"
			else
				"No. Series" := GLSetup."Bank Account Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            BankAccount.ReadIsolation(IsolationLevel::ReadUncommitted);
            BankAccount.SetLoadFields("No.");
            while BankAccount.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
#endif
        end;

        if not InsertFromContact then
            UpdateContFromBank.OnInsert(Rec);

        DimMgt.UpdateDefaultDim(
          DATABASE::"Bank Account", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        if IsContactUpdateNeeded() then begin
            Modify();
            UpdateContFromBank.OnModify(Rec);
            if not Find() then begin
                Reset();
                if Find() then;
            end;
        end;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Bank Account", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Bank Account", xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CommentLine: Record "Comment Line";
        PostCode: Record "Post Code";
        NoSeries: Codeunit "No. Series";
        MoveEntries: Codeunit MoveEntries;
        UpdateContFromBank: Codeunit "BankCont-Update";
        DimMgt: Codeunit DimensionManagement;
        InsertFromContact: Boolean;

        Text000: Label 'You cannot change %1 because there are one or more open ledger entries for this bank account.';
        Text003: Label 'Do you wish to create a contact for %1 %2?';
        Text11000000: Label '%1 %2 may not be filled out correctly.';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a %1 or an %2.';
        InvalidPercentageValueErr: Label 'If %1 is %2, then the value must be between 0 and 99.', Comment = '%1 is "field caption and %2 is "Percentage"';
        InvalidValueErr: Label 'The value must be positive.';
        DataExchNotSetErr: Label 'The Data Exchange Code field must be filled.';
        BankStmtScheduledDownloadDescTxt: Label '%1 Bank Statement Import', Comment = '%1 - Bank Account name';
        JobQEntriesCreatedQst: Label 'A job queue entry for import of bank statements has been created.\\Do you want to open the Job Queue Entry window?';
        TransactionImportTimespanMustBePositiveErr: Label 'The value in the Number of Days Included field must be a positive number not greater than 9999.';
        MFANotSupportedErr: Label 'Cannot setup automatic bank statement import because the selected bank requires multi-factor authentication.';
        BankAccNotLinkedErr: Label 'This bank account is not linked to an online bank account.';
        AutoLogonNotPossibleErr: Label 'Automatic logon is not possible for this bank account.';
        CancelTxt: Label 'Cancel';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = caption of field (Last Payment Statement No.)';
        CannotDeleteBalancingBankAccountErr: Label 'You cannot delete bank account that is used as balancing account in the Payment Registration Setup.', Locked = true;
        ConfirmDeleteBalancingBankAccountQst: Label 'This bank account is used as balancing account on the Payment Registration Setup page.\\Are you sure you want to delete it?';
        DisablingMakesBankRecAutomatchSlowerWarnMsg: Label 'Disabling the optimization will make automatic bank matching slower, but it will be more precise. It is useful to disable the optimization if you have several open bank ledger entries with the same amount and posting date that you need to automatch. Do you want to turn off the optimization?';

    procedure AssistEdit(OldBankAcc: Record "Bank Account"): Boolean
    var
        DefaultSelectedNoSeries: Code[20];
    begin
        GLSetup.Get();
        GLSetup.TestField("Bank Account Nos.");
        if "No. Series" <> '' then
            DefaultSelectedNoSeries := "No. Series"
        else
            DefaultSelectedNoSeries := OldBankAcc."No. Series";

        if NoSeries.LookupRelatedNoSeries(GLSetup."Bank Account Nos.", DefaultSelectedNoSeries, "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Bank Account", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowContact()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
        if "No." = '' then
            exit;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        ContBusRel.SetRange("No.", "No.");
        if not ContBusRel.FindFirst() then begin
            if not Confirm(Text003, false, TableCaption(), "No.") then
                exit;
            UpdateContFromBank.InsertNewContact(Rec, false);
            ContBusRel.FindFirst();
        end;
        Commit();

        Cont.FilterGroup(2);
        Cont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        Cont.SetRange("Company No.", ContBusRel."Contact No.");
        RunContactListPage(Cont);
    end;

    procedure SetInsertFromContact(FromContact: Boolean)
    begin
        InsertFromContact := FromContact;
    end;

    procedure CopyBankFieldsFromCompanyInfo(CompanyInformation: Record "Company Information")
    begin
        "Bank Account No." := CompanyInformation."Bank Account No.";
        "Bank Branch No." := CompanyInformation."Bank Branch No.";
        Name := CompanyInformation."Bank Name";
        IBAN := CompanyInformation.IBAN;
        "SWIFT Code" := CompanyInformation."SWIFT Code";
        OnAfterCopyBankFieldsFromCompanyInfo(Rec, CompanyInformation);
    end;

    procedure GetPaymentExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure GetPaymentExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetDDExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing Codeunit ID");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure GetDDExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
    end;

    procedure GetDDExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
        TestField("SEPA Direct Debit Exp. Format");
        BankExportImportSetup.Get("SEPA Direct Debit Exp. Format");
    end;

    procedure GetCreditTransferMessageNo(): Code[20]
    var
        CreditTransferMsgNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetCreditTransferMessageNo(CreditTransferMsgNo, IsHandled);
        if IsHandled then
            exit(CreditTransferMsgNo);

        TestField("Credit Transfer Msg. Nos.");
        exit(NoSeries.GetNextNo("Credit Transfer Msg. Nos.", Today()));
    end;

    procedure GetDirectDebitMessageNo(): Code[20]
    var
        DirectDebitMsgNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetDirectDebitMessageNo(DirectDebitMsgNo, IsHandled);
        if IsHandled then
            exit(DirectDebitMsgNo);

        TestField("Direct Debit Msg. Nos.");
        exit(NoSeries.GetNextNo("Direct Debit Msg. Nos.", Today()));
    end;

    procedure GetDefaultBankAccountNoForCurrency(CurrencyCode: Code[20]) BankAccountNo: Code[20]
    begin
        SetLoadFields("Currency Code", "Use as Default for Currency");
        SetRange("Currency Code", CurrencyCode);
        SetRange("Use as Default for Currency", true);
        if FindFirst() then;
        exit("No.");
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Bank Account", GetPosition());
    end;

    procedure GetCreditLimit(): Decimal
    begin
        CalcFields(Balance, Proposal, "Payment History");
        exit(Balance - "Min. Balance" - Proposal - "Payment History");
    end;

    procedure GetDataExchDef(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDefCodeResponse: Code[20];
        Handled: Boolean;
    begin
        OnGetDataExchangeDefinitionEvent(DataExchDefCodeResponse, Handled);
        if not Handled then begin
            TestField("Bank Statement Import Format");
            DataExchDefCodeResponse := "Bank Statement Import Format";
        end;

        if DataExchDefCodeResponse = '' then
            Error(DataExchNotSetErr);

        BankExportImportSetup.Get(DataExchDefCodeResponse);
        BankExportImportSetup.TestField("Data Exch. Def. Code");

        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Bank Statement Import");
    end;

    procedure GetDataExchDefPaymentExport(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
        BankExportImportSetup.TestField("Data Exch. Def. Code");
        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Payment Export");
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo();
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr, FieldCaption("Bank Account No."), FieldCaption(IBAN));
    end;

    procedure GetBankAccountNo(): Text
    var
        Handled: Boolean;
        ResultBankAccountNo: Text;
    begin
        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    procedure IsInLocalCurrency(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if "Currency Code" = '' then
            exit(true);

        GeneralLedgerSetup.Get();
        exit("Currency Code" = GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    procedure GetPosPayExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Positive Pay Export Code");
        BankExportImportSetup.Get("Positive Pay Export Code");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure IsLinkedToBankStatementServiceProvider(): Boolean
    var
        IsBankAccountLinked: Boolean;
    begin
        OnCheckLinkedToStatementProviderEvent(Rec, IsBankAccountLinked);
        exit(IsBankAccountLinked);
    end;

    procedure StatementProvidersExist(): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        exit(not TempNameValueBuffer.IsEmpty);
    end;

    procedure LinkStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnLinkStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure SimpleLinkStatementProvider(var OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnSimpleLinkStatementProviderEvent(OnlineBankAccLink, StatementProvider);
    end;

    procedure UnlinkStatementProvider()
    var
        Handled: Boolean;
    begin
        OnUnlinkStatementProviderEvent(Rec, Handled);
    end;

    procedure RefreshStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnRefreshStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure RenewAccessConsentStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnRenewAccessConsentStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure EditAccountStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnEditAccountStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure UpdateBankAccountLinking()
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService();

        if StatementProvider <> '' then
            OnUpdateBankAccountLinkingEvent(Rec, StatementProvider);
    end;

    procedure GetUnlinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet() then
            repeat
                if not BankAccount.IsLinkedToBankStatementServiceProvider() then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert();
                end;
            until BankAccount.Next() = 0;
    end;

    procedure GetLinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet() then
            repeat
                if BankAccount.IsLinkedToBankStatementServiceProvider() then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert();
                end;
            until BankAccount.Next() = 0;
    end;

    local procedure EnsureUniqueForCurrency()
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetLoadFields("Currency Code", "Use as Default for Currency");
        BankAccount.SetRange("Currency Code", "Currency Code");
        BankAccount.SetFilter("No.", '<>%1', "No.");
        BankAccount.SetRange("Use as Default for Currency", true);
        if BankAccount.FindFirst() then
            BankAccount.TestField("Use as Default for Currency", false);
    end;

    local procedure SelectBankLinkingService(): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        OptionStr: Text;
        OptionNo: Integer;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);

        if TempNameValueBuffer.IsEmpty() then
            exit(''); // Action should not be visible in this case so should not occur

        if (TempNameValueBuffer.Count = 1) or (not GuiAllowed) then
            exit(TempNameValueBuffer.Name);

        TempNameValueBuffer.FindSet();
        repeat
            OptionStr += StrSubstNo('%1,', TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next() = 0;
        OptionStr += CancelTxt;

        OptionNo := StrMenu(OptionStr);
        if (OptionNo = 0) or (OptionNo = TempNameValueBuffer.Count + 1) then
            exit;

        TempNameValueBuffer.SetRange(Value, SelectStr(OptionNo, OptionStr));
        TempNameValueBuffer.FindFirst();

        exit(TempNameValueBuffer.Name);
    end;

    procedure IsAutoLogonPossible(): Boolean
    var
        AutoLogonPossible: Boolean;
    begin
        AutoLogonPossible := true;
        OnCheckAutoLogonPossibleEvent(Rec, AutoLogonPossible);
        exit(AutoLogonPossible)
    end;

    local procedure ScheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsLinkedToBankStatementServiceProvider() then
            Error(BankAccNotLinkedErr);
        if not IsAutoLogonPossible() then
            Error(AutoLogonNotPossibleErr);

        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Automatic Import of Bank Stmt.", RecordId);
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(BankStmtScheduledDownloadDescTxt, Name), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Notify On Success" := false;
        JobQueueEntry."No. of Minutes between Runs" := 121;
        JobQueueEntry."Maximum No. of Attempts to Run" := 4;
        JobQueueEntry."Rerun Delay (sec.)" := 25 * 60;
        JobQueueEntry.Modify();
        if Confirm(JobQEntriesCreatedQst) then
            ShowBankStatementDownloadJobQueueEntry();
    end;

    local procedure UnscheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll();
    end;

    procedure CreateNewAccount(OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        GeneralLedgerSetup.Get();
        Init();
        Validate("Bank Account No.", OnlineBankAccLink."Bank Account No.");
        Validate(Name, OnlineBankAccLink.Name);
        if OnlineBankAccLink."Currency Code" <> '' then
            CurrencyCode := GeneralLedgerSetup.GetCurrencyCode(OnlineBankAccLink."Currency Code");
        Validate("Currency Code", CurrencyCode);
        Validate(Contact, OnlineBankAccLink.Contact);
    end;

    local procedure ShowBankStatementDownloadJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if JobQueueEntry.FindFirst() then
            PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
    end;

    local procedure SetAutomaticImportJobQueueEntryFilters(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Automatic Import of Bank Stmt.");
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
    end;

    local procedure CheckDeleteBalancingBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.SetRange("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetup.SetRange("Bal. Account No.", "No.");
        if PaymentRegistrationSetup.IsEmpty() then
            exit;

        if not GuiAllowed then
            Error(CannotDeleteBalancingBankAccountErr);

        if not Confirm(ConfirmDeleteBalancingBankAccountQst) then
            Error('');
    end;

    procedure GetOnlineFeedStatementStatus(var OnlineFeedStatus: Option; var Linked: Boolean)
    begin
        Linked := false;
        OnlineFeedStatus := OnlineFeedStatementStatus::"Not Linked";
        if IsLinkedToBankStatementServiceProvider() then begin
            Linked := true;
            OnlineFeedStatus := OnlineFeedStatementStatus::Linked;
            if IsScheduledBankStatement() then
                OnlineFeedStatus := OnlineFeedStatementStatus::"Linked and Auto. Bank Statement Enabled";
        end;
    end;

    local procedure IsScheduledBankStatement(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(JobQueueEntry.FindFirst());
    end;

    procedure DisableStatementProviders()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        if TempNameValueBuffer.FindSet() then
            repeat
                OnDisableStatementProviderEvent(TempNameValueBuffer.Name);
            until TempNameValueBuffer.Next() = 0;
    end;

    local procedure IsContactUpdateNeeded(): Boolean
    var
        BankContUpdate: Codeunit "BankCont-Update";
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (Name <> xRec.Name) or
          ("Search Name" <> xRec."Search Name") or
          ("Name 2" <> xRec."Name 2") or
          (Address <> xRec.Address) or
          ("Address 2" <> xRec."Address 2") or
          (City <> xRec.City) or
          ("Phone No." <> xRec."Phone No.") or
          ("Mobile Phone No." <> xRec."Mobile Phone No.") or
          ("Telex No." <> xRec."Telex No.") or
          ("Territory Code" <> xRec."Territory Code") or
          ("Currency Code" <> xRec."Currency Code") or
          ("Language Code" <> xRec."Language Code") or
          ("Format Region" <> xRec."Format Region") or
          ("Our Contact Code" <> xRec."Our Contact Code") or
          ("Country/Region Code" <> xRec."Country/Region Code") or
          ("Fax No." <> xRec."Fax No.") or
          ("Telex Answer Back" <> xRec."Telex Answer Back") or
          ("Post Code" <> xRec."Post Code") or
          (County <> xRec.County) or
          ("E-Mail" <> xRec."E-Mail") or
          ("Home Page" <> xRec."Home Page");

        if not UpdateNeeded and not IsTemporary then
            UpdateNeeded := BankContUpdate.ContactNameIsBlank("No.");

        OnAfterIsUpdateNeeded(xRec, Rec, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    local procedure RunContactListPage(var Contact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunContactListPage(Contact, IsHandled);
        if IsHandled then
            exit;

        Page.Run(Page::"Contact List", Contact);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsUpdateNeeded(BankAccount: Record "Bank Account"; xBankAccount: Record "Bank Account"; var UpdateNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBankFieldsFromCompanyInfo(var BankAccount: Record "Bank Account"; CompanyInformation: Record "Company Information")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIBAN(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinkedToStatementProviderEvent(var BankAccount: Record "Bank Account"; var IsLinked: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account is linked to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAutoLogonPossibleEvent(var BankAccount: Record "Bank Account"; var AutoLogonPossible: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account can be logged on to without multi-factor authentication
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnlinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var Handled: Boolean)
    begin
        // The subscriber of this event should unlink the bank account from a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    procedure OnMarkAccountLinkedEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var BankAccount: Record "Bank Account")
    begin
        // The subscriber of this event should Mark the account linked to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSimpleLinkStatementProviderEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should refresh the bank account linked to a bank statement provider service
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetDataExchangeDefinitionEvent(var DataExchDefCodeResponse: Code[20]; var Handled: Boolean)
    begin
        // This event should retrieve the data exchange definition format for processing the online feeds
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankAccountLinkingEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // This event should handle updating of the single or multiple bank accounts
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetStatementProvidersEvent(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        // The subscriber of this event should insert a unique identifier (Name) and friendly name of the provider (Value)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableStatementProviderEvent(ProviderName: Text)
    begin
        // The subscriber of this event should disable the statement provider with the given name
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenewAccessConsentStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should provide the UI for renewing access consent to the linked open banking bank account
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEditAccountStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should provide the UI for editing the information about the online bank account
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunContactListPage(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBankAccount(var BankAccount: Record "Bank Account"; FieldToValidate: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBankAccount(var Handled: Boolean; BankAccount: Record "Bank Account"; var ResultBankAccountNo: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var BankAccount: Record "Bank Account"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var BankAccount: Record "Bank Account"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCreditTransferMessageNo(var CreditTransferMsgNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectDebitMessageNo(var DirectDebitMsgNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

