codeunit 14962 PayrlAViewEntryToPayrlEntries
{

    trigger OnRun()
    begin
    end;

    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        GLSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";

    [Scope('OnPrem')]
    procedure GetPayrollEntries(var PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry"; var TempPayrollLedgerEntry: Record "Payroll Ledger Entry")
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        PayrollAnalysisViewFilter: Record "Payroll Analysis View Filter";
        UpdatePayrollAnalysisView: Codeunit "Update Payroll Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        PayrollAnalysisView.Get(PayrollAnalysisViewEntry."Analysis View Code");

        GLSetup.Get;

        StartDate := PayrollAnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        with PayrollAnalysisView do
            if StartDate < "Starting Date" then
                StartDate := 0D
            else
                if (PayrollAnalysisViewEntry."Posting Date" = NormalDate(PayrollAnalysisViewEntry."Posting Date")) and
                   not ("Date Compression" in ["Date Compression"::None, "Date Compression"::Day])
                then
                    case "Date Compression" of
                        "Date Compression"::Week:
                            EndDate := PayrollAnalysisViewEntry."Posting Date" + 6;
                        "Date Compression"::Month:
                            EndDate := CalcDate('<+1M-1D>', PayrollAnalysisViewEntry."Posting Date");
                        "Date Compression"::Quarter:
                            EndDate := CalcDate('<+3M-1D>', PayrollAnalysisViewEntry."Posting Date");
                        "Date Compression"::Year:
                            EndDate := CalcDate('<+1Y-1D>', PayrollAnalysisViewEntry."Posting Date");
                    end;

        with PayrollLedgerEntry do begin
            SetCurrentKey("Employee No.");
            SetRange("Employee No.", PayrollAnalysisViewEntry."Employee No.");
            SetRange("Element Code", PayrollAnalysisViewEntry."Element Code");
            SetRange("Posting Date", StartDate, EndDate);
            SetRange("Entry No.", 0, PayrollAnalysisView."Last Entry No.");

            if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", PayrollAnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 1 Code", GlobalDimValue)
            else
                if PayrollAnalysisViewFilter.Get(
                     PayrollAnalysisViewEntry."Analysis View Code",
                     GLSetup."Global Dimension 1 Code")
                then
                    SetFilter("Global Dimension 1 Code", PayrollAnalysisViewFilter."Dimension Value Filter");

            if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", PayrollAnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 2 Code", GlobalDimValue)
            else
                if PayrollAnalysisViewFilter.Get(
                     PayrollAnalysisViewEntry."Analysis View Code",
                     GLSetup."Global Dimension 2 Code")
                then
                    SetFilter("Global Dimension 2 Code", PayrollAnalysisViewFilter."Dimension Value Filter");

            if FindSet then
                repeat
                    if DimEntryOK("Dimension Set ID", PayrollAnalysisView."Dimension 1 Code", PayrollAnalysisViewEntry."Dimension 1 Value Code") and
                       DimEntryOK("Dimension Set ID", PayrollAnalysisView."Dimension 2 Code", PayrollAnalysisViewEntry."Dimension 2 Value Code") and
                       DimEntryOK("Dimension Set ID", PayrollAnalysisView."Dimension 3 Code", PayrollAnalysisViewEntry."Dimension 3 Value Code") and
                       DimEntryOK("Dimension Set ID", PayrollAnalysisView."Dimension 4 Code", PayrollAnalysisViewEntry."Dimension 4 Value Code") and
                       UpdatePayrollAnalysisView.DimSetIDInFilter("Dimension Set ID", PayrollAnalysisView)
                    then begin
                        TempPayrollLedgerEntry := PayrollLedgerEntry;
                        if TempPayrollLedgerEntry.Insert then;
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

    local procedure GetGlobalDimValue(GlobalDim: Code[20]; var PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            PayrollAnalysisView."Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := PayrollAnalysisViewEntry."Dimension 1 Value Code";
                end;
            PayrollAnalysisView."Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := PayrollAnalysisViewEntry."Dimension 2 Value Code";
                end;
            PayrollAnalysisView."Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := PayrollAnalysisViewEntry."Dimension 3 Value Code";
                end;
            PayrollAnalysisView."Dimension 4 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := PayrollAnalysisViewEntry."Dimension 4 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;
}

