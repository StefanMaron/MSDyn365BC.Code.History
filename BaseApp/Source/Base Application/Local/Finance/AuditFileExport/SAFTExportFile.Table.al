// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

table 10629 "SAFT Export File"
{
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '17.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Export ID"; Integer)
        {
            Editable = false;
        }
        field(2; "File No."; Integer)
        {
        }
        field(3; "SAF-T File"; BLOB)
        {
        }
    }

    keys
    {
        key(Key1; "Export ID", "File No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

