codeunit 1310 "O365 Activities Dictionary"
{
    var
        ActivitiesMgt: Codeunit "Activities Mgt.";

    trigger OnRun()
    var
        results: Dictionary of [Text, Text];
        ActivitiesCue: Record "Activities Cue";
    begin
        results.Add(ActivitiesCue.FieldName("Sales This Month"), Format(ActivitiesMgt.CalcSalesThisMonthAmount(false)));
        results.Add(ActivitiesCue.FieldName("Overdue Sales Invoice Amount"), Format(ActivitiesMgt.CalcOverdueSalesInvoiceAmount(false)));
        results.Add(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount"), Format(ActivitiesMgt.CalcOverduePurchaseInvoiceAmount(false)));
        results.Add(ActivitiesCue.FieldName("Top 10 Customer Sales YTD"), Format(ActivitiesMgt.CalcTop10CustomerSalesYTD()));
        results.Add(ActivitiesCue.FieldName("Average Collection Days"), Format(ActivitiesMgt.CalcAverageCollectionDays()));

        Page.SetBackgroundTaskResult(results);
    end;

    procedure FillActivitiesCue(DataList: Dictionary of [Text, Text]; var ActivitiesCue: record "Activities Cue")
    begin
        if DataList.ContainsKey(ActivitiesCue.FieldName("Sales This Month")) then
            Evaluate(ActivitiesCue."Sales This Month", DataList.Get(ActivitiesCue.FieldName("Sales This Month")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Overdue Sales Invoice Amount")) then
            Evaluate(ActivitiesCue."Overdue Sales Invoice Amount", DataList.Get(ActivitiesCue.FieldName("Overdue Sales Invoice Amount")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount")) then
            Evaluate(ActivitiesCue."Overdue Purch. Invoice Amount", DataList.Get(ActivitiesCue.FieldName("Overdue Purch. Invoice Amount")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Top 10 Customer Sales YTD")) then
            Evaluate(ActivitiesCue."Top 10 Customer Sales YTD", DataList.Get(ActivitiesCue.FieldName("Top 10 Customer Sales YTD")));

        if DataList.ContainsKey(ActivitiesCue.FieldName("Average Collection Days")) then
            Evaluate(ActivitiesCue."Average Collection Days", DataList.Get(ActivitiesCue.FieldName("Average Collection Days")));
    end;
}