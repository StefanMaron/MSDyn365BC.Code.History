namespace Microsoft.Sales.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

table 5107 "Sales Header Archive"
{
    Caption = 'Sales Header Archive';
    DataCaptionFields = "No.", "Sell-to Customer Name", "Version No.";
    DrillDownPageID = "Sales List Archive";
    LookupPageID = "Sales List Archive";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(34; "Price Group Code"; Code[10])
        {
            Caption = 'Price Group Code';
            TableRelation = "Customer Price Group";
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        field(40; "Cust./Item Disc. Gr."; Code[20])
        {
            Caption = 'Cust./Item Disc. Gr.';
            TableRelation = "Customer Discount Group";
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line Archive" where("Document Type" = field("Document Type"),
                                                                    "No." = field("No."),
                                                                    "Document Line No." = const(0),
                                                                    "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                    "Version No." = field("Version No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(57; Ship; Boolean)
        {
            Caption = 'Ship';
        }
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line Archive".Amount where("Document Type" = field("Document Type"),
                                                                 "Document No." = field("No."),
                                                                 "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                 "Version No." = field("Version No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line Archive"."Amount Including VAT" where("Document Type" = field("Document Type"),
                                                                                 "Document No." = field("No."),
                                                                                 "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                 "Version No." = field("Version No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            TableRelation = "Sales Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            TableRelation = "Sales Invoice Header";
        }
        field(66; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(67; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(68; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(69; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Invoice Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
#if not CLEAN24
        field(106; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
            ObsoleteReason = 'Field length will be increased to 50.';
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
        }
#else
#pragma warning disable AS0086
        field(106; "Package Tracking No."; Text[50])
        {
            Caption = 'Package Tracking No.';
        }
#pragma warning restore AS0086
#endif
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(120; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
        }
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
        }
        field(124; "IC Status"; Enum "Sales Document IC Status")
        {
            Caption = 'IC Status';
        }
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            Editable = false;
        }
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
        field(130; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        field(132; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(133; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        field(135; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(138; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(139; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(140; "Prepmt. Payment Discount %"; Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(145; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Sales Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                          "No." = field("No."),
                                                                          "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(151; "Sales Quote No."; Code[20])
        {
            Caption = 'Sales Quote No.';
            Editable = false;
            TableRelation = "Sales Header"."No." where("Document Type" = const(Quote),
                                                        "No." = field("Sales Quote No."));
            ValidateTableRelation = false;
        }
        field(152; "Quote Valid Until Date"; Date)
        {
            Caption = 'Quote Valid To Date';
        }
        field(153; "Quote Sent to Customer"; DateTime)
        {
            Caption = 'Quote Sent to Customer';
        }
        field(154; "Quote Accepted"; Boolean)
        {
            Caption = 'Quote Accepted';
        }
        field(155; "Quote Accepted Date"; Date)
        {
            Caption = 'Quote Accepted Date';
            Editable = false;
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Sell-to E-Mail';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(180; "Rcvd-from Country/Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
            ObsoleteReason = 'Use new field on range 181';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(181; "Rcvd.-from Count./Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
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
        }
        field(827; "Credit Card No."; Code[20])
        {
            Caption = 'Credit Card No.';
            ObsoleteReason = 'This field is not needed and it is not used anymore.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        field(3998; "Source Doc. Exists"; Boolean)
        {
            FieldClass = Flowfield;
            CalcFormula = exist("Sales Header" where("Document Type" = field("Document Type"),
                                                            "No." = field("No.")));
            Caption = 'Source Doc. Exists';
            Editable = false;
        }
        field(3999; "Last Archived Date"; DateTime)
        {
            Caption = 'Last Archived Date';
            FieldClass = FlowField;
            CalcFormula = max("Sales Header Archive".SystemCreatedAt where("Document Type" = field("Document Type"),
                                                            "No." = field("No."),
                                                            "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Editable = false;
        }
        field(5043; "Interaction Exist"; Boolean)
        {
            Caption = 'Interaction Exist';
        }
        field(5044; "Time Archived"; Time)
        {
            Caption = 'Time Archived';
        }
        field(5045; "Date Archived"; Date)
        {
            Caption = 'Date Archived';
        }
        field(5046; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5051; "Sell-to Customer Template Code"; Code[10])
        {
            Caption = 'Sell-to Customer Template Code';
            ObsoleteReason = 'Will be removed with other functionality related to "old" templates. Replaced by "Sell-to Customer Templ. Code".';
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
        }
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code (obsoleted)';
            ObsoleteReason = 'Will be removed with other functionality related to "old" templates. Replaced by "Bill-to Customer Templ. Code".';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity."No." where("Contact No." = field("Sell-to Contact No."),
                                                     Closed = const(false));
        }
        field(5056; "Sell-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Templ.";
        }
        field(5057; "Bill-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Templ.";
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("Sales Line Archive"."Completely Shipped" where("Document Type" = field("Document Type"),
                                                                               "Document No." = field("No."),
                                                                               "Version No." = field("Version No."),
                                                                               "Shipment Date" = field("Date Filter"),
                                                                               "Location Code" = field("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(5795; "Late Order Shipping"; Boolean)
        {
            CalcFormula = exist("Sales Line Archive" where("Document Type" = field("Document Type"),
                                                            "Sell-to Customer No." = field("Sell-to Customer No."),
                                                            "Document No." = field("No."),
                                                            "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                            "Version No." = field("Version No."),
                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; Receive; Boolean)
        {
            Caption = 'Receive';
        }
        field(5801; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        field(5802; "Return Receipt No. Series"; Code[20])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";
        }
        field(5803; "Last Return Receipt No."; Code[20])
        {
            Caption = 'Last Return Receipt No.';
            TableRelation = "Return Receipt Header";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Sell-to Customer No.")
        {
        }
        key(Key3; "Document Type", "Bill-to Customer No.")
        {
        }
        key(Key4; "Incoming Document Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Version No.", "Sell-to Customer Name")
        {
        }
    }

    trigger OnDelete()
    var
        SalesLineArchive: Record "Sales Line Archive";
        DeferralHeaderArchive: Record "Deferral Header Archive";
        CatalogItemMgt: Codeunit "Catalog Item Management";
    begin
        SalesLineArchive.SetRange("Document Type", "Document Type");
        SalesLineArchive.SetRange("Document No.", "No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesLineArchive.SetRange("Version No.", "Version No.");
        SalesLineArchive.SetRange(Nonstock, true);
        if SalesLineArchive.FindSet(true) then
            repeat
                CatalogItemMgt.DelNonStockSalesArch(SalesLineArchive);
            until SalesLineArchive.Next() = 0;
        SalesLineArchive.SetRange(Nonstock);
        SalesLineArchive.DeleteAll();

        SalesCommentLineArch.SetRange("Document Type", "Document Type");
        SalesCommentLineArch.SetRange("No.", "No.");
        SalesCommentLineArch.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesCommentLineArch.SetRange("Version No.", "Version No.");
        SalesCommentLineArch.DeleteAll();

        DeferralHeaderArchive.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralHeaderArchive.SetRange("Document Type", "Document Type");
        DeferralHeaderArchive.SetRange("Document No.", "No.");
        DeferralHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        DeferralHeaderArchive.SetRange("Version No.", "Version No.");
        DeferralHeaderArchive.DeleteAll(true);
    end;

    var
        SalesCommentLineArch: Record "Sales Comment Line Archive";
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."));
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesHeaderArchive: Record "Sales Header Archive"; var IsHandled: Boolean)
    begin
    end;
}

