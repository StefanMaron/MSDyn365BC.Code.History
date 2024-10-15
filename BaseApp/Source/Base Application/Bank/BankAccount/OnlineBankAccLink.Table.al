// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

table 777 "Online Bank Acc. Link"
{
    Caption = 'Online Bank Acc. Link';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Bank Account"."No.";
        }
        field(2; "Online Bank Account ID"; Text[250])
        {
            Caption = 'Online Bank Account ID';
        }
        field(3; "Online Bank ID"; Text[250])
        {
            Caption = 'Online Bank ID';
        }
        field(4; "Automatic Logon Possible"; Boolean)
        {
            Caption = 'Automatic Logon Possible';
        }
        field(5; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(7; Contact; Text[50])
        {
            Caption = 'Contact';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(100; "Temp Linked Bank Account No."; Code[20])
        {
            Caption = 'Temp Linked Bank Account No.';
        }
        field(101; ProviderId; Text[50])
        {
            Caption = 'ProviderId';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

