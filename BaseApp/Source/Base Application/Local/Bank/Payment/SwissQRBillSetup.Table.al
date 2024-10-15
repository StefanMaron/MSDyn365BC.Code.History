// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 11507 "Swiss QRBill Setup"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension table 11512 Swiss QR-Bill Setup';
    ObsoleteTag = '18.0';
    ReplicateData = false;

    fields
    {
        field(1; "Primary key"; Code[10]) { }
        field(2; "Swiss-Cross Image"; Media) { }
        field(3; "Address Type"; Option)
        {
            OptionMembers = Structured,Combined;
        }
        field(4; "Swiss-Cross Image Blob"; BLOB) { }
        field(6; "Umlaut Chars Encode Mode"; Option)
        {
            OptionMembers = Single,Double,Remove;
        }
        field(8; "Default Layout"; Code[20]) { }
        field(9; "Last Used Reference No."; BigInteger) { }
        field(10; "Journal Template"; Code[10]) { }
        field(11; "Journal Batch"; Code[10]) { }
    }
    keys
    {
        key(PK; "Primary key")
        {
            Clustered = true;
        }
    }
}
