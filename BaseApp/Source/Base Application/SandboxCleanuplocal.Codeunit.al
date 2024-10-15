codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
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

