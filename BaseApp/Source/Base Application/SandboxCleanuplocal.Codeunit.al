codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        if CompanyToBlock <> '' then begin
            ElecTaxDeclarationSetup.ChangeCompany(CompanyToBlock);
            ElecTaxDeclarationSetup.ModifyAll("Digipoort Client Cert. Name", '');
            ElecTaxDeclarationSetup.ModifyAll("Digipoort Service Cert. Name", '');
            ElecTaxDeclarationSetup.ModifyAll("Digipoort Delivery URL", '');
            ElecTaxDeclarationSetup.ModifyAll("Digipoort Status URL", '');
        end;
    end;
}

