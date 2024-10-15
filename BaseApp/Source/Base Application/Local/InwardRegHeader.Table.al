// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;

table 11200 "Inward Reg. Header"
{
    Caption = 'Inward Reg. Header';
    ObsoleteReason = 'Replaced by extension';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,Posted,Reversed';
            OptionMembers = New,Posted,Reversed;
        }
        field(10; Responsible; Code[20])
        {
            Caption = 'Responsible';
            TableRelation = "Salesperson/Purchaser";
        }
        field(11; "Latest Return"; Date)
        {
            Caption = 'Latest Return';
        }
        field(22; "Vendor Invoice No."; Code[20])
        {
            Caption = 'Vendor Invoice No.';
        }
        field(25; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(26; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            Editable = false;
            TableRelation = "Vendor Posting Group";
        }
        field(27; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(30; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(40; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(41; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "No.")
        {
        }
        key(Key3; Responsible, "Latest Return")
        {
        }
        key(Key4; "Vendor Invoice No.")
        {
        }
    }

    fieldgroups
    {
    }
}

