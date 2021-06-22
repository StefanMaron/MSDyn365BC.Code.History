codeunit 130410 "Sys. Warmup Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"Sys. Warmup Scenarios");
    end;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterCompanyOpen', '', true, true)]
    local procedure WarmUpOnAfterCompanyOpen()
    var
        O365GettingStarted: Record "O365 Getting Started";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not GuiAllowed then
            exit;

        if not CompanyInformationMgt.IsDemoCompany then
            exit;

        if not EnvironmentInfo.IsSaaS then
            exit;

        if not O365GettingStarted.IsEmpty then
            exit;

        if not TASKSCHEDULER.CanCreateTask then
            exit;

        TASKSCHEDULER.CreateTask(CODEUNIT::"Sys. Warmup Test Runner", 0, true, CompanyName, CurrentDateTime + 10000); // Add 10s
    end;
}

