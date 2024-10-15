codeunit 144205 "HRP Personified Reporting"
{
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ---------------------------------------------------------------------------------------------------------

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryHRP: Codeunit "Library - HRP";
        LibraryRandom: Codeunit "Library - Random";
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        TranslatePayroll: Codeunit "Translate Payroll";
        FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4;
        IsInitialized: Boolean;
        BonusMonthlyAmtTxt: Label 'BONUS MONTHLY AMT', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ExportADV1toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, false, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        PersonifiedAccountingMgt.ADV1toXML(Employee, PayrollPeriod."Ending Date", 1, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSPV1toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        CompanyPackNo: Integer;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, false, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        CompanyPackNo := 1;
        PersonifiedAccountingMgt.SVFormToXML(
          FormType::SPV_1, Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, CompanyPackNo, 1, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSZV61toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        CompanyPackNo: Integer;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, true, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        CompanyPackNo := 1;
        PersonifiedAccountingMgt.SVFormToXML(
          FormType::SZV_6_1, Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, CompanyPackNo, 1, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSZV62toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        CompanyPackNo: Integer;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, true, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        CompanyPackNo := 1;
        PersonifiedAccountingMgt.SVFormToXML(
          FormType::SZV_6_2, Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, CompanyPackNo, 1, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSZV63toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        CompanyPackNo: Integer;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, true, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        CompanyPackNo := 1;
        PersonifiedAccountingMgt.SVFormToXML(
          FormType::SZV_6_3, Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, CompanyPackNo, 1, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSZV64toXML()
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
        CompanyPackNo: Integer;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, true, false);

        // WHEN
        Employee.SetRecFilter;

        // THEN
        CompanyPackNo := 1;
        PersonifiedAccountingMgt.SVFormToXML(
          FormType::SZV_6_4, Employee, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, CompanyPackNo, 1, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportRSVtoXML()
    var
        Employee: Record Employee;
        Person: Record Person;
        PayrollPeriod: Record "Payroll Period";
        TempPackPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        RSVDetailedXMLExport: Codeunit "RSV Detailed XML Export";
        RSVCommonXMLExport: Codeunit "RSV Common XML Export";
        FileManagement: Codeunit "File Management";
        FolderName: Text;
    begin
        Initialize;

        // GIVEN
        CreatePersonSetup(Employee, PayrollPeriod, true, false);

        // WHEN
        Person.SetRange("No.", Employee."Person No.");
        FolderName := FileManagement.CreateClientTempSubDirectory;

        // THEN
        RSVDetailedXMLExport.SetSkipExport(true);
        RSVDetailedXMLExport.ExportDetailedXML(
          Person, TempPackPayrollReportingBuffer, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", 0, FolderName);
        RSVCommonXMLExport.SetSkipExport(true);
        RSVCommonXMLExport.ExportCommonXML(
          Person, TempPackPayrollReportingBuffer, PayrollPeriod."Starting Date", PayrollPeriod."Ending Date",
          PayrollPeriod."Ending Date", FolderName);
    end;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);
        if IsInitialized then
            exit;

        PersonifiedAccountingMgt.SetTestMode(true);

        IsInitialized := true;
        Commit();
    end;

    local procedure CreatePersonSetup(var Employee: Record Employee; var PayrollPeriod: Record "Payroll Period"; Disability: Boolean; Absence: Boolean)
    var
        EmployeeJournalLine: Record "Employee Journal Line";
        PersonMedicalInfo: Record "Person Medical Info";
        Counter: Integer;
    begin
        FindPayrollPeriodByMonth(1, PayrollPeriod);
        // CreateEmployee with salary 30000
        Employee.Get(LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", 30000));
        if Disability then
            LibraryHRP.CreatePersonMedicalInfo(
              PersonMedicalInfo, Employee."Person No.", PersonMedicalInfo.Type::Disability, PersonMedicalInfo.Privilege::" ",
              PersonMedicalInfo."Disability Group"::"2", PayrollPeriod."Starting Date");

        if Absence then; // TODO

        // for the 3 month of the first quarter calculate and post salary
        PayrollPeriod.Reset();
        PayrollPeriod.SetRange("Starting Date", PayrollPeriod."Starting Date", CalcDate('<+2M>', PayrollPeriod."Starting Date"));
        PayrollPeriod.FindSet();
        repeat
            Counter += 1;

            // for second month add bonus 600000 to exceed FSI limit
            if Counter = 2 then
                LibraryHRP.CreateEmplJnlLine(
                  EmployeeJournalLine, PayrollPeriod, Employee."No.", TranslatePayroll.ElementCode(BonusMonthlyAmtTxt),
                  600000, PayrollPeriod."Ending Date", true);

            CreatePostPayrollDoc(Employee."No.", PayrollPeriod);
        until PayrollPeriod.Next = 0;
    end;

    local procedure CreatePostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period")
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
    end;

    local procedure FindPayrollPeriodByMonth(MonthNo: Integer; var PayrollPeriod: Record "Payroll Period")
    begin
        // find first period after closed year
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);

        // find period by month
        PayrollPeriod.FilterGroup(2);
        PayrollPeriod.SetFilter("Starting Date", '>=%1', PayrollPeriod."Starting Date");
        PayrollPeriod.FilterGroup(0);
        PayrollPeriod.SetRange("Starting Date",
          DMY2Date(1, MonthNo, Date2DMY(PayrollPeriod."Starting Date", 3)));
        PayrollPeriod.FindFirst;
    end;
}

