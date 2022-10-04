codeunit 8624 "Setup Company Name"
{
    TableNo = "Company Information";

    trigger OnRun()
    begin
        Validate(Name, CompanyName);
        Validate("Ship-to Name", CompanyName);
        Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Table Processing Rule", 'OnDoesTableHaveCustomRuleInRapidStart', '', false, false)]
    local procedure CheckCompanyInformationOnDoesTableHaveCustomRuleInRapidStart(TableID: Integer; var Result: Boolean)
    begin
        if TableID = DATABASE::"Company Information" then
            Result := true;
    end;
}

