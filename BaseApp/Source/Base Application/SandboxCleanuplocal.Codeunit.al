codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    var
        SIISetup: Record "SII Setup";
    begin
        if CompanyToBlock <> '' then begin
            SIISetup.ChangeCompany(CompanyToBlock);
            SIISetup.ModifyAll(Enabled, false);
        end;
    end;
}

