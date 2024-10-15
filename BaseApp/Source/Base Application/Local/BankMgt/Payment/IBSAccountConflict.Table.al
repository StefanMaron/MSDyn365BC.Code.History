// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

table 2000013 "IBS Account Conflict"
{
    Caption = 'IBS Account Conflict';
    ObsoleteReason = 'Legacy ISABEL';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "IBS Log Entry No."; Code[20])
        {
            Caption = 'IBS Log Entry No.';
        }
        field(21; "Contract ID"; Code[50])
        {
            Caption = 'Contract ID';
        }
        field(22; "Bank ID"; Code[50])
        {
            Caption = 'Bank ID';
        }
        field(23; Account; Code[50])
        {
            Caption = 'Account';
        }
        field(24; "Account Type"; Code[50])
        {
            Caption = 'Account Type';
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "IBS Log Entry No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

