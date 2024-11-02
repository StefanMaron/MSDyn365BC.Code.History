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

        VATReportHeader.TestField("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::VIES);
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        REPORT.RunModal(REPORT::"VAT Report Suggest Lines", true, false, VATReportHeader);
    end;

    [Scope('OnPrem')]
    procedure CorrectLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLines: Page "VAT Report Lines";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestField("VAT Report Type", VATReportHeader."VAT Report Type"::Corrective);
        VATReportHeader.TestField("Original Report No.");
        VATReportHeader.TestField("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::VIES);

        VATReportLines.SetToDeclaration(VATReportHeader);
        VATReportLines.LookupMode := true;
        if VATReportLines.RunModal() = ACTION::LookupOK then
            VATReportLines.CopyLineToDeclaration();
        Clear(VATReportLines);
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
            VATReportHeader.Status::Exported:
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
            PrintReleased(VATReportHeader);
        end
    end;

    local procedure PrintReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        REPORT.RunModal(REPORT::"VAT Report Print", false, false, VATReportHeader);
    end;

    procedure Submit(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Submit(VATReportHeader);
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

