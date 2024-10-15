// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

using Microsoft.Finance.GeneralLedger.Account;

table 1661 "Import G/L Transaction"
{
    Caption = 'Import G/L Transaction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            Editable = false;
        }
        field(2; "External Account"; Code[50])
        {
            Caption = 'External Account';

            trigger OnValidate()
            var
                ImportGLTransaction: Record "Import G/L Transaction";
            begin
                if "External Account" = '' then
                    exit;
                ImportGLTransaction.SetRange("App ID", "App ID");
                ImportGLTransaction.SetRange("External Account", "External Account");
                if ImportGLTransaction.FindFirst() then
                    Validate("G/L Account", ImportGLTransaction."G/L Account");
            end;
        }
        field(3; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account" where(Blocked = const(false),
                                                 "Direct Posting" = const(true),
                                                 "Account Type" = const(Posting));
        }
        field(4; "G/L Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("G/L Account")));
            Caption = 'G/L Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(12; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "App ID", "Entry No.")
        {
        }
        key(Key2; "App ID", "External Account", "Transaction Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

