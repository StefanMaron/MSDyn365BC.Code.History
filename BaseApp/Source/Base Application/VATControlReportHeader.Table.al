table 31100 "VAT Control Report Header"
{
    Caption = 'VAT Control Report Header';
    DrillDownPageID = "VAT Control Report List";
    LookupPageID = "VAT Control Report List";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestModifyAllowed;
            end;
        }
        field(3; "Report Period"; Option)
        {
            Caption = 'Report Period';
            OptionCaption = 'Month,Quarter';
            OptionMembers = Month,Quarter;

            trigger OnValidate()
            begin
                TestModifyAllowed;
                CheckPeriodNo;
            end;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';
            MaxValue = 12;
            MinValue = 1;

            trigger OnValidate()
            begin
                TestModifyAllowed;
                if "Period No." <> xRec."Period No." then begin
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption("Period No."));
                    SetPeriod;
                end;
            end;
        }
        field(5; Year; Integer)
        {
            Caption = 'Year';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestModifyAllowed;
                if Year <> xRec.Year then begin
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption(Year));
                    SetPeriod;
                end;
            end;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestModifyAllowed;

                if "Start Date" <> xRec."Start Date" then
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption("Start Date"));
            end;
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                TestModifyAllowed;

                if "End Date" <> xRec."End Date" then
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption("End Date"));
            end;
        }
        field(8; "Created Date"; Date)
        {
            Caption = 'Created Date';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Release';
            OptionMembers = Open,Release;
        }
        field(15; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            TableRelation = "Registration Country/Region"."Country/Region Code" WHERE("Account Type" = CONST("Company Information"),
                                                                                       "Account No." = FILTER(''));
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';

            trigger OnValidate()
            begin
                TestModifyAllowed;
            end;
        }
        field(20; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
            TableRelation = "VAT Statement Template";

            trigger OnValidate()
            begin
                TestModifyAllowed;

                if "VAT Statement Template Name" <> xRec."VAT Statement Template Name" then begin
                    "VAT Statement Name" := '';
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption("VAT Statement Template Name"));
                end;
            end;
        }
        field(21; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            TableRelation = "VAT Statement Name".Name WHERE("Statement Template Name" = FIELD("VAT Statement Template Name"));

            trigger OnValidate()
            begin
                TestModifyAllowed;

                if "VAT Statement Name" <> xRec."VAT Statement Name" then
                    if LineExists then
                        Error(ChangeNotPosibleLineExistErr, FieldCaption("VAT Statement Name"));
            end;
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(100; "Closed by Document No. Filter"; Code[20])
        {
            Caption = 'Closed by Document No. Filter';
            Editable = false;
            FieldClass = FlowFilter;
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
        TestModifyAllowed;
        TestDeleteAllowed;

        VATCtrlRptLn.Reset();
        VATCtrlRptLn.SetRange("Control Report No.", "No.");
        VATCtrlRptLn.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if "No." = '' then
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", WorkDate, "No.", "No. Series");

        InitRecord;
    end;

    trigger OnRename()
    begin
        Error(RecordRenameErr, TableCaption);
    end;

    var
        RecordRenameErr: Label 'You cannot rename a %1.', Comment = '%1=Header No.';
        VATCtrlRptLn: Record "VAT Control Report Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DateMustBeErr: Label '%1 should be earlier than %2.', Comment = '%1=fieldcaption.startingdate;%2=fieldcaption.enddate';
        ChangeNotPosibleLineExistErr: Label 'You cannot change %1 because you already have declaration lines.', Comment = '%1= Header No.';
        AllowedValuesAreErr: Label 'The permitted values for %1 are from 1 to %2.', Comment = '%1=fieldcaption.periodnumber;%2=maxperiodnumber';
        VATControlReportMgt: Codeunit VATControlReportManagement;

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        "Created Date" := WorkDate;
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(VATCtrlRptHdrOld: Record "VAT Control Report Header"): Boolean
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, VATCtrlRptHdrOld."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
    begin
        StatReportingSetup.Get();
        StatReportingSetup.TestField("VAT Control Report Nos.");
        exit(StatReportingSetup."VAT Control Report Nos.");
    end;

    local procedure CheckPeriodNo()
    var
        MaxPeriodNo: Integer;
    begin
        if "Report Period" = "Report Period"::Month then
            MaxPeriodNo := 12
        else
            MaxPeriodNo := 4;
        if not ("Period No." in [1 .. MaxPeriodNo]) then
            Error(AllowedValuesAreErr, FieldCaption("Period No."), MaxPeriodNo);
    end;

    local procedure SetPeriod()
    begin
        if "Period No." <> 0 then
            CheckPeriodNo;
        if ("Period No." = 0) or (Year = 0) then begin
            "Start Date" := 0D;
            "End Date" := 0D;
        end else
            if "Report Period" = "Report Period"::Month then begin
                "Start Date" := DMY2Date(1, "Period No.", Year);
                "End Date" := CalcDate('<CM>', "Start Date");
            end else begin
                "Start Date" := DMY2Date(1, "Period No." * 3 - 2, Year);
                "End Date" := CalcDate('<CQ>', "Start Date");
            end;
        CheckPeriod;
    end;

    local procedure CheckPeriod()
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit;

        if "Start Date" >= "End Date" then
            Error(DateMustBeErr, FieldCaption("Start Date"), FieldCaption("End Date"));
    end;

    [Scope('OnPrem')]
    procedure PrintTestReport()
    var
        VATControlReportHeader: Record "VAT Control Report Header";
    begin
        VATControlReportHeader := Rec;
        VATControlReportHeader.SetRecFilter;
        REPORT.Run(REPORT::"VAT Control Report - Test", true, false, VATControlReportHeader);
    end;

    [Scope('OnPrem')]
    procedure Export(): Text
    var
        VATControlReportHeader: Record "VAT Control Report Header";
        ExportVATControlReport: Page "Export VAT Control Report";
    begin
        TestField(Status, Status::Release);
        VATControlReportHeader := Rec;
        VATControlReportHeader.SetRecFilter;
        ExportVATControlReport.SetTableView(VATControlReportHeader);
        ExportVATControlReport.SetRecord(VATControlReportHeader);
        ExportVATControlReport.RunModal();
        exit(ExportVATControlReport.GetClientFileName());
    end;

    [Scope('OnPrem')]
    procedure CloseLines()
    begin
        VATControlReportMgt.CloseVATCtrlRepLine(Rec, '', 0D);
    end;

    local procedure LineExists(): Boolean
    begin
        VATCtrlRptLn.Reset();
        VATCtrlRptLn.SetRange("Control Report No.", "No.");
        exit(VATCtrlRptLn.FindFirst);
    end;

    local procedure TestModifyAllowed()
    begin
        TestField(Status, Status::Open);
    end;

    local procedure TestDeleteAllowed()
    begin
        VATCtrlRptLn.Reset();
        VATCtrlRptLn.SetRange("Control Report No.", "No.");
        VATCtrlRptLn.SetFilter("Closed by Document No.", '<>%1', '');
        if VATCtrlRptLn.FindFirst then
            VATCtrlRptLn.TestField("Closed by Document No.", '');
    end;

    [Scope('OnPrem')]
    procedure SuggestLines()
    var
        VATCtrlRptHdr: Record "VAT Control Report Header";
        GetVATEntries: Report "Get VAT Entries";
    begin
        TestField(Status, Status::Open);
        VATCtrlRptHdr.Get("No.");
        VATCtrlRptHdr.SetRange("No.", "No.");
        GetVATEntries.UseRequestPage(true);
        GetVATEntries.SetTableView(VATCtrlRptHdr);
        GetVATEntries.SetVATCtrlRepHeader(VATCtrlRptHdr);
        GetVATEntries.RunModal;
        Clear(GetVATEntries);
    end;
}

