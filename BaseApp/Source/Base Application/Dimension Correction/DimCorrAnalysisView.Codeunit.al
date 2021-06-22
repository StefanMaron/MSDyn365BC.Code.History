codeunit 2584 "Dim Corr Analysis View"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        DimensionCorrection: Record "Dimension Correction";
    begin
        DimensionCorrection.Get(Rec."Record ID to Process");
        UpdateAnalysisViews(DimensionCorrection);
    end;

    procedure UpdateAnalysisViews(var DimensionCorrection: Record "Dimension Correction")
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        Session.LogMessage('0000EK8', StrSubstNo(StartingUpdateAnalysisViewsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
        DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::"In Process";
        Clear(DimensionCorrection."Update Analysis Views Error");
        DimensionCorrection.Modify();
        Commit();

        AnalysisView.SetRange(Blocked, false);
        AnalysisView.SetRange("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.SetRange("Update on Posting", true);
        if not AnalysisView.IsEmpty() then begin
            AnalysisView.FindSet();
            repeat
                if ShouldUpdateAnalysisView(AnalysisView, DimensionCorrection) then begin
                    AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                    AnalysisViewEntry.DeleteAll();
                    AnalysisView."Last Entry No." := 0;
                    AnalysisView."Last Date Updated" := 0D;
                    AnalysisView."Last Budget Entry No." := 0;
                    AnalysisView.Modify();
                    UpdateAnalysisView.Update(AnalysisView, 2, false);
                    Commit();
                end;
            until AnalysisView.Next() = 0;
        end;

        DimensionCorrection."Update Analysis Views Status" := DimensionCorrection."Update Analysis Views Status"::Completed;
        DimensionCorrection.Modify();
        Commit();

        Session.LogMessage('0000EK9', StrSubstNo(CompletedUpdateAnalysisViewsLbl, DimensionCorrection."Entry No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DimensionCorrectionTok);
    end;

    local procedure ShouldUpdateAnalysisView(var AnalysisView: Record "Analysis View"; var DimensionCorrection: Record "Dimension Correction") Result: Boolean
    var
        TempDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        if not DimensionCorrectionMgt.GetDimCorrectionChanges(DimensionCorrection."Entry No.", TempDimCorrectionChange) then
            exit(false);

        if not TempDimCorrectionChange.FindSet() then
            exit(false);

        repeat
            if AnalysisView.CheckDimensionIsTracked(TempDimCorrectionChange."Dimension Code") then
                exit(true);
        until TempDimCorrectionChange.Next() = 0;

        OnAfterShouldUpdateAnalysisView(AnalysisView, DimensionCorrection, Result);
    end;

    var
        StartingUpdateAnalysisViewsLbl: Label 'Starting Update Analysis Views, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        CompletedUpdateAnalysisViewsLbl: Label 'Completed Update Analysis Views, Dimension Correction - %1', Locked = true, Comment = '%1 - Number of Dimension Correction';
        DimensionCorrectionTok: Label 'DimensionCorrection', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldUpdateAnalysisView(var AnalysisView: Record "Analysis View"; var DimensionCorrection: Record "Dimension Correction"; var Result: Boolean)
    begin
    end;
}