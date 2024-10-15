// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 11502 "Swiss QRBill Buffer"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension table 11510 Swiss QR-Bill Buffer';
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; IBAN; Code[50]) { }
        field(3; Amount; Decimal) { }
        field(4; Currency; Code[10]) { }
        field(5; "Payment Reference Type"; Option)
        {
            OptionMembers = "Without Reference","Creditor Reference (ISO 11649)","QR Reference";
        }
        field(6; "Payment Reference"; Code[50]) { }
        field(7; "Unstructured Message"; Text[140]) { }
        field(8; "Billing Information"; Text[140]) { }
        field(9; "Alt. Procedure Name 1"; Text[10]) { }
        field(10; "Alt. Procedure Value 1"; Text[100]) { }
        field(11; "Alt. Procedure Name 2"; Text[10]) { }
        field(12; "Alt. Procedure Value 2"; Text[100]) { }
        field(14; "IBAN Type"; Option)
        {
            OptionMembers = IBAN,"QR-IBAN";
        }
        field(15; "Language Code"; Code[10]) { }
        field(20; "Creditor Address Type"; Option)
        {
            OptionMembers = Structured,Combined;
        }
        field(21; "Creditor Name"; Text[70]) { }
        field(22; "Creditor Street Or AddrLine1"; Text[70]) { }
        field(23; "Creditor BuildNo Or AddrLine2"; Text[70]) { }
        field(24; "Creditor Postal Code"; Code[16]) { }
        field(25; "Creditor City"; Text[30]) { }
        field(26; "Creditor Country"; Code[2]) { }
        field(30; "UCreditor Address Type"; Option)
        {
            OptionMembers = Structured,Combined;
        }
        field(31; "UCreditor Name"; Text[70]) { }
        field(32; "UCreditor Street Or AddrLine1"; Text[70]) { }
        field(33; "UCreditor BuildNo Or AddrLine2"; Text[70]) { }
        field(34; "UCreditor Postal Code"; Code[16]) { }
        field(35; "UCreditor City"; Text[30]) { }
        field(36; "UCreditor Country"; Code[2]) { }
        field(40; "UDebtor Address Type"; Option)
        {
            OptionMembers = Structured,Combined;
        }
        field(41; "UDebtor Name"; Text[70]) { }
        field(42; "UDebtor Street Or AddrLine1"; Text[70]) { }
        field(43; "UDebtor BuildNo Or AddrLine2"; Text[70]) { }
        field(44; "UDebtor Postal Code"; Code[16]) { }
        field(45; "UDebtor City"; Text[30]) { }
        field(46; "UDebtor Country"; Code[2]) { }
        field(100; "QR-Code Image"; Media) { }
        field(101; "QR-Code Image Blob"; BLOB) { }
        field(102; "File Name"; Text[250]) { }
        field(104; "QR-Bill Layout"; Code[20]) { }
        field(105; "Source Record Printed"; Boolean) { }
        field(106; "Customer Ledger Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
