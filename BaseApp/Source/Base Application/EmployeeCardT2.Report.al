report 17353 "Employee Card T-2"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Card T-2';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                ClassificatorOKIN: Record "Classificator OKIN";
                AlternativeAddress: Record "Alternative Address";
                Country: Record "Country/Region";
                ShiftInRows: Integer;
            begin
                Person.Get("Person No.");
                Position.Get("Position No.");
                ExcelMgt.SetActiveWriterSheet('Sheet1');

                ExcelMgt.FillCell('A7', Format(CompanyInfo.Name));
                ExcelMgt.FillCell('AV7', Format(CompanyInfo."OKPO Code"));

                ExcelMgt.FillCell('A16', Format(CompositionDate));
                ExcelMgt.FillCell('H16', "No.");
                ExcelMgt.FillCell('L16', Person."VAT Registration No.");
                ExcelMgt.FillCell('V16', "Social Security No.");
                ExcelMgt.FillCell('AG16', CopyStr(Employee."Last Name", 1, 1));
                ExcelMgt.FillCell('BH16', Format(Gender));

                ExcelMgt.FillCell('H26', "Last Name");
                ExcelMgt.FillCell('AB26', "First Name");
                ExcelMgt.FillCell('AW26', "Middle Name");

                ExcelMgt.FillCell('K29', Format("Birth Date"));

                AlternativeAddress.SetRange("Person No.", "Person No.");
                AlternativeAddress.SetRange("Address Type", AlternativeAddress."Address Type"::Birthplace);
                if AlternativeAddress.FindFirst then begin
                    ExcelMgt.FillCell('L31', AlternativeAddress.City + ', ' + AlternativeAddress.Address);
                    ExcelMgt.FillCell('BG30', AlternativeAddress.OKATO);
                end;

                if Country.Get(Person."Citizenship Country/Region") then
                    ExcelMgt.FillCell('J32', Country.Name);
                ExcelMgt.FillCell('BG32', Person.Citizenship);

                FillLastJobInfo("No.");
                PrintLangInfo("Person No.");
                FillLastEducation("Person No.");
                FillEducationInfo("Person No.");
                FillEmployeePositionInfo("Position No.");
                ExcelMgt.WriteAllToCurrentSheet;

                // Sheet2
                ExcelMgt.SetActiveWriterSheet('Sheet2');

                FillServicePeriodInfo("Person No.");
                if Person."Family Status" <> '' then
                    if ClassificatorOKIN.Get('10', Person."Family Status") then begin
                        ExcelMgt.FillCell('M10', ClassificatorOKIN.Name);
                        ExcelMgt.FillCell('BC10', ClassificatorOKIN.Code);
                    end;

                FillFamilyInfo("Person No.");

                Person.GetIdentityDoc(CompositionDate, PersonalDoc);
                ExcelMgt.FillCell('H24', PersonalDoc."Document Series");
                ExcelMgt.FillCell('N24', PersonalDoc."Document No.");
                ExcelMgt.FillCell('AK24', LocMgt.Date2Text(PersonalDoc."Issue Date"));
                ExcelMgt.FillCell('H25', PersonalDoc."Issue Authority");

                FillAdressInfo(31, AlternativeAddress."Address Type"::Registration, "Person No.");
                FillAdressInfo(35, AlternativeAddress."Address Type"::Permanent, "Person No.");

                ExcelMgt.FillCell('K39', "Phone No.");

                FillMilitaryInfo("Person No.");

                ExcelMgt.FillCell('B59', LocMgt.Date2Text(CompositionDate));
                ExcelMgt.WriteAllToCurrentSheet;

                // Sheet3
                ExcelMgt.SetActiveWriterSheet('Sheet3');

                FillJobHistoryInfo("No.");
                FillAttestationInfo("Person No.");
                ExcelMgt.WriteAllToCurrentSheet;

                // Sheet4
                ExcelMgt.SetActiveWriterSheet('Sheet4');
                ShiftInRows := FillVacationInfo("No.");
                FillDismissalInfo("No.", 49 + ShiftInRows);
                ExcelMgt.WriteAllToCurrentSheet;
            end;

            trigger OnPreDataItem()
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
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
                    field(CompositionDate; CompositionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Creation Date';
                        ToolTip = 'Specifies when the report data was created.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CompositionDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-2 Template Code"));
    end;

    trigger OnPreReport()
    begin
        if CompositionDate = 0D then
            Error(Text14808);

        HumResSetup.Get;
        HumResSetup.TestField("T-2 Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-2 Template Code");

        CompanyInfo.Get;
    end;

    var
        Person: Record Person;
        Position: Record Position;
        CompanyInfo: Record "Company Information";
        PersonalDoc: Record "Person Document";
        Text14808: Label 'You should enter Composition Date.';
        HumResSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        RecordMgt: Codeunit "Record of Service Management";
        FileName: Text[1024];
        CompositionDate: Date;
        Text17300: Label 'Order No. %1 according to %2 from %3';
        Text17301: Label 'Order No. %1 from %2';
        PostHighSchoolEducation: Label '19';
        PostHighSchoolEducationGroup: Label '34';

    [Scope('OnPrem')]
    procedure PrintLangInfo(PersonNo: Code[20])
    var
        EmployeeQualification: Record "Employee Qualification";
        Language: Codeunit Language;
        OKINCodes: Record "Classificator OKIN";
        RowNo: Integer;
        LanguageName: Text;
    begin
        with EmployeeQualification do begin
            RowNo := 0;

            Reset;
            SetRange("Person No.", PersonNo);
            SetRange("Qualification Type", "Qualification Type"::Language);

            if FindSet then
                repeat
                    LanguageName := Language.GetWindowsLanguageName("Language Code");
                    
                    if LanguageName <> '' then begin
                        ExcelMgt.FillCell('R' + Format(33 + 2 * RowNo), Format(LanguageName));
                        if OKINCodes.Get('05', "Language Proficiency") then begin
                            ExcelMgt.FillCell('AJ' + Format(33 + 2 * RowNo), Format(OKINCodes.Name));
                            ExcelMgt.FillCell('BG' + Format(33 + 2 * RowNo), Format("Language Proficiency"));
                        end;
                    end;

                    RowNo += 1;
                until (Next = 0) or (RowNo > 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure FillLastJobInfo(EmployeeNo: Code[30])
    var
        EmplJobEntry: Record "Employee Job Entry";
    begin
        EmplJobEntry.Reset;
        EmplJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmplJobEntry.SetRange("Employee No.", EmployeeNo);
        EmplJobEntry.FindLast;

        ExcelMgt.FillCell('AK16', Format(EmplJobEntry."Kind of Work"));
        ExcelMgt.FillCell('AU16', Format(EmplJobEntry."Work Mode"));

        ExcelMgt.FillCell('AY23', EmplJobEntry."Contract No.");
        ExcelMgt.FillCell('AY24', Format(EmplJobEntry."Document Date"));
    end;

    [Scope('OnPrem')]
    procedure FillLastEducation(PersonNo: Code[30])
    var
        EmployeeQualification: Record "Employee Qualification";
        MaxQualification: Record "Employee Qualification";
        OKINCodes: Record "Classificator OKIN";
    begin
        with EmployeeQualification do begin
            Reset;
            SetRange("Person No.", PersonNo);
            SetRange("Qualification Type", "Qualification Type"::Education);
            SetFilter("Type of Education", '<>%1&<>%2', '', PostHighSchoolEducation);

            if FindSet then
                repeat
                    if MaxQualification."Type of Education" < "Type of Education" then
                        MaxQualification := EmployeeQualification;
                until Next = 0;

            if Get(PersonNo, MaxQualification."Qualification Type",
                 MaxQualification."From Date", MaxQualification."Line No.")
            then
                if OKINCodes.Get('30', MaxQualification."Type of Education") then begin
                    ExcelMgt.FillCell('J37', OKINCodes.Name);
                    ExcelMgt.FillCell('BG36', "Type of Education");
                end;
        end
    end;

    [Scope('OnPrem')]
    procedure FillEducationInfo(PersonNo: Code[30])
    var
        EmployeeQualification: Record "Employee Qualification";
        RowNo: Integer;
        I: Integer;
    begin
        with EmployeeQualification do begin
            RowNo := 1;
            I := 1;

            Reset;
            SetRange("Person No.", PersonNo);
            SetRange("Qualification Type", "Qualification Type"::Education);
            SetFilter("Type of Education", '<>%1&<>%2', '', PostHighSchoolEducation);
            if Find('+') then
                repeat
                    FillEducationCells(RowNo, EmployeeQualification);
                    RowNo += 1;
                until (Next(-1) = 0) or (RowNo > 2);

            RowNo := 3;
            Reset;
            SetRange("Person No.", PersonNo);
            SetRange("Qualification Type", "Qualification Type"::Education);
            SetFilter("Type of Education", PostHighSchoolEducation);
            if Find('+') then
                FillEducationCells(RowNo, EmployeeQualification);
        end
    end;

    [Scope('OnPrem')]
    procedure FillEducationCells(RowNo: Integer; var EmployeeQualification: Record "Employee Qualification")
    var
        ClassificatorOKIN: Record "Classificator OKIN";
    begin
        with EmployeeQualification do begin
            ExcelMgt.FillCell('EducationInstitutionName' + Format(RowNo), "Institution/Company");

            if "To Date" <> 0D then begin
                ExcelMgt.FillCell('EducationYear' + Format(RowNo), Format(Date2DMY("To Date", 3)));
                ExcelMgt.FillCell('EducationDocName' + Format(RowNo), Format("Document Type"));
                ExcelMgt.FillCell('EducationQualification' + Format(RowNo), Description);
                ExcelMgt.FillCell('EducationKind' + Format(RowNo), Speciality);
                ExcelMgt.FillCell('EducationDocNo' + Format(RowNo), "Document No.");
                ExcelMgt.FillCell('OKSOCode' + Format(RowNo), "Science Degree");

                if "Type of Education" = PostHighSchoolEducation then begin
                    ExcelMgt.FillCell('BG55', "Type of Education");
                    if ClassificatorOKIN.Get(PostHighSchoolEducationGroup, "Kind of Education") then
                        ExcelMgt.FillCell('AB55', ClassificatorOKIN.Name);
                end;

                if RowNo <> 3 then
                    ExcelMgt.FillCell('EducationSeries' + Format(RowNo), "Document Series");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillEmployeePositionInfo(PositionNo: Code[20])
    var
        EmployeePosition: Record Position;
        JobTitle: Record "Job Title";
    begin
        if EmployeePosition.Get(PositionNo) then begin
            ExcelMgt.FillCell('I66', EmployeePosition."Job Title Name");

            if JobTitle.Get(EmployeePosition."Job Title Code") then
                ExcelMgt.FillCell('BG66', JobTitle."Code OKPDTR");
        end
    end;

    [Scope('OnPrem')]
    procedure FillServicePeriodInfo(PersonNo: Code[30])
    var
        ServicePeriod: array[3] of Integer;
    begin
        ExcelMgt.FillCell('U3', LocMgt.Date2Text(CompositionDate) + ' )');

        RecordMgt.CalcPersonTotalService(PersonNo, true, ServicePeriod);
        if ServicePeriodIsEmpty(ServicePeriod) then
            FillServPeriodFromPersonCard(PersonNo, ServicePeriod, true);
        FillServiceCells(ServicePeriod, 5);

        RecordMgt.CalcPersonTotalService(PersonNo, false, ServicePeriod);
        if ServicePeriodIsEmpty(ServicePeriod) then
            FillServPeriodFromPersonCard(PersonNo, ServicePeriod, false);

        FillServiceCells(ServicePeriod, 6);
    end;

    [Scope('OnPrem')]
    procedure FillServiceCells(ServicePeriod: array[3] of Integer; RowNo: Integer)
    begin
        ExcelMgt.FillCell('AC' + Format(RowNo), Format(ServicePeriod[1]));
        ExcelMgt.FillCell('AO' + Format(RowNo), Format(ServicePeriod[2]));
        ExcelMgt.FillCell('BB' + Format(RowNo), Format(ServicePeriod[3]));
    end;

    [Scope('OnPrem')]
    procedure FillFamilyInfo(PersonNo: Code[30])
    var
        EmployeeRelative: Record "Employee Relative";
        Person2: Record Person;
        RowNo: Integer;
    begin
        with EmployeeRelative do begin
            Reset;
            SetRange("Person No.", PersonNo);
            if FindSet then begin
                RowNo := 17;
                repeat
                    ExcelMgt.FillCell('A' + Format(RowNo), "Relative Code");

                    if Person2.Get("Relative Person No.") then
                        ExcelMgt.FillCell('Q' + Format(RowNo), Person2.GetFullName)
                    else
                        ExcelMgt.FillCell('Q' + Format(RowNo), "Last Name" + ' ' + "First Name" + ' ' + "Middle Name");

                    if "Birth Date" <> 0D then
                        ExcelMgt.FillCell('AY' + Format(RowNo), Format(Date2DMY("Birth Date", 3)));

                    RowNo += 1;
                until (RowNo > 22) or (Next = 0);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillMilitaryInfo(PersonNo: Code[20])
    var
        Person: Record Person;
        MilitaryRank: Record "Classificator OKIN";
    begin
        if Person.Get(PersonNo) then
            with Person do begin
                if "Military Status" = "Military Status"::"Not Liable" then
                    exit;

                ExcelMgt.FillCell('M45', Format("Military Retirement Category"));

                MilitaryRank.SetRange(Group, '17');
                MilitaryRank.SetRange(Code, "Military Rank");
                if MilitaryRank.FindFirst then
                    ExcelMgt.FillCell('M46', MilitaryRank.Name);

                ExcelMgt.FillCell('M47', Format("Military Structure"));
                ExcelMgt.FillCell('X48', Format("Military Speciality No."));
                ExcelMgt.FillCell('AH46', Format("Military Registration Office"));
                ExcelMgt.FillCell('AI50', Format("Military Registration No."));
            end
    end;

    [Scope('OnPrem')]
    procedure FillJobHistoryInfo(EmployeeNo: Code[30])
    var
        EmplJobEntry: Record "Employee Job Entry";
        RowNo: Integer;
    begin
        with EmplJobEntry do begin
            Reset;
            SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
            SetRange("Employee No.", EmployeeNo);
            SetFilter(Type, '<>%1', Type::Termination);
            SetRange("Position Changed", true);

            if FindSet then begin
                if Count > 13 then
                    Next(Count - 13);

                RowNo := 11;
                repeat
                    FillJobHistoryCells(RowNo, EmplJobEntry);
                    RowNo += 1;
                until (Next = 0)
            end
        end
    end;

    [Scope('OnPrem')]
    procedure FillJobHistoryCells(RowNo: Integer; var EmployeeJobEntry: Record "Employee Job Entry")
    var
        OrganizationalUnit: Record "Organizational Unit";
        JobTitle: Record "Job Title";
        Employee: Record Employee;
        Position: Record Position;
    begin
        with EmployeeJobEntry do begin
            ExcelMgt.FillCell('A' + Format(RowNo), Format("Starting Date"));

            if OrganizationalUnit.Get("Org. Unit Code") then
                ExcelMgt.FillCell('H' + Format(RowNo), OrganizationalUnit.Name);

            if JobTitle.Get("Job Title Code") then
                ExcelMgt.FillCell('V' + Format(RowNo), JobTitle.Name);

            if Position.Get("Position No.") then
                if JobTitle.Get("Job Title Code") then
                    ExcelMgt.FillCell('AJ' + Format(RowNo), Format(Position."Monthly Salary Amount"));

            Employee.Get("Employee No.");
            if "Supplement No." <> '' then
                ExcelMgt.FillCell('AS' + Format(RowNo), StrSubstNo(Text17300, "Document No.", "Supplement No.", "Document Date"))
            else
                ExcelMgt.FillCell('AS' + Format(RowNo), StrSubstNo(Text17301, "Document No.", "Document Date"));
        end
    end;

    [Scope('OnPrem')]
    procedure FillAttestationInfo(PersonNo: Code[30])
    var
        EmployeeQualification: Record "Employee Qualification";
        RowNo: Integer;
    begin
        with EmployeeQualification do begin
            Reset;
            SetRange("Person No.", PersonNo);
            SetRange("Qualification Type", "Qualification Type"::Attestation);
            if FindSet then begin
                if Count > 2 then
                    Next(Count - 2);
                RowNo := 30;
                repeat
                    ExcelMgt.FillCell('A' + Format(RowNo), Format("Document Date"));
                    ExcelMgt.FillCell('H' + Format(RowNo), Description);
                    ExcelMgt.FillCell('AJ' + Format(RowNo), "Document No.");
                    ExcelMgt.FillCell('AQ' + Format(RowNo), Format("Document Date"));

                    RowNo += 1;
                until Next = 0;
            end;
        end
    end;

    [Scope('OnPrem')]
    procedure FillVacationInfo(EmployeeNo: Code[30]) ShiftInRows: Integer
    var
        EmplAbsenceEntry: Record "Employee Absence Entry";
        ClassificatorOKIN: Record "Classificator OKIN";
        AccrualPeriod: Record "Employee Absence Entry";
        RowNo: Integer;
        I: Integer;
    begin
        with EmplAbsenceEntry do begin
            Reset;
            SetRange("Employee No.", EmployeeNo);
            SetRange("Entry Type", "Entry Type"::Usage);
            SetFilter("Vacation Type", '<>%1', 0);
            if FindSet then begin
                RowNo := 18;
                if Count > 9 then begin
                    for I := 1 to Count - 9 do
                        ExcelMgt.CopyRow(RowNo);
                    ShiftInRows := Count - 9;
                end;
                repeat
                    ExcelMgt.FillCell('A' + Format(RowNo), Format("Vacation Type"));

                    if AccrualPeriod.Get("Accrual Entry No.") then begin
                        ExcelMgt.FillCell('Q' + Format(RowNo), Format(AccrualPeriod."Start Date"));
                        ExcelMgt.FillCell('X' + Format(RowNo), Format(AccrualPeriod."End Date"));
                    end;

                    ExcelMgt.FillCell('AE' + Format(RowNo), Format("Calendar Days"));
                    ExcelMgt.FillCell('AM' + Format(RowNo), Format("Start Date"));
                    ExcelMgt.FillCell('AT' + Format(RowNo), Format("End Date"));

                    if ClassificatorOKIN.Get("Time Activity Code") then
                        ExcelMgt.FillCell('BA' + Format(RowNo), ClassificatorOKIN.Name);

                    RowNo += 1;
                until Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDismissalInfo(EmployeeNo: Code[30]; RowNo: Integer)
    var
        LaborContractLines: Record "Labor Contract Line";
        EmployeeJobEntry: Record "Employee Job Entry";
        Employee: Record Employee;
        GroundsForTermination: Record "Grounds for Termination";
    begin
        EmployeeJobEntry.Reset;
        EmployeeJobEntry.SetCurrentKey("Employee No.", "Starting Date", "Ending Date");
        EmployeeJobEntry.SetRange("Employee No.", EmployeeNo);
        if EmployeeJobEntry.FindLast then begin
            LaborContractLines.SetRange("Contract No.", EmployeeJobEntry."Contract No.");
            LaborContractLines.SetRange("Operation Type", LaborContractLines."Operation Type"::Dismissal);
            if LaborContractLines.FindLast then begin
                if Employee.Get(EmployeeNo) then begin
                    if GroundsForTermination.Get(Employee."Grounds for Term. Code") then
                        ExcelMgt.FillCell(
                          'AE' + Format(RowNo), GroundsForTermination."Dismissal Article" + '. ' + GroundsForTermination.Description);
                end else
                    ExcelMgt.FillCell('AE' + Format(RowNo), Format(LaborContractLines."Dismissal Reason"));
                ExcelMgt.FillCell('L' + Format(RowNo + 3), Format(LaborContractLines."Starting Date"));
                ExcelMgt.FillCell('P' + Format(RowNo + 5), LaborContractLines."Order No.");
                ExcelMgt.FillCell('AD' + Format(RowNo + 5), Format(LaborContractLines."Order Date"));
            end
        end
    end;

    [Scope('OnPrem')]
    procedure FillAdressInfo(RowNo: Integer; Type: Integer; PersonNo: Code[20])
    var
        AlternativeAddress: Record "Alternative Address";
    begin
        AlternativeAddress.SetRange("Person No.", PersonNo);
        AlternativeAddress.SetRange("Address Type", Type);
        if AlternativeAddress.FindLast then begin
            ExcelMgt.FillCell('I' + Format(RowNo), AlternativeAddress."Post Code");
            if AlternativeAddress.City <> '' then
                ExcelMgt.FillCell(
                  'T' + Format(RowNo),
                  AlternativeAddress."City Category" + '. ' + AlternativeAddress.City + ', ' + AlternativeAddress.Address)
            else
                if AlternativeAddress.Region <> '' then
                    ExcelMgt.FillCell(
                      'T' + Format(RowNo),
                      AlternativeAddress."Region Category" + '. ' + AlternativeAddress.Region + ', ' + AlternativeAddress.Address);

            if AlternativeAddress."Address Type" = AlternativeAddress."Address Type"::Registration then begin
                ExcelMgt.FillCell('X38', Format(Date2DMY(AlternativeAddress."Valid from Date", 1)));
                ExcelMgt.FillCell('AB38', LocMgt.GetMonthName(AlternativeAddress."Valid from Date", true));
                ExcelMgt.FillCell('AP38', Format(Date2DMY(AlternativeAddress."Valid from Date", 3)));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ServicePeriodIsEmpty(ServicePeriod: array[3] of Integer): Boolean
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            if ServicePeriod[I] <> 0 then
                exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FillServPeriodFromPersonCard(PersonNo: Code[30]; var ServicePeriod: array[3] of Integer; Total: Boolean)
    var
        Person: Record Person;
    begin
        if not Person.Get(PersonNo) then
            exit;

        if Total then begin
            ServicePeriod[1] := Person."Total Service (Years)";
            ServicePeriod[2] := Person."Total Service (Months)";
            ServicePeriod[3] := Person."Total Service (Days)";
        end else begin
            ServicePeriod[1] := Person."Unbroken Service (Years)";
            ServicePeriod[2] := Person."Unbroken Service (Months)";
            ServicePeriod[3] := Person."Unbroken Service (Days)";
        end;
    end;
}

