/// <summary>
/// What's New Wizard is shown to all users on tenants upgraded to 16 and new tenants on 16.
/// </summary>
page 896 "What's New Wizard"
{
    PageType = NavigatePage;
    Extensible = false;
    Caption = ' '; // Do not show the caption
    ObsoleteState = Pending;
    ObsoleteReason = 'Temporary solution';
    ObsoleteTag = '16.0';

    layout
    {
        area(Content)
        {
            group(PageOne)
            {
                ShowCaption = false;
                Visible = Step = Step::First;

                field("FirstBanner"; FirstBanner."Media Reference")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = ' ';
                }

                label(StepOne)
                {
                    ApplicationArea = All;
                    Caption = 'Step 1 of 2';
                    Style = StandardAccent;
                }

                label(Welcome)
                {
                    ApplicationArea = All;
                    Caption = 'Welcome';
                    Style = Strong;
                }

                label(FirstPage)
                {
                    ApplicationArea = All;
                    Caption = 'We have added new features and improved others, thanks to input from the Business Central community.';
                }

                field(LearnMoreLbl; LearnMoreLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = 'Learn more';
                    ToolTip = 'Click here to learn more about the new and improved features.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(LearnMoreUrlLbl);
                    end;
                }
            }
            group(PageTwo)
            {
                ShowCaption = false;
                Visible = Step = Step::Second;

                field("SecondBanner"; SecondBanner."Media Reference")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = ' ';
                }

                label(StepTwo)
                {
                    ApplicationArea = All;
                    Caption = 'Step 2 of 2';
                    Style = StandardAccent;
                }

                label(SettingsLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Settings';
                    Style = Strong;
                }

                label(SecondPageLbl)
                {
                    ApplicationArea = All;
                    Caption = 'You can now find all your settings in one place. Choose the Settings icon at the top right area of your screen.';
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
                ApplicationArea = All;
                Caption = 'Back';
                Image = PreviousRecord;
                InFooterBar = true;
                ToolTip = 'Back';
                Visible = Step = Step::Second;

                trigger OnAction()
                begin
                    Step := Step::First;
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Next';
                Visible = Step = Step::First;

                trigger OnAction()
                begin
                    Step := Step::Second;
                end;
            }
            action(ActionGotIt)
            {
                ApplicationArea = All;
                Caption = 'Got it';
                Image = NextRecord;
                InFooterBar = true;
                ToolTip = 'Got it';
                Visible = Step = Step::Second;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        FirstBanner: Record "Media Resources";
        SecondBanner: Record "Media Resources";
        Step: Option First,Second;
        LearnMoreLbl: Label 'Learn more';
        LearnMoreUrlLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2116962', Locked = true;

    trigger OnInit()
    begin
        LoadBanner();
        Step := Step::First;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Update(true);
    end;

    local procedure LoadBanner()
    begin
        if FirstBanner.Get('WHATSNEWWIZARD-BANNER-FIRST.PNG') then;
        if SecondBanner.Get('WHATSNEWWIZARD-BANNER-SECOND.PNG') then;
    end;
}