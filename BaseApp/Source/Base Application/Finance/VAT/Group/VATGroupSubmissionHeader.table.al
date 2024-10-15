// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Group;

table 4802 "VATGroup Submission Header"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to VAT Group Management extension table 4702 VAT Group Submission Header';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "ID"; Guid) { }
        field(5; "No."; Code[20]) { }
        field(6; "VAT Group Return No."; Code[20]) { }
        field(10; "Group Member ID"; Guid) { }
        field(15; "Group Member Name"; Text[250]) { }
        field(20; "Start Date"; Date) { }
        field(25; "End Date"; Date) { }
        field(30; "Submitted On"; DateTime) { }
        field(35; Company; Text[30]) { }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
        key("Submitted On"; "Submitted On")
        {
        }
        key("No."; "No.")
        {
        }
        key("VAT Group Return No."; "VAT Group Return No.")
        {
        }
        key(Dates; "Start Date", "End Date")
        {
        }
    }
}
