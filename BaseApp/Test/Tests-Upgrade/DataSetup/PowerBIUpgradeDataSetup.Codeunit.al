codeunit 132863 "PowerBI Upgrade Data Setup"
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

        MediaRepository.Reset();
        MediaRepository.Init();
        MediaRepository."File Name" := 'PowerBi-OptIn-480px.png';
        MediaRepository."Display Target" := Format(ClientType::Web);
        if MediaRepository.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupPowerBIWorkspacesData()
    var
        PowerBIReportConfiguration: Record "Power BI Report Configuration";
        I: Integer;
    begin
        if PowerBIReportConfiguration.Count >= 100 then
            exit;

        for I := 0 to 100 do begin
            PowerBIReportConfiguration.Init();
            PowerBIReportConfiguration.Context := CopyStr(CreateGuid(), 1, MaxStrLen(PowerBIReportConfiguration.Context));
            PowerBIReportConfiguration."User Security ID" := CreateGuid();
            PowerBIReportConfiguration."Report ID" := CreateGuid();
            PowerBIReportConfiguration.ReportEmbedUrl := StrSubstNo('http://microsoft.com/%1', I);
            PowerBIReportConfiguration.Insert();
        end;
    end;

}
