// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 11506 "Swiss QRBill Reports"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension table 11514 Swiss QR-Bill Reports';
    ObsoleteTag = '18.0';
    ReplicateData = false;

    fields
    {
        field(1; "Report Type"; Option)
        {
            OptionMembers = "Posted Sales Invoice","Posted Service Invoice","Issued Reminder","Issued Finance Charge Memo";
        }
        field(2; Enabled; Boolean) { }
    }

    keys
    {
        key(PK; "Report Type")
        {
            Clustered = true;
        }
    }
}
