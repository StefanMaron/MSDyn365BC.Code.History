page 1502 "Workflow Subpage"
{
    AutoSplitKey = true;
    Caption = 'Workflow Subpage';
    DelayedInsert = true;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Workflow Step Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = Condition;
                IndentationColumn = Indent;
                IndentationControls = "Event Description";
                field(Indent; Indent)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the relationship of the workflow step under parent workflow steps.';
                    Visible = false;
                    Width = 1;
                }
                field("Event Description"; "Event Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'When Event';
                    Editable = IsNotTemplate;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the workflow event that triggers the related workflow response.';
                    Width = 45;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'On Condition';
                    Editable = false;
                    ToolTip = 'Specifies the condition that moderates the workflow event that you specified in the Event Description field. When you choose the field, the Event Conditions window opens in which you can specify condition values for predefined lists of relevant fields.';
                    Width = 30;

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable then begin
                            OpenEventConditions;
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Entry Point"; "Entry Point")
                {
                    ApplicationArea = Suite;
                    Editable = IsNotTemplate;
                    ToolTip = 'Specifies the workflow step that starts the workflow. The first workflow step is always of type Entry Point.';
                    Visible = false;
                }
                field("Response Description"; "Response Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Then Response';
                    Editable = false;
                    Lookup = false;
                    StyleExpr = "Response Description Style";
                    ToolTip = 'Specifies the workflow response that is that triggered by the related workflow event.';
                    Width = 100;

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable then begin
                            OpenEventResponses;
                            CurrPage.Update(false);
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DecreaseIndent)
            {
                ApplicationArea = Suite;
                Caption = 'Decrease Indent';
                Image = PreviousRecord;
                Scope = Repeater;
                ToolTip = 'Reduce the indentation of this step.';
                Visible = IsNotTemplate;

                trigger OnAction()
                begin
                    MoveLeft;
                end;
            }
            action(IncreaseIndent)
            {
                ApplicationArea = Suite;
                Caption = 'Increase Indent';
                Image = NextRecord;
                Scope = Repeater;
                ToolTip = 'Increase the indentation of this step.';
                Visible = IsNotTemplate;

                trigger OnAction()
                begin
                    MoveRight;
                end;
            }
            action(DeleteEventConditions)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Event Conditions';
                Enabled = EnableEditActions;
                Image = Delete;
                Scope = Repeater;
                ToolTip = 'Remove the condition filter of this step.';
                Visible = IsNotTemplate;

                trigger OnAction()
                begin
                    DeleteEventConditions;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Workflow: Record Workflow;
    begin
        if Workflow.Get(WorkflowCode) then;
        SetActionVisibility;
        UpdateResponseDescriptionStyle;
        IsNotTemplate := not Workflow.Template;
    end;

    trigger OnAfterGetRecord()
    var
        Workflow: Record Workflow;
    begin
        Workflow.Get(WorkflowCode);
        SetActionVisibility;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        FilterGroup(4);
        if WorkflowCode <> GetRangeMax("Workflow Code") then begin
            WorkflowCode := GetRangeMax("Workflow Code");
            ClearBuffer;
        end;

        if IsEmpty then
            PopulateTable(WorkflowCode);

        exit(Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CreateNewWhenThenLine(WorkflowCode, BelowxRec);
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.IsBasicOnlyEnabled then
            CurrPage.Editable := false;
    end;

    var
        WorkflowCode: Code[20];
        EnableEditActions: Boolean;
        IsNotTemplate: Boolean;

    local procedure SetActionVisibility()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowRule: Record "Workflow Rule";
    begin
        if not WorkflowStep.Get("Workflow Code", "Event Step ID") then begin
            EnableEditActions := false;
            exit;
        end;

        Workflow.Get("Workflow Code");

        EnableEditActions := (not Workflow.Enabled) and (WorkflowStep.Type = WorkflowStep.Type::"Event") and
          ((not IsNullGuid(WorkflowStep.Argument)) or WorkflowStep.FindWorkflowRules(WorkflowRule));
    end;

    procedure RefreshBuffer()
    begin
        ClearBuffer;
        PopulateTable(WorkflowCode);
    end;
}

