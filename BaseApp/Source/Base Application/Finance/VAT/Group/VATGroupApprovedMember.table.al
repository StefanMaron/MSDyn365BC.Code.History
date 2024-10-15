// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Group;

table 4800 "VATGroup Approved Member"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to VAT Group Management extension table 4700 VAT Group Approved Member';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid) { }
        field(2; "Group Member Name"; Text[250]) { }
        field(3; "Contact Person Name"; Text[250]) { }
        field(4; "Contact Person Email"; Text[250]) { }
        field(5; Company; Text[30]) { }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(GroupMemberName; "Group Member Name")
        {
        }
    }
}
