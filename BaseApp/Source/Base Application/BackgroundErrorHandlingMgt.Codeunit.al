codeunit 9079 "Background Error Handling Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";

    procedure CleanTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        CheckCleanDeletedGenJnlLinesErrors(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else
            if ErrorHandlingParameters."Line Modified" then begin
                CleanDocumentRelatedErrors(
                    TempErrorMessage, ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name",
                    ErrorHandlingParameters."Previous Document No.", ErrorHandlingParameters."Previous Posting Date");
                CleanDocumentRelatedErrors(
                    TempErrorMessage, ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name",
                    ErrorHandlingParameters."Document No.", ErrorHandlingParameters."Posting Date");
            end;
    end;

    local procedure CheckCleanDeletedGenJnlLinesErrors(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if JournalErrorsMgt.GetDeletedGenJnlLine(TempGenJnlLine, true) then begin
            TempErrorMessage.Reset();
            if TempGenJnlLine.FindSet() then
                repeat
                    GenJnlLine.SetRange("Journal Template Name", TempGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TempGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Document No.", TempGenJnlLine."Document No.");
                    GenJnlLine.SetRange("Posting Date", TempGenJnlLine."Posting Date");
                    if GenJnlLine.FindSet() then
                        repeat
                            TempErrorMessage.SetRange("Context Record ID", GenJnlLine.RecordId);
                            TempErrorMessage.DeleteAll();
                        until GenJnlLine.Next() = 0;
                until TempGenJnlLine.Next() = 0;
        end;
    end;

    local procedure CleanDocumentRelatedErrors(var TempErrorMessage: Record "Error Message" temporary; TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date)
    var
        DocGenJnlLine: Record "Gen. Journal Line";
    begin
        TempErrorMessage.Reset();
        DocGenJnlLine.SetRange("Journal Template Name", TemplateName);
        DocGenJnlLine.SetRange("Journal Batch Name", BatchName);
        DocGenJnlLine.SetRange("Document No.", DocumentNo);
        DocGenJnlLine.SetRange("Posting Date", PostingDate);
        if DocGenJnlLine.FindSet() then
            repeat
                TempErrorMessage.SetRange("Context Record ID", DocGenJnlLine.RecordId());
                TempErrorMessage.DeleteAll();
            until DocGenJnlLine.Next() = 0;
    end;

    procedure CollectGenJnlCheckParameters(GenJnlLine: Record "Gen. Journal Line"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempxGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        ErrorHandlingParameters."Journal Template Name" := GenJnlLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        ErrorHandlingParameters."Full Batch Check" := JournalErrorsMgt.GetFullBatchCheck();
        ErrorHandlingParameters."Line Modified" := JournalErrorsMgt.GetRecXRecOnModify(TempxGenJnlLine, TempGenJnlLine);
        ErrorHandlingParameters."Document No." := TempGenJnlLine."Document No.";
        ErrorHandlingParameters."Posting Date" := TempGenJnlLine."Posting Date";
        ErrorHandlingParameters."Previous Document No." := TempxGenJnlLine."Document No.";
        ErrorHandlingParameters."Previous Posting Date" := TempxGenJnlLine."Posting Date";
    end;

    procedure GetErrorsFromGenJnlCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        JournalErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then
            JournalErrorsMgt.SetFullBatchCheck(false);
    end;
}