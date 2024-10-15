namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Service.History;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;
using Microsoft.Finance.VAT.TransactionNature;
using Microsoft.EServices.EDocument;

table 254 "VAT Entry"
{
    Caption = 'VAT Entry';
    DrillDownPageID = "VAT Entries";
    LookupPageID = "VAT Entries";
    Permissions = TableData "Sales Invoice Header" = rm,
                    TableData "Sales Cr.Memo Header" = rm,
                    TableData "Service Invoice Header" = rm,
                    TableData "Service Cr.Memo Header" = rm,
                    TableData "Issued Reminder Header" = rm,
                    TableData "Issued Fin. Charge Memo Header" = rm,
                    TableData "Purch. Inv. Header" = rm,
                    TableData "Purch. Cr. Memo Hdr." = rm,
                    TableData "G/L Entry" = rm,
                    TableData "VAT Entry" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(7; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
            Editable = false;

            trigger OnValidate()
            begin
                if Type = Type::Settlement then
                    Error(Text000, FieldCaption(Type), Type);
            end;
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base';
            Editable = false;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(12; "Bill-to/Pay-to No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to No.';
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale),
                                     "Reverse Sales VAT" = const(false)) Customer
            else
            if (Type = const(Sale),
                                              "Reverse Sales VAT" = const(true)) Vendor;

            trigger OnValidate()
            begin
                Validate(Type);
                if "Bill-to/Pay-to No." = '' then begin
                    "Country/Region Code" := '';
                    "VAT Registration No." := '';
                end else
                    case Type of
                        Type::Purchase:
                            begin
                                Vend.Get("Bill-to/Pay-to No.");
                                "Country/Region Code" := Vend."Country/Region Code";
                                "VAT Registration No." := Vend."VAT Registration No.";
                            end;
                        Type::Sale:
                            begin
                                Cust.Get("Bill-to/Pay-to No.");
                                "Country/Region Code" := Cust."Country/Region Code";
                                "VAT Registration No." := Cust."VAT Registration No.";
                            end;
                    end;
            end;
        }
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';

            trigger OnValidate()
            begin
                Validate(Type);
            end;
        }
        field(14; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            Editable = false;
            TableRelation = "Reason Code";
        }
        field(17; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
        }
        field(18; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Validate(Type);
                Validate("VAT Registration No.");
            end;
        }
        field(20; "Internal Ref. No."; Text[30])
        {
            Caption = 'Internal Ref. No.';
            Editable = false;
        }
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(22; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Amount';
            Editable = false;
        }
        field(23; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unrealized Base';
            Editable = false;
        }
        field(24; "Remaining Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Unrealized Amount';
            Editable = false;
        }
        field(25; "Remaining Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Unrealized Base';
            Editable = false;
        }
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(29; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            Editable = false;
            TableRelation = "Tax Area";
        }
        field(30; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            Editable = false;
        }
        field(31; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        field(32; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            Editable = false;
        }
        field(33; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            Editable = false;
            TableRelation = "Tax Jurisdiction";
        }
        field(34; "Tax Group Used"; Code[20])
        {
            Caption = 'Tax Group Used';
            Editable = false;
            TableRelation = "Tax Group";
        }
        field(35; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            Editable = false;
            OptionCaption = 'Sales Tax,Excise Tax';
            OptionMembers = "Sales Tax","Excise Tax";
        }
        field(36; "Tax on Tax"; Boolean)
        {
            Caption = 'Tax on Tax';
            Editable = false;
        }
        field(37; "Sales Tax Connection No."; Integer)
        {
            Caption = 'Sales Tax Connection No.';
            Editable = false;
        }
        field(38; "Unrealized VAT Entry No."; Integer)
        {
            Caption = 'Unrealized VAT Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
        }
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        field(43; "Additional-Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
        }
        field(44; "Additional-Currency Base"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Base';
            Editable = false;
        }
        field(45; "Add.-Currency Unrealized Amt."; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Unrealized Amt.';
            Editable = false;
        }
        field(46; "Add.-Currency Unrealized Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Unrealized Base';
            Editable = false;
        }
        field(48; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(49; "Add.-Curr. Rem. Unreal. Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Rem. Unreal. Amount';
            Editable = false;
        }
        field(50; "Add.-Curr. Rem. Unreal. Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Rem. Unreal. Base';
            Editable = false;
        }
        field(51; "VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(52; "Add.-Curr. VAT Difference"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Curr. VAT Difference';
            Editable = false;
        }
        field(53; "Ship-to/Order Address Code"; Code[10])
        {
            Caption = 'Ship-to/Order Address Code';
            TableRelation = if (Type = const(Purchase)) "Order Address".Code where("Vendor No." = field("Bill-to/Pay-to No."))
            else
            if (Type = const(Sale)) "Ship-to Address".Code where("Customer No." = field("Bill-to/Pay-to No."));
        }
        field(54; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', 0);
            end;
        }
        field(56; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(57; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            TableRelation = "VAT Entry";
        }
        field(58; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            TableRelation = "VAT Entry";
        }
        field(59; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            Editable = false;
        }
        field(60; "Base Before Pmt. Disc."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Base Before Pmt. Disc.';
            Editable = false;
        }
        field(70; "Source Currency VAT Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Source Currency VAT Amount';
            Editable = false;
        }
        field(71; "Source Currency VAT Base"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Source Currency VAT Base';
            Editable = false;
        }
        field(74; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            TableRelation = Currency;
            DataClassification = SystemMetadata;
        }
        field(75; "Source Currency Factor"; Decimal)
        {
            Caption = 'Source Currency Factor';
            DataClassification = SystemMetadata;
        }
        field(78; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(79; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(81; "Realized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Realized Amount';
            Editable = false;
        }
        field(82; "Realized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Realized Base';
            Editable = false;
        }
        field(83; "Add.-Curr. Realized Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Realized Amount';
            Editable = false;
        }
        field(84; "Add.-Curr. Realized Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Realized Base';
            Editable = false;
        }
        field(85; "G/L Acc. No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        field(86; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';

            trigger OnValidate()
            var
                VATDateReportingMgt: Codeunit "VAT Reporting Date Mgt";
            begin
                if (Rec."VAT Reporting Date" = xRec."VAT Reporting Date") and (CurrFieldNo <> 0) then
                    exit;
                // if type settlement then we error
                Validate(Type);
                if not VATDateReportingMgt.IsVATDateModifiable() then
                    Error(VATDateNotModifiableErr);

                VATDateReportingMgt.CheckDateAllowed("VAT Reporting Date", Rec.FieldNo("VAT Reporting Date"), false);
                VATDateReportingMgt.CheckDateAllowed(xRec."VAT Reporting Date", Rec.FieldNo("VAT Reporting Date"), true, false);
                VATDateReportingMgt.UpdateLinkedEntries(Rec);
            end;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            Caption = 'Non-Deductible VAT %"';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base';
            Editable = false;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6203; "Non-Deductible VAT Base ACY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Base ACY';
            Editable = false;
        }
        field(6204; "Non-Deductible VAT Amount ACY"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Non-Deductible VAT Amount ACY';
            Editable = false;
        }
        field(6205; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
        field(6206; "Non-Deductible VAT Diff. ACY"; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference ACY';
            Editable = false;
        }
        field(12100; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            TableRelation = "VAT Identifier";
        }
        field(12101; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            MaxValue = 100;
            MinValue = 0;
        }
        field(12102; "Nondeductible Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Nondeductible Amount';
        }
        field(12104; "Add. Curr. Nondeductible Amt."; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add. Curr. Nondeductible Amt.';
        }
        field(12106; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            MinValue = 0;
        }
        field(12109; "Nondeductible Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Nondeductible Base';
        }
        field(12110; "Add. Curr. Nondeductible Base"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add. Curr. Nondeductible Base';
        }
        field(12111; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
        }
        field(12112; "VAT Period"; Code[10])
        {
            Caption = 'VAT Period';
        }
        field(12120; "Include in VAT Transac. Rep."; Boolean)
        {
            Caption = 'Include in VAT Transac. Rep.';
        }
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            TableRelation = "Activity Code".Code;
        }
        field(12124; "Reverse Sales VAT"; Boolean)
        {
            Caption = 'Reverse Sales VAT';
            Editable = false;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            TableRelation = "Service Tariff Number";
        }
        field(12126; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(12128; "Plafond Entry"; Boolean)
        {
            Caption = 'Plafond Entry';
        }
        field(12130; Blacklisted; Boolean)
        {
            Caption = 'Blacklisted';
            Editable = false;
            ObsoleteReason = 'Obsolete feature';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(12131; "Blacklist Amount"; Decimal)
        {
            Caption = 'Blacklist Amount';
            Editable = false;
            ObsoleteReason = 'Obsolete feature';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(12132; "Related Entry No."; Integer)
        {
            Caption = 'Related Entry No.';
            Editable = false;
            TableRelation = "Vendor Ledger Entry";
        }
        field(12133; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(12134; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(12135; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
        }
        field(12136; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
        }
        field(12137; Resident; Option)
        {
            Caption = 'Resident';
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";
        }
        field(12140; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
        }
        field(12178; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            TableRelation = "Payment Method";
        }
        field(12179; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
        }
        field(12180; "Refers To Period"; Option)
        {
            Caption = 'Refers To Period';
            OptionCaption = ' ,Current,Current Calendar Year,Previous Calendar Year';
            OptionMembers = " ",Current,"Current Calendar Year","Previous Calendar Year";
        }
        field(12182; "Place of Birth"; Text[30])
        {
            Caption = 'Place of Birth';
        }
        field(12183; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            Editable = false;
            OptionCaption = ' ,Customer,Contact,Vendor';
            OptionMembers = " ",Customer,Contact,Vendor;
        }
        field(12184; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            Editable = false;
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Customer)) Customer
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;
        }
        field(12185; "VAT Transaction Nature"; Code[4])
        {
            Caption = 'VAT Transaction Nature';
            TableRelation = "VAT Transaction Nature";
        }
        field(12186; "Fattura Document Type"; Code[20])
        {
            Caption = 'Fattura Document Type';
            TableRelation = "Fattura Document Type";
        }
        field(12187; "Fattura File Exported"; Boolean)
        {
            Caption = 'Fattura File Exported';
        }
        field(12188; "Fattura Vendor No."; Code[20])
        {
            Caption = 'Fattura Vendor No.';
            TableRelation = Vendor;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date", "VAT Period", "Operation Occurred Date", "Activity Code", Blacklisted, "Document Type", "VAT Registration No.")
        {
            SumIndexFields = Base, Amount, "Additional-Currency Base", "Additional-Currency Amount", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Amount", "Add.-Curr. Rem. Unreal. Base", "Nondeductible Amount", "Nondeductible Base", "Add. Curr. Nondeductible Amt.", "Add. Curr. Nondeductible Base";
        }
        key(Key3; Type, Closed, Blacklisted, "Reverse Sales VAT", "EU Service", "Activity Code", "Document Type", "Bill-to/Pay-to No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Period", "Operation Occurred Date", "Document Date", "Refers To Period")
        {
            SumIndexFields = Base, Amount, "Nondeductible Base", "Nondeductible Amount", "Remaining Unrealized Base", "Remaining Unrealized Amount", "Blacklist Amount";
        }
        key(Key4; Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date", "G/L Acc. No.", "VAT Reporting Date")
        {
            SumIndexFields = Base, Amount, "Additional-Currency Base", "Additional-Currency Amount", "Remaining Unrealized Amount", "Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Amount", "Add.-Curr. Rem. Unreal. Base";
        }
        key(Key5; Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Remaining Unrealized Amount";
        }
        key(Key6; Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
        {
            SumIndexFields = Base, "Additional-Currency Base";
        }
        key(Key7; "Document No.", "Posting Date", "Unrealized VAT Entry No.")
        {
            SumIndexFields = "Remaining Unrealized Base", "Remaining Unrealized Amount", "Unrealized Base", "Unrealized Amount";
        }
        key(Key8; "Transaction No.")
        {
        }
        key(Key9; "Tax Jurisdiction Code", "Tax Group Used", "Tax Type", "Use Tax", "Posting Date")
        {
        }
        key(Key10; Type, "Bill-to/Pay-to No.", "Transaction No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Document No.", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT %", "Deductible %", "VAT Identifier", "Transaction No.", "Unrealized VAT Entry No.")
        {
            SumIndexFields = Base, Amount, "Nondeductible Base", "Nondeductible Amount", "Unrealized Base", "Unrealized Amount", "VAT Difference", "Additional-Currency Amount", "Additional-Currency Base", "Add. Curr. Nondeductible Amt.", "Add. Curr. Nondeductible Base";
        }
        key(Key12; "Related Entry No.")
        {
            SumIndexFields = "Blacklist Amount";
        }
        key(Key13; "Plafond Entry", Type, "Operation Occurred Date")
        {
            SumIndexFields = Base;
        }
        key(Key14; "Fiscal Code", "Operation Occurred Date")
        {
        }
        key(Key15; "VAT Registration No.", "Operation Occurred Date")
        {
        }
        key(Key16; "Operation Occurred Date", Type, "Document Type", "Document No.", "Contract No.")
        {
        }
        key(Key17; "Posting Date", Type, "Document Type", "Document No.")
        {
        }
        key(Key18; Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Jurisdiction Code", "Use Tax", "Posting Date", "G/L Acc. No.")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Additional-Currency Base", "Additional-Currency Amount", "Add.-Currency Unrealized Amt.", "Add.-Currency Unrealized Base", "Remaining Unrealized Amount";
        }
        key(Key19; "Posting Date", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", Reversed, "G/L Acc. No.", "VAT Reporting Date")
        {
            SumIndexFields = Base, Amount, "Unrealized Amount", "Unrealized Base", "Additional-Currency Base", "Additional-Currency Amount", "Add.-Currency Unrealized Amt.", "Add.-Currency Unrealized Base", "Remaining Unrealized Amount";
        }
        key(Key20; "Document Date")
        {
        }
        key(Key21; "G/L Acc. No.")
        {
        }
        key(Key22; Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", Reversed, "Posting Date", "G/L Acc. No.", "VAT Reporting Date")
        {
        }
        key(Key12100; Type, Closed, "Tax Liable", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Operation Occurred Date", "VAT Period")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Posting Date", "Document Type", "Document No.", "Posting Date")
        {
        }
    }

    var
        Cust: Record Customer;
        Vend: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        UseAddCurrAmounts: Boolean;
        CalculateSum: Boolean;

        Text000: Label 'You cannot change the contents of this field when %1 is %2.';
        ConfirmAdjustQst: Label 'Do you want to fill the G/L Account No. field in VAT entries that are linked to G/L Entries?';
        ProgressMsg: Label 'Processed entries: @2@@@@@@@@@@@@@@@@@\';
        AdjustTitleMsg: Label 'Adjust G/L account number in VAT entries.\';
        NoGLAccNoOnVATEntriesErr: Label 'The VAT Entry table with filter <%1> must not contain records.', Comment = '%1 - the filter expression applied to VAT entry record.';
        VATDateNotModifiableErr: Label 'Modification of the VAT Date on the VAT Entry is restricted by the current setting for VAT Reporting Date Usage in the General Ledger Setup.';

    internal procedure SetVATDateFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."VAT Reporting Date" = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate(GenJnlLine."Posting Date", GenJnlLine."Document Date")
        else
            "VAT Reporting Date" := GenJnlLine."VAT Reporting Date";
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure GetCurrencyCode(): Code[10]
    begin
        GLSetup.GetRecordOnce();
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetUnrealizedVATPart(SettledAmount: Decimal; Paid: Decimal; Full: Decimal; TotalUnrealVATAmountFirst: Decimal; TotalUnrealVATAmountLast: Decimal; LedgEntryOpen: Boolean): Decimal
    var
        UnrealizedVATType: Option " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)";
    begin
        if (Type <> Type::" ") and
           (Amount = 0) and
           (Base = 0)
        then begin
            UnrealizedVATType := GetUnrealizedVATType();
            if (UnrealizedVATType = UnrealizedVATType::" ") or
               (("Remaining Unrealized Amount" = 0) and
                ("Remaining Unrealized Base" = 0))
            then
                exit(0);

            if Abs(Paid) = Abs(Full) then
                exit(1);

            case UnrealizedVATType of
                UnrealizedVATType::Percentage:
                    begin
                        if Abs(Full) = Abs(Paid) - Abs(SettledAmount) then
                            exit(1);
                        if Full = 0 then
                            exit(Abs(SettledAmount) / (Abs(Paid) + Abs(SettledAmount)));
                        exit(Abs(SettledAmount) / (Abs(Full) - (Abs(Paid) - Abs(SettledAmount))));
                    end;
                UnrealizedVATType::First:
                    begin
                        if not LedgEntryOpen or ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") then
                            exit(1);
                        if Abs(Paid) < Abs(TotalUnrealVATAmountFirst) then
                            exit(Abs(CalcVATPart(
                                  GetCurrencyCode(), 1.0, Paid - Abs("Unrealized Amount" - "Remaining Unrealized Amount"), "Unrealized Amount")));
                        exit(1);
                    end;
                UnrealizedVATType::"First (Fully Paid)":
                    begin
                        if not LedgEntryOpen or ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") then
                            exit(1);
                        if Abs(Paid) < Abs(TotalUnrealVATAmountFirst) then
                            exit(0);
                        exit(1);
                    end;
                UnrealizedVATType::"Last (Fully Paid)":
                    exit(0);
                UnrealizedVATType::Last:
                    begin
                        if not LedgEntryOpen then
                            exit(1);
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            exit(0);
                        if Abs(Paid) > Abs(Full) - Abs(TotalUnrealVATAmountLast) then
                            exit(Abs(CalcVATPart(GetCurrencyCode(), 1.0,
                                  Paid - Abs("Unrealized Base" + "Unrealized Amount" - "Remaining Unrealized Amount"),
                                  "Unrealized Amount")));
                        exit(0);
                    end;
            end;
        end else
            exit(0);
    end;

    procedure GetUnrealizedVATType() UnrealizedVATType: Integer
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then begin
            TaxJurisdiction.Get("Tax Jurisdiction Code");
            UnrealizedVATType := TaxJurisdiction."Unrealized VAT Type";
        end else begin
            VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            UnrealizedVATType := VATPostingSetup."Unrealized VAT Type";
        end;
    end;

    local procedure CalcVATPart(CurrencyCode: Code[20]; CurrencyFactor: Decimal; SettledAmount: Decimal; TotalAmount: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(SettledAmount / TotalAmount);

        exit((SettledAmount / CurrencyFactor) / TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure SetUseAddCurrAmounts(NewUseAddCurrAmounts: Boolean)
    begin
        UseAddCurrAmounts := NewUseAddCurrAmounts;
    end;

    [Scope('OnPrem')]
    procedure SetCalculateSum(NewCalculateSum: Boolean)
    begin
        CalculateSum := NewCalculateSum;
    end;

    [Scope('OnPrem')]
    procedure GetAmount(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Additional-Currency Amount");
            exit("Additional-Currency Amount");
        end;
        if CalculateSum then
            CalcSums(Amount);
        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure GetBase(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Additional-Currency Base", "Add. Curr. Nondeductible Base");
            exit("Additional-Currency Base" + "Add. Curr. Nondeductible Base");
        end;
        if CalculateSum then
            CalcSums(Base, "Nondeductible Base");
        exit(Base + "Nondeductible Base");
    end;

    [Scope('OnPrem')]
    procedure GetRemUnrealAmount(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Add.-Curr. Rem. Unreal. Amount");
            exit("Add.-Curr. Rem. Unreal. Amount");
        end;
        if CalculateSum then
            CalcSums("Remaining Unrealized Amount");
        exit("Remaining Unrealized Amount");
    end;

    [Scope('OnPrem')]
    procedure GetRemUnrealBase(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Add.-Curr. Rem. Unreal. Base");
            exit("Add.-Curr. Rem. Unreal. Base");
        end;
        if CalculateSum then
            CalcSums("Remaining Unrealized Base");
        exit("Remaining Unrealized Base");
    end;

    [Scope('OnPrem')]
    procedure GetNonDeductAmount(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Add. Curr. Nondeductible Amt.");
            exit("Add. Curr. Nondeductible Amt.");
        end;
        if CalculateSum then
            CalcSums("Nondeductible Amount");
        exit("Nondeductible Amount");
    end;

    [Scope('OnPrem')]
    procedure GetNonDeductBase(): Decimal
    begin
        if UseAddCurrAmounts then begin
            if CalculateSum then
                CalcSums("Add. Curr. Nondeductible Base");
            exit("Add. Curr. Nondeductible Base");
        end;
        if CalculateSum then
            CalcSums("Nondeductible Base");
        exit("Nondeductible Base");
    end;

    [Scope('OnPrem')]
    procedure GetVATEntryFromVendLedgEntryNo(var VATEntry: Record "VAT Entry"; EntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(EntryNo);
        VATEntry.SetCurrentKey("Document No.", Type);
        VATEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
    end;

    procedure CopyFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        SetVATDateFromGenJnlLine(GenJnlLine);
        CopyPostingGroupsFromGenJnlLine(GenJnlLine);
        CopyPostingDataFromGenJnlLine(GenJnlLine);
        Type := GenJnlLine."Gen. Posting Type";
        "VAT Calculation Type" := GenJnlLine."VAT Calculation Type";
        "Ship-to/Order Address Code" := GenJnlLine."Ship-to/Order Address Code";
        "EU 3-Party Trade" := GenJnlLine."EU 3-Party Trade";
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "No. Series" := GenJnlLine."Posting No. Series";
        "VAT Base Discount %" := GenJnlLine."VAT Base Discount %";
        "Bill-to/Pay-to No." := GenJnlLine."Bill-to/Pay-to No.";
        "Country/Region Code" := GenJnlLine."Country/Region Code";
        "VAT Registration No." := GenJnlLine."VAT Registration No.";
        NonDeductibleVAT.Copy(Rec, GenJnlLine);

        OnAfterCopyFromGenJnlLine(Rec, GenJnlLine);
    end;

    procedure CopyPostingDataFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Posting Date" := GenJnlLine."Posting Date";
        if GenJnlLine."VAT Reporting Date" = 0D then
            "VAT Reporting Date" := GLSetup.GetVATDate(GenJnlLine."Posting Date", GenJnlLine."Document Date")
        else
            "VAT Reporting Date" := GenJnlLine."VAT Reporting Date";
        "Document Type" := GenJnlLine."Document Type";
        "Document Date" := GenJnlLine."Document Date";
        "Document No." := GenJnlLine."Document No.";
        "External Document No." := GenJnlLine."External Document No.";
        "Source Code" := GenJnlLine."Source Code";
        "Reason Code" := GenJnlLine."Reason Code";
        "Journal Templ. Name" := GenJnlLine."Journal Template Name";
        "Journal Batch Name" := GenJnlLine."Journal Batch Name";
    end;

    local procedure CopyPostingGroupsFromGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        "Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
        "Tax Area Code" := GenJnlLine."Tax Area Code";
        "Tax Liable" := GenJnlLine."Tax Liable";
        "Tax Group Code" := GenJnlLine."Tax Group Code";
        "Use Tax" := GenJnlLine."Use Tax";
    end;

    procedure SetGLAccountNo(WithUI: Boolean)
    var
        Response: Boolean;
    begin
        Response := false;
        SetGLAccountNoWithResponse(WithUI, WithUI, Response);
    end;

    procedure SetGLAccountNoWithResponse(WithUI: Boolean; ShowConfirm: Boolean; var Response: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        NoOfRecords: Integer;
        Index: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetGLAccountNo(Rec, IsHandled, Response, WithUI, ShowConfirm);
        if IsHandled then
            exit;

        SetRange("G/L Acc. No.", '');
        if WithUI then begin
            if ShowConfirm then
                Response := ConfirmManagement.GetResponseOrDefault(ConfirmAdjustQst, false);
            if not Response then
                exit;

            if GuiAllowed() then begin
                NoOfRecords := count();
                Window.Open(AdjustTitleMsg + ProgressMsg);
            end;
        end;
        SetLoadFields("G/L Acc. No.");
        if FindSet(true) then
            repeat
                AdjustGLAccountNoOnRec(Rec);
                if WithUI and GuiAllowed() then
                    Window.Update(2, Round(Index / NoOfRecords * 10000, 1));
            until Next() = 0;
        SetLoadFields();
        if WithUI and GuiAllowed() then
            Window.Close();

        IsHandled := false;
        OnAfterSetGLAccountNo(Rec, IsHandled, WithUI);
        if IsHandled then
            exit;

        CheckGLAccountNoFilled();
    end;

    procedure CheckGLAccountNoFilled()
    var
        VATEntryLocal: Record "VAT Entry";
    begin
        VATEntryLocal.Copy(Rec);
        VATEntryLocal.SetRange("G/L Acc. No.", '');
        if not VATEntryLocal.IsEmpty() then
            Error(NoGLAccNoOnVATEntriesErr, VATEntryLocal.GetFilters());
    end;

    local procedure AdjustGLAccountNoOnRec(var VATEntry: Record "VAT Entry")
    var
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATEntryEdit: Codeunit "VAT Entry - Edit";
    begin
        GLEntryVATEntryLink.SetRange("VAT Entry No.", "Entry No.");
        if not GLEntryVATEntryLink.FindFirst() then begin
            if not AddMissingGLEntryVATEntryLink(VATEntry, GLEntry, GLEntryVATEntryLink) then
                exit;
        end else begin
            GLEntry.SetLoadFields("G/L Account No.");
            if not GLEntry.Get(GLEntryVATEntryLink."G/L Entry No.") then
                exit;
        end;

        VATEntryEdit.SetGLAccountNo(Rec, GLEntry."G/L Account No.");
    end;

    local procedure AddMissingGLEntryVATEntryLink(var VATEntry: Record "VAT Entry"; var GLEntry: Record "G/L Entry"; var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link"): Boolean
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLEntry.SetRange("Gen. Bus. Posting Group", VATEntry."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
        GLEntry.SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
        GLEntry.SetRange("Tax Area Code", VATEntry."Tax Area Code");
        GLEntry.SetRange("Tax Liable", VATEntry."Tax Liable");
        GLEntry.SetRange("Tax Group Code", VATEntry."Tax Group Code");
        GLEntry.SetRange("Use Tax", VATEntry."Use Tax");
        if not GLEntry.FindFirst() then
            exit(false);

        GLEntryVATEntryLink.InsertLinkSelf(GLEntry."Entry No.", VATEntry."Entry No.");
        exit(true);
    end;

    procedure CopyAmountsFromVATEntry(VATEntry: Record "VAT Entry"; WithOppositeSign: Boolean)
    var
        Sign: Decimal;
    begin
        if WithOppositeSign then
            Sign := -1
        else
            Sign := 1;
        Base := Sign * VATEntry.Base;
        Amount := Sign * VATEntry.Amount;
        "Unrealized Amount" := Sign * VATEntry."Unrealized Amount";
        "Unrealized Base" := Sign * VATEntry."Unrealized Base";
        "Remaining Unrealized Amount" := Sign * VATEntry."Remaining Unrealized Amount";
        "Remaining Unrealized Base" := Sign * VATEntry."Remaining Unrealized Base";
        "Additional-Currency Amount" := Sign * VATEntry."Additional-Currency Amount";
        "Additional-Currency Base" := Sign * VATEntry."Additional-Currency Base";
        "Add.-Currency Unrealized Amt." := Sign * VATEntry."Add.-Currency Unrealized Amt.";
        "Add.-Currency Unrealized Base" := Sign * VATEntry."Add.-Currency Unrealized Base";
        "Add.-Curr. Rem. Unreal. Amount" := Sign * VATEntry."Add.-Curr. Rem. Unreal. Amount";
        "Add.-Curr. Rem. Unreal. Base" := Sign * VATEntry."Add.-Curr. Rem. Unreal. Base";
        "VAT Difference" := Sign * VATEntry."VAT Difference";
        "Add.-Curr. VAT Difference" := Sign * VATEntry."Add.-Curr. VAT Difference";
        "Realized Amount" := Sign * "Realized Amount";
        "Realized Base" := Sign * "Realized Base";
        "Add.-Curr. Realized Amount" := Sign * "Add.-Curr. Realized Amount";
        "Add.-Curr. Realized Base" := Sign * "Add.-Curr. Realized Base";

#if not CLEAN24
        OnAfterCopyAmountsFromVATEntry(VATEntry, WithOppositeSign);
#endif
        OnAfterOnCopyAmountsFromVATEntry(VATEntry, WithOppositeSign, Rec);
    end;

    procedure SetUnrealAmountsToZero()
    begin
        "Unrealized Amount" := 0;
        "Unrealized Base" := 0;
        "Remaining Unrealized Amount" := 0;
        "Remaining Unrealized Base" := 0;
        "Add.-Currency Unrealized Amt." := 0;
        "Add.-Currency Unrealized Base" := 0;
        "Add.-Curr. Rem. Unreal. Amount" := 0;
        "Add.-Curr. Rem. Unreal. Base" := 0;
        "Realized Amount" := 0;
        "Realized Base" := 0;
        "Add.-Curr. Realized Amount" := 0;
        "Add.-Curr. Realized Base" := 0;
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromGenJnlLine(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

#if not CLEAN24
    [Obsolete('Use the OnAfterOnCopyAmountsFromVATEntry method instead', '24.0')]
    [IntegrationEvent(false, false)]
    procedure OnAfterCopyAmountsFromVATEntry(var VATEntry: Record "VAT Entry"; WithOppositeSign: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnCopyAmountsFromVATEntry(var VATEntry: Record "VAT Entry"; WithOppositeSign: Boolean; var RecVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGLAccountNo(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean; var Response: Boolean; WithUI: Boolean; ShowConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLAccountNo(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean; WithUI: Boolean)
    begin
    end;
}

