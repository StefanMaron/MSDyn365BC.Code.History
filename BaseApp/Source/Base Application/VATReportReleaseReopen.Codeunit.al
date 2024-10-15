codeunit 741 "VAT Report Release/Reopen"
{

    trigger OnRun()
    begin
    end;

    procedure Release(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        ErrorMessage: Record "Error Message";
        IsValidated: Boolean;
    begin
        VATReportHeader.CheckIfCanBeReleased(VATReportHeader);

        ErrorMessage.SetContext(VATReportHeader);
        ErrorMessage.ClearLog;

        IsValidated := false;
        OnBeforeValidate(VATReportHeader, IsValidated);
        if not IsValidated then begin
            VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
            if VATReportsConfiguration.FindFirst and (VATReportsConfiguration."Validate Codeunit ID" <> 0) then
                CODEUNIT.Run(VATReportsConfiguration."Validate Codeunit ID", VATReportHeader)
            else
                CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);
        end;

        if ErrorMessage.HasErrors(false) then
            exit;

        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify;
    end;

    procedure Reopen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.CheckIfCanBeReopened(VATReportHeader);

        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Modify;
    end;

    procedure Submit(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportHeader.CheckIfCanBeSubmitted;

        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        VATReportHeader.Modify;

        UpdateLinesToCorrect(VATReportHeader."No.");

        with VATReportLine do begin
            SetRange("VAT Report No.", VATReportHeader."No.");
            SetFilter("Line Type", '%1|%2', "Line Type"::New, "Line Type"::Correction);
            ModifyAll("Able to Correct Line", true, false);
        end;
    end;

    local procedure UpdateLinesToCorrect(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CorrVATReportLine: Record "VAT Report Line";
    begin
        VATReportHeader.Get(VATReportNo);

        if VATReportHeader."Original Report No." <> '' then begin
            CorrVATReportLine.SetRange("VAT Report No.", VATReportNo);
            CorrVATReportLine.SetRange("Line Type", CorrVATReportLine."Line Type"::Correction);
            if CorrVATReportLine.FindSet then
                repeat
                    VATReportLine.Reset;
                    VATReportLine.SetRange("VAT Report to Correct", VATReportHeader."Original Report No.");
                    VATReportLine.SetRange("Related Line No.", CorrVATReportLine."Related Line No.");
                    VATReportLine.SetRange("Able to Correct Line", true);
                    VATReportLine.ModifyAll("Able to Correct Line", false, false);

                    VATReportLine.Reset;
                    VATReportLine.SetRange("VAT Report No.", VATReportHeader."Original Report No.");
                    VATReportLine.SetRange("Line No.", CorrVATReportLine."Related Line No.");
                    VATReportLine.SetRange("Able to Correct Line", true);
                    VATReportLine.ModifyAll("Able to Correct Line", false, false);
                until CorrVATReportLine.Next = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidate(var VATReportHeader: Record "VAT Report Header"; var IsValidated: Boolean)
    begin
    end;
}

