codeunit 17470 "RSV Calculation Mgt."
{
    // Using of TAB17470 "Personified Reporting Buffer":
    //   Code1   = Person No.
    //   Code2   = Reporting Period Code: "0" - Total, "1" - FirstPayrollReportingBuffer Month, "2" - SecondPayrollReportingBuffer Month, "3" - Third Month, "4" - Begin Balance
    //   Code3   = Tariff Code (Disability attribute): "01" - normal, "03" - disability
    //   Code4   = Special Condition Code  (RSV-2014 6.7-3)
    //   Amount1 = PF_BASE + PF_MI_NO_TAX  (RSV-2014 6.4-4)
    //   Amount2 = PF_BASE - PF_OVER       (RSV-2014 6.4-5)
    //   Amount3 = PF_OVER                 (RSV-2014 6.4-7)
    //   Amount4 = PF_INS_LIMIT            (RSV-2014 6.5)
    //   Amount5 = PF_SPECIAL1             (RSV-2014 6.7-4)
    //   Amount6 = PF_SPECIAL2             (RSV-2014 6.7-5)
    //   Amount7 = PF_BASE
    //   Amount8 = PF_INS
    //   Amount9 = TAX_FED_FMI


    trigger OnRun()
    begin
    end;

    var
        HumanResourcesSetup: Record "Human Resources Setup";
        PayrollElementCode: array[8] of Code[50];

    [Scope('OnPrem')]
    procedure CalcDetailedBuffer(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var Person: Record Person; RepStartDate: Date; RepEndDate: Date)
    var
        TempDisabilityPersonMedicalInfo: Record "Person Medical Info" temporary;
        TempSpecialConditionPersonMedicalInfo: Record "Person Medical Info" temporary;
        PeriodStartDate: array[4] of Date;
        PeriodEndDate: array[4] of Date;
        PersonPeriodStartDate: Date;
        PersonPeriodEndDate: Date;
        PersonStartDate: Date;
        PersonEndDate: Date;
        StartDate: Date;
        EndDate: Date;
        PeriodCodes: array[4] of Code[20];
        PersonCount: Integer;
        PackNo: Integer;
        i: Integer;
    begin
        CheckHRSetup;
        DetailPayrollReportingBuffer.DeleteAll;
        TotalPaidPayrollReportingBuffer.DeleteAll;
        PreparePeriodDates(PeriodStartDate, PeriodEndDate, RepEndDate);
        PreparePeriodCodes(PeriodCodes);

        PersonCount := 0;
        PackNo := 1;
        if Person.FindSet then
            repeat
                if GetPersonPeriodDates(PersonPeriodStartDate, PersonPeriodEndDate, Person."No.", RepStartDate, RepEndDate) then begin
                    GetDisabilityPeriods(TempDisabilityPersonMedicalInfo, Person."No.", PersonPeriodStartDate, PersonPeriodEndDate);
                    if TempDisabilityPersonMedicalInfo.FindSet then
                        repeat
                            GetSpecialConditionPeriods(
                              TempSpecialConditionPersonMedicalInfo, Person."No.",
                              TempDisabilityPersonMedicalInfo."Starting Date", TempDisabilityPersonMedicalInfo."Ending Date");
                            if TempSpecialConditionPersonMedicalInfo.FindSet then
                                repeat
                                    PersonStartDate := TempSpecialConditionPersonMedicalInfo."Starting Date";
                                    PersonEndDate := TempSpecialConditionPersonMedicalInfo."Ending Date";
                                    for i := 1 to ArrayLen(PeriodCodes) do
                                        if (PersonStartDate <= PeriodEndDate[i]) and
                                           (PersonEndDate >= PeriodStartDate[i])
                                        then begin
                                            StartDate := GetMaxDate(PeriodStartDate[i], PersonStartDate);
                                            EndDate := GetMinDate(PeriodEndDate[i], PersonEndDate);
                                            CalcAmountsForPeriod(
                                              DetailPayrollReportingBuffer,
                                              TotalPaidPayrollReportingBuffer,
                                              Person."No.", i, StartDate, EndDate, PeriodCodes[i],
                                              GetTariffCode(TempDisabilityPersonMedicalInfo."Disability Group"),
                                              TempSpecialConditionPersonMedicalInfo."Insurer No.");
                                        end;
                                until TempSpecialConditionPersonMedicalInfo.Next = 0;
                        until TempDisabilityPersonMedicalInfo.Next = 0;
                end;

                if UpdatePackNoInBuffer(DetailPayrollReportingBuffer, PackNo) or
                   UpdatePackNoInBuffer(TotalPaidPayrollReportingBuffer, PackNo)
                then
                    GetNextPackNo(PackNo, PersonCount);
            until Person.Next = 0;
        DetailPayrollReportingBuffer.Reset;
        TotalPaidPayrollReportingBuffer.Reset;
    end;

    [Scope('OnPrem')]
    procedure CalcBeginBalanceBuffer(var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var Person: Record Person; RepStartDate: Date)
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := 0D;
        EndDate := CalcDate('<-CY-1D>', RepStartDate);

        if Person.FindSet then
            repeat
                CalcTotalAmountsForPeriod(TotalPaidPayrollReportingBuffer, Person."No.", StartDate, EndDate);
            until Person.Next = 0;

        PrepareTotalAmounts(TotalPaidPayrollReportingBuffer);
    end;

    local procedure CalcAmountsForPeriod(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PersonNo: Code[20]; PeriodNo: Integer; StartDate: Date; EndDate: Date; PeriodCode: Code[20]; TariffCode: Code[20]; SpecialCode: Code[20])
    var
        PayrollAmounts: array[8] of Decimal;
        PaidAmounts: array[8] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(PayrollAmounts) do
            CalcPayrollAmount(PayrollAmounts[i], PaidAmounts[i], PersonNo, StartDate, EndDate, PayrollElementCode[i]);

        // Detail Buffer
        if CheckAmounts(PayrollAmounts) or (PeriodNo = 1) then
            InsertPersRepBuffer(
              DetailPayrollReportingBuffer, PersonNo, PeriodCode, TariffCode, SpecialCode, PayrollAmounts);

        // Total Buffer
        InsertPersRepBuffer(
          TotalPaidPayrollReportingBuffer, 'TOTAL_PAID', PeriodCode, '', '', PaidAmounts);
    end;

    local procedure CalcTotalAmountsForPeriod(var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        PayrollAmounts: array[8] of Decimal;
        PaidAmounts: array[8] of Decimal;
        i: Integer;
    begin
        for i := 1 to ArrayLen(PayrollAmounts) do
            CalcPayrollAmount(PayrollAmounts[i], PaidAmounts[i], PersonNo, StartDate, EndDate, PayrollElementCode[i]);

        InsertPersRepBuffer(
          TotalPaidPayrollReportingBuffer, 'TOTAL_CHARGE', '4', '', '', PayrollAmounts);

        InsertPersRepBuffer(
          TotalPaidPayrollReportingBuffer, 'TOTAL_PAID', '4', '', '', PaidAmounts);
    end;

    local procedure CalcPayrollAmount(var PayrollAmount: Decimal; var PaidAmount: Decimal; PersonNo: Code[20]; StartDate: Date; EndDate: Date; ElementCode: Code[50])
    var
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        Employee: Record Employee;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with PayrollLedgEntry do begin
            PayrollAmount := 0;
            PaidAmount := 0;
            SetRange("Posting Date", StartDate, EndDate);
            SetFilter("Element Code", ElementCode);

            Employee.SetRange("Person No.", PersonNo);
            if Employee.FindSet then
                repeat
                    SetRange("Employee No.", Employee."No.");
                    if FindSet then
                        repeat
                            PayrollAmount += "Payroll Amount";
                            VendorLedgerEntry.SetRange("Payroll Ledger Entry No.", "Entry No.");
                            if VendorLedgerEntry.FindSet then
                                repeat
                                    if VendorLedgerEntry."Vendor No." = GetFundVendorNo("Element Code") then begin
                                        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
                                        PaidAmount += Abs(VendorLedgerEntry.Amount - VendorLedgerEntry."Remaining Amount");
                                    end;
                                until VendorLedgerEntry.Next = 0;
                        until Next = 0;
                until Employee.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcTotals110_113(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalChargeAmtPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        i: Integer;
    begin
        TotalChargeAmtPayrollReportingBuffer.DeleteAll;
        DetailPayrollReportingBuffer.Reset;

        for i := 0 to 3 do begin
            DetailPayrollReportingBuffer.SetRange("Code 2", Format(i));
            DetailPayrollReportingBuffer.CalcSums("Amount 5", "Amount 6", "Amount 8", "Amount 9");
            TotalChargeAmtPayrollReportingBuffer := DetailPayrollReportingBuffer;
            TotalChargeAmtPayrollReportingBuffer."Entry No." := i + 1;
            TotalChargeAmtPayrollReportingBuffer."Code 2" := Format(i);
            TotalChargeAmtPayrollReportingBuffer.Insert;
        end;

        PrepareTotalAmounts(TotalChargeAmtPayrollReportingBuffer);
    end;

    [Scope('OnPrem')]
    procedure CalcTotals100(var TotalPaidAmtPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalAmt100PayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        TempChargeBeginBalancePayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
    begin
        TotalPaidAmtPayrollReportingBuffer.SetRange("Code 1", 'TOTAL_CHARGE');
        TotalPaidAmtPayrollReportingBuffer.SetRange("Code 2", '4');
        if not TotalPaidAmtPayrollReportingBuffer.FindFirst then
            exit;

        TempChargeBeginBalancePayrollReportingBuffer := TotalPaidAmtPayrollReportingBuffer;

        TotalPaidAmtPayrollReportingBuffer.Reset;
        TotalPaidAmtPayrollReportingBuffer.SetRange("Code 1", 'TOTAL_PAID');
        TotalPaidAmtPayrollReportingBuffer.SetRange("Code 2", '4');
        if not TotalPaidAmtPayrollReportingBuffer.FindFirst then
            exit;

        CalcBufferSums(
          TotalAmt100PayrollReportingBuffer,
          TempChargeBeginBalancePayrollReportingBuffer,
          TotalPaidAmtPayrollReportingBuffer, -1);
    end;

    [Scope('OnPrem')]
    procedure CalcTotalsSums(var ResultPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var FirstPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var SecondPayrollReportingBuffer: Record "Payroll Reporting Buffer"; SignFactor: Integer)
    begin
        SecondPayrollReportingBuffer.Reset;
        SecondPayrollReportingBuffer.SetRange("Code 2", '0');
        if not SecondPayrollReportingBuffer.FindFirst then
            exit;

        CalcBufferSums(ResultPayrollReportingBuffer, FirstPayrollReportingBuffer, SecondPayrollReportingBuffer, SignFactor);
    end;

    local procedure CalcBufferSums(var ResultPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var FirstPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var SecondPayrollReportingBuffer: Record "Payroll Reporting Buffer"; SignFactor: Integer)
    begin
        ResultPayrollReportingBuffer."Amount 1" :=
          FirstPayrollReportingBuffer."Amount 1" + SignFactor * SecondPayrollReportingBuffer."Amount 1";
        ResultPayrollReportingBuffer."Amount 2" :=
          FirstPayrollReportingBuffer."Amount 2" + SignFactor * SecondPayrollReportingBuffer."Amount 2";
        ResultPayrollReportingBuffer."Amount 3" :=
          FirstPayrollReportingBuffer."Amount 3" + SignFactor * SecondPayrollReportingBuffer."Amount 3";
        ResultPayrollReportingBuffer."Amount 4" :=
          FirstPayrollReportingBuffer."Amount 4" + SignFactor * SecondPayrollReportingBuffer."Amount 4";
        ResultPayrollReportingBuffer."Amount 5" :=
          FirstPayrollReportingBuffer."Amount 5" + SignFactor * SecondPayrollReportingBuffer."Amount 5";
        ResultPayrollReportingBuffer."Amount 6" :=
          FirstPayrollReportingBuffer."Amount 6" + SignFactor * SecondPayrollReportingBuffer."Amount 6";
    end;

    local procedure AddPersRepBuffAmounts(var RSVPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PayrollAmounts: array[8] of Decimal)
    begin
        with RSVPayrollReportingBuffer do begin
            "Amount 1" += PayrollAmounts[1] + PayrollAmounts[6];
            "Amount 2" += PayrollAmounts[1] - PayrollAmounts[2];
            "Amount 3" += PayrollAmounts[2];
            "Amount 4" += PayrollAmounts[3];
            "Amount 5" += PayrollAmounts[4];
            "Amount 6" += PayrollAmounts[5];
            "Amount 7" += PayrollAmounts[1];
            "Amount 8" += PayrollAmounts[7];
            "Amount 9" += PayrollAmounts[8];
        end;
    end;

    local procedure PreparePeriodDates(var PeriodStartDate: array[4] of Date; var PeriodEndDate: array[4] of Date; RepEndDate: Date)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(PeriodStartDate) do
            GetPeriodDates(PeriodStartDate[i], PeriodEndDate[i], RepEndDate, i - 1);
    end;

    local procedure PreparePeriodCodes(var PeriodCodes: array[4] of Code[20])
    begin
        PeriodCodes[1] := '0';
        PeriodCodes[2] := '1';
        PeriodCodes[3] := '2';
        PeriodCodes[4] := '3';
    end;

    local procedure PrepareTotalAmounts(var AmountsPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        with AmountsPayrollReportingBuffer do begin
            Reset;
            if FindSet then
                repeat
                    "Amount 1" := Abs("Amount 8");
                    "Amount 2" := 0;
                    "Amount 3" := 0;
                    "Amount 4" := Abs("Amount 5");
                    "Amount 5" := Abs("Amount 6");
                    "Amount 6" := Abs("Amount 9");
                    Modify;
                until Next = 0;
        end;
    end;

    local procedure GetPersonPeriodDates(var StartDate: Date; var EndDate: Date; PersonNo: Code[20]; RepStartDate: Date; RepEndDate: Date): Boolean
    var
        LaborContractLine: Record "Labor Contract Line";
    begin
        with LaborContractLine do begin
            StartDate := 0D;
            EndDate := 0D;
            FilterLaborContractInfo(LaborContractLine, PersonNo, RepStartDate, RepEndDate);
            if not FindSet then
                exit(false);

            repeat
                StartDate := GetMinDate("Starting Date", StartDate);
                EndDate := GetMaxDate("Ending Date", EndDate);
            until Next = 0;

            StartDate := GetMaxDate(StartDate, RepStartDate);
            EndDate := GetMinDate(EndDate, RepEndDate);
            exit(true);
        end;
    end;

    local procedure GetDisabilityPeriods(var DisabilityPersonMedicalInfo: Record "Person Medical Info"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        PersonMedicalInfo: Record "Person Medical Info";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        // Supported only one type of disability
        // If Person with disability for specified period then "Disability Group" = "1", else = " "
        with DisabilityPersonMedicalInfo do begin
            DeleteAll;
            FilterPersonMedicalDisabilityInfo(PersonMedicalInfo, PersonNo, StartDate, EndDate);
            if PersonMedicalInfo.FindSet then begin
                repeat
                    PeriodStartDate := GetMaxDate(PersonMedicalInfo."Starting Date", StartDate);
                    PeriodEndDate := GetMinDate(PersonMedicalInfo."Ending Date", EndDate);
                    if not FindLast then
                        InsertDisabilityPeriod(DisabilityPersonMedicalInfo, PeriodStartDate, PeriodEndDate, "Disability Group"::"1")
                    else
                        if "Ending Date" < PeriodStartDate then begin
                            InsertDisabilityPeriod(
                              DisabilityPersonMedicalInfo, CalcDate('<+1D>', "Ending Date"),
                              CalcDate('<-1D>', PeriodStartDate), "Disability Group"::" ");
                            InsertDisabilityPeriod(DisabilityPersonMedicalInfo, PeriodStartDate, PeriodEndDate, "Disability Group"::"1");
                        end else begin
                            "Ending Date" := PeriodEndDate;
                            Modify;
                        end;
                until PersonMedicalInfo.Next = 0;

                if PeriodEndDate < EndDate then
                    InsertDisabilityPeriod(
                      DisabilityPersonMedicalInfo, CalcDate('<+1D>', PeriodEndDate), EndDate, "Disability Group"::" ");

                FindFirst;
                if "Starting Date" > StartDate then
                    InsertDisabilityPeriod(
                      DisabilityPersonMedicalInfo, StartDate, CalcDate('<-1D>', "Starting Date"), "Disability Group"::" ");
            end else
                InsertDisabilityPeriod(DisabilityPersonMedicalInfo, StartDate, EndDate, "Disability Group"::" ");
        end;
    end;

    local procedure GetSpecialConditionPeriods(var SpecialConditionPersonMedicalInfo: Record "Person Medical Info"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        LaborContractLine: Record "Labor Contract Line";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        // Use the same method as in GetDisabilityPeriods()
        with SpecialConditionPersonMedicalInfo do begin
            DeleteAll;
            FilterLaborContractSpecialCondInfo(LaborContractLine, PersonNo, StartDate, EndDate);
            if LaborContractLine.FindSet then begin
                repeat
                    PeriodStartDate := GetMaxDate(LaborContractLine."Starting Date", StartDate);
                    PeriodEndDate := GetMinDate(LaborContractLine."Ending Date", EndDate);
                    if not FindLast then
                        InsertSpecialCondPeriod(
                          SpecialConditionPersonMedicalInfo, PeriodStartDate, PeriodEndDate, LaborContractLine."Special Conditions")
                    else begin
                        if "Ending Date" < PeriodStartDate then begin
                            InsertSpecialCondPeriod(
                              SpecialConditionPersonMedicalInfo, CalcDate('<+1D>', "Ending Date"), CalcDate('<-1D>', PeriodStartDate), '');
                            InsertSpecialCondPeriod(
                              SpecialConditionPersonMedicalInfo, PeriodStartDate, PeriodEndDate, LaborContractLine."Special Conditions");
                        end else
                            if "Ending Date" < PeriodEndDate then
                                InsertSpecialCondPeriod(
                                  SpecialConditionPersonMedicalInfo,
                                  CalcDate('<+1D>', "Ending Date"), PeriodEndDate, LaborContractLine."Special Conditions");
                    end;
                until LaborContractLine.Next = 0;

                if PeriodEndDate < EndDate then
                    InsertSpecialCondPeriod(SpecialConditionPersonMedicalInfo, CalcDate('<+1D>', PeriodEndDate), EndDate, '');

                FindFirst;
                if "Starting Date" > StartDate then
                    InsertSpecialCondPeriod(SpecialConditionPersonMedicalInfo, StartDate, CalcDate('<-1D>', "Starting Date"), '');
            end else
                InsertSpecialCondPeriod(SpecialConditionPersonMedicalInfo, StartDate, EndDate, '');
        end;
    end;

    local procedure GetPeriodDates(var StartDate: Date; var EndDate: Date; RepEndDate: Date; PeriodCode: Integer)
    begin
        case PeriodCode of
            0:
                begin
                    StartDate := CalcDate('<-CY>', RepEndDate);
                    EndDate := RepEndDate;
                end;
            1:
                begin
                    StartDate := CalcDate('<-CM-2M>', RepEndDate);
                    EndDate := CalcDate('<-2M+CM>', RepEndDate);
                end;
            2:
                begin
                    StartDate := CalcDate('<-CM-1M>', RepEndDate);
                    EndDate := CalcDate('<-1M+CM>', RepEndDate);
                end;
            3:
                begin
                    StartDate := CalcDate('<-CM>', RepEndDate);
                    EndDate := RepEndDate;
                end;
        end;
    end;

    local procedure GetTariffCode(DisabilityGroup: Option): Code[20]
    var
        PersonMedicalInfo: Record "Person Medical Info";
    begin
        if DisabilityGroup = PersonMedicalInfo."Disability Group"::" " then
            exit('01');
        exit('03');
    end;

    local procedure GetMinDate(Date1: Date; Date2: Date): Date
    begin
        // In case of 0D return non-empty date
        if Date1 = 0D then
            exit(Date2);
        if (Date2 = 0D) or (Date1 < Date2) then
            exit(Date1);
        exit(Date2);
    end;

    local procedure GetMaxDate(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    [Scope('OnPrem')]
    procedure GetReportingPersonList(var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        ReportingPersonPayrollReportingBuffer.DeleteAll;

        if PersonifiedPayrollReportingBuffer.FindSet then
            repeat
                FilterReportingBuffer(ReportingPersonPayrollReportingBuffer, PersonifiedPayrollReportingBuffer);
                if ReportingPersonPayrollReportingBuffer.IsEmpty then begin
                    ReportingPersonPayrollReportingBuffer := PersonifiedPayrollReportingBuffer;
                    ReportingPersonPayrollReportingBuffer.Insert;
                end;
            until PersonifiedPayrollReportingBuffer.Next = 0;

        ReportingPersonPayrollReportingBuffer.Reset;
    end;

    [Scope('OnPrem')]
    procedure GetReportingSheetCount(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer") SheetQty: Integer
    begin
        // Minimum number of pages = 3: Title, Section 1, Section 2.5
        SheetQty := 3;

        // Disability Tariff Code '01'
        PersonifiedPayrollReportingBuffer.SetRange("Code 3", '01');
        if not PersonifiedPayrollReportingBuffer.IsEmpty then
            SheetQty += 1;

        // Disability Tariff Code '03'
        PersonifiedPayrollReportingBuffer.SetRange("Code 3", '03');
        if not PersonifiedPayrollReportingBuffer.IsEmpty then
            SheetQty += 1;

        PersonifiedPayrollReportingBuffer.SetRange("Code 3");

        // Add two pages for each reporting person: Section 12, Section 13
        SheetQty += ReportingPersonPayrollReportingBuffer.Count * 2;
    end;

    local procedure GetFundVendorNo(PayrollElementCode: Code[20]): Code[20]
    var
        PayrollElement: Record "Payroll Element";
        PayrollPostingGroup: Record "Payroll Posting Group";
    begin
        if PayrollElement.Get(PayrollElementCode) then
            if PayrollPostingGroup.Get(PayrollElement."Payroll Posting Group") then
                exit(PayrollPostingGroup."Fund Vendor No.");
    end;

    local procedure GetNextPackNo(var PackNo: Integer; var PersonNo: Integer)
    begin
        PersonNo += 1;
        if PersonNo = MaxNoOfPersonsPerRSVFile then begin
            PackNo += 1;
            PersonNo := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure MaxNoOfPersonsPerRSVFile(): Integer
    begin
        exit(200);
    end;

    local procedure FilterPersonMedicalDisabilityInfo(var PersonMedicalInfo: Record "Person Medical Info"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        with PersonMedicalInfo do begin
            SetRange("Person No.", PersonNo);
            SetRange(Type, Type::Disability);
            SetFilter("Disability Group", '>0');
            SetFilter("Starting Date", '..%1', EndDate);
            SetFilter("Ending Date", '%1..|%2', StartDate, 0D);
        end;
    end;

    local procedure FilterLaborContractSpecialCondInfo(var LaborContractLine: Record "Labor Contract Line"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        with LaborContractLine do begin
            SetRange("Person No.", PersonNo);
            SetRange("Operation Type", "Operation Type"::Hire, "Operation Type"::Combination);
            SetFilter("Starting Date", '..%1', EndDate);
            SetFilter("Ending Date", '%1..|%2', StartDate, 0D);
            SetFilter("Special Conditions", '<>%1', '');
        end;
    end;

    local procedure FilterLaborContractInfo(var LaborContractLine: Record "Labor Contract Line"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        with LaborContractLine do begin
            SetRange("Person No.", PersonNo);
            SetRange("Operation Type", "Operation Type"::Hire, "Operation Type"::Combination);
            SetFilter("Starting Date", '..%1', EndDate);
            SetFilter("Ending Date", '%1..|%2', StartDate, 0D);
        end;
    end;

    [Scope('OnPrem')]
    procedure FilterReportingBuffer(var ToPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var FromPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        ToPayrollReportingBuffer.SetRange("Code 1", FromPayrollReportingBuffer."Code 1");
        ToPayrollReportingBuffer.SetRange("Code 3", FromPayrollReportingBuffer."Code 3");
        ToPayrollReportingBuffer.SetRange("Code 4", FromPayrollReportingBuffer."Code 4");
    end;

    local procedure InsertDisabilityPeriod(var PersonMedicalInfo: Record "Person Medical Info"; StartDate: Date; EndDate: Date; DisabilityGroup: Option)
    begin
        with PersonMedicalInfo do begin
            Init;
            "Starting Date" := StartDate;
            "Ending Date" := EndDate;
            "Disability Group" := DisabilityGroup;
            Insert;
        end;
    end;

    local procedure InsertSpecialCondPeriod(var SpecialConditionPersonMedicalInfo: Record "Person Medical Info"; StartDate: Date; EndDate: Date; SpecialCode: Code[20])
    begin
        // Use field "Person Medical Info"."Insurer No." as a Special Condition Code
        with SpecialConditionPersonMedicalInfo do begin
            Init;
            "Starting Date" := StartDate;
            "Ending Date" := EndDate;
            "Insurer No." := SpecialCode;
            Insert;
        end;
    end;

    local procedure InsertPersRepBuffer(var RSVPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PersonNo: Code[20]; PeriodCode: Code[20]; TariffCode: Code[20]; SpecialCode: Code[20]; PayrollAmounts: array[8] of Decimal)
    var
        LastEntryNo: Integer;
    begin
        with RSVPayrollReportingBuffer do begin
            SetRange("Pack No.");
            SetRange("Code 1", PersonNo);
            SetRange("Code 2", PeriodCode);
            SetRange("Code 3", TariffCode);
            SetRange("Code 4", SpecialCode);
            if FindFirst then begin
                AddPersRepBuffAmounts(RSVPayrollReportingBuffer, PayrollAmounts);
                Modify;
            end else begin
                LastEntryNo := 0;
                Reset;
                if FindLast then
                    LastEntryNo := "Entry No.";
                Init;
                "Entry No." := LastEntryNo + 1;
                "Code 1" := PersonNo;
                "Code 2" := PeriodCode;
                "Code 3" := TariffCode;
                "Code 4" := SpecialCode;
                AddPersRepBuffAmounts(RSVPayrollReportingBuffer, PayrollAmounts);
                "Pack No." := 0;
                Insert;
            end;
        end;
    end;

    local procedure CheckHRSetup()
    begin
        with HumanResourcesSetup do begin
            Get;

            TestField("PF BASE Element Code"); // RSV-2014-6.4-4
            TestField("PF OVER Limit Element Code"); // RSV-2014-6.4-7
            TestField("PF INS Limit Element Code"); // RSV-2014-6.5
            TestField("PF SPECIAL 1 Element Code"); // RSV-2014-6.7-4
            TestField("PF SPECIAL 2 Element Code"); // RSV-2014-6.7-5
            TestField("PF MI NO TAX Element Code");
            TestField("TAX PF INS Element Code");
            TestField("TAX FED FMI Element Code");

            PayrollElementCode[1] := "PF BASE Element Code";
            PayrollElementCode[2] := "PF OVER Limit Element Code";
            PayrollElementCode[3] := "PF INS Limit Element Code";
            PayrollElementCode[4] := "PF SPECIAL 1 Element Code";
            PayrollElementCode[5] := "PF SPECIAL 2 Element Code";
            PayrollElementCode[6] := "PF MI NO TAX Element Code";
            PayrollElementCode[7] := "TAX PF INS Element Code";
            PayrollElementCode[8] := "TAX FED FMI Element Code";
        end;
    end;

    local procedure CheckAmounts(Amounts: array[8] of Decimal): Boolean
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Amounts) do
            if Amounts[i] <> 0 then
                exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CreatePersonExperienceBuffer(var ExperienceLaborContractLine: Record "Labor Contract Line"; PersonNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        Employee: Record Employee;
        PersonifiedAccountingMgt: Codeunit "Personified Accounting Mgt.";
    begin
        with Employee do begin
            SetRange("No.", PersonNo);
            if FindSet then
                repeat
                    PersonifiedAccountingMgt.CreateExperienceBuffer(ExperienceLaborContractLine, "No.", StartDate, EndDate);
                until Next = 0;
        end;
    end;

    local procedure UpdatePackNoInBuffer(var PayrollReportingBuffer: Record "Payroll Reporting Buffer"; PackNo: Integer) EntryIsAdded: Boolean
    begin
        with PayrollReportingBuffer do begin
            Reset;
            SetRange("Pack No.", 0);
            EntryIsAdded := not IsEmpty;
            ModifyAll("Pack No.", PackNo);
            exit(EntryIsAdded);
        end;
    end;
}

