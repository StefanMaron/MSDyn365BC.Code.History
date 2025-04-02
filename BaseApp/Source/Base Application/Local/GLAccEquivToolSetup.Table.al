#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 10723 "G/L Acc. Equiv. Tool Setup"
{
    Caption = 'G/L Acc. Equiv. Tool Setup';
    ObsoleteReason = 'Obsolete feature';
#if CLEAN25
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '15.0';
#endif
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Delete Acc. Old Chart of Acc."; Code[20])
        {
            Caption = 'Delete Acc. Old Chart of Acc.';
#if not CLEAN25
            TableRelation = "Historic G/L Account"."No.";
            ValidateTableRelation = true;
#endif
        }
        field(3; "Delete Acc. New Chart of Acc."; Code[20])
        {
            Caption = 'Delete Acc. New Chart of Acc.';
#if not CLEAN25
            TableRelation = "New G/L Account"."No.";
            ValidateTableRelation = true;
#endif
        }
        field(4; "Log File Name"; Text[250])
        {
            Caption = 'Log File Name';
        }
        field(5; "Fiscal Year Starting Date"; Date)
        {
            Caption = 'Fiscal Year Starting Date';
        }
        field(6; "Fiscal Year Ending Date"; Date)
        {
            Caption = 'Fiscal Year Ending Date';
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ClosingDates = true;
        }
        field(9; "Proposed Balance Date"; Date)
        {
            Caption = 'Proposed Balance Date';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif
