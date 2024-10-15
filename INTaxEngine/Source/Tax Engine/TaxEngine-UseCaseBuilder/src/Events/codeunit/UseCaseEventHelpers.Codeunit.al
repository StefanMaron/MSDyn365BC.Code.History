codeunit 20288 "Use Case Event Helpers"
{
    procedure OpenAvailableUseCases(var UseCaseEvent: Record "Use Case Event");
    var
        UseCase: Record "Tax Use Case";
        TempUseCase: Record "Tax Use Case" Temporary;
        UseCaseExecution: Codeunit "Use Case Execution";
        AvailableUseCases: Page "Available Use Cases";
    begin
        if not UseCase.FindSet() then
            exit;

        repeat
            if UseCaseExecution.IsLeafUseCase(UseCase.ID) then begin
                Clear(TempUseCase);
                TempUseCase.ID := UseCase.ID;
                TempUseCase.Description := UseCase.Description;
                TempUseCase."Tax Type" := UseCase."Tax Type";
                TempUseCase.Enable := UseCaseExist(UseCaseEvent.Name, UseCase.ID);
                TempUseCase.Insert();
            end;
        until UseCase.Next() = 0;

        TempUseCase.Reset();
        if TempUseCase.FindSet() then begin
            AvailableUseCases.SetRuleBuffer(TempUseCase);
            AvailableUseCases.LOOKUPMODE(true);
            AvailableUseCases.EDITABLE(true);
            if AvailableUseCases.RunModal() = ACTION::LookupOK then begin
                AvailableUseCases.GetRuleBtuffer(TempUseCase);
                UpdateEventRuleRelation(TempUseCase, UseCaseEvent.Name);
            end;
        end;
    end;

    procedure OpenAvailableEvents(var UseCase: Record "Tax Use Case");
    var
        UseCaseEvent: Record "Use Case Event";
        TempUseCaseEvent: Record "Use Case Event" temporary;
        UseCaseEventHandling: Codeunit "Use Case Event Handling";
        AvailableUseCaseEvents: Page "Available Use Case Events";
    begin
        UseCaseEventHandling.CreateEventsLibrary();
        Commit();
        UseCase.TestField(Enable, false);

        if not (UseCaseEvent.FindSet()) then
            exit;

        repeat
            Clear(TempUseCaseEvent);
            TempUseCaseEvent.Name := UseCaseEvent.Name;
            TempUseCaseEvent.Enable := EventExist(UseCaseEvent.Name, UseCase.ID);
            TempUseCaseEvent.Description := UseCaseEvent.Description;
            TempUseCaseEvent."Table ID" := UseCaseEvent."Table ID";
            TempUseCaseEvent.Insert();
        until UseCaseEvent.Next() = 0;

        TempUseCaseEvent.Reset();
        if TempUseCaseEvent.FindSet() then begin
            Clear(AvailableUseCaseEvents);
            AvailableUseCaseEvents.SetEventBuffer(TempUseCaseEvent);
            AvailableUseCaseEvents.LOOKUPMODE(true);
            if AvailableUseCaseEvents.RunModal() = ACTION::LookupOK then begin
                AvailableUseCaseEvents.GetEventBuffer(TempUseCaseEvent);
                UpdateEvents(TempUseCaseEvent, UseCase);
            end;
        end;
    end;

    local procedure UseCaseExist(Name: Text[100]; CaseID: Guid): Boolean;
    var
        UseCaseEventRelation: Record "Use Case Event Relation";
    begin
        UseCaseEventRelation.SetRange("Event Name", Name);
        UseCaseEventRelation.SetRange("Case ID", CaseID);
        exit(Not UseCaseEventRelation.IsEmpty());
    end;

    local procedure EventExist(Name: Text[100]; CaseID: Guid): Boolean;
    var
        UseCaseEventRelation: Record "Use Case Event Relation";
    begin
        UseCaseEventRelation.SetRange("Event Name", Name);
        UseCaseEventRelation.SetRange("Case ID", CaseID);
        exit(Not UseCaseEventRelation.IsEmpty());
    end;

    local procedure UpdateEventRuleRelation(
        var NewTempAvailableUseCase: Record "Tax Use Case" Temporary;
        EventName: Text[100]);
    var
        UseCaseEvent: Record "Use Case Event";
        UseCaseEventRelation: Record "Use Case Event Relation";
    begin
        UseCaseEventRelation.SetRange("Event Name", EventName);
        if UseCaseEventRelation.FindSet() then
            repeat
                NewTempAvailableUseCase.Reset();
                NewTempAvailableUseCase.SetRange(ID, UseCaseEventRelation."Case ID");
                NewTempAvailableUseCase.SetRange(Enable, true);
                if not NewTempAvailableUseCase.FindFirst() then
                    UseCaseEventRelation.Delete(true)
                else
                    NewTempAvailableUseCase.Delete();
            until UseCaseEventRelation.Next() = 0;

        NewTempAvailableUseCase.Reset();
        NewTempAvailableUseCase.SetRange(Enable, true);
        if NewTempAvailableUseCase.FindSet() then
            repeat
                UseCaseEvent.Reset();
                UseCaseEvent.SetRange(Name, EventName);
                UseCaseEvent.FindFirst();

                UseCaseEventRelation.Init();
                UseCaseEventRelation."Event Name" := EventName;
                UseCaseEventRelation.Description := UseCaseEvent.Description;
                UseCaseEventRelation."Use Case Name" := NewTempAvailableUseCase.Description;
                UseCaseEventRelation."Case ID" := NewTempAvailableUseCase.ID;
                UseCaseEventRelation."Tax Type" := NewTempAvailableUseCase."Tax Type";
                UseCaseEventRelation.Insert(true);
            until NewTempAvailableUseCase.Next() = 0;
    end;

    local procedure UpdateEvents(
        var TempUseCaseEvent: Record "Use Case Event" temporary;
        VAR TaxUseCase: Record "Tax Use Case")
    var
        UseCaseEventRelation: Record "Use Case Event Relation";
    begin
        UseCaseEventRelation.SetRange("Case ID", TaxUseCase.ID);
        UseCaseEventRelation.DeleteAll();

        TempUseCaseEvent.Reset();
        TempUseCaseEvent.SetRange(Enable, true);
        if TempUseCaseEvent.FindSet() then
            repeat
                Clear(UseCaseEventRelation);
                UseCaseEventRelation."Case ID" := TaxUseCase.ID;
                UseCaseEventRelation."Event Name" := TempUseCaseEvent.Name;
                UseCaseEventRelation.Description := TempUseCaseEvent.Description;
                UseCaseEventRelation."Tax Type" := TaxUseCase."Tax Type";
                UseCaseEventRelation.Insert();
            until TempUseCaseEvent.Next() = 0;
    end;
}