codeunit 144201 "HRP AE General"
{
    // Tests for HRP average earnings
    // Due to complexity of AE calculations tests use hardcoded amounts and dates which are taken from specification
    // 
    //   1. Only max bunus has to be used for AE calculaton
    //   2. Both bonuses have to be used, becuase they have different elements
    //   3. Calculation period contains missed earnings. Verify number of periods
    //   4. Calculation period contains missed earnings. Verify EA days calculation
    //   5. Calculation AE for feature period vacation
    //   6. Verify AE calculation for last month day dismissal
    //   7. AE calculation for previous period monthly bonus
    //   8. AE calculation for business travel. Simple scenario
    //   9. AE calculation for vacation after business travel.
    //   10. AE calculation for vacation. Simple scenario
    //   11. AE calculation for sick leave after vacation.
    //   12. AE calculation for business travel after vacation.
    //   13. AE calculation with maximum allowed average earning (415000)
    //   14. AE calculation based on current period salary

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryHRP: Codeunit "Library - HRP";
        Translate: Codeunit "Translate Payroll";
        Assert: Codeunit Assert;
        BonusMonthlyAmtTxt: Label 'BONUS MONTHLY AMT', Locked = true;
        BonusMonthlyLastMonthPctTxt: Label 'BONUS MONTHLY % LM', Locked = true;
        BonusMonthlyPctTxt: Label 'BONUS MONTHLY %', Locked = true;
        LibraryRandom: Codeunit "Library - Random";
        SalaryDayTxt: Label 'SALARY DAY', Locked = true;
        AEDailyEarningsErr: Label 'Incorrect AE Daily Earnings';
        AETotalEarningsErr: Label 'Incorrect AE Total Earnings.';
        IncorrectAEEntriesNumberErr: Label 'Incorrect number of AE entries.';
        YearShift: Integer;
        AverageDaysAEErr: Label 'Incorrect number of Average Days.';
        AELinesQtyErr: Label 'Incorrect AE Entries quantity.';
        AEPeriodErr: Label 'Incorrect AE period.';
        IncorrectAETotalFSIEarningsErr: Label 'Incorrect AE Total FSI Earnings.';
        IncorrectAmoutForFSIErr: Label 'Incorrect Amout for FSI.';
        IncorrectLedgerEntriesCount: Label 'Incorrect Count of Employee Ledger Entries for last document.';
        IncorrectAmoutForAEErr: Label 'Incorrect Amout for AE.';

    [Test]
    [Scope('OnPrem')]
    procedure BonusCalcMethod_SameElementDiffAmounts()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case for NC 50272 part 1
        // Only max bunus has to be used for AE calculaton

        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 10000, '0901', '1001', '1001');
        repeat
            // usual monthly bonus
            LibraryHRP.CreateEmplJnlLine(
              EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
              2000, PayrollPeriod."Ending Date", true);

            case PayrollPeriod.Code of
                AdjustPeriod('0902'): // max bonus
                    LibraryHRP.CreateEmplJnlLine(
                      EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
                      5000, PayrollPeriod."Ending Date", true);
                AdjustPeriod('1001'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100118D), AdjustDate(20100124D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyPostedDocLineAETotalEarnings(PostedPayrollDocumentLine, 147000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BonusCalcMethod_DifferentElements()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case for NC 50272 part 1
        // Both bonuses have to be used, becuase they have different elements

        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 20000, '0901', '1001', '1001');
        repeat
            // usual monthly bonus
            LibraryHRP.CreateEmplJnlLine(
              EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyPctTxt),
              20, PayrollPeriod."Ending Date", true);

            case PayrollPeriod.Code of
                AdjustPeriod('0902'): // max bonus
                    LibraryHRP.CreateEmplJnlLine(
                      EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
                      3000, PayrollPeriod."Ending Date", true);
                AdjustPeriod('1001'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100118D), AdjustDate(20100124D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyPostedDocLineAETotalEarnings(PostedPayrollDocumentLine, 291000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissedEarning_NumberOfPeriods()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        PostedPayrollDocLineAE: Record "Posted Payroll Doc. Line AE";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case for NC 51612 (analog of the case 26 from the spec)
        // Calculation period contains missed earnings. Verify number of periods

        // 01.01.09 - 01.01.10 - regular work
        // 24.01.10 - 29.05.10 - pregnancy leave
        // 30.05.10 - 31.01.11 - child care leave
        // 10.02.11 - 20.02.11 - sick leave
        // AE calculation for this sick leave should use data from the previous AE period (0902-1001)

        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 10000, '0901', '1102', '1102');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // pregnancy
                    CreatePostPregnancySickLeave(EmployeeNo, PayrollPeriod, AdjustDate(20100124D), AdjustDate(20100529D));
                AdjustPeriod('1005'): // child care sick leave
                    CreatePostChildCare1_5_SickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100530D), AdjustDate(20110131D));
                AdjustPeriod('1102'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20110211D), AdjustDate(20110220D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1102') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        PostedPayrollDocLineAE.SetRange("Document No.", PostedPayrollDocumentLine."Document No.");
        PostedPayrollDocLineAE.SetRange("Document Line No.", PostedPayrollDocumentLine."Line No.");
        Assert.AreEqual(13, PostedPayrollDocLineAE.Count, IncorrectAEEntriesNumberErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissedEarning_CheckAverageDays()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case for NC 50894
        // Calculation period contains missed earnings. Verify EA days calculation

        // 01.01.09 - 01.01.10 - regular work
        // 24.01.10 - 29.05.10 - pregnancy leave
        // 30.05.10 - 31.12.10 - child care leave
        // Avarage Days for periods 1002 - 1004 should be 0

        TimeActivity.Get(LibraryHRP.FindChildCare1_5YearsTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 10000, '0901', '1012', '1005');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // pregnancy
                    CreatePostPregnancySickLeave(EmployeeNo, PayrollPeriod, AdjustDate(20100124D), AdjustDate(20100529D));
                AdjustPeriod('1005'): // child care sick leave
                    CreatePostChildCare1_5_SickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100530D), AdjustDate(20101231D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1005') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyPostedPeriodAEAverageDays(PostedPayrollDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcVacationFuturePeriod()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        PostedPayrollDocLineAE: Record "Posted Payroll Doc. Line AE";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case for NC 51031
        // Calculation AE for feature period vacation

        // 01.01.09 - 01.01.10 - regular work
        // 15.01.10 - bonus amount
        // 01.02.10 - 14.02.10 - vacation, which should be paid in January salary
        // AE calculation for this vaction should use AE period including current period (0902-1001)

        TimeActivity.Get(LibraryHRP.FindRegularVacationTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 10000, '0901', '1002', '1001');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // bonus and vacation
                    begin
                        LibraryHRP.CreateEmplJnlLine(
                          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
                          5000, AdjustDate(20100115D), true);

                        LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code,
                          PayrollPeriod."Ending Date", AdjustDate(20100201D), AdjustDate(20100214D));
                    end;
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        // check the number of linked AE entries for 1001
        PostedPayrollDocLineAE.SetRange("Document No.", PostedPayrollDocumentLine."Document No.");
        PostedPayrollDocLineAE.SetRange("Document Line No.", PostedPayrollDocumentLine."Line No.");
        PostedPayrollDocLineAE.SetRange("Period Code", PostedPayrollDocumentLine."Period Code");
        // it should be 2
        Assert.AreEqual(2, PostedPayrollDocLineAE.Count, AELinesQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastMonthDayDismissal()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        GroundsForTermination: Record "Grounds for Termination";
        EmployeeNo: Code[20];
    begin
        // case for NC 51033 (updated accordingly to RFH 298720
        // Verify AE calculation for last month day dismissal

        // 01.01.09 - 01.01.10 - regular work
        // 31.01.10 - dismissal
        // due last month day AE period should be 0902-1001

        InitAEScenario(EmployeeNo, PayrollPeriod, 10000, '0901', '1002', '1001');
        GroundsForTermination.Get(LibraryHRP.FindGroundOfTerminationCode);
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // dismissal
                    LibraryHRP.DismissEmployee(EmployeeNo, PayrollPeriod."Ending Date", GroundsForTermination.Code, true);
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                // find line with dismissal
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, GroundsForTermination."Element Code");
        until PayrollPeriod.Next = 0;

        Assert.AreEqual(AdjustPeriod('0902'), PostedPayrollDocumentLine."AE Period From", AEPeriodErr);
        Assert.AreEqual(AdjustPeriod('1001'), PostedPayrollDocumentLine."AE Period To", AEPeriodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MonthlyBonusPrevPeriod()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        ExpectedAmount: Decimal;
        SalaryAmount: Integer;
        BonusPercent: Integer;
    begin
        // case for NC 50134 part 1
        // AE calculation for previous period monthly bonus

        // 01.01.09 - 01.01.10 - regular work
        // monthly bonus is calculated for previous period
        // 01.06.09 - 14.06.09 - sick leave (to create difference between planned days and fact days)
        // 01.04.10 - 10.04.10 - sick leave (to calculate AE)

        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        SalaryAmount := LibraryRandom.RandIntInRange(10000, 20000);
        BonusPercent := LibraryRandom.RandIntInRange(3, 6) * 10;
        InitAEScenario(EmployeeNo, PayrollPeriod, SalaryAmount, '0901', '1004', '1004');
        repeat
            // create monthly bonus 40% for prev period
            CreatePostPrevMonthBonus(EmployeeNo, PayrollPeriod, BonusPercent);

            case PayrollPeriod.Code of
                AdjustPeriod('0906'): // sick leave (to create difference between planned days and fact days)
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20090601D), AdjustDate(20090614D));
                AdjustPeriod('1004'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100401D), AdjustDate(20100410D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

            case PayrollPeriod.Code of
                AdjustPeriod('0906'):
                    ExpectedAmount := Round(SalaryAmount * BonusPercent / 100 * GetActualVsPlannedRatio(EmployeeNo, PayrollPeriod.Code));
                AdjustPeriod('1004'):
                    FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
            end;
        until PayrollPeriod.Next = 0;

        VerifyPostedPayrollDocLineAEAmountForAE(
          PostedPayrollDocumentLine,
          AdjustPeriod('0906'),
          Translate.ElementCode(BonusMonthlyLastMonthPctTxt),
          ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessTravel_SunShine()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        TravelStartDate: Date;
        TravelEndDate: Date;
    begin
        // case 1 from test specification

        // 01.01.09 - 01.01.10 - regular work
        // 24.01.10 - 28.01.10 - business travel (to calculate AE)

        TimeActivity.Get(LibraryHRP.FindBusTravelTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 20000, '0901', '1001', '1001');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // business travel to cause AE calculatin
                    begin
                        FindLastWorkWeekPeriod(PayrollPeriod."Ending Date", TravelStartDate, TravelEndDate);
                        CreatePostTravelOrder(EmployeeNo, PayrollPeriod, TimeActivity.Code, TravelStartDate, TravelEndDate);
                    end;
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyPostedDocLineAETotalEarnings(PostedPayrollDocumentLine, 240000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VacationAfterBusinessTravel()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        TravelStartDate: Date;
        TravelEndDate: Date;
        ExpectedAmount: Decimal;
        SalaryAmount: Integer;
    begin
        // case 13 from test specification (continue of the case 1)

        // 01.01.09 - 01.01.10 - regular work
        // 24.01.10 - 28.01.10 - business travel
        // 01.02.10 - 07.02.10 - vacation (to calculate AE)

        SalaryAmount := LibraryRandom.RandIntInRange(10000, 20000);
        InitAEScenario(EmployeeNo, PayrollPeriod, SalaryAmount, '0901', '1002', '1002');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // business travel
                    begin
                        TimeActivity.Get(LibraryHRP.FindBusTravelTimeActivityCode);
                        FindLastWorkWeekPeriod(PayrollPeriod."Ending Date", TravelStartDate, TravelEndDate);
                        CreatePostTravelOrder(EmployeeNo, PayrollPeriod, TimeActivity.Code, TravelStartDate, TravelEndDate);
                    end;
                AdjustPeriod('1002'): // vacationto cause AE calculatin
                    begin
                        TimeActivity.Get(LibraryHRP.FindRegularVacationTimeActivityCode);
                        LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code, AdjustDate(20100201D), AdjustDate(20100201D), AdjustDate(20100207D));
                    end;
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

            case PayrollPeriod.Code of
                AdjustPeriod('1001'):
                    ExpectedAmount := Round(SalaryAmount * GetActualVsPlannedRatio(EmployeeNo, PayrollPeriod.Code));
                AdjustPeriod('1002'):
                    FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
            end;
        until PayrollPeriod.Next = 0;

        VerifyPostedPayrollDocLineAEAmountForAE(
          PostedPayrollDocumentLine,
          AdjustPeriod('1001'),
          Translate.ElementCode(SalaryDayTxt),
          ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vacation_SunShine()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case 2 from test specification

        // 01.01.09 - 01.01.10 - regular work
        // 15.01.10 - 21.01.10 - vacation (to calculate AE)

        TimeActivity.Get(LibraryHRP.FindRegularVacationTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 20000, '0901', '1001', '1001');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // vacation to cause AE calculatin
                    LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code, AdjustDate(20100114D), AdjustDate(20100115D), AdjustDate(20100121D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyPostedDocLineAETotalEarnings(PostedPayrollDocumentLine, 240000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessTravelAfterVacation()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        ExpectedAmount: Decimal;
        SalaryAmount: Integer;
    begin
        // case 11 from test specification (continue of the case 2)

        // 01.01.09 - 01.01.10 - regular work
        // 15.01.10 - 21.01.10 - vacation
        // 01.02.10 - 07.02.10 - business travel (to calculate AE)

        SalaryAmount := LibraryRandom.RandIntInRange(10000, 20000);
        InitAEScenario(EmployeeNo, PayrollPeriod, SalaryAmount, '0901', '1002', '1002');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // vacation
                    begin
                        TimeActivity.Get(LibraryHRP.FindRegularVacationTimeActivityCode);
                        LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code, AdjustDate(20100114D), AdjustDate(20100115D), AdjustDate(20100121D));
                    end;
                AdjustPeriod('1002'): // business travel to calculate AE
                    begin
                        TimeActivity.Get(LibraryHRP.FindBusTravelTimeActivityCode);
                        CreatePostTravelOrder(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100201D), AdjustDate(20100207D));
                    end;
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

            case PayrollPeriod.Code of
                AdjustPeriod('1001'):
                    ExpectedAmount := Round(SalaryAmount * GetActualVsPlannedRatio(EmployeeNo, PayrollPeriod.Code));
                AdjustPeriod('1002'):
                    FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
            end;
        until PayrollPeriod.Next = 0;

        VerifyPostedPayrollDocLineAEAmountForAE(
          PostedPayrollDocumentLine,
          AdjustPeriod('1001'),
          Translate.ElementCode(SalaryDayTxt),
          ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SickLeaveAfterVacation()
    var
        PayrollPeriod: Record "Payroll Period";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        SalaryAmount: Integer;
        ExpectedAmount: Decimal;
    begin
        // case 3 from test specification

        // 01.01.09 - 01.01.10 - regular work
        // 01.02.09 - 15.02.09 - vacation
        // 25.01.10 - 31.01.10 - sick leave (to calculate AE)

        SalaryAmount := LibraryRandom.RandIntInRange(10000, 20000);
        InitAEScenario(EmployeeNo, PayrollPeriod, SalaryAmount, '0901', '1001', '1001');
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('0902'): // vacation
                    begin
                        TimeActivity.Get(LibraryHRP.FindRegularVacationTimeActivityCode);
                        LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code, AdjustDate(20090201D), AdjustDate(20090201D), AdjustDate(20090214D));
                    end;
                AdjustPeriod('1001'): // sick leave to cause AE calculatin
                    begin
                        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
                        CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100125D), AdjustDate(20100131D));
                    end;
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);

            case PayrollPeriod.Code of
                AdjustPeriod('0902'):
                    ExpectedAmount := Round(SalaryAmount * GetActualVsPlannedRatio(EmployeeNo, PayrollPeriod.Code));
                AdjustPeriod('1001'):
                    FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
            end;
        until PayrollPeriod.Next = 0;

        VerifyPostedPayrollDocLineAEAmountForAE(
          PostedPayrollDocumentLine,
          AdjustPeriod('0902'),
          Translate.ElementCode(SalaryDayTxt),
          ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaxAvailableAE()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case 8 from test specification
        // when AE amount more then allowed maximum (415000)

        // 01.01.09 - 01.01.10 - regular work
        // 20% monthly bonus
        // 25.01.10 - 31.01.10 - sick leave (to calculate AE)

        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 35000, '0901', '1001', '1001');
        AddPrevPeriodIncomeFSI(EmployeeNo, AdjustPeriod('0801'), AdjustPeriod('0812'), 42000);
        repeat
            // usual monthly bonus
            LibraryHRP.CreateEmplJnlLine(
              EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyPctTxt),
              20, PayrollPeriod."Ending Date", true);

            case PayrollPeriod.Code of
                AdjustPeriod('1001'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100125D), AdjustDate(20100131D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        Assert.AreEqual(1136.99, PostedPayrollDocumentLine."AE Daily Earnings", AEDailyEarningsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AECalcBasedOnCurrPeriod()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // case 19 from test specification
        // AE calculation based on current period salary

        // 01.01.09 - work started
        // monthly bonus 882.35
        // 24.01.09 - 31.01.09 - vacation

        TimeActivity.Get(LibraryHRP.FindEducationVacationTimeActivityCode);
        InitAEScenario(EmployeeNo, PayrollPeriod, 15000, '0901', '0901', '0901');

        // monthly bonus
        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
          882.35, PayrollPeriod."Ending Date", true);

        LibraryHRP.CreateVacation(EmployeeNo, TimeActivity.Code, AdjustDate(20090124D), AdjustDate(20090124D), AdjustDate(20090131D));

        CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
        FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");

        VerifyAEDailyEarningsBasedOnCurrPeriod(PostedPayrollDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeBonus()
    var
        PayrollPeriod: Record "Payroll Period";
        EmplJnlLine: Record "Employee Journal Line";
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
    begin
        // RFH 353619. Negative bonus should not be taken into account for AE calculation

        InitAEScenario(EmployeeNo, PayrollPeriod, GetSalaryBiggerThanFSILimit, '0901', '1001', '1001');
        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);
        repeat
            case PayrollPeriod.Code of
                AdjustPeriod('0901'): // positive bonus
                    LibraryHRP.CreateEmplJnlLine(
                      EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
                      5000, PayrollPeriod."Ending Date", true);
                AdjustPeriod('0912'): // negative bonus
                    LibraryHRP.CreateEmplJnlLine(
                      EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyAmtTxt),
                      -5000, PayrollPeriod."Ending Date", true);
                AdjustPeriod('1001'): // sick leave to cause AE calculatin
                    CreatePostCommonDiseaseSickLeave(EmployeeNo, PayrollPeriod, TimeActivity.Code, AdjustDate(20100125D), AdjustDate(20100131D));
            end;

            CreatePostPayrollDoc(EmployeeNo, PayrollPeriod);
            if PayrollPeriod.Code = AdjustPeriod('1001') then
                FindPostedPayrollDocLine(PostedPayrollDocumentLine, EmployeeNo, PayrollPeriod.Code, TimeActivity."Element Code");
        until PayrollPeriod.Next = 0;

        VerifyAETotalFSIEarnings(PostedPayrollDocumentLine, LibraryHRP.GetFSILimit(AdjustPeriod('0901')));
        VerifyNegativeBonusFSIAmount(PostedPayrollDocumentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SickLeaveOrderContinuation()
    var
        PayrollPeriod: Record "Payroll Period";
        TimeActivity: Record "Time Activity";
        EmployeeNo: Code[20];
        DocNo: Code[20];
        CurDate: Date;
        NextDate: Date;
        DaysCount: Integer;
    begin
        // RFH 354727. System unexpected split sick record per Employeer/FSI for continuation of sick leave order.
        InitAEScenario(EmployeeNo, PayrollPeriod, GetSalaryBiggerThanFSILimit, '0901', '0901', '0901');
        TimeActivity.Get(LibraryHRP.FindCommonDiseaseTimeActivityCode);

        CurDate := CalcDate('<-CY>', PayrollPeriod."Starting Date");
        DaysCount := LibraryRandom.RandIntInRange(3, 10);  // should be no less then 3
        NextDate := CalcDate('<' + Format(DaysCount) + 'D>', CurDate);
        DocNo :=
          CreatePostDiseaseSickLeaveWithPrevDocNo(
            EmployeeNo, PayrollPeriod, TimeActivity.Code, CurDate, NextDate, '');

        DaysCount := LibraryRandom.RandInt(10);
        CurDate := CalcDate('<1D>', NextDate);
        NextDate := CalcDate('<' + Format(DaysCount) + 'D>', CurDate);
        DocNo :=
          CreatePostDiseaseSickLeaveWithPrevDocNo(
            EmployeeNo, PayrollPeriod, TimeActivity.Code, CurDate, NextDate, DocNo);

        DaysCount := LibraryRandom.RandInt(10);
        CurDate := CalcDate('<1D>', NextDate);
        NextDate := CalcDate('<' + Format(DaysCount) + 'D>', CurDate);
        DocNo :=
          CreatePostDiseaseSickLeaveWithPrevDocNo(
            EmployeeNo, PayrollPeriod, TimeActivity.Code, CurDate, NextDate, DocNo);

        VerifyNumberOfEmplLedgEntries(EmployeeNo, DocNo, TimeActivity."Element Code", 1);
    end;

    local procedure InitAEScenario(var EmployeeNo: Code[20]; var PayrollPeriod: Record "Payroll Period"; PayrollAmount: Decimal; StartPeriodCode: Code[10]; EndPeriodCode: Code[10]; EndLoopPeriodCode: Code[10])
    begin
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        YearShift := Date2DMY(PayrollPeriod."Starting Date", 3) - 2009; // year shift for date adjustment
        EmployeeNo := LibraryHRP.CreateNewEmployee(PayrollPeriod."Starting Date", PayrollAmount);
        PreparePayrollPeriod(PayrollPeriod, AdjustPeriod(StartPeriodCode), AdjustPeriod(EndPeriodCode), AdjustPeriod(EndLoopPeriodCode));
        PayrollPeriod.FindSet;
    end;

    local procedure PreparePayrollPeriod(var PayrollPeriod: Record "Payroll Period"; StartPeriodCode: Code[10]; EndPeriodCode: Code[10]; EndLoopPeriodCode: Code[10])
    begin
        // create periods if last one is not found
        LibraryHRP.PreparePayrollPeriods(PayrollPeriod, StartPeriodCode, EndPeriodCode);
        PayrollPeriod.SetRange(Code, StartPeriodCode, EndLoopPeriodCode);
    end;

    local procedure CreatePostCommonDiseaseSickLeave(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; StartDate: Date; EndDate: Date)
    begin
        LibraryHRP.CreateSickLeaveOrder(EmployeeNo, PayrollPeriod."Ending Date", StartDate, EndDate, TimeActivityCode, '', 100, 0, true);
    end;

    local procedure CreatePostDiseaseSickLeaveWithPrevDocNo(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; StartDate: Date; EndDate: Date; PrevDocNo: Code[20]): Code[20]
    var
        AbsenceHeader: Record "Absence Header";
        AbsenceLine: Record "Absence Line";
        AbsenceOrderPost: Codeunit "Absence Order-Post";
    begin
        LibraryHRP.CreateSickLeaveOrder(EmployeeNo, PayrollPeriod."Ending Date", StartDate, EndDate, TimeActivityCode, '', 100, 0, false);
        AbsenceHeader.SetRange("Employee No.", EmployeeNo);
        AbsenceHeader.FindLast;
        AbsenceLine.SetRange("Document No.", AbsenceHeader."No.");
        AbsenceLine.FindLast;
        AbsenceLine.Validate("Previous Document No.", PrevDocNo);
        AbsenceLine.Modify(true);
        AbsenceOrderPost.Run(AbsenceHeader);
        exit(AbsenceHeader."No.");
    end;

    local procedure CreatePostPregnancySickLeave(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; StartDate: Date; EndDate: Date)
    var
        TimeActivity: Record "Time Activity";
    begin
        LibraryHRP.CreateSickLeaveOrder(
          EmployeeNo, PayrollPeriod."Ending Date", StartDate, EndDate,
          LibraryHRP.FindSickLeaveTimeActivityCode(TimeActivity."Sick Leave Type"::"Pregnancy Leave"),
          '', 100, 0, true);
    end;

    local procedure CreatePostChildCare1_5_SickLeave(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; StartDate: Date; EndDate: Date)
    begin
        LibraryHRP.CreateSickLeaveOrder(
          EmployeeNo, PayrollPeriod."Ending Date", StartDate, EndDate, TimeActivityCode,
          CreateChildRelativePersone(EmployeeNo, StartDate), 100, 0, true);
    end;

    local procedure FindPostedPayrollDocLine(var PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; EmployeeNo: Code[20]; PayrollPeriodCode: Code[20]; ElementCode: Code[20])
    begin
        with PostedPayrollDocumentLine do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Period Code", PayrollPeriodCode);
            SetRange("Element Code", ElementCode);
            FindFirst;
        end;
    end;

    local procedure CreatePostPayrollDoc(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period")
    begin
        LibraryHRP.ReleaseTimeSheet(PayrollPeriod.Code, EmployeeNo);
        LibraryHRP.CreatePayrollDoc(EmployeeNo, PayrollPeriod.Code, '', PayrollPeriod."Ending Date");
        LibraryHRP.PostPayrollDoc(EmployeeNo, PayrollPeriod."Ending Date");
    end;

    local procedure CreatePostPrevMonthBonus(EmployeeNo: Code[200]; PayrollPeriod: Record "Payroll Period"; Percent: Decimal)
    var
        EmplJnlLine: Record "Employee Journal Line";
        PrevPayrollPeriod: Record "Payroll Period";
    begin
        // find prev period
        PrevPayrollPeriod := PayrollPeriod;
        PrevPayrollPeriod.Next(-1);

        LibraryHRP.CreateEmplJnlLine(
          EmplJnlLine, PayrollPeriod, EmployeeNo, Translate.ElementCode(BonusMonthlyLastMonthPctTxt),
          Percent, PayrollPeriod."Ending Date", true);
    end;

    local procedure CreateChildRelativePersone(EmployeeNo: Code[20]; BirthDate: Date): Code[20]
    var
        Employee: Record Employee;
        Relative: Record Relative;
    begin
        Employee.Get(EmployeeNo);
        Relative.SetRange("Relative Type", Relative."Relative Type"::Child);
        if Relative.FindFirst then;
        exit(LibraryHRP.CreateRelativePerson(Employee."Person No.", Relative.Code, BirthDate, BirthDate));
    end;

    local procedure CreatePostTravelOrder(EmployeeNo: Code[20]; PayrollPeriod: Record "Payroll Period"; TimeActivityCode: Code[10]; StartDate: Date; EndDate: Date)
    begin
        LibraryHRP.CreateTravelOrder(EmployeeNo, PayrollPeriod."Ending Date", StartDate, EndDate,
          TimeActivityCode, true);
    end;

    local procedure AdjustDate(Date: Date): Date
    begin
        exit(CalcDate(StrSubstNo('<+%1Y>', YearShift), Date));
    end;

    local procedure AdjustPeriod(PeriodCode: Code[10]): Code[10]
    var
        Year: Integer;
    begin
        Evaluate(Year, CopyStr(PeriodCode, 1, 2));
        exit(StrSubstNo('%1%2', Year + YearShift, CopyStr(PeriodCode, 3, 2)));
    end;

    local procedure VerifyPostedPeriodAEAverageDays(PostedPayrollDocumentLine: Record "Posted Payroll Document Line")
    var
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
    begin
        PostedPayrollPeriodAE.SetRange("Document No.", PostedPayrollDocumentLine."Document No.");
        PostedPayrollPeriodAE.SetRange("Line No.", PostedPayrollDocumentLine."Line No.");
        PostedPayrollPeriodAE.SetRange("Period Code", AdjustPeriod('1002'), AdjustPeriod('1004'));
        PostedPayrollPeriodAE.FindSet;
        repeat
            Assert.AreEqual(0, PostedPayrollPeriodAE."Average Days", AverageDaysAEErr);
        until PostedPayrollPeriodAE.Next = 0;
    end;

    local procedure VerifyPostedDocLineAETotalEarnings(PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; ExpectedAmount: Decimal)
    begin
        PostedPayrollDocumentLine.CalcFields("AE Total Earnings");
        Assert.AreEqual(ExpectedAmount, PostedPayrollDocumentLine."AE Total Earnings", AETotalEarningsErr);
    end;

    local procedure VerifyAEDailyEarningsBasedOnCurrPeriod(PostedPayrollDocumentLine: Record "Posted Payroll Document Line")
    var
        AETotalEarningsAmount: Decimal;
    begin
        with PostedPayrollDocumentLine do begin
            // keep AE Total FSI Earnings amount
            CalcFields("AE Total Earnings");
            AETotalEarningsAmount := "AE Total Earnings";
            // calculate sum of this month base salary and bonus
            SetRange("Document No.", "Document No.");
            SetRange("Directory Code", '2000'); // filter to exclude lines calculated based on AE
            CalcSums("Payroll Amount");

            Assert.AreEqual("Payroll Amount", AETotalEarningsAmount, AETotalEarningsErr);
        end;
    end;

    local procedure VerifyAETotalFSIEarnings(PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; ExpectedAmount: Decimal)
    begin
        PostedPayrollDocumentLine.CalcFields("AE Total FSI Earnings");
        Assert.AreEqual(ExpectedAmount, PostedPayrollDocumentLine."AE Total FSI Earnings", IncorrectAETotalFSIEarningsErr);
    end;

    local procedure VerifyNegativeBonusFSIAmount(PostedPayrollDocumentLine: Record "Posted Payroll Document Line")
    var
        PostedPayrollDocLineAE: Record "Posted Payroll Doc. Line AE";
    begin
        // "Amount for FSI" for negative bonus has to be zero
        with PostedPayrollDocLineAE do begin
            SetRange("Document No.", PostedPayrollDocumentLine."Document No.");
            SetRange("Document Line No.", PostedPayrollDocumentLine."Line No.");
            SetRange("Element Type", "Element Type"::Bonus);
            SetFilter(Amount, '<0');
            FindFirst;
            Assert.AreEqual(0, "Amount for FSI", IncorrectAmoutForFSIErr);
        end;
    end;

    local procedure VerifyNumberOfEmplLedgEntries(EmployeeNo: Code[20]; DocNo: Code[20]; ElementCode: Code[20]; EntriesCount: Integer)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document No.", DocNo);
        EmployeeLedgerEntry.SetRange("Element Code", ElementCode);
        Assert.AreEqual(EntriesCount, EmployeeLedgerEntry.Count, IncorrectLedgerEntriesCount);
    end;

    local procedure VerifyPostedPayrollDocLineAEAmountForAE(PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; PeriodCode: Code[10]; ElementCode: Code[20]; ExpectedAmount: Decimal)
    var
        PostedPayrollDocLineAE: Record "Posted Payroll Doc. Line AE";
    begin
        with PostedPayrollDocLineAE do begin
            SetRange("Document No.", PostedPayrollDocumentLine."Document No.");
            SetRange("Document Line No.", PostedPayrollDocumentLine."Line No.");
            SetRange("Period Code", PeriodCode);
            SetRange("Element Code", ElementCode);
            FindFirst;
            Assert.AreEqual(ExpectedAmount, "Amount for AE", IncorrectAmoutForAEErr);
        end;
    end;

    local procedure GetSalaryBiggerThanFSILimit(): Decimal
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        // calculate monthly salary which exceeds FSI limit
        LibraryHRP.FindPayrollPeriod(PayrollPeriod);
        exit(Round(LibraryHRP.GetFSILimit(PayrollPeriod.Code) * 2 / 12));
    end;

    local procedure GetActualVsPlannedRatio(EmloyeeNo: Code[20]; PeriodCode: Code[10]): Decimal
    var
        TimesheetStatus: Record "Timesheet Status";
    begin
        with TimesheetStatus do begin
            Get(PeriodCode, EmloyeeNo);
            TestField("Planned Work Days");
            exit("Actual Work Days" / "Planned Work Days");
        end;
    end;

    local procedure FindLastWorkWeekPeriod(RefDate: Date; var PeriodStartDate: Date; var PeriodEndDate: Date)
    var
        Date: Record Date;
    begin
        // find last whole work week period (Monday - Friday)
        with Date do begin
            SetRange("Period Type", "Period Type"::Date);
            SetRange("Period Start", CalcDate('<-CM>', RefDate), CalcDate('<CM>', RefDate));
            SetRange("Period No.", 5); // Friday
            FindLast;
            PeriodEndDate := "Period Start";
            PeriodStartDate := CalcDate('<-4D>', PeriodEndDate);
        end;
    end;

    local procedure AddPrevPeriodIncomeFSI(EmployeeNo: Code[20]; PeriodCodeFrom: Code[10]; PeriodCodeTo: Code[10]; Amount: Decimal)
    var
        PayrollPeriod: Record "Payroll Period";
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);
        PayrollPeriod.SetRange(Code, PeriodCodeFrom, PeriodCodeTo);
        PayrollPeriod.FindSet;
        repeat
            LibraryHRP.CreatePersonIncomeFSI(Employee."Person No.", PayrollPeriod.Code, Amount);
        until PayrollPeriod.Next = 0;
    end;
}

