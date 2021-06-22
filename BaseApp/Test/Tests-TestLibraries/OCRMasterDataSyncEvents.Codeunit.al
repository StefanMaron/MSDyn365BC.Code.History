codeunit 135099 "OCR Master Data Sync Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsValidationEnabled: Boolean;

    [EventSubscriber(ObjectType::Codeunit, 453, 'OnBeforeJobQueueScheduleTask', '', false, false)]
    [Scope('OnPrem')]
    procedure DisableTaskOnBeforeJobQueueScheduleTask(var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true
    end;

    [EventSubscriber(ObjectType::Codeunit, 884, 'OnBeforeSendRequest', '', false, false)]
    local procedure HandleOnBeforeSendRequest(Body: Text)
    var
        "Part": Text;
    begin
        if not IsValidationEnabled then
            exit;

        Part := LibraryVariableStorage.DequeueText;
        if Part <> '' then
            Assert.IsSubstring(Body, Part);
    end;

    [Scope('OnPrem')]
    procedure EnableValidation()
    begin
        IsValidationEnabled := true;
    end;

    [Scope('OnPrem')]
    procedure DisableValidation()
    begin
        IsValidationEnabled := false;
    end;

    [Scope('OnPrem')]
    procedure AssertEmptyQueue()
    begin
        LibraryVariableStorage.AssertEmpty;
    end;

    [Scope('OnPrem')]
    procedure EnqueueVariable(Variable: Variant)
    begin
        LibraryVariableStorage.Enqueue(Variable);
    end;

    [Scope('OnPrem')]
    procedure ClearQueue()
    begin
        LibraryVariableStorage.Clear;
    end;
}

