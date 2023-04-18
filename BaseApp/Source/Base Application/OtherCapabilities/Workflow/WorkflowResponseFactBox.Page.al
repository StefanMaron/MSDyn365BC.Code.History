page 1525 "Workflow Response FactBox"
{
    Caption = 'Workflow Response';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Workflow Step Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Response Description"; Rec."Response Description")
                {
                    ApplicationArea = Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies the workflow response.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        CurrFilterGroup: Integer;
    begin
        CurrFilterGroup := FilterGroup(0);
        SetRange("Parent Event Step ID");
        SetRange("Workflow Code");
        FilterGroup(4);
        if (ParentEventStepID <> GetRangeMax("Parent Event Step ID")) or (WorkflowCode <> GetRangeMax("Workflow Code")) then begin
            ParentEventStepID := GetRangeMax("Parent Event Step ID");
            WorkflowCode := GetRangeMax("Workflow Code");
            ClearBuffer();
        end;
        FilterGroup(CurrFilterGroup);

        if IsEmpty() then
            PopulateTableFromEvent(WorkflowCode, ParentEventStepID);

        exit(Find(Which));
    end;

    var
        ParentEventStepID: Integer;
        WorkflowCode: Code[20];

    procedure UpdateData()
    begin
        if (ParentEventStepID = 0) or (WorkflowCode = '') then
            exit;

        ClearBuffer();
        PopulateTableFromEvent(WorkflowCode, ParentEventStepID);
        CurrPage.Update(false);
    end;
}

