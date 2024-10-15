// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 11504 "Swiss QRBill Billing Info"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension table 11511 Swiss QR-Bill Billing Info';
    ObsoleteTag = '18.0';
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Document No."; Boolean) { }
        field(3; "Document Date"; Boolean) { }
        field(5; "VAT Number"; Boolean) { }
        field(6; "VAT Date"; Boolean) { }
        field(7; "VAT Details"; Boolean) { }
        field(9; "Payment Terms"; Boolean) { }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
