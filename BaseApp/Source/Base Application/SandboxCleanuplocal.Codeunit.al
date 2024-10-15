codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    var
        CertificateCZ: Record "Certificate CZ";
        nullGUID: Guid;
    begin
        if CompanyToBlock <> '' then begin
            CertificateCZ.ChangeCompany(CompanyToBlock);
            CertificateCZ.ModifyAll("Certificate Key", nullGUID);
        end;
    end;
}

