codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Deploymt. Cleanup", 'OnClearConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyToBlock: Text)
    begin
    end;
}

