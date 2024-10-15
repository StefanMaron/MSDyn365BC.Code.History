// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 10126 "Bank Rec. Sub-line"
{
    Caption = 'Bank Rec. Sub-line';
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Rec. Header"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Bank Rec. Line No."; Integer)
        {
            Caption = 'Bank Rec. Line No.';
            TableRelation = "Bank Rec. Line"."Line No." where("Bank Account No." = field("Bank Account No."),
                                                               "Statement No." = field("Statement No."),
                                                               "Record Type" = const(Deposit));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(9; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    BankRecHdr.Get("Bank Account No.", "Statement No.");
                    Currency.Get("Currency Code");
                    "Currency Factor" := CurrExchRate.ExchangeRate(BankRecHdr."Statement Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
            end;
        }
        field(17; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(18; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(19; "Bank Ledger Entry No."; Integer)
        {
            Caption = 'Bank Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Bank Rec. Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        BankRecHdr: Record "Bank Rec. Header";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
}

