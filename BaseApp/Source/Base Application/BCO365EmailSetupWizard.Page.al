page 2397 "BC O365 Email Setup Wizard"
{
    Caption = 'Email Setup';
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with "Email Account Wizard" from "System Application".';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            part(EmailSettingsWizardPage; "BC O365 Email Account Settings")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.EmailSettingsWizardPage.PAGE.LookupMode(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::LookupOK, ACTION::OK] then
            ValidateAndStoreSetup;
    end;

    local procedure ValidateAndStoreSetup()
    begin
        CurrPage.EmailSettingsWizardPage.PAGE.ValidateSettings(false);
        CurrPage.EmailSettingsWizardPage.PAGE.StoreSMTPSetup;
    end;
}

