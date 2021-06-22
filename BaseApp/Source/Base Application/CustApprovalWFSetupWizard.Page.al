page 1813 "Cust. Approval WF Setup Wizard"
{
    Caption = 'Customer Approval Workflow Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Approval Workflow Wizard";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT DoneVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND DoneVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = IntroVisible;
                group("Para1.1")
                {
                    Caption = 'Welcome to Customer Approval Workflow Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can create approval workflows that automatically notify an approver when a user tries to create or change a customer card.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to specify basic approval workflow settings for changing a customer card.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CustomerApproverSetupVisible;
                group("Para2.1")
                {
                    Caption = '';
                    group("Para2.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Choose who is authorized to approve or reject new or changed customer cards.';
                        field("Approver ID"; "Approver ID")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Approver';
                            LookupPageID = "Approval User Setup";

                            trigger OnValidate()
                            begin
                                CanEnableNext;
                            end;
                        }
                    }
                }
                group("Para2.2")
                {
                    Caption = '';
                    group("Para2.2.1")
                    {
                        Caption = 'Choose if the approval process starts automatically or if the user must start the process.';
                        field("App. Trigger"; "App. Trigger")
                        {
                            ApplicationArea = Suite;
                            Caption = 'The workflow starts when';

                            trigger OnValidate()
                            begin
                                CanEnableNext;
                            end;
                        }
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = CustomerAutoAppDetailsVisible;
                group("Para3.1")
                {
                    Caption = '';
                    InstructionalText = 'Choose criteria for when the approval process starts automatically.';
                    grid("Para3.1.1")
                    {
                        Caption = '';
                        GridLayout = Rows;
                        group("Para3.1.1.1")
                        {
                            Caption = '';
                            InstructionalText = 'The workflow starts when:';
                            field(CustomerFieldCap; CustomerFieldCaption)
                            {
                                ApplicationArea = Suite;
                                Caption = 'Field';
                                ShowCaption = false;

                                trigger OnLookup(var Text: Text): Boolean
                                var
                                    FieldRec: Record "Field";
                                    FieldSelection: Codeunit "Field Selection";
                                begin
                                    FindAndFilterToField(FieldRec, Text);
                                    FieldRec.SetRange("Field Caption");
                                    FieldRec.SetRange("No.");

                                    if FieldSelection.Open(FieldRec) then
                                        SetCustomerField(FieldRec."No.");
                                end;

                                trigger OnValidate()
                                var
                                    FieldRec: Record "Field";
                                    FieldSelection: Codeunit "Field Selection";
                                begin
                                    if CustomerFieldCaption = '' then begin
                                        SetCustomerField(0);
                                        exit;
                                    end;

                                    if not FindAndFilterToField(FieldRec, CustomerFieldCaption) then
                                        Error(FieldNotExistErr, CustomerFieldCaption);

                                    if FieldRec.Count = 1 then begin
                                        SetCustomerField(FieldRec."No.");
                                        exit;
                                    end;

                                    if FieldSelection.Open(FieldRec) then
                                        SetCustomerField(FieldRec."No.")
                                    else
                                        Error(FieldNotExistErr, CustomerFieldCaption);
                                end;
                            }
                            label(is)
                            {
                                ApplicationArea = Suite;
                                Caption = 'is';
                                ShowCaption = false;
                            }
                            field("Field Operator"; "Field Operator")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Operator';
                                ShowCaption = false;
                            }
                        }
                    }
                    group("Para3.1.2")
                    {
                        Caption = 'Specify the message to display when the workflow starts.';
                        field("Custom Message"; "Custom Message")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Message';
                            ShowCaption = false;
                        }
                    }
                }
            }
            group(Step10)
            {
                Caption = '';
                Visible = DoneVisible;
                group("Para10.1")
                {
                    Caption = '';
                    InstructionalText = 'Customer Approval Workflow Overview';
                    field(Overview; SummaryText)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                    }
                }
                group("Para10.2")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to enable the workflow with the specified settings.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousPage)
            {
                ApplicationArea = Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(NextPage)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(Finish)
            {
                ApplicationArea = Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    AssistedSetup: Codeunit "Assisted Setup";
                    ApprovalWorkflowSetupMgt: Codeunit "Approval Workflow Setup Mgt.";
                begin
                    ApprovalWorkflowSetupMgt.ApplyCustomerWizardUserInput(Rec);
                    AssistedSetup.Complete(PAGE::"Cust. Approval WF Setup Wizard");

                    CurrPage.Close;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        if not Get then begin
            Init;
            SetDefaultValues;
            Insert;
        end;
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
    begin
        if CloseAction = ACTION::OK then 
            if AssistedSetup.ExistsAndIsNotComplete(PAGE::"Cust. Approval WF Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    exit(false);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,"Customer Approver Setup","Automatic Approval Setup",Done;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        CustomerApproverSetupVisible: Boolean;
        CustomerAutoAppDetailsVisible: Boolean;
        DoneVisible: Boolean;
        NAVNotSetUpQst: Label 'Customer Approval has not been set up.\\Are you sure that you want to exit?';
        MandatoryApproverErr: Label 'You must select an approver before continuing.', Comment = '%1 = User Name';
        CustomerFieldCaption: Text[250];
        FieldNotExistErr: Label 'Field %1 does not exist.', Comment = '%1 = Field Caption';
        ManualTriggerTxt: Label 'An approval request will be sent to the user %1 when the user sends the request manually.', Comment = '%1 = User Name (eg. An approval request will be sent to the user Domain/Username when the user sends the request manually.)';
        AutoTriggerTxt: Label 'An approval request will be sent to the user %1 when the value in the %2 field is %3.', Comment = '%1 = User Name, %2 = Field caption, %3 = Of of this 3 values: Increased, Decreased, Changed (eg. An approval request will be sent to the user Domain/Username when the value in the Credit Limit (LCY) field is Increased.)';
        SummaryText: Text;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else begin
            if CustomerApproverSetupVisible then
                ValidateApprover;
            if CustomerAutoAppDetailsVisible then
                ValidateFieldSelection;
            Step := Step + 1;
        end;

        case Step of
            Step::Intro:
                ShowIntroStep;
            Step::"Customer Approver Setup":
                ShowApprovalUserSetupDetailsStep;
            Step::"Automatic Approval Setup":
                if "App. Trigger" = "App. Trigger"::"The user changes a specific field"
                then
                    ShowCustomerApprovalDetailsStep
                else
                    NextStep(Backwards);
            Step::Done:
                ShowDoneStep;
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls;
        IntroVisible := true;
        BackEnabled := false;
    end;

    local procedure ShowApprovalUserSetupDetailsStep()
    begin
        ResetWizardControls;
        CustomerApproverSetupVisible := true;
    end;

    local procedure ShowCustomerApprovalDetailsStep()
    begin
        ResetWizardControls;
        CustomerAutoAppDetailsVisible := true;
        SetCustomerField(Field);
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls;
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;

        if "App. Trigger" = "App. Trigger"::"The user sends an approval requests manually" then
            SummaryText := StrSubstNo(ManualTriggerTxt, "Approver ID");
        if "App. Trigger" = "App. Trigger"::"The user changes a specific field"
        then begin
            CalcFields("Field Caption");
            SummaryText := StrSubstNo(AutoTriggerTxt, "Approver ID", "Field Caption", "Field Operator");
        end;

        SummaryText := ConvertStr(SummaryText, '\', '/');
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        CustomerApproverSetupVisible := false;
        CustomerAutoAppDetailsVisible := false;
        DoneVisible := false;
    end;

    local procedure SetDefaultValues()
    var
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowCode: Code[20];
    begin
        TableNo := DATABASE::Customer;
        WorkflowCode := WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode);
        if Workflow.Get(WorkflowCode) then begin
            WorkflowStep.SetRange("Workflow Code", WorkflowCode);
            WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.ShowMessageCode);
            if WorkflowStep.FindFirst then begin
                WorkflowStepArgument.Get(WorkflowStep.Argument);
                "Custom Message" := WorkflowStepArgument.Message;
            end;
            WorkflowRule.SetRange("Workflow Code", WorkflowCode);
            if WorkflowRule.FindFirst then begin
                Field := WorkflowRule."Field No.";
                "Field Operator" := WorkflowRule.Operator;
            end;
        end;
    end;

    local procedure ValidateApprover()
    begin
        if "Approver ID" = '' then
            Error(MandatoryApproverErr);
    end;

    local procedure ValidateFieldSelection()
    begin
    end;

    local procedure CanEnableNext()
    begin
        NextEnabled := true;
    end;

    local procedure SetCustomerField(FieldNo: Integer)
    begin
        Field := FieldNo;
        CalcFields("Field Caption");
        CustomerFieldCaption := "Field Caption";
    end;

    local procedure FindAndFilterToField(var FieldRec: Record "Field"; CaptionToFind: Text): Boolean
    begin
        FieldRec.FilterGroup(2);
        FieldRec.SetRange(TableNo, DATABASE::Customer);
        FieldRec.SetFilter(Type, StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13',
            FieldRec.Type::Boolean,
            FieldRec.Type::Text,
            FieldRec.Type::Code,
            FieldRec.Type::Decimal,
            FieldRec.Type::Integer,
            FieldRec.Type::BigInteger,
            FieldRec.Type::Date,
            FieldRec.Type::Time,
            FieldRec.Type::DateTime,
            FieldRec.Type::DateFormula,
            FieldRec.Type::Option,
            FieldRec.Type::Duration,
            FieldRec.Type::RecordID));
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);

        if CaptionToFind = "Field Caption" then
            FieldRec.SetRange("No.", Field)
        else
            FieldRec.SetFilter("Field Caption", '%1', '@' + CaptionToFind + '*');

        exit(FieldRec.FindFirst);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType)) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;
}

