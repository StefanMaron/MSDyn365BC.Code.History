// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;

table 740 "VAT Report Header"
{
    Caption = 'VAT Report Header';
    LookupPageID = "VAT Report List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "VAT Report Config. Code"; Option)
        {
            Caption = 'VAT Report Config. Code';
            Editable = true;
            OptionCaption = ' ,VAT Transactions Report,Datifattura';
            OptionMembers = " ","VAT Transactions Report",Datifattura;

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        field(3; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
            OptionCaption = 'Standard,Corrective,,,,,,,,,Cancellation ';
            OptionMembers = Standard,Corrective,,,,,,,,,"Cancellation ";

            trigger OnValidate()
            var
                VATReportLine: Record "VAT Report Line";
            begin
                CheckEditingAllowed();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        "Original Report No." := '';
                    "VAT Report Type"::"Cancellation ":
                        begin
                            VATReportLine.SetRange("VAT Report No.", "No.");
                            if not VATReportLine.IsEmpty() then
                                if Confirm(DeleteReportLinesQst) then
                                    VATReportLine.DeleteAll()
                                else
                                    Error('');
                        end;
                end;
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("Start Date");
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                TestField("End Date");
                CheckEndDate();
            end;
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Submitted';
            OptionMembers = Open,Released,Submitted;
        }
        field(8; "No. Series"; Code[20])
        {
            Caption = 'No. Series';

            trigger OnValidate()
            begin
                CheckEditingAllowed();
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
                IsHandled: Boolean;
                TypeFilterText: Text[1024];
            begin
                IsHandled := false;
                OnBeforeLookupOriginalReportNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                TypeFilterText := '';
                ShowLookup := false;

                case "VAT Report Type" of
                    "VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation ":
                        begin
                            ShowLookup := true;
                            TypeFilterText := '<>' + Format("VAT Report Type"::"Cancellation ");
                        end;
                end;

                if ShowLookup then begin
                    LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                    LookupVATReportHeader.SetRange(Status, Status::Submitted);
                    LookupVATReportHeader.SetFilter("VAT Report Type", TypeFilterText);
                    VATReportList.SetTableView(LookupVATReportHeader);
                    VATReportList.LookupMode(true);
                    if VATReportList.RunModal() = ACTION::LookupOK then begin
                        VATReportList.GetRecord(LookupVATReportHeader);
                        Validate("Original Report No.", LookupVATReportHeader."No.");
                    end;
                end;
            end;

            trigger OnValidate()
            var
                VATReportHeader: Record "VAT Report Header";
            begin
                CheckEditingAllowed();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        if "Original Report No." <> '' then
                            Error(Text006, "VAT Report Type");
                    "VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation ":
                        begin
                            TestField("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(Text005);
                            VATReportHeader.Get("Original Report No.");
                            VATReportHeader.TestField(Status, VATReportHeader.Status::Submitted);
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                        end;
                end;
            end;
        }
        field(32; "Country/Region Filter"; Text[250])
        {
            Editable = false;
            Caption = 'Country/Region Filter';
        }
        field(100; "Amounts in Add. Rep. Currency"; Boolean)
        {
            Caption = 'Amounts in Add. Rep. Currency';
            Editable = false;
        }
        field(4800; "VATGroup Return"; Boolean)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4700 VAT Group Return';
            ObsoleteTag = '18.0';
        }
        field(4801; "VATGroup Status"; Text[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4701 VAT Group Status';
            ObsoleteTag = '18.0';
        }
        field(4802; "VATGroup Settlement Posted"; Boolean)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4702 VAT Group Settlement Posted';
            ObsoleteTag = '18.0';
        }
        field(12100; "Tax Auth. Receipt No."; Code[17])
        {
            Caption = 'Tax Auth. Receipt No.';

            trigger OnValidate()
            begin
                if Status = Status::Submitted then
                    Error(Text002, Format(Status));
            end;
        }
        field(12101; "Tax Auth. Doc. No."; Code[6])
        {
            Caption = 'Tax Auth. Doc. No.';
            ObsoleteReason = 'Replaced by Tax Auth. Document No.';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
        }
        field(12102; "Tax Auth. Document No."; Code[18])
        {
            Caption = 'Tax Auth. Document No.';
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
        VATReportLine: Record "VAT Report Line";
    begin
        TestField(Status, Status::Open);
        VATReportLine.SetRange("VAT Report No.", "No.");
        VATReportLine.DeleteAll();
        RemoveECSLLinesAndRelation();
    end;

    trigger OnInsert()
#if not CLEAN24
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        DefaultNoSeriesCode: Code[20];
        IsHandled: Boolean;
#endif
    begin
        if "No." = '' then begin
#if not CLEAN24
            DefaultNoSeriesCode := GetNoSeriesCode();
            NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(DefaultNoSeriesCode, xRec."No. Series", WorkDate(), "No.", "No. Series", IsHandled);
            if not IsHandled then begin
                if NoSeries.AreRelated(DefaultNoSeriesCode, xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := DefaultNoSeriesCode;
                "No." := NoSeries.GetNextNo("No. Series");
                NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", DefaultNoSeriesCode, WorkDate(), "No.");
            end;
#else
			if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
				"No. Series" := xRec."No. Series"
			else
				"No. Series" := GetNoSeriesCode();
            "No." := NoSeries.GetNextNo("No. Series");
#endif
        end;

        InitRecord();
    end;

    trigger OnModify()
    begin
        CheckDates();
    end;

    trigger OnRename()
    begin
        Error(Text004);
    end;

    var
        VATReportSetup: Record "VAT Report Setup";
        NoSeries: Codeunit "No. Series";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Editing is not allowed because the report is marked as %1.';
        Text003: Label 'The end date cannot be earlier than the start date.';
        Text004: Label 'You cannot rename the report because it has been assigned a report number.';
        Text005: Label 'You cannot specify the same report as the reference report.';
        Text006: Label 'You cannot specify an original report for a report of type %1.';
        Text007: Label 'This is not allowed because of the setup in the %1 window.';
        Text008: Label 'You must specify an original report for a report of type %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

        DeleteReportLinesQst: Label 'All existing report lines will be deleted. Do you want to continue?';

    procedure GetNoSeriesCode() Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        VATReportSetup.Get();
        VATReportSetup.TestField("No. Series");
        exit(VATReportSetup."No. Series");
    end;

    procedure AssistEdit(OldVATReportHeader: Record "VAT Report Header"): Boolean
    begin
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldVATReportHeader."No. Series", "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            exit(true);
        end;
    end;

    procedure InitRecord()
    begin
        "VAT Report Config. Code" := "VAT Report Config. Code"::"VAT Transactions Report";
        "Start Date" := WorkDate();
        "End Date" := WorkDate();

        OnAfterInitRecord(Rec);
    end;

    procedure CheckEditingAllowed()
    begin
        if Status in [Status::Released, Status::Submitted] then
            Error(Text002, Format(Status));
    end;

    procedure CheckDates()
    begin
        TestField("Start Date");
        TestField("End Date");
        CheckEndDate();
    end;

    procedure CheckEndDate()
    begin
        if "End Date" < "Start Date" then
            Error(Text003);
    end;

    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Released);
        TestField("Tax Auth. Receipt No.");
        TestField("Tax Auth. Document No.");
    end;

    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader.Status = VATReportHeader.Status::Submitted then begin
            VATReportSetup.Get();
            if not VATReportSetup."Modify Submitted Reports" then
                Error(Text007, VATReportSetup.TableCaption());
        end;
    end;

    procedure CheckIfCanBeReleased(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();
    end;

    internal procedure TestOriginalReportNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestOriginalReportNo(Rec, IsHandled);
        if IsHandled then
            exit;

        if "VAT Report Type" in ["VAT Report Type"::Corrective, "VAT Report Type"::"Cancellation "] then
            if "Original Report No." = '' then
                Error(Text008, Format("VAT Report Type"));
    end;

    procedure IsDatifattura(): Boolean
    begin
        exit("VAT Report Config. Code" = "VAT Report Config. Code"::Datifattura);
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::"VAT Transactions Report" then
            exit;

        ECSLVATReportLineRelation.SetRange("ECSL Report No.", "No.");
        if not ECSLVATReportLineRelation.IsEmpty() then
            ECSLVATReportLineRelation.DeleteAll(true);

        ECSLVATReportLine.SetRange("Report No.", "No.");
        if not ECSLVATReportLine.IsEmpty() then
            ECSLVATReportLine.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var VATReportHeader: Record "VAT Report Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupOriginalReportNo(var VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var VATReportHeader: Record "VAT Report Header"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestOriginalReportNo(VATReportHeader: Record "VAT Report Header"; var IsHandled: Boolean)
    begin
    end;
}

