﻿namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Graph;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Service.Item;
using Microsoft.Utilities;
using System;
using System.Automation;
using System.Email;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Utilities;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Bank.Payment;

table 23 Vendor
{
    Caption = 'Vendor';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Vendor List";
    LookupPageID = "Vendor Lookup";
    Permissions = TableData "Vendor Ledger Entry" = r,
                  TableData "Service Item" = rm,
                  TableData "Price List Header" = rd,
                  TableData "Price List Line" = rd,
#if not CLEAN21
                  TableData "Purchase Price" = rd,
                  TableData "Purchase Line Discount" = rd,
#endif
                  TableData "Purchase Price Access" = rd,
                  TableData "Purchase Discount Access" = rd,
                  tabledata Language = r,
                  tabledata "Language Selection" = r;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    PurchSetup.Get();
                    NoSeriesMgt.TestManual(PurchSetup."Vendor Nos.");
                    "No. Series" := '';
                end;
                if "Invoice Disc. Code" = '' then
                    "Invoice Disc. Code" := "No.";
                OnAfterValidateNo(Rec, xRec);
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
                OnBeforeLookupCity(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupCity(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidateCity(Rec, xRec);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';

            trigger OnLookup()
            var
                ContactBusinessRelation: Record "Contact Business Relation";
                Cont: Record Contact;
                TempVend: Record Vendor temporary;
            begin
                if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, "No.") then
                    Cont.SetRange("Company No.", ContactBusinessRelation."Contact No.")
                else
                    Cont.SetRange("Company No.", '');

                if "Primary Contact No." <> '' then
                    if Cont.Get("Primary Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    TempVend.Copy(Rec);
                    Find();
                    TransferFields(TempVend, false);
                    Validate("Primary Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            begin
                if MarketingSetup.Get() then
                    if MarketingSetup."Bus. Rel. Code for Vendors" <> '' then begin
                        if (xRec.Contact = '') and (xRec."Primary Contact No." = '') and (Contact <> '') then begin
                            Modify();
                            UpdateContFromVend.OnModify(Rec);
                            UpdateContFromVend.InsertNewContactPerson(Rec, false);
                            Modify(true);
                        end;
                        exit;
                    end;
            end;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Phone No.") do
                    if Char.IsLetter("Phone No."[i]) then
                        FieldError("Phone No.", PhoneNoCannotContainLettersErr);
            end;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(14; "Our Account No."; Text[20])
        {
            Caption = 'Our Account No.';
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
        field(19; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';
        }
        field(21; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyId();
            end;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                UpdateFormatRegion();
            end;
        }
        field(25; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateRegistrationNumber(Rec, IsHandled);
                if IsHandled then
                    exit;
                if StrLen("Registration Number") > 20 then
                    FieldError("Registration Number", FieldLengthErr);
            end;
        }
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                UpdatePaymentTermsId();
            end;
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(29; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidatePurchaserCode();
            end;
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(31; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Vendor;
            ValidateTableRelation = false;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");

                if "Country/Region Code" <> xRec."Country/Region Code" then
                    VATRegistrationValidation();
            end;
        }
        field(38; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const(Vendor),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; Blocked; Enum "Vendor Blocked")
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if (Blocked <> Blocked::All) and "Privacy Blocked" then
                    if GuiAllowed then
                        if Confirm(ConfirmBlockedPrivacyBlockedQst) then
                            "Privacy Blocked" := false
                        else
                            Error('')
                    else
                        Error(CanNotChangeBlockedDueToPrivacyBlockedErr);
            end;
        }
        field(45; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(46; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                UpdatePaymentMethodId();
            end;
        }
        field(48; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(53; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
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
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Purchases (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Vendor Ledger Entry"."Purchase (LCY)" where("Vendor No." = field("No."),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Currency Code" = field("Currency Filter")));
            Caption = 'Purchases (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(64; "Inv. Discounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Vendor Ledger Entry"."Inv. Discount (LCY)" where("Vendor No." = field("No."),
                                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Inv. Discounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Pmt. Discounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                  "Entry Type" = filter("Payment Discount" .. "Payment Discount (VAT Adjustment)"),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Pmt. Discounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Balance Due"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor No." = field("No."),
                                                                           "Initial Entry Due Date" = field(UPPERLIMIT("Date Filter")),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Balance Due';
            Editable = false;
            FieldClass = FlowField;
        }
        field(67; "Balance Due (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                   "Initial Entry Due Date" = field(UPPERLIMIT("Date Filter")),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Balance Due (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; Payments; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const(Payment),
                                                                          "Entry Type" = const("Initial Entry"),
                                                                          "Vendor No." = field("No."),
                                                                          "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                          "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                          "Currency Code" = field("Currency Filter")));
            Caption = 'Payments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Invoice Amounts"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const(Invoice),
                                                                           "Entry Type" = const("Initial Entry"),
                                                                           "Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Invoice Amounts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Cr. Memo Amounts"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const("Credit Memo"),
                                                                          "Entry Type" = const("Initial Entry"),
                                                                          "Vendor No." = field("No."),
                                                                          "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                          "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                          "Currency Code" = field("Currency Filter")));
            Caption = 'Cr. Memo Amounts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Finance Charge Memo Amounts"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const("Finance Charge Memo"),
                                                                           "Entry Type" = const("Initial Entry"),
                                                                           "Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Finance Charge Memo Amounts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(74; "Payments (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const(Payment),
                                                                                  "Entry Type" = const("Initial Entry"),
                                                                                  "Vendor No." = field("No."),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Payments (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(75; "Inv. Amounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const(Invoice),
                                                                                   "Entry Type" = const("Initial Entry"),
                                                                                   "Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Inv. Amounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Cr. Memo Amounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const("Credit Memo"),
                                                                                  "Entry Type" = const("Initial Entry"),
                                                                                  "Vendor No." = field("No."),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Cr. Memo Amounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Fin. Charge Memo Amounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const("Finance Charge Memo"),
                                                                                   "Entry Type" = const("Initial Entry"),
                                                                                   "Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Fin. Charge Memo Amounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; "Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount" where("Document Type" = const(Order),
                                                                          "Pay-to Vendor No." = field("No."),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Currency Code" = field("Currency Filter")));
            Caption = 'Outstanding Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Amt. Rcd. Not Invoiced" where("Document Type" = const(Order),
                                                                              "Pay-to Vendor No." = field("No."),
                                                                              "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Currency Code" = field("Currency Filter")));
            Caption = 'Amt. Rcd. Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                GLSetup: Record "General Ledger Setup";
                LocalAppMgt: Codeunit LocalApplicationManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATRegistrationNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;
                GLSetup.Get();
                CompanyInfo.Get();
                if (("Country/Region Code" = CompanyInfo."Country/Region Code") or
                    ("Country/Region Code" = '')) and
                   GLSetup."Validate loc.VAT Reg. No."
                then
                    LocalAppMgt.CheckDigitVAT("VAT Registration No.");
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." <> xRec."VAT Registration No." then
                    VATRegistrationValidation();
            end;
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(89; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Removed;
            SubType = Bitmap;
            ObsoleteTag = '18.0';
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            Numeric = true;

            trigger OnValidate()
            var
                GLNCalculator: Codeunit "GLN Calculator";
            begin
                if GLN <> '' then
                    GLNCalculator.AssertValidCheckDigit13(GLN);
            end;
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
                OnBeforeLookupPostCode(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupPostCode(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidatePostCode(Rec, xRec);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(93; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
        }
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Debit Amount" where("Vendor No." = field("No."),
                                                                                  "Entry Type" = filter(<> Application),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Credit Amount" where("Vendor No." = field("No."),
                                                                                   "Entry Type" = filter(<> Application),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Debit Amount (LCY)" where("Vendor No." = field("No."),
                                                                                        "Entry Type" = filter(<> Application),
                                                                                        "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                        "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                        "Posting Date" = field("Date Filter"),
                                                                                        "Currency Code" = field("Currency Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Credit Amount (LCY)" where("Vendor No." = field("No."),
                                                                                         "Entry Type" = filter(<> Application),
                                                                                         "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                         "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                         "Posting Date" = field("Date Filter"),
                                                                                         "Currency Code" = field("Currency Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "E-Mail" = '' then
                    exit;
                MailManagement.CheckValidEmailAddresses("E-Mail");
            end;
        }
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(104; "Reminder Amounts"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const(Reminder),
                                                                           "Entry Type" = const("Initial Entry"),
                                                                           "Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Reminder Amounts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(105; "Reminder Amounts (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const(Reminder),
                                                                                   "Entry Type" = const("Initial Entry"),
                                                                                   "Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Reminder Amounts (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(111; "Currency Filter"; Code[10])
        {
            Caption = 'Currency Filter';
            FieldClass = FlowFilter;
            TableRelation = Currency;
        }
        field(113; "Outstanding Orders (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount (LCY)" where("Document Type" = const(Order),
                                                                                "Pay-to Vendor No." = field("No."),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Currency Code" = field("Currency Filter")));
            Caption = 'Outstanding Orders (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(114; "Amt. Rcd. Not Invoiced (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Amt. Rcd. Not Invoiced (LCY)" where("Document Type" = const(Order),
                                                                                    "Pay-to Vendor No." = field("No."),
                                                                                    "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                    "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                    "Currency Code" = field("Currency Filter")));
            Caption = 'Amt. Rcd. Not Invoiced (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
        }
        field(117; "Pmt. Disc. Tolerance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                  "Entry Type" = filter("Payment Discount Tolerance" | "Payment Discount Tolerance (VAT Adjustment)" | "Payment Discount Tolerance (VAT Excl.)"),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Pmt. Disc. Tolerance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(118; "Pmt. Tolerance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Vendor No." = field("No."),
                                                                                  "Entry Type" = filter("Payment Tolerance" | "Payment Tolerance (VAT Adjustment)" | "Payment Tolerance (VAT Excl.)"),
                                                                                  "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                  "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                  "Posting Date" = field("Date Filter"),
                                                                                  "Currency Code" = field("Currency Filter")));
            Caption = 'Pmt. Tolerance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(119; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";

            trigger OnValidate()
            var
                VendLedgEntry: Record "Vendor Ledger Entry";
                AccountingPeriod: Record "Accounting Period";
                ICPartner: Record "IC Partner";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if xRec."IC Partner Code" <> "IC Partner Code" then begin
                    if not VendLedgEntry.SetCurrentKey("Vendor No.", Open) then
                        VendLedgEntry.SetCurrentKey("Vendor No.");
                    VendLedgEntry.SetRange("Vendor No.", "No.");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindLast() then
                        Error(Text010, FieldCaption("IC Partner Code"), TableCaption);

                    VendLedgEntry.Reset();
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "No.");
                    AccountingPeriod.SetRange(Closed, false);
                    if AccountingPeriod.FindFirst() then begin
                        VendLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
                        if VendLedgEntry.FindFirst() then
                            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text009, TableCaption), true) then
                                "IC Partner Code" := xRec."IC Partner Code";
                    end;
                end;

                if "IC Partner Code" <> '' then begin
                    ICPartner.Get("IC Partner Code");
                    if (ICPartner."Vendor No." <> '') and (ICPartner."Vendor No." <> "No.") then
                        Error(Text008, FieldCaption("IC Partner Code"), "IC Partner Code", TableCaption(), ICPartner."Vendor No.");
                    ICPartner."Vendor No." := "No.";
                    ICPartner.Modify();
                end;

                if (xRec."IC Partner Code" <> "IC Partner Code") and ICPartner.Get(xRec."IC Partner Code") then begin
                    ICPartner."Vendor No." := '';
                    ICPartner.Modify();
                end;
            end;
        }
        field(120; Refunds; Decimal)
        {
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const(Refund),
                                                                           "Entry Type" = const("Initial Entry"),
                                                                           "Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Refunds';
            FieldClass = FlowField;
        }
        field(121; "Refunds (LCY)"; Decimal)
        {
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const(Refund),
                                                                                   "Entry Type" = const("Initial Entry"),
                                                                                   "Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Refunds (LCY)';
            FieldClass = FlowField;
        }
        field(122; "Other Amounts"; Decimal)
        {
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Initial Document Type" = const(" "),
                                                                           "Entry Type" = const("Initial Entry"),
                                                                           "Vendor No." = field("No."),
                                                                           "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                           "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Currency Code" = field("Currency Filter")));
            Caption = 'Other Amounts';
            FieldClass = FlowField;
        }
        field(123; "Other Amounts (LCY)"; Decimal)
        {
            CalcFormula = - sum("Detailed Vendor Ledg. Entry"."Amount (LCY)" where("Initial Document Type" = const(" "),
                                                                                   "Entry Type" = const("Initial Entry"),
                                                                                   "Vendor No." = field("No."),
                                                                                   "Initial Entry Global Dim. 1" = field("Global Dimension 1 Filter"),
                                                                                   "Initial Entry Global Dim. 2" = field("Global Dimension 2 Filter"),
                                                                                   "Posting Date" = field("Date Filter"),
                                                                                   "Currency Code" = field("Currency Filter")));
            Caption = 'Other Amounts (LCY)';
            FieldClass = FlowField;
        }
        field(124; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(125; "Outstanding Invoices"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount" where("Document Type" = const(Invoice),
                                                                          "Pay-to Vendor No." = field("No."),
                                                                          "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Currency Code" = field("Currency Filter")));
            Caption = 'Outstanding Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(126; "Outstanding Invoices (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line"."Outstanding Amount (LCY)" where("Document Type" = const(Invoice),
                                                                                "Pay-to Vendor No." = field("No."),
                                                                                "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                "Currency Code" = field("Currency Filter")));
            Caption = 'Outstanding Invoices (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(130; "Pay-to No. Of Archived Doc."; Integer)
        {
            CalcFormula = count("Purchase Header Archive" where("Document Type" = const(Order),
                                                                 "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. Of Archived Doc.';
            FieldClass = FlowField;
        }
        field(131; "Buy-from No. Of Archived Doc."; Integer)
        {
            CalcFormula = count("Purchase Header Archive" where("Document Type" = const(Order),
                                                                 "Buy-from Vendor No." = field("No.")));
            Caption = 'Buy-from No. Of Archived Doc.';
            FieldClass = FlowField;
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
        }
        field(133; "Intrastat Partner Type"; Enum "Partner Type")
        {
            Caption = 'Intrastat Partner Type';
        }
        field(134; "Exclude from Pmt. Practices"; Boolean)
        {
            Caption = 'Exclude from Payment Practices';
        }
        field(135; "Company Size Code"; Code[20])
        {
            Caption = 'Company Size Code';
            TableRelation = "Company Size";
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if "Privacy Blocked" then
                    Blocked := Blocked::All
                else
                    Blocked := Blocked::" ";
            end;
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;
        }
        field(288; "Preferred Bank Account Code"; Code[20])
        {
            Caption = 'Preferred Bank Account Code';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("No."));
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
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Vendor)));
        }
        field(840; "Cash Flow Payment Terms Code"; Code[10])
        {
            Caption = 'Cash Flow Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(5049; "Primary Contact No."; Code[20])
        {
            Caption = 'Primary Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusRel: Record "Contact Business Relation";
                TempVend: Record Vendor temporary;
            begin
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
                ContBusRel.SetRange("No.", "No.");
                if ContBusRel.FindFirst() then
                    Cont.SetRange("Company No.", ContBusRel."Contact No.")
                else
                    Cont.SetRange("No.", '');

                if "Primary Contact No." <> '' then
                    if Cont.Get("Primary Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    TempVend.Copy(Rec);
                    Find();
                    TransferFields(TempVend, false);
                    Validate("Primary Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusRel: Record "Contact Business Relation";
            begin
                Contact := '';
                if "Primary Contact No." <> '' then begin
                    Cont.Get("Primary Contact No.");

                    ContBusRel.FindOrRestoreContactBusinessRelation(Cont, Rec, ContBusRel."Link to Table"::Vendor);

                    if Cont."Company No." <> ContBusRel."Contact No." then
                        Error(Text004, Cont."No.", Cont.Name, "No.", Name);

                    if Cont.Type = Cont.Type::Person then begin
                        Contact := Cont.Name;
                        exit;
                    end;

                    if Cont."Phone No." <> '' then
                        "Phone No." := Cont."Phone No.";
                    if Cont."E-Mail" <> '' then
                        "E-Mail" := Cont."E-Mail";
                end;
            end;
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

        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5701; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(5790; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");
            end;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Purchase);
            end;
        }
        field(7177; "No. of Pstd. Receipts"; Integer)
        {
            CalcFormula = count("Purch. Rcpt. Header" where("Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Pstd. Receipts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7178; "No. of Pstd. Invoices"; Integer)
        {
            CalcFormula = count("Purch. Inv. Header" where("Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Pstd. Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7179; "No. of Pstd. Return Shipments"; Integer)
        {
            CalcFormula = count("Return Shipment Header" where("Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Pstd. Return Shipments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7180; "No. of Pstd. Credit Memos"; Integer)
        {
            CalcFormula = count("Purch. Cr. Memo Hdr." where("Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Pstd. Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7181; "Pay-to No. of Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7182; "Pay-to No. of Invoices"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Invoice),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7183; "Pay-to No. of Return Orders"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Return Order"),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Return Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7184; "Pay-to No. of Credit Memos"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const("Credit Memo"),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7185; "Pay-to No. of Pstd. Receipts"; Integer)
        {
            CalcFormula = count("Purch. Rcpt. Header" where("Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Pstd. Receipts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7186; "Pay-to No. of Pstd. Invoices"; Integer)
        {
            CalcFormula = count("Purch. Inv. Header" where("Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Pstd. Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7187; "Pay-to No. of Pstd. Return S."; Integer)
        {
            CalcFormula = count("Return Shipment Header" where("Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Pstd. Return S.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7188; "Pay-to No. of Pstd. Cr. Memos"; Integer)
        {
            CalcFormula = count("Purch. Cr. Memo Hdr." where("Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Pstd. Cr. Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7189; "No. of Quotes"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Quote),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Quotes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7190; "No. of Blanket Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Blanket Order"),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Blanket Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7191; "No. of Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Orders';
            FieldClass = FlowField;
        }
        field(7192; "No. of Invoices"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Invoice),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7193; "No. of Return Orders"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Return Order"),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Return Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7194; "No. of Credit Memos"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const("Credit Memo"),
                                                         "Buy-from Vendor No." = field("No.")));
            Caption = 'No. of Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7195; "No. of Order Addresses"; Integer)
        {
            CalcFormula = count("Order Address" where("Vendor No." = field("No.")));
            Caption = 'No. of Order Addresses';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7196; "Pay-to No. of Quotes"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = const(Quote),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Quotes';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7197; "Pay-to No. of Blanket Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Blanket Order"),
                                                         "Pay-to Vendor No." = field("No.")));
            Caption = 'Pay-to No. of Blanket Orders';
            FieldClass = FlowField;
        }
        field(7198; "No. of Incoming Documents"; Integer)
        {
            CalcFormula = count("Incoming Document" where("Vendor No." = field("No.")));
            Caption = 'No. of Incoming Documents';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7601; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            TableRelation = "Document Sending Profile".Code;
        }
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU VAT Reg. No.';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Removed;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '22.0';
        }
        field(8001; "Currency Id"; Guid)
        {
            Caption = 'Currency Id';
            TableRelation = Currency.SystemId;

            trigger OnValidate()
            begin
                UpdateCurrencyCode();
            end;
        }
        field(8002; "Payment Terms Id"; Guid)
        {
            Caption = 'Payment Terms Id';
            TableRelation = "Payment Terms".SystemId;

            trigger OnValidate()
            begin
                UpdatePaymentTermsCode();
            end;
        }
        field(8003; "Payment Method Id"; Guid)
        {
            Caption = 'Payment Method Id';
            TableRelation = "Payment Method".SystemId;

            trigger OnValidate()
            begin
                UpdatePaymentMethodCode();
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
        field(12100; "Int. on Arrears Code"; Code[10])
        {
            Caption = 'Int. on Arrears Code';
            TableRelation = "Finance Charge Terms";
        }
        field(12101; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';

            trigger OnValidate()
            var
                LocalAppMgt: Codeunit LocalApplicationManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFiscalCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Resident, Resident::Resident);
                if "Fiscal Code" <> '' then
                    LocalAppMgt.CheckDigit("Fiscal Code");
            end;
        }
        field(12102; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code";
        }
        field(12103; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));
        }
        field(12104; "Soc. Sec. Company Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum(Contributions."Gross Amount" where("Vendor No." = field("No."),
                                                                  "Related Date" = field("Date Filter")));
            Caption = 'Soc. Sec. Company Base';
            FieldClass = FlowField;
        }
        field(12105; "Soc. Sec. 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Soc. Sec. 3 Parties Base';
        }
        field(12106; Resident; Option)
        {
            Caption = 'Resident';
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";

            trigger OnValidate()
            begin
                if Resident <> xRec.Resident then begin
                    TestField("Tax Representative Type", "Tax Representative Type"::" ");
                    if Resident = Resident::Resident then
                        InitFields()
                    else
                        "Fiscal Code" := '';
                end;
            end;
        }
        field(12108; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';

            trigger OnValidate()
            begin
                if not "Individual Person" then begin
                    Resident := Resident::Resident;
                    InitFields();
                    "Fiscal Code" := '';
                end else
                    TestField("Tax Representative Type", "Tax Representative Type"::" ");
            end;
        }
        field(12109; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
        field(12110; "Birth City"; Text[30])
        {
            Caption = 'Birth City';
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code".City
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
                PostCode.ValidateCity(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12111; "Birth Post Code"; Code[20])
        {
            Caption = 'Birth Post Code';
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code"
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12112; "Birth County"; Text[30])
        {
            Caption = 'Birth County';
        }
        field(12113; Gender; Option)
        {
            Caption = 'Gender';
            OptionCaption = ' ,Male,Female';
            OptionMembers = " ",Male,Female;
        }
        field(12114; "Residence Address"; Text[50])
        {
            Caption = 'Residence Address';
        }
        field(12115; "Residence Post Code"; Code[20])
        {
            Caption = 'Residence Post Code';
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code"
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Residence City", "Residence Post Code", "Residence County", "Residence Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12116; "Residence City"; Text[30])
        {
            Caption = 'Residence City';
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code".City
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Residence City", "Residence Post Code", "Residence County", "Residence Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12117; "Country of Fiscal Domicile"; Code[10])
        {
            Caption = 'Country/Region of Fiscal Domicile';
            TableRelation = "Country/Region";
        }
        field(12118; "Contribution Fiscal Code"; Code[20])
        {
            Caption = 'Contribution Fiscal Code';
        }
        field(12119; "Tax Exempt Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Exempt Amount (LCY)';
        }
        field(12120; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';

            trigger OnLookup()
            begin
                ContrCodes.LookupINAIL("INAIL Code");
            end;
        }
        field(12121; "INAIL Company Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum(Contributions."INAIL Company Amount" where("Vendor No." = field("No."),
                                                                          "Payment Date" = field("Date Filter"),
                                                                          "INAIL Code" = filter(<> '')));
            Caption = 'INAIL Company Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12122; "INAIL 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'INAIL 3 Parties Base';
        }
        field(12126; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "Tax Representative Type" <> "Tax Representative Type"::" " then begin
                    TestField("Individual Person", false);
                    TestField(Resident, Resident::"Non-Resident");
                end;
                if "Tax Representative Type" <> xRec."Tax Representative Type" then
                    "Tax Representative No." := '';
            end;
        }
        field(12127; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;

            trigger OnValidate()
            begin
                if "Tax Representative No." <> '' then
                    TestField("Tax Representative Type");
            end;
        }
        field(12129; "Birth Country/Region Code"; Code[10])
        {
            Caption = 'Birth Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12130; "Residence County"; Text[30])
        {
            Caption = 'Residence County';
        }
        field(12131; "Residence Country/Region Code"; Code[10])
        {
            Caption = 'Residence Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12170; "Apply Company Payment days"; Boolean)
        {
            Caption = 'Apply Company Payment days';
            InitValue = true;
        }
        field(12180; "Subcontracting Location Code"; Code[10])
        {
            Caption = 'Subcontracting Location Code';
            TableRelation = Location;
        }
        field(12181; "Subcontractor Procurement"; Boolean)
        {
            Caption = 'Subcontractor Procurement';
        }
        field(12182; "Linked to Work Center"; Boolean)
        {
            CalcFormula = exist("Work Center" where("Subcontractor No." = field("No.")));
            Caption = 'Linked to Work Center';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12183; Subcontractor; Boolean)
        {
            Caption = 'Subcontractor';
        }
        field(12184; "First Name"; Text[30])
        {
            Caption = 'First Name';

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
        field(12185; "Last Name"; Text[30])
        {
            Caption = 'Last Name';

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
        field(12186; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms" where("Payment Nos." = const(1));
        }
        field(12187; "Special Category"; Option)
        {
            Caption = 'Special Category';
            OptionCaption = ' ,A,B,C,D,E,F,G,H,K,L,M,N,P,Q,R,S,T,T1,T2,T3,T4,U,V,W,Y,Z,Z2';
            OptionMembers = " ",A,B,C,D,E,F,G,H,K,L,M,N,P,Q,R,S,T,T1,T2,T3,T4,U,V,W,Y,Z,Z2;
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
        key(Key3; "Vendor Posting Group")
        {
        }
        key(Key4; "Currency Code")
        {
        }
        key(Key5; Priority)
        {
        }
        key(Key6; "Country/Region Code")
        {
        }
        key(Key7; "Gen. Bus. Posting Group")
        {
        }
        key(Key8; "VAT Registration No.")
        {
        }
        key(Key9; Name)
        {
        }
        key(Key10; City)
        {
        }
        key(Key11; "Post Code")
        {
        }
        key(Key12; "Phone No.")
        {
        }
        key(Key13; Contact)
        {
        }
        key(Key14; Blocked)
        {
        }
        key(Key15; SystemModifiedAt)
        {
        }
#if not CLEAN23
        key(Key16; "Coupled to CRM")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteTag = '23.0';
        }
#endif
        key(Key21; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, City, "Post Code", "Phone No.", Contact)
        {
        }
        fieldgroup(Brick; "No.", Name, "Balance (LCY)", Contact, "Balance Due (LCY)", Image)
        {
        }
    }

    trigger OnDelete()
    var
        ItemVendor: Record "Item Vendor";
        PurchPrepmtPct: Record "Purchase Prepayment %";
        CustomReportSelection: Record "Custom Report Selection";
#if not CLEAN22
        IntrastatSetup: Record "Intrastat Setup";
#endif
        ItemReference: Record "Item Reference";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        ApprovalsMgmt.OnCancelVendorApprovalRequest(Rec);

        MoveEntries.MoveVendorEntries(Rec);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Vendor);
        CommentLine.SetRange("No.", "No.");
        if not CommentLine.IsEmpty() then
            CommentLine.DeleteAll();

        VendBankAcc.SetRange("Vendor No.", "No.");
        if not VendBankAcc.IsEmpty() then
            VendBankAcc.DeleteAll();

        OrderAddr.SetRange("Vendor No.", "No.");
        if not OrderAddr.IsEmpty() then
            OrderAddr.DeleteAll();

        FixedDueDates.SetRange(Type, FixedDueDates.Type::Vendor);
        FixedDueDates.SetRange(Code, "No.");
        FixedDueDates.DeleteAll();

        CheckOutstandingPurchaseDocuments();

        ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", Rec."No.");
        ItemReference.DeleteAll();

        UpdateContFromVend.OnDelete(Rec);

        DimMgt.DeleteDefaultDim(DATABASE::Vendor, "No.");

        ItemVendor.SetRange("Vendor No.", "No.");
        if not ItemVendor.IsEmpty() then
            ItemVendor.DeleteAll(true);

        CustomReportSelection.SetRange("Source Type", DATABASE::Vendor);
        CustomReportSelection.SetRange("Source No.", "No.");
        if not CustomReportSelection.IsEmpty() then
            CustomReportSelection.DeleteAll();

        PurchPrepmtPct.SetCurrentKey("Vendor No.");
        PurchPrepmtPct.SetRange("Vendor No.", "No.");
        if not PurchPrepmtPct.IsEmpty() then
            PurchPrepmtPct.DeleteAll(true);

        VATRegistrationLogMgt.DeleteVendorLog(Rec);
#if not CLEAN22
        IntrastatSetup.CheckDeleteIntrastatContact(IntrastatSetup."Intrastat Contact Type"::Vendor, "No.");
#endif
        CalendarManagement.DeleteCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::Vendor, "No.");
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            PurchSetup.Get();
            PurchSetup.TestField("Vendor Nos.");
            NoSeriesMgt.InitSeries(PurchSetup."Vendor Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        if "Invoice Disc. Code" = '' then
            "Invoice Disc. Code" := "No.";

        if not (InsertFromContact or (InsertFromTemplate and (Contact <> ''))) then
            UpdateContFromVend.OnInsert(Rec);

        if "Purchaser Code" = '' then
            SetDefaultPurchaser();

        DimMgt.UpdateDefaultDim(
          DATABASE::Vendor, "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        UpdateReferencedIds();
        SetLastModifiedDateTime();

        OnAfterOnInsert(Rec);
    end;

    trigger OnModify()
    begin
        UpdateReferencedIds();
        SetLastModifiedDateTime();

        if IsContactUpdateNeeded() then begin
            Modify();
            UpdateContFromVend.OnModify(Rec);
            if not Find() then begin
                Reset();
                if Find() then;
            end;
        end;
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRename(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        DimMgt.RenameDefaultDim(DATABASE::Vendor, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Vendor, xRec."No.", "No.");

        SetLastModifiedDateTime();
        if xRec."Invoice Disc. Code" = xRec."No." then
            "Invoice Disc. Code" := "No.";

        CalendarManagement.RenameCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::Vendor, "No.", xRec."No.");
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        CommentLine: Record "Comment Line";
        PostCode: Record "Post Code";
        VendBankAcc: Record "Vendor Bank Account";
        OrderAddr: Record "Order Address";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        MarketingSetup: Record "Marketing Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        MoveEntries: Codeunit MoveEntries;
        UpdateContFromVend: Codeunit "VendCont-Update";
        DimMgt: Codeunit DimensionManagement;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        CalendarManagement: Codeunit "Calendar Management";
        InsertFromContact: Boolean;
        FixedDueDates: Record "Fixed Due Dates";
        ContrCodes: Record "Contribution Code";

        Text000: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 for this vendor.';
        Text003: Label 'Do you wish to create a contact for %1 %2?';
        Text004: Label 'Contact %1 %2 is not related to vendor %3 %4.';
        Text005: Label 'post';
        Text006: Label 'create';
        Text007: Label 'You cannot %1 this type of document when Vendor %2 is blocked with type %3';
        Text008: Label 'The %1 %2 has been assigned to %3 %4.\The same %1 cannot be entered on more than one %3.';
        Text009: Label 'Reconciling IC transactions may be difficult if you change IC Partner Code because this %1 has ledger entries in a fiscal year that has not yet been closed.\ Do you still want to change the IC Partner Code?';
        Text010: Label 'You cannot change the contents of the %1 field because this %2 has one or more open ledger entries.';
        SelectVendorErr: Label 'You must select an existing vendor.';
        CreateNewVendTxt: Label 'Create a new vendor card for %1.', Comment = '%1 is the name to be used to create the customer. ';
        VendNotRegisteredTxt: Label 'This vendor is not registered. To continue, choose one of the following options:';
        SelectVendTxt: Label 'Select an existing vendor.';
        InsertFromTemplate: Boolean;
        PrivacyBlockedActionErr: Label 'You cannot %1 this type of document when Vendor %2 is blocked for privacy.', Comment = '%1 = action (create or post), %2 = vendor code.';
        PrivacyBlockedGenericTxt: Label 'Privacy Blocked must not be true for vendor %1.', Comment = '%1 = vendor code';
        ConfirmBlockedPrivacyBlockedQst: Label 'If you change the Blocked field, the Privacy Blocked field is changed to No. Do you want to continue?';
        CanNotChangeBlockedDueToPrivacyBlockedErr: Label 'The Blocked field cannot be changed because the user is blocked for privacy reasons.';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';
        FieldLengthErr: Label 'must not have the length more than 20 symbols';

    procedure AssistEdit(OldVend: Record Vendor): Boolean
    var
        Vend: Record Vendor;
    begin
        with Vend do begin
            Vend := Rec;
            PurchSetup.Get();
            PurchSetup.TestField("Vendor Nos.");
            if NoSeriesMgt.SelectSeries(PurchSetup."Vendor Nos.", OldVend."No. Series", "No. Series") then begin
                PurchSetup.Get();
                PurchSetup.TestField("Vendor Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := Vend;
                OnAssistEditOnBeforeExit(Rec);
                exit(true);
            end;
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::Vendor, "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowContact()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
        ConfirmManagement: Codeunit "Confirm Management";
        ContactPageID: Integer;
        ShouldExit: Boolean;
    begin
        if OfficeMgt.GetContact(OfficeContact, "No.") and (OfficeContact.Count = 1) then begin
            ContactPageID := PAGE::"Contact Card";
            OnShowContactOnBeforeOpenContactCard(OfficeContact, ContactPageID);
            PAGE.Run(ContactPageID, OfficeContact);
        end else begin
            ShouldExit := "No." = '';
            OnShowContactOnAfterCalcShouldExit(Rec, ContactPageID, ShouldExit);
            if ShouldExit then
                exit;

            ContBusRel.SetCurrentKey("Link to Table", "No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            ContBusRel.SetRange("No.", "No.");
            if not ContBusRel.FindFirst() then begin
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text003, TableCaption(), "No."), true) then
                    exit;
                UpdateContFromVend.InsertNewContact(Rec, false);
                ContBusRel.FindFirst();
            end;
            Commit();

            Cont.FilterGroup(2);
            Cont.SetRange("Company No.", ContBusRel."Contact No.");
            COntactPageID := PAGE::"Contact List";
            OnShowContactOnBeforeOpenContactList(Cont, ContactPageID);
            PAGE.Run(ContactPageID, Cont);
        end;
    end;

    procedure SetInsertFromContact(FromContact: Boolean)
    begin
        InsertFromContact := FromContact;
    end;

    procedure CheckBlockedVendOnDocs(Vend2: Record Vendor; Transaction: Boolean)
    var
        Source: Option Journal,Document;
    begin
        if IsOnBeforeCheckBlockedVendHandled(Vend2, Source::Document, Enum::"Gen. Journal Document Type"::" ", Transaction) then
            exit;

        if Vend2."Privacy Blocked" then
            VendPrivacyBlockedErrorMessage(Vend2, Transaction);

        if Vend2.Blocked = Vend2.Blocked::All then
            VendBlockedErrorMessage(Vend2, Transaction);
    end;

    procedure CheckBlockedVendOnJnls(Vend2: Record Vendor; DocType: Enum "Gen. Journal Document Type"; Transaction: Boolean)
    var
        Source: Option Journal,Document;
    begin
        if IsOnBeforeCheckBlockedVendHandled(Vend2, Source::Journal, DocType::" ", Transaction) then
            exit;

        with Vend2 do begin
            if "Privacy Blocked" then
                VendPrivacyBlockedErrorMessage(Vend2, Transaction);

            if (Blocked = Blocked::All) or
               (Blocked = Blocked::Payment) and (DocType = DocType::Payment)
            then
                VendBlockedErrorMessage(Vend2, Transaction);
        end;
    end;

    local procedure CheckOutstandingPurchaseDocuments()
    var
        PurchOrderLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOutstandingPurchaseDocuments(Rec, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.SetCurrentKey("Document Type", "Pay-to Vendor No.");
        PurchOrderLine.SetRange("Pay-to Vendor No.", "No.");
        if PurchOrderLine.FindFirst() then
            Error(
              Text000,
              TableCaption, "No.",
              PurchOrderLine."Document Type");

        PurchOrderLine.SetRange("Pay-to Vendor No.");
        PurchOrderLine.SetRange("Buy-from Vendor No.", "No.");
        if not PurchOrderLine.IsEmpty() then
            Error(
              Text000,
              TableCaption, "No.");
    end;

    procedure CreateAndShowNewInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.SetRange("Buy-from Vendor No.", "No.");
        PurchaseHeader.Insert(true);
        Commit();
        PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader)
    end;

    procedure CreateAndShowNewCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::"Credit Memo";
        PurchaseHeader.SetRange("Buy-from Vendor No.", "No.");
        PurchaseHeader.Insert(true);
        Commit();
        PAGE.Run(PAGE::"Purchase Credit Memo", PurchaseHeader)
    end;

    procedure CreateAndShowNewPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.SetRange("Buy-from Vendor No.", "No.");
        PurchaseHeader.Insert(true);
        Commit();
        PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
    end;

    procedure VendBlockedErrorMessage(Vend2: Record Vendor; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text005
        else
            Action := Text006;
        Error(
            ErrorInfo.Create(
                StrSubstNo(Text007, Action, Vend2."No.", Vend2.Blocked),
                true,
                Rec));
    end;

    procedure VendPrivacyBlockedErrorMessage(Vend2: Record Vendor; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
        if Transaction then
            Action := Text005
        else
            Action := Text006;

        Error(
            ErrorInfo.Create(
                StrSubstNo(PrivacyBlockedActionErr, Action, Vend2."No."),
                true,
                Rec));
    end;

    procedure GetPrivacyBlockedGenericErrorText(Vend2: Record Vendor): Text[250]
    begin
        exit(StrSubstNo(PrivacyBlockedGenericTxt, Vend2."No."));
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Vendor, GetPosition());
    end;

    procedure CalcOverDueBalance() OverDueBalance: Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        VendLedgEntryRemainAmtQuery: Query "Vend. Ledg. Entry Remain. Amt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcOverdueBalance(Rec, OverDueBalance, IsHandled);
        if IsHandled then
            exit(OverDueBalance);

        VendLedgEntryRemainAmtQuery.SetRange(Vendor_No, "No.");
        VendLedgEntryRemainAmtQuery.SetRange(IsOpen, true);
        VendLedgEntryRemainAmtQuery.SetFilter(Due_Date, '<%1', WorkDate());
        VendLedgEntryRemainAmtQuery.Open();

        if VendLedgEntryRemainAmtQuery.Read() then
            OverDueBalance := -VendLedgEntryRemainAmtQuery.Sum_Remaining_Amt_LCY;
    end;

    procedure GetTDDAddr(VendorNo: Code[20]; var AddrArray: array[8] of Text[100])
    var
        FormatAddr: Codeunit "Format Address";
    begin
        if Get(VendorNo) then begin
            FormatAddr.FormatAddr(
              AddrArray, Name, '', '', Address, '',
              City, "Post Code", '', "Country/Region Code");
            AddrArray[8] := FieldCaption("VAT Registration No.") + ':' + "VAT Registration No.";
        end;
        CompressArray(AddrArray);
    end;

    [Scope('OnPrem')]
    procedure InitFields()
    begin
        "First Name" := '';
        "Last Name" := '';
        "Date of Birth" := 0D;
        "Birth City" := '';
    end;

    [Scope('OnPrem')]
    procedure ValidateIndividualPerson()
    begin
        TestField("Individual Person");
    end;

    [Scope('OnPrem')]
    procedure LookupEntryNo(EntryNo: Integer): Integer
    var
        TempVendor: Record Vendor temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GetNonCustomVendors(TempVendor);
        TempVendor.FindFirst();
        if EntryNo <> 0 then
            if VendLedgEntry.Get(EntryNo) then
                TempVendor.Get(VendLedgEntry."Vendor No.");
        if PAGE.RunModal(0, TempVendor) = ACTION::LookupOK then begin
            VendLedgEntry.SetRange("Vendor No.", TempVendor."No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
            if PAGE.RunModal(0, VendLedgEntry, VendLedgEntry."Document No.") = ACTION::LookupOK then
                exit(VendLedgEntry."Entry No.");
        end;
        exit(EntryNo);
    end;

    [Scope('OnPrem')]
    procedure IsCustomAuthorityVendor(): Boolean
    var
        CustomsAuthorityVendor: Record "Customs Authority Vendor";
    begin
        CustomsAuthorityVendor.SetRange("Vendor No.", "No.");
        if CustomsAuthorityVendor.FindFirst() then
            exit(true);
        exit(false);
    end;

    local procedure GetNonCustomVendors(var TempVendor: Record Vendor temporary)
    begin
        TempVendor.DeleteAll();
        if FindSet() then
            repeat
                if not IsCustomAuthorityVendor() then begin
                    TempVendor := Rec;
                    TempVendor.Insert();
                end;
            until Next() = 0;
    end;

    procedure GetInvoicedPrepmtAmountLCY() InvoicedPrepmtAmountLCY: Decimal
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetInvoicedPrepmtAmountLCY(Rec, InvoicedPrepmtAmountLCY, IsHandled);
        if IsHandled then
            exit(InvoicedPrepmtAmountLCY);

        PurchLine.SetCurrentKey("Document Type", "Pay-to Vendor No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Pay-to Vendor No.", "No.");
        PurchLine.CalcSums("Prepmt. Amount Inv. (LCY)", "Prepmt. VAT Amount Inv. (LCY)");
        exit(PurchLine."Prepmt. Amount Inv. (LCY)" + PurchLine."Prepmt. VAT Amount Inv. (LCY)");
    end;

    procedure GetPriceCalculationMethod() Method: Enum "Price Calculation Method";
    begin
        if "Price Calculation Method" <> Method::" " then
            Method := "Price Calculation Method"
        else begin
            PurchSetup.Get();
            Method := PurchSetup."Price Calculation Method";
        end;
    end;

    procedure GetTotalAmountLCY() TotalAmountLCY: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTotalAmountLCY(Rec, TotalAmountLCY, IsHandled);
        if IsHandled then
            exit(TotalAmountLCY);

        CalcFields(
          "Balance (LCY)", "Outstanding Orders (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Outstanding Invoices (LCY)");

        exit(
          "Balance (LCY)" + "Outstanding Orders (LCY)" +
          "Amt. Rcd. Not Invoiced (LCY)" + "Outstanding Invoices (LCY)" - GetInvoicedPrepmtAmountLCY());
    end;

    [Scope('OnPrem')]
    procedure GetTaxCode(): Code[20]
    begin
        if "Fiscal Code" <> '' then
            exit("Fiscal Code");

        exit("VAT Registration No.");
    end;

    procedure HasAddress() Result: Boolean
    begin
        Result := (Address <> '') or
                  ("Address 2" <> '') or
                  (City <> '') or
                  ("Country/Region Code" <> '') or
                  (County <> '') or
                  ("Post Code" <> '') or
                  (Contact <> '');
        OnAfterHasAddress(Rec, Result);
    end;

    procedure GetBalanceAsCustomer(var LinkedCustomerNo: Code[20]) BalanceAsCustomer: Decimal;
    var
        Customer: Record Customer;
    begin
        BalanceAsCustomer := 0;
        LinkedCustomerNo := GetLinkedCustomer();
        if Customer.Get(LinkedCustomerNo) then begin
            OnGetBalanceAsCustomerOnBeforeCalcBalance(Customer);
            Customer.CalcFields("Balance (LCY)");
            BalanceAsCustomer := Customer."Balance (LCY)";
        end;
    end;

    procedure GetLinkedCustomer(): Code[20];
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        exit(
            ContBusRel.GetLinkedTables(
                Enum::"Contact Business Relation Link To Table"::Vendor, "No.",
                Enum::"Contact Business Relation Link To Table"::Customer))
    end;

    procedure GetVendorNo(VendorText: Text[100]): Code[20]
    begin
        exit(GetVendorNoOpenCard(VendorText, true));
    end;

    procedure GetVendorNoOpenCard(VendorText: Text[100]; ShowVendorCard: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
        NoFiltersApplied: Boolean;
        VendorWithoutQuote: Text;
        VendorFilterFromStart: Text;
        VendorFilterContains: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendorNoOpenCard(VendorText, ShowVendorCard, VendorNo, IsHandled);
        if IsHandled then
            exit(VendorNo);

        if VendorText = '' then
            exit('');

        if StrLen(VendorText) <= MaxStrLen(Vendor."No.") then
            if Vendor.Get(VendorText) then
                exit(Vendor."No.");

        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        Vendor.SetRange(Name, VendorText);
        OnGetVendorNoOpenCardOnBeforeVendorFindSet(Vendor);
        if Vendor.FindFirst() then
            exit(Vendor."No.");

        VendorWithoutQuote := ConvertStr(VendorText, '''', '?');

        Vendor.SetFilter(Name, '''@' + VendorWithoutQuote + '''');
        OnGetVendorNoOpenCardOnAfterSetVendorWithoutQuote(Vendor);
        if Vendor.FindFirst() and (Vendor.Count() = 1) then
            exit(Vendor."No.");
        Vendor.SetRange(Name);

        VendorFilterFromStart := '''@' + VendorWithoutQuote + '*''';

        Vendor.FilterGroup := -1;
        Vendor.SetFilter("No.", VendorFilterFromStart);
        Vendor.SetFilter(Name, VendorFilterFromStart);
        OnGetVendorNoOpenCardOnAfterVendorSetFilterFromStart(Vendor);
        if Vendor.FindFirst() then
            exit(Vendor."No.");

        VendorFilterContains := '''@*' + VendorWithoutQuote + '*''';

        Vendor.SetFilter("No.", VendorFilterContains);
        Vendor.SetFilter(Name, VendorFilterContains);
        Vendor.SetFilter(City, VendorFilterContains);
        Vendor.SetFilter(Contact, VendorFilterContains);
        Vendor.SetFilter("Phone No.", VendorFilterContains);
        Vendor.SetFilter("Post Code", VendorFilterContains);
        OnGetVendorNoOpenCardonAfterSetvendorFilters(Vendor, VendorFilterContains);

        if Vendor.Count() = 0 then
            MarkVendorsWithSimilarName(Vendor, VendorText);

        if Vendor.Count() = 1 then begin
            Vendor.FindFirst();
            exit(Vendor."No.");
        end;

        if not GuiAllowed() then
            Error(SelectVendorErr);

        OnGetVendorNoOpenCardOnAfterMarkCustomersWithSimilarName(Vendor);

        OnGetVendorNoOpenCardOnBeforeSelectVendor(Vendor);
        if Vendor.Count = 0 then begin
            if Vendor.WritePermission then
                case StrMenu(StrSubstNo('%1,%2', StrSubstNo(CreateNewVendTxt, VendorText), SelectVendTxt), 1, VendNotRegisteredTxt) of
                    0:
                        Error(SelectVendorErr);
                    1:
                        exit(CreateNewVendor(CopyStr(VendorText, 1, MaxStrLen(Vendor.Name)), ShowVendorCard));
                end;
            Vendor.Reset();
            NoFiltersApplied := true;
        end;

        if ShowVendorCard then
            VendorNo := PickVendor(Vendor, NoFiltersApplied)
        else
            exit('');

        if VendorNo <> '' then
            exit(VendorNo);

        Error(SelectVendorErr);
    end;

    local procedure MarkVendorsWithSimilarName(var Vendor: Record Vendor; VendorText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        VendorCount: Integer;
        VendorTextLenght: Integer;
        Treshold: Integer;
    begin
        if VendorText = '' then
            exit;
        if StrLen(VendorText) > MaxStrLen(Vendor.Name) then
            exit;
        VendorTextLenght := StrLen(VendorText);
        Treshold := VendorTextLenght div 5;
        if Treshold = 0 then
            exit;
        Vendor.Reset();
        Vendor.Ascending(false); // most likely to search for newest Vendors
        OnMarkVendorsWithSimilarNameOnBeforeVendorFindSet(Vendor);
        if Vendor.FindSet() then
            repeat
                VendorCount += 1;
                if Abs(VendorTextLenght - StrLen(Vendor.Name)) <= Treshold then
                    if TypeHelper.TextDistance(UpperCase(VendorText), UpperCase(Vendor.Name)) <= Treshold then
                        Vendor.Mark(true);
            until Vendor.Mark() or (Vendor.Next() = 0) or (VendorCount > 1000);
        Vendor.MarkedOnly(true);
    end;

    local procedure CreateNewVendor(VendorName: Text[100]; ShowVendorCard: Boolean) Result: Code[20]
    var
        Vendor: Record Vendor;
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        VendorCard: Page "Vendor Card";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateNewVendor(VendorName, ShowVendorCard, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not VendorTemplMgt.InsertVendorFromTemplate(Vendor) then
            Error(SelectVendorErr);

        Vendor.Name := VendorName;
        Vendor.Modify(true);
        Commit();
        if not ShowVendorCard then
            exit(Vendor."No.");
        Vendor.SetRange("No.", Vendor."No.");
        VendorCard.SetTableView(Vendor);
        if not (VendorCard.RunModal() = ACTION::OK) then
            Error(SelectVendorErr);

        exit(Vendor."No.");
    end;

    local procedure PickVendor(var Vendor: Record Vendor; NoFiltersApplied: Boolean): Code[20]
    var
        VendorList: Page "Vendor List";
    begin
        if not NoFiltersApplied then
            MarkVendorsByFilters(Vendor);

        VendorList.SetTableView(Vendor);
        VendorList.SetRecord(Vendor);
        VendorList.LookupMode := true;
        if VendorList.RunModal() = ACTION::LookupOK then
            VendorList.GetRecord(Vendor)
        else
            Clear(Vendor);

        exit(Vendor."No.");
    end;

    procedure SelectVendor(var Vendor: Record Vendor): Boolean
    begin
        exit(LookupVendor(Vendor));
    end;

    [Scope('OnPrem')]
    procedure LookupVendor(var Vendor: Record Vendor): Boolean
    var
        VendorLookup: Page "Vendor Lookup";
        Result: Boolean;
    begin
        VendorLookup.SetTableView(Vendor);
        VendorLookup.SetRecord(Vendor);
        VendorLookup.LookupMode := true;
        Result := VendorLookup.RunModal() = ACTION::LookupOK;
        if Result then
            VendorLookup.GetRecord(Vendor)
        else
            Clear(Vendor);

        exit(Result);
    end;

    local procedure MarkVendorsByFilters(var Vendor: Record Vendor)
    begin
        if Vendor.FindSet() then
            repeat
                Vendor.Mark(true);
            until Vendor.Next() = 0;
        if Vendor.FindFirst() then;
        Vendor.MarkedOnly := true;
    end;

    procedure OpenVendorLedgerEntries(FilterOnDueEntries: Boolean)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        OnBeforeOpenVendorLedgerEntries(Rec, DetailedVendorLedgEntry);
        DetailedVendorLedgEntry.SetRange("Vendor No.", "No.");
        CopyFilter("Global Dimension 1 Filter", DetailedVendorLedgEntry."Initial Entry Global Dim. 1");
        CopyFilter("Global Dimension 2 Filter", DetailedVendorLedgEntry."Initial Entry Global Dim. 2");
        if FilterOnDueEntries and (GetFilter("Date Filter") <> '') then begin
            CopyFilter("Date Filter", DetailedVendorLedgEntry."Initial Entry Due Date");
            DetailedVendorLedgEntry.SetFilter("Posting Date", '<=%1', GetRangeMax("Date Filter"));
        end;
        CopyFilter("Currency Filter", DetailedVendorLedgEntry."Currency Code");
        IsHandled := false;
        OnOpenVendorLedgerEntriesOnBeforeDrillDownEntries(DetailedVendorLedgEntry, FilterOnDueEntries, IsHandled);
        if not IsHandled then
            VendorLedgerEntry.DrillDownOnEntries(DetailedVendorLedgEntry);
    end;

    local procedure IsContactUpdateNeeded(): Boolean
    var
        VendContUpdate: Codeunit "VendCont-Update";
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
          ("Purchaser Code" <> xRec."Purchaser Code") or
          ("Country/Region Code" <> xRec."Country/Region Code") or
          ("Fax No." <> xRec."Fax No.") or
          ("Telex Answer Back" <> xRec."Telex Answer Back") or
          ("Registration Number" <> xRec."Registration Number") or
          ("VAT Registration No." <> xRec."VAT Registration No.") or
          ("Post Code" <> xRec."Post Code") or
          (County <> xRec.County) or
          ("E-Mail" <> xRec."E-Mail") or
          ("Home Page" <> xRec."Home Page");

        if not UpdateNeeded and not IsTemporary then
            UpdateNeeded := VendContUpdate.ContactNameIsBlank("No.");

        OnBeforeIsContactUpdateNeeded(Rec, xRec, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    procedure GetInsertFromContact(): Boolean
    begin
        exit(InsertFromContact);
    end;

    procedure GetInsertFromTemplate(): Boolean
    begin
        exit(InsertFromTemplate);
    end;

    procedure SetInsertFromTemplate(FromTemplate: Boolean)
    begin
        InsertFromTemplate := FromTemplate;
    end;

    procedure SetAddress(VendorAddress: Text[100]; VendorAddress2: Text[50]; VendorPostCode: Code[20]; VendorCity: Text[30]; VendorCounty: Text[30]; VendorCountryCode: Code[10]; VendorContact: Text[100])
    begin
        Address := VendorAddress;
        "Address 2" := VendorAddress2;
        "Post Code" := VendorPostCode;
        City := VendorCity;
        County := VendorCounty;
        "Country/Region Code" := VendorCountryCode;
        UpdateContFromVend.OnModify(Rec);
        Contact := VendorContact;
    end;

    protected procedure SetDefaultPurchaser()
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultPurchaser(Rec, IsHandled);
        if IsHandled then
            exit;

        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Purchaser Code", UserSetup."Salespers./Purch. Code");
    end;

    protected procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime();
        "Last Date Modified" := Today();

        OnAfterSetLastModifiedDateTime(Rec);
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceSource."Price Type"::Purchase;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Vendor);
        PriceSource.Validate("Source No.", "No.");
    end;

    procedure VATRegistrationValidation()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ResultRecordRef: RecordRef;
        ApplicableCountryCode: Code[10];
        IsHandled: Boolean;
        LogNotVerified: Boolean;
    begin
        IsHandled := false;
        OnBeforeVATRegistrationValidation(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if not VATRegistrationNoFormat.Test("VAT Registration No.", "Country/Region Code", "No.", DATABASE::Vendor) then
            exit;

        LogNotVerified := true;
        if ("Country/Region Code" <> '') or (VATRegistrationNoFormat."Country/Region Code" <> '') then begin
            ApplicableCountryCode := "Country/Region Code";
            if ApplicableCountryCode = '' then
                ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";
            if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                LogNotVerified := false;
                VATRegistrationLogMgt.ValidateVATRegNoWithVIES(
                    ResultRecordRef, Rec, "No.", VATRegistrationLog."Account Type"::Vendor.AsInteger(), ApplicableCountryCode);
                ResultRecordRef.SetTable(Rec);
            end;
        end;

        if LogNotVerified then
            VATRegistrationLogMgt.LogVendor(Rec);
    end;

    procedure UpdateCurrencyId()
    var
        Currency: Record Currency;
    begin
        if "Currency Code" = '' then begin
            Clear("Currency Id");
            exit;
        end;

        if not Currency.Get("Currency Code") then
            exit;

        "Currency Id" := Currency.SystemId;
    end;

    procedure UpdatePaymentTermsId()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if "Payment Terms Code" = '' then begin
            Clear("Payment Terms Id");
            exit;
        end;

        if not PaymentTerms.Get("Payment Terms Code") then
            exit;

        "Payment Terms Id" := PaymentTerms.SystemId;
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

    local procedure UpdateCurrencyCode()
    var
        Currency: Record Currency;
    begin
        if not IsNullGuid("Currency Id") then
            Currency.GetBySystemId("Currency Id");

        Validate("Currency Code", Currency.Code);
    end;

    local procedure UpdatePaymentTermsCode()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if not IsNullGuid("Payment Terms Id") then
            PaymentTerms.GetBySystemId("Payment Terms Id");

        Validate("Payment Terms Code", PaymentTerms.Code);
    end;

    local procedure UpdatePaymentMethodCode()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if not IsNullGuid("Payment Method Id") then
            PaymentMethod.GetBySystemId("Payment Method Id");

        Validate("Payment Method Code", PaymentMethod.Code);
    end;

    procedure UpdateReferencedIds()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        UpdateCurrencyId();
        UpdatePaymentTermsId();
        UpdatePaymentMethodId();
    end;

    procedure GetReferencedIds(var TempField: Record "Field" temporary)
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Vendor, FieldNo("Currency Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Vendor, FieldNo("Payment Terms Id"));
        DataTypeManagement.InsertFieldToBuffer(TempField, DATABASE::Vendor, FieldNo("Payment Method Id"));
    end;

    local procedure ValidatePurchaserCode()
    begin
        if "Purchaser Code" <> '' then
            if SalespersonPurchaser.Get("Purchaser Code") then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    Error(SalespersonPurchaser.GetPrivacyBlockedGenericText(SalespersonPurchaser, false))
    end;

    procedure CheckAllowMultiplePostingGroups()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckAllowMultiplePostingGroups(IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        if PurchSetup."Allow Multiple Posting Groups" then
            TestField("Allow Multiple Posting Groups");
    end;

    local procedure UpdateFormatRegion();
    var
        Language: Record Language;
        LanguageSelection: Record "Language Selection";
    begin
        if (Rec."Format Region" <> '') then
            exit;
        if not Language.Get("Language Code") then
            exit;

        LanguageSelection.SetRange("Language ID", Language."Windows Language ID");
        if LanguageSelection.FindFirst() then
            Rec.Validate("Format Region", LanguageSelection."Language Tag");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasAddress(Vendor: Record Vendor; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var Vendor: Record Vendor; xVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var Vendor: Record Vendor; xVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var Vendor: Record Vendor; xVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Vendor: Record Vendor; xVendor: Record Vendor; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCity(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupPostCode(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditOnBeforeExit(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsContactUpdateNeeded(Vendor: Record Vendor; xVendor: Record Vendor; var UpdateNeeded: Boolean)
    begin
    end;

    local procedure IsOnBeforeCheckBlockedVendHandled(Vendor: Record Vendor; Source: Option Journal,Document; DocType: Enum "Gen. Journal Document Type"; Transaction: Boolean) IsHandled: Boolean
    begin
        OnBeforeCheckBlockedVend(Vendor, Source, DocType.AsInteger(), Transaction, IsHandled)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedVend(Vendor: Record Vendor; Source: Option Journal,Document; DocType: Option; Transaction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOutstandingPurchaseDocuments(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNewVendor(VendorName: Text[100]; ShowVendorCard: Boolean; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendorNoOpenCard(VendorText: Text; ShowVendorCard: Boolean; var VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcOverdueBalance(var Vendor: Record Vendor; var OverdueBalance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInvoicedPrepmtAmountLCY(var Vendor: Record Vendor; var InvoicedPrepmtAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTotalAmountLCY(var Vendor: Record Vendor; var TotalAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLastModifiedDateTime(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var Vendor: Record Vendor; xVendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenVendorLedgerEntries(var Vendor: Record Vendor; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupCity(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostCode(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultPurchaser(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFiscalCode(var Vendor: Record Vendor; xVendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Vendor: Record Vendor; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATRegistrationNo(var Rec: Record "Vendor"; xRec: Record "Vendor"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Vendor: Record Vendor; var xVendor: Record Vendor; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATRegistrationValidation(var Vendor: Record Vendor; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardOnBeforeVendorFindSet(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardOnAfterVendorSetFilterFromStart(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardOnAfterSetVendorWithoutQuote(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardonAfterSetvendorFilters(var Vendor: Record Vendor; var VendorFilterContains: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMarkVendorsWithSimilarNameOnBeforeVendorFindSet(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowContactOnAfterCalcShouldExit(var Vendor: Record Vendor; var ContactPageID: Integer; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowContactOnBeforeOpenContactCard(var Contact: Record Contact; var ContactPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowContactOnBeforeOpenContactList(var Contact: Record Contact; var ContactPageID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBalanceAsCustomerOnBeforeCalcBalance(var Customer: Record Customer)
    begin
    end;

#if not CLEAN21
    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    [Scope('OnPrem')]
    procedure ValidatePricesIncludingVATOnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        OnValidatePricesIncludingVATOnAfterGetVATPostingSetup(VATPostingSetup);
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '16.0')]
    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnAfterGetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRegistrationNumber(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAllowMultiplePostingGroups(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardOnAfterMarkCustomersWithSimilarName(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVendorNoOpenCardOnBeforeSelectVendor(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenVendorLedgerEntriesOnBeforeDrillDownEntries(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; FilterOnDueEntries: Boolean; var IsHandled: Boolean)
    begin
    end;
}

