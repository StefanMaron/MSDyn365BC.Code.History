codeunit 144036 "ERM REP CNAE"
{
    // Test for feature - CNAE - Reports.
    //  1. Verify CNAE Description on Company Information Card, Update Company Information - CNAE Description.
    //  2. Verify Company Information - Name and Address. Create Normalized Account and Run Report - 10717 Normalized Account Schedule.
    // 
    // Covers Test Cases for WI - 351133.
    // -----------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // -----------------------------------------------------------------------------
    // NormalizedAccountScheduleReportForUpdatedCompanyInfo                 156907
    // CNAEDescriptionOnCompanyInformationCard                              151552

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        AccountScheduleNameCap: Label 'Acc__Schedule_Name_Name';
        CompanyNameCap: Label 'CompName_1_';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('NormalizedAccountScheduleRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NormalizedAccountScheduleReportForUpdatedCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationName: Text;
        AccountScheduleName: Code[10];
    begin
        // Verify Company Information - Name and Address. Create Normalized Account and Run Report - 10717 Normalized Account Schedule.

        // Setup: Update Company Information - Name, Address and Address to length - 50, Create Account Schedule.
        CompanyInformationName := GenerateRandomCode(50);  // Number of Digit - 50.
        UpdateCompanyInformationNameAndAddress(CompanyInformation, CompanyInformationName, CompanyInformationName, CompanyInformationName);
        AccountScheduleName := CreateAccountSchedule;

        // Exercise.
        RunNormalizedAccountScheduleReport(AccountScheduleName);  // Opens handler - NormalizedAccountScheduleRequestPageHandler.

        // Verify: Verify Account Schedule Name and Company Information - Name on generated XML of Report - Normalized Account Schedule.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(AccountScheduleNameCap, AccountScheduleName);
        LibraryReportDataset.AssertElementWithValueExists(CompanyNameCap, CompanyInformationName);

        // TearDown.
        UpdateCompanyInformationNameAndAddress(
          CompanyInformation, CompanyInformation.Name, CompanyInformation.Address, CompanyInformation."Address 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CNAEDescriptionOnCompanyInformationCard()
    var
        CompanyInformation: TestPage "Company Information";
        CNAEDescription: Text;
        OldCNAEDescription: Text;
    begin
        // Verify CNAE Description on Company Information card, Update Company Information - CNAE Description.

        // Setup: Update Company Information - CNAE Description to length - 80.
        CNAEDescription := GenerateRandomCode(80);  // Number of Digit - 80.

        // Exercise.
        OldCNAEDescription := UpdateCompanyInformationCNAEDescription(CNAEDescription);

        // Verify: Verify CNAE Description with CNAE Description field on Company Information Card.
        CompanyInformation.OpenEdit;
        CompanyInformation."CNAE Description".AssertEquals(CNAEDescription);
        CompanyInformation.Close;

        // TearDown.
        UpdateCompanyInformationCNAEDescription(OldCNAEDescription);
    end;

    local procedure CreateAccountSchedule(): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        AccScheduleName.Validate("Default Column Layout", ColumnLayoutName.Name);
        AccScheduleName.Validate(Standardized, true);
        AccScheduleName.Modify(true);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Date Filter", WorkDate);
        AccScheduleLine.Modify(true);
        exit(AccScheduleLine."Schedule Name");
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) ElectronicCode: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            ElectronicCode := InsStr(ElectronicCode, Format(LibraryRandom.RandInt(9)), Counter);  // Random value of 1 digit required.
    end;

    local procedure RunNormalizedAccountScheduleReport(Name: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
        NormalizedAccountSchedule: Report "Normalized Account Schedule";
    begin
        Clear(NormalizedAccountSchedule);
        AccScheduleName.SetRange(Name, Name);
        Commit;  // Commit is required to run report - Normalized Account Schedule.
        NormalizedAccountSchedule.SetTableView(AccScheduleName);
        NormalizedAccountSchedule.Run;  // Opens handler - NormalizedAccountScheduleRequestPageHandler.
    end;

    local procedure UpdateCompanyInformationCNAEDescription(CNAEDescription: Text) OldCompanyInformationCNAEDescription: Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        OldCompanyInformationCNAEDescription := CompanyInformation."CNAE Description";
        CompanyInformation.Validate("CNAE Description", CNAEDescription);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanyInformationNameAndAddress(var TempCompanyInformation: Record "Company Information" temporary; Name: Text; Address: Text; Address2: Text): Text[50]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        TempCompanyInformation := CompanyInformation;
        CompanyInformation.Validate(Name, Name);
        CompanyInformation.Validate(Address, Address);
        CompanyInformation.Validate("Address 2", Address2);
        CompanyInformation.Modify(true);
        exit(CompanyInformation.Name);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NormalizedAccountScheduleRequestPageHandler(var NormalizedAccountSchedule: TestRequestPage "Normalized Account Schedule")
    begin
        NormalizedAccountSchedule."Acc. Schedule Line".SetFilter("Date Filter", Format(WorkDate));
        NormalizedAccountSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

