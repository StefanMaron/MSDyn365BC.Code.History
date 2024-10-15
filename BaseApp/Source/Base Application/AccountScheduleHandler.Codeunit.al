codeunit 11775 "Account Schedule Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Categ. Generate Acc. Schedules", 'OnCreateIncomeStatementOnAfterCreateCOGSGroup', '', false, false)]
    local procedure DeleteAccSchedLinesOnCreateIncomeStatementOnAfterCreateCOGSGroup(var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
        AccScheduleLine.Reset();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");
        AccScheduleLine.DeleteAll;
        IsHandled := true;
    end;
}