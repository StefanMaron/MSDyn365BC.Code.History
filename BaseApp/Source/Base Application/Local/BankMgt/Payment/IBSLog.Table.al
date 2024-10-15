// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.NoSeries;

table 2000010 "IBS Log"
{
    Caption = 'IBS Log';
    ObsoleteReason = 'Legacy ISABEL';
    ObsoleteState = Removed;
    ObsoleteTag = '19.0';
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(21; "Process Status"; Option)
        {
            Caption = 'Process Status';
            Editable = false;
            OptionCaption = 'Created,Processed,Archived';
            OptionMembers = Created,Processed,Archived;
        }
        field(22; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            Editable = false;
            OptionCaption = 'Upload,Download,Report';
            OptionMembers = Upload,Download,"Report";
        }
        field(23; "Integration Type"; Option)
        {
            Caption = 'Integration Type';
            OptionCaption = 'Manual,Attended';
            OptionMembers = Manual,Attended;
        }
        field(24; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(25; "File Name"; Text[250])
        {
            Caption = 'File Name';
            Editable = false;
        }
        field(26; "File Type"; Option)
        {
            Caption = 'File Type';
            Editable = false;
            OptionCaption = 'National,International,Dom,SEPA,,,,,,,,,,Coda';
            OptionMembers = National,International,Dom,SEPA,,,,,,,,,,Coda;
        }
        field(27; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            Editable = false;
        }
        field(28; "BAN/IBAN"; Text[30])
        {
            Caption = 'BAN/IBAN';
            Editable = false;
        }
        field(31; "Processed Date"; Date)
        {
            Caption = 'Processed Date';
            Editable = false;
        }
        field(32; "Processed Time"; Time)
        {
            Caption = 'Processed Time';
            Editable = false;
        }
        field(33; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(34; "Request ID"; Code[20])
        {
            Caption = 'Request ID';
            Editable = false;
        }
        field(40; "IBS User ID"; Code[50])
        {
            Caption = 'IBS User ID';
        }
        field(41; "IBS Contract ID"; Code[50])
        {
            Caption = 'IBS Contract ID';
        }
        field(42; "Upload Status"; Option)
        {
            Caption = 'Upload Status';
            OptionCaption = ' ,Conflicts Exist,Ready for Upload';
            OptionMembers = " ","Conflicts Exist","Ready for Upload";
        }
        field(45; "IBS Request ID"; Text[250])
        {
            Caption = 'IBS Request ID';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Upload Status")
        {
        }
    }

    fieldgroups
    {
    }

}

