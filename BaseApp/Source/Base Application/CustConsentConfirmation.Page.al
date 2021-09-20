page 1820 "Cust. Consent Confirmation"
{
    Caption = 'Customer Consent Confirmation';
    InstructionalText = 'An action is requested regarding the customer consent.';
    PageType = ConfirmationDialog;
    RefreshOnActivate = true;
    Editable = false;

    layout
    {
        area(content)
        {
            field(ConsentText; ConsentTxt)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
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

    var
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=724009';
        ConsentTxt: Label 'By enabling this feature, you consent to your data being shared with third party systems and flowing outside of your organization''s selected geographic boundaries.  You control what data, if any, that you provide to the third-party. The third party may not meet the same compliance and security standards as Microsoft Dynamics 365 Business Central. Your privacy is important to us.  To learn more follow the link below.';
        LearnMoreTok: Label 'Learn more';

}