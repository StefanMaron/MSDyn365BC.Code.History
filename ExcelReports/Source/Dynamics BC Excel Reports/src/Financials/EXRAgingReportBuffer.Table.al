// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports;

table 4401 "EXR Aging Report Buffer"
{
    Caption = 'Aging Report Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(3; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
        }
        field(4; "Vendor Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(10; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(12; "Currency Code"; Code[20])
        {
            Caption = 'Currency Code';
        }
        field(13; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
        }
        field(14; "Remaining Amount (LCY)"; Decimal)
        {
            Caption = 'Remaining Amount (LCY)';
        }
        field(15; "Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Dimension 1 Code';
        }
        field(16; "Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Dimension 2 Code';
        }
        field(20; "Original Amount"; Decimal)
        {
            Caption = 'Original Amount';
        }
        field(21; "Original Amount (LCY)"; Decimal)
        {
            Caption = 'Original Amount (LCY)';
        }
        field(22; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(23; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(25; "Source Name"; Text[100])
        {
            Caption = 'Source Name';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key1; "Vendor Source No.")
        {
        }
    }
}
