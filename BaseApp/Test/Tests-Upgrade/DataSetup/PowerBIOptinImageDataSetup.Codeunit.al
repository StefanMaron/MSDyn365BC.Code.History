codeunit 132863 "PowerBI Optin Image Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure SetupPowerBIOptinImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        MediaRepository.SetFilter("Display Target", '<>%1', Format(ClientType::Web));
        MediaRepository.SetRange("File Name", 'PowerBi-OptIn-480px.png');
        MediaRepository.DeleteAll();
    end;

}
