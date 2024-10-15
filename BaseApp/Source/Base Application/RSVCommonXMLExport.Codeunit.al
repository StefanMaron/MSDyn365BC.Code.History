codeunit 17472 "RSV Common XML Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        RSVCalculationMgt: Codeunit "RSV Calculation Mgt.";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        BlockType: Option All,Period,Additional;
        TotalSheetCount: Integer;
        SkipExport: Boolean;
        ReportingYearTxt: Label 'ReportingYear', Locked = true;
        NumberInPackTxt: Label 'NumberInPack', Locked = true;
        RegistrationNumberPFRTxt: Label 'RegistrationNumberPFR', Locked = true;
        FillDateTxt: Label 'FillDate', Locked = true;
        FilePFRTxt: Label 'FilePFR', Locked = true;
        FileNameTxt: Label 'FileName', Locked = true;
        IncomingDocumentPackTxt: Label 'IncomingDocumentPack', Locked = true;
        SurroundingTxt: Label 'Surrounding', Locked = true;
        FileHeaderTxt: Label 'FileHeader', Locked = true;
        FileTypeTxt: Label 'FileType', Locked = true;
        FormatVersionTxt: Label 'FormatVersion', Locked = true;
        DataPreparationProgramTxt: Label 'DataPreparationProgram', Locked = true;
        ProgramNameTxt: Label 'ProgramName', Locked = true;
        VersionTxt: Label 'Version', Locked = true;
        DataSourceTxt: Label 'DataSourceTxt', Locked = true;
        INSURERTxt: Label 'INSURER', Locked = true;
        INNSymbolicTxt: Label 'INNSymbolic', Locked = true;
        KPPTxt: Label 'KPP', Locked = true;
        LastNameTxt: Label 'LastName', Locked = true;
        FirstNameTxt: Label 'FirstName', Locked = true;
        MiddleNameTxt: Label 'MiddleName', Locked = true;
        PhoneTxt: Label 'Phone', Locked = true;
        CompanyNameTxt: Label 'CompanyName', Locked = true;
        EXTERNALTxt: Label 'EXTERNAL', Locked = true;
        SingleRequestTxt: Label 'Single Request', Locked = true;
        CorrectionNumberTxt: Label 'CorrectionNumber', Locked = true;
        CorrectionTypeTxt: Label 'CorrectionType', Locked = true;
        ReportingPeriodCodeTxt: Label 'ReportingPeriodCode', Locked = true;
        OKVEDCodeTxt: Label 'OKVEDCode', Locked = true;
        QuantityIPTxt: Label 'QuantityIP', Locked = true;
        AverageHeadcountTxt: Label 'AverageHeadcount', Locked = true;
        NumberOfPagesTxt: Label 'NumberOfPages', Locked = true;
        RSVTitleTxt: Label 'RSVTitle', Locked = true;
        ConfirmingPersonTxt: Label 'ConfirmingPerson', Locked = true;
        Chapter1TitleTxt: Label 'Chapter1Title', Locked = true;
        LineCodeTxt: Label 'LineCode', Locked = true;
        OutstandingPaymentDueAtStartDateTxt: Label 'OutstandingPaymentDueAtStartDate', Locked = true;
        OutstandingPaymentDueAtEndDateTxt: Label 'OutstandingPaymentDueAtEndDate', Locked = true;
        AccruedFromCalculationPeriodStartDateTxt: Label 'AccruedFromCalculationPeriodStartDate', Locked = true;
        AddedFromCalculationPeriodStartTotalTxt: Label 'AddedFromCalculationPeriodStartTotal', Locked = true;
        AddedFromCalculationPeriodStartExtraTxt: Label 'AddedFromCalculationPeriodExtraTotal', Locked = true;
        TotalToPayTxt: Label 'TotalToPay', Locked = true;
        PaidFromCalculationPeriodStartDateTxt: Label 'PaidFromCalculationPeriodStartDate', Locked = true;
        InsuranceContributionOPSTxt: Label 'InsuranceContributionOPS', Locked = true;
        InsuranceContributionsOMSTxt: Label 'InsuranceContributionsOMS', Locked = true;
        OPSinsuredPartTxt: Label 'OPSinsuredPart', Locked = true;
        OPSaccumulatedPartTxt: Label 'OPSaccumulatedPart', Locked = true;
        ContributionsByExtraTariffTxt: Label 'ContributionsByExtraTariff', Locked = true;
        LastThreeMonthsTxt: Label 'LastThreeMonths', Locked = true;
        LastThreeMonthsTotalTxt: Label 'LastThreeMonthsTotal', Locked = true;
        TotalFromCalculationPeriodStartDateTxt: Label 'TotalFromCalculationPeriodStartDate', Locked = true;
        Chapter2TitleTxt: Label 'Chapter2Title', Locked = true;
        Chapter21Txt: Label 'Chapter_2_1', Locked = true;
        TariffCodeTxt: Label 'TariffCode', Locked = true;
        ForMandatoryPensionInsuranceTxt: Label 'ForMandatoryPensionInsurance', Locked = true;
        PaymentAndRewardAmountOPSTxt: Label 'PaymentAndRewardAmountOPS', Locked = true;
        NotLiableForOPSTxt: Label 'NotLiableForOPS', Locked = true;
        ExpenseAmountForDeductionOPSTxt: Label 'ExpenseAmountForDeductionOPS', Locked = true;
        AboveBaseLimitOPSTxt: Label 'AboveBaseLimitOPS', Locked = true;
        BaseForInsuranceContributionAccrualsForOPSTxt: Label 'BaseForInsuranceContributionAccrualsForOPS', Locked = true;
        AccruedForOPSForAmountsLessThanTxt: Label 'AccruedForOPSForAmountsLessThan', Locked = true;
        AccruedForOPSForAmountsExceededTxt: Label 'AccruedForOPSForAmountsExceeded', Locked = true;
        QuantotyOfFPtotalTxt: Label 'QuantotyOfFPtotal', Locked = true;
        QuantityFPWithBaseExceedLimitTxt: Label 'QuantityFPWithBaseExceedLimit', Locked = true;
        AmountCalcTxt: Label 'AmountCalc', Locked = true;
        TotalAmountFromCalculationPeriodStartDateTxt: Label 'TotalAmountFromCalculationPeriodStartDate', Locked = true;
        AmountLast1MonthTxt: Label 'AmountLast1Month', Locked = true;
        AmountLast2MonthTxt: Label 'AmountLast2Month', Locked = true;
        AmountLast3MonthTxt: Label 'AmountLast3Month', Locked = true;
        QuantityIP_TotalTxt: Label 'QuantityIP_Total', Locked = true;
        QuantityIP_1monthTxt: Label 'QuantityIP_1month', Locked = true;
        QuantityIP_2monthTxt: Label 'QuantityIP_2month', Locked = true;
        QuantityIP_3monthTxt: Label 'QuantityIP_3month', Locked = true;
        ForMandatoryMedicalInsuranceTxt: Label 'ForMandatoryMedicalInsurance', Locked = true;
        PaymentAndRewardAmountTxt: Label 'PaymentAndRewardAmount', Locked = true;
        NotLiableTxt: Label 'NotLiable', Locked = true;
        ExpenseAmountForDeductionTxt: Label 'ExpenseAmountForDeduction', Locked = true;
        BaseForInsuranceContributionAccrualsForOMSTxt: Label 'BaseForInsuranceContributionAccrualsForOMS', Locked = true;
        AccruedForOMSTxt: Label 'AccruedForOMS', Locked = true;
        QuantityIPTotalTxt: Label 'QuantityIPTotal', Locked = true;
        Chapter25Txt: Label 'Chapter_2_5', Locked = true;
        PackListForPFTxt: Label 'PackListForPF', Locked = true;
        QuantityOfPacksTxt: Label 'QuantityOfPacks', Locked = true;
        InfoAboutPackTxt: Label 'InfoAboutPack', Locked = true;
        TotalInfoByPacksTxt: Label 'TotalInfoByPacks', Locked = true;
        NumberPPTxt: Label 'NumberPP', Locked = true;
        BaseForInsuranceContributionsAccrualsLessThanLimitTxt: Label 'BaseForInsuranceCOntributionsAccrualsLessThanLimit', Locked = true;
        InsuranceContributionsOPSTxt: Label 'InsuranceContributionsOPS', Locked = true;
        QuantityIPInPackTxt: Label 'QuantityIPInPack', Locked = true;
        ConfirmingPersonNameTxt: Label 'ConfirmingPersonName', Locked = true;

    [Scope('OnPrem')]
    procedure ExportCommonXML(var Person: Record Person; var PackPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; FolderName: Text)
    var
        TempDetailPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        XmlDoc: DotNet XmlDocument;
        FileName: Text[250];
    begin
        if Person.IsEmpty then
            exit;

        FileName := GetXMLFileName(StartDate, 0, 0);
        CompanyInfo.Get();

        RSVCalculationMgt.CalcDetailedBuffer(
          TempDetailPayrollReportingBuffer, TempTotalPaidPayrollReportingBuffer, Person, StartDate, EndDate);
        RSVCalculationMgt.CalcBeginBalanceBuffer(TempTotalPaidPayrollReportingBuffer, Person, StartDate);
        RSVCalculationMgt.GetReportingPersonList(TempPersonPayrollReportingBuffer, TempDetailPayrollReportingBuffer);
        TotalSheetCount :=
          RSVCalculationMgt.GetReportingSheetCount(TempDetailPayrollReportingBuffer, TempPersonPayrollReportingBuffer);

        CreateXMLDoc(XmlDoc, XMLCurrNode);
        XMLAddComplexElement(FilePFRTxt);
        XMLAddSimpleElement(FileNameTxt, FileName);
        AddFileHeader;
        XMLAddComplexElement(IncomingDocumentPackTxt);
        XMLAddAttribute(XMLCurrNode, SurroundingTxt, SingleRequestTxt);

        FillInsuranceCalculation(
          CreationDate, EndDate, TempPersonPayrollReportingBuffer.Count,
          TempDetailPayrollReportingBuffer, TempTotalPaidPayrollReportingBuffer, PackPayrollReportingBuffer);

        if not SkipExport then
            SaveXMLFile(XmlDoc, FolderName, FileName);
    end;

    local procedure FillInsuranceCalculation(CreationDate: Date; EndDate: Date; EmployeeQty: Integer; var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var PackPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        PhoneNo: Text[30];
    begin
        XMLAddComplexElement(RSVTitleTxt);
        XMLAddSimpleElement(NumberInPackTxt, '1');
        XMLAddSimpleElement(RegistrationNumberPFRTxt, CompanyInfo."Pension Fund Registration No.");
        XMLAddSimpleElement(CorrectionNumberTxt, '000');
        XMLAddSimpleElement(ReportingPeriodCodeTxt, Format(GetAccountingPeriod(EndDate), 0, 9));
        XMLAddSimpleElement(ReportingYearTxt, Format(Date2DMY(EndDate, 3), 0, 9));
        XMLAddSimpleElement(CorrectionTypeTxt, '');
        XMLAddSimpleElement(CompanyNameTxt, CompanyInfo.Name);
        XMLAddSimpleElement(INNSymbolicTxt, CompanyInfo."VAT Registration No.");
        XMLAddSimpleElement(KPPTxt, CompanyInfo."KPP Code");
        XMLAddSimpleElement(OKVEDCodeTxt, CompanyInfo."OKVED Code");
        PhoneNo := DelChr(CompanyInfo."Phone No.", '=', DelChr(CompanyInfo."Phone No.", '=', '0123456789'));
        XMLAddSimpleElement(PhoneTxt, PhoneNo);
        XMLAddSimpleElement(QuantityIPTxt, Format(EmployeeQty, 0, 9));
        XMLAddSimpleElement(AverageHeadcountTxt, FormatDecimal(EmployeeQty));
        XMLAddSimpleElement(NumberOfPagesTxt, Format(TotalSheetCount, 0, 9));

        FillSection1(DetailPayrollReportingBuffer, TotalPaidPayrollReportingBuffer);
        FillSection2(DetailPayrollReportingBuffer, PackPayrollReportingBuffer);

        XMLAddSimpleElement(ConfirmingPersonTxt, '1');
        FillResponsibleName;

        XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
        XMLBackToParent;
    end;

    local procedure FillSection1(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var TotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
        TempTotalChargeAmtPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt100PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt130PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalAmt150PayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
    begin
        XMLAddComplexElement(Chapter1TitleTxt);

        // Calculate Amounts
        RSVCalculationMgt.CalcTotals110_113(DetailPayrollReportingBuffer, TempTotalChargeAmtPayrollReportingBuffer);
        RSVCalculationMgt.CalcTotals100(TotalPaidPayrollReportingBuffer, TempTotalAmt100PayrollReportingBuffer);
        RSVCalculationMgt.CalcTotalsSums(
          TempTotalAmt130PayrollReportingBuffer, TempTotalAmt100PayrollReportingBuffer, TempTotalChargeAmtPayrollReportingBuffer, 1);
        RSVCalculationMgt.CalcTotalsSums(
          TempTotalAmt150PayrollReportingBuffer, TempTotalAmt130PayrollReportingBuffer, TotalPaidPayrollReportingBuffer, -1);

        FillPayments(OutstandingPaymentDueAtStartDateTxt, BlockType::All, '100', TempTotalAmt100PayrollReportingBuffer);
        FillPaymentsForPeriod(AccruedFromCalculationPeriodStartDateTxt, BlockType::Period, 110, TempTotalChargeAmtPayrollReportingBuffer);

        // Empty Values
        TempTotalAmt100PayrollReportingBuffer.Init();
        FillPayments(AddedFromCalculationPeriodStartTotalTxt, BlockType::All, '120', TempTotalAmt100PayrollReportingBuffer);
        FillPayments(AddedFromCalculationPeriodStartExtraTxt, BlockType::Additional, '121', TempTotalAmt100PayrollReportingBuffer);
        FillPayments(TotalToPayTxt, BlockType::All, '130', TempTotalAmt130PayrollReportingBuffer);
        FillPaymentsForPeriod(PaidFromCalculationPeriodStartDateTxt, BlockType::All, 140, TotalPaidPayrollReportingBuffer);
        FillPayments(OutstandingPaymentDueAtEndDateTxt, BlockType::All, '150', TempTotalAmt150PayrollReportingBuffer);

        XMLBackToParent;
    end;

    local procedure FillPayments(BlockNodeText: Text[250]; BlockType: Option All,Period,Additional; LineCode: Text[250]; var AmountsPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        XMLAddComplexElement(BlockNodeText);

        XMLAddSimpleElement(LineCodeTxt, LineCode);
        XMLAddSimpleElement(InsuranceContributionOPSTxt, FormatDecimal(AmountsPayrollReportingBuffer."Amount 1"));

        if BlockType <> BlockType::Period then
            XMLAddSimpleElement(OPSinsuredPartTxt, FormatDecimal(AmountsPayrollReportingBuffer."Amount 2"));
        if BlockType = BlockType::All then
            XMLAddSimpleElement(OPSaccumulatedPartTxt, FormatDecimal(AmountsPayrollReportingBuffer."Amount 3"));

        if BlockType <> BlockType::Additional then begin
            XMLAddSimpleElement(ContributionsByExtraTariffTxt + '1', FormatDecimal(AmountsPayrollReportingBuffer."Amount 4"));
            XMLAddSimpleElement(ContributionsByExtraTariffTxt + '2_18', FormatDecimal(AmountsPayrollReportingBuffer."Amount 5"));
            XMLAddSimpleElement(InsuranceContributionsOMSTxt, FormatDecimal(AmountsPayrollReportingBuffer."Amount 6"));
        end;

        XMLBackToParent;
    end;

    local procedure FillPaymentsForPeriod(PaymentTitle: Text[250]; BlockType: Option; StartCodeValue: Integer; var AmountsPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        XMLAddComplexElement(PaymentTitle);

        with AmountsPayrollReportingBuffer do begin
            if Get(1) then
                FillPayments(TotalFromCalculationPeriodStartDateTxt, BlockType, Format(StartCodeValue), AmountsPayrollReportingBuffer);
            if Get(2) then
                FillPayments(LastThreeMonthsTxt + '1', BlockType, Format(StartCodeValue + 1), AmountsPayrollReportingBuffer);
            if Get(3) then
                FillPayments(LastThreeMonthsTxt + '2', BlockType, Format(StartCodeValue + 2), AmountsPayrollReportingBuffer);
            if Get(4) then
                FillPayments(LastThreeMonthsTxt + '3', BlockType, Format(StartCodeValue + 3), AmountsPayrollReportingBuffer);

            Reset;
            SetRange("Entry No.", 2, 4);
            CalcSums("Amount 1", "Amount 2", "Amount 3", "Amount 4", "Amount 5", "Amount 6");
            FillPayments(LastThreeMonthsTotalTxt, BlockType, Format(StartCodeValue + 4), AmountsPayrollReportingBuffer);
        end;

        XMLBackToParent;
    end;

    local procedure FillSection2(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var PackPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        XMLAddComplexElement(Chapter2TitleTxt);

        PersonifiedPayrollReportingBuffer.Reset();
        PersonifiedPayrollReportingBuffer.SetRange("Code 3", '01');
        FillSection2_1(PersonifiedPayrollReportingBuffer);

        PersonifiedPayrollReportingBuffer.SetRange("Code 3", '03');
        FillSection2_1(PersonifiedPayrollReportingBuffer);
        PersonifiedPayrollReportingBuffer.SetRange("Code 3");

        FillSection2_5(PersonifiedPayrollReportingBuffer, PackPayrollReportingBuffer);

        XMLBackToParent;
    end;

    local procedure FillSection2_1(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    var
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
        Amount213: array[4] of Decimal;
        Amount214: array[4] of Decimal;
        Amount215: array[4] of Decimal;
    begin
        if not PersonifiedPayrollReportingBuffer.FindFirst then
            exit;

        XMLAddComplexElement(Chapter21Txt);
        XMLAddSimpleElement(TariffCodeTxt, PersonifiedPayrollReportingBuffer."Code 3");
        Calculate2_1Amounts(PersonifiedPayrollReportingBuffer,
          Amount200, Amount201, Amount202, Amount203, Amount204, Amount205, Amount206, Amount207, Amount208,
          Amount210, Amount211, Amount202, Amount213, Amount214, Amount215);

        FillPensionInsurance(Amount200, Amount201, Amount202, Amount203, Amount204, Amount205, Amount206, Amount207, Amount208);
        FillMedicalInsurance(Amount210, Amount211, Amount202, Amount213, Amount214, Amount215);
        XMLBackToParent;
    end;

    local procedure FillPensionInsurance(Amount200: array[4] of Decimal; Amount201: array[4] of Decimal; Amount202: array[4] of Decimal; Amount203: array[4] of Decimal; Amount204: array[4] of Decimal; Amount205: array[4] of Decimal; Amount206: array[4] of Decimal; Amount207: array[4] of Decimal; Amount208: array[4] of Decimal)
    begin
        XMLAddComplexElement(ForMandatoryPensionInsuranceTxt);

        FillPaymentCalulation(PaymentAndRewardAmountOPSTxt, '200', Amount200);
        FillPaymentCalulation(NotLiableForOPSTxt, '201', Amount201);
        FillPaymentCalulation(ExpenseAmountForDeductionOPSTxt, '202', Amount202);
        FillPaymentCalulation(AboveBaseLimitOPSTxt, '203', Amount203);
        FillPaymentCalulation(BaseForInsuranceContributionAccrualsForOPSTxt, '204', Amount204);
        FillPaymentCalulation(AccruedForOPSForAmountsLessThanTxt, '205', Amount205);
        FillPaymentCalulation(AccruedForOPSForAmountsExceededTxt, '206', Amount206);
        FillFL(QuantotyOfFPtotalTxt, '207', Amount207);
        FillFL(QuantityFPWithBaseExceedLimitTxt, '208', Amount208);

        XMLBackToParent;
    end;

    local procedure FillPaymentCalulation(Title: Text[250]; LineCode: Text[250]; Amount: array[4] of Decimal)
    var
        i: Integer;
    begin
        XMLAddComplexElement(Title);
        XMLAddSimpleElement(LineCodeTxt, LineCode);
        XMLAddComplexElement(AmountCalcTxt);

        for i := 0 to 3 do
            if Amount[i + 1] < 0 then
                Amount[i + 1] := 0;

        XMLAddSimpleElement(TotalAmountFromCalculationPeriodStartDateTxt, FormatDecimal(Amount[1]));
        XMLAddSimpleElement(AmountLast1MonthTxt, FormatDecimal(Amount[2]));
        XMLAddSimpleElement(AmountLast2MonthTxt, FormatDecimal(Amount[3]));
        XMLAddSimpleElement(AmountLast3MonthTxt, FormatDecimal(Amount[4]));
        XMLBackToParent;
        XMLBackToParent;
    end;

    local procedure FillFL(Title: Text[250]; LineCode: Text[250]; Amount: array[4] of Decimal)
    begin
        XMLAddComplexElement(Title);

        XMLAddSimpleElement(LineCodeTxt, LineCode);
        XMLAddSimpleElement(QuantityIP_TotalTxt, FormatDecimal(Amount[1]));
        XMLAddSimpleElement(QuantityIP_1monthTxt, FormatDecimal(Amount[2]));
        XMLAddSimpleElement(QuantityIP_2monthTxt, FormatDecimal(Amount[3]));
        XMLAddSimpleElement(QuantityIP_3monthTxt, FormatDecimal(Amount[4]));

        XMLBackToParent;
    end;

    local procedure FillMedicalInsurance(Amount210: array[4] of Decimal; Amount211: array[4] of Decimal; Amount212: array[4] of Decimal; Amount213: array[4] of Decimal; Amount214: array[4] of Decimal; Amount215: array[4] of Decimal)
    begin
        XMLAddComplexElement(ForMandatoryMedicalInsuranceTxt);

        FillPaymentCalulation(PaymentAndRewardAmountTxt, '210', Amount210);
        FillPaymentCalulation(NotLiableTxt, '211', Amount211);
        FillPaymentCalulation(ExpenseAmountForDeductionTxt, '212', Amount212);
        FillPaymentCalulation(BaseForInsuranceContributionAccrualsForOMSTxt, '213', Amount213);
        FillPaymentCalulation(AccruedForOMSTxt, '214', Amount214);
        FillFL(QuantityIPTotalTxt, '215', Amount215);

        XMLBackToParent;
    end;

    local procedure FillSection2_5(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var PackPayrollReportingBuffer: Record "Payroll Reporting Buffer")
    begin
        XMLAddComplexElement(Chapter25Txt);
        XMLAddComplexElement(PackListForPFTxt);
        XMLAddSimpleElement(QuantityOfPacksTxt, Format(PackPayrollReportingBuffer.Count));

        if PackPayrollReportingBuffer.FindSet then
            repeat
                FillPackInfo(InfoAboutPackTxt, false, PersonifiedPayrollReportingBuffer,
                  PackPayrollReportingBuffer."File Name", PackPayrollReportingBuffer."Entry No.");
            until PackPayrollReportingBuffer.Next = 0;
        FillPackInfo(TotalInfoByPacksTxt, true, PersonifiedPayrollReportingBuffer, '', 0);

        XMLBackToParent;
        XMLBackToParent;
    end;

    local procedure FillPackInfo(Title: Text[250]; IsTotal: Boolean; var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; FileName: Text[250]; PackNo: Integer)
    var
        Amount2: Decimal;
        Amount4: Decimal;
    begin
        PersonifiedPayrollReportingBuffer.SetRange("Code 2");
        if PackNo = 0 then
            PersonifiedPayrollReportingBuffer.SetRange("Pack No.")
        else
            PersonifiedPayrollReportingBuffer.SetRange("Pack No.", PackNo);

        PersonifiedPayrollReportingBuffer.SetFilter("Code 2", '<>%1', '0');
        PersonifiedPayrollReportingBuffer.CalcSums("Amount 2", "Amount 4");
        Amount2 := PersonifiedPayrollReportingBuffer."Amount 2";
        Amount4 := -PersonifiedPayrollReportingBuffer."Amount 4";

        XMLAddComplexElement(Title);
        if not IsTotal then
            XMLAddSimpleElement(NumberPPTxt, Format(PackNo));
        XMLAddSimpleElement(BaseForInsuranceContributionsAccrualsLessThanLimitTxt, FormatDecimal(Amount2));
        XMLAddSimpleElement(InsuranceContributionsOPSTxt, FormatDecimal(Amount4));
        PersonifiedPayrollReportingBuffer.SetRange("Code 2", '0');
        XMLAddSimpleElement(QuantityIPInPackTxt, FormatDecimal(PersonifiedPayrollReportingBuffer.Count));
        if not IsTotal then
            XMLAddSimpleElement(FileNameTxt, FileName);
        XMLBackToParent;
    end;

    local procedure FillResponsibleName()
    begin
        XMLAddComplexElement(ConfirmingPersonNameTxt);
        XMLAddSimpleElement(LastNameTxt, '');
        XMLAddSimpleElement(FirstNameTxt, '');
        XMLAddSimpleElement(MiddleNameTxt, '');
        XMLBackToParent;
    end;

    local procedure GetXMLFileName(StartDate: Date; DepartmentNo: Integer; DepartmentPackNo: Integer): Text[250]
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Pension Fund Registration No.");
        exit(
          'PFR-700-' +
          'Y-' + Format(StartDate, 0, '<Year4>') +
          '-ORG-' + CompanyInfo."Pension Fund Registration No." +
          '-DCK-' + FormatNumber(1, 5) +
          '-DPT-' + FormatNumber(DepartmentNo, 6) +
          '-DCK-' + FormatNumber(DepartmentPackNo, 5) + '.XML'
          );
    end;

    [Scope('OnPrem')]
    procedure CreateXMLDoc(var XmlDoc: DotNet XmlDocument; var ProcInstr: DotNet XmlProcessingInstruction)
    begin
        XmlDoc := XmlDoc.XmlDocument;
        ProcInstr := XmlDoc.CreateProcessingInstruction('xml', 'version="1.0" encoding="windows-1251"');
        XmlDoc.AppendChild(ProcInstr);
    end;

    [Scope('OnPrem')]
    procedure SaveXMLFile(var XmlDoc: DotNet XmlDocument; FolderName: Text; FileName: Text[250])
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        XmlExcelReportsMgt: Codeunit "XML-Excel Reports Mgt.";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);

        XmlExcelReportsMgt.SaveXMLDocWithEncoding(OutStr, XmlDoc, 'windows-1251');

        TempBlob.CreateInStream(InStr);

        if FolderName = '' then
            DownloadFromStream(InStr, 'Export', '', 'All Files (*.*)|*.*', FileName)
        else begin
            if FolderName <> '' then
                if CopyStr(FolderName, StrLen(FolderName), 1) <> '\' then
                    FolderName += '\';
            FileName := CopyStr(FolderName + FileName, 1, 250);
            DownloadFromStream(InStr, 'Export', FileManagement.Magicpath, 'All Files (*.*)|*.*', FileName);
        end;
    end;

    local procedure XMLAddElement(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; var CreatedXMLNode: DotNet XmlNode) ExitStatus: Integer
    var
        NewChildNode: DotNet XmlNode;
        XmlNodeType: DotNet XmlNodeType;
    begin
        NewChildNode := XMLNode.OwnerDocument.CreateNode(XmlNodeType.Element, NodeName, NameSpace);

        if IsNull(NewChildNode) then begin
            ExitStatus := 50;
            exit;
        end;

        if NodeText <> '' then
            NewChildNode.InnerText := NodeText;

        if XMLNode.NodeType.Equals(XmlNodeType.ProcessingInstruction) then
            CreatedXMLNode := XMLNode.OwnerDocument.AppendChild(NewChildNode)
        else begin
            XMLNode.AppendChild(NewChildNode);
            CreatedXMLNode := NewChildNode;
        end;

        ExitStatus := 0;
    end;

    local procedure XMLAddAttribute(var XMLNode: DotNet XmlNode; Name: Text[260]; NodeValue: Text[260]) ExitStatus: Integer
    var
        XMLNewAttributeNode: DotNet XmlNode;
    begin
        XMLNewAttributeNode := XMLNode.OwnerDocument.CreateAttribute(Name);

        if IsNull(XMLNewAttributeNode) then begin
            ExitStatus := 60;
            exit(ExitStatus)
        end;

        if NodeValue <> '' then
            XMLNewAttributeNode.Value := NodeValue;

        XMLNode.Attributes.SetNamedItem(XMLNewAttributeNode);
    end;

    local procedure XMLAddSimpleElement(NodeName: Text[250]; NodeText: Text[250])
    begin
        XMLAddElement(XMLCurrNode, NodeName, UpperCase(NodeText), '', XMLNewChild);
    end;

    local procedure XMLAddComplexElement(NodeName: Text[250])
    begin
        XMLAddElement(XMLCurrNode, NodeName, '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;
    end;

    local procedure XMLBackToParent()
    begin
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure AddFileHeader()
    begin
        XMLAddComplexElement(FileHeaderTxt);
        XMLAddSimpleElement(FormatVersionTxt, '07.00');
        XMLAddSimpleElement(FileTypeTxt, EXTERNALTxt);
        XMLAddComplexElement(DataPreparationProgramTxt);
        XMLAddSimpleElement(ProgramNameTxt, 'MICROSOFT DYNAMICS NAV');
        XMLAddSimpleElement(VersionTxt, '2016');
        XMLBackToParent;
        XMLAddSimpleElement(DataSourceTxt, INSURERTxt);
        XMLBackToParent;
    end;

    local procedure FormatNumber(Number: Integer; StrLength: Integer): Text[30]
    begin
        exit(PadStr('', StrLength - StrLen(Format(Number)), '0') + Format(Number));
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure FormatDecimal(Amount: Decimal): Text[30]
    begin
        exit(Format(Amount, 0, 9));
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

    [Scope('OnPrem')]
    procedure Calculate2_1Amounts(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var Amount200: array[4] of Decimal; var Amount201: array[4] of Decimal; var Amount202: array[4] of Decimal; var Amount203: array[4] of Decimal; var Amount204: array[4] of Decimal; var Amount205: array[4] of Decimal; var Amount206: array[4] of Decimal; var Amount207: array[4] of Decimal; var Amount208: array[4] of Decimal; var Amount210: array[4] of Decimal; var Amount211: array[4] of Decimal; var Amount212: array[4] of Decimal; var Amount213: array[4] of Decimal; var Amount214: array[4] of Decimal; var Amount215: array[4] of Decimal)
    var
        i: Integer;
    begin
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
    end;

    [Scope('OnPrem')]
    procedure SetSkipExport(NewSkipExport: Boolean)
    begin
        SkipExport := NewSkipExport;
    end;
}

