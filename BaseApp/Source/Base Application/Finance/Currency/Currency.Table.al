namespace Microsoft.Finance.Currency;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Integration.Dataverse;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.HumanResources.Payables;
using System.Utilities;
using System.Reflection;

table 4 Currency
{
    Caption = 'Currency';
    LookupPageID = Currencies;
    Permissions = tabledata "General Ledger Setup" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
            begin
                if Symbol = '' then
                    Symbol := ResolveCurrencySymbol(Code);

                if (Code <> '') and (xRec.Code = '') then
                    UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification(Code);
            end;
        }
        field(2; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(3; "Last Date Adjusted"; Date)
        {
            Caption = 'Last Date Adjusted';
            Editable = false;
        }
        field(4; "ISO Code"; Code[3])
        {
            Caption = 'ISO Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Regex: Codeunit Regex;
            begin
                if "ISO Code" = '' then
                    exit;
                if StrLen("ISO Code") < MaxStrLen("ISO Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Code"), MaxStrLen("ISO Code"), "ISO Code");
                if not Regex.IsMatch("ISO Code", '^[a-zA-Z]*$') then
                    FieldError("ISO Code", ASCIILetterErr);
            end;
        }
        field(5; "ISO Numeric Code"; Code[3])
        {
            Caption = 'ISO Numeric Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "ISO Numeric Code" = '' then
                    exit;
                if StrLen("ISO Numeric Code") < MaxStrLen("ISO Numeric Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Numeric Code"), MaxStrLen("ISO Numeric Code"), "ISO Numeric Code");
                if not TypeHelper.IsNumeric("ISO Numeric Code") then
                    FieldError("ISO Numeric Code", NumericErr);
            end;
        }
        field(6; "Unrealized Gains Acc."; Code[20])
        {
            Caption = 'Unrealized Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Unrealized Gains Acc.");
            end;
        }
        field(7; "Realized Gains Acc."; Code[20])
        {
            Caption = 'Realized Gains Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized Gains Acc.");
            end;
        }
        field(8; "Unrealized Losses Acc."; Code[20])
        {
            Caption = 'Unrealized Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Unrealized Losses Acc.");
            end;
        }
        field(9; "Realized Losses Acc."; Code[20])
        {
            Caption = 'Realized Losses Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized Losses Acc.");
            end;
        }
        field(10; "Invoice Rounding Precision"; Decimal)
        {
            AutoFormatExpression = Code;
            DecimalPlaces = 2 : 5;
            Caption = 'Invoice Rounding Precision';
            InitValue = 0.01;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then
                    if "Invoice Rounding Precision" <> Round("Invoice Rounding Precision", "Amount Rounding Precision") then
                        FieldError(
                          "Invoice Rounding Precision",
                          StrSubstNo(Text000, "Amount Rounding Precision"));
            end;
        }
        field(12; "Invoice Rounding Type"; Option)
        {
            Caption = 'Invoice Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(13; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DecimalPlaces = 2 : 5;
            InitValue = 0.01;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Amount Rounding Precision" <> 0 then begin
                    "Invoice Rounding Precision" := Round("Invoice Rounding Precision", "Amount Rounding Precision");
                    if "Amount Rounding Precision" > "Invoice Rounding Precision" then
                        "Invoice Rounding Precision" := "Amount Rounding Precision";
                end;
            end;
        }
        field(14; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DecimalPlaces = 0 : 9;
            InitValue = 0.00001;
            MinValue = 0;
        }
        field(15; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(17; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
            InitValue = '2:2';
            NotBlank = true;

            trigger OnValidate()
            begin
                GLSetup.CheckDecimalPlacesFormat("Amount Decimal Places");
            end;
        }
        field(18; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
            InitValue = '2:5';
            NotBlank = true;

            trigger OnValidate()
            begin
                GLSetup.CheckDecimalPlacesFormat("Unit-Amount Decimal Places");
            end;
        }
        field(19; "Customer Filter"; Code[20])
        {
            Caption = 'Customer Filter';
            FieldClass = FlowFilter;
            TableRelation = Customer;
        }
        field(20; "Vendor Filter"; Code[20])
        {
            Caption = 'Vendor Filter';
            FieldClass = FlowFilter;
            TableRelation = Vendor;
        }
        field(21; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(22; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(23; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(24; "Cust. Ledg. Entries in Filter"; Boolean)
        {
            CalcFormula = exist("Cust. Ledger Entry" where("Customer No." = field("Customer Filter"),
                                                            "Currency Code" = field(Code)));
            Caption = 'Cust. Ledg. Entries in Filter';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Customer Balance"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer Filter"),
                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                         "Posting Date" = field("Date Filter"),
                                                                         "Currency Code" = field(Code)));
            Caption = 'Customer Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Customer Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Outstanding Amount" where("Document Type" = const(Order),
                                                                       "Bill-to Customer No." = field("Customer Filter"),
                                                                       "Currency Code" = field(Code),
                                                                       "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                       "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Customer Outstanding Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Customer Shipped Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Shipped Not Invoiced" where("Document Type" = const(Order),
                                                                         "Bill-to Customer No." = field("Customer Filter"),
                                                                         "Currency Code" = field(Code),
                                                                         "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                         "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Customer Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Customer Balance Due"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Customer No." = field("Customer Filter"),
                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                         "Initial Entry Due Date" = field("Date Filter"),
                                                                         "Posting Date" = field(upperlimit("Date Filter")),
                                                                         "Currency Code" = field(Code)));
            Caption = 'Customer Balance Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Vendor Ledg. Entries in Filter"; Boolean)
        {
            CalcFormula = exist("Vendor Ledger Entry" where("Vendor No." = field("Vendor Filter"),
                                                             "Currency Code" = field(Code)));
            Caption = 'Vendor Ledg. Entries in Filter';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Vendor Balance"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("Vendor Filter"),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field(Code)));
            Caption = 'Vendor Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Vendor Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount" where("Document Type" = const(Order),
                                                                          "Pay-to Vendor No." = field("Vendor Filter"),
                                                                          "Currency Code" = field(Code),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Vendor Outstanding Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Vendor Amt. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Amt. Rcd. Not Invoiced" where("Document Type" = const(Order),
                                                                              "Pay-to Vendor No." = field("Vendor Filter"),
                                                                              "Currency Code" = field(Code),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Vendor Amt. Rcd. Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Vendor Balance Due"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("Vendor Filter"),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Initial Entry Due Date" = field("Date Filter"),
                                                                           "Posting Date" = field(upperlimit("Date Filter")),
                                                                           "Currency Code" = field(Code)));
            Caption = 'Vendor Balance Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "Customer Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Customer No." = field("Customer Filter"),
                                                                                 "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                 "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = field("Date Filter"),
                                                                                 "Currency Code" = field(Code)));
            Caption = 'Customer Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "Vendor Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("Vendor Filter"),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field(Code)));
            Caption = 'Vendor Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Realized G/L Gains Account"; Code[20])
        {
            Caption = 'Realized G/L Gains Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized G/L Gains Account");
            end;
        }
        field(41; "Realized G/L Losses Account"; Code[20])
        {
            Caption = 'Realized G/L Losses Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Realized G/L Losses Account");
            end;
        }
        field(44; "Appln. Rounding Precision"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Appln. Rounding Precision';
            MinValue = 0;
        }
        field(45; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
        }
        field(46; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(47; "Residual Gains Account"; Code[20])
        {
            Caption = 'Residual Gains Account';
            TableRelation = "G/L Account";
        }
        field(48; "Residual Losses Account"; Code[20])
        {
            Caption = 'Residual Losses Account';
            TableRelation = "G/L Account";
        }
        field(50; "Conv. LCY Rndg. Debit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Debit Acc.';
            TableRelation = "G/L Account";
        }
        field(51; "Conv. LCY Rndg. Credit Acc."; Code[20])
        {
            Caption = 'Conv. LCY Rndg. Credit Acc.';
            TableRelation = "G/L Account";
        }
        field(52; "Max. VAT Difference Allowed"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Max. VAT Difference Allowed';

            trigger OnValidate()
            begin
                if "Max. VAT Difference Allowed" <> Round("Max. VAT Difference Allowed", "Amount Rounding Precision") then
                    Error(
                      Text001,
                      FieldCaption("Max. VAT Difference Allowed"), "Amount Rounding Precision");

                "Max. VAT Difference Allowed" := Abs("Max. VAT Difference Allowed");
            end;
        }
        field(53; "VAT Rounding Type"; Option)
        {
            Caption = 'VAT Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(54; "Payment Tolerance %"; Decimal)
        {
            Caption = 'Payment Tolerance %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(55; "Max. Payment Tolerance Amount"; Decimal)
        {
            AutoFormatExpression = Code;
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance Amount';
            Editable = false;
            MinValue = 0;
        }
        field(56; Symbol; Text[10])
        {
            Caption = 'Symbol';
        }
        field(57; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
#if not CLEAN23
            ObsoleteState = Pending;
            ObsoleteTag = '23.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
        }
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dataverse';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Currency)));
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(11760; "Customs Currency Code"; Code[10])
        {
            Caption = 'Customs Currency Code';
            TableRelation = Currency;
            ObsoleteState = Removed;
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; SystemModifiedAt)
        {
        }
#if not CLEAN23
        key(Key3; "Coupled to CRM")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteTag = '23.0';
        }
#endif
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
    begin
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Currency Code", Code);
        if not CustLedgEntry.IsEmpty() then
            Error(Text002, CustLedgEntry.TableCaption(), TableCaption(), Code);

        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Currency Code", Code);
        if not VendLedgEntry.IsEmpty() then
            Error(Text002, VendLedgEntry.TableCaption(), TableCaption(), Code);

        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetRange("Currency Code", Code);
        if not EmplLedgEntry.IsEmpty() then
            Error(Text002, EmplLedgEntry.TableCaption(), TableCaption(), Code);

        CurrExchRate.SetRange("Currency Code", Code);
        CurrExchRate.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestField(Code);

        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        TypeHelper: Codeunit "Type Helper";
        AccountSuggested: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must be rounded to the nearest %1';
        Text001: Label '%1 must be rounded to the nearest %2.';
        Text002: Label 'There is one or more opened entries in the %1 table using %2 %3.', Comment = '1 either customer or vendor ledger entry table 2 name co currency table 3 currencency code';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        IncorrectEntryTypeErr: Label 'Incorrect Entry Type %1.';
#pragma warning restore AA0470
        EuroDescriptionTxt: Label 'Euro', Comment = 'Currency Description';
        CanadiandollarDescriptionTxt: Label 'Canadian dollar', Comment = 'Currency Description';
        BritishpoundDescriptionTxt: Label 'Pound Sterling', Comment = 'Currency Description';
        USdollarDescriptionTxt: Label 'US dollar', Comment = 'Currency Description';
        ISOCodeLengthErr: Label 'The length of the string is %1, but it must be equal to %2 characters. Value: %3.', Comment = '%1, %2 - numbers, %3 - actual value';
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';
        NoAccountSuggestedMsg: Label 'Cannot suggest G/L accounts as there is nothing to base suggestion on.';

    procedure InitRoundingPrecision()
    begin
        GLSetup.Get();
        if GLSetup."Amount Rounding Precision" <> 0 then
            "Amount Rounding Precision" := GLSetup."Amount Rounding Precision"
        else
            "Amount Rounding Precision" := 0.01;
        if GLSetup."Unit-Amount Rounding Precision" <> 0 then
            "Unit-Amount Rounding Precision" := GLSetup."Unit-Amount Rounding Precision"
        else
            "Unit-Amount Rounding Precision" := 0.00001;
        "Max. VAT Difference Allowed" := GLSetup."Max. VAT Difference Allowed";
        "VAT Rounding Type" := GLSetup."VAT Rounding Type";
        "Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
        "Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";

        OnAfterInitRoundingPrecision(Rec, xRec, GLSetup);
    end;

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    procedure VATRoundingDirection(): Text[1]
    begin
        case "VAT Rounding Type" of
            "VAT Rounding Type"::Nearest:
                exit('=');
            "VAT Rounding Type"::Up:
                exit('>');
            "VAT Rounding Type"::Down:
                exit('<');
        end;
    end;

    procedure InvoiceRoundingDirection(): Text[1]
    begin
        case "Invoice Rounding Type" of
            "Invoice Rounding Type"::Nearest:
                exit('=');
            "Invoice Rounding Type"::Up:
                exit('>');
            "Invoice Rounding Type"::Down:
                exit('<');
        end;
    end;

    procedure CheckAmountRoundingPrecision()
    begin
        TestField("Unit-Amount Rounding Precision");
        TestField("Amount Rounding Precision");
    end;

    procedure GetGainLossAccount(DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"): Code[20]
    begin
        OnBeforeGetGainLossAccount(Rec, DtldCVLedgEntryBuf);

        case DtldCVLedgEntryBuf."Entry Type" of
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Loss":
                exit(GetUnrealizedLossesAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Unrealized Gain":
                exit(GetUnrealizedGainsAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Realized Loss":
                exit(GetRealizedLossesAccount());
            DtldCVLedgEntryBuf."Entry Type"::"Realized Gain":
                exit(GetRealizedGainsAccount());
            else
                Error(IncorrectEntryTypeErr, DtldCVLedgEntryBuf."Entry Type");
        end;
    end;

    procedure GetRealizedGainsAccount(): Code[20]
    begin
        TestField("Realized Gains Acc.");
        exit("Realized Gains Acc.");
    end;

    procedure GetRealizedLossesAccount(): Code[20]
    begin
        TestField("Realized Losses Acc.");
        exit("Realized Losses Acc.");
    end;

    procedure GetRealizedGLGainsAccount(): Code[20]
    begin
        TestField("Realized G/L Gains Account");
        exit("Realized G/L Gains Account");
    end;

    procedure GetRealizedGLLossesAccount(): Code[20]
    begin
        TestField("Realized G/L Losses Account");
        exit("Realized G/L Losses Account");
    end;

    procedure GetResidualGainsAccount(): Code[20]
    begin
        TestField("Residual Gains Account");
        exit("Residual Gains Account");
    end;

    procedure GetResidualLossesAccount(): Code[20]
    begin
        TestField("Residual Losses Account");
        exit("Residual Losses Account");
    end;

    procedure GetUnrealizedGainsAccount(): Code[20]
    begin
        TestField("Unrealized Gains Acc.");
        exit("Unrealized Gains Acc.");
    end;

    procedure GetUnrealizedLossesAccount(): Code[20]
    begin
        TestField("Unrealized Losses Acc.");
        exit("Unrealized Losses Acc.");
    end;

    procedure GetConvLCYRoundingDebitAccount(): Code[20]
    begin
        TestField("Conv. LCY Rndg. Debit Acc.");
        exit("Conv. LCY Rndg. Debit Acc.");
    end;

    procedure GetConvLCYRoundingCreditAccount(): Code[20]
    begin
        TestField("Conv. LCY Rndg. Credit Acc.");
        exit("Conv. LCY Rndg. Credit Acc.");
    end;

    procedure GetCurrencySymbol(): Text[10]
    begin
        if Symbol <> '' then
            exit(Symbol);

        exit(Code);
    end;

    procedure ResolveCurrencySymbol(CurrencyCode: Code[10]): Text[10]
    var
        Currency: Record Currency;
        PoundChar: Char;
        EuroChar: Char;
        YenChar: Char;
    begin
        OnBeforeResolveCurrencySymbol(Rec, CurrencyCode);
        if Currency.Get(CurrencyCode) then
            if Currency.Symbol <> '' then
                exit(Currency.Symbol);

        PoundChar := 163;
        YenChar := 165;
        EuroChar := 8364;

        case CurrencyCode of
            'AUD', 'BND', 'CAD', 'FJD', 'HKD', 'MXN', 'NZD', 'SBD', 'SGD', 'USD':
                exit('$');
            'GBP':
                exit(Format(PoundChar));
            'DKK', 'ISK', 'NOK', 'SEK':
                exit('kr');
            'EUR':
                exit(Format(EuroChar));
            'CNY', 'JPY':
                exit(Format(YenChar));
        end;

        exit('');
    end;

    procedure ResolveCurrencyDescription(CurrencyCode: Code[10]): Text
    var
        Currency: Record Currency;
    begin
        if Currency.Get(CurrencyCode) then
            if Currency.Description <> '' then
                exit(Currency.Description);

        case CurrencyCode of
            'CAD':
                exit(CanadiandollarDescriptionTxt);
            'GBP':
                exit(BritishpoundDescriptionTxt);
            'USD':
                exit(USdollarDescriptionTxt);
            'EUR':
                exit(EuroDescriptionTxt);
        end;

        exit('');
    end;

    procedure ResolveGLCurrencySymbol(CurrencyCode: Code[10]): Text[10]
    var
        Currency: Record Currency;
    begin
        if CurrencyCode <> '' then
            exit(Currency.ResolveCurrencySymbol(CurrencyCode));

        GLSetup.Get();
        exit(GLSetup.GetCurrencySymbol());
    end;

    procedure Initialize(CurrencyCode: Code[10])
    begin
        Initialize(CurrencyCode, false);
    end;

    procedure Initialize(CurrencyCode: Code[10]; CheckAmountRoundingPrecision: Boolean)
    begin
        if CurrencyCode <> '' then begin
            Get(CurrencyCode);
            if CheckAmountRoundingPrecision then
                TestField("Amount Rounding Precision");
        end else
            InitRoundingPrecision();
    end;

    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        AccountSuggested := false;
        RecRef.GetTable(Rec);
        SuggestGainLossAccounts(RecRef);
        SuggestOtherAccounts(RecRef);
        if AccountSuggested then
            RecRef.Modify()
        else
            Message(NoAccountSuggestedMsg);
    end;

    local procedure SuggestGainLossAccounts(var RecRef: RecordRef)
    begin
        if "Unrealized Gains Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Unrealized Gains Acc."));
        if "Realized Gains Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Realized Gains Acc."));
        if "Unrealized Losses Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Unrealized Losses Acc."));
        if "Realized Losses Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Realized Losses Acc."));
    end;

    local procedure SuggestOtherAccounts(var RecRef: RecordRef)
    begin
        if "Realized G/L Gains Account" = '' then
            SuggestAccount(RecRef, FieldNo("Realized G/L Gains Account"));
        if "Realized G/L Losses Account" = '' then
            SuggestAccount(RecRef, FieldNo("Realized G/L Losses Account"));
        if "Residual Gains Account" = '' then
            SuggestAccount(RecRef, FieldNo("Residual Gains Account"));
        if "Residual Losses Account" = '' then
            SuggestAccount(RecRef, FieldNo("Residual Losses Account"));
        if "Conv. LCY Rndg. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Conv. LCY Rndg. Debit Acc."));
        if "Conv. LCY Rndg. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Conv. LCY Rndg. Credit Acc."));
    end;

    local procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        CurrencyRecRef: RecordRef;
        CurrencyFieldRef: FieldRef;
    begin
        CurrencyRecRef.Open(DATABASE::Currency);

        CurrencyRecRef.Reset();
        CurrencyFieldRef := CurrencyRecRef.Field(FieldNo(Code));
        CurrencyFieldRef.SetFilter('<>%1', Code);
        TempAccountUseBuffer.UpdateBuffer(CurrencyRecRef, AccountFieldNo);
        CurrencyRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
            AccountSuggested := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRoundingPrecision(var Currency: Record Currency; var xCurrency: Record Currency; var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGainLossAccount(var Currency: Record Currency; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResolveCurrencySymbol(var Currency: Record Currency; var CurrencyCode: Code[10])
    begin
    end;
}

