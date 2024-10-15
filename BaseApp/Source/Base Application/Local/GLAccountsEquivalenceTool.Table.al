// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.GeneralLedger.Ledger;

table 10720 "G/L Accounts Equivalence Tool"
{
    Caption = 'G/L Accounts Equivalence Tool';
    ObsoleteReason = 'Obsolete feature';
    ObsoleteState = Pending;
    Permissions = TableData "G/L Entry" = rimd;
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = "Historic G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;
        }
        field(2; Name; Text[30])
        {
            CalcFormula = Lookup("Historic G/L Account".Name where("No." = field("No.")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Account Type"; Option)
        {
            CalcFormula = Lookup("Historic G/L Account"."Account Type" where("No." = field("No.")));
            Caption = 'Account Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Posting,Heading';
            OptionMembers = Posting,Heading;
        }
        field(4; "New No."; Code[20])
        {
            Caption = 'New No.';
            TableRelation = "New G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;
        }
        field(5; "New Name"; Text[30])
        {
            CalcFormula = Lookup("New G/L Account".Name where("No." = field("New No.")));
            Caption = 'New Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Matching Type"; Option)
        {
            Caption = 'Matching Type';
            OptionCaption = '1-1,1-n';
            OptionMembers = "1-1","1-n";
        }
        field(7; Ready; Boolean)
        {
            Caption = 'Ready';
        }
        field(8; Implement; Boolean)
        {
            Caption = 'Implement';
        }
        field(9; Done; Boolean)
        {
            Caption = 'Done';
            Editable = false;
        }
        field(10; "Last Run Date"; Date)
        {
            Caption = 'Last Run Date';
            Editable = false;
        }
        field(11; Preferred; Boolean)
        {
            Caption = 'Preferred';
        }
        field(12; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Last Run Date", Implement)
        {
        }
        key(Key3; "New No.")
        {
        }
    }

    fieldgroups
    {
    }
}

