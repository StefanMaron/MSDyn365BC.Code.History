page 1501 Workflow
{
    Caption = 'Workflow';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Flow';
    SourceTable = Workflow;

    layout
    {
        area(content)
        {
            field("Code"; Code)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the workflow.';

                trigger OnValidate()
                begin
                    if OpenNew then begin
                        if Insert() then;
                        CurrPage.Update(false);
                        Get(Code);
                        OpenNew := false;
                    end;
                end;
            }
            field(Description; Description)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the workflow.';
            }
            field(Category; Category)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                ToolTip = 'Specifies the category that the workflow belongs to.';
            }
            field(Enabled; Enabled)
            {
                ApplicationArea = Basic, Suite;
                Editable = IsNotTemplate;
                Enabled = IsNotTemplate;
                ToolTip = 'Specifies that the workflow will start when the event in the first entry-point workflow step occurs.';

                trigger OnValidate()
                begin
                    CurrPage.Update;
                end;
            }
            part(WorkflowSubpage; "Workflow Subpage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Workflow Steps';
                SubPageLink = "Workflow Code" = FIELD(Code);
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(WorkflowResponses; "Workflow Response FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Workflow Responses';
                Provider = WorkflowSubpage;
                SubPageLink = "Parent Event Step ID" = FIELD("Event Step ID"),
                              "Workflow Code" = FIELD("Workflow Code");
            }
            systempart(Control11; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control10; Links)
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
            action(ImportWorkflow)
            {
                ApplicationArea = Suite;
                Caption = 'Import from File';
                Enabled = Code <> '';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Import an existing workflow from an XML file.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    WorkflowImpExpMgt: Codeunit "Workflow Imp. / Exp. Mgt";
                    FileManagement: Codeunit "File Management";
                begin
                    if FileManagement.BLOBImport(TempBlob, '') = '' then
                        exit;

                    WorkflowImpExpMgt.ReplaceWorkflow(Rec, TempBlob);
                    CurrPage.WorkflowSubpage.PAGE.RefreshBuffer;
                end;
            }
            action(ExportWorkflow)
            {
                ApplicationArea = Suite;
                Caption = 'Export to File';
                Enabled = Code <> '';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Export the workflow to a file that can be imported in another Dynamics 365 database.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    Workflow: Record Workflow;
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                begin
                    Workflow.Get(Code);
                    Workflow.SetRange(Code, Code);
                    Workflow.ExportToBlob(TempBlob);
                    FileManagement.BLOBExport(TempBlob, '*.xml', true);
                end;
            }
            group(Flow)
            {
                Caption = 'Flow';
                action(WebhookClientLink)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View';
                    Image = Flow;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ToolTip = 'View Flow Definition';
                    Visible = HasWebhookClientLink;

                    trigger OnAction()
                    var
                        WorkflowMgt: Codeunit "Workflow Management";
                    begin
                        if not WorkflowWebhookSubscription.IsEmpty then
                            HyperLink(WorkflowMgt.GetWebhookClientLink(WorkflowWebhookSubscription."Client Id", WorkflowWebhookSubscription."Client Type"));
                    end;
                }
            }
        }
        area(navigation)
        {
            action(WorkflowStepInstances)
            {
                ApplicationArea = Suite;
                Caption = 'Workflow Step Instances';
                Enabled = InstancesExist;
                Image = List;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Show all instances of workflow steps in current workflows.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    WorkflowStepInstances: Page "Workflow Step Instances";
                begin
                    WorkflowStepInstances.SetWorkflow(Rec);
                    WorkflowStepInstances.RunModal;
                end;
            }
            action(ArchivedWorkflowStepInstances)
            {
                ApplicationArea = Suite;
                Caption = 'Archived Workflow Step Instances';
                Enabled = ArchiveExists;
                Image = ListPage;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View all instances of workflow steps that are no longer used, either because they are completed or because they were manually archived.';
                Visible = IsNotTemplate;

                trigger OnAction()
                var
                    ArchivedWFStepInstances: Page "Archived WF Step Instances";
                begin
                    ArchivedWFStepInstances.SetWorkflowCode(Code);
                    ArchivedWFStepInstances.RunModal;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if OpenNew then
            Clear(Rec);

        CurrPage.WorkflowResponses.PAGE.UpdateData;

        if not TemplateValueSet then begin
            TemplateValueSet := True;
            SetRange(Template, Template);
        end;
    end;

    trigger OnAfterGetRecord()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
    begin
        IsNotTemplate := not Template;

        WorkflowStepInstance.SetRange("Workflow Code", Code);
        InstancesExist := not WorkflowStepInstance.IsEmpty;

        WorkflowStepInstanceArchive.SetRange("Workflow Code", Code);
        ArchiveExists := not WorkflowStepInstanceArchive.IsEmpty;
    end;

    trigger OnClosePage()
    var
        Workflow: Record Workflow;
    begin
        if Workflow.Get then
            Workflow.Delete();
    end;

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsNotTemplate := not Template;
        InstancesExist := false;
        ArchiveExists := false;

        if OpenView or ApplicationAreaMgmtFacade.IsBasicOnlyEnabled then
            CurrPage.Editable := false;

        // Load webhook subscription link when page opens
        WorkflowWebhookSubscription.SetRange(Enabled, true);
        WorkflowWebhookSubscription.SetRange("WF Definition Id", Code);
        HasWebhookClientLink := WorkflowWebhookSubscription.FindFirst;
    end;

    var
        WorkflowWebhookSubscription: Record "Workflow Webhook Subscription";
        IsNotTemplate: Boolean;
        InstancesExist: Boolean;
        ArchiveExists: Boolean;
        OpenNew: Boolean;
        OpenView: Boolean;
        HasWebhookClientLink: Boolean;
        TemplateValueSet: Boolean;

    procedure SetOpenNew(NewOpenNew: Boolean)
    begin
        OpenNew := NewOpenNew
    end;

    procedure SetOpenView(NewOpenView: Boolean)
    begin
        OpenView := NewOpenView
    end;
}

