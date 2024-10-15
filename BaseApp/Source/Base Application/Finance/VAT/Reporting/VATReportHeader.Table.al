// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;

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
            OptionCaption = ' ,VIES';
            OptionMembers = " ",VIES;
            TableRelation = "VAT Reports Configuration"."VAT Report Type";

            trigger OnValidate()
            begin
                CheckEditingAllowed();
            end;
        }
        field(3; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
            OptionCaption = 'Standard,Corrective';
            OptionMembers = Standard,Corrective;

            trigger OnValidate()
            begin
                CheckEditingAllowed();
                CheckIfFilterCanBeChanged();

                if "VAT Report Type" = "VAT Report Type"::Standard then
                    "Original Report No." := '';
            end;
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Original Report No.", '');
                CheckEditingAllowed();
            end;
        }
        field(5; "End Date"; Date)
        {
            Caption = 'End Date';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Original Report No.", '');
                CheckEditingAllowed();
                CheckEndDate();
                if "End Date" <> xRec."End Date" then
                    Validate("Processing Date", "End Date");
            end;
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Exported,Submitted';
            OptionMembers = Open,Released,Exported,Submitted;
        }
        field(7; "VAT Registration No."; Code[20])
        {
            Caption = 'VAT Registration No.';
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
            TableRelation = "VAT Report Header"."No." where("VAT Report Type" = const(Standard),
                                                             Status = const(Submitted));

            trigger OnLookup()
            var
                LookupVATReportHeader: Record "VAT Report Header";
                VATReportList: Page "VAT Report List";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupOriginalReportNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                LookupVATReportHeader.SetFilter("No.", '<>' + "No.");
                LookupVATReportHeader.SetRange(Status, Status::Submitted);
                LookupVATReportHeader.SetRange("VAT Report Type", "VAT Report Type"::Standard);
                VATReportList.SetTableView(LookupVATReportHeader);
                VATReportList.LookupMode(true);
                if VATReportList.RunModal() = ACTION::LookupOK then begin
                    VATReportList.GetRecord(LookupVATReportHeader);
                    Validate("Original Report No.", LookupVATReportHeader."No.");
                end;
            end;

            trigger OnValidate()
            var
                VATReportHeader: Record "VAT Report Header";
            begin
                CheckEditingAllowed();
                CheckIfFilterCanBeChanged();

                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        if "Original Report No." <> '' then
                            Error(Text006, "VAT Report Type");
                    "VAT Report Type"::Corrective:
                        begin
                            TestField("Original Report No.");
                            CheckOriginalReport("Original Report No.");
                            if "Original Report No." = "No." then
                                Error(Text005);
                            VATReportHeader.Get("Original Report No.");
                            VATReportHeader.TestField(Status, Status::Submitted);
                            "Start Date" := VATReportHeader."Start Date";
                            "End Date" := VATReportHeader."End Date";
                            "Report Period Type" := VATReportHeader."Report Period Type";
                            "Report Period No." := VATReportHeader."Report Period No.";
                            "Report Year" := VATReportHeader."Report Year";
                            "Trade Type" := VATReportHeader."Trade Type";
                            "EU Goods/Services" := VATReportHeader."EU Goods/Services";
                        end;
                end;
            end;
        }
        field(10; "Report Period Type"; Option)
        {
            Caption = 'Report Period Type';
            OptionCaption = ' ,Month,Quarter,Year,Bi-Monthly';
            OptionMembers = " ",Month,Quarter,Year,"Bi-Monthly";

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                if "Report Period Type" <> xRec."Report Period Type" then begin
                    if LineExists() then
                        Error(Text010, FieldCaption("Report Period No."));
                    SetPeriod();
                end;
            end;
        }
        field(11; "Report Period No."; Integer)
        {
            Caption = 'Report Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                TestField("Report Period Type");
                if "Report Period No." <> xRec."Report Period No." then begin
                    if LineExists() then
                        Error(Text010, FieldCaption("Report Period No."));
                    SetPeriod();
                end;
            end;
        }
        field(12; "Report Year"; Integer)
        {
            Caption = 'Report Year';
            MinValue = 2000;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Original Report No.", '');
                if "Report Year" <> xRec."Report Year" then begin
                    if LineExists() then
                        Error(Text010, FieldCaption("Report Year"));
                    SetPeriod();
                end;
            end;
        }
        field(16; "Processing Date"; Date)
        {
            Caption = 'Processing Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                if "Processing Date" < "End Date" then
                    Error(Text003, FieldCaption("Processing Date"), FieldCaption("End Date"));

                case true of
                    Date2DWY("Processing Date", 1) = 6:
                        "Processing Date" := CalcDate('<+2D>', "Processing Date");
                    Date2DWY("Processing Date", 1) = 7:
                        "Processing Date" := CalcDate('<+1D>', "Processing Date");
                end;
            end;
        }
        field(19; "Test Export"; Boolean)
        {
            Caption = 'Test Export';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(20; Notice; Boolean)
        {
            Caption = 'Notice';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(21; Revocation; Boolean)
        {
            Caption = 'Revocation';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(22; "Date Type"; Enum "VAT Date Type")
        {
            Caption = 'Date Type';
            ObsoleteReason = 'Selected VAT Date type no longer supported';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(28; "Trade Type"; Option)
        {
            Caption = 'Trade Type';
            InitValue = Sales;
            OptionCaption = 'Purchases,Sales,Both';
            OptionMembers = Purchases,Sales,Both;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                CheckIfFilterCanBeChanged();
            end;
        }
        field(29; "EU Goods/Services"; Option)
        {
            Caption = 'EU Goods/Services';
            OptionCaption = 'Both,Goods,Services';
            OptionMembers = Both,Goods,Services;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                CheckIfFilterCanBeChanged();
            end;
        }
        field(31; "Total Base"; Decimal)
        {
            CalcFormula = sum("VAT Report Line".Base where("VAT Report No." = field("No."),
                                                            "Line Type" = filter(New | Correction)));
            Caption = 'Total Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Total Amount"; Decimal)
        {
            CalcFormula = sum("VAT Report Line".Amount where("VAT Report No." = field("No."),
                                                              "Line Type" = filter(New | Correction)));
            Caption = 'Total Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Total Number of Supplies"; Decimal)
        {
            CalcFormula = sum("VAT Report Line"."Number of Supplies" where("VAT Report No." = field("No."),
                                                                            "Line Type" = filter(New | Correction)));
            Caption = 'Total Number of Supplies';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "Total Number of Lines"; Integer)
        {
            CalcFormula = count("VAT Report Line" where("VAT Report No." = field("No."),
                                                         "Line Type" = filter(New | Correction)));
            Caption = 'Total Number of Lines';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Company Name"; Text[100])
        {
            Caption = 'Company Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(41; "Company Address"; Text[30])
        {
            Caption = 'Company Address';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(42; "Country/Region Name"; Text[30])
        {
            Caption = 'Country/Region Name';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(48; City; Text[30])
        {
            Caption = 'City';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(49; "Post Code"; Code[20])
        {
            Caption = 'Post Code';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(50; "Tax Office ID"; Code[20])
        {
            Caption = 'Tax Office ID';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(51; "Sign-off Place"; Text[30])
        {
            Caption = 'Sign-off Place';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(52; "Sign-off Date"; Date)
        {
            Caption = 'Sign-off Date';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(53; "Signed by Employee No."; Code[20])
        {
            Caption = 'Signed by Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(54; "Created by Employee No."; Code[20])
        {
            Caption = 'Created by Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
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
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Report Config. Code")
        {
        }
        key(Key3; "VAT Report Type", Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATReportLine: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        TestField(Status, Status::Open);
        VATReportLine.SetRange("VAT Report No.", "No.");
        VATReportLine.DeleteAll();
        VATReportLineRelation.SetRange("VAT Report No.", "No.");
        VATReportLineRelation.DeleteAll();
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
        CheckEditingAllowed();
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
        Text003: Label 'The %1 cannot be earlier than the %2.';
#pragma warning restore AA0470
        Text004: Label 'You cannot rename the report because it has been assigned a report number.';
        Text005: Label 'You cannot specify the same report as the reference report.';
#pragma warning disable AA0470
        Text006: Label 'You cannot specify an original report for a report of type %1.';
        Text007: Label 'This is not allowed because of the setup in the %1 window.';
        Text008: Label 'You must specify an original report for a report of type %1.';
        Text010: Label 'You cannot change %1 because you already have declaration lines.';
        Text011: Label 'The field %1 can take values from 1 to %2.';
        Text012: Label 'Deletion is not allowed because the report is marked as %1.';
        ReportTypeChangeErr: Label 'You cannot change this field when the report has existing VAT Report lines.';
#pragma warning restore AA0470
#pragma warning restore AA0074

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
        "VAT Report Config. Code" := "VAT Report Config. Code"::VIES;
        "Report Period Type" := "Report Period Type"::Month;
        "Report Period No." := Date2DMY(WorkDate(), 2);
        Validate("Report Year", Date2DMY(WorkDate(), 3));

        FillCompanyInfo();

        OnAfterInitRecord(Rec);
    end;

    procedure CheckEditingAllowed()
    begin
        VATReportSetup.Get();
        if (not VATReportSetup."Modify Submitted Reports") and (Status <> Status::Open) then
            Error(Text002, Format(Status));
    end;

    [Scope('OnPrem')]
    procedure CheckDeleteAllowed()
    begin
        if Status <> Status::Open then
            Error(Text012, Format(Status));
    end;

    [Scope('OnPrem')]
    procedure CheckIfFilterCanBeChanged()
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", "No.");
        if VATReportLine.Count <> 0 then
            Error(ReportTypeChangeErr);
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
            Error(Text003, "End Date", "Start Date");
    end;

    procedure CheckIfCanBeSubmitted()
    begin
        TestField(Status, Status::Exported);
    end;

    procedure CheckIfCanBeReopened(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Submitted:
                begin
                    VATReportSetup.Get();
                    if not VATReportSetup."Modify Submitted Reports" then
                        Error(Text007, VATReportSetup.TableCaption());
                end
        end;
    end;

    procedure CheckIfCanBeReleased(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if VATReportHeader."VAT Report Type" in ["VAT Report Type"::Corrective] then
            if VATReportHeader."Original Report No." = '' then
                Error(Text008, Format(VATReportHeader."VAT Report Type"));
    end;

    local procedure CheckPeriodNo()
    var
        MaxPeriodNo: Integer;
    begin
        case "Report Period Type" of
            "Report Period Type"::Month:
                MaxPeriodNo := 12;
            "Report Period Type"::Quarter,
          "Report Period Type"::"Bi-Monthly":
                MaxPeriodNo := 4;
            "Report Period Type"::Year:
                MaxPeriodNo := 1;
        end;
        if not ("Report Period No." in [1 .. MaxPeriodNo]) then
            Error(Text011, FieldCaption("Report Period No."), MaxPeriodNo);
    end;

    local procedure SetPeriod()
    begin
        if "Report Period No." <> 0 then
            CheckPeriodNo();
        if "Report Period Type" = "Report Period Type"::Year then
            "Report Period No." := 1;

        if ("Report Period No." = 0) or ("Report Year" = 0) then begin
            Validate("Start Date", 0D);
            Validate("End Date", 0D);
        end else
            case "Report Period Type" of
                "Report Period Type"::Month:
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No.", "Report Year"));
                        Validate("End Date", CalcDate('<CM>', "Start Date"));
                    end;
                "Report Period Type"::Quarter:
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No." * 3 - 2, "Report Year"));
                        Validate("End Date", CalcDate('<CQ>', "Start Date"));
                    end;
                "Report Period Type"::Year:
                    begin
                        Validate("Start Date", DMY2Date(1, 1, "Report Year"));
                        Validate("End Date", DMY2Date(31, 12, "Report Year"));
                    end;
                "Report Period Type"::"Bi-Monthly":
                    begin
                        Validate("Start Date", DMY2Date(1, "Report Period No." * 3 - 2, "Report Year"));
                        Validate("End Date", CalcDate('<CM + 1M>', "Start Date"));
                    end;
            end;
        CheckPeriod();
    end;

    local procedure CheckPeriod()
    begin
        if ("Start Date" = 0D) or ("End Date" = 0D) then
            exit;

        CheckEndDate();
    end;

    [Scope('OnPrem')]
    procedure LineExists(): Boolean
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.Reset();
        VATReportLine.SetRange("VAT Report No.", "No.");
        exit(not VATReportLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure FillCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        VATReportSetup: Record "VAT Report Setup";
    begin
        CompanyInfo.Get();
        VATReportSetup.Get();
        CompanyInfo.TestField("Country/Region Code");

        CountryRegion.Get(CompanyInfo."Country/Region Code");

        Validate("VAT Registration No.", CompanyInfo."VAT Registration No.");
        Validate("Company Name", GetCompanyName(CompanyInfo, VATReportSetup));
        Validate("Company Address", GetCompanyAddress(CompanyInfo, VATReportSetup));
        Validate("Country/Region Name", CountryRegion.Name);
        Validate(City, GetCompanyCity(CompanyInfo, VATReportSetup));
        Validate("Post Code", CompanyInfo."Post Code");
        Validate("Tax Office ID", CompanyInfo."Tax Office Number");
    end;

    [Scope('OnPrem')]
    procedure CheckOriginalReport(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.Get(VATReportNo);
        VATReportHeader.TestField("VAT Report Type", VATReportHeader."VAT Report Type"::Standard);
        VATReportHeader.TestField(Status, VATReportHeader.Status::Submitted);
    end;

    local procedure GetCompanyName(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[100]
    begin
        if VATReportSetup."Company Name" <> '' then
            exit(VATReportSetup."Company Name");

        exit(CompanyInformation.Name);
    end;

    local procedure GetCompanyAddress(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[30]
    begin
        if VATReportSetup."Company Address" <> '' then
            exit(VATReportSetup."Company Address");

        exit(CompanyInformation.Address);
    end;

    local procedure GetCompanyCity(CompanyInformation: Record "Company Information"; VATReportSetup: Record "VAT Report Setup"): Text[30]
    begin
        if VATReportSetup."Company City" <> '' then
            exit(VATReportSetup."Company City");

        exit(CompanyInformation.City);
    end;

    local procedure RemoveECSLLinesAndRelation()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        if "VAT Report Config. Code" <> "VAT Report Config. Code"::VIES then
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
}

