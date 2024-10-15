codeunit 17460 "Personified Accounting Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        HRSetup: Record "Human Resources Setup";
        LocalMgt: Codeunit "Localisation Management";
        LocalReportMgt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        Text001: Label 'Export data to Excel\ @1@@@@@@@@@@@@@';
        Text002: Label 'Export';
        Text003: Label 'All Files (*.*)|*.*';
        Text004: Label '%1 must be the first day of the month.';
        Text005: Label '%1 must be the first day of the quarter.';
        Text006: Label '%1 must be the last day of the month.';
        Text007: Label '%1 must be the last day of the quarter.';
        Text008: Label '%1 must be filled in.';
        Text009: Label 'Period Starting Date';
        Text010: Label 'Period Ending Date';
        Text011: Label 'Creation Date';
        Text013: Label '%1 cannot be greater then %2.';
        Text014: Label '%1 must be defined for person %2.';
        AddressType: Option Permanent,Registration,Birthplace,Other;
        Text015: Label 'Registration address';
        Text016: Label 'Birthplace address ';
        HRSetupRead: Boolean;
        CONTRACTTxt: Label 'CONTRACT', Locked = true;
        ContractType1Txt: Label 'LABOR', Locked = true;
        ContractType2Txt: Label 'CIVIL', Locked = true;
        LineTypeTxt: Label 'LineType', Locked = true;
        LineNumberTxt: Label 'LineNumber', Locked = true;
        MonthTxt: Label 'Month', Locked = true;
        ITOGTxt: Label 'ITOG', Locked = true;
        ITOGOTxt: Label 'ITOGO', Locked = true;
        MESCTxt: Label 'MESC', Locked = true;
        DocumentTypeTxt: Label 'DocumentType', Locked = true;
        QuantityTxt: Label 'Quantity', Locked = true;
        CategoryCodeTxt: Label 'CategoryCode', Locked = true;
        ContractTypeTxt: Label 'ContractType', Locked = true;
        ReportingPeriodTxt: Label 'ReportingPeriod', Locked = true;
        ReportingYearTxt: Label 'ReportingYear', Locked = true;
        DocumentCollectionTxt: Label 'DocumentCollection', Locked = true;
        DocumentPresenceTxt: Label 'DocumentPresence', Locked = true;
        NumberInPackTxt: Label 'NumberInPack', Locked = true;
        CreationDateTxt: Label 'CreationDate', Locked = true;
        CreationDateAsOfTxt: Label 'CreationDateAsOf', Locked = true;
        PackNumberTxt: Label 'PackNumber', Locked = true;
        PrimaryTxt: Label 'Primary', Locked = true;
        FormTypeTxt: Label 'FormType', Locked = true;
        RegistrationNumberTxt: Label 'RegistrationNumber', Locked = true;
        InsuranceNumberTxt: Label 'InsuranceNumber', Locked = true;
        TaxNumberTxt: Label 'TaxNumberTxt', Locked = true;
        ShortNameTxt: Label 'ShortName', Locked = true;
        FillDateTxt: Label 'FillDate', Locked = true;
        QuarterTxt: Label 'Quarter', Locked = true;
        YearTxt: Label 'Year', Locked = true;
        MaleTxt: Label 'M', Locked = true;
        FemaleTxt: Label 'F', Locked = true;
        FilePFRTxt: Label 'FilePFR', Locked = true;
        FileNameTxt: Label 'FileName', Locked = true;
        PackContentTxt: Label 'PACK CONTENT', Locked = true;
        PackContentTypeTxt: Label 'PackContentType', Locked = true;
        IncomingContentTxt: Label 'INCOMING_CONTENT', Locked = true;
        IncomingDocumentPackTxt: Label 'IncomingDocumentPack', Locked = true;
        PartOfFileTxt: Label 'Part of file', Locked = true;
        SurroundingTxt: Label 'Surrounding', Locked = true;
        StageTxt: Label 'Stage', Locked = true;
        BeforeProcessingTxt: Label 'Before Processing', Locked = true;
        AnketaIPTxt: Label 'ANKETA_IP', Locked = true;
        FileHeaderTxt: Label 'FileHeader', Locked = true;
        FileTypeTxt: Label 'FileType', Locked = true;
        FormatVersionTxt: Label 'FormatVersion', Locked = true;
        GenderTxt: Label 'Gender', Locked = true;
        DataPreparationProgramTxt: Label 'DataPreparationProgram', Locked = true;
        ProgramNameTxt: Label 'ProgramName', Locked = true;
        VersionTxt: Label 'Version', Locked = true;
        DataSourceTxt: Label 'DataSourceTxt', Locked = true;
        INSURERTxt: Label 'INSURER', Locked = true;
        TotalContributionToInsuredTxt: Label 'TotalContributionToInsured', Locked = true;
        TotalContributionToAccumulatedTxt: Label 'TotalContributionToAccumulated', Locked = true;
        AccruedTxt: Label 'Accrued', Locked = true;
        PaidTxt: Label 'Paid', Locked = true;
        NameTxt: Label 'Name', Locked = true;
        FromToTxt: Label 'from %1 to %2', Locked = true;
        INNTxt: Label 'INN', Locked = true;
        KPPTxt: Label 'KPP', Locked = true;
        FIOTxt: Label 'FIO', Locked = true;
        LastNameTxt: Label 'LastName', Locked = true;
        FirstNameTxt: Label 'FirstName', Locked = true;
        MiddleNameTxt: Label 'MiddleName', Locked = true;
        AbbreviationTxt: Label 'Abbreviation', Locked = true;
        AddressTypeTxt: Label 'AddressType', Locked = true;
        InformationTypeTxt: Label 'InformationType', Locked = true;
        ORIGINALTxt: Label 'ORIGINAL', Locked = true;
        CORRECTIVETxt: Label 'CORRECTIVE', Locked = true;
        CANCELLATIONTxt: Label 'CANCELLATION', Locked = true;
        RUSSIANTxt: Label 'RUSSIAN', Locked = true;
        PostCodeTxt: Label 'PostCode', Locked = true;
        RussianAddressTxt: Label 'RussianAddress', Locked = true;
        AddressConditionTxt: Label 'AddressCondition', Locked = true;
        VALIDTxt: Label 'VALID', Locked = true;
        RegionTxt: Label 'Region', Locked = true;
        CountyTxt: Label 'County', Locked = true;
        CityTxt: Label 'City', Locked = true;
        StreetTxt: Label 'Street', Locked = true;
        HouseTxt: Label 'House', Locked = true;
        BlockTxt: Label 'Block', Locked = true;
        FlatTxt: Label 'Flat', Locked = true;
        HTxt: Label 'H', Locked = true;
        BLCKTxt: Label 'BLCK', Locked = true;
        FLTxt: Label 'FL', Locked = true;
        FOREIGNTxt: Label 'FOREIGN', Locked = true;
        ForeignAddressTxt: Label 'ForeignAddress', Locked = true;
        CountryCodeTxt: Label 'CountryCode', Locked = true;
        CountryNameTxt: Label 'CountryName', Locked = true;
        AddressTxt: Label 'Address', Locked = true;
        GeographicalNameTxt: Label 'GeographicalName', Locked = true;
        NumberTxt: Label 'Number', Locked = true;
        LocalityTxt: Label 'Locality', Locked = true;
        StagePeriodTxt: Label 'StagePeriod', Locked = true;
        PeriodStartDateTxt: Label 'PeriodStartDate', Locked = true;
        PeriodEndDateTxt: Label 'PeriodEndDate', Locked = true;
        BirthDateTxt: Label 'BirthDate', Locked = true;
        BirthPlaceTxt: Label 'BirthPlace', Locked = true;
        BirthPlaceTypeTxt: Label 'BirthPlaceType', Locked = true;
        BirthCityTxt: Label 'BirthCity', Locked = true;
        BirthRegionTxt: Label 'BirthRegion', Locked = true;
        BirthCountyTxt: Label 'BirthCounty', Locked = true;
        CitizenshipTxt: Label 'Citizenship', Locked = true;
        RegistrationAddressTxt: Label 'RegistrationAddress', Locked = true;
        ActualAddressTxt: Label 'ActualAddress', Locked = true;
        PhoneTxt: Label 'Phone', Locked = true;
        STANDARDTxt: Label 'STANDARD', Locked = true;
        SPECIALTxt: Label 'SPECIAL', Locked = true;
        AnketaDataTxt: Label 'AnketaData', Locked = true;
        CompanyNameTxt: Label 'CompanyName', Locked = true;
        FormTxt: Label 'Form', Locked = true;
        PackCreatorTxt: Label 'PackCreator', Locked = true;
        CodEGRIPTxt: Label 'CodEGRIP', Locked = true;
        CodEGRULTxt: Label 'CodEGRUL', Locked = true;
        EXTERNALTxt: Label 'EXTERNAL', Locked = true;
        AddressIPTxt: Label 'AddressIP', Locked = true;
        SPV1TitleTxt: Label 'SPV1Title', Locked = true;
        SPV1Txt: Label 'SPV-1', Locked = true;
        SZV62TitleTxt: Label 'SZV62Title', Locked = true;
        SZV62Txt: Label 'SZV-6-2', Locked = true;
        SZV63TitleTxt: Label 'SZV63Title', Locked = true;
        SZV64TitleTxt: Label 'SZV64Title', Locked = true;
        IncomingList1Txt: Label 'IncomingList1', Locked = true;
        IncomingList2Txt: Label 'IncomingList2', Locked = true;
        IncomingList3Txt: Label 'IncomingList3', Locked = true;
        DocumentType1Txt: Label 'DocumentType1', Locked = true;
        DocumentType2Txt: Label 'DocumentType2', Locked = true;
        DocumentType3Txt: Label 'DocumentType3', Locked = true;
        ConfirmationDocumentTxt: Label 'ConfirmationDocument', Locked = true;
        ConfirmationDocumentTypeTxt: Label 'ConfirmationDocumentType', Locked = true;
        ConfirmationDocumentNameTxt: Label 'ConfirmationDocumentName', Locked = true;
        ConfirmationDocumentNumberTxt: Label 'ConfirmationDocumentNumber', Locked = true;
        DocumentTxt: Label 'Document', Locked = true;
        SeriaRomanDigitsTxt: Label 'SeriaRomanDigits', Locked = true;
        SeriaRussianLettersTxt: Label 'SeriaRussianLetters', Locked = true;
        IssueDateTxt: Label 'IssueDate', Locked = true;
        IssueAuthorityTxt: Label 'IssueAuthority', Locked = true;
        SpecialConditionsTxt: Label 'SpecialConditions', Locked = true;
        BenefitsQuantityTxt: Label 'BenefitsQuantity', Locked = true;
        BenefitsYearsTxt: Label 'BenefitsYears', Locked = true;
        BonusAmountTxt: Label 'BonusAmount', Locked = true;
        TotalPaidAmountTxt: Label 'TotalPaidAmount', Locked = true;
        PaidAmountAccruedInsuranceContributionsTxt: Label 'PaidAmountAccruedInsuranceContributions', Locked = true;
        PaidAmountAccruedInsuranceContributionsLessTxt: Label 'PaidAmountAccruedInsuranceContributionsLess', Locked = true;
        PaidAmountAccruedInsuranceContributionsMoreTxt: Label 'PaidAmountAccruedInsuranceContributionsMore', Locked = true;
        PACKTOTALTxt: Label 'PACK TOTAL', Locked = true;
        BonusAmount64Txt: Label 'BonusAmount64', Locked = true;
        SpecialBonusAmountTxt: Label 'SpecialBonusAmount', Locked = true;
        SpecialPaidAmount271Txt: Label 'SpecialPaidAmount271', Locked = true;
        SpecialPaidAmount27218Txt: Label 'SpecialPaidAmount27218', Locked = true;
        TerritorialConditionsTxt: Label 'TerritorialConditions', Locked = true;
        SpecialLaborConditionsTxt: Label 'SpecialLaborConditions', Locked = true;
        CountableServiceReasonTxt: Label 'CountableServiceReason', Locked = true;
        MaternityLeaveTxt: Label 'MaternityLeave', Locked = true;
        LongServiceTxt: Label 'LongService', Locked = true;
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure ADV1toXML(var Employee: Record Employee; FillingDate: Date; CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer)
    var
        XmlDoc: DotNet XmlDocument;
        Counter: Integer;
        FileName: Text;
    begin
        GetHRSetup;
        Counter := 1;

        CheckEmployees(Employee);

        FileName := GetXMLFileName(Today, CompanyPackNo, DepartmentNo, DepartmentPackNo);

        CreateXMLDoc(XmlDoc, XMLCurrNode);
        XMLAddComplexElement(FilePFRTxt);
        XMLAddSimpleElement(FileNameTxt, FileName);
        AddFileHeader;
        XMLAddComplexElement(IncomingDocumentPackTxt);
        XMLAddAttribute(XMLCurrNode, SurroundingTxt, PartOfFileTxt);
        XMLAddAttribute(XMLCurrNode, StageTxt, BeforeProcessingTxt);
        XMLAddComplexElement(IncomingContentTxt);
        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        XMLAddSimpleElement(PackContentTypeTxt, PackContentTxt);
        AddCompanyInfo;
        XMLAddComplexElement(PackNumberTxt);
        XMLAddSimpleElement(PrimaryTxt, Format(CompanyPackNo));
        XMLBackToParent;
        XMLAddComplexElement(DocumentCollectionTxt);
        XMLAddSimpleElement(QuantityTxt, '1');
        XMLAddComplexElement(DocumentPresenceTxt);
        XMLAddSimpleElement(DocumentTypeTxt, AnketaIPTxt);
        XMLAddSimpleElement(QuantityTxt, Format(Employee.Count));
        XMLBackToParent;
        XMLBackToParent;
        XMLAddSimpleElement(CreationDateTxt, FormatDate(FillingDate));
        XMLBackToParent;
        if Employee.FindSet then
            repeat
                Counter += 1;
                AddEmployeeForm(Counter, Employee, FillingDate);
            until Employee.Next = 0;

        if not TestMode then
            SaveXMLFile(XmlDoc, FileName);
    end;

    [Scope('OnPrem')]
    procedure ADV1toExcel(var Employee: Record Employee; FillingDate: Date)
    var
        CountryRegion: Record "Country/Region";
        AlternativeAddress: Record "Alternative Address";
        RegAlternativeAddress: Record "Alternative Address";
        PermAlternativeAddress: Record "Alternative Address";
        ExcelTemplate: Record "Excel Template";
        PersonDocument: Record "Person Document";
        Window: Dialog;
        FileName: Text;
        TemplateSheetName: Text[30];
        DocumentName: Text[100];
        FullAddress: Text[1024];
        Counter: Integer;
    begin
        CompanyInfo.Get;

        CheckEmployees(Employee);

        GetHRSetup;
        HRSetup.TestField("ADV-1 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HRSetup."ADV-1 Template Code");
        ExcelMgt.OpenBookForUpdate(FileName);
        TemplateSheetName := 'Sheet1';
        ExcelMgt.OpenSheet(TemplateSheetName);

        Window.Open(Text001);

        if Employee.FindSet then
            repeat
                Counter += 1;
                Window.Update(1, Round(Counter / Employee.Count * 10000, 1));
                ExcelMgt.CopySheet(TemplateSheetName, TemplateSheetName, Employee."No.");
                ExcelMgt.OpenSheet(Employee."No.");
                FillExcelRow('J8', 25, Employee."Last Name");
                FillExcelRow('J10', 25, Employee."First Name");
                FillExcelRow('J12', 25, Employee."Middle Name");
                case Employee.Gender of
                    Employee.Gender::Male:
                        ExcelMgt.FillCell('J14', MaleTxt);
                    Employee.Gender::Female:
                        ExcelMgt.FillCell('J14', FemaleTxt);
                end;
                FillADV1Date('K16', Employee."Birth Date");
                GetAddressByType(Employee."Person No.", AddressType::Birthplace, AlternativeAddress);
                if (AlternativeAddress.City = '') and (AlternativeAddress.Area = '') then
                    FillExcelRow('P19', 21, AlternativeAddress.Region)
                else begin
                    FillExcelRow('P19', 21, AlternativeAddress.City);
                    FillExcelRow('P21', 21, AlternativeAddress.Area);
                    FillExcelRow('P23', 21, AlternativeAddress.Region);
                end;
                if CountryRegion.Get(AlternativeAddress."Country/Region Code") then
                    FillExcelRow('P25', 21, CountryRegion.Name);
                FillExcelRow('P27', 21, GetCitizenship(Employee."Person No."));

                GetAddressByType(Employee."Person No.", AddressType::Registration, RegAlternativeAddress);
                FillExcelRow('N31', 6, RegAlternativeAddress."Post Code");
                FullAddress := RegAlternativeAddress.GetFullAddress(false);
                FillExcelRow('X31', 13, CopyStr(FullAddress, 1, 13));
                FillExcelRow('N33', 23, CopyStr(FullAddress, 14, 23));
                FillExcelRow('N35', 23, CopyStr(FullAddress, 37, 23));

                GetAddressByType(Employee."Person No.", AddressType::Permanent, PermAlternativeAddress);
                if RegAlternativeAddress.GetFullAddress(true) <>
                   PermAlternativeAddress.GetFullAddress(true)
                then begin
                    FillExcelRow('N37', 6, PermAlternativeAddress."Post Code");
                    FullAddress := PermAlternativeAddress.GetFullAddress(false);
                    FillExcelRow('X37', 13, CopyStr(FullAddress, 1, 13));
                    FillExcelRow('N39', 23, CopyStr(FullAddress, 14, 23));
                    FillExcelRow('N41', 23, CopyStr(FullAddress, 37, 23));
                    if (Employee."Phone No." = '') and (Employee."Mobile Phone No." <> '') then
                        FillExcelRow('N45', 23, Employee."Mobile Phone No.")
                    else
                        FillExcelRow('N45', 23, Employee."Phone No.");
                end;

                GetIdentifyDoc(Employee."Person No.", PersonDocument, DocumentName);
                FillExcelRow('J50', 25, DocumentName);

                FillExcelRow('J54', 19, PersonDocument."Document Series" + ' ' + PersonDocument."Document No.");
                FillADV1Date('K56', PersonDocument."Issue Date");
                FillExcelRow('J58', 25, CopyStr(PersonDocument."Issue Authority", 1, 25));
                FillExcelRow('J60', 25, CopyStr(PersonDocument."Issue Authority", 26, 25));
                FillADV1Date('B65', FillingDate);
            until Employee.Next = 0;

        if TestMode then
            ExcelMgt.CloseBook
        else begin
          ExcelMgt.DeleteSheet(TemplateSheetName);
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HRSetup."ADV-1 Template Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure SVFormToExcel(FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4; var Employee: Record Employee; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; AnalysisReportName: Code[10]; CorrectionYear: Integer)
    var
        TempPersonMedicalInfoDisability: Record "Person Medical Info" temporary;
        TempEmployeeWithDisability: Record Employee temporary;
        TempEmployeeWithoutDisability: Record Employee temporary;
        ExcelTemplate: Record "Excel Template";
        Person: Record Person;
        Window: Dialog;
        FileName: Text;
        TemplateSheetName: Text[30];
        AdditionalSheetName: Text[30];
        Counter: Integer;
        DisabilityPeriodBufferCounter: Integer;
        SZV6_2SheetCreated: Boolean;
        CategoryType: Option WithoutDisability,WithDisability;
        EmployeePeriodStartDate: Date;
        EmployeePeriodEndDate: Date;
    begin
        if Employee.IsEmpty then
            exit;

        CompanyInfo.Get;
        FileName := ExcelTemplate.OpenTemplate(GetExcelTemplate(FormType));
        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheetByNumber(1);
        TemplateSheetName := ExcelMgt.GetSheetName;

        Window.Open(Text001);

        case FormType of
            FormType::SPV_1, FormType::SZV_6_1, FormType::SZV_6_3, FormType::SZV_6_4:
                begin
                    if Employee.FindSet then
                        repeat
                            Person.Get(Employee."Person No.");

                            Counter += 1;
                            Window.Update(1, Round(Counter / Employee.Count * 10000, 1));
                            ExcelMgt.CopySheet(TemplateSheetName, TemplateSheetName, Employee."No.");
                            ExcelMgt.OpenSheet(Employee."No.");

                            if (InfoType <> InfoType::Initial) and (FormType = FormType::SZV_6_3) then begin
                                EmployeePeriodStartDate := DMY2Date(1, 1, CorrectionYear);
                                EmployeePeriodEndDate := DMY2Date(31, 12, CorrectionYear);
                            end else begin
                                EmployeePeriodStartDate := StartDate;
                                EmployeePeriodEndDate := EndDate;
                            end;

                            FitPeriodToLaborContract(Employee, EmployeePeriodStartDate, EmployeePeriodEndDate);
                            GetDisabilityPeriods(Employee, EmployeePeriodStartDate, EmployeePeriodEndDate, TempPersonMedicalInfoDisability);
                            DisabilityPeriodBufferCounter := 0;
                            TempPersonMedicalInfoDisability.FindSet;
                            repeat
                                DisabilityPeriodBufferCounter += 1;
                                if DisabilityPeriodBufferCounter > 1 then begin
                                    AdditionalSheetName := Employee."No." + ' (' + Format(DisabilityPeriodBufferCounter) + ')';
                                    ExcelMgt.CopySheet(TemplateSheetName, TemplateSheetName, AdditionalSheetName);
                                    ExcelMgt.OpenSheet(AdditionalSheetName);
                                end;

                                case FormType of
                                    FormType::SPV_1:
                                        FillSPV1Sheet(
                                          Employee, TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                          CreationDate, InfoType, TempPersonMedicalInfoDisability."Disability Group");
                                    FormType::SZV_6_1:
                                        FillSZV6_1Sheet(
                                          Employee, TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                          InfoType, TempPersonMedicalInfoDisability."Disability Group");
                                    FormType::SZV_6_3:
                                        FillSZV6_3Sheet(
                                          Employee, TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                          InfoType, TempPersonMedicalInfoDisability."Disability Group", AnalysisReportName);
                                    FormType::SZV_6_4:
                                        FillSZV6_4Sheet(
                                          Employee, EmployeePeriodStartDate, EmployeePeriodEndDate,
                                          TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                          InfoType, TempPersonMedicalInfoDisability."Disability Group", AnalysisReportName);
                                end;
                            until TempPersonMedicalInfoDisability.Next = 0;
                        until Employee.Next = 0;
                    if not TestMode then
                        ExcelMgt.DeleteSheet(TemplateSheetName);
                end;
            FormType::SZV_6_2:
                begin
                    GetDisabilityBuffers(
                      Employee, StartDate, EndDate, TempPersonMedicalInfoDisability, TempEmployeeWithDisability, TempEmployeeWithoutDisability);

                    if TempEmployeeWithoutDisability.Count > 0 then begin
                        if TempEmployeeWithDisability.Count > 0 then
                            ExcelMgt.CopySheet(TemplateSheetName, TemplateSheetName, 'Sheet2');
                        SZV6_2SheetCreated := true;
                        FillSZV6_2Sheet(
                          TempEmployeeWithoutDisability, TempPersonMedicalInfoDisability,
                          StartDate, EndDate, InfoType, CategoryType::WithoutDisability);
                    end;

                    if TempEmployeeWithDisability.Count > 0 then begin
                        if SZV6_2SheetCreated then
                            ExcelMgt.OpenSheet('Sheet2');
                        FillSZV6_2Sheet(
                          TempEmployeeWithDisability, TempPersonMedicalInfoDisability,
                          StartDate, EndDate, InfoType, CategoryType::WithDisability);
                    end;
                end;
        end;
        if TestMode then
            ExcelMgt.CloseBook
        else
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(GetExcelTemplate(FormType)));
    end;

    local procedure FillSPV1Sheet(Employee: Record Employee; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option)
    begin
        FillSVCompanyInfo('DI3', 'AO7', 'AD8', 'H9', 'AU9');
        FillSVHeader(CategoryType, InfoType, 'AU10', 'DA7', 'DA9', 'DA11');

        if InfoType <> InfoType::Cancel then begin
            FillSPV1Date('AA11', CreationDate);
            FillSVHeaderQuarterInfo(EndDate, 'N15', 'AI15', 'BB15', 'BM15', 'X16');
            FillSVPersonShortInfo(Employee."Person No.", 'B22', 'Q22');

            CalcAndFillInsAndAccumAmounts(Employee."No.", StartDate, EndDate, 'AR22', 'BP22', 'CM22', 'DK22');
            FillExperienceBuffer(
              Employee."No.", StartDate, EndDate, 26, 12,
              'B', 'I', 'Y', 'AO', 'BB', 'BR', 'CI', 'CZ', 'DQ');
        end;
    end;

    local procedure FillSZV6_1Sheet(var Employee: Record Employee; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option)
    begin
        FillSVCompanyInfo('DI3', 'AO7', 'AD8', 'H9', 'AU9');
        FillSVHeader(CategoryType, InfoType, 'AU10', 'T18', 'D21', 'D23');
        FillSVHeaderPeriodInfo(
          InfoType, EndDate,
          'M14', 'AH14', 'BA14', 'BL14', 'CW14',
          'BQ21', 'CL21', 'DE21', 'DP21', 'BE23');

        if InfoType <> InfoType::Cancel then begin
            FillSVPersonShortInfo(Employee."Person No.", 'AC28', 'B28');
            FillSVPersonAddress(Employee."Person No.", 'AR28');

            CalcAndFillInsAndAccumAmounts(Employee."No.", StartDate, EndDate, 'BR28', 'CI28', 'CZ28', 'DQ28');
            FillExperienceBuffer(
              Employee."No.", StartDate, EndDate, 32, 12,
              'B', 'I', 'Y', 'AO', 'BB', 'BR', 'CI', 'CZ', 'DQ');
        end;
    end;

    local procedure FillSZV6_2Sheet(var Employee: Record Employee; var TempPersonMedicalInfoDisability: Record "Person Medical Info" temporary; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability)
    var
        Person: Record Person;
        Window: Dialog;
        RowNo: Integer;
        i: Integer;
        j: Integer;
        InsurAmount: Decimal;
        AccumAmount: Decimal;
        TotalInsurAmount: Decimal;
        TotalAccumAmount: Decimal;
    begin
        FillSVCompanyInfo('EZ3', 'AO8', 'AU10', 'H9', 'AU9');
        FillSVHeader(CategoryType, InfoType, 'AU11', 'T14', 'B16', 'B19');
        FillSVHeaderPeriodInfo(
          InfoType, EndDate,
          'DM7', 'EH7', 'FA7', 'FK7', 'DC8',
          'BQ17', 'CL17', 'DE17', 'DP17', 'ET17');

        if InfoType <> InfoType::Cancel then begin
            ExcelMgt.FillCell('EB10', Format(Employee.Count));

            Window.Open(Text001);
            RowNo := 24;
            if Employee.FindSet then
                repeat
                    i += 1;
                    Window.Update(1, Round(i / Employee.Count * 10000, 1));
                    Person.Get(Employee."Person No.");
                    TempPersonMedicalInfoDisability.Reset;
                    TempPersonMedicalInfoDisability.SetRange("Employee No.", Employee."No.");
                    TempPersonMedicalInfoDisability.SetRange("Disability Group", CategoryType);
                    TempPersonMedicalInfoDisability.FindSet;
                    j := 0;
                    repeat
                        j += 1;
                        if (i <> Employee.Count) or (j <> TempPersonMedicalInfoDisability.Count) then
                            ExcelMgt.CopyRow(RowNo);
                        ExcelMgt.FillCell('B' + Format(RowNo), Format(i));
                        FillSVPersonShortInfo(Person."No.", 'AR' + Format(RowNo), 'I' + Format(RowNo));
                        FillSVPersonAddress(Employee."Person No.", 'BN' + Format(RowNo));

                        CalcInsAndAccumAmounts(InsurAmount, AccumAmount, Employee."No.", StartDate, EndDate);
                        FillInsAndAccumAmounts(InsurAmount, AccumAmount,
                          'CJ' + Format(RowNo), 'CY' + Format(RowNo), 'DN' + Format(RowNo), 'EC' + Format(RowNo));

                        TotalInsurAmount += InsurAmount;
                        TotalAccumAmount += AccumAmount;
                        ExcelMgt.FillCellWithTextFormat('ER' + Format(RowNo), FormatDate(TempPersonMedicalInfoDisability."Starting Date"));
                        ExcelMgt.FillCellWithTextFormat('FH' + Format(RowNo), FormatDate(TempPersonMedicalInfoDisability."Ending Date"));
                        RowNo += 1;
                    until TempPersonMedicalInfoDisability.Next = 0;
                until Employee.Next = 0;

            if i > 0 then
                FillInsAndAccumAmounts(
                  TotalInsurAmount, TotalAccumAmount,
                  'CJ' + Format(RowNo), 'CY' + Format(RowNo), 'DN' + Format(RowNo), 'EC' + Format(RowNo));
        end;
    end;

    local procedure FillSZV6_3Sheet(var Employee: Record Employee; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option; AnalysisReportName: Code[10])
    var
        DirectorEmployee: Record Employee;
    begin
        FillSVCompanyInfo('CP4', 'COMPANY_PFR_ID', 'COMPANY_NAME_SHORT', 'COMPANY_INN', 'COMPANY_KPP');
        FillSVHeader(CategoryType, InfoType, 'INS_PERSON_CATEGORY_ID', 'DOC_TYPE_ORIGIN', 'DOC_TYPE_CORRECT', 'DOC_TYPE_CANCEL');
        FillSVPersonInfo(Employee."Person No.", 'EMPLNAME_LAST', 'EMPLNAME_FIRST', 'EMPLNAME_MIDDLE', 'EMPL_PFR_ID');
        FillSVContractInfo(Employee."Contract No.", 'AGREEMENT_LABOR', 'AGREEMENT_CIVIL');
        ExcelMgt.FillCell('REPORTED_YEAR', Format(Date2DMY(StartDate, 3)));

        FillSZV6_3SalaryAmounts(Employee."No.", AnalysisReportName, StartDate, EndDate);

        if DirectorEmployee.Get(CompanyInfo."Director No.") then begin
            ExcelMgt.FillCell('SIGN_OCCUPATION', DirectorEmployee.GetJobTitleName);
            ExcelMgt.FillCell('SIGN_NAME', DirectorEmployee.GetNameInitials);
            ExcelMgt.FillCell('SIGN_DATE', Format(WorkDate));
        end;
    end;

    local procedure FillSZV6_4Sheet(var Employee: Record Employee; PeriodStartDate: Date; PeriodEndDate: Date; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option; AnalysisReportName: Code[10])
    begin
        FillSVCompanyInfo('CP5', 'AJ16', 'AH18', 'I20', 'BA20');
        FillSVHeader(CategoryType, InfoType, 'AO22', 'R31', 'B34', 'B36');
        FillSVHeaderPeriodInfo(InfoType, PeriodEndDate, 'M28', 'AD28', 'AS28', 'BB28', 'CF28', 'BG34', 'BX34', 'CM34', 'AF36', 'CG36');
        FillSVPersonInfo(Employee."Person No.", 'M45', 'H46', 'M47', 'U48');
        FillSVContractInfo(Employee."Contract No.", 'B42', 'U42');

        FillSZV6_4MonthAmounts(Employee."No.", AnalysisReportName, PeriodStartDate, StartDate, EndDate);
        CalcAndFillSZV6_4InsAndSaveAmt(AnalysisReportName, Employee."No.", StartDate, EndDate);
        FillExperienceBuffer(Employee."No.", StartDate, EndDate, 77, 1, 'A', 'F', 'R', 'AD', 'AP', 'BC', 'BP', 'CD', 'CQ');
    end;

    local procedure FillSZV6_3SalaryAmounts(EmployeeNo: Code[20]; TemplName: Code[10]; StartDate: Date; EndDate: Date)
    var
        TotalFundAmount: Decimal;
        TotalInsAmount: Decimal;
        Month: Integer;
        YearForAmounts: Integer;
    begin
        if Date2DMY(StartDate, 2) = Date2DMY(EndDate, 2) then
            CalcAndFillSZV6_3Amounts(
              TotalFundAmount, TotalInsAmount, EmployeeNo, TemplName, StartDate, EndDate)
        else begin
            YearForAmounts := Date2DMY(StartDate, 3);
            CalcAndFillSZV6_3Amounts(
              TotalFundAmount, TotalInsAmount,
              EmployeeNo, TemplName, StartDate, CalcDate('<+CM>', StartDate));

            for Month := Date2DMY(StartDate, 2) + 1 to Date2DMY(EndDate, 2) - 1 do
                CalcAndFillSZV6_3Amounts(
                  TotalFundAmount, TotalInsAmount, EmployeeNo, TemplName,
                  DMY2Date(1, Month, YearForAmounts), DMY2Date(1, Month + 1, YearForAmounts) - 1);

            CalcAndFillSZV6_3Amounts(
              TotalFundAmount, TotalInsAmount, EmployeeNo, TemplName,
              DMY2Date(1, Month + 1, YearForAmounts), EndDate);
        end;

        ExcelMgt.FillCell('FUND_SUM', Format(TotalFundAmount));
        ExcelMgt.FillCell('BASE_SUM', Format(TotalInsAmount));
    end;

    local procedure FillSZV6_3FundAndInsAmounts(InsAmount: Decimal; AccumAmount: Decimal; Month: Integer)
    begin
        if InsAmount <> 0 then
            ExcelMgt.FillCell(
              'FUND_' + Format(Month, 0, '<Integer,2><Filler Character,0>'),
              Format(InsAmount));
        if AccumAmount <> 0 then
            ExcelMgt.FillCell(
              'BASE_' + Format(Month, 0, '<Integer,2><Filler Character,0>'),
              Format(AccumAmount));
    end;

    local procedure FillSZV6_4MonthAmounts(EmployeeNo: Code[20]; TemplName: Code[10]; PeriodStartDate: Date; StartDate: Date; EndDate: Date)
    var
        CurrentMonth: Date;
        StartDateAdd: Date;
        EndDateAdd: Date;
        i: Integer;
        Table1RowNo: Integer;
        Table2RowNo: Integer;
        RowCount: Integer;
        IsZeroAmounts: Boolean;
    begin
        Table1RowNo := 54;
        Table2RowNo := 62;

        FillSZV6_4MonthGroup(
          Table1RowNo, Table2RowNo, false, EmployeeNo, TemplName, StartDate, EndDate);

        CurrentMonth := PeriodStartDate;
        RowCount := 3;
        for i := 1 to RowCount do begin
            IsZeroAmounts := not CalcDatesIntersection(
                StartDateAdd, EndDateAdd, StartDate, EndDate, CurrentMonth, CalcDate('<CM>', CurrentMonth));
            FillSZV6_4MonthGroup(
              Table1RowNo + i, Table2RowNo + i, IsZeroAmounts, EmployeeNo, TemplName, StartDateAdd, EndDateAdd);

            if i < RowCount then
                CurrentMonth := CalcDate('<1M>', CurrentMonth);
        end;
    end;

    local procedure FillSZV6_4MonthGroup(Table1RowNo: Integer; Table2RowNo: Integer; IsZeroAmounts: Boolean; EmployeeNo: Code[20]; TemplName: Code[10]; StartDate: Date; EndDate: Date)
    var
        BonusAmount: Decimal;
        InsAmount: Decimal;
        InsOverAmount: Decimal;
        Special1Amount: Decimal;
        Special2Amount: Decimal;
    begin
        if not IsZeroAmounts then begin
            CalcSZV6_4BonusAndInsAmounts(
              BonusAmount, InsAmount, InsOverAmount, TemplName, EmployeeNo, StartDate, EndDate);
            CalcSZV6_4SpecialCondAmounts(Special1Amount, Special2Amount, TemplName, EmployeeNo, StartDate, EndDate);
        end;

        ExcelMgt.FillCell('Z' + Format(Table1RowNo), Format(BonusAmount));
        ExcelMgt.FillCell('AU' + Format(Table1RowNo), Format(InsAmount));
        ExcelMgt.FillCell('BZ' + Format(Table1RowNo), Format(InsOverAmount));
        ExcelMgt.FillCell('Z' + Format(Table2RowNo), Format(Special1Amount));
        ExcelMgt.FillCell('BO' + Format(Table2RowNo), Format(Special2Amount));
    end;

    local procedure FillSVCompanyInfo(OKPOCellText: Text[30]; PFRegNoCellText: Text[30]; CompNameCellText: Text[30]; VATRegNoCellText: Text[30]; KPPCodeCellText: Text[30])
    begin
        ExcelMgt.FillCell(OKPOCellText, CompanyInfo."OKPO Code");
        ExcelMgt.FillCell(PFRegNoCellText, CompanyInfo."Pension Fund Registration No.");
        ExcelMgt.FillCell(CompNameCellText, CompanyInfo.Name);
        ExcelMgt.FillCell(VATRegNoCellText, CompanyInfo."VAT Registration No.");
        ExcelMgt.FillCell(KPPCodeCellText, CompanyInfo."KPP Code");
    end;

    local procedure FillSVHeader(CategoryType: Option; InfoType: Option Initial,Corrective,Cancel; CategoryCellText: Text[30]; InitialCellText: Text[30]; CorrCellText: Text[30]; CancelCellText: Text[30])
    begin
        ExcelMgt.FillCell(CategoryCellText, GetCategoryCode(CategoryType));
        case InfoType of
            InfoType::Initial:
                FillCellXChar(InitialCellText);
            InfoType::Corrective:
                FillCellXChar(CorrCellText);
            InfoType::Cancel:
                FillCellXChar(CancelCellText);
        end;
    end;

    local procedure FillSVHeaderPeriodInfo(InfoType: Option Initial,Corrective,Cancel; PeriodEndDate: Date; InitialFirstCellText: Text[30]; InitialSecondCellText: Text[30]; InitialThirdCellText: Text[30]; InitialFourthCellText: Text[30]; InitialYearCellText: Text[30]; CorrFirstCellText: Text[30]; CorrSecondCellText: Text[30]; CorrThirdCellText: Text[30]; CorrFourthCellText: Text[30]; CorrYearCellText: Text[30])
    begin
        case InfoType of
            InfoType::Initial:
                FillSVHeaderQuarterInfo(
                  PeriodEndDate, InitialFirstCellText, InitialSecondCellText,
                  InitialThirdCellText, InitialFourthCellText, InitialYearCellText);
            InfoType::Corrective, InfoType::Cancel:
                FillSVHeaderQuarterInfo(
                  PeriodEndDate, CorrFirstCellText, CorrSecondCellText,
                  CorrThirdCellText, CorrFourthCellText, CorrYearCellText);
        end;
    end;

    local procedure FillSVHeaderQuarterInfo(PeriodEndDate: Date; FirstCellText: Text[30]; SecondCellText: Text[30]; ThirdCellText: Text[30]; FourthCellText: Text[30]; YearCellText: Text[30])
    begin
        case Date2DMY(PeriodEndDate, 2) of
            3:
                FillCellXChar(FirstCellText);
            6:
                FillCellXChar(SecondCellText);
            9:
                FillCellXChar(ThirdCellText);
            12:
                FillCellXChar(FourthCellText);
        end;
        ExcelMgt.FillCell(YearCellText, Format(Date2DMY(PeriodEndDate, 3)));
    end;

    local procedure FillSVPersonInfo(PersonNo: Code[20]; LastNameCellText: Text[30]; FirstNameCellText: Text[30]; MiddleNameCellText: Text[30]; SocialCellText: Text[30])
    var
        Person: Record Person;
    begin
        with Person do begin
            Get(PersonNo);
            ExcelMgt.FillCell(LastNameCellText, "Last Name");
            ExcelMgt.FillCell(FirstNameCellText, "First Name");
            ExcelMgt.FillCell(MiddleNameCellText, "Middle Name");
            ExcelMgt.FillCell(SocialCellText, "Social Security No.");
        end;
    end;

    local procedure FillSVPersonShortInfo(PersonNo: Code[20]; SocialCellText: Text[30]; NameCellText: Text[30])
    var
        Person: Record Person;
    begin
        with Person do begin
            Get(PersonNo);
            ExcelMgt.FillCell(SocialCellText, "Social Security No.");
            ExcelMgt.FillCell(NameCellText, "Full Name");
        end;
    end;

    local procedure FillSVPersonAddress(PersonNo: Code[20]; CellText: Text[30])
    var
        AlternativeAddress: Record "Alternative Address";
    begin
        GetAddressByType(PersonNo, AddressType::Registration, AlternativeAddress);
        ExcelMgt.FillCell(CellText, AlternativeAddress.GetFullAddress(true));
    end;

    local procedure FillSVContractInfo(EmplContractNo: Code[20]; LaborCellText: Text[30]; CivilCellText: Text[30])
    var
        LaborContract: Record "Labor Contract";
    begin
        if LaborContract.Get(EmplContractNo) then
            case LaborContract."Contract Type" of
                LaborContract."Contract Type"::"Labor Contract":
                    FillCellXChar(LaborCellText);
                LaborContract."Contract Type"::"Civil Contract":
                    FillCellXChar(CivilCellText);
            end;
    end;

    local procedure FillExperienceBuffer(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date; RowNo: Integer; RowCount: Integer; CellText1: Text[30]; CellText2: Text[30]; CellText3: Text[30]; CellText4: Text[30]; CellText5: Text[30]; CellText6: Text[30]; CellText7: Text[30]; CellText8: Text[30]; CellText9: Text[30])
    var
        ExperienceBuffer: Record "Labor Contract Line" temporary;
        i: Integer;
    begin
        CreateExperienceBuffer(ExperienceBuffer, EmployeeNo, StartDate, EndDate);
        if ExperienceBuffer.FindSet then begin
            repeat
                i += 1;
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText1, RowNo), Format(i));
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText2, RowNo), FormatDate(ExperienceBuffer."Starting Date"));
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText3, RowNo), FormatDate(ExperienceBuffer."Ending Date"));
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText4, RowNo), ExperienceBuffer."Territorial Conditions");
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText5, RowNo), ExperienceBuffer."Special Conditions");
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText6, RowNo), ExperienceBuffer."Record of Service Reason");
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText7, RowNo), ExperienceBuffer."Record of Service Additional");
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText8, RowNo), ExperienceBuffer."Service Years Reason");
                ExcelMgt.FillCell(StrSubstNo('%1%2', CellText9, RowNo), ExperienceBuffer."Service Years Additional");
                RowNo += 1;
                if (i > RowCount) and (i < ExperienceBuffer.Count) then
                    ExcelMgt.CopyRow(RowNo - 1);
            until ExperienceBuffer.Next = 0;
        end;
    end;

    local procedure FillCellXChar(CellText: Text[30])
    begin
        ExcelMgt.FillCell(CellText, 'X');
    end;

    [Scope('OnPrem')]
    procedure SVFormToXML(FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4; var Employee: Record Employee; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; var CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer; TemplateName: Code[10]; CorrectionYear: Integer)
    var
        DisabilityPeriodBuffer: Record "Person Medical Info" temporary;
        EmpWithDisabilityBuffer: Record Employee temporary;
        EmpWithoutDisabilityBuffer: Record Employee temporary;
        EmpWithDisabLaborBuffer: Record Employee temporary;
        EmpWithoutDisabLaborBuffer: Record Employee temporary;
        EmpWithDisabCivilBuffer: Record Employee temporary;
        EmpWithoutDisabCivilBuffer: Record Employee temporary;
    begin
        GetHRSetup;
        HRSetup.TestField("TAX PF INS Element Code");
        HRSetup.TestField("TAX PF SAV Element Code");

        if (FormType = FormType::SZV_6_3) and (InfoType <> InfoType::Initial) then
            GetDisabilityBuffers(
              Employee,
              DMY2Date(1, 1, CorrectionYear),
              DMY2Date(31, 12, CorrectionYear),
              DisabilityPeriodBuffer,
              EmpWithDisabilityBuffer,
              EmpWithoutDisabilityBuffer)
        else
            GetDisabilityBuffers(Employee, StartDate, EndDate, DisabilityPeriodBuffer, EmpWithDisabilityBuffer, EmpWithoutDisabilityBuffer);

        if FormType = FormType::SZV_6_4 then begin
            CreateDisabLaborAndCivilBuffer(EmpWithoutDisabilityBuffer, EmpWithoutDisabLaborBuffer, EmpWithoutDisabCivilBuffer);
            CreateDisabLaborAndCivilBuffer(EmpWithDisabilityBuffer, EmpWithDisabLaborBuffer, EmpWithDisabCivilBuffer);
            SVFormDisabilityGroupToXML(
              DisabilityPeriodBuffer, EmpWithDisabLaborBuffer, EmpWithoutDisabLaborBuffer,
              FormType, StartDate, EndDate, CreationDate, InfoType, CompanyPackNo,
              DepartmentNo, DepartmentPackNo, TemplateName);
            SVFormDisabilityGroupToXML(
              DisabilityPeriodBuffer, EmpWithDisabCivilBuffer, EmpWithoutDisabCivilBuffer,
              FormType, StartDate, EndDate, CreationDate, InfoType, CompanyPackNo,
              DepartmentNo, DepartmentPackNo, TemplateName);
        end else
            SVFormDisabilityGroupToXML(
              DisabilityPeriodBuffer, EmpWithDisabilityBuffer, EmpWithoutDisabilityBuffer,
              FormType, StartDate, EndDate, CreationDate, InfoType, CompanyPackNo,
              DepartmentNo, DepartmentPackNo, TemplateName);
    end;

    local procedure SVFormDisabilityGroupToXML(var DisabilityPeriodBuffer: Record "Person Medical Info" temporary; var EmpWithDisabilityBuffer: Record Employee temporary; var EmpWithoutDisabilityBuffer: Record Employee temporary; FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; var CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer; TemplateName: Code[10])
    var
        CategoryType: Option WithoutDisability,WithDisability;
    begin
        if not EmpWithoutDisabilityBuffer.IsEmpty then begin
            CreateSVFormXML(
              FormType, EmpWithoutDisabilityBuffer, DisabilityPeriodBuffer, StartDate, EndDate, CreationDate,
              InfoType, CompanyPackNo, DepartmentNo, DepartmentPackNo, CategoryType::WithoutDisability, TemplateName);
            CompanyPackNo += 1;
        end;

        if not EmpWithDisabilityBuffer.IsEmpty then begin
            CreateSVFormXML(
              FormType, EmpWithDisabilityBuffer, DisabilityPeriodBuffer, StartDate, EndDate, CreationDate,
              InfoType, CompanyPackNo, DepartmentNo, DepartmentPackNo, CategoryType::WithDisability, TemplateName);
            CompanyPackNo += 1;
        end;
    end;

    local procedure CreateDisabLaborAndCivilBuffer(var EmplBuffer: Record Employee temporary; var EmplLaborBuffer: Record Employee temporary; var EmplCivilBuffer: Record Employee temporary)
    var
        LaborContract: Record "Labor Contract";
    begin
        if EmplBuffer.FindSet then
            repeat
                if LaborContract.Get(EmplBuffer."Contract No.") then
                    if LaborContract."Contract Type" = LaborContract."Contract Type"::"Labor Contract" then begin
                        EmplLaborBuffer.Copy(EmplBuffer);
                        EmplLaborBuffer.Insert;
                    end else begin
                        EmplCivilBuffer.Copy(EmplBuffer);
                        EmplCivilBuffer.Insert;
                    end;
            until EmplBuffer.Next = 0;
    end;

    local procedure CreateSVFormXML(FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4; var Employee: Record Employee; var TempPersonMedicalInfoDisability: Record "Person Medical Info" temporary; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer; CategoryType: Option WithoutDisability,WithDisability; TemplateName: Code[10])
    var
        XmlDoc: DotNet XmlDocument;
        Counter: Integer;
        DocCounter: Integer;
        InsurAmount: Decimal;
        AccumAmount: Decimal;
        SZV6_4BonusAmount: Decimal;
        SZV6_4InsAmount: Decimal;
        SZV6_4InsOverAmount: Decimal;
        TotalInsurAmount: Decimal;
        TotalAccumAmount: Decimal;
        SZV6_4TotalBonusAmount: Decimal;
        SZV6_4TotalInsAmount: Decimal;
        SZV6_4TotalInsOverAmount: Decimal;
        FileName: Text[250];
    begin
        FileName := GetXMLFileName(StartDate, CompanyPackNo, DepartmentNo, DepartmentPackNo);
        Counter := 1;

        CreateXMLDoc(XmlDoc, XMLCurrNode);
        XMLAddComplexElement(FilePFRTxt);
        XMLAddSimpleElement(FileNameTxt, FileName);
        AddFileHeader;
        XMLAddComplexElement(IncomingDocumentPackTxt);
        XMLAddAttribute(XMLCurrNode, SurroundingTxt, PartOfFileTxt);
        XMLAddAttribute(XMLCurrNode, StageTxt, BeforeProcessingTxt);

        if Employee.FindSet then
            repeat
                TempPersonMedicalInfoDisability.Reset;
                TempPersonMedicalInfoDisability.SetRange("Employee No.", Employee."No.");
                TempPersonMedicalInfoDisability.SetRange("Disability Group", CategoryType);
                if TempPersonMedicalInfoDisability.FindSet then
                    repeat
                        case FormType of
                            FormType::SPV_1, FormType::SZV_6_1, FormType::SZV_6_2:
                                CalcInsAndAccumAmounts(
                                  InsurAmount, AccumAmount, Employee."No.",
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date");
                            FormType::SZV_6_3:
                                CalcTotalEmployeeSalaryAmount(
                                  AccumAmount, InsurAmount, Employee."No.", TemplateName,
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date");
                            FormType::SZV_6_4:
                                begin
                                    CalcSZV6_4BonusAndInsAmounts(
                                      SZV6_4BonusAmount, SZV6_4InsAmount, SZV6_4InsOverAmount, TemplateName, Employee."No.",
                                      TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date");
                                    CalcSZV6_4InsAndAccumAmounts(
                                      InsurAmount, AccumAmount, TemplateName, Employee."No.",
                                      TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date");
                                    SZV6_4TotalBonusAmount += SZV6_4BonusAmount;
                                    SZV6_4TotalInsAmount += SZV6_4InsAmount;
                                    SZV6_4TotalInsOverAmount += SZV6_4InsOverAmount;
                                end;
                        end;
                        TotalInsurAmount += InsurAmount;
                        TotalAccumAmount += AccumAmount;
                        DocCounter += 1;
                    until TempPersonMedicalInfoDisability.Next = 0;
            until Employee.Next = 0;

        AddIncomingListInfo(
          FormType, Counter, DocCounter, CompanyPackNo, Employee, CreationDate, StartDate, EndDate,
          InfoType, SZV6_4TotalBonusAmount, SZV6_4TotalInsAmount, SZV6_4TotalInsOverAmount,
          TotalInsurAmount, TotalAccumAmount, CategoryType);

        if Employee.FindSet then
            repeat
                Counter += 1;
                TempPersonMedicalInfoDisability.Reset;
                TempPersonMedicalInfoDisability.SetRange("Employee No.", Employee."No.");
                TempPersonMedicalInfoDisability.SetRange("Disability Group", CategoryType);
                if TempPersonMedicalInfoDisability.FindSet then
                    repeat
                        case FormType of
                            FormType::SPV_1:
                                AddEmplContribAndPeriodsSPV1(
                                  Counter, Employee, StartDate, EndDate,
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                  CreationDate, InfoType, CategoryType);
                            FormType::SZV_6_1, FormType::SZV_6_2:
                                AddEmplContribAndPeriodsSZV62(
                                  Counter, Employee, StartDate, EndDate,
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                  CreationDate, InfoType, CategoryType);
                            FormType::SZV_6_3:
                                AddEmplContribAndPeriodsSZV63(
                                  Counter, Employee,
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                  CreationDate, InfoType, CategoryType, TemplateName);
                            FormType::SZV_6_4:
                                AddEmplContribAndPeriodsSZV64(
                                  Counter, Employee, StartDate,
                                  TempPersonMedicalInfoDisability."Starting Date", TempPersonMedicalInfoDisability."Ending Date",
                                  CreationDate, InfoType, CategoryType, TemplateName);
                        end;
                    until TempPersonMedicalInfoDisability.Next = 0;
            until Employee.Next = 0;

        if not TestMode then
            SaveXMLFile(XmlDoc, FileName);
    end;

    local procedure CreateXMLDoc(var XmlDoc: DotNet XmlDocument; var ProcInstr: DotNet XmlProcessingInstruction)
    begin
        XmlDoc := XmlDoc.XmlDocument;
        ProcInstr := XmlDoc.CreateProcessingInstruction('xml', ' version="1.0" encoding="windows-1251"');
        XmlDoc.AppendChild(ProcInstr);
    end;

    local procedure SaveXMLFile(var XmlDoc: DotNet XmlDocument; FileName: Text[250])
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XmlDoc.Save(OutStr);
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, Text002, '', Text003, FileName);
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

    local procedure AddCompanyInfo()
    begin
        CompanyInfo.Get;
        XMLAddComplexElement(PackCreatorTxt);
        AddCompanyTaxNumberInfo;
        XMLAddSimpleElement(CodEGRIPTxt, '');
        XMLAddSimpleElement(CodEGRULTxt, CompanyInfo."OGRN Code");
        XMLAddSimpleElement(FormTxt, CompanyInfo."Form of Ownership");
        XMLAddSimpleElement(CompanyNameTxt, LocalReportMgt.GetCompanyName);
        XMLAddSimpleElement(ShortNameTxt, CompanyInfo.Name);
        XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");
        XMLBackToParent;
    end;

    local procedure AddEmployeeForm(Counter: Integer; Employee: Record Employee; FillingDate: Date)
    var
        AlternativeAddress: Record "Alternative Address";
        Person: Record Person;
    begin
        XMLAddComplexElement(AnketaIPTxt);
        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        XMLAddComplexElement(AnketaDataTxt);
        AddEmployeeNameInfo(Employee);
        case Employee.Gender of
            Employee.Gender::Male:
                XMLAddSimpleElement(GenderTxt, MaleTxt);
            Employee.Gender::Female:
                XMLAddSimpleElement(GenderTxt, FemaleTxt);
        end;
        XMLAddSimpleElement(BirthDateTxt, FormatDate(Employee."Birth Date"));
        GetAddressByType(Employee."Person No.", AddressType::Birthplace, AlternativeAddress);
        XMLAddComplexElement(BirthPlaceTxt);
        Person.Get(Employee."Person No.");
        case Person."Birthplace Type" of
            Person."Birthplace Type"::Standard:
                XMLAddSimpleElement(BirthPlaceTypeTxt, STANDARDTxt);
            Person."Birthplace Type"::Special:
                XMLAddSimpleElement(BirthPlaceTypeTxt, SPECIALTxt);
        end;
        XMLAddSimpleElement(BirthCityTxt, AlternativeAddress.City);
        XMLAddSimpleElement(BirthCountyTxt, AlternativeAddress.Area);
        XMLAddSimpleElement(BirthRegionTxt, AlternativeAddress.Region);
        XMLBackToParent;
        XMLAddSimpleElement(CitizenshipTxt, GetCitizenship(Employee."Person No."));
        AddAddressInfo(RegistrationAddressTxt, Employee."Person No.", AddressType::Registration);
        AddAddressInfo(ActualAddressTxt, Employee."Person No.", AddressType::Permanent);
        if (Employee."Phone No." = '') and (Employee."Mobile Phone No." <> '') then
            XMLAddSimpleElement(PhoneTxt, Employee."Mobile Phone No.")
        else
            XMLAddSimpleElement(PhoneTxt, Employee."Phone No.");
        XMLBackToParent;
        AddEmployeeDocumentInfo(Employee."Person No.");
        XMLAddSimpleElement(FillDateTxt, FormatDate(FillingDate));
        XMLBackToParent;
    end;

    local procedure AddEmplContribAndPeriodsSPV1(Counter: Integer; Employee: Record Employee; StartDate: Date; EndDate: Date; EmployeePeriodStartDate: Date; EmployeePeriodEndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability)
    var
        Person: Record Person;
        InsurAmount: Decimal;
        AccumAmount: Decimal;
    begin
        Person.Get(Employee."Person No.");
        XMLAddComplexElement(SPV1TitleTxt);
        AddEmplContribPeriodsHeader(Counter, Employee, StartDate, EndDate, InfoType, SPV1Txt, CategoryType);
        CalcInsAndAccumAmounts(InsurAmount, AccumAmount, Employee."No.", EmployeePeriodStartDate, EmployeePeriodEndDate);
        AddInsAndAccumAmountInfo(InsurAmount, AccumAmount);
        XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
        XMLAddSimpleElement(CreationDateAsOfTxt, FormatDate(CreationDate));
        AddEmplExpBuffer(Employee."No.", EmployeePeriodStartDate, EmployeePeriodEndDate);

        XMLBackToParent;
    end;

    local procedure AddEmplContribAndPeriodsSZV62(Counter: Integer; Employee: Record Employee; StartDate: Date; EndDate: Date; EmployeePeriodStartDate: Date; EmployeePeriodEndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability)
    var
        Person: Record Person;
        InsurAmount: Decimal;
        AccumAmount: Decimal;
    begin
        Person.Get(Employee."Person No.");
        XMLAddComplexElement(SZV62TitleTxt);
        AddEmplContribPeriodsHeader(Counter, Employee, StartDate, EndDate, InfoType, SZV62Txt, CategoryType);
        AddAddressInfo(AddressIPTxt, Employee."Person No.", AddressType::Registration);

        CalcInsAndAccumAmounts(InsurAmount, AccumAmount, Employee."No.", StartDate, EndDate);
        AddInsAndAccumAmountInfo(InsurAmount, AccumAmount);
        XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
        AddEmplExpBuffer(Employee."No.", EmployeePeriodStartDate, EmployeePeriodEndDate);

        XMLBackToParent;
    end;

    local procedure AddEmplContribAndPeriodsSZV63(Counter: Integer; Employee: Record Employee; EmployeePeriodStartDate: Date; EmployeePeriodEndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability; TemplName: Code[10])
    var
        Month: Integer;
        TotalAmount: Decimal;
        TotalInsAmount: Decimal;
        AmountType: Option Month,Total,OverallTotal;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
    begin
        XMLAddComplexElement(SZV63TitleTxt);
        AddEmplContribPeriodsSZV63Hdr(
          Counter, Employee, Date2DMY(EmployeePeriodEndDate, 3), InfoType, CategoryType, CreationDate);

        PeriodStartDate := EmployeePeriodStartDate;
        for Month := Date2DMY(EmployeePeriodStartDate, 2) to Date2DMY(EmployeePeriodEndDate, 2) do begin
            if Month = Date2DMY(EmployeePeriodEndDate, 2) then
                PeriodEndDate := EmployeePeriodEndDate
            else
                PeriodEndDate := CalcDate('<CM>', PeriodStartDate);
            AddSZV63MonthAmountNode(
              TotalAmount, TotalInsAmount, Employee."No.", TemplName, PeriodStartDate, PeriodEndDate);
            PeriodStartDate := CalcDate('<1M-CM>', PeriodStartDate);
        end;

        AddBonusAmountInfo(AmountType::Total, TotalAmount, TotalInsAmount, 0);

        XMLBackToParent;
    end;

    local procedure AddEmplContribAndPeriodsSZV64(Counter: Integer; Employee: Record Employee; PeriodStartDate: Date; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability; TemplName: Code[10])
    var
        CurrentMonth: Date;
        StartDateAdd: Date;
        EndDateAdd: Date;
        MonthCount: Integer;
        i: Integer;
        InsurAmount: Decimal;
        AccumAmount: Decimal;
    begin
        XMLAddComplexElement(SZV64TitleTxt);
        AddEmplContribPeriodsSZV64Hdr(
          Counter, Employee, PeriodStartDate, InfoType, CategoryType, CreationDate);

        AddSZV64MonthAmountNode(true, TemplName, Employee."No.", StartDate, EndDate);

        CurrentMonth := PeriodStartDate;
        MonthCount := 3;
        for i := 1 to MonthCount do begin
            if CalcDatesIntersection(
                 StartDateAdd, EndDateAdd, StartDate, EndDate,
                 CurrentMonth, CalcDate('<CM>', CurrentMonth))
            then
                AddSZV64MonthAmountNode(false, TemplName, Employee."No.", StartDateAdd, EndDateAdd);
            if i < MonthCount then
                CurrentMonth := CalcDate('<1M>', CurrentMonth);
        end;

        CalcSZV6_4InsAndAccumAmounts(
          InsurAmount, AccumAmount, TemplName, Employee."No.",
          StartDate, EndDate);
        AddInsAndAccumAmountInfo(InsurAmount, AccumAmount);

        AddEmplExpBuffer(Employee."No.", StartDate, EndDate);

        XMLBackToParent;
    end;

    local procedure AddSZV63MonthAmountNode(var TotalAmount: Decimal; var TotalInsAmount: Decimal; EmployeeNo: Code[20]; TemplateName: Code[10]; StartDate: Date; EndDate: Date)
    var
        Amount: Decimal;
        InsAmount: Decimal;
        AmountType: Option Month,Total,OverallTotal;
    begin
        GetSZV6Amounts(
          Amount, InsAmount, TotalAmount, TotalInsAmount, EmployeeNo, TemplateName, StartDate, EndDate);
        if (Amount <> 0) or (InsAmount <> 0) then
            AddBonusAmountInfo(AmountType::Month, Amount, InsAmount, Date2DMY(StartDate, 2));
    end;

    local procedure GetSZV6Amounts(var Amount: Decimal; var InsAmount: Decimal; var TotalAmount: Decimal; var TotalInsAmount: Decimal; EmployeeNo: Code[20]; TemplateName: Code[10]; StartDate: Date; EndDate: Date)
    begin
        CalcTotalEmployeeSalaryAmount(Amount, InsAmount, EmployeeNo, TemplateName, StartDate, EndDate);
        TotalAmount += Amount;
        TotalInsAmount += InsAmount;
    end;

    local procedure AddSZV64MonthAmountNode(IsMonth: Boolean; TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        BonusAmount: Decimal;
        InsAmount: Decimal;
        InsOverAmount: Decimal;
        Special1Amount: Decimal;
        Special2Amount: Decimal;
    begin
        CalcSZV6_4BonusAndInsAmounts(
          BonusAmount, InsAmount, InsOverAmount, TemplName, EmployeeNo, StartDate, EndDate);
        CalcSZV6_4SpecialCondAmounts(Special1Amount, Special2Amount, TemplName, EmployeeNo, StartDate, EndDate);
        AddBonusAmountInfo6_4(IsMonth, Date2DMY(EndDate, 2), BonusAmount, InsAmount, InsOverAmount);
        AddSpecialConditionsAmounts(IsMonth, Date2DMY(EndDate, 2), Special1Amount, Special2Amount);
    end;

    local procedure AddEmplContribPeriodsHeader(Counter: Integer; Employee: Record Employee; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; FormType: Text[30]; CategoryType: Option WithoutDisability,WithDisability)
    var
        Person: Record Person;
    begin
        Person.Get(Employee."Person No.");
        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        XMLAddSimpleElement(FormTypeTxt, FormType);
        AddInfoType(InfoType);
        XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");
        XMLAddSimpleElement(ShortNameTxt, CompanyInfo.Name);
        AddCompanyTaxNumberInfo;
        XMLAddSimpleElement(CategoryCodeTxt, GetCategoryCode(CategoryType));
        AddPeriodInfo(StartDate, EndDate);
        XMLAddSimpleElement(InsuranceNumberTxt, Person."Social Security No.");
        AddEmployeeNameInfo(Employee);
    end;

    local procedure AddEmplContribPeriodsSZV63Hdr(Counter: Integer; Employee: Record Employee; Year: Integer; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability; CreationDate: Date)
    var
        Person: Record Person;
    begin
        Person.Get(Employee."Person No.");
        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        AddInfoType(InfoType);
        XMLAddSimpleElement(InsuranceNumberTxt, Person."Social Security No.");
        AddEmployeeNameInfo(Employee);
        XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");
        XMLAddSimpleElement(ShortNameTxt, CompanyInfo.Name);
        AddCompanyTaxNumberInfo;
        XMLAddSimpleElement(CategoryCodeTxt, GetCategoryCode(CategoryType));

        XMLAddSimpleElement(ContractTypeTxt, GetContractType(Employee));

        XMLAddSimpleElement(ReportingYearTxt, Format(Year));
        XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
    end;

    local procedure AddEmplContribPeriodsSZV64Hdr(Counter: Integer; Employee: Record Employee; PeriodStartDate: Date; InfoType: Option Initial,Corrective,Cancel; CategoryType: Option WithoutDisability,WithDisability; CreationDate: Date)
    var
        Person: Record Person;
    begin
        Person.Get(Employee."Person No.");
        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        AddInfoType(InfoType);
        XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");
        XMLAddSimpleElement(ShortNameTxt, CompanyInfo.Name);
        AddCompanyTaxNumberInfo;
        XMLAddSimpleElement(CategoryCodeTxt, GetCategoryCode(CategoryType));
        AddPeriodInfo(PeriodStartDate, CalcDate('<+2M+CM>', PeriodStartDate));
        XMLAddSimpleElement(InsuranceNumberTxt, Person."Social Security No.");
        AddEmployeeNameInfo(Employee);
        XMLAddSimpleElement(ContractTypeTxt, GetContractType(Employee));
        XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
        XMLAddSimpleElement(CreationDateAsOfTxt, FormatDate(CreationDate));
    end;

    local procedure AddEmplExpBuffer(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        ExperienceBuffer: Record "Labor Contract Line" temporary;
        i: Integer;
    begin
        CreateExperienceBuffer(ExperienceBuffer, EmployeeNo, StartDate, EndDate);
        if ExperienceBuffer.FindSet then
            repeat
                i += 1;
                XMLAddComplexElement(StagePeriodTxt);
                XMLAddSimpleElement(LineNumberTxt, Format(i));
                XMLAddSimpleElement(PeriodStartDateTxt, FormatDate(ExperienceBuffer."Starting Date"));
                XMLAddSimpleElement(PeriodEndDateTxt, FormatDate(ExperienceBuffer."Ending Date"));
                XMLBackToParent;
            until ExperienceBuffer.Next = 0;
    end;

    local procedure AddPeriodInfo(StartDate: Date; EndDate: Date)
    begin
        XMLAddComplexElement(ReportingPeriodTxt);
        case Date2DMY(EndDate, 2) of
            3:
                XMLAddSimpleElement(QuarterTxt, '1');
            6:
                XMLAddSimpleElement(QuarterTxt, '2');
            9:
                XMLAddSimpleElement(QuarterTxt, '3');
            12:
                XMLAddSimpleElement(QuarterTxt, '4');
        end;
        XMLAddSimpleElement(YearTxt, Format(Date2DMY(StartDate, 3)));
        XMLAddSimpleElement(NameTxt, StrSubstNo(FromToTxt, FormatDate(StartDate), FormatDate(EndDate)));
        XMLBackToParent;
    end;

    local procedure AddInsAndAccumAmountInfo(InsAmount: Decimal; AccumAmount: Decimal)
    begin
        XMLAddComplexElement(TotalContributionToInsuredTxt);
        XMLAddSimpleElement(AccruedTxt, Format(InsAmount, 0, 9));
        XMLAddSimpleElement(PaidTxt, Format(InsAmount, 0, 9));
        XMLBackToParent;
        XMLAddComplexElement(TotalContributionToAccumulatedTxt);
        XMLAddSimpleElement(AccruedTxt, Format(AccumAmount, 0, 9));
        XMLAddSimpleElement(PaidTxt, Format(AccumAmount, 0, 9));
        XMLBackToParent;
    end;

    local procedure AddCompanyTaxNumberInfo()
    begin
        XMLAddComplexElement(TaxNumberTxt);
        XMLAddSimpleElement(INNTxt, CompanyInfo."VAT Registration No.");
        XMLAddSimpleElement(KPPTxt, CompanyInfo."KPP Code");
        XMLBackToParent;
    end;

    local procedure AddEmployeeNameInfo(Employee: Record Employee)
    begin
        XMLAddComplexElement(FIOTxt);
        XMLAddSimpleElement(LastNameTxt, Employee."Last Name");
        XMLAddSimpleElement(FirstNameTxt, Employee."First Name");
        XMLAddSimpleElement(MiddleNameTxt, Employee."Middle Name");
        XMLBackToParent;
    end;

    local procedure AddIncomingListInfo(FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4; Counter: Integer; DocCounter: Integer; PackNumber: Integer; var Employee: Record Employee; CreationDate: Date; StartDate: Date; EndDate: Date; InfoType: Option Initial,Corrective,Cancel; SZV6_4TotalBonusAmount: Decimal; SZV6_4TotalInsAmount: Decimal; SZV6_4TotalInsOverAmount: Decimal; InsurAmount: Decimal; AccumAmount: Decimal; CategoryType: Option WithoutDisability,WithDisability)
    var
        AmountType: Option Month,Total,OverallTotal;
    begin
        case FormType of
            FormType::SPV_1, FormType::SZV_6_1, FormType::SZV_6_2:
                XMLAddComplexElement(IncomingList1Txt);
            FormType::SZV_6_3:
                XMLAddComplexElement(IncomingList2Txt);
            FormType::SZV_6_4:
                XMLAddComplexElement(IncomingList3Txt);
        end;

        XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
        XMLAddSimpleElement(PackContentTypeTxt, PackContentTxt);
        AddCompanyInfo;
        XMLAddComplexElement(PackNumberTxt);
        XMLAddSimpleElement(PrimaryTxt, Format(PackNumber));
        XMLBackToParent;
        XMLAddComplexElement(DocumentCollectionTxt);
        XMLAddSimpleElement(QuantityTxt, '1');
        XMLAddComplexElement(DocumentPresenceTxt);

        case FormType of
            FormType::SPV_1, FormType::SZV_6_1, FormType::SZV_6_2:
                XMLAddSimpleElement(DocumentTypeTxt, DocumentType1Txt);
            FormType::SZV_6_3:
                XMLAddSimpleElement(DocumentTypeTxt, DocumentType2Txt);
            FormType::SZV_6_4:
                XMLAddSimpleElement(DocumentTypeTxt, DocumentType3Txt);
        end;

        XMLAddSimpleElement(QuantityTxt, Format(DocCounter));
        XMLBackToParent;
        XMLBackToParent;
        XMLAddSimpleElement(CreationDateTxt, FormatDate(CreationDate));
        AddInfoType(InfoType);
        XMLAddSimpleElement(CategoryCodeTxt, GetCategoryCode(CategoryType));

        case FormType of
            FormType::SPV_1, FormType::SZV_6_1, FormType::SZV_6_2:
                begin
                    AddPeriodInfo(StartDate, EndDate);
                    AddInsAndAccumAmountInfo(InsurAmount, AccumAmount);
                end;
            FormType::SZV_6_3:
                begin
                    XMLAddSimpleElement(ContractTypeTxt, GetContractType(Employee));
                    XMLAddSimpleElement(ReportingYearTxt, Format(Date2DMY(EndDate, 3)));
                    AddBonusAmountInfo(AmountType::OverallTotal, AccumAmount, InsurAmount, 0);
                end;
            FormType::SZV_6_4:
                begin
                    AddPeriodInfo(StartDate, EndDate);
                    XMLAddSimpleElement(ContractTypeTxt, GetContractType(Employee));
                    AddBonusAmountInfo6_4(
                      true, 0, SZV6_4TotalBonusAmount, SZV6_4TotalInsAmount, SZV6_4TotalInsOverAmount);
                    AddInsAndAccumAmountInfo(InsurAmount, AccumAmount);
                end;
        end;
        XMLBackToParent;
    end;

    local procedure AddInfoType(InfoType: Option Initial,Corrective,Cancel)
    begin
        case InfoType of
            InfoType::Initial:
                XMLAddSimpleElement(InformationTypeTxt, ORIGINALTxt);
            InfoType::Corrective:
                XMLAddSimpleElement(InformationTypeTxt, CORRECTIVETxt);
            InfoType::Cancel:
                XMLAddSimpleElement(InformationTypeTxt, CANCELLATIONTxt);
        end;
    end;

    local procedure AddAddressInfo(AddressElementName: Text; PersonNo: Code[20]; AddrType: Option Permanent,Registration,Birthplace,Other)
    var
        AlternativeAddress: Record "Alternative Address";
        CountryRegion: Record "Country/Region";
    begin
        if GetAddressByType(PersonNo, AddrType, AlternativeAddress) then begin
            XMLAddComplexElement(AddressElementName);

            if AlternativeAddress."Country/Region Code" = HRSetup."Local Country/Region Code" then begin
                XMLAddSimpleElement(AddressTypeTxt, RUSSIANTxt);
                XMLAddSimpleElement(PostCodeTxt, AlternativeAddress."Post Code");
                XMLAddComplexElement(RussianAddressTxt);
                XMLAddSimpleElement(AddressConditionTxt, VALIDTxt);
                AddAddrNamePart(RegionTxt, AlternativeAddress.Region, AlternativeAddress."Region Category");
                AddAddrNamePart(CountyTxt, AlternativeAddress.Area, AlternativeAddress."Area Category");
                AddAddrNamePart(CityTxt, AlternativeAddress.City, AlternativeAddress."City Category");
                AddAddrNamePart(LocalityTxt, AlternativeAddress.Locality, AlternativeAddress."Locality Category");
                AddAddrNamePart(StreetTxt, AlternativeAddress.Street, AlternativeAddress."Street Category");
                if AlternativeAddress.House <> '' then
                    AddAddrNumberPart(HouseTxt, HTxt, AlternativeAddress.House)
                else
                    AddAddrNumberPart(HouseTxt, '', '');
                if AlternativeAddress.Building <> '' then
                    AddAddrNumberPart(BlockTxt, BLCKTxt, AlternativeAddress.Building)
                else
                    AddAddrNumberPart(BlockTxt, '', '');
                if AlternativeAddress.Apartment <> '' then
                    AddAddrNumberPart(FlatTxt, FLTxt, AlternativeAddress.Apartment)
                else
                    AddAddrNumberPart(FlatTxt, '', '');
                XMLBackToParent;
            end else begin
                XMLAddSimpleElement(AddressTypeTxt, FOREIGNTxt);
                XMLAddSimpleElement(PostCodeTxt, AlternativeAddress."Post Code");
                XMLAddComplexElement(ForeignAddressTxt);
                XMLAddSimpleElement(CountryCodeTxt, AlternativeAddress.County);
                if CountryRegion.Get(AlternativeAddress.County) then;
                XMLAddSimpleElement(CountryNameTxt, CountryRegion.Name);
                XMLAddSimpleElement(AddressTxt, AlternativeAddress.Address);
                XMLBackToParent;
            end;
            XMLBackToParent;
        end;
    end;

    local procedure AddAddrNamePart(TagName: Text; AddressPartValue: Text; Abbreviation: Text)
    begin
        XMLAddComplexElement(TagName);
        XMLAddSimpleElement(GeographicalNameTxt, AddressPartValue);
        XMLAddSimpleElement(AbbreviationTxt, Abbreviation);
        XMLBackToParent;
    end;

    local procedure AddAddrNumberPart(TagName: Text; Abbreviation: Text; Number: Text)
    begin
        XMLAddComplexElement(TagName);
        XMLAddSimpleElement(AbbreviationTxt, Abbreviation);
        XMLAddSimpleElement(NumberTxt, Number);
        XMLBackToParent;
    end;

    local procedure AddEmployeeDocumentInfo(PersonNo: Code[20])
    var
        PersonDocument: Record "Person Document";
        DocumentName: Text[100];
        DocumentTypeDesc: Code[14];
    begin
        GetIdentifyDoc(PersonNo, PersonDocument, DocumentName);
        XMLAddComplexElement(ConfirmationDocumentTxt);
        case PersonDocument."Document Type" of
            '1':
                DocumentTypeDesc := 'ÅÇæÅÄÉÆ';
            '2':
                DocumentTypeDesc := 'çâÅÇæÅÄÉÆ';
            '3':
                DocumentTypeDesc := 'æéêä Ä ÉÄåä';
            '4':
                DocumentTypeDesc := 'ôäÄæÆ ÄöêûàÉÇ';
            '5':
                DocumentTypeDesc := 'æÅÉÇéèÇ Äü Äæé';
            '6':
                DocumentTypeDesc := 'ÅÇæÅÄÉÆ îÄÉöïÆ';
            '7':
                DocumentTypeDesc := 'éÄàììøë üêïàÆ';
            '9':
                DocumentTypeDesc := 'äêÅÅÇæÅÄÉÆ Éö';
            '10':
                DocumentTypeDesc := 'êìÅÇæÅÄÉÆ';
            '11':
                DocumentTypeDesc := 'æéêä üàåàìûÇ';
            '12':
                DocumentTypeDesc := 'éêä ìÇ åêÆàï£';
            '13':
                DocumentTypeDesc := 'ôäÄæÆ üàåàìûÇ';
            '14':
                DocumentTypeDesc := 'éÉàî ôäÄæÆ';
            '21':
                DocumentTypeDesc := 'ÅÇæÅÄÉÆ ÉÄææêê';
            '22':
                DocumentTypeDesc := 'çâÅÇæÅÄÉÆ Éö';
            '26':
                DocumentTypeDesc := 'ÅÇæÅÄÉÆ îÄÉƒèÇ';
            '27':
                DocumentTypeDesc := 'éÄàì üêïàÆ Äç';
            '91':
                DocumentTypeDesc := 'ÅÉÄùàà';
        end;
        if PersonDocument."Document Type" = '91' then
            DocumentName := ''
        else
            DocumentName := DocumentTypeDesc;

        XMLAddSimpleElement(ConfirmationDocumentTypeTxt, DocumentTypeDesc);
        XMLAddComplexElement(DocumentTxt);
        XMLAddSimpleElement(ConfirmationDocumentNameTxt, DocumentName);
        XMLAddSimpleElement(SeriaRomanDigitsTxt, CopyStr(PersonDocument."Document Series", 1, 2));
        XMLAddSimpleElement(SeriaRussianLettersTxt, CopyStr(PersonDocument."Document Series", 3, 2));
        XMLAddSimpleElement(ConfirmationDocumentNumberTxt, PersonDocument."Document No.");
        XMLAddSimpleElement(IssueDateTxt, FormatDate(PersonDocument."Issue Date"));
        XMLAddSimpleElement(IssueAuthorityTxt, PersonDocument."Issue Authority");
        XMLBackToParent;
        XMLBackToParent;
    end;

    [Scope('OnPrem')]
    procedure AddFavourableExperiencePart(var LaborContractLineBuffer: Record "Labor Contract Line" temporary)
    var
        GeneralDirectory: Record "General Directory";
    begin
        with LaborContractLineBuffer do
            if HasSpecialWorkConditions then begin
                XMLAddSimpleElement(BenefitsQuantityTxt, '1');
                XMLAddComplexElement(BenefitsYearsTxt);
                XMLAddSimpleElement(LineNumberTxt, '1');
                XMLAddComplexElement(SpecialConditionsTxt);
                AddCalculationFeature("Territorial Conditions", GeneralDirectory.Type::"Territor. Condition");
                AddCalculationFeature("Special Conditions", GeneralDirectory.Type::"Special Work Condition");
                AddCalculationFeature("Record of Service Reason", GeneralDirectory.Type::"Countable Service Reason");
                AddCalculationFeature("Record of Service Additional", GeneralDirectory.Type::"Countable Service Addition");
                XMLBackToParent;
                XMLBackToParent;
            end;
    end;

    local procedure AddCalculationFeature(GeneralDirectoryCode: Code[20]; GeneralDirectoryType: Option)
    var
        GeneralDirectory: Record "General Directory";
    begin
        if GeneralDirectoryCode <> '' then
            with GeneralDirectory do begin
                SetRange(Code, GeneralDirectoryCode);
                SetRange(Type, GeneralDirectoryType);
                FindFirst;
                case "XML Element Type" of
                    "XML Element Type"::"Territorial Conditions":
                        begin
                            XMLAddComplexElement(TerritorialConditionsTxt);
                            XMLAddSimpleElement('Äß¡«óá¡¿ÑÆô', GeneralDirectoryCode);
                            XMLBackToParent;
                        end;
                    "XML Element Type"::"Special Conditions":
                        begin
                            XMLAddComplexElement(SpecialLaborConditionsTxt);
                            XMLAddSimpleElement('Äß¡«óá¡¿ÑÄôÆ', GeneralDirectoryCode);
                            XMLBackToParent;
                        end;
                    "XML Element Type"::"Countable Service Reason":
                        begin
                            XMLAddComplexElement(CountableServiceReasonTxt);
                            XMLAddSimpleElement('Äß¡«óá¡¿Ñêæ', GeneralDirectoryCode);
                            XMLBackToParent;
                        end;
                    "XML Element Type"::"Maternity Leave":
                        XMLAddSimpleElement(MaternityLeaveTxt, GeneralDirectoryCode);
                    "XML Element Type"::"Long Service":
                        begin
                            XMLAddComplexElement(LongServiceTxt);
                            XMLAddSimpleElement('Äß¡«óá¡¿Ñéï', GeneralDirectoryCode);
                            XMLBackToParent;
                        end;
                end;
            end;
    end;

    local procedure AddBonusAmountInfo(AmountType: Option Month,Total,OverallTotal; Amount: Decimal; InsAmount: Decimal; Month: Integer)
    begin
        XMLAddComplexElement(BonusAmountTxt);
        case AmountType of
            AmountType::Month:
                begin
                    XMLAddSimpleElement(LineTypeTxt, MonthTxt);
                    XMLAddSimpleElement(MonthTxt, Format(Month));
                end;
            AmountType::Total:
                XMLAddSimpleElement(LineTypeTxt, ITOGOTxt);
            AmountType::OverallTotal:
                XMLAddSimpleElement(LineTypeTxt, PACKTOTALTxt);
        end;

        XMLAddSimpleElement(TotalPaidAmountTxt, Format(Amount, 0, 9));
        XMLAddSimpleElement(PaidAmountAccruedInsuranceContributionsTxt, Format(InsAmount, 0, 9));

        XMLBackToParent;
    end;

    local procedure AddBonusAmountInfo6_4(IsTotal: Boolean; Month: Integer; BonusAmount: Decimal; InsAmount: Decimal; InsOverAmount: Decimal)
    begin
        XMLAddComplexElement(BonusAmount64Txt);
        if IsTotal then
            XMLAddSimpleElement(LineTypeTxt, ITOGTxt)
        else begin
            XMLAddSimpleElement(LineTypeTxt, MESCTxt);
            XMLAddSimpleElement(MonthTxt, Format(Month));
        end;
        XMLAddSimpleElement(TotalPaidAmountTxt, Format(BonusAmount, 0, 9));
        XMLAddSimpleElement(PaidAmountAccruedInsuranceContributionsLessTxt, Format(InsAmount, 0, 9));
        XMLAddSimpleElement(PaidAmountAccruedInsuranceContributionsMoreTxt, Format(InsOverAmount, 0, 9));
        XMLBackToParent;
    end;

    local procedure AddSpecialConditionsAmounts(IsTotal: Boolean; Month: Integer; Amount1: Decimal; Amount2: Decimal)
    begin
        XMLAddComplexElement(SpecialBonusAmountTxt);
        if IsTotal then
            XMLAddSimpleElement(LineTypeTxt, ITOGTxt)
        else begin
            XMLAddSimpleElement(LineTypeTxt, MESCTxt);
            XMLAddSimpleElement(MonthTxt, Format(Month));
        end;
        XMLAddSimpleElement(SpecialPaidAmount271Txt, Format(Amount1, 0, 9));
        XMLAddSimpleElement(SpecialPaidAmount27218Txt, Format(Amount2, 0, 9));
        XMLBackToParent;
    end;

    local procedure XMLAddElement(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode) ExitStatus: Integer
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

    local procedure XMLAddAttribute(var XMLNode: DotNet XmlNode; Name: Text; NodeValue: Text) ExitStatus: Integer
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

    local procedure XMLAddSimpleElement(NodeName: Text; NodeText: Text)
    begin
        XMLAddElement(XMLCurrNode, NodeName, UpperCase(NodeText), '', XMLNewChild);
    end;

    local procedure XMLAddComplexElement(NodeName: Text)
    begin
        XMLAddElement(XMLCurrNode, NodeName, '', '', XMLNewChild);
        XMLCurrNode := XMLNewChild;
    end;

    local procedure XMLBackToParent()
    begin
        XMLCurrNode := XMLCurrNode.ParentNode;
    end;

    local procedure CalcAndFillSZV6_3Amounts(var TotalFundAmount: Decimal; var TotalInsAmount: Decimal; EmployeeNo: Code[20]; TemplName: Code[10]; StartDate: Date; EndDate: Date)
    var
        FundAmount: Decimal;
        InsAmount: Decimal;
    begin
        CalcTotalEmployeeSalaryAmount(FundAmount, InsAmount, EmployeeNo, TemplName, StartDate, EndDate);
        FillSZV6_3FundAndInsAmounts(FundAmount, InsAmount, Date2DMY(StartDate, 2));
        TotalFundAmount += FundAmount;
        TotalInsAmount += InsAmount;
    end;

    local procedure CalcAndFillInsAndAccumAmounts(EmployeeNo: Code[20]; StartDate: Date; EndDate: Date; InsurCalcCellName: Text[30]; InsurPaidCellName: Text[30]; AccumCalcCellName: Text[30]; AccumPaidCellName: Text[30])
    var
        InsurAmount: Decimal;
        AccumAmount: Decimal;
    begin
        CalcInsAndAccumAmounts(InsurAmount, AccumAmount, EmployeeNo, StartDate, EndDate);
        FillInsAndAccumAmounts(
          InsurAmount, AccumAmount, InsurCalcCellName, InsurPaidCellName, AccumCalcCellName, AccumPaidCellName);
    end;

    local procedure CalcAndFillSZV6_4InsAndSaveAmt(TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        InsAmount: Decimal;
        AccumAmount: Decimal;
    begin
        CalcSZV6_4InsAndAccumAmounts(InsAmount, AccumAmount, TemplName, EmployeeNo, StartDate, EndDate);
        FillInsAndAccumAmounts(InsAmount, AccumAmount, 'A71', 'AB71', 'BC71', 'CD71');
    end;

    local procedure CalcInsAndAccumAmounts(var InsurAmount: Decimal; var AccumAmount: Decimal; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        Employee: Record Employee;
    begin
        with Employee do begin
            SetRange("Employee No. Filter", EmployeeNo);
            SetRange("Date Filter", StartDate, EndDate);
            SetRange("Element Code Filter", HRSetup."TAX PF INS Element Code");
            CalcFields("Payroll Amount");
            InsurAmount := -"Payroll Amount";

            SetRange("Element Code Filter", HRSetup."TAX PF SAV Element Code");
            CalcFields("Payroll Amount");
            AccumAmount := -"Payroll Amount";
        end;
    end;

    local procedure CalcSZV6_4BonusAndInsAmounts(var BonusAmount: Decimal; var InsAmount: Decimal; var InsOverAmount: Decimal; TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
    begin
        if not CalcSZV6_4Amounts(
             PayrollAnalysisLine, PayrollAnalysisColumn,
             TemplName, EmployeeNo, StartDate, EndDate)
        then
            exit;

        BonusAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
        PayrollAnalysisLine.Next;
        InsAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
        PayrollAnalysisLine.Next;
        InsOverAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
    end;

    local procedure CalcSZV6_4SpecialCondAmounts(var Special1Amount: Decimal; var Special2Amount: Decimal; TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
    begin
        if not CalcSZV6_4Amounts(
             PayrollAnalysisLine, PayrollAnalysisColumn,
             TemplName, EmployeeNo, StartDate, EndDate)
        then
            exit;

        PayrollAnalysisLine.Next(3);
        Special1Amount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
        PayrollAnalysisLine.Next;
        Special2Amount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
    end;

    local procedure CalcSZV6_4InsAndAccumAmounts(var InsAmount: Decimal; var AccumAmount: Decimal; TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
    begin
        if not CalcSZV6_4Amounts(
             PayrollAnalysisLine, PayrollAnalysisColumn,
             TemplName, EmployeeNo, StartDate, EndDate)
        then
            exit;

        PayrollAnalysisLine.Next(5);
        InsAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
        PayrollAnalysisLine.Next;
        AccumAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
    end;

    local procedure CalcSZV6_4Amounts(var PayrollAnalysisLine: Record "Payroll Analysis Line"; var PayrollAnalysisColumn: Record "Payroll Analysis Column"; TemplName: Code[10]; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date): Boolean
    begin
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", TemplName);
        PayrollAnalysisLine.SetRange("Employee Filter", EmployeeNo);
        PayrollAnalysisLine.SetRange("Date Filter", StartDate, EndDate);
        if not PayrollAnalysisLine.FindSet then
            exit(false);
        if PayrollAnalysisLine.Count < 7 then
            exit(false);
        PayrollAnalysisColumn.SetRange("Analysis Column Template", TemplName);
        if not PayrollAnalysisColumn.FindSet then
            exit(false);
        exit(true);
    end;

    local procedure FillInsAndAccumAmounts(InsurAmount: Decimal; AccumAmount: Decimal; InsurCalcCellName: Text[30]; InsurPaidCellName: Text[30]; AccumCalcCellName: Text[30]; AccumPaidCellName: Text[30])
    begin
        ExcelMgt.FillCell(InsurCalcCellName, FormatDecimal(InsurAmount));
        ExcelMgt.FillCell(InsurPaidCellName, FormatDecimal(InsurAmount));
        ExcelMgt.FillCell(AccumCalcCellName, FormatDecimal(AccumAmount));
        ExcelMgt.FillCell(AccumPaidCellName, FormatDecimal(AccumAmount));
    end;

    local procedure CalcDatesIntersection(var ResultStartDate: Date; var ResultEndDate: Date; StartDate1: Date; EndDate1: Date; StartDate2: Date; EndDate2: Date): Boolean
    begin
        if (StartDate1 > EndDate2) or (EndDate1 < StartDate2) then
            exit(false);
        if StartDate1 > StartDate2 then
            ResultStartDate := StartDate1
        else
            ResultStartDate := StartDate2;
        if EndDate1 < EndDate2 then
            ResultEndDate := EndDate1
        else
            ResultEndDate := EndDate2;
        exit(true);
    end;

    local procedure GetAddressByType(PersonNo: Code[20]; AddrType: Option Permanent,Registration,Birthplace,Other; var AlternativeAddress: Record "Alternative Address"): Boolean
    begin
        with AlternativeAddress do begin
            Init;
            SetCurrentKey("Person No.", "Address Type", "Valid from Date");
            SetRange("Person No.", PersonNo);
            SetRange("Address Type", AddrType);
            exit(FindLast);
        end;
    end;

    local procedure GetIdentifyDoc(PersonNo: Code[20]; var PersonDocument: Record "Person Document"; var DocumentName: Text[100])
    var
        Person: Record Person;
        TaxpayerDocumentType: Record "Taxpayer Document Type";
    begin
        Person.Get(PersonNo);
        Person.TestField("Identity Document Type");
        TaxpayerDocumentType.Get(Person."Identity Document Type");
        DocumentName := TaxpayerDocumentType."Document Name";
        PersonDocument.SetRange("Person No.", PersonNo);
        PersonDocument.SetRange("Document Type", Person."Identity Document Type");
        if PersonDocument.FindLast then;
    end;

    local procedure GetCitizenship(PersonNo: Code[20]): Text[30]
    var
        Person: Record Person;
        CountryRegion: Record "Country/Region";
    begin
        Person.Get(PersonNo);
        if (Person.Citizenship = '3') and (Person."Citizenship Country/Region" <> '') then begin
            CountryRegion.Get(Person."Citizenship Country/Region");
            exit(CountryRegion.Name);
        end;

        exit('');
    end;

    local procedure FillExcelRow(CellName: Text[30]; CellsQty: Integer; Value: Text[250])
    begin
        ExcelMgt.FillCellsGroup2(CellName, CellsQty, 1, UpperCase(Value), ' ', 1);
    end;

    local procedure FillADV1Date(CellName: Code[10]; Date: Date)
    begin
        FillExcelRow(CellName, 2, Format(Date2DMY(Date, 1)));
        CellName := ExcelMgt.GetNextColumn(ExcelMgt.CellName2ColumnName(CellName), 3) + Format(ExcelMgt.CellName2RowNo(CellName));
        FillExcelRow(CellName, 8, LocalMgt.Month2Text(Date));
        CellName := ExcelMgt.GetNextColumn(ExcelMgt.CellName2ColumnName(CellName), 9) + Format(ExcelMgt.CellName2RowNo(CellName));
        FillExcelRow(CellName, 4, Format(Date2DMY(Date, 3)));
    end;

    local procedure FillSPV1Date(CellName: Code[10]; Date: Date)
    begin
        ExcelMgt.FillCell(CellName, Format(Date2DMY(Date, 1)));
        CellName := ExcelMgt.GetNextColumn(ExcelMgt.CellName2ColumnName(CellName), 8) + Format(ExcelMgt.CellName2RowNo(CellName));
        ExcelMgt.FillCell(CellName, LocalMgt.Month2Text(Date));
        CellName := ExcelMgt.GetNextColumn(ExcelMgt.CellName2ColumnName(CellName), 20) + Format(ExcelMgt.CellName2RowNo(CellName));
        ExcelMgt.FillCell(CellName, Format(Date2DMY(Date, 3)));
    end;

    local procedure FormatDecimal(Amount: Decimal): Text[30]
    begin
        exit(Format(Amount, 0, 1));
    end;

    [Scope('OnPrem')]
    procedure GetSZVType(Employee: Record Employee; StartDate: Date; EndDate: Date): Integer
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        TimeActivity: Record "Time Activity";
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        SZVType: Option "SZV-6-1","SZV-6-2";
    begin
        EmployeeAbsenceEntry.SetRange("Employee No.", Employee."No.");
        EmployeeAbsenceEntry.SetFilter("Start Date", '..%1', EndDate);
        EmployeeAbsenceEntry.SetFilter("End Date", '%1..', StartDate);
        EmployeeAbsenceEntry.SetRange("Entry Type", EmployeeAbsenceEntry."Entry Type"::Usage);
        if EmployeeAbsenceEntry.FindSet then
            repeat
                TimeActivity.Get(EmployeeAbsenceEntry."Time Activity Code");
                if TimeActivity."PF Reporting Absence Code" <> '' then
                    exit(SZVType::"SZV-6-1");
            until EmployeeAbsenceEntry.Next = 0;

        FilterLaborContract(LaborContract, Employee."No.", StartDate, EndDate);
        LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Civil Contract");
        LaborContract.SetRange(Status, LaborContract.Status::Approved);
        if LaborContract.FindFirst then
            exit(SZVType::"SZV-6-1");

        LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Labor Contract");
        if LaborContract.FindFirst then begin
            LaborContractLine.SetRange("Contract No.", LaborContract."No.");
            LaborContractLine.SetRange(Status, LaborContractLine.Status::Approved);
            LaborContractLine.SetFilter("Starting Date", '..%1', EndDate);
            LaborContractLine.SetFilter("Ending Date", '..%1|%2', EndDate, 0D);
            if LaborContractLine.FindSet then
                repeat
                    if LaborContractLine.HasSpecialWorkConditions then
                        exit(SZVType::"SZV-6-1");
                until LaborContractLine.Next = 0;
        end;

        exit(SZVType::"SZV-6-2");
    end;

    local procedure GetXMLFileName(StartDate: Date; CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer): Text
    begin
        CompanyInfo.Get;
        CompanyInfo.TestField("Pension Fund Registration No.");
        exit(
          'PFR-700-' +
          'Y-' + Format(StartDate, 0, '<Year4>') +
          '-ORG-' + CompanyInfo."Pension Fund Registration No." +
          '-DCK-' + FormatNumber(CompanyPackNo, 5) +
          '-DPT-' + FormatNumber(DepartmentNo, 6) +
          '-DCK-' + FormatNumber(DepartmentPackNo, 5) + '.XML'
          );
    end;

    local procedure GetExcelTemplate(FormType: Option SPV_1,SZV_6_1,SZV_6_2,SZV_6_3,SZV_6_4): Code[10]
    begin
        GetHRSetup;
        case FormType of
            FormType::SPV_1:
                begin
                    HRSetup.TestField("SPV-1 Template Code");
                    exit(HRSetup."SPV-1 Template Code");
                end;
            FormType::SZV_6_1:
                begin
                    HRSetup.TestField("SZV-6-1 Template Code");
                    exit(HRSetup."SZV-6-1 Template Code");
                end;
            FormType::SZV_6_2:
                begin
                    HRSetup.TestField("SZV-6-2 Template Code");
                    exit(HRSetup."SZV-6-2 Template Code");
                end;
            FormType::SZV_6_3:
                begin
                    HRSetup.TestField("SZV-6-3 Template Code");
                    exit(HRSetup."SZV-6-3 Template Code");
                end;
            FormType::SZV_6_4:
                begin
                    HRSetup.TestField("SZV-6-4 Template Code");
                    exit(HRSetup."SZV-6-4 Template Code");
                end;
        end;
    end;

    local procedure FormatNumber(Number: Integer; StrLength: Integer): Text[30]
    begin
        exit(PadStr('', StrLength - StrLen(Format(Number)), '0') + Format(Number));
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure CheckEmptyDate(Date: Date; Name: Text[30])
    begin
        if Date = 0D then
            Error(Text008, Name);
    end;

    [Scope('OnPrem')]
    procedure CheckStartDate(StartDate: Date)
    begin
        CheckEmptyDate(StartDate, Text009);

        if Date2DMY(StartDate, 1) <> 1 then
            Error(Text004, Text009);

        if not (Date2DMY(StartDate, 2) in [1, 4, 7, 10]) then
            Error(Text005, Text009);
    end;

    [Scope('OnPrem')]
    procedure CheckEndDate(EndDate: Date)
    begin
        CheckEmptyDate(EndDate, Text010);

        if Date2DMY(CalcDate('<+1D>', EndDate), 1) <> 1 then
            Error(Text006, Text010);

        if not (Date2DMY(EndDate, 2) in [3, 6, 9, 12]) then
            Error(Text007, Text010);
    end;

    [Scope('OnPrem')]
    procedure CalcEndDate(StartDate: Date): Date
    begin
        exit(CalcDate('<+3M-1D>', StartDate));
    end;

    [Scope('OnPrem')]
    procedure CheckData(FormType: Option SPV,SZV; ExportType: Option Excel,XML; StartDate: Date; EndDate: Date; CreationDate: Date)
    begin
        CheckStartDate(StartDate);
        CheckEndDate(EndDate);

        if StartDate > EndDate then
            Error(Text013, Text009, Text010);

        if not ((FormType = FormType::SZV) and (ExportType = ExportType::XML)) then
            CheckEmptyDate(CreationDate, Text011);

        if StartDate > CreationDate then
            Error(Text013, Text009, Text011);
    end;

    [Scope('OnPrem')]
    procedure CreateExperienceBuffer(var ExperienceBuffer: Record "Labor Contract Line"; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        EmployeeAbsenceEntry: Record "Employee Absence Entry";
        TimeActivity: Record "Time Activity";
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
    begin
        FilterLaborContract(LaborContract, EmployeeNo, StartDate, EndDate);
        LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Labor Contract");
        if LaborContract.FindFirst then begin
            LaborContractLine.SetRange("Contract No.", LaborContract."No.");
            LaborContractLine.SetRange(Status, LaborContractLine.Status::Approved);
            LaborContractLine.SetFilter("Starting Date", '..%1', EndDate);
            LaborContractLine.SetFilter("Ending Date", '..%1|%2', EndDate, 0D);
            LaborContractLine.FindSet;
            repeat
                if LaborContract.Status = LaborContract.Status::Closed then
                    LaborContractLine."Ending Date" := LaborContract."Ending Date";
                AddPeriod(ExperienceBuffer, LaborContractLine, StartDate, EndDate);
            until LaborContractLine.Next = 0;
        end;

        LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Civil Contract");
        if LaborContract.FindFirst then begin
            LaborContractLine.Init;
            LaborContractLine."Starting Date" := LaborContract."Starting Date";
            LaborContractLine."Ending Date" := LaborContract."Ending Date";
            LaborContractLine."Record of Service Additional" := CONTRACTTxt;
            AddPeriod(ExperienceBuffer, LaborContractLine, StartDate, EndDate);
        end;

        EmployeeAbsenceEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeAbsenceEntry.SetFilter("Start Date", '..%1', EndDate);
        EmployeeAbsenceEntry.SetFilter("End Date", '%1..', StartDate);
        EmployeeAbsenceEntry.SetRange("Entry Type", EmployeeAbsenceEntry."Entry Type"::Usage);
        if EmployeeAbsenceEntry.FindSet then
            repeat
                TimeActivity.Get(EmployeeAbsenceEntry."Time Activity Code");
                if TimeActivity."PF Reporting Absence Code" <> '' then begin
                    LaborContractLine.Init;
                    LaborContractLine."Starting Date" := EmployeeAbsenceEntry."Start Date";
                    LaborContractLine."Ending Date" := EmployeeAbsenceEntry."End Date";
                    LaborContractLine."Record of Service Additional" := TimeActivity."PF Reporting Absence Code";
                    AddPeriod(ExperienceBuffer, LaborContractLine, StartDate, EndDate);
                end;
            until EmployeeAbsenceEntry.Next = 0;
    end;

    local procedure AddPeriod(var ExperienceBuffer: Record "Labor Contract Line"; Period: Record "Labor Contract Line"; StartDate: Date; EndDate: Date)
    var
        NewExperienceBuffer: Record "Labor Contract Line" temporary;
    begin
        if Period."Starting Date" < StartDate then
            Period."Starting Date" := StartDate;

        if (Period."Ending Date" > EndDate) or (Period."Ending Date" = 0D) then
            Period."Ending Date" := EndDate;

        Period."Contract No." := '';
        Period."Operation Type" := 0;

        ExperienceBuffer.Reset;
        if ExperienceBuffer.FindSet then
            repeat
                // if there is no periods intersection
                if (ExperienceBuffer."Ending Date" < Period."Starting Date") or
                   (ExperienceBuffer."Starting Date" > Period."Ending Date")
                then begin
                    NewExperienceBuffer := ExperienceBuffer;
                    NewExperienceBuffer.Insert;
                end else
                    // if labor conditions are the same
                    if CheckPeriodsConditions(ExperienceBuffer, Period) then begin
                        NewExperienceBuffer := ExperienceBuffer;
                        NewExperienceBuffer.Insert;
                    end else
                        // otherwise add periods
                        case true of
                    // new period is the same with old one
                    (ExperienceBuffer."Starting Date" = Period."Starting Date") and
                    (ExperienceBuffer."Ending Date" = Period."Ending Date"):
                        begin
                            // change old period data to new period's
                            NewExperienceBuffer := ExperienceBuffer;
                            CopyPeriodSpecialConditions(Period, NewExperienceBuffer);
                            NewExperienceBuffer.Insert;
                        end;
                    // new period is earler than old one
                    (ExperienceBuffer."Starting Date" = Period."Starting Date") and
                    (ExperienceBuffer."Ending Date" <> Period."Ending Date"):
                        begin
                            // first is new period
                            NewExperienceBuffer := Period;
                            NewExperienceBuffer."Supplement No." := FormatDateSupplement(Period."Starting Date");
                            NewExperienceBuffer.Insert;
                            // next is rest of old period
                            NewExperienceBuffer := ExperienceBuffer;
                            NewExperienceBuffer."Starting Date" := Period."Ending Date" + 1;
                            NewExperienceBuffer."Supplement No." := FormatDateSupplement(NewExperienceBuffer."Starting Date");
                            NewExperienceBuffer.Insert;
                        end;
                    // new period is inside the old one
                    (ExperienceBuffer."Starting Date" <> Period."Starting Date") and
                    (ExperienceBuffer."Ending Date" <> Period."Ending Date"):
                        begin
                            // first is a beginnig part of old period
                            NewExperienceBuffer := ExperienceBuffer;
                            NewExperienceBuffer."Ending Date" := Period."Starting Date" - 1;
                            NewExperienceBuffer.Insert;

                            // second - whole new period
                            NewExperienceBuffer."Starting Date" := Period."Starting Date";
                            NewExperienceBuffer."Supplement No." := FormatDateSupplement(NewExperienceBuffer."Starting Date");
                            NewExperienceBuffer."Ending Date" := Period."Ending Date";
                            CopyPeriodSpecialConditions(Period, NewExperienceBuffer);
                            NewExperienceBuffer.Insert;

                            // thirt - rest of the old period
                            NewExperienceBuffer := ExperienceBuffer;
                            NewExperienceBuffer."Starting Date" := Period."Ending Date" + 1;
                            NewExperienceBuffer."Supplement No." := FormatDateSupplement(NewExperienceBuffer."Starting Date");
                            NewExperienceBuffer.Insert;
                        end;
                    // new period is later than old one
                    (ExperienceBuffer."Starting Date" <> Period."Starting Date") and
                    (ExperienceBuffer."Ending Date" = Period."Ending Date"):
                        begin
                            // first is a beginning part of the old period
                            NewExperienceBuffer := ExperienceBuffer;
                            NewExperienceBuffer."Ending Date" := Period."Starting Date" - 1;
                            NewExperienceBuffer.Insert;
                            // second is a new period
                            NewExperienceBuffer."Starting Date" := Period."Starting Date";
                            NewExperienceBuffer."Supplement No." := FormatDateSupplement(NewExperienceBuffer."Starting Date");
                            NewExperienceBuffer."Ending Date" := Period."Ending Date";
                            CopyPeriodSpecialConditions(Period, NewExperienceBuffer);
                            NewExperienceBuffer.Insert;
                        end;
                        end;
            until ExperienceBuffer.Next = 0
        else begin
            NewExperienceBuffer."Starting Date" := Period."Starting Date";
            NewExperienceBuffer."Supplement No." := FormatDateSupplement(NewExperienceBuffer."Starting Date");
            NewExperienceBuffer."Ending Date" := Period."Ending Date";
            CopyPeriodSpecialConditions(Period, NewExperienceBuffer);
            NewExperienceBuffer.Insert;
        end;

        ExperienceBuffer.Reset;
        ExperienceBuffer.DeleteAll;

        if NewExperienceBuffer.FindSet then
            repeat
                ExperienceBuffer := NewExperienceBuffer;
                ExperienceBuffer.Insert;
            until NewExperienceBuffer.Next = 0;
    end;

    local procedure CopyPeriodSpecialConditions(PeriodFrom: Record "Labor Contract Line"; var PeriodTo: Record "Labor Contract Line")
    begin
        with PeriodTo do begin
            "Territorial Conditions" := PeriodFrom."Territorial Conditions";
            "Special Conditions" := PeriodFrom."Special Conditions";
            "Record of Service Reason" := PeriodFrom."Record of Service Reason";
            "Record of Service Additional" := PeriodFrom."Record of Service Additional";
            "Service Years Reason" := PeriodFrom."Service Years Reason";
            "Service Years Additional" := PeriodFrom."Service Years Additional";
        end;
    end;

    local procedure CheckPeriodsConditions(ExperienceBuffer: Record "Labor Contract Line"; Period: Record "Labor Contract Line"): Boolean
    begin
        exit(
          (ExperienceBuffer."Territorial Conditions" = Period."Territorial Conditions") and
          (ExperienceBuffer."Special Conditions" = Period."Special Conditions") and
          (ExperienceBuffer."Record of Service Reason" = Period."Record of Service Reason") and
          (ExperienceBuffer."Record of Service Additional" = Period."Record of Service Additional") and
          (ExperienceBuffer."Service Years Reason" = Period."Service Years Reason") and
          (ExperienceBuffer."Service Years Additional" = Period."Service Years Additional"));
    end;

    local procedure FormatDateSupplement(Date: Date): Code[10]
    begin
        exit(Format(Date, 0, '<year4><month,2><Filler Character,0><day,2><Filler Character,0>'));
    end;

    local procedure GetDisabilityPeriods(Employee: Record Employee; StartDate: Date; EndDate: Date; var TempPersonMedicalInfoDisability: Record "Person Medical Info" temporary)
    var
        PersonMedicalInfo: Record "Person Medical Info";
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        TempDate: Date;
    begin
        TempPersonMedicalInfoDisability.Reset;
        TempPersonMedicalInfoDisability.DeleteAll;

        PersonMedicalInfo.SetRange("Person No.", Employee."Person No.");
        PersonMedicalInfo.SetRange(Type, PersonMedicalInfo.Type::Disability);
        PersonMedicalInfo.SetFilter("Disability Group", '>0');
        PersonMedicalInfo.SetFilter("Starting Date", '..%1', EndDate);
        PersonMedicalInfo.SetFilter("Ending Date", '%1..|%2', StartDate, 0D);
        if PersonMedicalInfo.FindSet then begin
            repeat
                if PersonMedicalInfo."Starting Date" < StartDate then
                    PeriodStartDate := StartDate
                else
                    PeriodStartDate := PersonMedicalInfo."Starting Date";

                if (PersonMedicalInfo."Ending Date" = 0D) or
                   (PersonMedicalInfo."Ending Date" > EndDate)
                then
                    PeriodEndDate := EndDate
                else
                    PeriodEndDate := PersonMedicalInfo."Ending Date";

                if TempPersonMedicalInfoDisability.FindLast and
                   (TempPersonMedicalInfoDisability."Disability Group" <> TempPersonMedicalInfoDisability."Disability Group"::" ")
                then begin
                    if TempPersonMedicalInfoDisability."Ending Date" < PeriodStartDate
                    then begin
                        TempDate := TempPersonMedicalInfoDisability."Ending Date";
                        TempPersonMedicalInfoDisability.Init;
                        TempPersonMedicalInfoDisability."Starting Date" := CalcDate('<+1D>', TempDate);
                        TempPersonMedicalInfoDisability."Ending Date" := CalcDate('<-1D>', PeriodStartDate);
                        TempPersonMedicalInfoDisability.Insert;
                        TempPersonMedicalInfoDisability.Init;
                        TempPersonMedicalInfoDisability."Starting Date" := PeriodStartDate;
                        TempPersonMedicalInfoDisability."Ending Date" := PeriodEndDate;
                        TempPersonMedicalInfoDisability."Disability Group" := TempPersonMedicalInfoDisability."Disability Group"::"1";
                        TempPersonMedicalInfoDisability.Insert;
                    end else begin
                        TempPersonMedicalInfoDisability."Ending Date" := PeriodEndDate;
                        TempPersonMedicalInfoDisability.Modify;
                    end;
                end else begin
                    TempPersonMedicalInfoDisability.Init;
                    TempPersonMedicalInfoDisability."Starting Date" := PeriodStartDate;
                    TempPersonMedicalInfoDisability."Ending Date" := PeriodEndDate;
                    TempPersonMedicalInfoDisability."Disability Group" := TempPersonMedicalInfoDisability."Disability Group"::"1";
                    TempPersonMedicalInfoDisability.Insert;
                end;
            until PersonMedicalInfo.Next = 0;

            if PeriodEndDate < EndDate then begin
                TempPersonMedicalInfoDisability.Init;
                TempPersonMedicalInfoDisability."Starting Date" := PeriodEndDate + 1;
                TempPersonMedicalInfoDisability."Ending Date" := EndDate;
                TempPersonMedicalInfoDisability.Insert;
            end;
        end else begin
            TempPersonMedicalInfoDisability.Init;
            TempPersonMedicalInfoDisability."Starting Date" := StartDate;
            TempPersonMedicalInfoDisability."Ending Date" := EndDate;
            TempPersonMedicalInfoDisability.Insert;
        end;

        if TempPersonMedicalInfoDisability.FindFirst then
            if (TempPersonMedicalInfoDisability."Disability Group" <> TempPersonMedicalInfoDisability."Disability Group"::" ") and
               (TempPersonMedicalInfoDisability."Starting Date" > StartDate)
            then begin
                PeriodEndDate := TempPersonMedicalInfoDisability."Starting Date" - 1;
                TempPersonMedicalInfoDisability.Init;
                TempPersonMedicalInfoDisability."Starting Date" := StartDate;
                TempPersonMedicalInfoDisability."Ending Date" := PeriodEndDate;
                TempPersonMedicalInfoDisability.Insert;
            end;
    end;

    local procedure GetDisabilityBuffers(var Employee: Record Employee; StartDate: Date; EndDate: Date; var TempPersonMedicalInfoDisability: Record "Person Medical Info" temporary; var TempEmployeeWithDisability: Record Employee temporary; var TempEmployeeWithoutDisability: Record Employee temporary)
    var
        TempPersonMedicalInfoPeriod: Record "Person Medical Info" temporary;
        WithDisabilityPeriod: Boolean;
        WithoutDisabilityPeriod: Boolean;
        EmployeePeriodStartDate: Date;
        EmployeePeriodEndDate: Date;
    begin
        TempPersonMedicalInfoDisability.Reset;
        TempPersonMedicalInfoDisability.DeleteAll;

        if Employee.FindSet then
            repeat
                WithDisabilityPeriod := false;
                WithoutDisabilityPeriod := false;
                EmployeePeriodStartDate := StartDate;
                EmployeePeriodEndDate := EndDate;

                FitPeriodToLaborContract(Employee, EmployeePeriodStartDate, EmployeePeriodEndDate);
                GetDisabilityPeriods(Employee, EmployeePeriodStartDate, EmployeePeriodEndDate, TempPersonMedicalInfoPeriod);

                if TempPersonMedicalInfoPeriod.FindSet then
                    repeat
                        TempPersonMedicalInfoDisability := TempPersonMedicalInfoPeriod;
                        TempPersonMedicalInfoDisability."Person No." := Employee."No."; // for case when 2 employees per person
                        TempPersonMedicalInfoDisability."Employee No." := Employee."No.";
                        TempPersonMedicalInfoDisability.Insert;

                        if TempPersonMedicalInfoPeriod."Disability Group" =
                           TempPersonMedicalInfoPeriod."Disability Group"::" "
                        then
                            WithoutDisabilityPeriod := true
                        else
                            WithDisabilityPeriod := true;
                    until TempPersonMedicalInfoPeriod.Next = 0;

                if WithDisabilityPeriod then begin
                    TempEmployeeWithDisability := Employee;
                    TempEmployeeWithDisability.Insert;
                end;

                if WithoutDisabilityPeriod then begin
                    TempEmployeeWithoutDisability := Employee;
                    TempEmployeeWithoutDisability.Insert;
                end;
            until Employee.Next = 0;
    end;

    local procedure GetCategoryCode(CategoryType: Option): Code[10]
    var
        PersonMedicalInfo: Record "Person Medical Info";
    begin
        case CategoryType of
            PersonMedicalInfo."Disability Group"::" ":
                exit('ìÉ');
            else
                exit('ÄçÄê');
        end;
    end;

    local procedure GetContractType(Employee: Record Employee): Code[20]
    var
        LaborContract: Record "Labor Contract";
    begin
        if LaborContract.Get(Employee."Contract No.") then
            case LaborContract."Contract Type" of
                LaborContract."Contract Type"::"Labor Contract":
                    exit(ContractType1Txt);
                LaborContract."Contract Type"::"Civil Contract":
                    exit(ContractType2Txt);
            end;
    end;

    local procedure CheckEmployees(var Employee: Record Employee)
    var
        Person: Record Person;
        PersonDocument: Record "Person Document";
        TaxpayerDocumentType: Record "Taxpayer Document Type";
        CountryRegion: Record "Country/Region";
        AlternativeAddress: Record "Alternative Address";
    begin
        if Employee.FindSet then
            repeat
                Employee.TestField(Gender);
                Employee.TestField("Person No.");
                Person.Get(Employee."Person No.");
                Person.TestField(Citizenship);
                if Person.Citizenship = '3' then begin
                    Person.TestField("Citizenship Country/Region");
                    CountryRegion.Get(Person."Citizenship Country/Region");
                end;
                Person.TestField("Identity Document Type");
                TaxpayerDocumentType.Get(Person."Identity Document Type");
                PersonDocument.SetRange("Person No.", Person."No.");
                PersonDocument.SetRange("Document Type", Person."Identity Document Type");
                PersonDocument.FindLast;
                PersonDocument.TestField("Document No.");
                PersonDocument.TestField("Issue Authority");
                PersonDocument.TestField("Issue Date");
                if not GetAddressByType(Person."No.", AddressType::Registration, AlternativeAddress) then
                    Error(Text014, Text015, Person."No.");
                if Person."Birthplace Type" = Person."Birthplace Type"::Standard then
                    if not GetAddressByType(Person."No.", AddressType::Birthplace, AlternativeAddress) then
                        Error(Text014, Text016, Person."No.");
            until Employee.Next = 0;
    end;

    local procedure GetHRSetup()
    begin
        if not HRSetupRead then
            HRSetup.Get;
        HRSetupRead := true;
    end;

    [Scope('OnPrem')]
    procedure CheckEmployeeLaborContract(Employee: Record Employee; StartDate: Date; EndDate: Date): Boolean
    var
        LaborContract: Record "Labor Contract";
    begin
        FilterLaborContract(LaborContract, Employee."No.", StartDate, EndDate);
        exit(LaborContract.FindFirst);
    end;

    local procedure FitPeriodToLaborContract(Employee: Record Employee; var StartDate: Date; var EndDate: Date)
    var
        LaborContract: Record "Labor Contract";
    begin
        FilterLaborContract(LaborContract, Employee."No.", StartDate, EndDate);
        if LaborContract.FindFirst then begin
            if LaborContract."Starting Date" > StartDate then
                StartDate := LaborContract."Starting Date";
            if (LaborContract."Ending Date" <> 0D) and (LaborContract."Ending Date" < EndDate) then
                EndDate := LaborContract."Ending Date";
        end;
    end;

    local procedure FilterLaborContract(var LaborContract: Record "Labor Contract"; EmployeeNo: Code[20]; StartDate: Date; EndDate: Date)
    begin
        LaborContract.SetRange("Employee No.", EmployeeNo);
        LaborContract.SetFilter("Starting Date", '..%1', EndDate);
        LaborContract.SetFilter("Ending Date", '%1..|%2', StartDate, 0D);
    end;

    local procedure CalcTotalEmployeeSalaryAmount(var FundAmount: Decimal; var InsAmount: Decimal; EmployeeNo: Code[20]; TemplName: Code[10]; StartDate: Date; EndDate: Date)
    var
        PayrollAnalysisLine: Record "Payroll Analysis Line";
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
    begin
        // This block is hardcoded against analytical report with 2 lines
        PayrollAnalysisLine.SetRange("Analysis Line Template Name", TemplName);
        PayrollAnalysisLine.SetRange("Employee Filter", EmployeeNo);
        PayrollAnalysisLine.SetRange("Date Filter", StartDate, EndDate);
        PayrollAnalysisColumn.SetRange("Analysis Column Template", TemplName);

        if not PayrollAnalysisColumn.FindFirst then
            exit;
        if not PayrollAnalysisLine.FindSet then
            exit;
        if PayrollAnalysisLine.Count < 2 then
            exit;

        FundAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
        PayrollAnalysisLine.Next;
        InsAmount := PayrollAnalysisReportMgt.CalcCell(PayrollAnalysisLine, PayrollAnalysisColumn, false);
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

