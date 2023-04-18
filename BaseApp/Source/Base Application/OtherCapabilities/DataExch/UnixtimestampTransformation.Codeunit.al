codeunit 1225 "Unixtimestamp Transformation"
{

    trigger OnRun()
    begin
    end;

    var
        UNIXTimeStampDescTxt: Label 'Transforming UNIX timestamp to text format.';
        UNIXTimeStampTxt: Label 'UNIXTIMESTAMP', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnTransformation', '', false, false)]
    local procedure TransformUnixtimestampOnTransformation(TransformationCode: Code[20]; InputText: Text; var OutputText: Text)
    begin
        if TransformationCode <> GetUnixTimestampCode() then
            exit;
        if not TryConvert2BigInteger(InputText, OutputText) then
            OutputText := ''
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnCreateTransformationRules', '', false, false)]
    local procedure InsertUnixtimestampOnCreateTransformationRules()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if not TransformationRule.Get(GetUnixTimestampCode()) then
            TransformationRule.CreateRule(
                GetUnixTimestampCode(), UNIXTimeStampDescTxt, TransformationRule."Transformation Type"::Custom.AsInteger(), 0, 0, '', '');
    end;

    [TryFunction]
    local procedure TryConvert2BigInteger(InputText: Text; var OutputText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        TempBinteger: BigInteger;
    begin
        Evaluate(TempBinteger, InputText);
        OutputText := Format(TypeHelper.EvaluateUnixTimestamp(TempBinteger), 0, 9);
    end;

    procedure GetUnixTimestampCode(): Code[20]
    begin
        exit(UNIXTimeStampTxt);
    end;
}

