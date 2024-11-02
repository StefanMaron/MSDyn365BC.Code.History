// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 740 "VAT Report Mediator"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
#pragma warning disable AA0074
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';
#pragma warning restore AA0074

    procedure GetLines(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();

        VATReportHeader.TestField("VAT Report Config. Code");

        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        if VATReportHeader.isDatifattura() then
            Report.RunModal(Report::"Datifattura Suggest Lines", ShowRequestPage(VATReportHeader), false, VATReportHeader)
        else
            Report.RunModal(Report::"VAT Report Suggest Lines", false, false, VATReportHeader);
    end;

    procedure Export(VATReportHeader: Record "VAT Report Header")
    var
        VATReportExport: Codeunit "VAT Report Export";
    begin
        VATReportExport.Export(VATReportHeader);
    end;

    procedure Release(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
    end;

    procedure Reopen(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Reopen(VATReportHeader);
    end;

    procedure Print(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                PrintOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                PrintReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                PrintReleased(VATReportHeader);
        end;
    end;

    local procedure PrintOpen(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            Commit();
            PrintReleased(VATReportHeader);
        end
    end;

    local procedure PrintReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        if not VATReportHeader.isDatifattura() then
            REPORT.RunModal(REPORT::"VAT Report Print", true, false, VATReportHeader);
    end;

    procedure Submit(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Submit(VATReportHeader);
    end;

    local procedure ShowRequestPage(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        exit(VATReportSetup."Filter Datifattura Lines" and VATReportHeader.isDatifattura())
    end;

    procedure GetVATReportConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
        OnGetVATReportConfigurationOnAfterVATReportsConfigurationSetFilters(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.FindFirst();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetVATReportConfigurationOnAfterVATReportsConfigurationSetFilters(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
    end;
}

