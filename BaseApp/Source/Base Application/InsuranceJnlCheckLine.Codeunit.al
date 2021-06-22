codeunit 5651 "Insurance Jnl.-Check Line"
{
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        GLSetup.Get();
        RunCheck(Rec);
    end;

    var
        Text000: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text001: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        GLSetup: Record "General Ledger Setup";
        FASetup: Record "FA Setup";
        DimMgt: Codeunit DimensionManagement;
        CallNo: Integer;

    procedure RunCheck(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        with InsuranceJnlLine do begin
            if "Insurance No." = '' then
                exit;
            TestField("Insurance No.");
            TestField("Document No.");
            TestField("Posting Date");
            TestField("FA No.");
            if CallNo = 0 then begin
                FASetup.Get();
                FASetup.TestField("Insurance Depr. Book");
            end;
            CallNo := 1;

            OnRunCheckOnBeforeCheckDimIDComb(InsuranceJnlLine);
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  Text000,
                  TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                  DimMgt.GetDimCombErr);

            TableID[1] := DATABASE::Insurance;
            No[1] := "Insurance No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                if "Line No." <> 0 then
                    Error(
                      Text001,
                      TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                      DimMgt.GetDimValuePostingErr)
                else
                    Error(DimMgt.GetDimValuePostingErr);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeCheckDimIDComb(var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
    end;

}

