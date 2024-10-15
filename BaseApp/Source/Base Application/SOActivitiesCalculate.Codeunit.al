codeunit 906 "SO Activities Calculate"
{
    var
        Results: Dictionary of [Text, Text];

    trigger OnRun()
    var
        Parameters: Dictionary of [Text, Text];
    begin
        Parameters := Page.GetBackgroundParameters();

        CalculateFieldValues(Parameters, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    procedure CalculateFieldValues(Parameters: Dictionary of [Text, Text]; var ReturnResults: Dictionary of [Text, Text])
    var
        SalesCue: Record "Sales Cue";
    begin
        SalesCue.SetView(Parameters.Get('View'));

        CalculateCueFieldValues(SalesCue);

        ReturnResults.Add(SalesCue.FieldName("Average Days Delayed"), Format(SalesCue."Average Days Delayed"));
        ReturnResults.Add(SalesCue.FieldName("Ready to Ship"), Format(SalesCue."Ready to Ship"));
        ReturnResults.Add(SalesCue.FieldName("Partially Shipped"), Format(SalesCue."Partially Shipped"));
        ReturnResults.Add(SalesCue.FieldName(Delayed), Format(SalesCue.Delayed));

        ReturnResults.Add(SalesCue.FieldName("Missing SII Entries"), Format(SalesCue."Missing SII Entries"));
        ReturnResults.Add(SalesCue.FieldName("Days Since Last SII Check"), Format(SalesCue."Days Since Last SII Check"));
    end;

    procedure EvaluateResults(var Results: Dictionary of [Text, Text]; var SalesCue: Record "Sales Cue")
    var
        ResultValue: Text;
    begin
        if Results.Count() = 0 then
            exit;

        if TryGetDictionaryValue(Results, SalesCue.FieldName("Average Days Delayed"), ResultValue) then
            Evaluate(SalesCue."Average Days Delayed", ResultValue);
        if TryGetDictionaryValue(Results, SalesCue.FieldName("Ready to Ship"), ResultValue) then
            Evaluate(SalesCue."Ready to Ship", ResultValue);
        if TryGetDictionaryValue(Results, SalesCue.FieldName("Partially Shipped"), ResultValue) then
            Evaluate(SalesCue."Partially Shipped", ResultValue);
        if TryGetDictionaryValue(Results, SalesCue.FieldName(Delayed), ResultValue) then
            Evaluate(SalesCue.Delayed, ResultValue);

        if TryGetDictionaryValue(Results, SalesCue.FieldName("Missing SII Entries"), ResultValue) then
            Evaluate(SalesCue."Missing SII Entries", ResultValue);
        if TryGetDictionaryValue(Results, SalesCue.FieldName("Days Since Last SII Check"), ResultValue) then
            Evaluate(SalesCue."Days Since Last SII Check", ResultValue);
    end;

    [TryFunction]
    local procedure TryGetDictionaryValue(var Results: Dictionary of [Text, Text]; DictionaryKey: Text; var ReturnValue: Text)
    begin
        ReturnValue := Results.Get(DictionaryKey);
    end;

    local procedure CalculateCueFieldValues(var SalesCue: Record "Sales Cue")
    var
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        SalesCue."Average Days Delayed" := SalesCue.CalculateAverageDaysDelayed();
        SalesCue."Ready to Ship" := SalesCue.CountOrders(SalesCue.FieldNo("Ready to Ship"));
        SalesCue."Partially Shipped" := SalesCue.CountOrders(SalesCue.FieldNo("Partially Shipped"));
        SalesCue.Delayed := SalesCue.CountOrders(SalesCue.FieldNo(Delayed));
        SalesCue."Missing SII Entries" := SIIRecreateMissingEntries.GetMissingEntriesCount();
        SalesCue."Days Since Last SII Check" := SIIRecreateMissingEntries.GetDaysSinceLastCheck();
    end;
}