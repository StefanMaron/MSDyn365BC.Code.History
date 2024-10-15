report 17430 "Export Form 2-NDFL to XML"
{
    ApplicationArea = Basic, Suite;
    Caption = 'XML Employee Income';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PersonIncomeHeader; "Person Income Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", Year;
            dataitem(TaxIterator; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                dataitem(PersonIncomeEntry1; "Person Income Entry")
                {
                    DataItemTableView = SORTING("Person Income No.", "Person Income Line No.", "Line No.") WHERE("Entry Type" = CONST("Taxable Income"), "Tax Code" = FILTER(<> ''), "Advance Payment" = CONST(false));

                    trigger OnAfterGetRecord()
                    begin
                        TempPersonIncomeEntry.SetRange("Period Code", "Period Code");
                        TempPersonIncomeEntry.SetRange("Tax Code", "Tax Code");
                        if TempPersonIncomeEntry.FindFirst then begin
                            TempPersonIncomeEntry.Base += Base;
                            TempPersonIncomeEntry.Modify();
                        end else begin
                            TempPersonIncomeEntry := PersonIncomeEntry1;
                            TempPersonIncomeEntry.Insert();
                        end;
                    end;

                    trigger OnPostDataItem()
                    var
                        TaxDeductCode: Code[10];
                        TaxDeductAmount: Decimal;
                    begin
                        with TempPersonIncomeEntry do begin
                            Reset;
                            if FindSet then
                                repeat
                                    XMLExcelReportsMgt.AddSubNode(CurrNode[3], CurrNode[4], SvSumIncTxt);
                                    XMLExcelReportsMgt.AddAttribute(CurrNode[4], MonthTxt, CreateMonthText(GetPeriodCode("Period Code")));
                                    XMLExcelReportsMgt.AddAttribute(CurrNode[4], IncomeCodeTxt, "Tax Code");
                                    XMLExcelReportsMgt.AddAttribute(CurrNode[4], IncomeAmtTxt, DecimalToText(Base));
                                    TaxDeductCode := GetLastPayrollDirDeductCode("Tax Code", "Posting Date");
                                    if TaxDeductCode <> '' then begin
                                        TaxDeductAmount := GetTotalDeductAmount(TaxDeductCode, "Period Code");
                                        if TaxDeductAmount <> 0 then begin
                                            XMLExcelReportsMgt.AddSubNode(CurrNode[4], CurrNode[5], SvSumDedTxt);
                                            XMLExcelReportsMgt.AddAttribute(CurrNode[5], DeductCodeTxt, TaxDeductCode);
                                            XMLExcelReportsMgt.AddAttribute(CurrNode[5], DeductAmtTxt, DecimalToText(TaxDeductAmount));
                                        end;
                                    end;
                                until Next = 0;
                            DeleteAll();
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Person Income No.", PersonIncomeHeader."No.");
                        SetRange("Person No.", PersonIncomeHeader."Person No.");
                        case PersentTax of
                            PersentTax::"13":
                                SetRange("Tax %", "Tax %"::"13");
                            PersentTax::"30":
                                SetRange("Tax %", "Tax %"::"30");
                            PersentTax::"9":
                                SetRange("Tax %", "Tax %"::"9");
                            PersentTax::"35":
                                SetRange("Tax %", "Tax %"::"35");
                        end;

                        TempPersonIncomeEntry.Reset();
                        TempPersonIncomeEntry.SetRange("Person Income No.", PersonIncomeHeader."No.");
                        TempPersonIncomeEntry.SetRange("Person No.", PersonIncomeHeader."Person No.");

                        XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], IncDedTxt);
                    end;
                }
                dataitem("Person Income Entry"; "Person Income Entry")
                {
                    DataItemTableView = SORTING("Person Income No.", "Person Income Line No.", "Line No.") WHERE("Entry Type" = CONST("Tax Deduction"), Interim = CONST(false), "Tax Deduction Code" = FILTER(<> ''));

                    trigger OnAfterGetRecord()
                    begin
                        PayrollDirectory.Reset();
                        PayrollDirectory.SetRange(Type, PayrollDirectory.Type::Income);
                        PayrollDirectory.SetRange("Tax Deduction Code", "Tax Deduction Code");
                        PayrollDirectory.SetFilter("Starting Date", '..%1', DirectoryStartDate);

                        if not PayrollDirectory.FindLast then
                            AddToFilter(NonLinkedDeductDirectoryFilter, "Tax Deduction Code");
                    end;

                    trigger OnPostDataItem()
                    begin
                        if NonLinkedDeductDirectoryFilter <> '' then
                            XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], TaxDedSSITxt);
                    end;

                    trigger OnPreDataItem()
                    begin
                        NonLinkedDeductDirectoryFilter := '';

                        if PersentTax <> PersentTax::"13" then
                            CurrReport.Break();

                        SetRange("Person Income No.", PersonIncomeHeader."No.");
                        SetRange("Person No.", PersonIncomeHeader."Person No.");
                    end;
                }
                dataitem(PayrollDirectoryStandart; "Payroll Directory")
                {
                    DataItemTableView = SORTING(Type, Code, "Starting Date") WHERE(Type = FILTER("Tax Deduction"));
                    dataitem(PersonIncomeEntry2; "Person Income Entry")
                    {
                        DataItemLink = "Tax Deduction Code" = FIELD(Code);
                        DataItemTableView = SORTING("Person Income No.", "Person Income Line No.", "Line No.") WHERE("Entry Type" = CONST("Tax Deduction"), Interim = CONST(false), "Tax Deduction Code" = FILTER(<> ''));

                        trigger OnAfterGetRecord()
                        begin
                            TaxDeductAmount := TaxDeductAmount + "Tax Deduction Amount";
                        end;

                        trigger OnPostDataItem()
                        begin
                            if TaxDeductAmount <> 0 then begin
                                PersonTaxDeduction.Reset();
                                PersonTaxDeduction.SetRange("Person No.", "Person No.");
                                PersonTaxDeduction.SetRange(Year, PersonIncomeHeader.Year);
                                PersonTaxDeduction.SetRange("Deduction Code", PayrollDirectoryStandart.Code);
                                if PersonTaxDeduction.FindFirst then begin
                                    PersonTaxDeduction.CalcSums("Deduction Amount");
                                    TaxDeductAmount := TaxDeductAmount + PersonTaxDeduction."Deduction Amount";
                                end;

                                XMLExcelReportsMgt.AddSubNode(CurrNode[3], CurrNode[4], PrevDedSSITxt);
                                XMLExcelReportsMgt.AddAttribute(CurrNode[4], DeductCodeTxt, PayrollDirectoryStandart.Code);
                                XMLExcelReportsMgt.AddAttribute(CurrNode[4], DeductAmtTxt, DecimalToText(-TaxDeductAmount));
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Person Income No.", PersonIncomeHeader."No.");

                            TaxDeductAmount := 0;
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if NonLinkedDeductDirectoryFilter = '' then
                            CurrReport.Break();

                        SetFilter("Starting Date", '..%1', DirectoryStartDate);
                        SetFilter(Code, NonLinkedDeductDirectoryFilter);
                    end;
                }
                dataitem(PayrollDirectoryNonStandart; "Payroll Directory")
                {
                    DataItemTableView = SORTING(Type, Code, "Starting Date") WHERE(Type = FILTER("Tax Deduction"), "Tax Deduction Type" = FILTER(<> Standart));
                    dataitem(PropertyDeductEntries; "Person Income Entry")
                    {
                        DataItemLink = "Tax Deduction Code" = FIELD(Code);
                        DataItemTableView = SORTING("Person Income No.", "Person Income Line No.", "Line No.") WHERE("Entry Type" = CONST("Tax Deduction"), Interim = CONST(false), "Tax Deduction Code" = FILTER(<> ''));

                        trigger OnAfterGetRecord()
                        begin
                            TaxDeductAmount := TaxDeductAmount + "Tax Deduction Amount";
                        end;

                        trigger OnPostDataItem()
                        var
                            ExternalDocNoMaxStrLen: Integer;
                            ExtDocIssuedByMaxStrLen: Integer;
                        begin
                            if TaxDeductAmount > 0 then begin
                                PersonTaxDeduction.Reset();
                                PersonTaxDeduction.SetRange("Document No.", PersonIncomeHeader."No.");
                                PersonTaxDeduction.SetRange("Person No.", PersonIncomeHeader."Person No.");
                                PersonTaxDeduction.SetRange("Deduction Code", PayrollDirectoryNonStandart.Code);
                                if PersonTaxDeduction.FindFirst then begin
                                    PersonTaxDeduction.CalcSums("Deduction Amount");
                                    TaxDeductAmount := TaxDeductAmount + PersonTaxDeduction."Deduction Amount";
                                end;
                                if TaxDeductAmount <> 0 then begin
                                    PayrollElement.Reset();
                                    PayrollElement.SetCurrentKey("Directory Code");
                                    PayrollElement.SetRange("Directory Code", PayrollDirectoryNonStandart.Code);
                                    if PayrollElement.FindSet then
                                        repeat
                                            EmplLedgEntry.Reset();
                                            EmplLedgEntry.SetCurrentKey("Employee No.");
                                            EmplLedgEntry.SetRange("Employee No.", Employee."No.");
                                            EmplLedgEntry.SetRange("Element Code", PayrollElement.Code);
                                            EmplLedgEntry.SetRange("Action Starting Date", DirectoryStartDate, DirectoryEndDate);
                                            EmplLedgEntry.SetFilter("External Document No.", '<>%1', '');
                                            EmplLedgEntry.SetFilter("External Document Date", '<>%1', 0D);
                                            EmplLedgEntry.SetFilter("External Document Issued By", '<>%1', '');

                                            if EmplLedgEntry.FindLast then begin
                                                ExternalDocNoMaxStrLen := 20;
                                                if StrLen(EmplLedgEntry."External Document No.") > ExternalDocNoMaxStrLen then
                                                    Error(
                                                      StringExceedsMaxLenErr, EmplLedgEntry.FieldCaption("External Document No."),
                                                      EmplLedgEntry."Entry No.", ExternalDocNoMaxStrLen, Person."No.");

                                                ExtDocIssuedByMaxStrLen := 4;
                                                if StrLen(EmplLedgEntry."External Document Issued By") > ExtDocIssuedByMaxStrLen then
                                                    Error(
                                                      StringExceedsMaxLenErr, EmplLedgEntry.FieldCaption("External Document Issued By"),
                                                      EmplLedgEntry."Entry No.", ExtDocIssuedByMaxStrLen, Person."No.");

                                                XMLExcelReportsMgt.AddSubNode(CurrNode[3], CurrNode[4], NotifPropDedTxt);
                                                XMLExcelReportsMgt.AddAttribute(CurrNode[4], NotifNumberTxt, EmplLedgEntry."External Document No.");
                                                XMLExcelReportsMgt.AddAttribute(CurrNode[4], NotifDateTxt,
                                                  Format(EmplLedgEntry."External Document Date", 0, '<Day,2>.<Month,2>.<Year4>'));
                                                XMLExcelReportsMgt.AddAttribute(CurrNode[4], IFNSNotifTxt, EmplLedgEntry."External Document Issued By")
                                            end;
                                        until PayrollElement.Next = 0;
                                end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Person Income No.", PersonIncomeHeader."No.");
                            TaxDeductAmount := 0;
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        if NonLinkedDeductDirectoryFilter = '' then
                            CurrReport.Break();

                        SetFilter("Starting Date", '..%1', DirectoryStartDate);
                    end;
                }
                dataitem(EarningsFooter; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

                    trigger OnAfterGetRecord()
                    begin
                        XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], SGDNalPerTxt);
                        XMLExcelReportsMgt.AddAttribute(CurrNode[3], IncSumTotTxt, DecimalToText(BaseAmount));
                        XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxBaseTxt, DecimalToText(BaseAmount - TaxAmount));
                        XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxCalcTxt, Round(AccruedAmount, 1));
                        XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxNotHeldTxt, Round(PaidToPersonAmount, 1));
                        XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxPaidTxt, Round(GetTotalPaidToBudgetForTax(PersonIncomeHeader, PersentTax), 1));
                        if PaidToPersonAmount - AccruedAmount > 0 then begin
                            XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxHeldAboveTxt, Round(PaidToPersonAmount - AccruedAmount, 1));
                            XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxHeldTxt, 0);
                        end else begin
                            XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxHeldAboveTxt, 0);
                            XMLExcelReportsMgt.AddAttribute(CurrNode[3], TaxHeldTxt, Round(AccruedAmount - PaidToPersonAmount, 1));
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 4 then
                        CurrReport.Break();

                    case Number of
                        1:
                            PersentTax := PersentTax::"13";
                        2:
                            PersentTax := PersentTax::"30";
                        3:
                            PersentTax := PersentTax::"9";
                        4:
                            PersentTax := PersentTax::"35";
                    end;

                    if not Person."Non-Resident" and (PersentTax = PersentTax::"30") then
                        CurrReport.Skip();

                    BaseAmount := GetTotalTaxableIncomeForTax(PersonIncomeHeader, PersentTax);
                    TaxAmount := GetTotalTaxDeduction(PersonIncomeHeader, PersentTax);
                    AccruedAmount := GetTotalAccruedAmountForTax(PersonIncomeHeader, PersentTax);
                    PaidToPersonAmount := GetTotalPaidToPersonForTax(PersonIncomeHeader, PersentTax);

                    if (BaseAmount = 0) and (TaxAmount = 0) and (AccruedAmount = 0) and (PaidToPersonAmount = 0) then
                        CurrReport.Skip();

                    XMLExcelReportsMgt.AddSubNode(CurrNode[1], CurrNode[2], IncomeTxt);
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], RateTxt, Format(PersentTax));

                    ExportEmpIncRegToExcel.AddEmployee(Employee."No.", DocumentIdentificator);
                end;
            }

            trigger OnAfterGetRecord()
            var
                AddressPresent: Boolean;
                AddressRegPresent: Boolean;
            begin
                DirectoryStartDate := DMY2Date(1, 1, Year);
                DirectoryEndDate := CalcDate('<+CY>', DMY2Date(1, 12, Year));

                Person.Get("Person No.");
                Employee.SetRange("Person No.", Person."No.");
                if not Employee.FindFirst then
                    CurrReport.Break();

                DocumentIdentificator := IncStr(DocumentIdentificator);

                XMLExcelReportsMgt.AddSubNode(RootNode, CurrNode[1], DocumentTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], KNDTxt, '1151078');
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], DateDocTxt, Format(DocumentDate, 0, '<Day,2>.<Month,2>.<Year4>'));
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], ReportYearTxt, Format(Year));
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], NomSprTxt, DocumentIdentificator);
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], PriznakTxt, '1');
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], KodNOTxt, HRSetup."Tax Inspection Code");

                XMLExcelReportsMgt.AddSubNode(CurrNode[1], CurrNode[2], SvNATxt);
                if CompanyInfo."Separated Org. Unit" then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], OKATOTxt, CurrOKATO)
                else
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], OKATOTxt, CompanyInfo."OKATO Code");
                XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], SvNAULTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], OrgNameTxt, LocalReportMgt.GetCompanyName);
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], INNULTxt, CompanyInfo."VAT Registration No.");
                if CompanyInfo."Separated Org. Unit" then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[3], KPPTxt, CurrKPP)
                else
                    XMLExcelReportsMgt.AddAttribute(CurrNode[3], KPPTxt, CompanyInfo."KPP Code");

                XMLExcelReportsMgt.AddSubNode(CurrNode[1], CurrNode[2], ReceiverTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[2], INNFLTxt, Person."VAT Registration No.");
                if Person."Non-Resident" then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], StatusTxt, '2')
                else
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], StatusTxt, '1');
                if Person."Birth Date" <> 0D then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], BirthDateTxt, Format(Person."Birth Date", 0, '<Day,2>.<Month,2>.<Year4>'))
                else
                    Error(
                      FieldShouldNotBeEmptyErr,
                      Person.FieldCaption("Birth Date"), Person.TableCaption,
                      Person.FieldCaption("No."), Person."No.");
                if Person.Citizenship <> '' then begin
                    Country.Get(Person."Citizenship Country/Region");
                    Country.TestField("Local Country/Region Code");
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], CitizTxt, Country."Local Country/Region Code");
                end else
                    Error(
                      FieldShouldNotBeEmptyErr,
                      Person.FieldCaption(Citizenship), Person.TableCaption,
                      Person.FieldCaption("No."), Person."No.");

                XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], FIOTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], LastNameTxt, Person."Last Name");
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], FirstNameTxt, Person."First Name");
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], MiddleNameTxt, Person."Middle Name");
                XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], UdLichFLTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[3], KodUdLichTxt, Person."Identity Document Type");

                Person.GetIdentityDoc(DirectoryEndDate, PersonalDoc);
                if PersonalDoc."Document Type" = '21' then
                    XMLExcelReportsMgt.AddAttribute(
                      CurrNode[3], SerNomDocTxt,
                      CopyStr(PersonalDoc."Document Series", 1, 2) + ' ' + CopyStr(PersonalDoc."Document Series", 2, 2) + ' ' + PersonalDoc.
                      "Document No.")
                else
                    XMLExcelReportsMgt.AddAttribute(
                      CurrNode[3], SerNomDocTxt, PersonalDoc."Document Series" + ' ' + PersonalDoc."Document No.");

                AddressPresent := false;

                AltAddr.Reset();
                AltAddr.SetRange("Person No.", Person."No.");
                AltAddr.SetRange("Address Type", AltAddr."Address Type"::Registration);
                if (not AltAddr.FindLast) and (not Person."Non-Resident") then
                    Error(RegistrationAddressErr);

                AddressPresent := true;
                XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], AdrMZRFTxt);
                if AltAddr."Post Code" <> '' then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[3], PostCodeTxt, AltAddr."Post Code")
                else
                    Error(
                      FieldShouldNotBeEmptyErr,
                      AltAddr.FieldCaption("Post Code"), AltAddr.TableCaption,
                      Person.FieldCaption("No."), Person."No.");

                if AltAddr."KLADR Code" <> '' then begin
                    if AltAddr."Region Code" <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], RegionCodeTxt, CopyStr(AltAddr."Region Code", 1, 2))
                    else
                        Error(
                          FieldShouldNotBeEmptyErr,
                          AltAddr.FieldCaption(Region), AltAddr.TableCaption,
                          Person.FieldCaption("No."), Person."No.");
                    if AltAddr.Area <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], CountyTxt, AltAddr.Area + ' ' + AltAddr."Area Category");
                    if AltAddr.City <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], CityTxt, AltAddr.City + ' ' + AltAddr."City Category");
                    if AltAddr.Locality <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], LocalityTxt, AltAddr.Locality + ' ' + AltAddr."Locality Category");
                    if AltAddr.Street <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], StreetTxt, AltAddr.Street + ' ' + AltAddr."Street Category");
                    if AltAddr.House <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], HouseTxt, AltAddr.House);
                    if AltAddr.Building <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], BlockTxt, AltAddr.Building);
                    if AltAddr.Apartment <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], FlatTxt, AltAddr.Apartment);
                    AddressRegPresent := true;
                end else
                    Error(
                      FieldShouldNotBeEmptyErr,
                      AltAddr.FieldCaption("KLADR Code"), AltAddr.TableCaption,
                      Person.FieldCaption("No."), Person."No.");

                if (Person.Citizenship <> CompanyInfo."Country/Region Code") and (not AddressRegPresent) then begin
                    AltAddr.Reset();
                    AltAddr.SetRange("Person No.", Person."No.");
                    AltAddr.SetRange("Address Type", AltAddr."Address Type"::Permanent);
                    if (not AltAddr.FindLast) and (not AddressPresent) then
                        Error(PermanentAddressErr, Person."No.");

                    XMLExcelReportsMgt.AddSubNode(CurrNode[2], CurrNode[3], AdrINOTxt);
                    if AltAddr."Country/Region Code" <> '' then begin
                        Country.Get(AltAddr."Country/Region Code");
                        Country.TestField("Local Country/Region Code");
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], KodStrTxt, Country."Local Country/Region Code");
                    end else
                        Error(
                          FieldShouldNotBeEmptyErr,
                          AltAddr.FieldCaption("Country/Region Code"), AltAddr.TableCaption,
                          Person.FieldCaption("No."), Person."No.");
                    if AltAddr.Address <> '' then
                        XMLExcelReportsMgt.AddAttribute(
                          CurrNode[3], AdrTextTxt, AltAddr.Address)
                    else
                        Error(
                          FieldShouldNotBeEmptyErr,
                          AltAddr.FieldCaption(Address), AltAddr.TableCaption,
                          Person.FieldCaption("No."), Person."No.");
                end;
            end;

            trigger OnPostDataItem()
            begin
                if ServerFileName = '' then
                    ServerFileName := FileMgt.ServerTempFileName('xml');
                XMLDoc.Save(ServerFileName);
                Clear(XMLDoc);

                if not TestMode then begin
