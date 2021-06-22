table 737 "VAT Return Period"
{
    Caption = 'VAT Return Period';
    LookupPageID = "VAT Return Period List";

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
            TableRelation = IF ("VAT Return No." = FILTER(<> '')) "VAT Report Header"."No." WHERE("VAT Report Config. Code" = CONST("VAT Return"),
                                                                                                "No." = FIELD("VAT Return No."));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                DrillDownVATReturn;
            end;
        }
        field(21; "VAT Return Status"; Option)
        {
            CalcFormula = Lookup ("VAT Report Header".Status WHERE("VAT Report Config. Code" = CONST("VAT Return"),
                                                                   "No." = FIELD("VAT Return No.")));
            Caption = 'VAT Return Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Released,Submitted,Accepted,Closed,Rejected,Canceled';
            OptionMembers = Open,Released,Submitted,Accepted,Closed,Rejected,Canceled;
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
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        if VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", "VAT Return No.") then
            Error(DeleteExistingVATRetErr);
    end;

    trigger OnInsert()
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if "No." = '' then
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", WorkDate, "No.", "No. Series");
    end;

    var
        DeleteExistingVATRetErr: Label 'You cannot delete a VAT return period that has a linked VAT return.';
        OverdueTxt: Label 'Your VAT return is overdue since %1 (%2 days)', Comment = '%1 - date; %2 - days count';
        OpenTxt: Label 'Your VAT return is due %1 (in %2 days)', Comment = '%1 - date; %2 - days count';
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupGot: Boolean;

    local procedure GetNoSeriesCode(): Code[20]
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("VAT Return Period No. Series");
        exit(VATReportSetup."VAT Return Period No. Series");
    end;

    [Scope('OnPrem')]
    procedure CopyToVATReturn(var VATReportHeader: Record "VAT Report Header")
    begin
        TestField("Start Date");
        TestField("End Date");
        VATReportHeader."Return Period No." := "No.";
        VATReportHeader."Period Year" := Date2DMY("End Date", 3);
        VATReportHeader."Start Date" := "Start Date";
        VATReportHeader."End Date" := "End Date";
        ParseDatePeriod(VATReportHeader);
    end;

    local procedure ParseDatePeriod(var VATReportHeader: Record "VAT Report Header")
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Start", VATReportHeader."Start Date");
        Date.SetRange("Period End", ClosingDate(VATReportHeader."End Date"));
        if Date.FindFirst then begin
            case Date."Period Type" of
                Date."Period Type"::Month:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
                Date."Period Type"::Quarter:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Quarter;
                Date."Period Type"::Year:
                    VATReportHeader."Period Type" := VATReportHeader."Period Type"::Year;
            end;
            VATReportHeader."Period No." := Date."Period No.";
        end else begin
            VATReportHeader."Period Type" := VATReportHeader."Period Type"::" ";
            VATReportHeader."Period No." := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"; StartDate: Date; EndDate: Date): Boolean
    begin
        VATReturnPeriod.SetRange("Start Date", StartDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        exit(VATReturnPeriod.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure DiffersFromVATReturnPeriod(var VATReturnPeriod: Record "VAT Return Period"): Boolean
    begin
        exit(
          ("Due Date" <> VATReturnPeriod."Due Date") or
          (Status <> VATReturnPeriod.Status) or
          ("Received Date" <> VATReturnPeriod."Received Date") or
          ("Period Key" <> VATReturnPeriod."Period Key"));
    end;

    [Scope('OnPrem')]
    procedure DrillDownVATReturn()
    var
        VATReportMgt: Codeunit "VAT Report Mgt.";
    begin
        if (Status = Status::Open) or ("VAT Return No." <> '') then
            VATReportMgt.OpenVATReturnCardFromVATPeriod(Rec);
    end;

    local procedure GetVATReportSetup()
    begin
        if VATReportSetupGot then
            exit;

        VATReportSetup.Get();
        VATReportSetupGot := true;
    end;

    [Scope('OnPrem')]
    procedure CheckOpenOrOverdue(): Text
    begin
        GetVATReportSetup;
        if (Status = Status::Open) and ("Due Date" <> 0D) then
            case true of
                // Overdue
                ("Due Date" < WorkDate):
                    exit(StrSubstNo(OverdueTxt, "Due Date", WorkDate - "Due Date"));
                    // Open
                VATReportSetup.IsPeriodReminderCalculation and
              ("Due Date" >= WorkDate) and
              ("Due Date" <= CalcDate(VATReportSetup."Period Reminder Calculation", WorkDate)):
                    exit(StrSubstNo(OpenTxt, "Due Date", "Due Date" - WorkDate));
            end;
    end;
}

