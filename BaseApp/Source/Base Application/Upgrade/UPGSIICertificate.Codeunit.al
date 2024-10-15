codeunit 104103 "UPG SII Certificate"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;
         
        MoveCertificateFromBlobToIsolatedStorage();
    end;

    local procedure MoveCertificateFromBlobToIsolatedStorage()
    var
        SIISetup: Record "SII Setup";
        IsolatedCertificate: Record "Isolated Certificate";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        TempBlob: Codeunit "Temp Blob";
        CertificateManagement: Codeunit "Certificate Management";
        MoveCertificate: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateSIICertificateTag()) then
            exit;

        if SIISetup.Get() then begin
            SIISetup.Calcfields(Certificate);
            MoveCertificate := SIISetup.Certificate.HasValue();
        end;
        if MoveCertificate then begin
            IsolatedCertificate.Insert(true);
            TempBlob.FromRecord(SIISetup, SIISetup.FieldNo(Certificate));
            CertificateManagement.SetCertPassword(SIISetup.Password);
            CertificateManagement.InitIsolatedCertificateFromBlob(IsolatedCertificate, TempBlob);
            IsolatedCertificate.Modify(true);
            SIISetup."Certificate Code" := IsolatedCertificate.Code;
            Clear(SIISetup.Certificate);
            SIISetup.Password := '';
            SIISetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateSIICertificateTag());
    end;
}