report 17359 "Form 1-NDFL"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Form 1-NDFL';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Person Income Header"; "Person Income Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                InterimAccruals: Decimal;
                TotalAccruals: Decimal;
                TotalPayments: Decimal;
                RowNo: Integer;
            begin
                Person.Get("Person No.");
                Employee.SetRange("Person No.", Person."No.");
                if not Employee.FindFirst then
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text026, Person."No."));

                ExcelMgt.OpenSheet('Sheet1');

                ExcelMgt.FillCell('BL3', DocumentNo);
                ExcelMgt.FillCell('CS6', CompanyInfo."VAT Registration No.");
                if CompanyInfo."Separated Org. Unit" then begin
                    ExcelMgt.FillCell('DT6', CurrKPP);
                    ExcelMgt.FillCell('R10', CurrOKATO);
                end else begin
                    ExcelMgt.FillCell('DT6', CompanyInfo."KPP Code");
                    ExcelMgt.FillCell('R10', CompanyInfo."OKATO Code");
                end;
                ExcelMgt.FillCell('BK7', Person."Tax Inspection Code");
                ExcelMgt.FillCell('BI8', CompanyInfo.Name + CompanyInfo."Name 2");
                ExcelMgt.FillCell('J13', Person."VAT Registration No.");
                ExcelMgt.FillCell('DH13', Person."Social Security No.");
                ExcelMgt.FillCell('AC14', Employee.GetFullNameOnDate(DocumentDate));
                if Person."Identity Document Type" <> '' then begin
                    ExcelMgt.FillCell('BS15', Person."Identity Document Type");
                    Person.GetIdentityDoc(DMY2Date(31, 12, Year), PersonalDoc);
                end else
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption("Identity Document Type"), Person.TableCaption,
                        Person.TableCaption, Person."No."));
                ExcelMgt.FillCell(
                  'DU15', PersonalDoc."Document Series" + ' ' + PersonalDoc."Document No.");
                if Employee."Birth Date" <> 0D then begin
                    ExcelMgt.FillCell('AL16', Format(Employee."Birth Date", 0, '<Day,2>'));
                    ExcelMgt.FillCell('AQ16', Format(Employee."Birth Date", 0, '<Month,2>'));
                    ExcelMgt.FillCell('AV16', Format(Employee."Birth Date", 0, '<Year4>'));
                end else
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text013, Employee."No."));
                if Person.Citizenship = '' then
                    ExcelMgt.ErrorExcelProcessing(
                      StrSubstNo(Text027,
                        Person.FieldCaption(Citizenship), Person.TableCaption,
                        Person.TableCaption, Person."No."));
                ExcelMgt.FillCell('DX16', Person.Citizenship);
                if Person."Non-Resident" then
                    ExcelMgt.FillCell('CC22', '2')
                else
                    ExcelMgt.FillCell('CC22', '1');

                AltAddr.Reset();
                AltAddr.SetRange("Person No.", Employee."Person No.");
                AltAddr.SetRange("Address Type", AltAddr."Address Type"::Registration);
                if AltAddr.FindLast then begin
                    if AltAddr."Post Code" <> '' then
                        ExcelMgt.FillCell('CX17', AltAddr."Post Code")
                    else
                        ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text017, Employee."No."));
                    if AltAddr."KLADR Code" <> '' then begin
                        ExcelMgt.FillCell('BM17', AltAddr."Region Code");
                        if AltAddr."Region Code" <> '' then
                            ExcelMgt.FillCell('ER17', AltAddr."Region Code")
                        else
                            ExcelMgt.ErrorExcelProcessing(
                              StrSubstNo(Text019, Employee."No.", AltAddr."Region Code" + ' ' + AltAddr."Region Category"));
                        if AltAddr.Area <> '' then
                            ExcelMgt.FillCell('H18', AltAddr.Area + ' ' + AltAddr."Area Category");
                        if AltAddr.City <> '' then
                            ExcelMgt.FillCell('CM18', AltAddr.City + ' ' + AltAddr."City Category");
                        if AltAddr.Locality <> '' then
                            ExcelMgt.FillCell('T19', AltAddr.Locality + ' ' + AltAddr."Locality Category");
                        if AltAddr.Street <> '' then
                            ExcelMgt.FillCell('CM19', AltAddr.Street + ' ' + AltAddr."Street Category");
                        if AltAddr.House <> '' then
                            ExcelMgt.FillCell('DX19', AltAddr.House);
                        if AltAddr.Building <> '' then
                            ExcelMgt.FillCell('EN19', AltAddr.Building);
                        if AltAddr.Apartment <> '' then
                            ExcelMgt.FillCell('FE19', AltAddr.Apartment);
                    end else
                        ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text018, Employee."No."));
                end else
                    ExcelMgt.ErrorExcelProcessing(StrSubstNo(Text016, Employee."No."));

                AltAddr.SetRange("Address Type", AltAddr."Address Type"::Other);
                if AltAddr.FindLast then
                    ExcelMgt.FillCell('I21', AltAddr.GetAddress);

                // Chapter 3
                FillChapter3('Sheet2.1', PersonIncomeEntry."Tax %"::"13");
                FillChapter3('Sheet2.2', PersonIncomeEntry."Tax %"::"30");

                // Chapter 4
                RowNo := 0;
                with PersonIncomeEntry do begin
                    Reset;
                    SetRange("Person Income No.", "Person Income Header"."No.");
                    SetRange("Entry Type", "Entry Type"::"Taxable Income");
                    SetFilter("Tax %", '%1|%2', "Tax %"::"13", "Tax %"::"30");
                    SetFilter("Tax Code", '<>%1', '');
                    SetRange("Advance Payment", false);
                    if FindSet then
                        repeat
                            if not FindIncomeCode("Tax Code", RowNo) and (RowNo < 5) then begin
                                I := RowNo + 1;
                                J := ConvertPeriodCode2ColNo("Period Code");
                                Ch4TaxCode[I] := "Tax Code";
                                Ch4IncomeAmount[I] [J] := Base;
                                Ch4IncomeAmount[I] [13] := Ch4IncomeAmount[I] [13] + Base;
                            end else begin
                                I := RowNo;
                                J := ConvertPeriodCode2ColNo("Period Code");
                                Ch4IncomeAmount[I] [J] := Ch4IncomeAmount[I] [J] + Base;
                                Ch4IncomeAmount[I] [13] := Ch4IncomeAmount[I] [13] + Base;
                            end;
                        until Next() = 0;
                end;

                // Calculate accrued income tax
                with TempPersonIncomeEntry do begin
                    Reset;
                    SetRange("Person Income No.", "Person Income Header"."No.");
                    SetRange("Entry Type", "Entry Type"::"Accrued Income Tax");

                    PersonIncomeEntry.Reset();
                    PersonIncomeEntry.SetRange("Person Income No.", "Person Income Header"."No.");
                    PersonIncomeEntry.SetRange("Entry Type", "Entry Type"::"Accrued Income Tax");
                    PersonIncomeEntry.SetFilter("Tax %", '%1|%2', "Tax %"::"13", "Tax %"::"30");
                    PersonIncomeEntry.SetRange(Interim, false);
                    if PersonIncomeEntry.FindSet then
                        repeat
                            SetRange("Period Code", PersonIncomeEntry."Period Code");
                            if FindFirst then begin
                                Amount += PersonIncomeEntry.Amount;
                                Modify;
                            end else begin
                                TempPersonIncomeEntry := PersonIncomeEntry;
                                Insert;
                            end;
                        until PersonIncomeEntry.Next() = 0;

                    Reset;
                    if FindSet then
                        repeat
                            J := ConvertPeriodCode2ColNo("Period Code");
                            Ch4Amounts[6] [J] += Amount;
                        until Next() = 0;
                    DeleteAll();
                end;

                InitColumns(3);
                ExcelMgt.OpenSheet('Sheet3');

                // 8-12
                for I := 1 to 5 do
                    if Ch4TaxCode[I] <> '' then begin
                        ExcelMgt.FillCell('B' + Format(7 + I), Ch4TaxCode[I]);
                        for J := 1 to 13 do
                            if Ch4IncomeAmount[I, J] <> 0 then
                                ExcelMgt.FillCell(Columns[J] + Format(7 + I), Format(Ch4IncomeAmount[I, J], 0, 1));
                    end;

                PersonIncomeEntry.Reset();
                PersonIncomeEntry.SetRange("Person Income No.", "No.");
                PersonIncomeEntry.SetFilter("Tax Deduction Code", '<>%1', '');
                if PersonIncomeEntry.FindSet then
                    repeat
                        // Individual deductions
                        GatherDeductEntries(PayrollDirectory."Tax Deduction Type"::Individual,
                          PersonIncomeEntry, DeductCodes, DeductAmounts, 3);
                        FillDeductEntries(DeductCodes, DeductAmounts, 12, 3);
                        ClearDeductAmounts(DeductAmounts);

                        // Standart deductions
                        GatherDeductEntries(PayrollDirectory."Tax Deduction Type"::Standart,
                          PersonIncomeEntry, DeductCodes, DeductAmounts, 7);
                        FillDeductEntries(DeductCodes, DeductAmounts, 19, 7);
                        IncreaceTotalDeductAmounts(DeductAmounts);
                        ClearDeductAmounts(DeductAmounts);

                        // Social deductions
                        GatherDeductEntries(PayrollDirectory."Tax Deduction Type"::Social,
                          PersonIncomeEntry, DeductCodes, DeductAmounts, 2);
                        FillDeductEntries(DeductCodes, DeductAmounts, 28, 2);
                        ClearDeductAmounts(DeductAmounts);

                        // Material deductions
                        GatherDeductEntries(PayrollDirectory."Tax Deduction Type"::Material,
                          PersonIncomeEntry, DeductCodes, DeductAmounts, 3);
                        FillDeductEntries(DeductCodes, DeductAmounts, 30, 3);
                        ClearDeductAmounts(DeductAmounts);

                        // Professional deductions
                        GatherDeductEntries(PayrollDirectory."Tax Deduction Type"::Professional,
                          PersonIncomeEntry, DeductCodes, DeductAmounts, 3);
                        FillDeductEntries(DeductCodes, DeductAmounts, 33, 3);
                        ClearDeductAmounts(DeductAmounts);
                    until PersonIncomeEntry.Next() = 0;

                CalcCh4Amounts;

                for J := 1 to 13 do begin
                    if Ch4Amounts[1, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(16), Format(Ch4Amounts[1, J], 0, 1));
                    if Ch4Amounts[2, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(18), Format(Ch4Amounts[2, J], 0, 1));
                    if Ch4Amounts[3, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(27), Format(Ch4Amounts[3, J], 0, 1));
                    if Ch4Amounts[4, J] > 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(37), Format(Ch4Amounts[4, J], 0, 1));
                    if Ch4Amounts[5, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(38), Format(Ch4Amounts[5, J], 0, 1));
                    if Ch4Amounts[6, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(39), Format(Ch4Amounts[6, J], 0, 1));
                    if Ch4Amounts[7, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(40), Format(Ch4Amounts[7, J], 0, 1));
                    // IF Ch4Amounts[5,J] > Ch4Amounts[6,J] THEN
                    // ExcelMgt.FillCell(Columns[J] + FORMAT(41),FORMAT(Ch4Amounts[5,J] - Ch4Amounts[6,J],0,1));
                    // IF Ch4Amounts[5,J] < Ch4Amounts[6,J] THEN
                    // ExcelMgt.FillCell(Columns[J] + FORMAT(42),FORMAT(Ch4Amounts[6,J] - Ch4Amounts[5,J],0,1));
                end;

                // chapter 5
                Ch5RowNo := 7;
                ExcelMgt.OpenSheet('Sheet4');

                // Calculate accrued income tax
                with TempPersonIncomeEntry do begin
                    Reset;
                    SetRange("Person Income No.", "Person Income Header"."No.");
                    SetRange("Entry Type", "Entry Type"::"Accrued Income Tax");

                    PersonIncomeEntry.Reset();
                    PersonIncomeEntry.SetRange("Person Income No.", "Person Income Header"."No.");
                    PersonIncomeEntry.SetRange("Entry Type", "Entry Type"::"Accrued Income Tax");
                    if PersonIncomeEntry.FindSet then
                        repeat
                            SetRange("Posting Date", PersonIncomeEntry."Posting Date");
                            if FindFirst then begin
                                Amount += PersonIncomeEntry.Amount;
                                Modify;
                            end else begin
                                TempPersonIncomeEntry := PersonIncomeEntry;
                                Insert;
                            end;
                        until PersonIncomeEntry.Next() = 0;

                    TotalAccruals := 0;
                    Reset;
                    if FindSet then
                        repeat
                            TempPersonIncomeEntryByDate.Init();
                            TempPersonIncomeEntryByDate := TempPersonIncomeEntry;
                            TempPersonIncomeEntryByDate.Insert();
                            if not TempPersonIncomeEntryByDate.Interim then
                                TotalAccruals += TempPersonIncomeEntryByDate.Amount;
                        until Next() = 0;
                    DeleteAll();
                end;

                TempPersonIncomeEntry.DeleteAll();
                with PersonIncomeEntry do begin
                    TotalPayments := 0;
                    Reset;
                    SetRange("Person Income No.", "Person Income Header"."No.");
                    SetRange("Entry Type", "Entry Type"::"Paid Income Tax");
                    if FindSet then
                        repeat
                            TempPersonIncomeEntryByDate.Init();
                            TempPersonIncomeEntryByDate := PersonIncomeEntry;
                            TempPersonIncomeEntryByDate.Insert();
                            TempPersonIncomeEntry.SetRange("Posting Date", TempPersonIncomeEntryByDate."Posting Date");
                            if not TempPersonIncomeEntry.FindFirst then begin
                                TempPersonIncomeEntry := TempPersonIncomeEntryByDate;
                                TempPersonIncomeEntry.Insert();
                                TotalPayments += TempPersonIncomeEntryByDate.Amount;
                            end;
                        until Next() = 0;
                end;

                with TempPersonIncomeEntryByDate do begin
                    TempPersonIncomeEntry.Reset();
                    TempPersonIncomeEntry.SetCurrentKey("Posting Date");
                    Reset;
                    SetCurrentKey("Posting Date");
                    InterimAccruals := 0;
                    if TempPersonIncomeEntry.FindSet then
                        repeat
                            SetRange("Posting Date", TempPersonIncomeEntry."Posting Date");
                            if FindSet then begin
                                ExcelMgt.CopyRow(Ch5RowNo);
                                repeat
                                    PayrollPeriod.Get("Period Code");
                                    case "Entry Type" of
                                        "Entry Type"::"Accrued Income Tax":
                                            begin
                                                if Interim then
                                                    InterimAccruals += Amount
                                                else
                                                    Amount -= InterimAccruals;
                                                ExcelMgt.FillCell('A' + Format(Ch5RowNo), Format("Posting Date"));
                                                ExcelMgt.FillCell('O' + Format(Ch5RowNo), PayrollPeriod.Name);
                                                ExcelMgt.FillCell('AK' + Format(Ch5RowNo), Format("Document Date"));
                                                ExcelMgt.FillCell('AW' + Format(Ch5RowNo), Format(Amount));
                                            end;
                                        "Entry Type"::"Paid Income Tax":
                                            begin
                                                ExcelMgt.FillCell('BG' + Format(Ch5RowNo), Format("Posting Date"));
                                                ExcelMgt.FillCell('CA' + Format(Ch5RowNo), Format(Amount));
                                                if VendLedgEntry.Get("Vendor Ledger Entry No.") then begin
                                                    VendLedgEntry.CalcFields(Amount);
                                                    ExcelMgt.FillCell('BQ' + Format(Ch5RowNo), VendLedgEntry."Document No.");
                                                    BankAccLedgEntry.Reset();
                                                    BankAccLedgEntry.SetCurrentKey("Document No.", "Posting Date");
                                                    BankAccLedgEntry.SetRange("Document No.", VendLedgEntry."Document No.");
                                                    BankAccLedgEntry.SetRange("Posting Date", VendLedgEntry."Posting Date");
                                                    BankAccLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type");
                                                    if BankAccLedgEntry.FindFirst then begin
                                                        CheckLedgEntry.Reset();
                                                        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                                                        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccLedgEntry."Entry No.");
                                                        if CheckLedgEntry.FindFirst then begin
                                                            ExcelMgt.FillCell('CP' + Format(Ch5RowNo), CheckLedgEntry.KBK);
                                                            ExcelMgt.FillCell('DD' + Format(Ch5RowNo), CheckLedgEntry.OKATO);
                                                        end;
                                                    end;
                                                end;
                                            end;
                                    end;
                                until Next() = 0;
                                Ch5RowNo += 1;
                            end;
                        until TempPersonIncomeEntry.Next() = 0;
                    ExcelMgt.FillCell('AW' + Format(Ch5RowNo), Format(TotalAccruals));
                    ExcelMgt.FillCell('CA' + Format(Ch5RowNo), Format(TotalPayments));
                end;

                // chapter 6 and 7
                ExcelMgt.OpenSheet('Sheet5');
                FillChapter6;
                FillChapter7;

                // chapter 8
                FillChapter8;
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
                    field(PreviewMode; PreviewMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
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
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."NDFL-1 Template Code"))
        else
          ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        if DocumentDate = 0D then
            Error(Text000);

        HumanResSetup.Get();
        CompanyInfo.Get();

        HumanResSetup.TestField("NDFL-1 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."NDFL-1 Template Code");

        if PreviewMode then begin
            DocumentNo := 'XXXXXXXXXX';
        end else begin
            HumanResSetup.TestField("Personal Information Nos.");
            DocumentNo := NoSeriesMgt.GetNextNo(HumanResSetup."Personal Information Nos.", WorkDate, true);
        end;

        ExcelMgt.OpenBookForUpdate(FileName);
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        Person: Record Person;
        PersonalDoc: Record "Person Document";
        AltAddr: Record "Alternative Address";
        PersonIncomeEntry: Record "Person Income Entry";
        TempPersonIncomeEntry: Record "Person Income Entry" temporary;
        TempPersonIncomeEntryByDate: Record "Person Income Entry" temporary;
        PayrollPeriod: Record "Payroll Period";
        PayrollDirectory: Record "Payroll Directory";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        ExcelMgt: Codeunit "Excel Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Ch4TaxCode: array[5] of Code[10];
        Columns: array[13] of Code[2];
        Ch4IncomeAmount: array[5, 13] of Decimal;
        FileName: Text[1024];
        I: Integer;
        J: Integer;
        Ch4Amounts: array[7, 13] of Decimal;
        Ch6Amounts: array[6, 13] of Decimal;
        Ch7Amounts: array[7, 13] of Decimal;
        Ch8Amounts: array[5, 7] of Decimal;
        DocumentDate: Date;
        Text000: Label 'Enter Create Date.';
        Text013: Label 'Gender is missing for employee %1.';
        Text016: Label 'Registration address is missing for employee %1.';
        Text017: Label 'Registration post code is missing for employee %1.';
        Text018: Label 'Registration address region is missing for employee %1.';
        Text019: Label 'Registration address region is not found for employee %1.';
        Text026: Label 'There is no Employee No. associated with Person No. %1.';
        DocumentNo: Code[20];
        CurrOKATO: Code[11];
        CurrKPP: Code[10];
        PreviewMode: Boolean;
        Ch5RowNo: Integer;
        TotalDeductAmounts: array[7, 13] of Decimal;
        Text027: Label 'Field %1 in table %2 for %3 %4 should not be empty.';
        DeductCodes: array[7] of Code[10];
        DeductAmounts: array[7, 13] of Decimal;
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure InitColumns(ChapterNo: Integer)
    begin
        Clear(Columns);
        case ChapterNo of
            3, 4, 5:
                begin
                    Columns[1] := 'AK';
                    Columns[2] := 'AU';
                    Columns[3] := 'BE';
                    Columns[4] := 'BO';
                    Columns[5] := 'BY';
                    Columns[6] := 'CI';
                    Columns[7] := 'CS';
                    Columns[8] := 'DC';
                    Columns[9] := 'DM';
                    Columns[10] := 'DW';
                    Columns[11] := 'EG';
                    Columns[12] := 'EQ';
                    Columns[13] := 'FA';
                end;
            6:
                begin
                    Columns[1] := 'S';
                    Columns[2] := 'AK';
                    Columns[3] := 'BC';
                    Columns[4] := 'BU';
                    Columns[5] := 'CM';
                    Columns[6] := 'DU';
                    Columns[7] := 'EQ';
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindIncomeCode(TaxCode: Code[10]; var RowNo: Integer): Boolean
    begin
        RowNo := 0;
        for I := 1 to 5 do begin
            if Ch4TaxCode[I] <> '' then
                RowNo := I;
            if Ch4TaxCode[I] = TaxCode then
                exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FillChapter3(SheetName: Text[30]; TaxPercent: Integer)
    var
        RowNo: Integer;
    begin
        ExcelMgt.OpenSheet(SheetName);
        RowNo := 5;
        PersonIncomeEntry."Tax %" := TaxPercent;
        ExcelMgt.FillCell('AS2', Format(PersonIncomeEntry."Tax %"));

        with TempPersonIncomeEntry do begin
            Reset;
            SetRange("Person Income No.", "Person Income Header"."No.");
            SetRange("Entry Type", "Entry Type"::"Taxable Income");

            PersonIncomeEntry.Reset();
            PersonIncomeEntry.SetRange("Person Income No.", "Person Income Header"."No.");
            PersonIncomeEntry.SetRange("Entry Type", "Entry Type"::"Taxable Income");
            PersonIncomeEntry.SetFilter("Tax Code", '<>%1', '');
            PersonIncomeEntry.SetRange("Tax %", TaxPercent);
            PersonIncomeEntry.SetRange("Advance Payment", false);
            if PersonIncomeEntry.FindSet then
                repeat
                    SetRange("Period Code", PersonIncomeEntry."Period Code");
                    SetRange("Tax Code", PersonIncomeEntry."Tax Code");
                    if FindFirst then begin
                        Base += PersonIncomeEntry.Base;
                        if "Posting Date" < PersonIncomeEntry."Posting Date" then
                            "Posting Date" := PersonIncomeEntry."Posting Date";
                        Modify;
                    end else begin
                        TempPersonIncomeEntry := PersonIncomeEntry;
                        Insert;
                    end;
                until PersonIncomeEntry.Next() = 0;

            Reset;
            if FindSet then
                repeat
                    PayrollPeriod.Get("Period Code");
                    ExcelMgt.CopyRow(RowNo);
                    ExcelMgt.FillCell('C' + Format(RowNo), Format("Posting Date"));
                    ExcelMgt.FillCell('AM' + Format(RowNo), PayrollPeriod.Name);
                    ExcelMgt.FillCell('BG' + Format(RowNo), "Tax Code");
                    ExcelMgt.FillCell('CA' + Format(RowNo), Format(Base));
                    RowNo += 1;
                until Next() = 0;
            DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure FillChapter6()
    begin
        with PersonIncomeEntry do begin
            Reset;
            SetRange("Person Income No.", "Person Income Header"."No.");
            SetRange("Entry Type", "Entry Type"::"Taxable Income");
            SetFilter("Tax Code", '<>%1', '');
            SetRange("Tax %", "Tax %"::"9");
            if FindSet then
                repeat
                    J := ConvertPeriodCode2ColNo("Period Code");
                    Ch6Amounts[1] [J] := Ch6Amounts[1] [J] + Base;
                    Ch6Amounts[2] [J] := Ch6Amounts[2] [J] + Base - "Tax Deduction Amount";
                until Next() = 0;
        end;

        InitColumns(4);
        CalcCh6Amounts;

        for J := 1 to 13 do begin
            if Ch6Amounts[1, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(5), Format(Ch6Amounts[1, J], 0, 1));
            if Ch6Amounts[2, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(9), Format(Ch6Amounts[2, J], 0, 1));
            if Ch6Amounts[3, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(10), Format(Ch6Amounts[3, J], 0, 1));
            if Ch6Amounts[4, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(11), Format(Ch6Amounts[4, J], 0, 1));
            if Ch6Amounts[3, J] > Ch6Amounts[4, J] then
                ExcelMgt.FillCell(Columns[J] + Format(12), Format(Ch6Amounts[3, J] - Ch6Amounts[4, J], 0, 1));
            if Ch6Amounts[3, J] < Ch6Amounts[4, J] then
                ExcelMgt.FillCell(Columns[J] + Format(14), Format(Ch6Amounts[4, J] - Ch6Amounts[3, J], 0, 1));
        end;
    end;

    [Scope('OnPrem')]
    procedure FillChapter7()
    begin
        with PersonIncomeEntry do begin
            Reset;
            SetRange("Person Income No.", "Person Income Header"."No.");
            SetRange("Entry Type", "Entry Type"::"Taxable Income");
            SetFilter("Tax Code", '<>%1', '');
            SetRange("Tax %", "Tax %"::"35");
            if FindSet then
                repeat
                    J := ConvertPeriodCode2ColNo("Period Code");
                    Ch7Amounts[1] [J] := Ch7Amounts[1] [J] + Base;
                    Ch7Amounts[2] [J] := Ch7Amounts[2] [J] + "Tax Deduction Amount";
                    Ch7Amounts[3] [J] := Ch7Amounts[1] [J] + Ch7Amounts[2] [J];
                until Next() = 0;
        end;

        InitColumns(5);
        CalcCh7Amounts;

        for J := 1 to 13 do begin
            if Ch7Amounts[1, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(25), Format(Ch7Amounts[1, J], 0, 1));
            if Ch7Amounts[2, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(27), Format(Ch7Amounts[2, J], 0, 1));
            if Ch7Amounts[3, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(33), Format(Ch7Amounts[3, J], 0, 1));
            if Ch7Amounts[4, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(34), Format(Ch7Amounts[4, J], 0, 1));
            if Ch7Amounts[5, J] <> 0 then
                ExcelMgt.FillCell(Columns[J] + Format(35), Format(Ch7Amounts[5, J], 0, 1));
            if Ch7Amounts[4, J] > Ch7Amounts[5, J] then
                ExcelMgt.FillCell(Columns[J] + Format(36), Format(Ch7Amounts[4, J] - Ch7Amounts[5, J], 0, 1));
            if Ch7Amounts[4, J] < Ch7Amounts[5, J] then
                ExcelMgt.FillCell(Columns[J] + Format(38), Format(Ch7Amounts[5, J] - Ch7Amounts[4, J], 0, 1));
        end;
    end;

    [Scope('OnPrem')]
    procedure FillChapter8()
    begin
        InitColumns(6);
        CalcCh8Amounts;

        ExcelMgt.OpenSheet('Sheet6');

        for I := 1 to 5 do
            for J := 1 to 7 do
                if Ch8Amounts[I] [J] <> 0 then
                    ExcelMgt.FillCell(Columns[J] + Format(4 + I), Format(Ch8Amounts[I, J], 0, 1));
    end;

    [Scope('OnPrem')]
    procedure ConvertPeriodCode2ColNo(PeriodCode: Code[10]): Integer
    begin
        Evaluate(J, CopyStr(PeriodCode, 3, 2));
        exit(J);
    end;

    [Scope('OnPrem')]
    procedure ConvertColNo2PeriodCode(ColNo: Integer; Year: Integer): Code[10]
    var
        PeriodCode: Code[10];
    begin
        PeriodCode := CopyStr(Format(Year), 3, 2);
        if ColNo < 10 then
            PeriodCode := PeriodCode + '0' + Format(ColNo)
        else
            PeriodCode := PeriodCode + Format(ColNo);
        exit(PeriodCode);
    end;

    [Scope('OnPrem')]
    procedure CalcPeriodAmount(EmployeeNo: Code[20]; ElementCode: Code[20]; PeriodCode: Code[10]): Decimal
    begin
        Employee.SetRange("Employee No. Filter", EmployeeNo);
        Employee.SetRange("Element Code Filter", ElementCode);
        Employee.SetRange("Payroll Period Filter", PeriodCode);
        Employee.CalcFields("Payroll Amount");
        exit(Abs(Employee."Payroll Amount"));
    end;

    [Scope('OnPrem')]
    procedure CalcCh4Amounts()
    begin
        for J := 1 to 13 do begin
            for I := 1 to 5 do
                Ch4Amounts[1] [J] := Ch4Amounts[1] [J] + Ch4IncomeAmount[I] [J];
            if J = 1 then
                Ch4Amounts[2] [J] := Ch4Amounts[1] [J]
            else
                if J < 13 then
                    Ch4Amounts[2] [J] := Ch4Amounts[1] [J] + Ch4Amounts[2] [J - 1]
                else
                    Ch4Amounts[2] [13] := Ch4Amounts[2] [12];
        end;

        for J := 1 to 13 do begin
            for I := 1 to 7 do
                Ch4Amounts[3] [J] := Ch4Amounts[3] [J] + TotalDeductAmounts[I] [J];
            if (J > 1) and (J <> 13) then
                Ch4Amounts[3] [J] := Ch4Amounts[3] [J] + Ch4Amounts[3] [J - 1];
        end;

        for J := 1 to 13 do begin
            if J = 1 then
                Ch4Amounts[4] [J] := Ch4Amounts[1] [J] - Ch4Amounts[3] [J]
            else
                if J < 13 then
                    Ch4Amounts[4] [J] := Ch4Amounts[1] [J] - Ch4Amounts[3] [J] + Ch4Amounts[3] [J - 1]
                else
                    Ch4Amounts[4] [J] := Ch4Amounts[1] [J] - Ch4Amounts[3] [J];
            if J = 1 then
                Ch4Amounts[5] [J] := Ch4Amounts[4] [J]
            else
                if J < 13 then
                    Ch4Amounts[5] [J] := Ch4Amounts[4] [J] + Ch4Amounts[5] [J - 1]
                else
                    Ch4Amounts[5] [13] := Ch4Amounts[5] [12];
        end;

        for J := 1 to 13 do begin
            if J < 13 then begin
                Ch4Amounts[6] [J] :=
                  CalcPeriodAmount(
                    Employee."No.", HumanResSetup."Income Tax 13%", ConvertColNo2PeriodCode(J, "Person Income Header".Year));
                Ch4Amounts[6] [13] := Ch4Amounts[6] [13] + Ch4Amounts[6] [J];
            end;
            if J = 1 then
                Ch4Amounts[7] [J] := Ch4Amounts[6] [J]
            else
                if J < 13 then
                    Ch4Amounts[7] [J] := Ch4Amounts[6] [J] + Ch4Amounts[7] [J - 1]
                else
                    Ch4Amounts[7] [13] := Ch4Amounts[7] [12];
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcCh6Amounts()
    begin
        for J := 1 to 12 do begin
            Ch6Amounts[1] [13] := Ch6Amounts[1] [13] + Ch6Amounts[1] [J];
            Ch6Amounts[2] [13] := Ch6Amounts[2] [13] + Ch6Amounts[2] [J];
            Ch6Amounts[3] [J] := Round(Ch6Amounts[2] [J] / 100 * 9);
            Ch6Amounts[3] [13] := Ch6Amounts[3] [13] + Ch6Amounts[3] [J];
            Ch6Amounts[4] [J] :=
              CalcPeriodAmount(
                Employee."No.", HumanResSetup."Income Tax 9%", ConvertColNo2PeriodCode(J, "Person Income Header".Year));
            Ch6Amounts[4] [13] := Ch6Amounts[4] [13] + Ch6Amounts[4] [J];
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcCh7Amounts()
    begin
        for J := 1 to 12 do begin
            Ch7Amounts[1] [13] := Ch7Amounts[1] [13] + Ch7Amounts[1] [J];
            Ch7Amounts[2] [13] := Ch7Amounts[2] [13] + Ch7Amounts[2] [J];
            Ch7Amounts[3] [13] := Ch7Amounts[3] [13] + Ch7Amounts[3] [J];
            Ch7Amounts[4] [J] := Round(Ch7Amounts[3] [J] / 100 * 35);
            Ch7Amounts[4] [13] := Ch7Amounts[4] [13] + Ch7Amounts[4] [J];
            Ch7Amounts[5] [J] :=
              CalcPeriodAmount(
                Employee."No.", HumanResSetup."Income Tax 35%", ConvertColNo2PeriodCode(J, "Person Income Header".Year));
            Ch7Amounts[5] [13] := Ch7Amounts[5] [13] + Ch7Amounts[5] [J];
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcCh8Amounts()
    begin
        Ch8Amounts[1] [1] := Ch6Amounts[3, 13];
        Ch8Amounts[1] [2] := Ch6Amounts[4, 13];
        if Ch6Amounts[3, 13] > Ch6Amounts[4, 13] then
            Ch8Amounts[1] [6] := Ch6Amounts[3, 13] - Ch6Amounts[4, 13];
        if Ch6Amounts[3, 13] < Ch6Amounts[4, 13] then
            Ch8Amounts[1] [7] := Ch6Amounts[4, 13] - Ch6Amounts[3, 13];

        Ch8Amounts[2] [1] := Ch4Amounts[6, 13];
        Ch8Amounts[2] [2] := Ch4Amounts[6, 13];
        if Ch4Amounts[6, 13] > Ch4Amounts[6, 13] then
            Ch8Amounts[2] [6] := Ch4Amounts[6, 13] - Ch4Amounts[6, 13];
        if Ch4Amounts[6, 13] < Ch4Amounts[6, 13] then
            Ch8Amounts[2] [7] := Ch4Amounts[6, 13] - Ch4Amounts[6, 13];

        Ch8Amounts[4] [1] := Ch7Amounts[4, 13];
        Ch8Amounts[4] [2] := Ch7Amounts[5, 13];
        if Ch7Amounts[4, 13] > Ch7Amounts[5, 13] then
            Ch8Amounts[4] [6] := Ch7Amounts[4, 13] - Ch7Amounts[5, 13];
        if Ch7Amounts[4, 13] < Ch7Amounts[5, 13] then
            Ch8Amounts[4] [7] := Ch7Amounts[5, 13] - Ch7Amounts[4, 13];

        for I := 1 to 4 do begin
            Ch8Amounts[5] [1] := Ch8Amounts[5] [1] + Ch8Amounts[I, 1];
            Ch8Amounts[5] [2] := Ch8Amounts[5] [2] + Ch8Amounts[I, 2];
            Ch8Amounts[5] [6] := Ch8Amounts[5] [6] + Ch8Amounts[I, 6];
            Ch8Amounts[5] [7] := Ch8Amounts[5] [7] + Ch8Amounts[I, 7];
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidTaxDeductionCode(TaxDeductionCode: Code[10]; CheckDate: Date; TaxDeductionType: Option): Boolean
    var
        PayrollDirectory: Record "Payroll Directory";
    begin
        PayrollDirectory.SetRange(Type, PayrollDirectory.Type::"Tax Deduction");
        PayrollDirectory.SetRange(Code, TaxDeductionCode);
        PayrollDirectory.SetFilter("Starting Date", '<=%1', CheckDate);
        if not PayrollDirectory.FindLast then
            exit(false);

        exit(PayrollDirectory."Tax Deduction Type" = TaxDeductionType)
    end;

    [Scope('OnPrem')]
    procedure GatherDeductEntries(TaxDeductionType: Option; var PersonIncomeEntry: Record "Person Income Entry"; var DeductCodes: array[7] of Code[10]; var DeductAmounts: array[7, 13] of Decimal; RowsQty: Integer)
    var
        DeductsPersonIncomeEntry: Record "Person Income Entry";
        I: Integer;
        J: Integer;
        K: Integer;
        K1: Integer;
    begin
        DeductsPersonIncomeEntry.SetView(PersonIncomeEntry.GetView);

        I := 1;
        with DeductsPersonIncomeEntry do
            if FindSet then
                repeat
                    if ValidTaxDeductionCode("Tax Deduction Code", "Document Date", TaxDeductionType) then begin
                        J := ConvertPeriodCode2ColNo("Period Code");
                        K := 1;
                        while K < I do begin
                            if DeductCodes[K] = "Tax Deduction Code" then begin
                                K1 := K;
                                K := I;
                            end else
                                K := K + 1;
                        end;
                        if K1 > 0 then begin
                            DeductAmounts[K1] [J] := DeductAmounts[K1] [J] + "Tax Deduction Amount";
                            DeductAmounts[K1] [13] := DeductAmounts[K1] [13] + "Tax Deduction Amount";
                        end else begin
                            DeductCodes[I] := "Tax Deduction Code";
                            DeductAmounts[I] [J] := DeductAmounts[I] [J] + "Tax Deduction Amount";
                            DeductAmounts[I] [13] := DeductAmounts[I] [13] + "Tax Deduction Amount";
                            I += 1;
                        end;
                    end;
                until (Next() = 0) or (I > RowsQty);
    end;

    [Scope('OnPrem')]
    procedure FillDeductEntries(DeductCodes: array[7] of Code[10]; DeductAmounts: array[7, 13] of Decimal; StartingRow: Decimal; RowsQty: Integer)
    var
        I: Integer;
        J: Integer;
    begin
        for I := 1 to RowsQty do
            if DeductCodes[I] <> '' then begin
                ExcelMgt.FillCell('U' + Format(StartingRow + I), DeductCodes[I]);
                for J := 1 to 13 do
                    if DeductAmounts[I, J] <> 0 then
                        ExcelMgt.FillCell(Columns[J] + Format(StartingRow + I), Format(DeductAmounts[I, J], 0, 1));
            end;
    end;

    [Scope('OnPrem')]
    procedure IncreaceTotalDeductAmounts(DeductAmounts: array[7, 13] of Decimal)
    begin
        for I := 1 to 7 do
            for J := 1 to 13 do
                TotalDeductAmounts[I, J] += DeductAmounts[I, J];
    end;

    [Scope('OnPrem')]
    procedure ClearDeductAmounts(var DeductAmounts: array[7, 13] of Decimal)
    begin
        for I := 1 to 7 do
            for J := 1 to 13 do
                DeductAmounts[I, J] := 0;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
        DocumentDate := WorkDate;
    end;
}

