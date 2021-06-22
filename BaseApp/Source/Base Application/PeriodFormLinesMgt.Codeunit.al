codeunit 920 "Period Form Lines Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        DummyBuffer: Record "Customer Sales Buffer";
        PeriodFormMgt: Codeunit PeriodFormManagement;

    procedure FindDate(var BufferRecord: Variant; var DateRec: Record Date; Which: Text[3]; PeriodType: Option): Boolean
    var
        RecRef: RecordRef;
        FoundDate: Boolean;
        FoundLine: Boolean;
    begin
        RecRef.GetTable(BufferRecord);
        CopyPeriodStartFilter(RecRef, DateRec);
        FoundDate := PeriodFormMgt.FindDate(Which, DateRec, PeriodType);
        if not FoundDate then
            exit(false);

        FoundLine := FindLine(RecRef, DateRec);
        if not FoundLine then
            FoundLine := InsertLine(RecRef, DateRec);

        RecRef.SetTable(BufferRecord);

        exit(FoundLine);
    end;

    procedure NextDate(var BufferRecord: Variant; var DateRec: Record Date; Steps: Integer; PeriodType: Option): Integer
    var
        RecRef: RecordRef;
        ResultSteps: Integer;
    begin
        RecRef.GetTable(BufferRecord);
        CopyPeriodStartFilter(RecRef, DateRec);
        ResultSteps := PeriodFormMgt.NextDate(Steps, DateRec, PeriodType);
        if ResultSteps = 0 then
            exit(0);

        if not FindLine(RecRef, DateRec) then
            if not InsertLine(RecRef, DateRec) then
                exit(0);

        RecRef.SetTable(BufferRecord);

        exit(ResultSteps);
    end;

    local procedure FindLine(var RecRef: RecordRef; TargetDate: Record Date) FoundLine: Boolean
    begin
        RecRef.Reset();
        SetFieldFilter(RecRef, DummyBuffer.FieldNo("Period Type"), TargetDate."Period Type");
        SetFieldFilter(RecRef, DummyBuffer.FieldNo("Period Start"), TargetDate."Period Start");
        FoundLine := RecRef.FindFirst();
        RecRef.Reset();
    end;

    local procedure InsertLine(var RecRef: RecordRef; TargetDate: Record Date): Boolean
    begin
        SetFieldValue(RecRef, DummyBuffer.FieldNo("Period Type"), TargetDate."Period Type");
        SetFieldValue(RecRef, DummyBuffer.FieldNo("Period Start"), TargetDate."Period Start");
        SetFieldValue(RecRef, DummyBuffer.FieldNo("Period End"), TargetDate."Period End");
        SetFieldValue(RecRef, DummyBuffer.FieldNo("Period Name"), TargetDate."Period Name");
        exit(RecRef.Insert());
    end;

    local procedure SetFieldValue(var RecRef: RecordRef; FieldNo: Integer; FieldValue: Variant)
    var
        BufferField: FieldRef;
    begin
        BufferField := RecRef.Field(FieldNo);
        BufferField.Value := FieldValue;
    end;

    local procedure SetFieldFilter(var RecRef: RecordRef; FieldNo: Integer; FieldFilter: Variant)
    var
        BufferField: FieldRef;
    begin
        BufferField := RecRef.Field(FieldNo);
        BufferField.SetRange(FieldFilter);
    end;

    local procedure GetPeriodStartFilter(RecRef: RecordRef): Text
    var
        PeriodStart: FieldRef;
    begin
        PeriodStart := RecRef.Field(DummyBuffer.FieldNo("Period Start"));
        exit(PeriodStart.GetFilter());
    end;

    local procedure CopyPeriodStartFilter(var RecRef: RecordRef; var DateRec: Record Date)
    begin
        DateRec.SetFilter("Period Start", GetPeriodStartFilter(RecRef));
    end;

}