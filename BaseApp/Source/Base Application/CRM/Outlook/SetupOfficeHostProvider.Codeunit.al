namespace Microsoft.CRM.Outlook;

using Microsoft.Foundation.Company;

codeunit 1634 "Setup Office Host Provider"
{

    trigger OnRun()
    begin
        InitSetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure InitSetup()
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        if not OfficeAddinSetup.IsEmpty() then
            exit;

        OfficeAddinSetup.Init();
        OfficeAddinSetup.Insert();
    end;
}

