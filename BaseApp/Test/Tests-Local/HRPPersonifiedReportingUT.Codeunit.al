codeunit 144209 "HRP Personified Reporting UT"
{
    // ---------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // ---------------------------------------------------------------------------------------------------------
    // PayrollRepBufMultiplePacks_UT1                                                                   360787
    // PayrollRepBufMultiplePacks_UT2                                                                   360787
    // PayrollRepBufMultiplePacks_UT3                                                                   360787
    // PayrollRepBufMultiplePacks_UT4                                                                   360787
    // PayrollRepBufMultiplePacks_UT5                                                                   360787

    Subtype = Test;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
        RSVCalculationMgt: Codeunit "RSV Calculation Mgt.";
        IsInitialized: Boolean;
        WrongRecordsCntErr: Label 'Wrong records count in table %1.', Comment = '%1 = Table Name';
        PayrollRepBufAmountErr: Label 'Wrong Amount in Payroll Reporting Buffer. Amount No. = %1.', Comment = '%1 = Column No.';
        IncorrectPackCountErr: Label 'Incorrect count of packs.';

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT1_0()
    begin
        PayrollRepBuf_UT1(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT1_1()
    begin
        PayrollRepBuf_UT1(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT1_2()
    begin
        PayrollRepBuf_UT1(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT1_3()
    begin
        PayrollRepBuf_UT1(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT2_0()
    begin
        PayrollRepBuf_UT2(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT2_1()
    begin
        PayrollRepBuf_UT2(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT2_2()
    begin
        PayrollRepBuf_UT2(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT2_3()
    begin
        PayrollRepBuf_UT2(3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_1()
    begin
        PayrollRepBuf_UT3(0, 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_2()
    begin
        PayrollRepBuf_UT3(0, 2, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_3()
    begin
        PayrollRepBuf_UT3(0, 3, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_4()
    begin
        PayrollRepBuf_UT3(0, 4, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_5()
    begin
        PayrollRepBuf_UT3(0, 5, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_6()
    begin
        PayrollRepBuf_UT3(0, 6, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_7()
    begin
        PayrollRepBuf_UT3(0, 7, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_8()
    begin
        PayrollRepBuf_UT3(0, 8, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_9()
    begin
        PayrollRepBuf_UT3(0, 9, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_10()
    begin
        PayrollRepBuf_UT3(0, 10, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_11()
    begin
        PayrollRepBuf_UT3(0, 11, 2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_0_12()
    begin
        PayrollRepBuf_UT3(0, 12, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_1()
    begin
        PayrollRepBuf_UT3(1, 1, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_2()
    begin
        PayrollRepBuf_UT3(1, 2, 2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_3()
    begin
        PayrollRepBuf_UT3(1, 3, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_4()
    begin
        PayrollRepBuf_UT3(1, 4, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_5()
    begin
        PayrollRepBuf_UT3(1, 5, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_6()
    begin
        PayrollRepBuf_UT3(1, 6, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_7()
    begin
        PayrollRepBuf_UT3(1, 7, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_8()
    begin
        PayrollRepBuf_UT3(1, 8, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_9()
    begin
        PayrollRepBuf_UT3(1, 9, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_10()
    begin
        PayrollRepBuf_UT3(1, 10, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_11()
    begin
        PayrollRepBuf_UT3(1, 11, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_1_12()
    begin
        PayrollRepBuf_UT3(1, 12, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_1()
    begin
        PayrollRepBuf_UT3(2, 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_2()
    begin
        PayrollRepBuf_UT3(2, 2, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_3()
    begin
        PayrollRepBuf_UT3(2, 3, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_4()
    begin
        PayrollRepBuf_UT3(2, 4, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_5()
    begin
        PayrollRepBuf_UT3(2, 5, 2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_6()
    begin
        PayrollRepBuf_UT3(2, 6, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_7()
    begin
        PayrollRepBuf_UT3(2, 7, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_8()
    begin
        PayrollRepBuf_UT3(2, 8, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_9()
    begin
        PayrollRepBuf_UT3(2, 9, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_10()
    begin
        PayrollRepBuf_UT3(2, 10, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_11()
    begin
        PayrollRepBuf_UT3(2, 11, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_2_12()
    begin
        PayrollRepBuf_UT3(2, 12, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_1()
    begin
        PayrollRepBuf_UT3(3, 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_2()
    begin
        PayrollRepBuf_UT3(3, 2, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_3()
    begin
        PayrollRepBuf_UT3(3, 3, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_4()
    begin
        PayrollRepBuf_UT3(3, 4, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_5()
    begin
        PayrollRepBuf_UT3(3, 5, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_6()
    begin
        PayrollRepBuf_UT3(3, 6, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_7()
    begin
        PayrollRepBuf_UT3(3, 7, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_8()
    begin
        PayrollRepBuf_UT3(3, 8, 2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_9()
    begin
        PayrollRepBuf_UT3(3, 9, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_10()
    begin
        PayrollRepBuf_UT3(3, 10, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_11()
    begin
        PayrollRepBuf_UT3(3, 11, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT3_3_12()
    begin
        PayrollRepBuf_UT3(3, 12, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_1()
    begin
        PayrollRepBuf_UT4(0, 1, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_2()
    begin
        PayrollRepBuf_UT4(0, 2, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_3()
    begin
        PayrollRepBuf_UT4(0, 3, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_4()
    begin
        PayrollRepBuf_UT4(0, 4, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_5()
    begin
        PayrollRepBuf_UT4(0, 5, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_6()
    begin
        PayrollRepBuf_UT4(0, 6, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_7()
    begin
        PayrollRepBuf_UT4(0, 7, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_8()
    begin
        PayrollRepBuf_UT4(0, 8, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_9()
    begin
        PayrollRepBuf_UT4(0, 9, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_10()
    begin
        PayrollRepBuf_UT4(0, 10, 4, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_11()
    begin
        PayrollRepBuf_UT4(0, 11, 4, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_0_12()
    begin
        PayrollRepBuf_UT4(0, 12, 4, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_1()
    begin
        PayrollRepBuf_UT4(1, 1, 4, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_2()
    begin
        PayrollRepBuf_UT4(1, 2, 4, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_3()
    begin
        PayrollRepBuf_UT4(1, 3, 4, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_4()
    begin
        PayrollRepBuf_UT4(1, 4, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_5()
    begin
        PayrollRepBuf_UT4(1, 5, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_6()
    begin
        PayrollRepBuf_UT4(1, 6, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_7()
    begin
        PayrollRepBuf_UT4(1, 7, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_8()
    begin
        PayrollRepBuf_UT4(1, 8, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_9()
    begin
        PayrollRepBuf_UT4(1, 9, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_10()
    begin
        PayrollRepBuf_UT4(1, 10, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_11()
    begin
        PayrollRepBuf_UT4(1, 11, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_1_12()
    begin
        PayrollRepBuf_UT4(1, 12, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_1()
    begin
        PayrollRepBuf_UT4(2, 1, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_2()
    begin
        PayrollRepBuf_UT4(2, 2, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_3()
    begin
        PayrollRepBuf_UT4(2, 3, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_4()
    begin
        PayrollRepBuf_UT4(2, 4, 4, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_5()
    begin
        PayrollRepBuf_UT4(2, 5, 4, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_6()
    begin
        PayrollRepBuf_UT4(2, 6, 4, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_7()
    begin
        PayrollRepBuf_UT4(2, 7, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_8()
    begin
        PayrollRepBuf_UT4(2, 8, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_9()
    begin
        PayrollRepBuf_UT4(2, 9, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_10()
    begin
        PayrollRepBuf_UT4(2, 10, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_11()
    begin
        PayrollRepBuf_UT4(2, 11, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_2_12()
    begin
        PayrollRepBuf_UT4(2, 12, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_1()
    begin
        PayrollRepBuf_UT4(3, 1, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_2()
    begin
        PayrollRepBuf_UT4(3, 2, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_3()
    begin
        PayrollRepBuf_UT4(3, 3, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_4()
    begin
        PayrollRepBuf_UT4(3, 4, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_5()
    begin
        PayrollRepBuf_UT4(3, 5, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_6()
    begin
        PayrollRepBuf_UT4(3, 6, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_7()
    begin
        PayrollRepBuf_UT4(3, 7, 4, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_8()
    begin
        PayrollRepBuf_UT4(3, 8, 4, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_9()
    begin
        PayrollRepBuf_UT4(3, 9, 4, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_10()
    begin
        PayrollRepBuf_UT4(3, 10, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_11()
    begin
        PayrollRepBuf_UT4(3, 11, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT4_3_12()
    begin
        PayrollRepBuf_UT4(3, 12, 2, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBuf_UT5()
    var
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempPerson: Record Person temporary;
        Person: Record Person;
        StartDate: Date;
        EndDate: Date;
        PersonNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 109050] Verify several Employees per person are combined
        Initialize;
        GetReportPeriod(StartDate, EndDate, 0);

        // [GIVEN] Several Persons with several Employees per each Person
        for i := 1 to 10 + LibraryRandom.RandInt(10) do begin
            PersonNo := MockPerson;
            Person.Get(PersonNo);
            TempPerson := Person;
            TempPerson.Insert();
            for i := 1 to (10 + LibraryRandom.RandInt(10)) do
                MockEmployee(PersonNo);
        end;

        // [WHEN] Create Reporting Export Buffer
        RSVCalculationMgt.CalcDetailedBuffer(TempPayrollReportingBuffer, TempTotalPayrollReportingBuffer, TempPerson, StartDate, EndDate);

        // [THEN] Reporting Buffer record's count corresponds to Person's count
        Assert.AreEqual(
          TempPerson.Count, TempPayrollReportingBuffer.Count,
          StrSubstNo(WrongRecordsCntErr, TempPayrollReportingBuffer.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBufMultiplePacks_UT1()
    begin
        // [SCENARIO 360787.1] Person per Pack = '0', No Of Persons = 0, No Of Packs = 0

        PayrollRepBufMultiplePacks_UT(0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBufMultiplePacks_UT2()
    var
        NoOfPersons: Integer;
    begin
        // [SCENARIO 360787.2] Person per Pack = 'X', No Of Persons = X - 1, No Of Packs = 1

        NoOfPersons := RSVCalculationMgt.MaxNoOfPersonsPerRSVFile - 1;
        PayrollRepBufMultiplePacks_UT(NoOfPersons, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBufMultiplePacks_UT3()
    var
        NoOfPersons: Integer;
    begin
        // [SCENARIO 360787.3] Person per Pack = 'X', No Of Persons = X, No Of Packs = 1

        NoOfPersons := RSVCalculationMgt.MaxNoOfPersonsPerRSVFile;
        PayrollRepBufMultiplePacks_UT(NoOfPersons, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBufMultiplePacks_UT4()
    var
        NoOfPersons: Integer;
    begin
        // [SCENARIO 360787.4] Person per Pack = 'X', No Of Persons = X + 1, No Of Packs = 2

        NoOfPersons := RSVCalculationMgt.MaxNoOfPersonsPerRSVFile + 1;
        PayrollRepBufMultiplePacks_UT(NoOfPersons, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PayrollRepBufMultiplePacks_UT5()
    var
        NoOfPersons: Integer;
        NoOfPacks: Integer;
    begin
        // [SCENARIO 360787.5] Person per Pack = 'X', No Of Persons = 3 * X, No Of Packs = 3

        NoOfPacks := 3;
        NoOfPersons := NoOfPacks * RSVCalculationMgt.MaxNoOfPersonsPerRSVFile;
        PayrollRepBufMultiplePacks_UT(NoOfPersons, NoOfPacks);
    end;

    local procedure PayrollRepBufMultiplePacks_UT(NoOfPersons: Integer; ExpectedNoOfPacks: Integer)
    var
        Person: Record Person;
        Employee: Record Employee;
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        FirstPersonCode: Code[20];
        PayrollElementCodes: array[8] of Code[20];
        i: Integer;
    begin
        // [GIVEN] 'X' persons with posted payroll entries
        Initialize;
        CreatePayrollSetup(PayrollElementCodes);
        i := 0;
        while i < NoOfPersons do begin
            MockEmployeeWithLaborContract(Employee);
            if FirstPersonCode = '' then
                FirstPersonCode := Employee."Person No.";
            i += 1;
        end;
        Person.SetRange("No.", FirstPersonCode, Employee."Person No.");

        // [WHEN] Create Reporting Export Buffer for 'X' persons
        RSVCalculationMgt.CalcDetailedBuffer(
          TempPayrollReportingBuffer, TempTotalPaidPayrollReportingBuffer, Person, CalcDate('<-CY>', WorkDate), WorkDate);

        // [THEN] The last pack in buffer (count of packs) = rounds up the result of divison X by Y
        Assert.AreEqual(
          ExpectedNoOfPacks, GetLastPackNoInPayrollRepBuffer(TempPayrollReportingBuffer), IncorrectPackCountErr);
    end;

    local procedure PayrollRepBuf_UT1(PeriodNo: Integer)
    var
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        Person: Record Person;
        PayrollElementCodes: array[8] of Code[20];
        Amounts: array[9] of Decimal;
        StartDate: Date;
        EndDate: Date;
        EmployeeNo: Code[20];
        PersonNo: Code[20];
    begin
        // [SCENARIO] Verify single Employee without any payments
        Initialize;
        CreatePayrollSetup(PayrollElementCodes);
        GetReportPeriod(StartDate, EndDate, PeriodNo);

        // [GIVEN] Single Employee without payments
        PersonNo := MockPerson;
        EmployeeNo := MockEmployee(PersonNo);
        GetPayrollAmounts(Amounts, PayrollElementCodes, Format(EmployeeNo), StartDate, EndDate);

        // [WHEN] Run RSV Calc. RepBuf
        Person.SetRange("No.", PersonNo);
        RSVCalculationMgt.CalcDetailedBuffer(TempPayrollReportingBuffer, TempTotalPayrollReportingBuffer, Person, StartDate, EndDate);

        // [THEN] Reporting Buffer has Employee's data with no payments
        Assert.AreEqual(1, TempPayrollReportingBuffer.Count, StrSubstNo(WrongRecordsCntErr, TempPayrollReportingBuffer.TableCaption));
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts, Format(PersonNo), 0, 1, 1);
    end;

    local procedure PayrollRepBuf_UT2(PeriodNo: Integer)
    var
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        Person: Record Person;
        PayrollElementCodes: array[8] of Code[20];
        Amounts: array[9] of Decimal;
        StartDate: Date;
        EndDate: Date;
        EmployeeNo: array[2] of Code[20];
        PersonNo: array[2] of Code[20];
        i: Integer;
    begin
        // [SCENARIO] Verify two Employees without any payments
        Initialize;
        CreatePayrollSetup(PayrollElementCodes);
        GetReportPeriod(StartDate, EndDate, PeriodNo);

        // [GIVEN] Two Employees without payments
        for i := 1 to 2 do begin
            PersonNo[i] := MockPerson;
            EmployeeNo[i] := MockEmployee(PersonNo[i]);
        end;
        GetPayrollAmounts(Amounts, PayrollElementCodes, StrSubstNo('%1|%2', EmployeeNo[1], EmployeeNo[2]), StartDate, EndDate);

        // [WHEN] Run RSV Calc. RepBuf
        Person.SetFilter("No.", '%1|%2', PersonNo[1], PersonNo[2]);
        RSVCalculationMgt.CalcDetailedBuffer(TempPayrollReportingBuffer, TempTotalPayrollReportingBuffer, Person, StartDate, EndDate);

        // [THEN] Reporting Buffer has data for two Employees with no payments
        Assert.AreEqual(2, TempPayrollReportingBuffer.Count, StrSubstNo(WrongRecordsCntErr, TempPayrollReportingBuffer.TableCaption));
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts, StrSubstNo('%1|%2', PersonNo[1], PersonNo[2]), 0, 2, 1);
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts, Format(PersonNo[1]), 0, 1, 1);
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts, Format(PersonNo[2]), 0, 1, 1);
    end;

    local procedure PayrollRepBuf_UT3(PeriodNo: Integer; MonthNo: Integer; ExpTotalRecCnt: Integer; ExpMonthNoValue: Integer)
    var
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        Person: Record Person;
        PayrollElementCodes: array[8] of Code[20];
        Amounts: array[9] of Decimal;
        StartDate: Date;
        EndDate: Date;
        EmployeeNo: Code[20];
        PersonNo: Code[20];
    begin
        // [SCENARIO] Verify single Employee with single payments per payroll element
        Initialize;
        CreatePayrollSetup(PayrollElementCodes);
        GetReportPeriod(StartDate, EndDate, PeriodNo);

        // [GIVEN] Single Employee with payments
        PersonNo := MockPerson;
        EmployeeNo := MockEmployee(PersonNo);
        MockEmployeePayments(PayrollElementCodes, EmployeeNo, GetPostingDate(MonthNo));
        GetPayrollAmounts(Amounts, PayrollElementCodes, Format(EmployeeNo), StartDate, EndDate);

        // [WHEN] Run RSV Calc. RepBuf
        Person.SetRange("No.", PersonNo);
        RSVCalculationMgt.CalcDetailedBuffer(TempPayrollReportingBuffer, TempTotalPayrollReportingBuffer, Person, StartDate, EndDate);

        // [THEN] Reporting Buffer has payment's data for the Employee
        Assert.AreEqual(
          ExpTotalRecCnt, TempPayrollReportingBuffer.Count,
          StrSubstNo(WrongRecordsCntErr, TempPayrollReportingBuffer.TableCaption));
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts, Format(PersonNo), ExpMonthNoValue, 1, 1);
    end;

    local procedure PayrollRepBuf_UT4(PeriodNo: Integer; MonthNo: Integer; ExpTotalRecCnt: Integer; ExpMonthNoValue: Integer)
    var
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        Person: Record Person;
        PayrollElementCodes: array[8] of Code[20];
        AmountsTotal: array[9] of Decimal;
        Amounts1: array[9] of Decimal;
        Amounts2: array[9] of Decimal;
        StartDate: Date;
        EndDate: Date;
        EmployeeNo: array[2] of Code[20];
        PersonNo: array[2] of Code[20];
        i: Integer;
        ExpTotalFilteredCnt: Integer;
    begin
        // [SCENARIO] Verify two Employees with single payments per payroll element
        Initialize;
        CreatePayrollSetup(PayrollElementCodes);
        GetReportPeriod(StartDate, EndDate, PeriodNo);
        ExpTotalFilteredCnt := ExpTotalRecCnt;
        if ExpMonthNoValue <> 0 then
            ExpTotalFilteredCnt /= 2;

        // [GIVEN] Two Employee with payments
        for i := 1 to 2 do begin
            PersonNo[i] := MockPerson;
            EmployeeNo[i] := MockEmployee(PersonNo[i]);
            MockEmployeePayments(PayrollElementCodes, EmployeeNo[i], GetPostingDate(MonthNo));
        end;
        GetPayrollAmounts(AmountsTotal, PayrollElementCodes, StrSubstNo('%1|%2', EmployeeNo[1], EmployeeNo[2]), StartDate, EndDate);
        GetPayrollAmounts(Amounts1, PayrollElementCodes, Format(EmployeeNo[1]), StartDate, EndDate);
        GetPayrollAmounts(Amounts2, PayrollElementCodes, Format(EmployeeNo[2]), StartDate, EndDate);

        // [WHEN] Run RSV Calc. RepBuf
        Person.SetFilter("No.", '%1|%2', PersonNo[1], PersonNo[2]);
        RSVCalculationMgt.CalcDetailedBuffer(TempPayrollReportingBuffer, TempTotalPayrollReportingBuffer, Person, StartDate, EndDate);

        // [THEN] Reporting Export Buffer has payment's data for two Employees
        Assert.AreEqual(
          ExpTotalRecCnt, TempPayrollReportingBuffer.Count,
          StrSubstNo(WrongRecordsCntErr, TempPayrollReportingBuffer.TableCaption));
        VerifyPayrollRepBuf(
          TempPayrollReportingBuffer, AmountsTotal, StrSubstNo('%1|%2', PersonNo[1], PersonNo[2]), ExpMonthNoValue, ExpTotalFilteredCnt, 2);
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts1, Format(PersonNo[1]), ExpMonthNoValue, 1, 1);
        VerifyPayrollRepBuf(TempPayrollReportingBuffer, Amounts2, Format(PersonNo[2]), ExpMonthNoValue, 1, 1);
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

    local procedure CreatePayrollSetup(var PayrollElementCodes: array[8] of Code[20])
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        with HumanResourcesSetup do begin
            Get;
            "PF BASE Element Code" := MockPayrollElement;
            "PF OVER Limit Element Code" := MockPayrollElement;
            "PF INS Limit Element Code" := MockPayrollElement;
            "PF SPECIAL 1 Element Code" := MockPayrollElement;
            "PF SPECIAL 2 Element Code" := MockPayrollElement;
            "PF MI NO TAX Element Code" := MockPayrollElement;
            "TAX PF INS Element Code" := MockPayrollElement;
            "TAX FED FMI Element Code" := MockPayrollElement;
            PayrollElementCodes[1] := "PF BASE Element Code";
            PayrollElementCodes[2] := "PF OVER Limit Element Code";
            PayrollElementCodes[3] := CopyStr("PF INS Limit Element Code", 1, MaxStrLen(PayrollElementCodes[3]));
            PayrollElementCodes[4] := "PF SPECIAL 1 Element Code";
            PayrollElementCodes[5] := "PF SPECIAL 2 Element Code";
            PayrollElementCodes[6] := "PF MI NO TAX Element Code";
            PayrollElementCodes[7] := CopyStr("TAX PF INS Element Code", 1, MaxStrLen(PayrollElementCodes[7]));
            PayrollElementCodes[8] := CopyStr("TAX FED FMI Element Code", 1, MaxStrLen(PayrollElementCodes[8]));
            Modify;
        end;
    end;

    local procedure MockEmployee(PersonNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
    begin
        with Employee do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Employee);
            "Person No." := PersonNo;
            Insert;
            MockLaborContract("No.", PersonNo);
            exit("No.");
        end;
    end;

    local procedure MockPerson(): Code[20]
    var
        Person: Record Person;
    begin
        with Person do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Person);
            Insert;
            exit("No.");
        end;
    end;

    local procedure MockLaborContract(EmployeeNo: Code[20]; PersonNo: Code[20])
    var
        LaborContract: Record "Labor Contract";
    begin
        with LaborContract do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Labor Contract");
            "Contract Type" := "Contract Type"::"Labor Contract";
            "Starting Date" := CalcDate('<-CY>', WorkDate);
            "Person No." := PersonNo;
            "Employee No." := EmployeeNo;
            Insert;
            MockLaborContractLine("No.", PersonNo);
        end;
    end;

    local procedure MockLaborContractLine(ContractNo: Code[20]; PersonNo: Code[20])
    var
        LaborContractLine: Record "Labor Contract Line";
    begin
        with LaborContractLine do begin
            Init;
            "Contract No." := ContractNo;
            "Operation Type" := "Operation Type"::Hire;
            "Supplement No." := '1';
            "Starting Date" := CalcDate('<-CY>', WorkDate);
            "Person No." := PersonNo;
            Insert;
        end;
    end;

    local procedure MockPayrollElement(): Code[20]
    var
        PayrollElement: Record "Payroll Element";
    begin
        with PayrollElement do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Payroll Element");
            Insert;
            exit(Code);
        end;
    end;

    local procedure MockEmployeePayments(PayrollElementCodes: array[8] of Code[20]; EmployeeNo: Code[20]; PostingDate: Date)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(PayrollElementCodes) do
            MockPayrollLedgerEntry(EmployeeNo, PostingDate, PayrollElementCodes[i], LibraryRandom.RandDec(1000000, 2));
    end;

    local procedure MockPayrollLedgerEntry(EmployeeNo: Code[20]; PostingDate: Date; ElementCode: Code[20]; PayrollAmount: Decimal)
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
    begin
        with PayrollLedgerEntry do begin
            Init;
            FindLast;
            "Entry No." += 1;
            "Employee No." := EmployeeNo;
            "Posting Date" := PostingDate;
            "Element Code" := ElementCode;
            "Payroll Amount" := PayrollAmount;
            Insert;
        end;
    end;

    local procedure GetReportPeriod(var StartDate: Date; var EndDate: Date; PeriodNo: Integer)
    begin
        StartDate := CalcDate('<-CY>', WorkDate);
        case PeriodNo of
            0:
                EndDate := CalcDate('<+11M+CM>', StartDate);
            1:
                EndDate := CalcDate('<+2M+CM>', StartDate);
            2:
                EndDate := CalcDate('<+5M+CM>', StartDate);
            3:
                EndDate := CalcDate('<+8M+CM>', StartDate);
        end;
    end;

    local procedure GetPostingDate(MonthNo: Integer) ResultPayrollReportingBuffer: Date
    begin
        ResultPayrollReportingBuffer := CalcDate('<-CY+15D>', WorkDate);
        if MonthNo > 1 then
            ResultPayrollReportingBuffer := CalcDate(StrSubstNo('<+%1M>', MonthNo - 1), ResultPayrollReportingBuffer);
    end;

    local procedure GetPayrollAmounts(var Amounts: array[9] of Decimal; PayrollElementCodes: array[8] of Code[20]; EmployeeFilter: Text[1024]; StartDate: Date; EndDate: Date)
    var
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        i: Integer;
    begin
        for i := 1 to ArrayLen(PayrollElementCodes) do begin
            PayrollLedgerEntry.SetFilter("Employee No.", EmployeeFilter);
            PayrollLedgerEntry.SetRange("Element Code", PayrollElementCodes[i]);
            PayrollLedgerEntry.SetRange("Posting Date", StartDate, EndDate);
            PayrollLedgerEntry.CalcSums("Payroll Amount");
            Amounts[i + 1] := PayrollLedgerEntry."Payroll Amount";
        end;

        Amounts[1] := Amounts[2] + Amounts[7];
        Amounts[2] -= Amounts[3];
        Amounts[7] := Amounts[2] + Amounts[3];
    end;

    local procedure GetLastPackNoInPayrollRepBuffer(var PayrollReportingBuffer: Record "Payroll Reporting Buffer"): Integer
    begin
        with PayrollReportingBuffer do begin
            Reset;
            SetCurrentKey("Pack No.");
            if not FindLast then
                exit(0);
            exit("Pack No.");
        end;
    end;

    local procedure VerifyPayrollRepBuf(var PayrollReportingBuffer: Record "Payroll Reporting Buffer"; ExpAmounts: array[9] of Decimal; PersonFilter: Text[1024]; ExpMonthNoValue: Integer; ExpRecCnt: Integer; ExpMonthRecCnt: Integer)
    begin
        // Employee Total
        PayrollReportingBuffer.SetFilter("Code 1", PersonFilter);
        PayrollReportingBuffer.SetRange("Code 2", '0');
        PayrollReportingBuffer.SetRange("Code 3", '01');
        PayrollReportingBuffer.SetRange("Code 4", '');
        Assert.AreEqual(ExpRecCnt, PayrollReportingBuffer.Count, StrSubstNo(WrongRecordsCntErr, PayrollReportingBuffer.TableCaption));
        VerifyPayrollRepBufAmounts(PayrollReportingBuffer, ExpAmounts);

        if ExpMonthNoValue > 0 then begin
            // Verify Month Period
            PayrollReportingBuffer.SetRange("Code 2", Format(ExpMonthNoValue));
            Assert.AreEqual(
              ExpMonthRecCnt, PayrollReportingBuffer.Count,
              StrSubstNo(WrongRecordsCntErr, PayrollReportingBuffer.TableCaption));
            VerifyPayrollRepBufAmounts(PayrollReportingBuffer, ExpAmounts);
        end;
    end;

    local procedure VerifyPayrollRepBufAmounts(var PayrollReportingBuffer: Record "Payroll Reporting Buffer"; ExpAmounts: array[9] of Decimal)
    begin
        PayrollReportingBuffer.CalcSums(
          "Amount 1", "Amount 2", "Amount 3", "Amount 4", "Amount 5", "Amount 6", "Amount 7", "Amount 8", "Amount 9");
        Assert.AreEqual(ExpAmounts[1], PayrollReportingBuffer."Amount 1", StrSubstNo(PayrollRepBufAmountErr, 1));
        Assert.AreEqual(ExpAmounts[2], PayrollReportingBuffer."Amount 2", StrSubstNo(PayrollRepBufAmountErr, 2));
        Assert.AreEqual(ExpAmounts[3], PayrollReportingBuffer."Amount 3", StrSubstNo(PayrollRepBufAmountErr, 3));
        Assert.AreEqual(ExpAmounts[4], PayrollReportingBuffer."Amount 4", StrSubstNo(PayrollRepBufAmountErr, 4));
        Assert.AreEqual(ExpAmounts[5], PayrollReportingBuffer."Amount 5", StrSubstNo(PayrollRepBufAmountErr, 5));
        Assert.AreEqual(ExpAmounts[6], PayrollReportingBuffer."Amount 6", StrSubstNo(PayrollRepBufAmountErr, 6));
        Assert.AreEqual(ExpAmounts[7], PayrollReportingBuffer."Amount 7", StrSubstNo(PayrollRepBufAmountErr, 7));
        Assert.AreEqual(ExpAmounts[8], PayrollReportingBuffer."Amount 8", StrSubstNo(PayrollRepBufAmountErr, 8));
        Assert.AreEqual(ExpAmounts[9], PayrollReportingBuffer."Amount 9", StrSubstNo(PayrollRepBufAmountErr, 9));
    end;

    local procedure MockEmployeeWithLaborContract(var Employee: Record Employee)
    begin
        Employee.Get(MockEmployee(MockPerson));
    end;
}

