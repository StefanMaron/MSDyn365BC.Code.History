report 17360 "Form 2-NDFL"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Form 2-NDFL';
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
                    DataItemTableView = SORTING("Posting Date") WHERE("Entry Type" = CONST("Taxable Income"), "Tax Code" = FILTER(<> ''), "Advance Payment" = CONST(false));

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
                        I: Integer;
                        TaxDeductCode: Code[10];
                        TaxDeductAmount: Decimal;
                        RowNo: Integer;
                    begin
                        LineNo := 0;
                        RowNo := GetCurrentBlockStartPosition + EarningsOffset;

                        TempPersonIncomeEntry.Reset();
                        TempPersonIncomeEntry.SetRange("Person Income No.", PersonIncomeHeader."No.");
                        TempPersonIncomeEntry.SetRange("Person No.", PersonIncomeHeader."Person No.");

                        for I := 1 to (TempPersonIncomeEntry.Count div 2) - 1 do // 2 entries per line, 2 lines already exists, +1 due to
                            ExcelMgt.CopyRow(RowNo);

                        with TempPersonIncomeEntry do begin
                            Reset;
                            if FindSet then
                                repeat
                                    LineNo := LineNo + 1;
                                    if LineNo / 2 - LineNo div 2 <> 0 then begin
                                        ExcelMgt.FillCell('A' + Format(RowNo), CreateMonthText(GetPeriodCode("Period Code")));
                                        ExcelMgt.FillCell('H' + Format(RowNo), "Tax Code");
                                        ExcelMgt.FillCell('P' + Format(RowNo), Format(Base, 0, 1));

                                        TaxDeductCode := GetLastPayrollDirDeductCode("Tax Code", "Posting Date");
                                        if TaxDeductCode <> '' then begin
                                            TaxDeductAmount := GetTotalDeductAmount(TaxDeductCode, "Period Code");
                                            if TaxDeductAmount <> 0 then begin
                                                ExcelMgt.FillCell('AF' + Format(RowNo), TaxDeductCode);
                                                ExcelMgt.FillCell('AN' + Format(RowNo), Format(TaxDeductAmount, 0, 1));
                                            end;
                                        end;
                                    end else begin
                                        ExcelMgt.FillCell('BH' + Format(RowNo), CreateMonthText(GetPeriodCode("Period Code")));
                                        ExcelMgt.FillCell('BO' + Format(RowNo), "Tax Code");
                                        ExcelMgt.FillCell('BW' + Format(RowNo), Format(Base, 0, 1));

                                        TaxDeductCode := GetLastPayrollDirDeductCode("Tax Code", "Posting Date");
                                        if TaxDeductCode <> '' then begin
                                            TaxDeductAmount := GetTotalDeductAmount(TaxDeductCode, "Period Code");
                                            if TaxDeductAmount <> 0 then begin
                                                ExcelMgt.FillCell('CM' + Format(RowNo), TaxDeductCode);
                                                ExcelMgt.FillCell('CU' + Format(RowNo), Format(TaxDeductAmount, 0, 1));
                                            end;
                                        end;

                                        RowNo := RowNo + 1;
                                        if RowNo > GetCurrentBlockStartPosition + EarningsOffset + 1 then
                                            ExpandingOffset += 1;
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

                    trigger OnPreDataItem()
                    begin
                        LineNo := 0;

                        NonLinkedDeductDirectoryFilter := '';

                        if PersentTax <> PersentTax::"13" then
                            CurrReport.Break();

                        SetRange("Person Income No.", PersonIncomeHeader."No.");
                        SetRange("Person No.", PersonIncomeHeader."Person No.");
                    end;
                }
                dataitem(PayrollDirectory2; "Payroll Directory")
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
                                if (LineNo mod 4 = 0) and (LineNo <> 0) then
                                    ExpandingOffset += 1;

                                LineNo := LineNo + 1;

                                PersonTaxDeduction.Reset();
                                PersonTaxDeduction.SetRange("Person No.", "Person No.");
                                PersonTaxDeduction.SetRange(Year, PersonIncomeHeader.Year);
                                PersonTaxDeduction.SetRange("Deduction Code", PayrollDirectory2.Code);
                                if PersonTaxDeduction.FindFirst then begin
                                    PersonTaxDeduction.CalcSums("Deduction Amount");
                                    TaxDeductAmount := TaxDeductAmount + PersonTaxDeduction."Deduction Amount";
                                end;

                                TotalTaxDeductAmount := TotalTaxDeductAmount + TaxDeductAmount;
                                TaxDeductCode := PayrollDirectory2.Code;
                                FillTaxDeductionInfo;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Person Income No.", PersonIncomeHeader."No.");

                            TaxDeductAmount := 0;
                        end;
                    }

                    trigger OnPreDataItem()
                    var
                        I: Integer;
                    begin
                        if NonLinkedDeductDirectoryFilter = '' then
                            CurrReport.Break();

                        SetFilter("Starting Date", '..%1', DirectoryStartDate);
                        SetFilter(Code, NonLinkedDeductDirectoryFilter);

                        for I := 1 to (Count - 1) div 4 do
                            ExcelMgt.CopyRow(GetCurrentBlockStartPosition + DeductsOffset);
                    end;
                }
                dataitem(PayrollDirectory3; "Payroll Directory")
                {
                    DataItemTableView = SORTING(Type, Code, "Starting Date") WHERE(Type = FILTER("Tax Deduction"), "Tax Deduction Type" = FILTER(<> Standart));
                    dataitem(PersonIncomeEntry3; "Person Income Entry")
                    {
                        DataItemLink = "Tax Deduction Code" = FIELD(Code);
                        DataItemTableView = SORTING("Person Income No.", "Person Income Line No.", "Line No.") WHERE("Entry Type" = CONST("Tax Deduction"), Interim = CONST(false), "Tax Deduction Code" = FILTER(<> ''));

                        trigger OnAfterGetRecord()
                        begin
                            TaxDeductAmount := TaxDeductAmount + "Tax Deduction Amount";
                        end;

                        trigger OnPostDataItem()
                        var
                            PayrollElement: Record "Payroll Element";
                            RowNo: Integer;
                        begin
                            if TaxDeductAmount > 0 then begin
                                RowNo := GetCurrentBlockStartPosition + DeductsOffset;

                                PersonTaxDeduction.Reset();
                                PersonTaxDeduction.SetRange("Document No.", PersonIncomeHeader."No.");
                                PersonTaxDeduction.SetRange("Person No.", PersonIncomeHeader."Person No.");
                                PersonTaxDeduction.SetRange("Deduction Code", PayrollDirectory3.Code);
                                if PersonTaxDeduction.FindFirst then begin
                                    PersonTaxDeduction.CalcSums("Deduction Amount");
                                    TaxDeductAmount := TaxDeductAmount + PersonTaxDeduction."Deduction Amount";
                                end;

                                if TaxDeductAmount <> 0 then begin
                                    PayrollElement.Reset();
                                    PayrollElement.SetCurrentKey("Directory Code");
                                    PayrollElement.SetRange("Directory Code", PayrollDirectory3.Code);
                                    if PayrollElement.FindSet then
                                        repeat
                                            EmplLedgEntry.Reset();
                                            EmplLedgEntry.SetRange("Employee No.", Employee."No.");
                                            EmplLedgEntry.SetRange("Element Code", PayrollElement.Code);
                                            EmplLedgEntry.SetRange("Action Starting Date", DirectoryStartDate, DirectoryEndDate);
                                            if EmplLedgEntry.FindLast then begin
                                                if EmplLedgEntry."External Document No." <> '' then
                                                    ExcelMgt.FillCell('BW' + Format(RowNo + 1), EmplLedgEntry."External Document No.");
                                                if EmplLedgEntry."External Document Date" <> 0D then begin
                                                    ExcelMgt.FillCell('AC' + Format(RowNo + 2), Format(EmplLedgEntry."External Document Date", 0, '<Day,2>'));
                                                    ExcelMgt.FillCell('AG' + Format(RowNo + 2), Format(EmplLedgEntry."External Document Date", 0, '<Month,2>'));
                                                    ExcelMgt.FillCell('AK' + Format(RowNo + 2), Format(EmplLedgEntry."External Document Date", 0, '<Year4>'));
                                                end;
                                                if EmplLedgEntry."External Document Issued By" <> '' then
                                                    ExcelMgt.FillCell('CY' + Format(RowNo + 2), EmplLedgEntry."External Document Issued By");
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

                trigger OnAfterGetRecord()
                var
                    BaseAmount: Decimal;
                    TaxAmount: Decimal;
                    AccruedAmount: Decimal;
                    PaidToPersonAmount: Decimal;
                    TransferredAmount: Decimal;
                begin
                    if Number > 4 then
                        CurrReport.Break();

                    PersentTax := Number - 1;

                    BaseAmount := GetTotalTaxableIncomeForTax(PersonIncomeHeader, PersentTax);
                    TaxAmount := GetTotalTaxDeduction(PersonIncomeHeader, PersentTax);
                    AccruedAmount := GetTotalAccruedAmountForTax(PersonIncomeHeader, PersentTax);
                    PaidToPersonAmount := GetTotalPaidToPersonForTax(PersonIncomeHeader, PersentTax);
                    TransferredAmount := GetTotalPaidToBudgetForTax(PersonIncomeHeader, PersentTax);

                    if (BaseAmount = 0) and (TaxAmount = 0) and (AccruedAmount = 0) and (PaidToPersonAmount = 0) and (TransferredAmount = 0)
                    then
                        CurrReport.Skip();

                    if not Person."Non-Resident" and (PersentTax = PersentTax::"30") then
                        CurrReport.Skip();

                    BlockNo += 1;

                    case PersentTax of
                        PersentTax::"13":
                            begin
                                ExcelMgt.FillCell('AG' + Format(GetCurrentBlockStartPosition), Text13Persent);
                                ExcelMgt.FillCell('BT' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset - 1), Text13Persent);
                            end;
                        PersentTax::"30":
                            begin
                                ExcelMgt.FillCell('AG' + Format(GetCurrentBlockStartPosition), Text30Persent);
                                ExcelMgt.FillCell('BT' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset - 1), Text30Persent);
                            end;
                        PersentTax::"9":
                            begin
                                ExcelMgt.FillCell('AG' + Format(GetCurrentBlockStartPosition), Text9Persent);
                                ExcelMgt.FillCell('BT' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset - 1), Text9Persent);
                            end;
                        PersentTax::"35":
                            begin
                                ExcelMgt.FillCell('AG' + Format(GetCurrentBlockStartPosition), Text35Persent);
                                ExcelMgt.FillCell('BT' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset - 1), Text35Persent);
                            end;
                    end;

                    if BaseAmount <> 0 then
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset),
                          Format(BaseAmount, 0, 1));
                    if (BaseAmount - TaxAmount) <> 0 then
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 1),
                          Format(BaseAmount - TaxAmount, 0, 1));
                    if AccruedAmount <> 0 then begin
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 2),
                          Format(AccruedAmount, 0, 1));
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 3),
                          Format(AccruedAmount, 0, 1));
                    end;
                    if TransferredAmount <> 0 then
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 4),
                          Format(Round(TransferredAmount, 1), 0, 1));
                    if PaidToPersonAmount <> 0 then
                        ExcelMgt.FillCell(
                          'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 6),
                          Format(PaidToPersonAmount, 0, 1));

                    if PaidToPersonAmount - AccruedAmount > 0 then begin
                        if AccruedAmount - PaidToPersonAmount <> 0 then
                            ExcelMgt.FillCell(
                              'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 7),
                              Format(Round(AccruedAmount - PaidToPersonAmount, 1), 0, 1));
                    end else begin
                        if PaidToPersonAmount - AccruedAmount <> 0 then
                            ExcelMgt.FillCell(
                              'CM' + Format(GetCurrentBlockStartPosition + TotalsBlockOffset + 9),
                              Format(Round(PaidToPersonAmount - AccruedAmount, 1), 0, 1));
                    end;

                    ExportEmpIncRegToExcel.AddEmployee(Employee."No.", DocumentNo);
                end;

                trigger OnPreDataItem()
                var
                    BaseAmount: Decimal;
                    TaxAmount: Decimal;
                    AccruedAmount: Decimal;
                    PaidToPersonAmount: Decimal;
                    TransferredAmount: Decimal;
                    I: Integer;
                    InitialBlockCovered: Boolean;
                begin
                    InitialBlockCovered := false;
                    for I := 0 to 3 do begin
                        PersentTax := 3 - I;
                        BaseAmount := GetTotalTaxableIncomeForTax(PersonIncomeHeader, PersentTax);
                        TaxAmount := GetTotalTaxDeduction(PersonIncomeHeader, PersentTax);
                        AccruedAmount := GetTotalAccruedAmountForTax(PersonIncomeHeader, PersentTax);
                        PaidToPersonAmount := GetTotalPaidToPersonForTax(PersonIncomeHeader, PersentTax);
                        TransferredAmount := GetTotalPaidToBudgetForTax(PersonIncomeHeader, PersentTax);

                        if not ((BaseAmount = 0) and (TaxAmount = 0) and (AccruedAmount = 0) and (PaidToPersonAmount = 0) and (TransferredAmount = 0))
                        then
                            if InitialBlockCovered then
                                ExcelMgt.CopyRowsTo(22, 41, 42)
                            else
                                InitialBlockCovered := true;
                    end;

                    BlockNo := -1;
                    BlockSize := 20;
                    InitialBlockStart := 22;
                    TotalsBlockOffset := 12;
                    EarningsOffset := 3;
                    DeductsOffset := 8;
                    ExpandingOffset := 0;
                end;
            }

            trigger OnAfterGetRecord()
            var
                Country: Record "Country/Region";
            begin
                ExcelMgt.CopySheet('Sheet1', 'Sheet1', Format(Year) + '_' + "Person No.");
                ExcelMgt.OpenSheet(Format(Year) + '_' + "Person No.");

                InitialSheetBeingCopied := true;

                if PreviewMode then
                    DocumentNo := 'XXXXXXXXXX'
                else
                    DocumentNo := NoSeriesMgt.GetNextNo(HumanResSetup."Personal Information Nos.", WorkDate, true);

                DirectoryStartDate := DMY2Date(1, 1, Year);
                DirectoryEndDate := CalcDate('<+CY>', DMY2Date(1, 12, Year));

                Person.Get("Person No.");
                Employee.SetRange("Person No.", Person."No.");
                if not Employee.FindFirst then
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text026, Person."No."));

                ExcelMgt.FillCell('BE6', CopyStr(Format(Year), 3, 2));
                ExcelMgt.FillCell('BP6', DocumentNo);
                ExcelMgt.FillCell('CB6', Format(DocumentDate, 0, '<Day,2>'));
                ExcelMgt.FillCell('CG6', Format(DocumentDate, 0, '<Month,2>'));
                ExcelMgt.FillCell('CL6', Format(DocumentDate, 0, '<Year4>'));
                ExcelMgt.FillCell('DA6', '1');
                ExcelMgt.FillCell('DE8', HumanResSetup."Tax Inspection Code");

                ExcelMgt.FillCell('BF9', CompanyInfo."VAT Registration No.");

                ExcelMgt.FillCell('A11', CompanyInfo.Name + CompanyInfo."Name 2");
                if CompanyInfo."Separated Org. Unit" then begin
                    ExcelMgt.FillCell('CD9', CurrKPP);
                    ExcelMgt.FillCell('P12', CurrOKATO);
                end else begin
                    ExcelMgt.FillCell('CD9', CompanyInfo."KPP Code");
                    ExcelMgt.FillCell('P12', CompanyInfo."OKATO Code");
                end;

                ExcelMgt.FillCell('CL12', CompanyInfo."Phone No.");

                if Person."VAT Registration No." <> '' then
                    ExcelMgt.FillCell('J15', Person."VAT Registration No.")
                else
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption("VAT Registration No."), Person.TableCaption,
                        Person.FieldCaption("No."), Person."No."));

                ExcelMgt.FillCell('AZ15', Employee.GetFullNameOnDate(DocumentDate));
                if Person."Non-Resident" then
                    ExcelMgt.FillCell('AD16', '2')
                else
                    ExcelMgt.FillCell('AD16', '1');
                if Person."Identity Document Type" <> '' then
                    ExcelMgt.FillCell('AR17', Person."Identity Document Type")
                else
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption("Identity Document Type"), Person.TableCaption,
                        Person.FieldCaption("No."), Person."No."));

                Person.GetIdentityDoc(DirectoryEndDate, PersonalDoc);
                ExcelMgt.FillCell(
                  'CB17', PersonalDoc."Document Series" + ' ' + PersonalDoc."Document No.");

                if Person.Citizenship <> '' then begin
                    if Country.Get(Person."Citizenship Country/Region") then;
                    if Country."Local Country/Region Code" <> '' then
                        ExcelMgt.FillCell('DB16', Country."Local Country/Region Code")
                    else
                        ExcelMgt.ErrorExcelProcessing(
                          StrSubstNo(Text027,
                            Country.FieldCaption("Local Country/Region Code"), Country.TableCaption,
                            Country.FieldCaption(Code), Country.Code));
                end else
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption(Citizenship), Person.TableCaption,
                        Person.FieldCaption("No."), Person."No."));

                if Employee."Birth Date" <> 0D then begin
                    ExcelMgt.FillCell('BD16', Format(Employee."Birth Date", 0, '<Day,2>'));
                    ExcelMgt.FillCell('BI16', Format(Employee."Birth Date", 0, '<Month,2>'));
                    ExcelMgt.FillCell('BN16', Format(Employee."Birth Date", 0, '<Year4>'));
                end else
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption("Birth Date"), Person.TableCaption,
                        Person.FieldCaption("No."), Person."No."));

                AltAddr.Reset();
                AltAddr.SetRange("Person No.", Employee."Person No.");
                AltAddr.SetRange("Address Type", AltAddr."Address Type"::Registration);
                if AltAddr.FindLast then begin
                    if AltAddr."Post Code" <> '' then
                        ExcelMgt.FillCell('BX18', AltAddr."Post Code")
                    else
                        ExcelMgt.ErrorExcelProcessing(
                          StrSubstNo(Text027,
                            AltAddr.FieldCaption("Post Code"), AltAddr.TableCaption,
                            Person.FieldCaption("No."), Person."No."));
                    if AltAddr."KLADR Code" <> '' then begin
                        if AltAddr."Region Code" <> '' then
                            ExcelMgt.FillCell('CT18', AltAddr."Region Code")
                        else
                            ExcelMgt.ErrorExcelProcessing(
                              StrSubstNo(Text027,
                                AltAddr.FieldCaption("Region Code"), AltAddr.TableCaption,
                                Person.FieldCaption("No."), Person."No."));
                        if AltAddr.Area <> '' then
                            ExcelMgt.FillCell('K19', AltAddr.Area + ' ' + AltAddr."Area Category");
                        if AltAddr.City <> '' then
                            ExcelMgt.FillCell('AS19', AltAddr.City + ' ' + AltAddr."City Category");
                        if AltAddr.Locality <> '' then
                            ExcelMgt.FillCell('CK19', AltAddr.Locality + ' ' + AltAddr."Locality Category");
                        if AltAddr.Street <> '' then
                            ExcelMgt.FillCell('K20', AltAddr.Street + ' ' + AltAddr."Street Category");
                        if AltAddr.House <> '' then
                            ExcelMgt.FillCell('BK20', AltAddr.House);
                        if AltAddr.Building <> '' then
                            ExcelMgt.FillCell('CB20', AltAddr.Building);
                        if AltAddr.Apartment <> '' then
                            ExcelMgt.FillCell('CU20', AltAddr.Apartment);
                    end else
                        ExcelMgt.ErrorExcelProcessing(
                          StrSubstNo(Text027,
                            AltAddr.FieldCaption("KLADR Code"), AltAddr.TableCaption,
                            Person.FieldCaption("No."), Person."No."));
                end else
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text016, Employee."No."));
            end;

            trigger OnPostDataItem()
            begin
                if InitialSheetBeingCopied then
                    ExcelMgt.DeleteSheet('Sheet1');
            end;

            trigger OnPreDataItem()
            begin
                InitialSheetBeingCopied := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
                    field(PreviewMode; PreviewMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
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
            DocumentDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."NDFL-2 Template Code"));

        if CreateRegister then
            CreateNDFLRegister;
    end;

    trigger OnPreReport()
    begin
        if DocumentDate = 0D then
            Error(Text000);

        HumanResSetup.Get();
        CompanyInfo.Get();

        if not PreviewMode then
            HumanResSetup.TestField("Personal Information Nos.");

        if CreateRegister then
            HumanResSetup.TestField("NDFL Register Template Code");

        HumanResSetup.TestField("NDFL-2 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."NDFL-2 Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('Sheet1');
    end;

    var
        Text000: Label 'Enter Create Date.';
        Text016: Label 'Registration address is missing for person %1';
        Text026: Label 'There is no Employee No. associated with Person No. %1.';
        Text027: Label 'Field %1 in table %2 for %3 %4 should not be empty.';
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        Person: Record Person;
        Employee: Record Employee;
        AltAddr: Record "Alternative Address";
        PersonalDoc: Record "Person Document";
        ExcelTemplate: Record "Excel Template";
        PersonTaxDeduction: Record "Person Tax Deduction";
        PayrollDirectory: Record "Payroll Directory";
        EmplLedgEntry: Record "Employee Ledger Entry";
        TempPersonIncomeEntry: Record "Person Income Entry" temporary;
        ExcelMgt: Codeunit "Excel Management";
        ExportEmpIncRegToExcel: Codeunit "Export Emp. Inc. Reg. to Excel";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
        DocumentDate: Date;
        CurrOKATO: Code[11];
        CurrKPP: Code[10];
        TaxDeductCode: Code[10];
        LineNo: Integer;
        FileName: Text[1024];
        TaxDeductAmount: Decimal;
        PreviewMode: Boolean;
        TotalTaxDeductAmount: Decimal;
        DirectoryStartDate: Date;
        DirectoryEndDate: Date;
        PersentTax: Option "13","30","35","9";
        Text13Persent: Label '13';
        Text9Persent: Label '9';
        Text35Persent: Label '35';
        Text30Persent: Label '30';
        NonLinkedDeductDirectoryFilter: Text[1024];
        BlockNo: Integer;
        BlockSize: Integer;
        InitialBlockStart: Integer;
        TotalsBlockOffset: Integer;
        EarningsOffset: Integer;
        DeductsOffset: Integer;
        ExpandingOffset: Integer;
        CreateRegister: Boolean;
        InitialSheetBeingCopied: Boolean;
        TestMode: Boolean;

    local procedure CreateMonthText(MonthNo: Integer) MonthText: Text[30]
    begin
        if MonthNo < 10 then
            MonthText := '0' + Format(MonthNo)
        else
            MonthText := Format(MonthNo);
    end;

    local procedure FillTaxDeductionInfo()
    var
        RowNo: Integer;
    begin
        RowNo := GetCurrentBlockStartPosition + DeductsOffset;
        case LineNo mod 4 of
            1:
                begin
                    ExcelMgt.FillCell('A' + Format(RowNo), TaxDeductCode);
                    ExcelMgt.FillCell('L' + Format(RowNo), Format(Abs(TaxDeductAmount), 0, 1));
                end;
            2:
                begin
                    ExcelMgt.FillCell('AD' + Format(RowNo), TaxDeductCode);
                    ExcelMgt.FillCell('AO' + Format(RowNo), Format(Abs(TaxDeductAmount), 0, 1));
                end;
            3:
                begin
                    ExcelMgt.FillCell('BH' + Format(RowNo), TaxDeductCode);
                    ExcelMgt.FillCell('BS' + Format(RowNo), Format(Abs(TaxDeductAmount), 0, 1));
                end;
            0:
                begin
                    ExcelMgt.FillCell('CK' + Format(RowNo), TaxDeductCode);
                    ExcelMgt.FillCell('CV' + Format(RowNo), Format(Abs(TaxDeductAmount), 0, 1));
                end;
        end;
    end;

    local procedure GetPeriodCode(PeriodCode: Code[10]): Integer
    var
        PayrollPeriod: Record "Payroll Period";
    begin
        PayrollPeriod.Get(PeriodCode);
        exit(Date2DMY(PayrollPeriod."Starting Date", 2));
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

    local procedure GetCurrentBlockStartPosition(): Integer
    begin
        exit(InitialBlockStart + BlockSize * BlockNo + ExpandingOffset);
    end;

    local procedure CreateNDFLRegister()
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.Get();

        if not ExportEmpIncRegToExcel.BufferIsEmpty then begin
            ExportEmpIncRegToExcel.SetParameters(
              '',
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
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
        DocumentDate := WorkDate;
    end;
}

