codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearCompanyConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text)
    var
        GovTalkSetup: Record "GovTalk Setup";
        nullGUID: Guid;
    begin
        GovTalkSetup.ModifyAll(Password, nullGUID);
    end;
}

