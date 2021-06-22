page 1505 "Workflow Templates"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Templates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "Workflow Buffer";
    SourceTableTemporary = true;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Indentation;
                IndentationControls = Description;
                ShowAsTree = true;
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specifies a description of the workflow template.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control7; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewAction)
            {
                ApplicationArea = Suite;
                Caption = 'View';
                Image = View;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'View an existing workflow template.';

                trigger OnAction()
                var
                    Workflow: Record Workflow;
                begin
                    Workflow.Get("Workflow Code");
                    PAGE.Run(PAGE::Workflow, Workflow);
                end;
            }
            action("New Workflow from Template")
            {
                ApplicationArea = Suite;
                Caption = 'New Workflow from Template';
                Enabled = NOT IsLookupMode;
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                ToolTip = 'Create a new workflow template using an existing workflow template.';

                trigger OnAction()
                begin
                    CopyWorkflow(Rec)
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "Workflow Code" = '' then
            DescriptionStyle := 'Strong'
        else
            DescriptionStyle := 'Standard';
    end;

    trigger OnOpenPage()
    begin
        WorkflowSetup.InitWorkflow;
        InitBufferForTemplates(Rec);
        IsLookupMode := CurrPage.LookupMode;
        if FindFirst then;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CurrPage.LookupMode and (CloseAction = ACTION::LookupOK) and ("Workflow Code" = '') then
            Error(QueryClosePageLookupErr);
    end;

    var
        WorkflowSetup: Codeunit "Workflow Setup";
        QueryClosePageLookupErr: Label 'Select a workflow template to continue, or choose Cancel to close the page.';
        DescriptionStyle: Text;
        IsLookupMode: Boolean;
}

