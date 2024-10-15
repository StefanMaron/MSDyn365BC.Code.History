namespace System.Privacy;

page 1822 "Consent Microsoft Confirm"
{
    Caption = 'Please review terms and conditions';
    PageType = NavigatePage;
    Editable = false;

    layout
    {
        area(content)
        {


            group(Control1)
            {
                InstructionalText = 'By enabling this feature, you consent to your data being shared with a Microsoft service that might be outside of your organization''s selected geographic boundaries and might have different compliance and security standards than Microsoft Dynamics Business Central. Your privacy is important to us, and you can choose whether to share data with the service. To learn more, follow the link below.';
                ShowCaption = false;
            }

            field(LearnMore; LearnMoreTok)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Caption = ' ';
                ToolTip = 'View information about the privacy.';

                trigger OnDrillDown()
                begin
                    Hyperlink(PrivacyLinkTxt);
                end;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Accept)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'I accept';
                ToolTip = 'Agree to the terms and conditions.';
                Image = Confirm;
                InFooterBar = true;

                trigger OnAction();
                begin
                    Agreed := true;
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                ToolTip = 'Disagree with the terms and conditions.';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction();
                begin
                    Agreed := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';
        LearnMoreTok: Label 'Privacy and Cookies';
        Agreed: Boolean;

    procedure WasAgreed(): Boolean
    begin
        exit(Agreed);
    end;

}