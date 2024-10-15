codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Deploymt. Cleanup", 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    var
        GovTalkSetup: Record "GovTalk Setup";
        nullGUID: Guid;
    begin
        if CompanyToBlock <> '' then begin
            GovTalkSetup.ChangeCompany(CompanyToBlock);
            GovTalkSetup.ModifyAll(Password, nullGUID);
        end;
    end;
}

