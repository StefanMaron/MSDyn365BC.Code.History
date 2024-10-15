// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 737 "VAT Return Period"
{
    Caption = 'VAT Return Period';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(3; "Period Key"; Code[10])
        {
            Caption = 'Period Key';
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Closed';
            OptionMembers = Open,Closed;
        }
        field(8; "Received Date"; Date)
        {
            Caption = 'Received Date';
        }
        field(20; "VAT Return No."; Code[20])
        {
            Caption = 'VAT Return No.';
            Editable = false;
        }
        field(21; "VAT Return Status"; Option)
        {
            CalcFormula = lookup("VAT Report Header".Status where("No." = field("VAT Return No.")));
            Caption = 'VAT Return Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Released,Exported,Submitted';
            OptionMembers = Open,Released,Exported,Submitted;
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

    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupGot: Boolean;

        OverdueTxt: Label 'Your VAT return is overdue since %1 (%2 days)', Comment = '%1 - date; %2 - days count';
        OpenTxt: Label 'Your VAT return is due %1 (in %2 days)', Comment = '%1 - date; %2 - days count';

    internal procedure FindVATPeriodByDate(VATReportingDate: Date): Boolean
    begin
        Rec.SetFilter("End Date", '>=%1', VATReportingDate);
        Rec.SetFilter("Start Date", '<=%1', VATReportingDate);
        exit(Rec.FindFirst());
    end;

    local procedure GetVATReportSetup()
    begin
        if VATReportSetupGot then
            exit;

        VATReportSetup.Get();
        VATReportSetupGot := true;
    end;

    procedure CheckOpenOrOverdue(): Text
    begin
        GetVATReportSetup();
        if (Status = Status::Open) and ("Due Date" <> 0D) then
            case true of
                // Overdue
                ("Due Date" < WorkDate()):
                    exit(StrSubstNo(OverdueTxt, "Due Date", WorkDate() - "Due Date"));
                // Open
                VATReportSetup.IsPeriodReminderCalculation() and
              ("Due Date" >= WorkDate()) and
              ("Due Date" <= CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate())):
                    exit(StrSubstNo(OpenTxt, "Due Date", "Due Date" - WorkDate()));
            end;
    end;
}
