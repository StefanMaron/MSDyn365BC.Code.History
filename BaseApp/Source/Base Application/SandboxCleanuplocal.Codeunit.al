codeunit 1883 "Sandbox Cleanup local"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sandbox Cleanup", 'OnClearCompanyConfiguration', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text)
    begin
    end;
}

