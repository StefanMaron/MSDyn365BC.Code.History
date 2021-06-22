codeunit 6304 "Setup Azure AD Mgt. Provider"
{

    trigger OnRun()
    begin
        InitSetup;
    end;

    [EventSubscriber(ObjectType::Codeunit, 2, 'OnCompanyInitialize', '', false, false)]
    local procedure InitSetup()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
    begin
        with AzureADMgtSetup do
            if IsEmpty then begin
                Init;
                ResetToDefault;
                Insert;
            end else begin
                Init;
                ResetToDefault;
                Modify;
            end;
    end;
}

