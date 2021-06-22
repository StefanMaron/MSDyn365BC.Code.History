codeunit 413 AnalysisViewEntryToGLEntries
{

    trigger OnRun()
    begin
    end;

    var
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";

    procedure GetGLEntries(var AnalysisViewEntry: Record "Analysis View Entry"; var TempGLEntry: Record "G/L Entry")
    var
        GLEntry: Record "G/L Entry";
        AnalysisViewFilter: Record "Analysis View Filter";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        AnalysisView.Get(AnalysisViewEntry."Analysis View Code");

        if AnalysisView."Date Compression" = AnalysisView."Date Compression"::None then begin
            if GLEntry.Get(AnalysisViewEntry."Entry No.") then begin
                TempGLEntry := GLEntry;
                TempGLEntry.Insert();
            end;
            exit;
        end;

        GLSetup.Get();

        StartDate := AnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        with AnalysisView do
            if StartDate < "Starting Date" then
                StartDate := 0D
            else
                if (AnalysisViewEntry."Posting Date" = NormalDate(AnalysisViewEntry."Posting Date")) and
                   not ("Date Compression" in ["Date Compression"::None, "Date Compression"::Day])
                then
                    EndDate := CalculateEndDate("Date Compression", AnalysisViewEntry);

        with GLEntry do begin
            SetCurrentKey("G/L Account No.", "Posting Date");
            SetRange("G/L Account No.", AnalysisViewEntry."Account No.");
            SetRange("Posting Date", StartDate, EndDate);
            SetRange("Entry No.", 0, AnalysisView."Last Entry No.");

            if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", AnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 1 Code", GlobalDimValue)
            else
                if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 1 Code")
                then
                    SetFilter("Global Dimension 1 Code", AnalysisViewFilter."Dimension Value Filter");

            if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", AnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 2 Code", GlobalDimValue)
            else
                if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 2 Code")
                then
                    SetFilter("Global Dimension 2 Code", AnalysisViewFilter."Dimension Value Filter");

            if Find('-') then
                repeat
                    if DimEntryOK("Dimension Set ID", AnalysisView."Dimension 1 Code", AnalysisViewEntry."Dimension 1 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 2 Code", AnalysisViewEntry."Dimension 2 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 3 Code", AnalysisViewEntry."Dimension 3 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 4 Code", AnalysisViewEntry."Dimension 4 Value Code") and
                       UpdateAnalysisView.DimSetIDInFilter("Dimension Set ID", AnalysisView)
                    then begin
                        TempGLEntry := GLEntry;
                        if TempGLEntry.Insert() then;
                    end;
                until Next = 0;
        end;
    end;

    procedure GetCFLedgEntries(var AnalysisViewEntry: Record "Analysis View Entry"; var CFForecastEntry: Record "Cash Flow Forecast Entry")
    var
        CFForecastEntry2: Record "Cash Flow Forecast Entry";
        AnalysisViewFilter: Record "Analysis View Filter";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        AnalysisView.Get(AnalysisViewEntry."Analysis View Code");

        if AnalysisView."Date Compression" = AnalysisView."Date Compression"::None then begin
            if CFForecastEntry2.Get(AnalysisViewEntry."Entry No.") then begin
                CFForecastEntry := CFForecastEntry2;
                CFForecastEntry.Insert();
            end;
            exit;
        end;

        GLSetup.Get();

        StartDate := AnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        with AnalysisView do
            if StartDate < "Starting Date" then
                StartDate := 0D
            else
                if (AnalysisViewEntry."Posting Date" = NormalDate(AnalysisViewEntry."Posting Date")) and
                   not ("Date Compression" in ["Date Compression"::None, "Date Compression"::Day])
                then
                    EndDate := CalculateEndDate("Date Compression", AnalysisViewEntry);

        with CFForecastEntry2 do begin
            SetCurrentKey("Cash Flow Forecast No.", "Cash Flow Account No.", "Source Type", "Cash Flow Date");
            SetRange("Cash Flow Forecast No.", AnalysisViewEntry."Cash Flow Forecast No.");
            SetRange("Cash Flow Account No.", AnalysisViewEntry."Account No.");
            SetRange("Cash Flow Date", StartDate, EndDate);

            if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", AnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 1 Code", GlobalDimValue)
            else
                if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 1 Code")
                then
                    SetFilter("Global Dimension 1 Code", AnalysisViewFilter."Dimension Value Filter");

            if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", AnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 2 Code", GlobalDimValue)
            else
                if AnalysisViewFilter.Get(AnalysisViewEntry."Analysis View Code", GLSetup."Global Dimension 2 Code")
                then
                    SetFilter("Global Dimension 2 Code", AnalysisViewFilter."Dimension Value Filter");

            if Find('-') then
                repeat
                    if DimEntryOK("Dimension Set ID", AnalysisView."Dimension 1 Code", AnalysisViewEntry."Dimension 1 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 2 Code", AnalysisViewEntry."Dimension 2 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 3 Code", AnalysisViewEntry."Dimension 3 Value Code") and
                       DimEntryOK("Dimension Set ID", AnalysisView."Dimension 4 Code", AnalysisViewEntry."Dimension 4 Value Code") and
                       UpdateAnalysisView.DimSetIDInFilter("Dimension Set ID", AnalysisView)
                    then begin
                        CFForecastEntry := CFForecastEntry2;
                        CFForecastEntry.Insert();
                    end;
                until Next = 0;
        end;
    end;

    local procedure DimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]): Boolean
    begin
        if Dim = '' then
            exit(true);

        if DimSetEntry.Get(DimSetID, Dim) then
            exit(DimSetEntry."Dimension Value Code" = DimValue);

        exit(DimValue = '');
    end;

    local procedure CalculateEndDate(DateCompression: Integer; AnalysisViewEntry: Record "Analysis View Entry"): Date
    var
        AnalysisView2: Record "Analysis View";
        AccountingPeriod: Record "Accounting Period";
    begin
        case DateCompression of
            AnalysisView2."Date Compression"::Week:
                exit(CalcDate('<+6D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Month:
                exit(CalcDate('<+1M-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Quarter:
                exit(CalcDate('<+3M-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Year:
                exit(CalcDate('<+1Y-1D>', AnalysisViewEntry."Posting Date"));
            AnalysisView2."Date Compression"::Period:
                begin
                    AccountingPeriod."Starting Date" := AnalysisViewEntry."Posting Date";
                    if AccountingPeriod.Next <> 0 then
                        exit(CalcDate('<-1D>', AccountingPeriod."Starting Date"));

                    exit(DMY2Date(31, 12, 9999));
                end;
        end;
    end;

    local procedure GetGlobalDimValue(GlobalDim: Code[20]; var AnalysisViewEntry: Record "Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            AnalysisView."Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 1 Value Code";
                end;
            AnalysisView."Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 2 Value Code";
                end;
            AnalysisView."Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 3 Value Code";
                end;
            AnalysisView."Dimension 4 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := AnalysisViewEntry."Dimension 4 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;
}

