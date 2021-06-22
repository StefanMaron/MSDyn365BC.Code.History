page 1816 "Job Creation Wizard"
{
    Caption = 'Create New Job';
    DelayedInsert = true;
    PageType = NavigatePage;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND NOT FinalStepVisible;
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible AND FinalStepVisible;
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control25)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to Create New Job")
                {
                    Caption = 'Welcome to Create New Job';
                    Visible = FirstStepVisible;
                    group(Control23)
                    {
                        InstructionalText = 'Do you want to create a new job from an existing job?';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                        field(FromExistingJob; FromExistingJob)
                        {
                            ApplicationArea = Jobs;
                            CaptionClass = Format(FromExistingJob);
                        }
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = CreationStepVisible;
                group(Control20)
                {
                    Caption = 'Welcome to Create New Job';
                    Visible = CreationStepVisible;
                    group(Control18)
                    {
                        InstructionalText = 'Fill in the following fields for the new job.';
                        ShowCaption = false;
                        Visible = CreationStepVisible;
                        field("No."; "No.")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'No.';

                            trigger OnAssistEdit()
                            begin
                                if AssistEdit(xRec) then
                                    CurrPage.Update;
                            end;
                        }
                        field(Description; Description)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Description';
                        }
                        field("Bill-to Customer No."; "Bill-to Customer No.")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Bill-to Customer No.';
                            TableRelation = Customer;
                        }
                    }
                    group(Control9)
                    {
                        InstructionalText = 'To select the tasks to copy from an existing job, choose Next.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control4)
                    {
                        InstructionalText = 'To view your new job, choose Finish.';
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners;
    end;

    trigger OnOpenPage()
    begin
        Init;

        Step := Step::Start;
        EnableControls;
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Creation,Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        CreationStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FromExistingJob: Boolean;
        SelectJobNumberMsg: Label 'To continue, specify the job number that you want to copy.';
        SelectCustomerNumberMsg: Label 'To continue, specify the customer of the new job.';

    local procedure EnableControls()
    begin
        if Step = Step::Finish then begin
            if "No." = '' then begin
                Message(SelectJobNumberMsg);
                Step := Step - 1;
                exit;
            end;

            if "Bill-to Customer No." = '' then begin
                Message(SelectCustomerNumberMsg);
                Step := Step - 1;
                exit;
            end;
        end;

        ResetControls;

        case Step of
            Step::Start:
                ShowStartStep;
            Step::Creation:
                ShowCreationStep;
            Step::Finish:
                ShowFinalStep;
        end;
    end;

    local procedure FinishAction()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
        CurrPage.Close;
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls;
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        FinishActionEnabled := false;
        BackActionEnabled := false;
        FromExistingJob := true;
    end;

    local procedure ShowCreationStep()
    begin
        CreationStepVisible := true;
        FinishActionEnabled := false;

        // If user clicked "Back", the Job will already exist, so don't try to create it again.
        if "No." = '' then begin
            Insert(true);
            Commit();
        end;

        if not FromExistingJob then
            FinishAction;
    end;

    local procedure ShowFinalStep()
    var
        CopyJobTasks: Page "Copy Job Tasks";
    begin
        FinalStepVisible := true;
        BackActionEnabled := false;
        NextActionEnabled := false;

        CopyJobTasks.SetToJob(Rec);
        CopyJobTasks.Run;
    end;

    local procedure ResetControls()
    begin
        FinishActionEnabled := true;
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        CreationStepVisible := false;
        FinalStepVisible := false;
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