#if not CLEAN17
                    FileMgt.DownloadToFile(ServerFileName, FileName);
#else
                    FileMgt.DownloadHandler(ServerFileName, '', '', '', FileName);
#endif
                    Message(Text006);
                end;

                if CreateRegister then
                    CreateNDFLRegister;
            end;

            trigger OnPreDataItem()
            begin
                if not FindSet then
                    Error(NoDataMsg);

                CompanyInfo.Get();
                HRSetup.Get();

                if CreateRegister then
                    HRSetup.TestField("NDFL Register Template Code");

                XMLDoc := XMLDoc.XmlDocument;
                XMLExcelReportsMgt.CreateXMLDoc(XMLDoc, 'windows-1251', RootNode, FileTxt);
                XMLExcelReportsMgt.AddAttribute(RootNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
                XMLExcelReportsMgt.AddAttribute(RootNode, VersProgTxt, CopyStr(ApplicationSystemConstants.ApplicationVersion, 1, 40));
                XMLExcelReportsMgt.AddAttribute(RootNode, VersFormTxt, '5.02');
                XMLExcelReportsMgt.AddAttribute(RootNode, IDFileTxt, IDFile);

                XMLExcelReportsMgt.AddSubNode(RootNode, CurrNode[1], SvRekvTxt);
                if CompanyInfo."Separated Org. Unit" then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[1], OKATOTxt, CurrOKATO)
                else
                    XMLExcelReportsMgt.AddAttribute(CurrNode[1], OKATOTxt, CompanyInfo."OKATO Code");
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], ReportYearTxt, Format(Year));
                XMLExcelReportsMgt.AddAttribute(CurrNode[1], PriznakFTxt, '1');
                XMLExcelReportsMgt.AddSubNode(CurrNode[1], CurrNode[2], SvULTxt);
                XMLExcelReportsMgt.AddAttribute(CurrNode[2], INNULTxt, CompanyInfo."VAT Registration No.");
                if CompanyInfo."Separated Org. Unit" then
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], KPPTxt, CurrKPP)
                else
                    XMLExcelReportsMgt.AddAttribute(CurrNode[2], KPPTxt, CompanyInfo."KPP Code");

                DocumentIdentificator := '00000000';
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name of the file.';

                        trigger OnAssistEdit()
                        begin
