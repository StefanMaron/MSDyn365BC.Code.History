codeunit 8896 "Open Mail Setup Page"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'This codeunit will not be needed after the full transition to the email module';
    ObsoleteTag = '17.0';

    /// <summary>
    /// Open the relevant page for setting up email. Use this function for role center pages that need to reference email setup.
    /// </summary>
    trigger OnRun()
    var
        EmailFeature: Codeunit "Email Feature";
    begin
        if EmailFeature.IsEnabled() then
            Page.Run(Page::"Email Accounts")
        else
            Page.Run(Page::"SMTP Mail Setup");
    end;
}