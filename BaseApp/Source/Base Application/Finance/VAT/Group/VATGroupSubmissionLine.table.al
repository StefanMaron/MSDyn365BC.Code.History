// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Group;

table 4803 "VATGroup Submission Line"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to VAT Group Management extension table 4703 VAT Group Submission Line';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Group Submission ID"; Guid) { }
        field(5; "VAT Group Submission No."; Code[20]) { }
        field(7; "ID"; Guid) { }
        field(10; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(15; "Row No."; Code[10]) { }
        field(20; Description; Text[100]) { }
        field(25; "Box No."; Text[30]) { }
        field(30; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "VAT Group Submission ID", "Line No.")
        {
            Clustered = true;
        }
    }
}
