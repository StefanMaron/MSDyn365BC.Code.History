page 1500 Workflows
{
    ApplicationArea = Suite;
    Caption = 'Workflows';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage,Flow';
    RefreshOnActivate = true;
    SourceTable = "Workflow Buffer";
    SourceTableTemporary = true;
    SourceTableView = WHERE(Template = CONST(false));
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
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specifies a description of the workflow.';
                }
                field(Source; Source)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ToolTip = 'Specifies the source of the workflow.';
                }
                field("Category Code"; "Category Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow type, such as Administration or Finance.';
                    Visible = false;
                }
                field("Workflow Code"; "Workflow Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow that the workflow step belongs to.';
                    Visible = false;
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies if the workflow is enabled.';
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
            group(New)
            {
                Caption = 'New';
                action(NewAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'New';
                    Image = NewDocument;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;
                    ToolTip = 'Create a new workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        WorkflowPage: Page Workflow;
                    begin
                        if IsEmpty then begin
                            Clear(Rec);
                            Insert;
                        end;
                        Workflow.SetRange(Template, false);
                        if Workflow.IsEmpty then
                            Workflow.Insert();
                        Workflow.FilterGroup := 2;
                        WorkflowPage.SetOpenNew(true);
                        WorkflowPage.SetTableView(Workflow);
                        WorkflowPage.SetRecord(Workflow);
                        WorkflowPage.Run;
                    end;
                }
                action(CopyFromTemplate)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Workflow from Template';
                    Image = Copy;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;
                    ToolTip = 'Create a new workflow quickly using a template.';

                    trigger OnAction()
                    var
                        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
                    begin
                        if IsEmpty then begin
                            Clear(Rec);
                            Insert;
                        end;
                        if PAGE.RunModal(PAGE::"Workflow Templates", TempWorkflowBuffer) = ACTION::LookupOK then begin
                            CopyWorkflow(TempWorkflowBuffer);

                            // If first workflow on an empty page
                            if Count = 1 then
                                Rec := TempWorkflowBuffer;

                            RefreshTempWorkflowBuffer;
                        end;
                    end;
                }
                action(CopyWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Workflow';
                    Enabled = "Workflow Code" <> '';
                    Image = Copy;
                    Promoted = true;
                    PromotedCategory = New;
                    PromotedIsBig = true;
                    ToolTip = 'Copy an existing workflow.';

                    trigger OnAction()
                    begin
                        CopyWorkflow(Rec);
                    end;
                }
            }
            group(Manage)
            {
                Caption = 'Manage';
                action(EditAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'Edit';
                    Enabled = "Workflow Code" <> '';
                    Image = Edit;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Return';
                    ToolTip = 'Edit an existing workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                    begin
                        if Workflow.Get("Workflow Code") then
                            PAGE.Run(PAGE::Workflow, Workflow);
                    end;
                }
                action(ViewAction)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Enabled = "Workflow Code" <> '';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'View an existing workflow.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        WorkflowPage: Page Workflow;
                    begin
                        Workflow.Get("Workflow Code");
                        WorkflowPage.SetRecord(Workflow);
                        WorkflowPage.SetOpenView(true);
                        WorkflowPage.Run;
                    end;
                }
                action(DeleteAction)
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete';
                    Enabled = "Workflow Code" <> '';
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'Delete the record.';

                    trigger OnAction()
                    begin
                        Delete(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Process)
            {
                Caption = 'Process';
                action(ImportWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Import from File';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Import workflow from a file.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                    begin
                        if FileManagement.BLOBImport(TempBlob, '') <> '' then begin
                            Workflow.ImportFromBlob(TempBlob);
                            RefreshTempWorkflowBuffer;
                        end;
                    end;
                }
                action(ExportWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Export to File';
                    Enabled = ExportEnabled;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Export the workflow to a file that can be imported in another Dynamics 365 database.';

                    trigger OnAction()
                    var
                        Workflow: Record Workflow;
                        TempBlob: Codeunit "Temp Blob";
                        FileManagement: Codeunit "File Management";
                        "Filter": Text;
                    begin
                        Filter := GetFilterFromSelection;
                        if Filter = '' then
                            exit;
                        Workflow.SetFilter(Code, Filter);
                        Workflow.ExportToBlob(TempBlob);
                        FileManagement.BLOBExport(TempBlob, '*.xml', true);
                    end;
                }
            }
            group(Flow)
            {
                Caption = 'Flow';
                action(WebhookClientLink)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Enabled = ExternalLinkEnabled;
                    Image = Flow;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'View Flow Definition';
                    Visible = IsSaaS;

                    trigger OnAction()
                    var
                        WorkflowMgt: Codeunit "Workflow Management";
                    begin
                        CalcFields("External Client Type");
                        HyperLink(WorkflowMgt.GetWebhookClientLink("External Client ID", "External Client Type"));
                    end;
                }
            }
        }
        area(navigation)
        {
            action(ViewTemplates)
            {
                ApplicationArea = Suite;
                Caption = 'View Templates';
                Ellipsis = true;
                Image = ViewPage;
                RunObject = Page "Workflow Templates";
                ToolTip = 'View the existing workflow templates.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RefreshTempWorkflowBufferRow;
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshTempWorkflowBuffer;
        ExportEnabled := not IsEmpty;

        if "Workflow Code" = '' then begin
            DescriptionStyle := 'Strong';
            ExternalLinkEnabled := false;
            Source := '';
        end else begin
            DescriptionStyle := 'Standard';

            // Enable/disable external links
            CalcFields("External Client ID");
            ExternalLinkEnabled := not IsNullGuid("External Client ID");

            if ExternalLinkEnabled then
                Source := FlowSourceText
            else
                Source := BusinessCentralSourceTxt;
        end
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        WorkflowSetup.InitWorkflow;
        if not WorkflowBufferInitialized then
            InitBufferForWorkflows(Rec);

        IsSaaS := EnvironmentInfo.IsSaaS;
    end;

    var
        WorkflowSetup: Codeunit "Workflow Setup";
        DescriptionStyle: Text;
        ExportEnabled: Boolean;
        Refresh: Boolean;
        WorkflowBufferInitialized: Boolean;
        ExternalLinkEnabled: Boolean;
        IsSaaS: Boolean;
        Source: Text;
        BusinessCentralSourceTxt: Label 'Business Central';
        FlowSourceText: Label 'Microsoft Flow';

    local procedure RefreshTempWorkflowBuffer()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
        WorkflowCode: Code[20];
        CurrentWorkflowChanged: Boolean;
        WorkflowCountChanged: Boolean;
    begin
        WorkflowCode := "Workflow Code";
        if Workflow.Get(WorkflowCode) then
            CurrentWorkflowChanged := ("Category Code" <> Workflow.Category) or (Description <> Workflow.Description)
        else
            CurrentWorkflowChanged := WorkflowCode <> '';

        Workflow.SetRange(Template, false);

        TempWorkflowBuffer.Copy(Rec, true);
        TempWorkflowBuffer.Reset();
        TempWorkflowBuffer.SetFilter("Workflow Code", '<>%1', '');
        TempWorkflowBuffer.SetRange(Template, false);

        WorkflowCountChanged := Workflow.Count <> TempWorkflowBuffer.Count();

        if CurrentWorkflowChanged or WorkflowCountChanged then begin
            InitBufferForWorkflows(Rec);
            Refresh := true;
        end;
    end;

    local procedure RefreshTempWorkflowBufferRow()
    var
        Workflow: Record Workflow;
    begin
        if Refresh then begin
            CurrPage.Update(false);
            Refresh := false;
            exit;
        end;

        if "Workflow Code" = '' then
            exit;

        Workflow.Get("Workflow Code");
        "Category Code" := Workflow.Category;
        Description := Workflow.Description;
        Modify;
    end;

    local procedure GetFilterFromSelection() "Filter": Text
    var
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        TempWorkflowBuffer.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempWorkflowBuffer);

        if TempWorkflowBuffer.FindSet then
            repeat
                if TempWorkflowBuffer."Workflow Code" <> '' then
                    if Filter = '' then
                        Filter := TempWorkflowBuffer."Workflow Code"
                    else
                        Filter := StrSubstNo('%1|%2', Filter, TempWorkflowBuffer."Workflow Code");
            until TempWorkflowBuffer.Next = 0;
    end;

    procedure SetWorkflowBufferRec(var TempWorkflowBuffer: Record "Workflow Buffer" temporary)
    begin
        WorkflowBufferInitialized := true;
        InitBufferForWorkflows(Rec);
        CopyFilters(TempWorkflowBuffer);
        if StrLen(GetFilter("Workflow Code")) > 0 then
            SetFilter("Workflow Code", TempWorkflowBuffer.GetFilter("Workflow Code") + '|''''');
        if FindLast then;
    end;
}

