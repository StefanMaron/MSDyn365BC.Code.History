codeunit 1501 "Workflow Management"
{
    Permissions = TableData Workflow = r,
                  TableData "Workflow Step" = r,
                  TableData "Workflow Step Instance" = rimd,
                  TableData "Workflow Table Relation Value" = rimd,
                  TableData "Workflow Event Queue" = rimd,
                  TableData "Workflow Step Argument" = d,
                  TableData "Workflow - Record Change" = rimd,
                  TableData "Workflow Record Change Archive" = rimd,
                  TableData "Workflow Step Instance Archive" = rimd,
                  TableData "Workflow Step Argument Archive" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WorkflowRecordManagement: Codeunit "Workflow Record Management";
        AlwaysTxt: Label '<Always>';
        CombinedConditionTxt: Label '%1; %2', Locked = true;

    procedure TrackWorkflow(Variant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        RecRef: RecordRef;
    begin
        WorkflowStepInstance.MoveForward(Variant);
        RecRef.GetTable(Variant);
        UpdateRelatedTableValues(RecRef);

        if IsWorkflowCompleted(WorkflowStepInstance) then
            ArchiveWorkflowInstance(WorkflowStepInstance);
    end;

    procedure FindWorkflowStepInstance(Variant: Variant; xVariant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]): Boolean
    begin
        exit(FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant, xVariant, WorkflowStepInstance, FunctionName, true));
    end;

    procedure CanExecuteWorkflow(Variant: Variant; FunctionName: Code[128]): Boolean
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        exit(FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant, Variant, WorkflowStepInstance, FunctionName, false));
    end;

    local procedure FindWorkflowStepInstanceWithOptionalWorkflowStart(Variant: Variant; xVariant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]; StartWorkflow: Boolean): Boolean
    var
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStepInstanceLoop: Record "Workflow Step Instance";
        WorkflowStepInstance2: Record "Workflow Step Instance";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActiveStepInstanceFound: Boolean;
    begin
        RecRef.GetTable(Variant);
        xRecRef.GetTable(xVariant);

        if not StartWorkflow then begin
            Workflow.SetRange(Enabled, true);
            if Workflow.IsEmpty then begin
                WorkflowStepInstanceLoop.SetRange(Type, WorkflowStepInstanceLoop.Type::"Event");
                WorkflowStepInstanceLoop.SetRange(Status, WorkflowStepInstanceLoop.Status::Active);
                WorkflowStepInstanceLoop.SetRange("Function Name", FunctionName);
                if WorkflowStepInstanceLoop.IsEmpty then
                    exit(false);
            end;
        end;

        with WorkflowStepInstanceLoop do begin
            Reset;
            SetRange(Type, Type::"Event");
            SetRange(Status, Status::Active);
            SetRange("Function Name", FunctionName);
            SetCurrentKey("Sequence No.");

            if FindSet then
                repeat
                    if WorkflowStepInstance2.Get(ID, "Workflow Code", "Previous Workflow Step ID") then
                        if (Format(WorkflowStepInstance2."Record ID") = Format(RecRef.RecordId)) and
                           (WorkflowStepInstance2.Status in [WorkflowStepInstance2.Status::Completed, WorkflowStepInstance2.Status::Processing])
                        then begin
                            ActiveStepInstanceFound := true;
                            if WorkflowStepInstance.Get(ID, "Workflow Code", "Workflow Step ID") then begin
                                WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                                if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then
                                    exit(true);
                            end;
                        end;
                until Next = 0;
        end;

        // If the execution reaches inside this IF, it means that
        // active steps were found but the condition were not met.
        if ActiveStepInstanceFound then
            exit(false);

        WorkflowStepInstance.Reset();
        if FindMatchingWorkflowStepInstance(RecRef, xRecRef, WorkflowStepInstance, FunctionName) then
            exit(true);

        WorkflowStepInstance.Reset();
        if FindWorkflow(RecRef, xRecRef, FunctionName, Workflow) then begin
            if StartWorkflow then
                InstantiateWorkflow(Workflow, FunctionName, WorkflowStepInstance);
            exit(true);
        end;

        exit(false);
    end;

    procedure MarkChildrenStatus(WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option)
    var
        ChildWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        ChildWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        ChildWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
        ChildWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        ChildWorkflowStepInstance.SetFilter(Status, '<>%1', WorkflowStepInstance.Status::Processing);
        ChildWorkflowStepInstance.ModifyAll(Status, NewStatus, true);
    end;

    procedure MarkSiblingStatus(WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option)
    var
        SiblingWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        SiblingWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        SiblingWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        SiblingWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Previous Workflow Step ID");
        SiblingWorkflowStepInstance.SetFilter("Workflow Step ID", '<>%1', WorkflowStepInstance."Workflow Step ID");
        SiblingWorkflowStepInstance.SetFilter(Status, '<>%1', WorkflowStepInstance.Status::Processing);
        SiblingWorkflowStepInstance.ModifyAll(Status, NewStatus, true);
    end;

    procedure UpdateStatus(var WorkflowStepInstance: Record "Workflow Step Instance"; NewStatus: Option; ChildrenStatus: Option; SiblingsStatus: Option)
    begin
        WorkflowStepInstance.Status := NewStatus;
        WorkflowStepInstance.Modify(true);

        MarkChildrenStatus(WorkflowStepInstance, ChildrenStatus);

        MarkSiblingStatus(WorkflowStepInstance, SiblingsStatus);
    end;

    procedure FindWorkflow(RecRef: RecordRef; xRecRef: RecordRef; FunctionName: Code[128]; var Workflow: Record Workflow): Boolean
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
        WorkflowEvent: Record "Workflow Event";
    begin
        Workflow.SetRange(Enabled, true);
        if Workflow.IsEmpty then
            exit(false);

        WorkflowEvent.SetRange("Table ID", RecRef.Number);
        WorkflowEvent.SetRange("Function Name", FunctionName);

        if WorkflowEvent.IsEmpty then
            exit(false);

        WorkflowStep.SetRange("Function Name", FunctionName);
        WorkflowStep.SetRange("Entry Point", true);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::"Event");
        if WorkflowStep.FindSet then
            repeat
                if Workflow.Get(WorkflowStep."Workflow Code") then
                    if Workflow.Enabled then begin
                        WorkflowStep.FindWorkflowRules(WorkflowRule);
                        if EvaluateCondition(RecRef, xRecRef, WorkflowStep.Argument, WorkflowRule) then begin
                            Workflow.Get(Workflow.Code);
                            exit(true);
                        end;
                    end;
            until WorkflowStep.Next = 0;
        Clear(Workflow);
        exit(false);
    end;

    procedure WorkflowExists(Variant: Variant; xVariant: Variant; FunctionName: Code[128]): Boolean
    var
        Workflow: Record Workflow;
        RecordRef: RecordRef;
        xRecordRef: RecordRef;
    begin
        RecordRef.GetTable(Variant);
        xRecordRef.GetTable(xVariant);
        exit(FindWorkflow(RecordRef, xRecordRef, FunctionName, Workflow));
    end;

    local procedure InstantiateWorkflow(Workflow: Record Workflow; FunctionName: Text; var WorkflowStepInstance: Record "Workflow Step Instance")
    begin
        Workflow.CreateInstance(WorkflowStepInstance);
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        WorkflowStepInstance.FindFirst;
    end;

    local procedure UpdateRelatedTableValues(RecRef: RecordRef)
    var
        WorkflowTableRelationValue: Record "Workflow Table Relation Value";
    begin
        WorkflowTableRelationValue.SetRange("Record ID", RecRef.RecordId);
        if WorkflowTableRelationValue.FindSet(true) then
            repeat
                WorkflowTableRelationValue.UpdateRelationValue(RecRef);
            until WorkflowTableRelationValue.Next = 0;
    end;

    local procedure FindMatchingWorkflowStepInstance(RecRef: RecordRef; xRecRef: RecordRef; var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]): Boolean
    var
        WorkflowRule: Record "Workflow Rule";
    begin
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        WorkflowStepInstance.SetRange(Type, WorkflowStepInstance.Type::"Event");
        WorkflowStepInstance.SetFilter(Status, '%1|%2', WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status::Processing);
        if WorkflowStepInstance.FindSet then begin
            repeat
                WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                if WorkflowStepInstance.MatchesRecordValues(RecRef) then
                    if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then
                        exit(true);
            until WorkflowStepInstance.Next = 0;
        end;
        exit(false);
    end;

    local procedure EvaluateCondition(RecRef: RecordRef; xRecRef: RecordRef; ArgumentID: Guid; var WorkflowRule: Record "Workflow Rule"): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
        Result: Boolean;
    begin
        if WorkflowStepArgument.Get(ArgumentID) and WorkflowStepArgument."Event Conditions".HasValue then begin
            TempBlob.FromRecord(WorkflowStepArgument, WorkflowStepArgument.FieldNo("Event Conditions"));
            Result := EvaluateConditionOnTable(RecRef.RecordId, RecRef.Number, TempBlob) and
              EvaluateConditionsOnRelatedTables(RecRef, TempBlob);
        end else
            Result := true;

        Result := Result and EvaluateRules(RecRef, xRecRef, WorkflowRule);

        exit(Result);
    end;

    local procedure EvaluateConditionOnTable(SourceRecordId: RecordID; TableId: Integer; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRef: RecordRef;
        LookupRecRef: RecordRef;
    begin
        RecRef.Open(TableId);

        if not RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob) then
            exit(true);

        if not LookupRecRef.Get(SourceRecordId) then
            exit(false);

        LookupRecRef.SetView(RecRef.GetView(false));

        exit(LookupRecRef.Find);
    end;

    local procedure EvaluateRules(RecRef: RecordRef; xRecRef: RecordRef; var WorkflowRule: Record "Workflow Rule") Result: Boolean
    begin
        if RecRef.Number <> xRecRef.Number then
            exit(false);

        Result := true;
        if WorkflowRule.FindSet then
            repeat
                Result := Result and WorkflowRule.EvaluateRule(RecRef, xRecRef);
            until (WorkflowRule.Next = 0) or (not Result);

        exit(Result);
    end;

    local procedure IsWorkflowCompleted(WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        CompletedWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        CompletedWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        CompletedWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        CompletedWorkflowStepInstance.SetRange(Status, WorkflowStepInstance.Status::Active);
        exit(CompletedWorkflowStepInstance.IsEmpty);
    end;

    procedure ArchiveWorkflowInstance(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ToArchiveWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        ToArchiveWorkflowRecordChange: Record "Workflow - Record Change";
        WorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        ToArchiveWorkflowStepArgument: Record "Workflow Step Argument";
    begin
        ToArchiveWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        ToArchiveWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);

        if ToArchiveWorkflowStepInstance.FindSet then begin
            repeat
                WorkflowStepInstanceArchive.Init();
                WorkflowStepInstanceArchive.TransferFields(ToArchiveWorkflowStepInstance);
                if ToArchiveWorkflowStepArgument.Get(ToArchiveWorkflowStepInstance.Argument) then begin
                    WorkflowStepInstanceArchive.Argument := CreateWorkflowStepArgumentArchive(ToArchiveWorkflowStepArgument);
                    ToArchiveWorkflowStepArgument.Delete(true);
                end;
                WorkflowStepInstanceArchive.Insert();
            until ToArchiveWorkflowStepInstance.Next = 0;

            ToArchiveWorkflowStepInstance.DeleteAll(true);
        end;

        ToArchiveWorkflowRecordChange.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);

        if ToArchiveWorkflowRecordChange.FindSet then begin
            repeat
                WorkflowRecordChangeArchive.Init();
                WorkflowRecordChangeArchive.TransferFields(ToArchiveWorkflowRecordChange);
                WorkflowRecordChangeArchive.Insert();
            until ToArchiveWorkflowRecordChange.Next = 0;

            ToArchiveWorkflowRecordChange.DeleteAll(true);
        end;
    end;

    local procedure EvaluateConditionsOnRelatedTables(RecRef: RecordRef; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRefRelated: RecordRef;
        List: DotNet ArrayList;
    begin
        WorkflowTableRelation.SetRange("Table ID", RecRef.Number);

        if WorkflowTableRelation.FindSet then begin
            List := List.ArrayList;
            repeat
                if not List.Contains(WorkflowTableRelation."Related Table ID") then begin
                    List.Add(WorkflowTableRelation."Related Table ID");
                    RecRefRelated.Open(WorkflowTableRelation."Related Table ID");
                    if RequestPageParametersHelper.ConvertParametersToFilters(RecRefRelated, TempBlob) then begin
                        ApplyRelationshipFilters(RecRef, RecRefRelated);
                        if RecRefRelated.IsEmpty then
                            exit(false);
                    end;
                    RecRefRelated.Close;
                end;
            until WorkflowTableRelation.Next = 0;
        end;

        exit(true);
    end;

    local procedure ApplyRelationshipFilters(RecRef: RecordRef; RecRefRelated: RecordRef)
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        FieldRefSrc: FieldRef;
        FieldRefRelated: FieldRef;
    begin
        WorkflowTableRelation.SetRange("Table ID", RecRef.Number);
        WorkflowTableRelation.SetRange("Related Table ID", RecRefRelated.Number);
        if WorkflowTableRelation.FindSet then
            repeat
                FieldRefRelated := RecRefRelated.Field(WorkflowTableRelation."Related Field ID");
                FieldRefSrc := RecRef.Field(WorkflowTableRelation."Field ID");
                FieldRefRelated.SetRange(FieldRefSrc.Value);
            until WorkflowTableRelation.Next = 0
    end;

    procedure FindResponse(var ResponseWorkflowStepInstance: Record "Workflow Step Instance"; PreviousWorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    begin
        ResponseWorkflowStepInstance.SetRange("Workflow Code", PreviousWorkflowStepInstance."Workflow Code");
        ResponseWorkflowStepInstance.SetRange(ID, PreviousWorkflowStepInstance.ID);
        ResponseWorkflowStepInstance.SetRange(Type, ResponseWorkflowStepInstance.Type::Response);
        ResponseWorkflowStepInstance.SetRange("Previous Workflow Step ID", PreviousWorkflowStepInstance."Workflow Step ID");
        exit(ResponseWorkflowStepInstance.FindFirst);
    end;

    procedure FindEventWorkflowStepInstance(var WorkflowStepInstance: Record "Workflow Step Instance"; FunctionName: Code[128]; Variant: Variant; xVariant: Variant): Boolean
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
    begin
        Workflow.SetRange(Enabled, true);
        if WorkflowStepInstance.IsEmpty and Workflow.IsEmpty then
            exit(false);

        WorkflowEvent.Get(FunctionName);

        exit(FindWorkflowStepInstance(Variant, xVariant, WorkflowStepInstance, WorkflowEvent."Function Name"));
    end;

    procedure HandleEvent(FunctionName: Code[128]; Variant: Variant)
    begin
        HandleEventWithxRec(FunctionName, Variant, Variant);
    end;

    procedure HandleEventWithxRec(FunctionName: Code[128]; Variant: Variant; xVariant: Variant)
    var
        ActionableWorkflowStepInstance: Record "Workflow Step Instance";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleEventWithxRec(FunctionName, Variant, xVariant, IsHandled);
        if IsHandled then
            exit;

        RecRef.GetTable(Variant);
        if RecRef.IsTemporary then
            exit;
        if FindEventWorkflowStepInstance(ActionableWorkflowStepInstance, FunctionName, Variant, xVariant) then
            ExecuteResponses(Variant, xVariant, ActionableWorkflowStepInstance);
    end;

    procedure HandleEventOnKnownWorkflowInstance(FunctionName: Code[128]; Variant: Variant; WorkflowStepInstanceID: Guid)
    begin
        HandleEventWithxRecOnKnownWorkflowInstance(FunctionName, Variant, Variant, WorkflowStepInstanceID)
    end;

    procedure HandleEventWithxRecOnKnownWorkflowInstance(FunctionName: Code[128]; Variant: Variant; xVariant: Variant; WorkflowStepInstanceID: Guid)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        ActionableWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActionableStepFound: Boolean;
    begin
        RecRef.GetTable(Variant);
        xRecRef.GetTable(xVariant);

        WorkflowStepInstance.SetRange(ID, WorkflowStepInstanceID);
        WorkflowStepInstance.SetRange(Status, ActionableWorkflowStepInstance.Status::Active);
        WorkflowStepInstance.SetRange("Function Name", FunctionName);
        if WorkflowStepInstance.FindSet then
            repeat
                WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then begin
                    ActionableWorkflowStepInstance := WorkflowStepInstance;
                    ActionableStepFound := true;
                end;
            until (WorkflowStepInstance.Next = 0) or ActionableStepFound;

        if ActionableStepFound then
            ExecuteResponses(Variant, xVariant, ActionableWorkflowStepInstance);
    end;

    procedure ExecuteResponses(Variant: Variant; xVariant: Variant; ActionableWorkflowStepInstance: Record "Workflow Step Instance")
    var
        ResponseWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        RecRef: RecordRef;
        Variant1: Variant;
    begin
        if not CanExecuteEvent(ActionableWorkflowStepInstance) then begin
            StoreEventForLaterProcessing(Variant, xVariant, ActionableWorkflowStepInstance);

            if ActionableWorkflowStepInstance.Status <> ActionableWorkflowStepInstance.Status::Completed then begin
                ActionableWorkflowStepInstance.Status := ActionableWorkflowStepInstance.Status::Processing;
                ActionableWorkflowStepInstance.Modify(true);
            end;

            exit;
        end;

        RecRef.GetTable(Variant);

        UpdateStatus(ActionableWorkflowStepInstance, ActionableWorkflowStepInstance.Status::Completed,
          ActionableWorkflowStepInstance.Status::Active, ActionableWorkflowStepInstance.Status::Ignored);

        UpdateStepAndRelatedTableData(ActionableWorkflowStepInstance, RecRef);

        ChangeStatusForResponsesAndEvents(ActionableWorkflowStepInstance);

        Variant1 := Variant;

        while FindResponse(ResponseWorkflowStepInstance, ActionableWorkflowStepInstance) do begin
            UpdateStepAndRelatedTableData(ResponseWorkflowStepInstance, RecRef);

            WorkflowResponseHandling.ExecuteResponse(Variant1, ResponseWorkflowStepInstance, xVariant);

            UpdateStatusForResponse(ResponseWorkflowStepInstance);

            ActionableWorkflowStepInstance := ResponseWorkflowStepInstance;
            Clear(ResponseWorkflowStepInstance);
        end;

        ExecuteQueuedEvents;

        if IsWorkflowCompleted(ActionableWorkflowStepInstance) then
            ArchiveWorkflowInstance(ActionableWorkflowStepInstance);
    end;

    local procedure CanExecuteEvent(WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        ProcessingWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        ProcessingWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        ProcessingWorkflowStepInstance.SetRange(Status, WorkflowStepInstance.Status::Processing);
        ProcessingWorkflowStepInstance.SetFilter("Workflow Step ID", '<>%1', WorkflowStepInstance."Workflow Step ID");
        exit(ProcessingWorkflowStepInstance.IsEmpty);
    end;

    local procedure StoreEventForLaterProcessing(Variant: Variant; xVariant: Variant; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        WorkflowEventQueue.Init();
        WorkflowEventQueue."Session ID" := SessionId;
        WorkflowEventQueue."Step Record ID" := WorkflowStepInstance.RecordId;
        WorkflowEventQueue."Record ID" := RecRef.RecordId;
        WorkflowEventQueue."Record Index" := WorkflowRecordManagement.BackupRecord(Variant);
        WorkflowEventQueue."xRecord Index" := WorkflowRecordManagement.BackupRecord(xVariant);
        WorkflowEventQueue.Insert(true);
    end;

    local procedure ExecuteQueuedEvents()
    var
        WorkflowEventQueue: Record "Workflow Event Queue";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowRule: Record "Workflow Rule";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        Variant: Variant;
        xVariant: Variant;
    begin
        WorkflowEventQueue.SetRange("Session ID", SessionId);
        if WorkflowEventQueue.FindSet then
            repeat
                WorkflowStepInstance.Get(WorkflowEventQueue."Step Record ID");
                if WorkflowStepInstance.Status = WorkflowStepInstance.Status::Processing then begin
                    WorkflowRecordManagement.RestoreRecord(WorkflowEventQueue."Record Index", Variant);
                    WorkflowRecordManagement.RestoreRecord(WorkflowEventQueue."xRecord Index", xVariant);
                    RecRef.GetTable(Variant);
                    xRecRef.GetTable(xVariant);
                    WorkflowStepInstance.FindWorkflowRules(WorkflowRule);
                    if EvaluateCondition(RecRef, xRecRef, WorkflowStepInstance.Argument, WorkflowRule) then begin
                        ExecuteResponses(RecRef, xRecRef, WorkflowStepInstance);
                        WorkflowEventQueue.Delete();
                    end;
                end;
            until WorkflowEventQueue.Next = 0;
    end;

    procedure ChangeStatusForResponsesAndEvents(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        MarkWorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowEventQueue: Record "Workflow Event Queue";
    begin
        MarkWorkflowStepInstance.SetRange(ID, WorkflowStepInstance.ID);
        MarkWorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        MarkWorkflowStepInstance.SetRange("Previous Workflow Step ID", WorkflowStepInstance."Workflow Step ID");
        if MarkWorkflowStepInstance.FindSet then
            repeat
                if MarkWorkflowStepInstance.Type = MarkWorkflowStepInstance.Type::Response then begin
                    MarkWorkflowStepInstance.Status := MarkWorkflowStepInstance.Status::Processing;
                    MarkWorkflowStepInstance.Modify(true);
                    ChangeStatusForResponsesAndEvents(MarkWorkflowStepInstance);
                end else begin
                    // check if queued event
                    WorkflowEventQueue.SetRange("Session ID", SessionId);
                    WorkflowEventQueue.SetRange("Step Record ID", MarkWorkflowStepInstance."Record ID");
                    if WorkflowEventQueue.IsEmpty then begin
                        MarkWorkflowStepInstance.Status := MarkWorkflowStepInstance.Status::Active;
                        MarkWorkflowStepInstance.Modify(true);
                    end;
                end;
            until MarkWorkflowStepInstance.Next = 0;
    end;

    local procedure UpdateStepAndRelatedTableData(var WorkflowStepInstance: Record "Workflow Step Instance"; RecRef: RecordRef)
    begin
        WorkflowStepInstance."Record ID" := RecRef.RecordId;
        WorkflowStepInstance.Modify(true);

        UpdateRelatedTableValues(RecRef);

        if not WorkflowStepInstance.TableRelationValuesExist(RecRef) then
            WorkflowStepInstance.SetTableRelationValues(RecRef);
    end;

    local procedure UpdateStatusForResponse(var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        NextWorkflowStepInstance: Record "Workflow Step Instance";
    begin
        if WorkflowStepInstance."Next Workflow Step ID" <> 0 then begin
            NextWorkflowStepInstance.Get(WorkflowStepInstance.ID,
              WorkflowStepInstance."Workflow Code", WorkflowStepInstance."Next Workflow Step ID");

            case NextWorkflowStepInstance.Type of
                NextWorkflowStepInstance.Type::"Event":
                    UpdateStatus(NextWorkflowStepInstance, NextWorkflowStepInstance.Status::Active,
                      NextWorkflowStepInstance.Status::Inactive, NextWorkflowStepInstance.Status::Ignored);
                NextWorkflowStepInstance.Type::Response:
                    UpdateStatus(NextWorkflowStepInstance, NextWorkflowStepInstance.Status::Completed,
                      NextWorkflowStepInstance.Status::Active, NextWorkflowStepInstance.Status::Ignored);
            end;
        end;
        UpdateStatus(WorkflowStepInstance, WorkflowStepInstance.Status::Completed,
          WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status::Ignored);
    end;

    procedure EnabledWorkflowExist(TableNo: Integer; EventFilter: Text): Boolean
    var
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowDefinition.SetRange(Table_ID, TableNo);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Template, false);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetFilter(Function_Name, EventFilter);
        WorkflowDefinition.Open;
        exit(WorkflowDefinition.Read);
    end;

    procedure NavigateToWorkflows(TableNo: Integer; EventFilter: Text)
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
        Workflows: Page Workflows;
        WorkflowDefinition: Query "Workflow Definition";
        "Count": Integer;
        WorkflowFilter: Text;
        CategoryFilter: Text;
    begin
        WorkflowDefinition.SetRange(Table_ID, TableNo);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Template, false);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetFilter(Function_Name, EventFilter);
        WorkflowDefinition.Open;

        while WorkflowDefinition.Read do begin
            Workflow.Get(WorkflowDefinition.Code);
            BuildFilter(WorkflowFilter, Workflow.Code);
            BuildFilter(CategoryFilter, Workflow.Category);
            Count += 1;
        end;

        if Count = 1 then begin
            Workflow.Get(WorkflowFilter);
            PAGE.RunModal(PAGE::Workflow, Workflow);
        end else begin
            TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);
            TempWorkflowBuffer.SetFilter("Workflow Code", WorkflowFilter);
            TempWorkflowBuffer.SetFilter("Category Code", CategoryFilter);
            Workflows.SetWorkflowBufferRec(TempWorkflowBuffer);
            Workflows.RunModal;
        end;
    end;

    local procedure BuildFilter(var InitialFilter: Text; NewValue: Text)
    begin
        if StrPos(InitialFilter, NewValue) = 0 then begin
            if StrLen(InitialFilter) > 0 then
                InitialFilter += '|';
            InitialFilter += NewValue;
        end;
    end;

    local procedure CreateWorkflowStepArgumentArchive(ToArchiveWorkflowStepArgument: Record "Workflow Step Argument"): Guid
    var
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
    begin
        WorkflowStepArgumentArchive.Init();
        WorkflowStepArgumentArchive.TransferFields(ToArchiveWorkflowStepArgument);
        WorkflowStepArgumentArchive."Original Record ID" := ToArchiveWorkflowStepArgument.RecordId;
        WorkflowStepArgumentArchive.Insert(true);

        exit(WorkflowStepArgumentArchive.ID);
    end;

    procedure BuildConditionDisplay(WorkflowStep: Record "Workflow Step") Condition: Text[100]
    var
        RuleAsText: Text;
    begin
        Condition := CopyStr(WorkflowStep.GetConditionAsDisplayText, 1, MaxStrLen(Condition));
        RuleAsText := WorkflowStep.GetRuleAsDisplayText;
        if RuleAsText <> '' then
            if Condition = '' then
                Condition := CopyStr(RuleAsText, 1, MaxStrLen(Condition))
            else
                Condition := CopyStr(StrSubstNo(CombinedConditionTxt, Condition, RuleAsText), 1, MaxStrLen(Condition));

        if Condition = '' then
            Condition := AlwaysTxt;
    end;

    procedure ClearSupportedCombinations(FunctionName: Code[128]; WFEventResponseCombinationType: Option "Event",Response)
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WFEventResponseCombination.SetRange(Type, WFEventResponseCombinationType);
        WFEventResponseCombination.SetRange("Function Name", FunctionName);
        if not WFEventResponseCombination.IsEmpty then
            WFEventResponseCombination.DeleteAll(true);

        WFEventResponseCombination.Reset();
        WFEventResponseCombination.SetRange("Predecessor Type", WFEventResponseCombinationType);
        WFEventResponseCombination.SetRange("Predecessor Function Name", FunctionName);
        if not WFEventResponseCombination.IsEmpty then
            WFEventResponseCombination.DeleteAll(true);
    end;

    procedure GetWebhookClientLink(ClientId: Guid; ClientType: Text): Text
    var
        FlowServiceMgt: Codeunit "Flow Service Management";
    begin
        if not IsNullGuid(ClientId) then
            case ClientType of
                'Flow':
                    exit(FlowServiceMgt.GetFlowDetailsUrl(ClientId));
            end;

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleEventWithxRec(FunctionName: Code[128]; Variant: Variant; xVariant: Variant; var IsHandled: Boolean)
    begin
    end;
}

