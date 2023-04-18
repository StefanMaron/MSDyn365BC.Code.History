page 1515 "Workflow Step Responses"
{
    AutoSplitKey = true;
    Caption = 'Workflow Responses';
    DataCaptionExpression = DataCaptionString;
    DelayedInsert = true;
    PageType = StandardDialog;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = "Workflow Step Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = ShowResponseList;
                field(ResponseDescriptionTableControl; "Response Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Response';
                    ToolTip = 'Specifies the workflow response.';
                    Width = 100;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkflowResponse: Record "Workflow Response";
                    begin
                        ResponseDescriptionLookup('', WorkflowResponse);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Control4)
            {
                ShowCaption = false;
                Visible = NOT ShowResponseList;
                field(ResponseDescriptionCardControl; "Response Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Select Response';
                    ToolTip = 'Specifies that you want to select a workflow response.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkflowResponse: Record "Workflow Response";
                    begin
                        ResponseDescriptionLookup('', WorkflowResponse);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            field(AddMoreResponsesLabel; AddMoreResponsesLabel)
            {
                ApplicationArea = Suite;
                Caption = 'AddMoreResponsesLabel';
                Editable = false;
                Enabled = CanAddMoreResponses;
                ShowCaption = false;
                Visible = CanAddMoreResponses;

                trigger OnDrillDown()
                begin
                    AddMoreResponsesLabel := '';
                    ShowResponseList := true;
                    UpdatePageData();
                end;
            }
            field(NextStepDescription; "Next Step Description")
            {
                ApplicationArea = Suite;
                Caption = 'Next Step';
                Editable = false;
                Enabled = ShowNextStep;
                ShowCaption = false;
                ToolTip = 'Specifies another workflow step than the next one in the sequence that you want to start, for example, because the event on the workflow step failed to meet a condition.';
                Visible = ShowNextStep;

                trigger OnDrillDown()
                begin
                    if NextStepLookup() then
                        CurrPage.Update(false);
                end;
            }
            part("Workflow Response Options"; "Workflow Response Options")
            {
                ApplicationArea = Suite;
                Caption = 'Options for the Selected Response';
                SubPageLink = ID = FIELD(Argument);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        TempWorkflowStepBuffer: Record "Workflow Step Buffer" temporary;
    begin
        TempWorkflowStepBuffer.Copy(Rec, true);
        if TempWorkflowStepBuffer.FindLast() then;
        if ("Next Step Description" = '') and (Order = TempWorkflowStepBuffer.Order) then
            "Next Step Description" := NextStepTxt;

        ShowNextStep := "Next Step Description" <> '';

        UpdateRecFromWorkflowStep();
    end;

    trigger OnAfterGetRecord()
    begin
        WorkflowStep.Get("Workflow Code", "Response Step ID");
        "Response Description" := WorkflowStep.GetDescription();
        Modify();

        UpdateNextStepDescription();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        SetCurrentKey(Order);
        Ascending(true);

        if IsEmpty() then
            PopulateTableFromEvent(GetRangeMax("Workflow Code"), GetRangeMax("Parent Event Step ID"));

        exit(Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        xRecWorkflowStep: Record "Workflow Step";
    begin
        if not BelowxRec then
            "Previous Workflow Step ID" := xRec."Previous Workflow Step ID"
        else
            if not xRecWorkflowStep.Get("Workflow Code", xRec."Response Step ID") then
                "Previous Workflow Step ID" := "Parent Event Step ID"
            else
                "Previous Workflow Step ID" := xRec."Response Step ID";

        CalculateNewKey(BelowxRec);

        WorkflowStep.Init();
        UpdateNextStepDescription();
    end;

    trigger OnOpenPage()
    begin
        CalcFields(Template);
        ShowResponseList := Count > 1;
        CanAddMoreResponses := not (ShowResponseList or Template);
        AddMoreResponsesLabel := AddMoreResponsesLbl;
        UpdatePageCaption();
        ShowNextStep := true;
    end;

    var
        WorkflowStep: Record "Workflow Step";
        ShowResponseList: Boolean;
        CanAddMoreResponses: Boolean;
        DataCaptionString: Text;
        AddMoreResponsesLabel: Text;
        AddMoreResponsesLbl: Label 'Add More Responses';
        NextStepTxt: Label '<(Optional) Select Next Step>';
        ShowNextStep: Boolean;

    local procedure UpdatePageCaption()
    var
        WorkflowStep2: Record "Workflow Step";
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowStep2.Get(GetRangeMax("Workflow Code"), GetRangeMax("Parent Event Step ID"));
        WorkflowEvent.Get(WorkflowStep2."Function Name");
        DataCaptionString := WorkflowEvent.Description;
    end;

    local procedure UpdatePageData()
    begin
        ClearBuffer();
        PopulateTableFromEvent(GetRangeMax("Workflow Code"), GetRangeMax("Parent Event Step ID"));
        CurrPage.Update(false);
    end;
}

