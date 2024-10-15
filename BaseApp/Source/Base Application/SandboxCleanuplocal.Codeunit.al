codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearCompanyConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Client Cert. Name", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Service Cert. Name", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Delivery URL", '');
        ElecTaxDeclarationSetup.ModifyAll("Digipoort Status URL", '');
    end;
}

