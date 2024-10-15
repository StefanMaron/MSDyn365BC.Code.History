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
    Permissions = TableData "G/L Entry" = rimd;
#if CLEAN25
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';
#endif
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
#if not CLEAN25
            TableRelation = "Historic G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;
#endif
        }
        field(2; Name; Text[30])
        {
#if not CLEAN25
            CalcFormula = lookup("Historic G/L Account".Name where("No." = field("No.")));
#endif
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Account Type"; Option)
        {
#if not CLEAN25
            CalcFormula = lookup("Historic G/L Account"."Account Type" where("No." = field("No.")));
#endif
            Caption = 'Account Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Posting,Heading';
            OptionMembers = Posting,Heading;
        }
        field(4; "New No."; Code[20])
        {
            Caption = 'New No.';
#if not CLEAN25
            TableRelation = "New G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = true;
            ValidateTableRelation = true;
#endif
        }
        field(5; "New Name"; Text[30])
        {
#if not CLEAN25
            CalcFormula = lookup("New G/L Account".Name where("No." = field("New No.")));
#endif
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

