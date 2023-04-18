page 5189 "Create Rating"
{
    Caption = 'Create Rating';
    DataCaptionExpression = "Profile Questionnaire Code" + ' ' + Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            group(Step3)
            {
                Caption = 'Step 3';
                InstructionalText = 'Please specify the range of points required to get the different answer options.';
                Visible = Step3Visible;
                field(GetProfileLineAnswerDesc; GetProfileLineAnswerDesc())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Please select one of the options below to specify the points your contact must earn in order to receive this rating.';
                    Editable = false;
                    MultiLine = true;
                }
                group(Control3)
                {
                    ShowCaption = false;
                    field("Interval Option"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Interval;

                        trigger OnValidate()
                        begin
                            if "Interval Option" = "Interval Option"::Interval then
                                IntervalIntervalOptionOnValida();
                        end;
                    }
                    field("Wizard From Value"; Rec."Wizard From Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'From:';
                        DecimalPlaces = 0 :;
                        Enabled = WizardFromValueEnable;
                    }
                    field("Wizard To Value"; Rec."Wizard To Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'To:';
                        DecimalPlaces = 0 :;
                        Enabled = WizardToValueEnable;
                    }
                }
                group(Control32)
                {
                    ShowCaption = false;
                    field("Interval Option2"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Minimum;

                        trigger OnValidate()
                        begin
                            if "Interval Option" = "Interval Option"::Minimum then
                                MinimumIntervalOptionOnValidat();
                        end;
                    }
                    field(Minimum; "Wizard From Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'From:';
                        DecimalPlaces = 0 :;
                        Enabled = MinimumEnable;
                    }
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field("Interval Option3"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Maximum;

                        trigger OnValidate()
                        begin
                            if "Interval Option" = "Interval Option"::Maximum then
                                MaximumIntervalOptionOnValidat();
                        end;
                    }
                    field(Maximum; "Wizard To Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'To:';
                        DecimalPlaces = 0 :;
                        Enabled = MaximumEnable;
                    }
                }
            }
            group(Step1)
            {
                Caption = 'Step 1';
                InstructionalText = 'This wizard helps you define the methods you will use to rate your contacts.';
                Visible = Step1Visible;
                field("Profile Questionnaire Code"; Rec."Profile Questionnaire Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'For which questionnaire should this rating be created';
                    TableRelation = "Profile Questionnaire Header";
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Describe the type of rating (for example, Overall Customer Rating)';
                    MultiLine = true;
                }
                field("Min. % Questions Answered"; Rec."Min. % Questions Answered")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'What percentage of questions need to be answered before a rating is assigned?';
                    MultiLine = true;
                }
            }
            group(Step4)
            {
                Caption = 'Step 4';
                InstructionalText = 'When you choose Finish, the questions and answers you have created will be saved and the Answer Points window will open. In this window, you can assign points to each answer.';
                Visible = Step4Visible;
                part(SubForm; "Create Rating Subform")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Visible = SubFormVisible;
                }
            }
            group(Step2)
            {
                Caption = 'Step 2';
                Visible = Step2Visible;
                field("Answer Option"; Rec."Answer Option")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Specify which of the following grouping methods you will use to rate your contacts.';
                    ValuesAllowed = HighLow, ABC, Custom;

                    trigger OnValidate()
                    begin
                        if "Answer Option" = "Answer Option"::Custom then
                            CustomAnswerOptionOnValidate();
                        if "Answer Option" = "Answer Option"::ABC then
                            ABCAnswerOptionOnValidate();
                        if "Answer Option" = "Answer Option"::HighLow then
                            HighLowAnswerOptionOnValidate();
                    end;
                }
                field(NoOfAnswers; NoOfProfileAnswers())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Number of possible answers:';
                    Enabled = NoOfAnswersEnable;

                    trigger OnDrillDown()
                    begin
                        ShowAnswers();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Back)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Back';
                Enabled = BackEnable;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowStep(false);
                    PerformPrevWizardStatus();
                    ShowStep(true);
                    UpdateCntrls();
                    CurrPage.Update(true);
                end;
            }
            action(Next)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Next';
                Enabled = NextEnable;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CheckStatus();
                    ShowStep(false);
                    PerformNextWizardStatus();
                    ShowStep(true);
                    UpdateCntrls();
                    CurrPage.Update(true);
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Enabled = FinishEnable;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CheckStatus();
                    FinishWizard();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        MaximumEnable := true;
        MinimumEnable := true;
        WizardToValueEnable := true;
        WizardFromValueEnable := true;
        NoOfAnswersEnable := true;
        NextEnable := true;
        SubFormVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FormWidth := CancelXPos + CancelWidth + 220;
        FrmXPos := Round((FrmWidth - FormWidth) / 2, 1) + FrmXPos;
        FrmWidth := FormWidth;

        Validate("Auto Contact Classification", true);
        Validate("Contact Class. Field", "Contact Class. Field"::Rating);
        Modify();

        ValidateAnswerOption();
        ValidateIntervalOption();

        ShowStep(true);

        UpdateCntrls();
    end;

    var
        TempProfileLineAnswer: Record "Profile Questionnaire Line" temporary;
        FormWidth: Integer;
        CancelXPos: Integer;
        CancelWidth: Integer;
        FrmXPos: Integer;
        FrmWidth: Integer;
        [InDataSet]
        Step1Visible: Boolean;
        [InDataSet]
        Step2Visible: Boolean;
        [InDataSet]
        Step3Visible: Boolean;
        [InDataSet]
        Step4Visible: Boolean;
        [InDataSet]
        SubFormVisible: Boolean;
        [InDataSet]
        NextEnable: Boolean;
        [InDataSet]
        BackEnable: Boolean;
        [InDataSet]
        FinishEnable: Boolean;
        [InDataSet]
        NoOfAnswersEnable: Boolean;
        [InDataSet]
        WizardFromValueEnable: Boolean;
        [InDataSet]
        WizardToValueEnable: Boolean;
        [InDataSet]
        MinimumEnable: Boolean;
        [InDataSet]
        MaximumEnable: Boolean;

    local procedure ShowStep(Visible: Boolean)
    begin
        case "Wizard Step" of
            "Wizard Step"::"1":
                begin
                    NextEnable := true;
                    BackEnable := false;
                    Step1Visible := Visible;
                    if Visible then;
                end;
            "Wizard Step"::"2":
                begin
                    Step2Visible := Visible;
                    BackEnable := true;
                    NextEnable := true;
                end;
            "Wizard Step"::"3":
                begin
                    Step3Visible := Visible;
                    if Visible then begin
                        BackEnable := true;
                        NextEnable := true;
                        FinishEnable := false;
                    end;
                end;
            "Wizard Step"::"4":
                begin
                    if Visible then begin
                        GetAnswers(TempProfileLineAnswer);
                        CurrPage.SubForm.PAGE.SetRecords(Rec, TempProfileLineAnswer);
                    end;
                    FinishEnable := true;
                    NextEnable := false;
                    Step4Visible := Visible;
                    CurrPage.SubForm.PAGE.UpdateForm();
                end;
        end;
    end;

    local procedure UpdateCntrls()
    begin
        NoOfAnswersEnable := "Answer Option" = "Answer Option"::Custom;
        WizardFromValueEnable := "Interval Option" = "Interval Option"::Interval;
        WizardToValueEnable := "Interval Option" = "Interval Option"::Interval;
        MinimumEnable := "Interval Option" = "Interval Option"::Minimum;
        MaximumEnable := "Interval Option" = "Interval Option"::Maximum;
    end;

    local procedure IntervalIntervalOptionOnValida()
    begin
        ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure MinimumIntervalOptionOnValidat()
    begin
        ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure MaximumIntervalOptionOnValidat()
    begin
        ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure HighLowAnswerOptionOnValidate()
    begin
        ValidateAnswerOption();
        UpdateCntrls();
    end;

    local procedure ABCAnswerOptionOnValidate()
    begin
        ValidateAnswerOption();
        UpdateCntrls();
    end;

    local procedure CustomAnswerOptionOnValidate()
    begin
        ValidateAnswerOption();
        ShowAnswers();
        UpdateCntrls();
    end;
}

