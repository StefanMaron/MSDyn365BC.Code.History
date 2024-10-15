// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Foundation.Period;

table 10626 "SAFT Mapping Range"
{
    Caption = 'SAF-T Mapping Range';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            NotBlank = true;
        }
        field(2; "Mapping Type"; Option)
        {
            OptionMembers = " ","Two Digit Standard Account","Four Digit Standard Account","Income Statement";
        }
        field(3; "Starting Date"; Date)
        {
        }
        field(4; "Ending Date"; Date)
        {
        }
        field(5; "Range Type"; Option)
        {
            OptionMembers = " ","Accounting Period","Date Range";
        }
        field(6; "Accounting Period"; Date)
        {
            TableRelation = "Accounting Period" where("New Fiscal Year" = const(true));
        }
        field(7; "Include Incoming Balance"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Range Type", "Starting Date", "Ending Date")
        {
        }
    }
}

