namespace Microsoft.FixedAssets.Reports;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5608 "Fixed Asset - Acquisition List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Reports/FixedAssetAcquisitionList.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Acquisition List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(DeprBookText; DeprBookText)
            {
            }
            column(FixAssetTableCaptFaFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(No_FixedAsset; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_FixedAsset; Description)
            {
                IncludeCaption = true;
            }
            column(LocCode_FixedAsset; "FA Location Code")
            {
                IncludeCaption = true;
            }
            column(RespEmp_FixedAsset; "Responsible Employee")
            {
                IncludeCaption = true;
            }
            column(SerialNo_FixedAsset; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(FaDeprBookAcquDate; Format(FADeprBook."Acquisition Date"))
            {
            }
            column(FixedAssetAcqListCptn; FixedAssetAcqListCptnLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(FADeprBkAcquisitionDtCptn; FADeprBkAcquisitionDtCptnLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Clear(FADeprBook);
                PrintFA := false;
                if not FADeprBook.Get("No.", DeprBookCode) then begin
                    if FAWithoutAcqDate then
                        PrintFA := true;
                end else
                    if FADeprBook."Acquisition Date" = 0D then begin
                        if FAWithoutAcqDate then
                            PrintFA := true;
                    end else
                        PrintFA := (FADeprBook."Acquisition Date" >= StartingDate) and
                          (FADeprBook."Acquisition Date" <= EndingDate);
                if not PrintFA then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DeprBookCode; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    group("Acquisition Period")
                    {
                        Caption = 'Acquisition Period';
                        field(StartingDate; StartingDate)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date when you want the report to start.';
                        }
                        field(EndingDate; EndingDate)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the date when you want the report to end.';
                        }
                    }
                    field(FAWithoutAcqDate; FAWithoutAcqDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Include Fixed Assets Not Yet Acquired';
                        ToolTip = 'Specifies if you want to include a fixed asset for which the first acquisition cost has not yet been posted.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FAGenReport.AppendFAPostingFilter("Fixed Asset", StartingDate, EndingDate);
        FAFilter := "Fixed Asset".GetFilters();
        DeprBookText := StrSubstNo('%1%2 %3', DeprBook.TableCaption(), ':', DeprBookCode);
        ValidateDates(StartingDate, EndingDate);
        FAGenReport.ValidateDates(StartingDate, EndingDate);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAGenReport: Codeunit "FA General Report";
        DeprBookCode: Code[10];
        DeprBookText: Text[50];
        FAFilter: Text;
        StartingDate: Date;
        EndingDate: Date;
        FAWithoutAcqDate: Boolean;
        PrintFA: Boolean;
        Text001: Label 'You must specify a Starting Date.';
        Text002: Label 'You must specify an Ending Date.';
        Text003: Label 'You must specify an Ending Date that is later than the Starting Date.';
        FixedAssetAcqListCptnLbl: Label 'Fixed Asset - Acquisition List';
        CurrReportPageNoCaptionLbl: Label 'Page';
        FADeprBkAcquisitionDtCptnLbl: Label 'Acquisition Date';

    local procedure ValidateDates(StartingDate: Date; EndingDate: Date)
    begin
        if StartingDate = 0D then
            Error(Text001);

        if EndingDate = 0D then
            Error(Text002);

        if StartingDate > EndingDate then
            Error(Text003);
    end;
}

