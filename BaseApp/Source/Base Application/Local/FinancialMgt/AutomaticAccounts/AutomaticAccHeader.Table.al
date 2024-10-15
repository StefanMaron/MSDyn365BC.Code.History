// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AutomaticAccounts;

table 11203 "Automatic Acc. Header"
{
    Caption = 'Automatic Acc. Header';
    ObsoleteReason = 'Moved to Automatic Account Codes app.';
#if CLEAN22
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#else
    DrillDownPageID = "Automatic Acc. List";
    LookupPageID = "Automatic Acc. List";
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#endif

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; Balance; Decimal)
        {
            CalcFormula = sum("Automatic Acc. Line"."Allocation %" where("Automatic Acc. No." = field("No.")));
            Caption = 'Balance';
            FieldClass = FlowField;
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

    trigger OnDelete()
    begin
        AutoAccountLine.SetRange("Automatic Acc. No.", "No.");
        AutoAccountLine.DeleteAll(true);
    end;

    var
        AutoAccountLine: Record "Automatic Acc. Line";
}

