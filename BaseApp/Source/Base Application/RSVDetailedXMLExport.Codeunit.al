codeunit 17473 "RSV Detailed XML Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        RSVCalculationMgt: Codeunit "RSV Calculation Mgt.";
        RSVCommonXMLExport: Codeunit "RSV Common XML Export";
        XMLCurrNode: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
        SkipExport: Boolean;
        ContractType1Txt: Label 'LABOR', Locked = true;
        ContractType2Txt: Label 'CIVIL', Locked = true;
        LineTypeTxt: Label 'LineType', Locked = true;
        LineNumberTxt: Label 'LineNumber', Locked = true;
        MonthTxt: Label 'Month', Locked = true;
        ITOGTxt: Label 'ITOG', Locked = true;
        MESCTxt: Label 'MESC', Locked = true;
        DocumentTypeTxt: Label 'DocumentType', Locked = true;
        QuantityTxt: Label 'Quantity', Locked = true;
        CategoryCodeTxt: Label 'CategoryCode', Locked = true;
        ReportingPeriodTxt: Label 'ReportingPeriod', Locked = true;
        DocumentCollectionTxt: Label 'DocumentCollection', Locked = true;
        DocumentPresenceTxt: Label 'DocumentPresence', Locked = true;
        NumberInPackTxt: Label 'NumberInPack', Locked = true;
        CreationDateTxt: Label 'CreationDate', Locked = true;
        PackNumberTxt: Label 'PackNumber', Locked = true;
        PrimaryTxt: Label 'Primary', Locked = true;
        RegistrationNumberTxt: Label 'RegistrationNumber', Locked = true;
        InsuranceNumberTxt: Label 'InsuranceNumber', Locked = true;
        TaxNumberTxt: Label 'TaxNumberTxt', Locked = true;
        ShortNameTxt: Label 'ShortName', Locked = true;
        FillDateTxt: Label 'FillDate', Locked = true;
        QuarterTxt: Label 'Quarter', Locked = true;
        YearTxt: Label 'Year', Locked = true;
        FilePFRTxt: Label 'FilePFR', Locked = true;
        FileNameTxt: Label 'FileName', Locked = true;
        PackContentTxt: Label 'PACK CONTENT', Locked = true;
        PackContentTypeTxt: Label 'PackContentType', Locked = true;
        IncomingDocumentPackTxt: Label 'IncomingDocumentPack', Locked = true;
        PartOfFileTxt: Label 'Part of file', Locked = true;
        SurroundingTxt: Label 'Surrounding', Locked = true;
        StageTxt: Label 'Stage', Locked = true;
        BeforeProcessingTxt: Label 'Before Processing', Locked = true;
        FileHeaderTxt: Label 'FileHeader', Locked = true;
        FileTypeTxt: Label 'FileType', Locked = true;
        FormatVersionTxt: Label 'FormatVersion', Locked = true;
        DataPreparationProgramTxt: Label 'DataPreparationProgram', Locked = true;
        ProgramNameTxt: Label 'ProgramName', Locked = true;
        VersionTxt: Label 'Version', Locked = true;
        DataSourceTxt: Label 'DataSourceTxt', Locked = true;
        INSURERTxt: Label 'INSURER', Locked = true;
        NameTxt: Label 'Name', Locked = true;
        INNTxt: Label 'INN', Locked = true;
        KPPTxt: Label 'KPP', Locked = true;
        FIOTxt: Label 'FIO', Locked = true;
        LastNameTxt: Label 'LastName', Locked = true;
        FirstNameTxt: Label 'FirstName', Locked = true;
        MiddleNameTxt: Label 'MiddleName', Locked = true;
        InformationTypeTxt: Label 'InformationType', Locked = true;
        ORIGINALTxt: Label 'ORIGINAL', Locked = true;
        CORRECTIVETxt: Label 'CORRECTIVE', Locked = true;
        CANCELLATIONTxt: Label 'CANCELLATION', Locked = true;
        StagePeriodTxt: Label 'StagePeriod', Locked = true;
        PeriodStartDateTxt: Label 'PeriodStartDate', Locked = true;
        PeriodEndDateTxt: Label 'PeriodEndDate', Locked = true;
        PackCreatorTxt: Label 'PackCreator', Locked = true;
        EXTERNALTxt: Label 'EXTERNAL', Locked = true;
        SPV1TitleTxt: Label 'SPV1Title', Locked = true;
        SpecialConditionsTxt: Label 'SpecialConditions', Locked = true;
        BenefitsYearsTxt: Label 'BenefitsYears', Locked = true;
        TerritorialConditionsTxt: Label 'TerritorialConditions', Locked = true;
        SpecialLaborConditionsTxt: Label 'SpecialLaborConditions', Locked = true;
        MaternityLeaveTxt: Label 'MaternityLeave', Locked = true;
        LineCodeTxt: Label 'LineCode', Locked = true;
        BaseForInsuranceContributionsAccrualsLessThanLimitTxt: Label 'BaseForInsuranceCOntributionsAccrualsLessThanLimit', Locked = true;
        InsuranceContributionsOPSTxt: Label 'InsuranceContributionsOPS', Locked = true;
        NumberOfBenefitsTxt: Label 'NumberOfBenefits', Locked = true;
        DismissalDataTxt: Label 'DismissalDataTxt', Locked = true;
        DISMISSEDTxt: Label 'DISMISSED', Locked = true;
        OtherRewardsPaymentAmountTxt: Label 'OtherRewardsPaymentAmount', Locked = true;
        NotExceededTotalTxt: Label 'NotExceededTotal', Locked = true;
        NotExceededByContractsTxt: Label 'NotExceededByContracts', Locked = true;
        ExceededLimitTxt: Label 'ExceededLimit', Locked = true;
        ContributionAmountsForOPSTxt: Label 'ContributionAmountsForOPS', Locked = true;
        InfoAboutPaymentsAndRewardsToIPTxt: Label 'InfoAboutPaymentsAndRewardsToIP', Locked = true;
        Chapter6PackTitleTxt: Label 'Chapter6PackTitle', Locked = true;
        NRTxt: Label 'NR', Locked = true;
        OOITxt: Label 'OOI', Locked = true;

    [Scope('OnPrem')]
    procedure ExportDetailedXML(var Person: Record Person; var PackPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; FolderName: Text)
    var
        TempDetailPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        TempTotalPaidPayrollReportingBuffer: Record "Payroll Reporting Buffer" temporary;
        PackNo: Integer;
    begin
        if Person.IsEmpty then
            exit;

        CompanyInfo.Get;

        RSVCalculationMgt.CalcDetailedBuffer(
          TempDetailPayrollReportingBuffer, TempTotalPaidPayrollReportingBuffer, Person, StartDate, EndDate);
        RSVCalculationMgt.CalcBeginBalanceBuffer(TempTotalPaidPayrollReportingBuffer, Person, StartDate);
        with TempDetailPayrollReportingBuffer do begin
            PackNo := 1;
            while GetNextBufferByPack(TempDetailPayrollReportingBuffer, PackNo) do begin
                RSVCalculationMgt.GetReportingPersonList(TempPersonPayrollReportingBuffer, TempDetailPayrollReportingBuffer);
                PackPayrollReportingBuffer."Entry No." := "Pack No.";
                PackPayrollReportingBuffer."File Name" :=
                  CreateDetailedXML(TempDetailPayrollReportingBuffer, TempPersonPayrollReportingBuffer,
                    StartDate, EndDate, CreationDate, InfoType, FolderName);
                PackPayrollReportingBuffer.Insert;
                PackNo += 1;
            end;
        end;
    end;

    local procedure CreateDetailedXML(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; FolderName: Text) FileName: Text[250]
    begin
        FileName := GetXMLFileName(StartDate, PersonifiedPayrollReportingBuffer."Pack No.", 0, 0);
        RSVCommonXMLExport.CreateXMLDoc(XmlDoc, XMLCurrNode);
        XMLAddComplexElement(FilePFRTxt);
        XMLAddSimpleElement(FileNameTxt, FileName);
        AddFileHeader;
        AddPackage(PersonifiedPayrollReportingBuffer, ReportingPersonPayrollReportingBuffer, StartDate, EndDate, CreationDate, InfoType);
        if not SkipExport then
            RSVCommonXMLExport.SaveXMLFile(XmlDoc, FolderName, FileName);
        exit(FileName);
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

    local procedure AddPackage(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel)
    begin
        XMLAddComplexElement(IncomingDocumentPackTxt);
        XMLAddAttribute(XMLCurrNode, SurroundingTxt, PartOfFileTxt);
        XMLAddAttribute(XMLCurrNode, StageTxt, BeforeProcessingTxt);
        AddPackageHeader(
          PersonifiedPayrollReportingBuffer, StartDate, EndDate, CreationDate, InfoType, ReportingPersonPayrollReportingBuffer.Count);
        AddPackageDetails(
          PersonifiedPayrollReportingBuffer, ReportingPersonPayrollReportingBuffer, StartDate, EndDate, CreationDate, InfoType);
    end;

    local procedure AddPackageHeader(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel; DocCount: Integer)
    begin
        XMLAddComplexElement(Chapter6PackTitleTxt);
        XMLAddSimpleElement(NumberInPackTxt, '1');
        XMLAddSimpleElement(PackContentTypeTxt, PackContentTxt);

        AddCompanyInfo;

        XMLAddComplexElement(PackNumberTxt);
        XMLAddSimpleElement(PrimaryTxt, Format(PersonifiedPayrollReportingBuffer."Pack No."));
        XMLBackToParent;

        XMLAddComplexElement(DocumentCollectionTxt);
        XMLAddSimpleElement(QuantityTxt, '1');
        XMLAddComplexElement(DocumentPresenceTxt);
        XMLAddSimpleElement(DocumentTypeTxt, SPV1TitleTxt);
        XMLAddSimpleElement(QuantityTxt, Format(DocCount));
        XMLBackToParent;
        XMLBackToParent;

        XMLAddSimpleElement(CreationDateTxt, FormatDate(CreationDate));

        AddInfoType(InfoType);

        AddPeriodInfo(StartDate, EndDate);

        ResetAllFiltersExceptPackNo(PersonifiedPayrollReportingBuffer, PersonifiedPayrollReportingBuffer."Pack No.");
        PersonifiedPayrollReportingBuffer.SetFilter("Code 2", '<>%1', '0');
        PersonifiedPayrollReportingBuffer.CalcSums("Amount 2", "Amount 4");

        XMLAddSimpleElement(
          BaseForInsuranceContributionsAccrualsLessThanLimitTxt, FormatDecimal(PersonifiedPayrollReportingBuffer."Amount 2"));
        XMLAddSimpleElement(InsuranceContributionsOPSTxt, FormatDecimal(-PersonifiedPayrollReportingBuffer."Amount 4"));
        XMLBackToParent;
    end;

    local procedure AddPackageDetails(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; var ReportingPersonPayrollReportingBuffer: Record "Payroll Reporting Buffer"; StartDate: Date; EndDate: Date; CreationDate: Date; InfoType: Option Initial,Corrective,Cancel)
    var
        Person: Record Person;
        Counter: Integer;
        LineCounter: Integer;
    begin
        ResetAllFiltersExceptPackNo(PersonifiedPayrollReportingBuffer, PersonifiedPayrollReportingBuffer."Pack No.");
        Counter := 2;
        if ReportingPersonPayrollReportingBuffer.FindSet then
            repeat
                if Person.Get(ReportingPersonPayrollReportingBuffer."Code 1") then;
                XMLAddComplexElement(SPV1TitleTxt);
                XMLAddSimpleElement(NumberInPackTxt, Format(Counter));
                AddInfoType(InfoType);
                XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");

                AddPersonInfo(ReportingPersonPayrollReportingBuffer."Code 1", EndDate);
                AddPeriodInfo(StartDate, EndDate);
                LineCounter := 0;
                PersonifiedPayrollReportingBuffer.SetRange("Code 1", ReportingPersonPayrollReportingBuffer."Code 1");
                RSVCalculationMgt.FilterReportingBuffer(PersonifiedPayrollReportingBuffer, ReportingPersonPayrollReportingBuffer);
                if PersonifiedPayrollReportingBuffer.FindSet then
                    repeat
                        if PersonifiedPayrollReportingBuffer."Code 2" in ['0' .. '3'] then begin
                            LineCounter += 1;
                            AddPackageDetailLine(PersonifiedPayrollReportingBuffer, LineCounter, EndDate);
                        end;
                    until PersonifiedPayrollReportingBuffer.Next = 0;

                PersonifiedPayrollReportingBuffer.SetFilter("Code 2", '<>%1', '0');
                PersonifiedPayrollReportingBuffer.CalcSums("Amount 4");
                PersonifiedPayrollReportingBuffer.SetRange("Code 2");

                XMLAddSimpleElement(ContributionAmountsForOPSTxt, FormatDecimal(-PersonifiedPayrollReportingBuffer."Amount 4"));
                AddExperienceBuf(ReportingPersonPayrollReportingBuffer."Code 1", EndDate);
                XMLAddSimpleElement(FillDateTxt, FormatDate(CreationDate));
                XMLBackToParent;
                Counter += 1;
            until ReportingPersonPayrollReportingBuffer.Next = 0;
    end;

    local procedure AddPackageDetailLine(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; LineCounter: Integer; EndDate: Date)
    begin
        XMLAddComplexElement(InfoAboutPaymentsAndRewardsToIPTxt);
        XMLAddSimpleElement(LineNumberTxt, Format(LineCounter));
        if PersonifiedPayrollReportingBuffer."Code 2" = '0' then
            XMLAddSimpleElement(LineTypeTxt, ITOGTxt)
        else begin
            XMLAddSimpleElement(LineTypeTxt, MESCTxt);
            XMLAddSimpleElement(MonthTxt, Format(GetMonthNo(PersonifiedPayrollReportingBuffer."Code 2", EndDate)));
        end;
        case PersonifiedPayrollReportingBuffer."Code 2" of
            '0':
                XMLAddSimpleElement(LineCodeTxt, '400');
            '1':
                XMLAddSimpleElement(LineCodeTxt, '401');
            '2':
                XMLAddSimpleElement(LineCodeTxt, '402');
            '3':
                XMLAddSimpleElement(LineCodeTxt, '403');
        end;
        if PersonifiedPayrollReportingBuffer."Code 3" = '01' then
            XMLAddSimpleElement(CategoryCodeTxt, NRTxt)
        else
            XMLAddSimpleElement(CategoryCodeTxt, OOITxt);
        XMLAddSimpleElement(OtherRewardsPaymentAmountTxt, FormatDecimal(PersonifiedPayrollReportingBuffer."Amount 1"));
        XMLAddSimpleElement(NotExceededTotalTxt, FormatDecimal(PersonifiedPayrollReportingBuffer."Amount 2"));
        XMLAddSimpleElement(NotExceededByContractsTxt, FormatDecimal(0));
        XMLAddSimpleElement(ExceededLimitTxt, FormatDecimal(PersonifiedPayrollReportingBuffer."Amount 3"));
        XMLBackToParent;
    end;

    local procedure AddCompanyInfo()
    begin
        CompanyInfo.Get;
        XMLAddComplexElement(PackCreatorTxt);
        XMLAddComplexElement(TaxNumberTxt);
        XMLAddSimpleElement(INNTxt, CompanyInfo."VAT Registration No.");
        XMLAddSimpleElement(KPPTxt, CompanyInfo."KPP Code");
        XMLBackToParent;
        XMLAddSimpleElement(ShortNameTxt, CompanyInfo.Name);
        XMLAddSimpleElement(RegistrationNumberTxt, CompanyInfo."Pension Fund Registration No.");
        XMLBackToParent;
    end;

    local procedure AddPeriodInfo(StartDate: Date; EndDate: Date)
    begin
        XMLAddComplexElement(ReportingPeriodTxt);
        case Date2DMY(EndDate, 2) of
            3:
                XMLAddSimpleElement(QuarterTxt, '3');
            6:
                XMLAddSimpleElement(QuarterTxt, '6');
            9:
                XMLAddSimpleElement(QuarterTxt, '9');
            12:
                XMLAddSimpleElement(QuarterTxt, '0');
        end;
        XMLAddSimpleElement(YearTxt, Format(Date2DMY(StartDate, 3)));
        XMLAddSimpleElement(NameTxt, StrSubstNo('ß %1 »« %2', FormatDate(StartDate), FormatDate(EndDate)));
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

    local procedure AddPersonInfo(PersonNo: Code[20]; EndDate: Date)
    var
        Person: Record Person;
        LaborContract: Record "Labor Contract";
        StartDate: Date;
    begin
        if Person.Get(PersonNo) then begin
            XMLAddSimpleElement(InsuranceNumberTxt, Person."Social Security No.");
            XMLAddComplexElement(FIOTxt);
            XMLAddSimpleElement(LastNameTxt, Person."Last Name");
            XMLAddSimpleElement(FirstNameTxt, Person."First Name");
            XMLAddSimpleElement(MiddleNameTxt, Person."Middle Name");
            XMLBackToParent;

            StartDate := CalcDate('<-CM-2M>', EndDate);
            LaborContract.SetRange("Contract Type", LaborContract."Contract Type"::"Labor Contract");
            LaborContract.SetRange("Person No.", PersonNo);
            LaborContract.SetFilter("Ending Date", '>=%1&<=%2', StartDate, EndDate);

            if LaborContract.FindFirst then
                XMLAddSimpleElement(DismissalDataTxt, DISMISSEDTxt);
        end;
    end;

    local procedure AddExperienceBuf(EmployeeNo: Code[20]; EndDate: Date)
    var
        TempExperienceLaborContractLine: Record "Labor Contract Line" temporary;
        GeneralDirectory: Record "General Directory";
        PeriodCount: Integer;
    begin
        RSVCalculationMgt.CreatePersonExperienceBuffer(TempExperienceLaborContractLine, EmployeeNo, CalcDate('<-CM-2M>', EndDate), EndDate);
        PeriodCount := 0;
        GeneralDirectory.SetRange(
          "XML Element Type",
          GeneralDirectory."XML Element Type"::"Territorial Conditions",
          GeneralDirectory."XML Element Type"::"Long Service");

        if TempExperienceLaborContractLine.FindSet then
            repeat
                PeriodCount += 1;
                XMLAddComplexElement(StagePeriodTxt);
                XMLAddSimpleElement(LineNumberTxt, Format(PeriodCount));
                XMLAddSimpleElement(PeriodStartDateTxt, FormatDate(TempExperienceLaborContractLine."Starting Date"));
                XMLAddSimpleElement(PeriodEndDateTxt, FormatDate(TempExperienceLaborContractLine."Ending Date"));

                GeneralDirectory.SetRange(Code, TempExperienceLaborContractLine."Record of Service Additional");
                if GeneralDirectory.FindFirst then begin
                    XMLAddSimpleElement(NumberOfBenefitsTxt, '1');
                    AddDetailExperienceBuf(GeneralDirectory);
                end else
                    XMLAddSimpleElement(NumberOfBenefitsTxt, '0');
                XMLBackToParent;
            until TempExperienceLaborContractLine.Next = 0;
    end;

    local procedure AddDetailExperienceBuf(GeneralDirectory: Record "General Directory")
    begin
        XMLAddComplexElement(BenefitsYearsTxt);
        XMLAddSimpleElement(LineNumberTxt, '1');
        XMLAddComplexElement(SpecialConditionsTxt);

        with GeneralDirectory do
            case "XML Element Type" of
                "XML Element Type"::"Territorial Conditions":
                    begin
                        XMLAddComplexElement(TerritorialConditionsTxt);
                        XMLAddSimpleElement('Äß¡«óá¡¿ÑÄôÆ', Format(Code));
                        XMLBackToParent;
                    end;
                "XML Element Type"::"Special Conditions":
                    begin
                        XMLAddComplexElement(SpecialLaborConditionsTxt);
                        XMLAddSimpleElement('Äß¡«óá¡¿ÑÆô', Format(Code));
                        XMLBackToParent;
                    end;
                "XML Element Type"::"Maternity Leave":
                    XMLAddSimpleElement(MaternityLeaveTxt, Format(Code));
            end;

        XMLBackToParent;
        XMLBackToParent;
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure FormatDecimal(Amount: Decimal): Text[30]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Sign><Integer><Decimals><comma,.>'));
    end;

    [Scope('OnPrem')]
    procedure FormatNumber(Number: Integer; StrLength: Integer): Text[30]
    begin
        exit(PadStr('', StrLength - StrLen(Format(Number)), '0') + Format(Number));
    end;

    local procedure ResetAllFiltersExceptPackNo(var PersonifiedPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PackNo: Integer)
    begin
        PersonifiedPayrollReportingBuffer.Reset;
        PersonifiedPayrollReportingBuffer.SetCurrentKey("Pack No.");
        PersonifiedPayrollReportingBuffer.SetRange("Pack No.", PackNo);
    end;

    [Scope('OnPrem')]
    procedure GetXMLFileName(StartDate: Date; CompanyPackNo: Integer; DepartmentNo: Integer; DepartmentPackNo: Integer): Text[250]
    begin
        CompanyInfo.TestField("Pension Fund Registration No.");
        exit(
          'PFR-700-' +
          'Y-' + Format(StartDate, 0, '<Year4>') +
          '-ORG-' + CompanyInfo."Pension Fund Registration No." +
          '-DCK-' + FormatNumber(CompanyPackNo + 1, 5) +
          '-DPT-' + FormatNumber(DepartmentNo, 6) +
          '-DCK-' + FormatNumber(DepartmentPackNo, 5) + '.XML');
    end;

    [Scope('OnPrem')]
    procedure GetContractType(Employee: Record Employee): Code[20]
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

    local procedure GetMonthNo(MonthCode: Code[20]; PeriodEndDate: Date): Integer
    var
        QuarterEndMonthNo: Integer;
    begin
        QuarterEndMonthNo := Date2DMY(PeriodEndDate, 2);
        case MonthCode of
            '1':
                exit(QuarterEndMonthNo - 2);
            '2':
                exit(QuarterEndMonthNo - 1);
            '3':
                exit(QuarterEndMonthNo);
        end;
    end;

    local procedure GetNextBufferByPack(var DetailPayrollReportingBuffer: Record "Payroll Reporting Buffer"; PackNo: Integer): Boolean
    begin
        ResetAllFiltersExceptPackNo(DetailPayrollReportingBuffer, PackNo);
        exit(DetailPayrollReportingBuffer.FindSet);
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

    [Scope('OnPrem')]
    procedure SetSkipExport(NewSkipExport: Boolean)
    begin
        SkipExport := NewSkipExport;
    end;
}

