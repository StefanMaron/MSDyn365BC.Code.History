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
                        Hyperlink(LearnMoreUrl1Lbl);
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
                    Caption = 'One more thing...';
                    Style = Strong;
                }

                label(SecondPageLbl)
                {
                    ApplicationArea = All;
                    Caption = 'We''ve renamed some features to make them easier to find. The "Navigate" action is now "Find Entries", and the "Navigate" menu on the action bar is now "Related".';
                }

                field(LearnMoreLbl2; LearnMoreLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = 'Learn more';
                    ToolTip = 'Click here to learn more about the new and improved features.';

                    trigger OnDrillDown()
                    begin
                        Hyperlink(LearnMoreUrl2Lbl);
                    end;
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
        LearnMoreUrl1Lbl: Label 'https://go.microsoft.com/fwlink/?linkid=2116962', Locked = true;
        LearnMoreUrl2Lbl: Label 'https://go.microsoft.com/fwlink/?linkid=2140502', Locked = true;

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