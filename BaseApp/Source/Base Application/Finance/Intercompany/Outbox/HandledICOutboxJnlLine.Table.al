namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 417 "Handled IC Outbox Jnl. Line"
{
    Caption = 'Handled IC Outbox Jnl. Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            TableRelation = if ("Account Type" = const("G/L Account")) "IC G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const("Bank Account")) "IC Bank Account";
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
            Editable = false;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(8; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(9; "Currency Code"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Code';
            Editable = false;
        }
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(12; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            Editable = false;
        }
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
            Editable = false;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Editable = false;
        }
        field(15; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.DeleteICJnlDim(
          DATABASE::"Handled IC Outbox Jnl. Line", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}

