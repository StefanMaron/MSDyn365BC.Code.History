// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Finance.VAT.TransactionNature;
using Microsoft.EServices.EDocument;

table 741 "VAT Report Line"
{
    Caption = 'VAT Report Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            Editable = false;
            TableRelation = "VAT Report Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
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
            Editable = false;
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            IF (Type = const(Sale)) Customer;
        }
        field(13; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
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
        field(19; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";
        }
        field(20; "Internal Ref. No."; Text[30])
        {
            Caption = 'Internal Ref. No.';
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
        field(26; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
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
        field(55; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            Editable = false;
        }
        field(56; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(100; "Record Identifier"; Code[30])
        {
            Caption = 'Record Identifier';
            Editable = false;
        }
        field(12100; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
            Editable = false;
        }
        field(12102; "Contract Payment Type"; Option)
        {
            Caption = 'Contract Payment Type';
            OptionCaption = 'Without Contract,Contract,Other';
            OptionMembers = "Without Contract",Contract,Other;
        }
        field(12104; "Amount Incl. VAT"; Decimal)
        {
            Caption = 'Amount Incl. VAT';
            Editable = false;
        }
        field(12106; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
            Editable = false;
        }
        field(12108; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
            Editable = false;
        }
        field(12109; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        field(12110; "VAT Group Identifier"; Text[20])
        {
            Caption = 'VAT Group Identifier';
        }
        field(12111; "Incl. in Report"; Boolean)
        {
            Caption = 'Incl. in Report';
        }
        field(12112; "VAT Transaction Nature"; Code[4])
        {
            Caption = 'VAT Transaction Nature';
            TableRelation = "VAT Transaction Nature";
        }
        field(12113; "Fattura Document Type"; Code[20])
        {
            Caption = 'Fattura Document Type';
            TableRelation = "Fattura Document Type";
        }
    }

    keys
    {
        key(Key1; "VAT Report No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.")
        {
        }
        key(Key3; "Invoice No.")
        {
        }
        key(Key4; "VAT Report No.", "VAT Group Identifier")
        {
        }
        key(Key5; "VAT Report No.", "Record Identifier", Type, "VAT Group Identifier")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportHeader.Get("VAT Report No.");

        VATReportHeader.CheckEditingAllowed();
    end;

    var
        VATReportHeader: Record "VAT Report Header";
}

