table 740 "VAT Report Header"
{
    Caption = 'VAT Report Header';
    LookupPageID = "VAT Report List";

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
        field(2; "VAT Report Config. Code"; Option)
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            OptionCaption = 'EC Sales List,VAT Return';
            OptionMembers = "EC Sales List","VAT Return";
            TableRelation = "VAT Reports Configuration"."VAT Report Type";

            trigger OnValidate()
            begin
                CheckEditingAllowed;
            end;
        }
        field(3; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
            OptionCaption = 'Standard,Corrective,Supplementary';
            OptionMembers = Standard,Corrective,Supplementary;

            trigger OnValidate()
            begin
                CheckEditingAllowed;

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        "Original Report No." := '';
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        begin
                            VATReportSetup.Get();
                            if VATReportSetup."Modify Submitted Reports" then
                                Error(Text001, VATReportSetup.FieldCaption("Modify Submitted Reports"), VATReportSetup.TableCaption);
                        end;
                end;
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed;
                TestField("Start Date");
                HandleDateInput;
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed;
                TestField("End Date");
                CheckEndDate;
                HandleDateInput;
            end;
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Submitted,Accepted,Closed,Rejected,Canceled';
            OptionMembers = Open,Released,Submitted,Accepted,Closed,Rejected,Canceled;
        }
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';

            trigger OnValidate()
            begin
                CheckEditingAllowed;
            end;
        }
        field(9; "Original Report No."; Code[20])
        {
            Caption = 'Original Report No.';

            trigger OnLookup()
            var
                LookupVATReportHeader: Record "VAT Report Header";
                VATReportList: Page "VAT Report List";
                ShowLookup: Boolean;
                TypeFilterText: Text[1024];
            begin
                TypeFilterText := '';
                ShowLookup := false;

                case "VAT Report Type" of
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        ShowLookup := true;
                end;

                if ShowLookup then begin
                    LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                    LookupVATReportHeader.SetRange(Status, Status::Accepted);
                    LookupVATReportHeader.SetFilter("VAT Report Type", TypeFilterText);
                    VATReportList.SetTableView(LookupVATReportHeader);
                    VATReportList.LookupMode(true);
                    if VATReportList.RunModal = ACTION::LookupOK then begin
                        VATReportList.GetRecord(LookupVATReportHeader);
                        Validate("Original Report No.", LookupVATReportHeader."No.");
                    end;
                end;
            end;

            trigger OnValidate()
            var
                VATReportHeader: Record "VAT Report Header";
            begin
                CheckEditingAllowed;

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        begin
                            if "Original Report No." <> '' then
                                Error(Text006, "VAT Report Type");
                        end;
                    "VAT Report Type"::Corrective, "VAT Report Type"::Supplementary:
                        begin
                            TestField("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(Text005);
                            VATReportHeader.Get("VAT Report Config. Code", "Original Report No.");
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                        end;
                end;
            end;
        }
        field(10; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = ' ,,Month,Quarter,Year';
            OptionMembers = " ",,Month,Quarter,Year;

            trigger OnValidate()
            begin
                if "Period Type" = "Period Type"::Year then
                    "Period No." := 1;

                HandlePeriodInput;
            end;
        }
        field(11; "Period No."; Integer)
        {
            Caption = 'Period No.';
            TableRelation = "Date Lookup Buffer"."Period No." WHERE("Period Type" = FIELD("Period Type"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                HandlePeriodInput;
            end;
        }
        field(12; "Period Year"; Integer)
        {
            Caption = 'Period Year';

            trigger OnValidate()
            begin
                HandlePeriodInput;
            end;
        }
        field(13; "Message Id"; Text[250])
        {
            Caption = 'Message Id';
        }
        field(14; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        field(15; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            TableRelation = "VAT Statement Name".Name WHERE("Statement Template Name" = FIELD("Statement Template Name"));
        }
        field(16; "VAT Report Version"; Code[10])
        {
            Caption = 'VAT Report Version';
            TableRelation = "VAT Reports Configuration"."VAT Report Version" WHERE("VAT Report Type" = FIELD("VAT Report Config. Code"));
        }
        field(17; "Submitted By"; Guid)
        {
            Caption = 'Submitted By';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = User."User Security ID";
        }
        field(18; "Submitted Date"; Date)
        {
            Caption = 'Submitted Date';
        }
        field(19; "Return Period No."; Code[20])
        {
            Caption = 'Return Period No.';
        }
        field(30; "Additional Information"; Code[50])
        {
            Caption = 'Additional Information';
        }
        field(31; "Created Date-Time"; DateTime)
        {
            Editable = false;
            Caption = 'Created Date-Time';
        }
        field(100; "Amounts in Add. Rep. Currency"; Boolean)
        {
            Caption = 'Amounts in Add. Rep. Currency';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Report Config. Code", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        TestField(Status, Status::Open);
        VATStatementReportLine.SetRange("VAT Report No.", "No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
        VATStatementReportLine.DeleteAll();
        VATReportLineRelation.SetRange("VAT Report No.", "No.");
        VATReportLineRelation.DeleteAll();
        RemoveVATReturnPeriodLink;
        RemoveECSLLinesAndRelation;
    end;

    trigger OnInsert()
    begin
        if "No." = '' then
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", WorkDate, "No.", "No. Series");

        InitRecord;
    end;

    trigger OnModify()
    begin
        CheckDates;
    end;

    trigger OnRename()
    begin
        Error(Text004);
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        Text001: Label 'The value of %1 field in the %2 window does not allow this option.';
        Text002: Label 'Editing is not allowed because the report is marked as %1.';
        Text003: Label 'The end date cannot be earlier than the start date.';
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text004: Label 'You cannot rename the report because it has been assigned a report number.';
        Text005: Label 'You cannot specify the same report as the reference report.';
        Text006: Label 'You cannot specify an original report for a report of type %1.';
        Text007: Label 'This is not allowed because of the setup in the %1 window.';
        Text008: Label 'You must specify an original report for a report of type %1.';

    procedure GetNoSeriesCode(): Code[20]
    begin
        VATReportSetup.Get();
        if "VAT Report Config. Code" = "VAT Report Config. Code"::"VAT Return" then begin
            VATReportSetup.TestField("VAT Return No. Series");
            exit(VATReportSetup."VAT Return No. Series");
        end;

        VATReportSetup.TestField("No. Series");
        exit(VATReportSetup."No. Series");
    end;

    procedure AssistEdit(OldVATReportHeader: Record "VAT Report Header"): Boolean
    begin
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldVATReportHeader."No. Series", "No. Series") then begin
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    procedure InitRecord()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        date: Date;
    begin
        if ("VAT Report Config. Code" = "VAT Report Config. Code"::"EC Sales List") or
           ("VAT Report Config. Code" = "VAT Report Config. Code"::"VAT Return")
        then begin
            date := CalcDate('<-1M>', WorkDate);
            Validate("Period Year", Date2DMY(date, 3));
            Validate("Period Type", "Period Type"::Month);
            Validate("Period No.", Date2DMY(date, 2));
        end else begin
            "Start Date" := WorkDate;
            "End Date" := WorkDate;
        end;

        VATReportsConfiguration.SetRange("VAT Report Type", "VAT Report Config. Code");
        if VATReportsConfiguration.FindFirst and (VATReportsConfiguration.Count = 1) then
            "VAT Report Version" := VATReportsConfiguration."VAT Report Version";
    end;

    procedure CheckEditingAllowed()
    begin
        if Status <> Status::Open then
            Error(Text002, Format(Status));
    end;

    procedure CheckDates()
    begin
        TestField("Start Date");
        TestField("End Date");
        CheckEndDate;
    end;

    procedure CheckEndDate()
    begin
        if "End Date" < "Start Date" then
            Error(Text003);
    end;

    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Released);
    end;

    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status <> VATReportHeader.Status::Released then
            if VATReportSetup.Get then
                if not VATReportSetup."Modify Submitted Reports" then
                    Error(Text007, VATReportSetup.TableCaption);
    end;

    procedure CheckIfCanBeReleased(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if VATReportHeader."VAT Report Type" in ["VAT Report Type"::Corrective, "VAT Report Type"::Supplementary] then
            if VATReportHeader."Original Report No." = '' then
                Error(Text008, Format(VATReportHeader."VAT Report Type"));
    end;

    procedure PeriodToDate()
    begin
        if not IsPeriodValid then
            exit;

        if "Period Type" = "Period Type"::Month then begin
            "Start Date" := DMY2Date(1, "Period No.", "Period Year");
            "End Date" := CalcDate('<1M-1D>', "Start Date");
        end;

        if "Period Type" = "Period Type"::Quarter then begin
            "Start Date" := DMY2Date(1, 1 + ("Period No." - 1) * 3, "Period Year");
            "End Date" := CalcDate('<+3M-1D>', "Start Date");
        end;

        if "Period Type" = "Period Type"::Year then begin
            "Start Date" := DMY2Date(1, 1, "Period Year");
            "End Date" := DMY2Date(31, 12, "Period Year");
        end;
    end;

    local procedure HandleDateInput()
    begin
        Clear("Period No.");
        Clear("Period Type");
        Clear("Period Year");
    end;

    local procedure HandlePeriodInput()
    begin
        Clear("Start Date");
        Clear("End Date");

        if not IsPeriodValid then
            exit;

        PeriodToDate;
    end;

    procedure IsPeriodValid(): Boolean
    begin
        if ("Period Year" = 0) or ("Period Type" = "Period Type"::" ") or ("Period No." = 0) then
            exit(false);

        if ("Period Type" = "Period Type"::Quarter) and
           (("Period No." < 1) or ("Period No." > 4))
        then
            exit(false);

        if ("Period Type" = "Period Type"::Month) and
           (("Period No." < 1) or ("Period No." > 12))
        then
            exit(false);

        exit(true);
    end;

    local procedure RemoveVATReturnPeriodLink()
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        if "Return Period No." <> '' then
            if VATReturnPeriod.Get("Return Period No.") then begin
                VATReturnPeriod.Validate("VAT Return No.", '');
                VATReturnPeriod.Modify(true);
            end;
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::"EC Sales List" then
            exit;

        ECSLVATReportLineRelation.SetRange("ECSL Report No.", "No.");
        if not ECSLVATReportLineRelation.IsEmpty then
            ECSLVATReportLineRelation.DeleteAll(true);

        ECSLVATReportLine.SetRange("Report No.", "No.");
        if not ECSLVATReportLine.IsEmpty then
            ECSLVATReportLine.DeleteAll(true);
    end;
}