#if not CLEAN17
                            FileName := FileMgt.SaveFileDialog(Text002, '.xml', '');
#else
                            FileName := '';
#endif
                        end;
                    }
                    field(CreateRegister; CreateRegister)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Register';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CompanyInfo.Get();
            HRSetup.Get();
            NoGUID := CreateGuid;
            HRSetup.TestField("Tax Inspection Code");
            CompanyInfo.TestField("VAT Registration No.");
            CompanyInfo.TestField("KPP Code");
            NoGUIDText := CopyStr(Format(NoGUID), 2, StrLen(Format(NoGUID)) - 2);
            IDFile :=
              'NO_NDFL2' + '_' + HRSetup."Tax Inspection Code" + '_' + HRSetup."Tax Inspection Code" + '_' +
              CompanyInfo."VAT Registration No." + CompanyInfo."KPP Code" + '_' +
              Format(Today, 0, '<Year4><Month,2><Day,2>') + '_' + NoGUIDText;
            FileName := IDFile + '.xml';

            DocumentDate := Today;
        end;
    }

    labels
    {
    }

    var
        NoDataMsg: Label 'No person income data available. ';
        Text002: Label 'Export file as';
        RegistrationAddressErr: Label 'Registration address is missing for person %1.', Comment = '%1 = Person No.';
        PermanentAddressErr: Label 'Permanent address is missing for person %1.', Comment = '%1 = Person No.';
        Text006: Label 'XML file created.';
        CompanyInfo: Record "Company Information";
        HRSetup: Record "Human Resources Setup";
        Person: Record Person;
        PayrollDirectory: Record "Payroll Directory";
        EmplLedgEntry: Record "Employee Ledger Entry";
        AltAddr: Record "Alternative Address";
        PersonalDoc: Record "Person Document";
        PersonTaxDeduction: Record "Person Tax Deduction";
        Employee: Record Employee;
        Country: Record "Country/Region";
        PayrollElement: Record "Payroll Element";
        TempPersonIncomeEntry: Record "Person Income Entry" temporary;
        FileMgt: Codeunit "File Management";
        XMLExcelReportsMgt: Codeunit "XML-Excel Reports Mgt.";
        LocalReportMgt: Codeunit "Local Report Management";
        ApplicationSystemConstants: Codeunit "Application System Constants";
        ExportEmpIncRegToExcel: Codeunit "Export Emp. Inc. Reg. to Excel";
        XMLDoc: DotNet XmlDocument;
        CurrNode: array[6] of DotNet XmlNode;
        RootNode: DotNet XmlNode;
        ServerFileName: Text;
        FileName: Text[250];
        IDFile: Text[240];
        DirectoryStartDate: Date;
        DirectoryEndDate: Date;
        PersentTax: Option "13","30","35","9";
        DocumentIdentificator: Text[10];
        NoGUID: Guid;
        NoGUIDText: Text[40];
        NotNumberLine: Code[10];
        NotNumber: Integer;
        CurrOKATO: Code[11];
        CurrKPP: Code[10];
        TaxDeductAmount: Decimal;
        DocumentDate: Date;
        FieldShouldNotBeEmptyErr: Label 'Field %1 in table %2 for %3 %4 should not be empty.', Comment = '%1 = Field Name, %2 = Table Name, %3 = Person, %4 = Person No.';
        NonLinkedDeductDirectoryFilter: Text[1024];
        StringExceedsMaxLenErr: Label '%1 in Employee Ledger Entry No.: %2 exceeds %3 characters in realty deduction entry for person %4.', Comment = '%1 = DOcument No., %2 = Entry No, %3 = Length, %4 = Person No.';
        BaseAmount: Decimal;
        TaxAmount: Decimal;
        AccruedAmount: Decimal;
        PaidToPersonAmount: Decimal;
        CreateRegister: Boolean;
        VersProgTxt: Label 'VersProg', Locked = true;
        VersFormTxt: Label 'VersForm';
        IDFileTxt: Label 'IDFile';
        OKATOTxt: Label 'OKATO', Locked = true;
        SvRekvTxt: Label 'SvRekv';
        ReportYearTxt: Label 'ReportYear';
        FileTxt: Label 'File';
        PriznakTxt: Label 'Priznak';
        PriznakFTxt: Label 'PriznakF';
        INNULTxt: Label 'INNUL', Locked = true;
        INNFLTxt: Label 'INNFL', Locked = true;
        StatusTxt: Label 'Status';
        KPPTxt: Label 'KPP', Locked = true;
        SvULTxt: Label 'SvUL';
        DocumentTxt: Label 'Document';
        KNDTxt: Label 'KND', Locked = true;
        DateDocTxt: Label 'DateDoc';
        NomSprTxt: Label 'NomSpr';
        KodNOTxt: Label 'KodNO';
        SvNATxt: Label 'SvNA';
        SvNAULTxt: Label 'SvNAUL';
        OrgNameTxt: Label 'OrgName';
        ReceiverTxt: Label 'Receiver';
        BirthDateTxt: Label 'BirthDate';
        CitizTxt: Label 'Citiz';
        FIOTxt: Label 'FIO', Locked = true;
        FirstNameTxt: Label 'FirstName';
        MiddleNameTxt: Label 'MiddleName';
        LastNameTxt: Label 'LastName';
        UdLichFLTxt: Label 'UdLichFL';
        KodUdLichTxt: Label 'KodUdLich';
        SerNomDocTxt: Label 'SerNomDoc';
        AdrMZRFTxt: Label 'AdrMZRF';
        PostCodeTxt: Label 'PostCode';
        RegionCodeTxt: Label 'RegionCode';
        CountyTxt: Label 'County';
        CityTxt: Label 'City';
        LocalityTxt: Label 'Locality';
        StreetTxt: Label 'Street';
        HouseTxt: Label 'House';
        BlockTxt: Label 'Block';
        FlatTxt: Label 'Flat';
        AdrINOTxt: Label 'AdrINO';
        KodStrTxt: Label 'KodStr';
        AdrTextTxt: Label 'AdrText';
        IncomeTxt: Label 'Income';
        RateTxt: Label 'Rate';
        IncDedTxt: Label 'IncDed';
        SvSumIncTxt: Label 'SvSumInc';
        MonthTxt: Label 'Month';
        IncomeCodeTxt: Label 'IncomeCode';
        IncomeAmtTxt: Label 'IncomeAmt';
        SvSumDedTxt: Label 'SvSumDed';
        DeductCodeTxt: Label 'DeductCode';
        DeductAmtTxt: Label 'DeductAmt';
        TaxDedSSITxt: Label 'TaxDedSSI';
        PrevDedSSITxt: Label 'PrevDedSSI';
        NotifPropDedTxt: Label 'NotifPropDed';
        NotifNumberTxt: Label 'NotifNumber';
        NotifDateTxt: Label 'NotifDate';
        IFNSNotifTxt: Label 'IFNSNotif';
        SGDNalPerTxt: Label 'SGDNalPer';
        IncSumTotTxt: Label 'IncSumTot';
        TaxBaseTxt: Label 'TaxBase';
        TaxCalcTxt: Label 'TaxCalc';
        TaxNotHeldTxt: Label 'TaxNotHeld';
        TaxPaidTxt: Label 'TaxPaid';
        TaxHeldTxt: Label 'TaxHeld';
        TaxHeldAboveTxt: Label 'TaxHeldAbove';
        TestMode: Boolean;

    local procedure CreateMonthText(MonthNo: Integer) MonthText: Text[30]
    begin
        if MonthNo < 10 then
            MonthText := '0' + Format(MonthNo)
        else
            MonthText := Format(MonthNo);
    end;

    local procedure DecimalToText(TransferNumber: Decimal): Text[30]
    begin
        TransferNumber := Round(TransferNumber, 0.01, '=');
        NotNumberLine := DelChr(Format(TransferNumber, 0, '<Integer><Decimals,3>'), '<=>', '0123456789.,');
        NotNumber := StrPos(Format(TransferNumber), NotNumberLine);
        if (NotNumber <> 0) and (NotNumberLine <> Format(TransferNumber)) then
            exit(DelStr(Format(TransferNumber), NotNumber, StrLen(NotNumberLine)));

        exit(ConvertStr(Format(TransferNumber, 0, '<Integer><Decimals,3>'), ',', '.'));
    end;

    local procedure GetPeriodCode(PeriodCode: Code[10]): Integer
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Get(PeriodCode);
        exit(Date2DMY(PayrollPeriod."Starting Date", 2));
    end;

    local procedure GetTotalTaxableIncomeForTax(PersonIncomeHeader: Record "Person Income Header"; TaxPersent: Option "13","30","35","9") TotalBaseAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Taxable Income");
            SetFilter("Tax Code", '<>%1', '');
            SetRange("Advance Payment", false);
            case TaxPersent of
                TaxPersent::"13":
                    SetRange("Tax %", "Tax %"::"13");
                TaxPersent::"30":
                    SetRange("Tax %", "Tax %"::"30");
                TaxPersent::"9":
                    SetRange("Tax %", "Tax %"::"9");
                TaxPersent::"35":
                    SetRange("Tax %", "Tax %"::"35");
            end;
            if FindSet then
                repeat
                    TotalBaseAmount += Base;
                until Next = 0;
        end;
    end;

    local procedure GetTotalTaxDeduction(PersonIncomeHeader: Record "Person Income Header"; TaxPersent: Option "13","30","35","9") TotalTaxDeductionAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
        PayrollDirectory: Record "Payroll Directory";
        TaxDeductionsFilter: Text[1024];
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Tax Deduction");
            SetFilter("Tax Deduction Code", '<>%1', '');
            if FindSet then
                repeat
                    PayrollDirectory.SetRange("Tax Deduction Code", "Tax Deduction Code");
                    PayrollDirectory.SetRange(Type, PayrollDirectory.Type::Income);
                    PayrollDirectory.SetFilter("Starting Date", '..%1', "Posting Date");
                    if PayrollDirectory.FindLast then
                        case TaxPersent of
                            TaxPersent::"13":
                                if PayrollDirectory."Income Tax Percent" = PayrollDirectory."Income Tax Percent"::"13" then
                                    AddToFilter(TaxDeductionsFilter, "Tax Deduction Code");
                            TaxPersent::"9":
                                if PayrollDirectory."Income Tax Percent" = PayrollDirectory."Income Tax Percent"::"9" then
                                    AddToFilter(TaxDeductionsFilter, "Tax Deduction Code");
                            TaxPersent::"35":
                                if PayrollDirectory."Income Tax Percent" = PayrollDirectory."Income Tax Percent"::"35" then
                                    AddToFilter(TaxDeductionsFilter, "Tax Deduction Code");
                            TaxPersent::"30":
                                if PayrollDirectory."Income Tax Percent" = PayrollDirectory."Income Tax Percent"::"30" then
                                    AddToFilter(TaxDeductionsFilter, "Tax Deduction Code");
                        end
                    else
                        if TaxPersent = TaxPersent::"13" then // not linked added to total in 13% case
                            AddToFilter(TaxDeductionsFilter, "Tax Deduction Code");
                until Next = 0;

            if TaxDeductionsFilter = '' then
                exit(0);

            Reset;
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Tax Deduction");
            SetFilter("Tax Deduction Code", TaxDeductionsFilter);
            if FindSet then
                repeat
                    TotalTaxDeductionAmount += "Tax Deduction Amount";
                until Next = 0;
        end
    end;

    local procedure GetTotalAccruedAmountForTax(PersonIncomeHeader: Record "Person Income Header"; TaxPersent: Option "13","30","35","9") TotalAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Accrued Income Tax");
            SetRange(Interim, false);

            case TaxPersent of
                TaxPersent::"13":
                    SetRange("Tax %", "Tax %"::"13");
                TaxPersent::"30":
                    SetRange("Tax %", "Tax %"::"30");
                TaxPersent::"9":
                    SetRange("Tax %", "Tax %"::"9");
                TaxPersent::"35":
                    SetRange("Tax %", "Tax %"::"35");
            end;
            if FindSet then
                repeat
                    TotalAmount += Amount;
                until Next = 0;
        end;
    end;

    local procedure GetTotalPaidToPersonForTax(PersonIncomeHeader: Record "Person Income Header"; TaxPersent: Option "13","30","35","9") TotalAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Paid Taxable Income");

            case TaxPersent of
                TaxPersent::"13":
                    SetRange("Tax %", "Tax %"::"13");
                TaxPersent::"30":
                    SetRange("Tax %", "Tax %"::"30");
                TaxPersent::"9":
                    SetRange("Tax %", "Tax %"::"9");
                TaxPersent::"35":
                    SetRange("Tax %", "Tax %"::"35");
            end;
            if FindSet then
                repeat
                    TotalAmount += Base;
                until Next = 0;
        end;
    end;

    local procedure GetTotalPaidToBudgetForTax(PersonIncomeHeader: Record "Person Income Header"; TaxPersent: Option "13","30","35","9") TotalAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Paid Income Tax");

            case TaxPersent of
                TaxPersent::"13":
                    SetRange("Tax %", "Tax %"::"13");
                TaxPersent::"30":
                    SetRange("Tax %", "Tax %"::"30");
                TaxPersent::"9":
                    SetRange("Tax %", "Tax %"::"9");
                TaxPersent::"35":
                    SetRange("Tax %", "Tax %"::"35");
            end;
            if FindSet then
                repeat
                    TotalAmount += Amount;
                until Next = 0;
        end;
    end;

    local procedure GetLastPayrollDirDeductCode(PayrollCode: Code[10]; StartDate: Date): Code[10]
    var
        PayrollDirectory: Record "Payroll Directory";
    begin
        PayrollDirectory.SetRange(Type, PayrollDirectory.Type::Income);
        PayrollDirectory.SetRange(Code, PayrollCode);
        PayrollDirectory.SetFilter("Starting Date", '..%1', StartDate);

        if PayrollDirectory.FindLast then
            exit(PayrollDirectory."Tax Deduction Code");
    end;

    local procedure GetTotalDeductAmount(TaxDeductCode: Code[10]; PeriodCode: Code[10]) TotalAmount: Decimal
    var
        PersonIncomeEntry: Record "Person Income Entry";
    begin
        with PersonIncomeEntry do begin
            SetRange("Person Income No.", PersonIncomeHeader."No.");
            SetRange("Entry Type", "Entry Type"::"Tax Deduction");
            SetRange("Tax Deduction Code", TaxDeductCode);
            SetRange("Period Code", PeriodCode);
            if FindSet then
                repeat
                    TotalAmount += "Tax Deduction Amount";
                until Next = 0;
        end;
    end;

    local procedure AddToFilter(var "Filter": Text[1024]; AdditionToFilter: Text[30])
    begin
        if Filter = '' then
            Filter := AdditionToFilter
        else
            Filter += '|' + AdditionToFilter;
    end;

    local procedure CreateNDFLRegister()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();

        if not ExportEmpIncRegToExcel.BufferIsEmpty then begin
            ExportEmpIncRegToExcel.SetParameters(
              FileName,
              CompanyInfo.Name + CompanyInfo."Name 2",
              CompanyInfo."VAT Registration No.",
              CompanyInfo."OKATO Code",
              '',
              Today,
              HumanResourcesSetup."Tax Inspection Code",
              PersonIncomeHeader.Year,
              1);
            ExportEmpIncRegToExcel.ExportRegisterToExcel;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
        TestMode := true;
    end;
}

