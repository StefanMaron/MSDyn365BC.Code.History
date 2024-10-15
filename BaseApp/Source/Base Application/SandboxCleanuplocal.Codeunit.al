codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 1882, 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    begin
    end;
}

