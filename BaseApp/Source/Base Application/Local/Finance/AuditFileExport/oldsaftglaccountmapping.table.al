// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Account;

table 10624 "SAFT G/L Account Mapping"
{
    Caption = 'SAF-T G/L Account Mapping';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Mapping Range Code"; Code[20])
        {
            Editable = false;
            NotBlank = true;
        }
        field(2; "G/L Account No."; Code[20])
        {
            Editable = false;
            NotBlank = true;
            TableRelation = "G/L Account";
        }
        field(3; "Mapping Type"; Option)
        {
            OptionMembers = " ","Two Digit Standard Account","Four Digit Standard Account","Income Statement";
        }
        field(4; "Category No."; Code[20])
        {
        }
        field(5; "No."; Code[20])
        {
        }
        field(6; "G/L Entries Exists"; Boolean)
        {
            Editable = false;
        }
        field(50; "G/L Account Name"; Text[100])
        {
            CalcFormula = Lookup("G/L Account".Name where("No." = field("G/L Account No.")));
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Mapping Range Code", "G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

