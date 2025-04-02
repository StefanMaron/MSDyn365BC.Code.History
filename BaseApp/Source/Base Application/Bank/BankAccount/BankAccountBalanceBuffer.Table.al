// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

table 929 "Bank Account Balance Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
        }
        field(10; "Net Change"; Decimal)
        {
            Caption = 'Net Change';
        }
        field(11; "Net Change (LCY)"; Decimal)
        {
            Caption = 'Net Change (LCY)';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
