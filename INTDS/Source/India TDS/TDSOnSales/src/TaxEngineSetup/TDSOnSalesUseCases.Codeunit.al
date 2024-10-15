codeunit 18663 "TDS On Sales Use Cases"
{
    procedure GetJObject(): JsonObject
    var
        JObject: JsonObject;
    begin
        JObject.ReadFrom(GetText());
        exit(JObject);
    end;

    procedure GetText(): Text
    begin
        exit(TDSOnSalesUseCasesLbl);
    end;

    var
        TDSOnSalesUseCasesLbl: Label 'TDS on Sales Use Cases';
}