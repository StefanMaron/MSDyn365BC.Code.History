codeunit 17471 "RSV Excel Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        HumanResourcesSetup: Record "Human Resources Setup";
        ExcelMgt: Codeunit "Excel Management";
        ExcelExportProgressMsg: Label 'Export data to Excel\ @1@@@@@@@@@@@@@';
        RSVCalculationMgt: Codeunit "RSV Calculation Mgt.";
        Window: Dialog;
        TotalSheetCount: Integer;
        SheetCounter: Integer;

    [Scope('OnPrem')]
    procedure ExportRSVToExcel(var Person: Record Person; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel)
    var
        ExcelTemplate: Record "Excel Template";
        TempDetailPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        FileName: Text[250];
    begin
        if Person.IsEmpty() then
            exit;
        CompanyInfo.Get();
        HumanResourcesSetup.Get();
        HumanResourcesSetup.TestField("RSV Template Code");

        FileName := CopyStr(ExcelTemplate.OpenTemplate(HumanResourcesSetup."RSV Template Code"), 1, MaxStrLen(FileName));
        ExcelMgt.OpenBookForUpdate(FileName);
        SheetCounter := 0;
        Window.Open(ExcelExportProgressMsg);

        RSVCalculationMgt.CalcDetailedBuffer(
          TempDetailPayrollReportingBuffer, TempTotalPaidPayrollReportingBuffer, Person, StartDate, EndDate);
        RSVCalculationMgt.CalcBeginBalanceBuffer(TempTotalPaidPayrollReportingBuffer, Person, StartDate);
        RSVCalculationMgt.GetReportingPersonList(TempPersonPayrollReportingBuffer, TempDetailPayrollReportingBuffer);
        TotalSheetCount :=
          RSVCalculationMgt.GetReportingSheetCount(TempDetailPayrollReportingBuffer, TempPersonPayrollReportingBuffer);

        CompanyInfo.TestField("Pension Fund Registration No.");
        ExportCommonPart(
          TempDetailPayrollReportingBuffer,
          TempTotalPaidPayrollReportingBuffer, EndDate, TempPersonPayrollReportingBuffer.Count);
        StartDate := CalcDate('<-CM-2M>', EndDate);
        ExportDetailedPart(TempDetailPayrollReportingBuffer, TempPersonPayrollReportingBuffer, StartDate, EndDate, InfoType);

        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResourcesSetup."RSV Template Code"));
    end;

    local procedure ExportCommonPart(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; EndDate: Date; EmployeeQty: Integer)
    var
        IsDisability: Boolean;
    begin
        Page1_Fill(EndDate, EmployeeQty);
        Page2_Fill(DetailPayrollReportingBuffer, TotalPaidPayrollReportingBuffer);

        DetailPayrollReportingBuffer.Reset();
        DetailPayrollReportingBuffer.SetRange("Code 3", '03');
        IsDisability := not DetailPayrollReportingBuffer.IsEmpty;

        // Fill Total Employee Info without Disability (TariffCode = 01)
        DetailPayrollReportingBuffer.SetRange("Code 3", '01');
        if not (IsDisability and DetailPayrollReportingBuffer.IsEmpty) then
            Page3_Fill(DetailPayrollReportingBuffer);

        // Fill Total Employee Info with Disability (TariffCode = 03)
        DetailPayrollReportingBuffer.SetRange("Code 3", '03');
        Page3_Fill(DetailPayrollReportingBuffer);
        DetailPayrollReportingBuffer.SetRange("Code 3");

        Page6_Fill(DetailPayrollReportingBuffer);
    end;

    local procedure ExportDetailedPart(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel)
    var
        StartSheetNo: Integer;
        PersonCount: Integer;
        TemplateSheet11Name: Text[30];
        TemplateSheet12Name: Text[30];
        i: Integer;
    begin
        StartSheetNo := SheetCounter;

        ExcelMgt.OpenSheetByNumber(StartSheetNo + 1);
        TemplateSheet11Name := ExcelMgt.GetSheetName;
        ExcelMgt.OpenSheetByNumber(StartSheetNo + 2);
        TemplateSheet12Name := ExcelMgt.GetSheetName;

        PersonCount := ReportingPersonPayrollReportingBuffer.Count();
        PersonifiedPayrollReportingBuffer.Reset();
        if ReportingPersonPayrollReportingBuffer.FindSet then
            repeat
                RSVCalculationMgt.FilterReportingBuffer(PersonifiedPayrollReportingBuffer, ReportingPersonPayrollReportingBuffer);
                Page11_Fill(PersonifiedPayrollReportingBuffer, TemplateSheet11Name, PersonCount, StartSheetNo, StartDate, EndDate, InfoType);
                Page12_Fill(PersonifiedPayrollReportingBuffer, TemplateSheet12Name, PersonCount, StartSheetNo, EndDate);
                PersonCount -= 1;
            until ReportingPersonPayrollReportingBuffer.Next() = 0;

        for i := 1 to 2 do begin
            ExcelMgt.OpenSheetByNumber(ExcelMgt.GetSheetsCount);
            ExcelMgt.DeleteSheet(ExcelMgt.GetSheetName);
        end;
    end;

    local procedure Page1_Fill(EndDate: Date; EmployeeQty: Integer)
    var
        PhoneNo: Text[30];
    begin
        PageX_New('AZ15', 'BL15', 'BX15', 'CV15');

        Page1_FillCorrectionNo(0);
        Page1_FillAccountingPeriod(GetAccountingPeriod(EndDate));
        Page1_FillYear(Date2DMY(EndDate, 3));
        Page1_FillCompanyName(CompanyInfo.Name);
        Page1_FillINN(Format(CompanyInfo."VAT Registration No."));
        Page1_FillOKVED(CompanyInfo."OKVED Code");
        Page1_FillKPP(CompanyInfo."KPP Code");
        PhoneNo := DelChr(CompanyInfo."Phone No.", '=', DelChr(CompanyInfo."Phone No.", '=', '0123456789'));
        Page1_FillPhoneNumber(PhoneNo);
        Page1_FillQuantityOfInsuredPersons(EmployeeQty);
        Page1_FillAverageCount(EmployeeQty);
        Page1_FillPageCount(TotalSheetCount);
    end;

    local procedure Page2_Fill(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        TempTotalChargeAmtPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt100PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt130PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt150PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
    begin
        PageX_New('BD2', 'BP2', 'CB2', 'CZ2');

        // Calculate Amounts
        RSVCalculationMgt.CalcTotals110_113(DetailPayrollReportingBuffer, TempTotalChargeAmtPayrollReportingBuffer);
        RSVCalculationMgt.CalcTotals100(TotalPaidPayrollReportingBuffer, TempTotalAmt100PayrollReportingBuffer);
        RSVCalculationMgt.CalcTotalsSums(
          TempTotalAmt130PayrollReportingBuffer, TempTotalAmt100PayrollReportingBuffer, TempTotalChargeAmtPayrollReportingBuffer, 1);
        RSVCalculationMgt.CalcTotalsSums(
          TempTotalAmt150PayrollReportingBuffer, TempTotalAmt130PayrollReportingBuffer, TotalPaidPayrollReportingBuffer, -1);

        // Fill Amount Values
        Page2_FillPaymentInfo(TempTotalAmt100PayrollReportingBuffer, 10);
        Page2_FillPaymentInfo110_140(TempTotalChargeAmtPayrollReportingBuffer, 11);
        Page2_FillPaymentInfo110_140(TotalPaidPayrollReportingBuffer, 19);
        Page2_FillPaymentInfo(TempTotalAmt130PayrollReportingBuffer, 18);
        Page2_FillPaymentInfo(TempTotalAmt150PayrollReportingBuffer, 24);

        // Fill empty Values
        TempTotalAmt100PayrollReportingBuffer.Init();
        Page2_FillPaymentInfo(TempTotalAmt100PayrollReportingBuffer, 16);
        Page2_FillPaymentInfo(TempTotalAmt100PayrollReportingBuffer, 17);
    end;

    local procedure Page3_Fill(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        TemplateSheetName: Text[30];
        i: Integer;
        Amount200: array[4] of Decimal;
        Amount201: array[4] of Decimal;
        Amount202: array[4] of Decimal;
        Amount203: array[4] of Decimal;
        Amount204: array[4] of Decimal;
        Amount205: array[4] of Decimal;
        Amount206: array[4] of Decimal;
        Amount207: array[4] of Decimal;
        Amount208: array[4] of Decimal;
        Amount210: array[4] of Decimal;
        Amount211: array[4] of Decimal;
        Amount212: array[4] of Decimal;
        Amount213: array[4] of Decimal;
        Amount214: array[4] of Decimal;
        Amount215: array[4] of Decimal;
    begin
        if (not PersonifiedPayrollReportingBuffer.FindFirst) and (SheetCounter >= 3) then
            exit;

        if SheetCounter >= 3 then begin
            ExcelMgt.OpenSheetByNumber(3);
            TemplateSheetName := ExcelMgt.GetSheetName;
            ExcelMgt.OpenSheetByNumber(4);
            ExcelMgt.CopySheet(TemplateSheetName, ExcelMgt.GetSheetName, StrSubstNo('%1 (_2_)', TemplateSheetName));
        end;

        PageX_New('AZ2', 'BL2', 'BX2', 'CV2');
        Page3_FillTariffCode(PersonifiedPayrollReportingBuffer."Code 3");

        // Calculate Amounts
        for i := 0 to 3 do begin
            PersonifiedPayrollReportingBuffer.SetRange("Code 2", Format(i));
            PersonifiedPayrollReportingBuffer.CalcSums("Amount 1", "Amount 3", "Amount 4", "Amount 7", "Amount 8", "Amount 9");
            Amount200[i + 1] := PersonifiedPayrollReportingBuffer."Amount 1";
            Amount201[i + 1] := PersonifiedPayrollReportingBuffer."Amount 1" - PersonifiedPayrollReportingBuffer."Amount 7";
            Amount202[i + 1] := 0;
            Amount203[i + 1] := PersonifiedPayrollReportingBuffer."Amount 3";
            Amount204[i + 1] := Amount200[i + 1] - Amount201[i + 1] - Amount202[i + 1] - Amount203[i + 1];
            Amount205[i + 1] := -PersonifiedPayrollReportingBuffer."Amount 4";
            Amount206[i + 1] := -(PersonifiedPayrollReportingBuffer."Amount 8" - PersonifiedPayrollReportingBuffer."Amount 4");

            PersonifiedPayrollReportingBuffer.SetFilter("Amount 7", '<>%1', 0);
            Amount207[i + 1] := PersonifiedPayrollReportingBuffer.Count();
            PersonifiedPayrollReportingBuffer.SetRange("Amount 7");

            PersonifiedPayrollReportingBuffer.SetFilter("Amount 3", '<>%1', 0);
            Amount208[i + 1] := PersonifiedPayrollReportingBuffer.Count();
            PersonifiedPayrollReportingBuffer.SetRange("Amount 3");

            Amount210[i + 1] := Amount200[i + 1];
            Amount211[i + 1] := Amount201[i + 1];
            Amount212[i + 1] := 0;
            Amount213[i + 1] := Amount210[i + 1] - Amount211[i + 1] - Amount212[i + 1];
            Amount214[i + 1] := -PersonifiedPayrollReportingBuffer."Amount 9";

            PersonifiedPayrollReportingBuffer.SetFilter("Amount 9", '<>%1', 0);
            Amount215[i + 1] := PersonifiedPayrollReportingBuffer.Count();
            PersonifiedPayrollReportingBuffer.SetRange("Amount 9");
        end;

        // Fill Amounts
        Page3_FillPaymentInfo(Amount200, 12);
        Page3_FillPaymentInfo(Amount201, 13);
        Page3_FillPaymentInfo(Amount202, 14);
        Page3_FillPaymentInfo(Amount203, 15);
        Page3_FillPaymentInfo(Amount204, 16);
        Page3_FillPaymentInfo(Amount205, 17);
        Page3_FillPaymentInfo(Amount206, 18);
        Page3_FillPaymentInfo(Amount207, 19);
        Page3_FillPaymentInfo(Amount208, 20);

        Page3_FillPaymentInfo(Amount210, 22);
        Page3_FillPaymentInfo(Amount211, 23);
        Page3_FillPaymentInfo(Amount212, 24);
        Page3_FillPaymentInfo(Amount213, 25);
        Page3_FillPaymentInfo(Amount214, 26);
        Page3_FillPaymentInfo(Amount215, 27);
    end;

    local procedure Page6_Fill(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        PageX_New('AW2', 'BI2', 'BU2', 'CS2');
        Page6_FillPackInfo(PersonifiedPayrollReportingBuffer);
    end;

    local procedure Page11_Fill(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; TemplateSheetName: Text[30]; EmployeeNo: Integer; StartSheetNo: Integer; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel)
    var
        Person: Record Person;
        TempPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        PeriodNo: Integer;
        RowNo: Integer;
        EmptyRowNo: Integer;
    begin
        if not PersonifiedPayrollReportingBuffer.FindFirst then
            exit;

        Person.Get(PersonifiedPayrollReportingBuffer."Code 1");

        ExcelMgt.OpenSheetByNumber(StartSheetNo + 1);
        ExcelMgt.CopySheet(TemplateSheetName, ExcelMgt.GetSheetName, StrSubstNo('%1 (_%2_)', TemplateSheetName, EmployeeNo));
        Page11_New(StartSheetNo + 1, StartSheetNo + 1 + (EmployeeNo - 1) * 2);

        // Fill Page11 Header
        Page11_FillInsuredPersonInfo(Person, StartDate, EndDate);
        Page11_FillAccountingPeriod(GetAccountingPeriod(EndDate));
        Page11_FillYear(Date2DMY(EndDate, 3));
        Page11_FillInfoType(InfoType);

        // Fill Table 6.4
        if PersonifiedPayrollReportingBuffer.GetFilter("Code 3") = '01' then begin
            RowNo := 36;
            EmptyRowNo := 40;
        end else begin
            RowNo := 40;
            EmptyRowNo := 36;
        end;
        for PeriodNo := 0 to 3 do begin
            Page11_FillPaymentInfo(PersonifiedPayrollReportingBuffer, PeriodNo, RowNo);
            Page11_FillPaymentInfo(TempPayrollReportingBuffer, PeriodNo, EmptyRowNo);
        end;

        // Fill Table 6.5
        PersonifiedPayrollReportingBuffer.SetFilter("Code 2", '<>%1', '0');
        PersonifiedPayrollReportingBuffer.CalcSums("Amount 4");
        Page11_FillInsurancePaymentsInfo(-PersonifiedPayrollReportingBuffer."Amount 4");
        PersonifiedPayrollReportingBuffer.SetRange("Code 2");
    end;

    local procedure Page12_Fill(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; TemplateSheetName: Text[30]; EmployeeNo: Integer; StartSheetNo: Integer; EndDate: Date)
    var
        TempSpecialCodeListEmployee: Record Employee temporary;
        TempExperienceLaborContractLine: Record "Labor Contract Line" temporary;
        PeriodNo: Integer;
        i: Integer;
        RowNo: Integer;
    begin
        if not PersonifiedPayrollReportingBuffer.FindFirst then
            exit;

        ExcelMgt.OpenSheetByNumber(StartSheetNo + 2);
        ExcelMgt.CopySheet(TemplateSheetName, ExcelMgt.GetSheetName, StrSubstNo('%1 (_%2_)', TemplateSheetName, EmployeeNo));

        Page12_New(StartSheetNo + 2, StartSheetNo + 2 + (EmployeeNo - 1) * 2);

        // Fill Table 6.7 "Special Condition Codes"
        GetEmployeeSpecialCodeList(TempSpecialCodeListEmployee, PersonifiedPayrollReportingBuffer);
        PersonifiedPayrollReportingBuffer.SetRange("Code 4");
        if TempSpecialCodeListEmployee.FindSet then
            repeat
                PersonifiedPayrollReportingBuffer.SetRange("Code 4", TempSpecialCodeListEmployee."No.");
                for PeriodNo := 0 to 3 do
                    Page12_FillPaymentInfo(PersonifiedPayrollReportingBuffer, PeriodNo);
            until TempSpecialCodeListEmployee.Next() = 0;
        PersonifiedPayrollReportingBuffer.SetRange("Code 2");
        PersonifiedPayrollReportingBuffer.SetRange("Code 4");

        // Fill Table 6.8 Working Experience for the last 3 month
        RSVCalculationMgt.CreatePersonExperienceBuffer(
          TempExperienceLaborContractLine, PersonifiedPayrollReportingBuffer."Code 1", CalcDate('<-CM-2M>', EndDate), EndDate);
        RowNo := 27;
        i := 0;
        if TempExperienceLaborContractLine.FindSet then begin
            repeat
                i += 1;
                Page12_FillWorkingPeriods(i, RowNo, TempExperienceLaborContractLine);
                RowNo += 1;
                if i < TempExperienceLaborContractLine.Count then
                    ExcelMgt.CopyRow(RowNo - 1);
            until TempExperienceLaborContractLine.Next() = 0;
        end;
    end;

    local procedure Page1_FillCorrectionNo(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('Z25', 3, 1, Format(Value), '0', 0);
    end;

    local procedure Page1_FillAccountingPeriod(Value: Integer)
    begin
        ExcelMgt.FillCell('BR25', Format(Value));
    end;

    local procedure Page1_FillYear(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('DB25', 4, 1, Format(Value), ' ', 1);
    end;

    local procedure Page1_FillCompanyName(Value: Text[1024])
    begin
        ExcelMgt.FillCell('A30', Value);
    end;

    local procedure Page1_FillINN(Value: Text[250])
    begin
        ExcelMgt.FillCellsGroup2('K33', 12, 1, Value, '-', 0);
    end;

    local procedure Page1_FillOKVED(Value: Text[250])
    begin
        ExcelMgt.FillCellsGroup2('BV33', 2, 1, Value, ' ', 1);
        ExcelMgt.FillCellsGroup2('CE33', 3, 1, CopyStr(Value, 4, 2), ' ', 1);
        ExcelMgt.FillCellsGroup2('CN33', 5, 1, CopyStr(Value, 7, 5), ' ', 1);
    end;

    local procedure Page1_FillKPP(Value: Text[250])
    begin
        ExcelMgt.FillCellsGroup2('K35', 9, 1, Value, ' ', 1);
    end;

    local procedure Page1_FillPhoneNumber(PhoneNumber: Text[250])
    begin
        PhoneNumber := DelChr(PhoneNumber, '=', '(');
        PhoneNumber := DelChr(PhoneNumber, '=', ')');
        PhoneNumber := DelChr(PhoneNumber, '=', '-');
        PhoneNumber := DelChr(PhoneNumber, '=', ' ');
        ExcelMgt.FillCellsGroup2('BV35', 14, 1, PhoneNumber, ' ', 0);
    end;

    [Scope('OnPrem')]
    procedure Page1_FillQuantityOfInsuredPersons(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('AG37', 6, 1, Format(Value), '0', 0);
    end;

    [Scope('OnPrem')]
    procedure Page1_FillAverageCount(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('CT37', 6, 1, Format(Value), '0', 0);
    end;

    local procedure Page1_FillPageCount(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('F40', 6, 1, Format(Value), '0', 0);
    end;

    local procedure Page2_FillPaymentInfo110_140(var AmountsPayrollReportingBuffer: Record "Payroll Reporting Buffer"; RowNo: Integer)
    var
        i: Integer;
    begin
        for i := 0 to 3 do
            if AmountsPayrollReportingBuffer.Get(i + 1) then
                Page2_FillPaymentInfo(AmountsPayrollReportingBuffer, RowNo + i);

        AmountsPayrollReportingBuffer.Reset();
        AmountsPayrollReportingBuffer.SetRange("Entry No.", 2, 4);
        AmountsPayrollReportingBuffer.CalcSums("Amount 1", "Amount 2", "Amount 3", "Amount 4", "Amount 5", "Amount 6");
        Page2_FillPaymentInfo(AmountsPayrollReportingBuffer, RowNo + 4);
    end;

    local procedure Page2_FillPaymentInfo(AmountsPayrollReportingBuffer: Record "Payroll Reporting Buffer"; RowNo: Integer)
    begin
        PrintDig('AR' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 1");
        PrintDig('BD' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 2");
        PrintDig('BO' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 3");
        PrintDig('CB' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 4");
        PrintDig('CU' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 5");
        PrintDig('DN' + Format(RowNo), AmountsPayrollReportingBuffer."Amount 6");
    end;

    local procedure Page3_FillTariffCode(Value: Text[250])
    begin
        ExcelMgt.FillCellsGroup2('DV4', 2, 1, Value, ' ', 2);
    end;

    local procedure Page3_FillPaymentInfo(Amounts: array[4] of Decimal; RowNo: Integer)
    begin
        PrintDig('BO' + Format(RowNo), Amounts[1]);
        PrintDig('CQ' + Format(RowNo), Amounts[2]);
        PrintDig('DD' + Format(RowNo), Amounts[3]);
        PrintDig('DQ' + Format(RowNo), Amounts[4]);
    end;

    local procedure Page6_FillPackInfo(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        Amount2: Decimal;
        Amount4: Decimal;
    begin
        PersonifiedPayrollReportingBuffer.SetFilter("Code 2", '<>%1', '0');
        PersonifiedPayrollReportingBuffer.CalcSums("Amount 2", "Amount 4");
        Amount2 := PersonifiedPayrollReportingBuffer."Amount 2";
        Amount4 := -PersonifiedPayrollReportingBuffer."Amount 4";

        PersonifiedPayrollReportingBuffer.SetRange("Code 2", '0');

        // Pack #1
        PrintDig('A12', 1);
        PrintDig('H12', Amount2);
        PrintDig('AX12', Amount4);
        PrintDig('CD12', PersonifiedPayrollReportingBuffer.Count);
        PrintDig('CU12', 1);

        // Total
        PrintDig('H13', Amount2);
        PrintDig('AX13', Amount4);
        PrintDig('CD13', PersonifiedPayrollReportingBuffer.Count);
    end;

    local procedure Page11_New(OpenSheetNo: Integer; PageNo: Integer)
    begin
        SheetCounter += 1;
        ExcelMgt.OpenSheetByNumber(OpenSheetNo);
        Window.Update(1, Round(SheetCounter / TotalSheetCount * 10000, 1));

        PageX_FillPFRegistrationNo('AZ2', 'BL2', 'BX2');
        PageX_FillPageNo(PageNo, 'CV2');
    end;

    local procedure Page11_FillInsuredPersonInfo(Person: Record Person; StartDate: Date; EndDate: Date)
    var
        LaborContract: Record "Labor Contract";
    begin
        ExcelMgt.FillCell('A10', Person."Last Name");
        ExcelMgt.FillCell('AA10', Person."First Name");
        ExcelMgt.FillCell('BA10', Person."Middle Name");
        ExcelMgt.FillCell('BY10', Person."Social Security No.");

        LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Labor Contract");
        LaborContract.SetRange("Person No.", Person."No.");
        LaborContract.SetFilter("Ending Date", '>=%1&<=%2', StartDate, EndDate);

        if LaborContract.FindFirst then
            ExcelMgt.FillCell('AW12', 'X')
    end;

    local procedure Page11_FillAccountingPeriod(Value: Integer)
    begin
        ExcelMgt.FillCell('AA16', Format(Value));
    end;

    local procedure Page11_FillYear(Value: Integer)
    begin
        ExcelMgt.FillCellsGroup2('CL16', 4, 1, Format(Value), ' ', 1);
    end;

    local procedure Page11_FillInfoType(InfoType: Option Initial,Corrective,Cancel)
    begin
        case InfoType of
            InfoType::Initial:
                ExcelMgt.FillCell('A21', 'X');
            InfoType::Corrective:
                ExcelMgt.FillCell('R21', 'X');
            InfoType::Cancel:
                ExcelMgt.FillCell('AP21', 'X');
        end;
    end;

    local procedure Page11_FillPaymentInfo(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PeriodNo: Integer; RowNo: Integer)
    var
        TempPrintPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
    begin
        TempPrintPayrollReportingBuffer.Init();
        PersonifiedPayrollReportingBuffer.SetRange("Code 2", Format(PeriodNo));
        if PersonifiedPayrollReportingBuffer.FindFirst then
            TempPrintPayrollReportingBuffer := PersonifiedPayrollReportingBuffer;

        PrintText('AF' + Format(RowNo + PeriodNo), GetDisabilityCategoryName(TempPrintPayrollReportingBuffer."Code 3"));
        PrintDig('AO' + Format(RowNo + PeriodNo), TempPrintPayrollReportingBuffer."Amount 1");
        PrintDig('BH' + Format(RowNo + PeriodNo), TempPrintPayrollReportingBuffer."Amount 2");
        PrintDig('CE' + Format(RowNo + PeriodNo), 0);
        PrintDig('CZ' + Format(RowNo + PeriodNo), TempPrintPayrollReportingBuffer."Amount 3");
    end;

    local procedure Page11_FillInsurancePaymentsInfo(Value: Decimal)
    begin
        PrintDig('AM49', Value div 1);
        PrintDig('BS49', (100 * (Value mod 1)) div 1);
    end;

    local procedure Page12_New(OpenSheetNo: Integer; PageNo: Integer)
    begin
        SheetCounter += 1;
        ExcelMgt.OpenSheetByNumber(OpenSheetNo);
        Window.Update(1, Round(SheetCounter / TotalSheetCount * 10000, 1));

        PageX_FillPFRegistrationNo('AU2', 'BG2', 'BS2');
        PageX_FillPageNo(PageNo, 'CQ2');
    end;

    local procedure Page12_FillPaymentInfo(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PeriodNo: Integer)
    var
        PrintPayrollReportingBuffer: Record "Payroll Reporting Buffer";
        RowNo: Integer;
    begin
        PrintPayrollReportingBuffer.Init();
        PersonifiedPayrollReportingBuffer.SetRange("Code 2", Format(PeriodNo));
        if PersonifiedPayrollReportingBuffer.FindFirst then
            PrintPayrollReportingBuffer := PersonifiedPayrollReportingBuffer;

        RowNo := 12 + PeriodNo;
        PrintText('AZ' + Format(RowNo), PrintPayrollReportingBuffer."Code 4");
        PrintDig('BI' + Format(RowNo), PrintPayrollReportingBuffer."Amount 5");
        PrintDig('CL' + Format(RowNo), PrintPayrollReportingBuffer."Amount 6");
    end;

    local procedure Page12_FillWorkingPeriods(No: Integer; RowNo: Integer; ExperienceLaborContractLine: Record "Labor Contract Line")
    begin
        PrintDig(StrSubstNo('A%1', RowNo), No);
        PrintText(StrSubstNo('E%1', RowNo), Format(ExperienceLaborContractLine."Starting Date"));
        PrintText(StrSubstNo('R%1', RowNo), Format(ExperienceLaborContractLine."Ending Date"));
        PrintText(StrSubstNo('AE%1', RowNo), Format(ExperienceLaborContractLine."Territorial Conditions"));
        PrintText(StrSubstNo('AS%1', RowNo), Format(ExperienceLaborContractLine."Special Conditions"));
        PrintText(StrSubstNo('BE%1', RowNo), Format(ExperienceLaborContractLine."Record of Service Reason"));
        PrintText(StrSubstNo('BS%1', RowNo), Format(ExperienceLaborContractLine."Record of Service Additional"));
        PrintText(StrSubstNo('CG%1', RowNo), Format(ExperienceLaborContractLine."Service Years Reason"));
        PrintText(StrSubstNo('CV%1', RowNo), Format(ExperienceLaborContractLine."Service Years Additional"));
    end;

    local procedure PageX_New(Cell1: Text[30]; Cell2: Text[30]; Cell3: Text[30]; Cell4: Text[30])
    begin
        SheetCounter += 1;
        ExcelMgt.OpenSheetByNumber(SheetCounter);
        Window.Update(1, Round(SheetCounter / TotalSheetCount * 10000, 1));

        PageX_FillPFRegistrationNo(Cell1, Cell2, Cell3);
        PageX_FillPageNo(SheetCounter, Cell4);
    end;

    local procedure PageX_FillPFRegistrationNo(Cell1: Text[30]; Cell2: Text[30]; Cell3: Text[30])
    var
        Value: Text[250];
    begin
        Value := Format(CompanyInfo."Pension Fund Registration No.");
        ExcelMgt.FillCellsGroup2(Cell1, 3, 1, Value, ' ', 1);
        ExcelMgt.FillCellsGroup2(Cell2, 3, 1, CopyStr(Value, 5, 3), ' ', 1);
        ExcelMgt.FillCellsGroup2(Cell3, 6, 1, CopyStr(Value, 9, 6), ' ', 1);
    end;

    local procedure PageX_FillPageNo(PageNo: Integer; Cell: Text[30])
    begin
        ExcelMgt.FillCellsGroup2(Cell, 6, 1, Format(PageNo), '0', 0);
    end;

    local procedure GetAccountingPeriod(EndDate: Date): Integer
    var
        Month: Integer;
    begin
        Month := Date2DMY(EndDate, 2);
        if Month = 12 then
            exit(0);
        exit(Month);
    end;

    local procedure GetEmployeeSpecialCodeList(var SpecialCodeListEmployee: Record Employee; var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        SpecialCodeListEmployee.DeleteAll();
        PersonifiedPayrollReportingBuffer.SetFilter("Code 4", '<>%1', '');
        if PersonifiedPayrollReportingBuffer.FindSet then
            repeat
                SpecialCodeListEmployee."No." := PersonifiedPayrollReportingBuffer."Code 4";
                if SpecialCodeListEmployee.Insert() then;
            until PersonifiedPayrollReportingBuffer.Next() = 0;

        if SpecialCodeListEmployee.IsEmpty() then begin
            SpecialCodeListEmployee."No." := 'ZZZZZZZZZZ';
            SpecialCodeListEmployee.Insert();
        end;
    end;

    local procedure GetDisabilityCategoryName(TariffNo: Code[20]): Text[250]
    begin
        case TariffNo of
            '01':
                exit('ìÉ');
            '03':
                exit('ÄÄê');
            else
                exit('-');
        end;
    end;

    local procedure PrintDig(CellName: Text[30]; Value: Decimal)
    begin
        if Value > 0 then
            ExcelMgt.FillCell(CellName, Format(Value))
        else
            ExcelMgt.FillCell(CellName, '-');
    end;

    local procedure PrintText(CellName: Text[30]; Value: Text[250])
    begin
        if Value <> '' then
            ExcelMgt.FillCell(CellName, Value)
        else
            ExcelMgt.FillCell(CellName, '-');
    end;
}

