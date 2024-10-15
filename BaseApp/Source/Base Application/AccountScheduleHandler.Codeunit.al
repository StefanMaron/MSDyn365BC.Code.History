#if not CLEAN21
codeunit 11775 "Account Schedule Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '21.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Categ. Generate Acc. Schedules", 'OnCreateIncomeStatementOnAfterCreateCOGSGroup', '', false, false)]
    local procedure DeleteAccSchedLinesOnCreateIncomeStatementOnAfterCreateCOGSGroup(var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
        AccScheduleLine.Reset();
        AccScheduleLine.SetRange("Schedule Name", AccScheduleLine."Schedule Name");
        AccScheduleLine.DeleteAll();
        IsHandled := true;
    end;
}
#endif