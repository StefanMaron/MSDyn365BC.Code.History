codeunit 8648 "Company Setup Notification"
{
    Access = Internal;

    procedure OpenCompanyInformationPage(N: Notification)
    var
    begin
        Page.RunModal(Page::"Company Information");
    end;

    procedure OpenCostingMethodConfigurationPage(N: Notification)
    var
    begin
        Page.RunModal(Page::"Costing Method Configuration");
    end;
}