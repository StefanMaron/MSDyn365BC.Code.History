codeunit 9079 "Background Error Handling Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        NullJSONTxt: Label 'null', Locked = true;

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
    begin
        if JournalErrorsMgt.GetDeletedGenJnlLine(TempGenJnlLine, false) then begin
            TempErrorMessage.Reset();
            if TempGenJnlLine.FindSet() then
                repeat
                    TempErrorMessage.SetRange("Context Record ID", TempGenJnlLine.RecordId);
                    TempErrorMessage.DeleteAll();

                    CleanDocumentRelatedErrors(
                        TempErrorMessage, TempGenJnlLine."Journal Template Name", TempGenJnlLine."Journal Batch Name",
                        TempGenJnlLine."Document No.", TempGenJnlLine."Posting Date");
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

    procedure PackDeletedDocumentsToArgs(var Args: Dictionary of [Text, Text])
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        if JournalErrorsMgt.GetDeletedGenJnlLine(TempGenJnlLine, true) then begin
            TempGenJnlLine.FindSet();
            repeat
                Args.Add(Format(TempGenJnlLine."Line No."), DeletedDocumentToJson(TempGenJnlLine));
            until TempGenJnlLine.Next() = 0;
        end;
    end;

    local procedure DeletedDocumentToJson(TempGenJnlLine: Record "Gen. Journal Line" temporary) JSON: Text
    var
        JObject: JsonObject;
    begin
        JObject.Add(TempGenJnlLine.FieldName("Document No."), TempGenJnlLine."Document No.");
        JObject.Add(TempGenJnlLine.FieldName("Posting Date"), TempGenJnlLine."Posting Date");
        JObject.WriteTo(JSON);
    end;

    local procedure ParseDeletedDocument(JSON: Text; var TempGenJnlLine: Record "Gen. Journal Line" temporary): Boolean
    var
        JObject: JsonObject;
        DocumentNo: Text;
        PostingDateText: Text;
    begin
        if NullJSONTxt <> JSON then begin
            if not JObject.ReadFrom(JSON) then
                exit(false);
            if not GetJsonKeyValue(JObject, TempGenJnlLine.FieldName("Document No."), DocumentNo) then
                exit(false);
            if not GetJsonKeyValue(JObject, TempGenJnlLine.FieldName("Posting Date"), PostingDateText) then
                exit(false);

            TempGenJnlLine.Init();
            TempGenJnlLine."Document No." := CopyStr(DocumentNo, 1, MaxStrLen(TempGenJnlLine."Document No."));
            Evaluate(TempGenJnlLine."Posting Date", PostingDateText);

            exit(true);
        end;
    end;

    local procedure GetJsonKeyValue(var JObject: JsonObject; KeyName: Text; var KeyValue: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(false);

        KeyValue := JToken.AsValue().AsText();
        exit(true);
    end;

    procedure GetDeletedDocumentsFromArgs(Args: Dictionary of [Text, Text]; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        JSON: Text;
    begin
        foreach JSON in Args.Values do
            if ParseDeletedDocument(JSON, TempGenJnlLine) then begin
                TempGenJnlLine."Line No." += 10000;
                TempGenJnlLine.Insert();
            end;
    end;
}