// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

table 10622 "SAFT Mapping"
{
    Caption = 'SAF-T Mapping';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Mapping Type"; Option)
        {
            OptionMembers = " ","Two Digit Standard Account","Four Digit Standard Account","Income Statement";
        }
        field(2; "Category No."; Code[20])
        {
        }
        field(3; "No."; Code[20])
        {
        }
        field(4; Description; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Mapping Type", "Category No.", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }
}

