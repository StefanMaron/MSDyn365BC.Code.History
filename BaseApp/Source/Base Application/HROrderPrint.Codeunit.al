codeunit 17372 "HR Order - Print"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        HumanResSetup: Record "Human Resources Setup";
        Director: Record Employee;
        Accountant: Record Employee;
        Employee: Record Employee;
        EmplJobEntry: Record "Employee Job Entry";
        Contract: Record "Labor Contract";
        Position: Record Position;
        OrgUnit: Record "Organizational Unit";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        Text000: Label 'Previous contract line does not exist.';
        Text001: Label 'Employer';
        LocalRepMgt: Codeunit "Local Report Management";
        WholeAmountText: Text[250];
        HundredAmount: Decimal;

    [Scope('OnPrem')]
    procedure PrintFormT1(ContractLine: Record "Labor Contract Line")
    var
        ExcelTemplate: Record "Excel Template";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Director No.");
        Director.Get(CompanyInfo."Director No.");

        HumanResSetup.Get();
        HumanResSetup.TestField("T-1 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-1 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        with ContractLine do begin
            Contract.Get("Contract No.");
            Employee.Get(Contract."Employee No.");
            Position.Get("Position No.");

            ExcelMgt.FillCell('A8', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AI13', "Order No.");
            ExcelMgt.FillCell('AV13', LocalRepMgt.FormatDate("Order Date"));
            ExcelMgt.FillCell('AU19', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('AU20', LocalRepMgt.FormatDate("Ending Date"));
            ExcelMgt.FillCell('AU23', Contract."Employee No.");
            ExcelMgt.FillCell('A23', Employee.GetFullNameOnDate("Order Date"));
            ExcelMgt.FillCell('B25', Employee."Org. Unit Name");
            ExcelMgt.FillCell('A27', Employee."Job Title");
            ExcelMgt.FillCell('A30',
              StrSubstNo('%1 - %2, %3 - %4, %5 - %6',
                Position.FieldCaption("Kind of Work"), Position."Kind of Work",
                Contract.FieldCaption("Work Mode"), Format(Contract."Work Mode"),
                Position.FieldCaption("Conditions of Work"), Position."Conditions of Work"));
            ExcelMgt.FillCell('R34', Format(Position."Base Salary Amount" div 1));
            ExcelMgt.FillCell('R36', Format(Position."Additional Salary Amount" div 1));
            ExcelMgt.FillCell('AN34', Format((Position."Base Salary Amount" mod 1) * 100));
            ExcelMgt.FillCell('AN36', Format((Position."Additional Salary Amount" mod 1) * 100));
            ExcelMgt.FillCell('N39', "Trial Period Description");
            ExcelMgt.FillCell('AP43', Format("Contract No."));
            ExcelMgt.FillCell('N43', Format(Date2DMY("Starting Date", 1)));
            ExcelMgt.FillCell('R43', LocMgt.GetMonthName("Starting Date", true));
            ExcelMgt.FillCell('AH43', CopyStr(Format(Date2DMY("Starting Date", 3)), 3, 2));
            ExcelMgt.FillCell('J48', Director.GetJobTitleName);
            ExcelMgt.FillCell('AP48', Director.GetNameInitials);

            ExcelMgt.WriteAllToCurrentSheet;
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-1a Template Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT1a(GroupOrderHeader: Record "Group Order Header")
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("T-1a Template Code");
        CompanyInfo.Get();

        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-1a Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
        ExcelMgt.FillCell('CF7', Format(CompanyInfo."OKPO Code"));

        if Employee.Get(CompanyInfo."Director No.") then begin
            ExcelMgt.FillCell('R27', Employee.GetJobTitleName);
            ExcelMgt.FillCell('BC27', Employee.GetFullNameOnDate(GroupOrderHeader."Posting Date"));
        end;

        ExcelMgt.FillCell('BC11', GroupOrderHeader."No.");
        ExcelMgt.FillCell('BQ11', LocalRepMgt.FormatDate(GroupOrderHeader."Posting Date"));

        PrintFormT1aLines(GroupOrderHeader."No.", GroupOrderHeader."Document Type");

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-1a Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT1aLines(DocNo: Code[20]; DocType: Option)
    var
        GroupOrderLine: Record "Group Order Line";
        LaborContractLine: Record "Labor Contract Line";
        RowNo: Integer;
    begin
        RowNo := 24;

        with GroupOrderLine do begin
            SetRange("Document No.", DocNo);
            SetRange("Document Type", DocType);

            if FindSet then
                repeat
                    ExcelMgt.CopyRow(RowNo);

                    ExcelMgt.FillCell('A' + Format(RowNo), "Employee Name");
                    ExcelMgt.FillCell('U' + Format(RowNo), "Employee No.");

                    Employee.Get("Employee No.");
                    ExcelMgt.FillCell('AA' + Format(RowNo), Employee."Org. Unit Name");
                    ExcelMgt.FillCell('AJ' + Format(RowNo), Employee.GetJobTitleName);

                    FillLaborContractInfoForT1a(Employee."Contract No.", RowNo);

                    LaborContractLine.SetRange("Contract No.", Employee."Contract No.");
                    LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Hire);
                    LaborContractLine.FindFirst;
                    Position.Get(LaborContractLine."Position No.");
                    ExcelMgt.FillCell('AS' + Format(RowNo), Format(Position."Monthly Salary Amount"));

                    RowNo += 1;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillLaborContractInfoForT1a(ContractNo: Code[20]; RowNo: Integer)
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
    begin
        if LaborContract.Get(ContractNo) then begin
            ExcelMgt.FillCell('BB' + Format(RowNo), LaborContract."No.");
            ExcelMgt.FillCell('BH' + Format(RowNo), LocalRepMgt.FormatDate(LaborContract."Starting Date"));

            LaborContractLine.SetRange("Contract No.", ContractNo);
            if LaborContractLine.FindFirst then begin
                ExcelMgt.FillCell('BP' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Starting Date"));
                ExcelMgt.FillCell('BX' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Ending Date"));

                if (LaborContractLine."Trial Period End Date" <> 0D) and
                   (LaborContractLine."Trial Period Start Date" <> 0D)
                then
                    ExcelMgt.FillCell('CF' + Format(RowNo),
                      Format(Date2DMY(LaborContractLine."Trial Period End Date", 2) -
                        Date2DMY(LaborContractLine."Trial Period Start Date", 2)));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT5(ContractLine: Record "Labor Contract Line")
    var
        PrevContractLine: Record "Labor Contract Line";
        ExcelTemplate: Record "Excel Template";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Director No.");
        Director.Get(CompanyInfo."Director No.");

        HumanResSetup.Get();
        HumanResSetup.TestField("T-5 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-5 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        with ContractLine do begin
            Contract.Get("Contract No.");
            Employee.Get(Contract."Employee No.");

            PrevContractLine := ContractLine;
            if PrevContractLine.Next(-1) = 0 then
                Error(Text000);

            ExcelMgt.FillCell('A8', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AI13', "Order No.");
            ExcelMgt.FillCell('AV13', LocalRepMgt.FormatDate("Order Date"));
            ExcelMgt.FillCell('AU19', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('AU20', LocalRepMgt.FormatDate("Ending Date"));
            ExcelMgt.FillCell('A23', Employee.GetFullNameOnDate("Order Date"));
            ExcelMgt.FillCell('AU23', Contract."Employee No.");

            Position.Get(PrevContractLine."Position No.");
            ExcelMgt.FillCell('H27', Position."Org. Unit Name");
            ExcelMgt.FillCell('H29', Position."Job Title Name");

            Position.Get("Position No.");
            ExcelMgt.FillCell('H34', Position."Org. Unit Name");
            ExcelMgt.FillCell('H36', Position."Job Title Name");

            ExcelMgt.FillCell('V38', Format(Position."Base Salary Amount" div 1));
            ExcelMgt.FillCell('AN38', Format((Position."Base Salary Amount" mod 1) * 100));
            ExcelMgt.FillCell('V40', Format(Position."Additional Salary Amount" div 1));
            ExcelMgt.FillCell('AN40', Format((Position."Additional Salary Amount" mod 1) * 100));
            ExcelMgt.FillCell('AV46', "Supplement No.");
            ExcelMgt.FillCell('V46', Format(Date2DMY(Contract."Starting Date", 1)));
            ExcelMgt.FillCell('Z46', LocMgt.GetMonthName("Order Date", true));
            ExcelMgt.FillCell('AN46', CopyStr(Format(Date2DMY(Contract."Starting Date", 3)), 3, 2));

            ExcelMgt.FillCell('J52', Director.GetJobTitleName);
            ExcelMgt.FillCell('AP52', Director.GetNameInitials);

            ExcelMgt.WriteAllToCurrentSheet;
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-5 Template Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT5a(GroupOrderHeader: Record "Group Order Header")
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
    begin
        CompanyInfo.Get();
        HumanResSetup.Get();
        HumanResSetup.TestField("T-5a Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-5a Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
        ExcelMgt.FillCell('CF7', Format(CompanyInfo."OKPO Code"));

        if Employee.Get(CompanyInfo."Director No.") then begin
            ExcelMgt.FillCell('R28', Employee.GetJobTitleName);
            ExcelMgt.FillCell('BC28', Employee.GetFullNameOnDate(GroupOrderHeader."Posting Date"));
        end;

        ExcelMgt.FillCell('BC11', GroupOrderHeader."No.");
        ExcelMgt.FillCell('BQ11', LocalRepMgt.FormatDate(GroupOrderHeader."Posting Date"));

        PrintFormT5aLines(GroupOrderHeader."No.", GroupOrderHeader."Document Type");

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-5a Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT5aLines(DocNo: Code[20]; DocType: Option)
    var
        GroupOrderLine: Record "Group Order Line";
        LaborContractLine: Record "Labor Contract Line";
        RowNo: Integer;
    begin
        RowNo := 25;

        with GroupOrderLine do begin
            SetRange("Document No.", DocNo);
            SetRange("Document Type", DocType);

            if FindSet then
                repeat
                    ExcelMgt.CopyRow(RowNo);

                    ExcelMgt.FillCell('A' + Format(RowNo), "Employee Name");
                    ExcelMgt.FillCell('U' + Format(RowNo), "Employee No.");

                    Employee.Get("Employee No.");

                    FillLaborContractInfoForT5a(Employee."Contract No.", "Supplement No.", RowNo);

                    LaborContractLine.SetRange("Contract No.", "Contract No.");
                    LaborContractLine.SetRange("Supplement No.", "Supplement No.");
                    LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Transfer);
                    if LaborContractLine.FindFirst then
                        if Position.Get(LaborContractLine."Position No.") then
                            ExcelMgt.FillCell('AY' + Format(RowNo), Format(Position."Monthly Salary Amount"));

                    RowNo += 1;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillLaborContractInfoForT5a(ContractNo: Code[20]; AmendmentNo: Code[10]; RowNo: Integer)
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
        Position: Record Position;
    begin
        if LaborContract.Get(ContractNo) then begin
            LaborContractLine.SetRange("Contract No.", ContractNo);
            LaborContractLine.SetFilter("Supplement No.", '<=%1', AmendmentNo);

            if LaborContractLine.FindLast then begin
                // new position info
                if Position.Get(LaborContractLine."Position No.") then begin
                    ExcelMgt.FillCell('AG' + Format(RowNo), Position."Org. Unit Name");
                    ExcelMgt.FillCell('AS' + Format(RowNo), Position."Job Title Name");
                end;

                ExcelMgt.FillCell('BH' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Starting Date"));
                ExcelMgt.FillCell('BN' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Ending Date"));

                if LaborContractLine."Supplement No." <> '' then
                    ExcelMgt.FillCell('BV' + Format(RowNo), LaborContractLine."Order No." + ' ' +
                      LaborContractLine."Supplement No.")
                else
                    ExcelMgt.FillCell('BV' + Format(RowNo), LaborContractLine."Order No.");
                ExcelMgt.FillCell('CD' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Order Date"));

                // prev position info
                if LaborContractLine.Find('<') then
                    if Position.Get(LaborContractLine."Position No.") then begin
                        ExcelMgt.FillCell('AA' + Format(RowNo), Position."Org. Unit Name");
                        ExcelMgt.FillCell('AM' + Format(RowNo), Position."Job Title Name");
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT6(AbsenceHeader: Record "Absence Header"; Posted: Boolean)
    var
        AbsenceLine: Record "Absence Line";
        PostedAbsenceLine: Record "Posted Absence Line";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        ExcelTemplate: Record "Excel Template";
        TotalDays: Decimal;
        OverallVacationStartDate: Date;
        OverallVacationEndDate: Date;
    begin
        AbsenceHeader.TestField("HR Order Date");

        HumanResSetup.Get();
        HumanResSetup.TestField("T-6 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-6 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        CompanyInfo.Get();

        with AbsenceHeader do begin
            ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AI13', "HR Order No.");
            ExcelMgt.FillCell('AV13', LocalRepMgt.FormatDate("HR Order Date"));
            ExcelMgt.FillCell('AU19', "Employee No.");

            Employee.Get("Employee No.");
            ExcelMgt.FillCell('A19', Employee.GetFullNameOnDate("HR Order Date"));
            Employee.GetJobEntry("Employee No.", "HR Order Date", EmplJobEntry);
            OrgUnit.Get(EmplJobEntry."Org. Unit Code");
            ExcelMgt.FillCell('A21', OrgUnit.Name);
            ExcelMgt.FillCell('A23', Employee.GetJobTitleName);

            EmplAbsenceEntry.Reset();
            EmplAbsenceEntry.SetCurrentKey("Employee No.");
            EmplAbsenceEntry.SetRange("Employee No.", "Employee No.");
            EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Usage);
            EmplAbsenceEntry.SetRange("Document Type", "Document Type" + 1);
            EmplAbsenceEntry.SetRange("Document No.", "No.");
            if EmplAbsenceEntry.FindFirst then
                if EmplAbsenceEntry.Get(EmplAbsenceEntry."Accrual Entry No.") then begin
                    ExcelMgt.FillCell('M26', LocMgt.Date2Text(EmplAbsenceEntry."Start Date"));
                    ExcelMgt.FillCell('AN26', LocMgt.Date2Text(EmplAbsenceEntry."End Date"));
                end;

            Employee.Get(CompanyInfo."Director No.");
            ExcelMgt.FillCell('J47', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP47', Employee.GetNameInitials);

            if Posted then begin
                PostedAbsenceLine.SetRange("Document Type", "Document Type");
                PostedAbsenceLine.SetRange("Document No.", "No.");
                if PostedAbsenceLine.FindSet then
                    repeat
                        if PostedAbsenceLine."Vacation Type" < PostedAbsenceLine."Vacation Type"::Additional then begin // A case
                            ExcelMgt.FillCell('AC28', Format(PostedAbsenceLine."Payment Days"));
                            ExcelMgt.FillCell('C30', LocMgt.Date2Text(PostedAbsenceLine."Start Date"));
                            ExcelMgt.FillCell('AD30', LocMgt.Date2Text(PostedAbsenceLine."End Date"));
                        end else begin // B case
                            ExcelMgt.FillCell('C34', Format(PostedAbsenceLine."Vacation Type"));
                            ExcelMgt.FillCell('Q37', Format(PostedAbsenceLine."Payment Days"));
                            ExcelMgt.FillCell('C39', LocMgt.Date2Text(PostedAbsenceLine."Start Date"));
                            ExcelMgt.FillCell('AD39', LocMgt.Date2Text(PostedAbsenceLine."End Date"));
                        end;
                        TotalDays += PostedAbsenceLine."Payment Days";
                        OverallVacationStartDate := GetMinDate(PostedAbsenceLine."Start Date", OverallVacationStartDate);
                        OverallVacationEndDate := GetMaxDate(PostedAbsenceLine."End Date", OverallVacationEndDate);
                    until PostedAbsenceLine.Next = 0;
                ExcelMgt.FillCell('Q41', Format(TotalDays));
                ExcelMgt.FillCell('C43', LocMgt.Date2Text(OverallVacationStartDate));
                ExcelMgt.FillCell('AD43', LocMgt.Date2Text(OverallVacationEndDate));
            end else begin
                AbsenceLine.SetRange("Document Type", "Document Type");
                AbsenceLine.SetRange("Document No.", "No.");
                if AbsenceLine.FindSet then
                    repeat
                        if AbsenceLine."Vacation Type" < AbsenceLine."Vacation Type"::Additional then begin // A case
                            TotalDays += AbsenceLine."Payment Days";
                            ExcelMgt.FillCell('AC28', Format(AbsenceLine."Payment Days"));
                            ExcelMgt.FillCell('C30', LocMgt.Date2Text(AbsenceLine."Start Date"));
                            ExcelMgt.FillCell('AD30', LocMgt.Date2Text(AbsenceLine."End Date"));
                        end else begin // B case
                            TotalDays += AbsenceLine."Calendar Days";
                            ExcelMgt.FillCell('C34', Format(AbsenceLine."Vacation Type"));
                            ExcelMgt.FillCell('Q37', Format(AbsenceLine."Calendar Days"));
                            ExcelMgt.FillCell('C39', LocMgt.Date2Text(AbsenceLine."Start Date"));
                            ExcelMgt.FillCell('AD39', LocMgt.Date2Text(AbsenceLine."End Date"));
                        end;
                    until AbsenceLine.Next = 0;
                ExcelMgt.FillCell('Q41', Format(TotalDays));
                ExcelMgt.FillCell('C43', LocMgt.Date2Text(OverallVacationStartDate));
                ExcelMgt.FillCell('AD43', LocMgt.Date2Text(OverallVacationEndDate));
            end;
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-6 Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT8(ContractLine: Record "Labor Contract Line")
    var
        PrevContractLine: Record "Labor Contract Line";
        GroundsForTermination: Record "Grounds for Termination";
        ExcelTemplate: Record "Excel Template";
        LaborContract: Record "Labor Contract";
    begin
        HumanResSetup.Get();
        CompanyInfo.Get();
        HumanResSetup.TestField("T-8 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-8 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        with ContractLine do begin
            Contract.Get("Contract No.");
            GroundsForTermination.Get("Dismissal Reason");
            Employee.Get(Contract."Employee No.");

            PrevContractLine.SetRange("Contract No.", "Contract No.");
            PrevContractLine.SetFilter("Operation Type", '<>%1', "Operation Type");
            PrevContractLine.FindLast;
            Position.Get(PrevContractLine."Position No.");

            ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AI14', "Order No.");
            ExcelMgt.FillCell('AV14', LocalRepMgt.FormatDate("Order Date"));
            if LaborContract.Get("Contract No.") then begin
                ExcelMgt.FillCell('AE18', Format(Date2DMY(LaborContract."Starting Date", 1)));
                ExcelMgt.FillCell('AH18', LocMgt.GetMonthName(LaborContract."Starting Date", true));
                ExcelMgt.FillCell('AS18', CopyStr(Format(Date2DMY(LaborContract."Starting Date", 3)), 3, 2));
            end;
            ExcelMgt.FillCell('AY18', Format("Contract No."));
            ExcelMgt.FillCell('A25', Employee.GetFullNameOnDate("Order Date"));
            ExcelMgt.FillCell('AU25', Contract."Employee No.");
            ExcelMgt.FillCell('A27', Employee."Org. Unit Name");
            ExcelMgt.FillCell('A29', Employee."Job Title");
            ExcelMgt.FillCell('A34', "Dismissal Reason" + ' ' + GroundsForTermination.Description);
            ExcelMgt.FillCell('O39', "Dismissal Document");

            if Director.Get(CompanyInfo."Director No.") then begin
                ExcelMgt.FillCell('J45', Director.GetJobTitleName);
                ExcelMgt.FillCell('AP45', Director.GetNameInitials);
            end;

            ExcelMgt.WriteAllToCurrentSheet;
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-8 Template Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT8a(GroupOrderHeader: Record "Group Order Header")
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
    begin
        CompanyInfo.Get();
        HumanResSetup.Get();
        HumanResSetup.TestField("T-8a Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-8a Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
        ExcelMgt.FillCell('CF7', Format(CompanyInfo."OKPO Code"));

        if Employee.Get(CompanyInfo."Director No.") then begin
            ExcelMgt.FillCell('R27', Employee.GetJobTitleName);
            ExcelMgt.FillCell('BC27', Employee.GetFullNameOnDate(GroupOrderHeader."Posting Date"));
        end;

        ExcelMgt.FillCell('BC11', GroupOrderHeader."No.");
        ExcelMgt.FillCell('BQ11', LocalRepMgt.FormatDate(GroupOrderHeader."Posting Date"));

        PrintFormT8aLines(GroupOrderHeader."No.", GroupOrderHeader."Document Type");

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-8a Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT8aLines(DocNo: Code[20]; DocType: Option)
    var
        GroupOrderLine: Record "Group Order Line";
        RowNo: Integer;
    begin
        RowNo := 24;

        with GroupOrderLine do begin
            SetRange("Document No.", DocNo);
            SetRange("Document Type", DocType);

            if FindSet then
                repeat
                    ExcelMgt.CopyRow(RowNo);

                    ExcelMgt.FillCell('A' + Format(RowNo), "Employee Name");
                    ExcelMgt.FillCell('W' + Format(RowNo), "Employee No.");

                    Employee.Get("Employee No.");
                    ExcelMgt.FillCell('AC' + Format(RowNo), Employee."Org. Unit Name");
                    ExcelMgt.FillCell('AM' + Format(RowNo), Employee.GetJobTitleName);

                    FillLaborContractInfoForT8a(Employee."Contract No.", RowNo);

                    RowNo += 1;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillLaborContractInfoForT8a(ContractNo: Code[20]; RowNo: Integer)
    var
        LaborContract: Record "Labor Contract";
        LaborContractLine: Record "Labor Contract Line";
    begin
        if LaborContract.Get(ContractNo) then begin
            ExcelMgt.FillCell('AW' + Format(RowNo), LaborContract."No.");
            ExcelMgt.FillCell('BC' + Format(RowNo), LocalRepMgt.FormatDate(LaborContract."Starting Date"));

            LaborContractLine.SetRange("Contract No.", ContractNo);
            if LaborContractLine.FindLast then begin
                ExcelMgt.FillCell('BK' + Format(RowNo), LocalRepMgt.FormatDate(LaborContractLine."Ending Date"));
                ExcelMgt.FillCell('BT' + Format(RowNo), LaborContractLine."Dismissal Reason");
                ExcelMgt.FillCell('CD' + Format(RowNo), LaborContractLine."Dismissal Document");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT9(AbsenseOrder: Record "Absence Header"; CalendarDays: Decimal; StartDate: Date; EndDate: Date)
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("T-9 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-9 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        CompanyInfo.Get();

        ExcelMgt.FillCell('H31', Format(CalendarDays));
        ExcelMgt.FillCell('B33', LocMgt.Date2Text(StartDate));
        ExcelMgt.FillCell('AC33', LocMgt.Date2Text(EndDate));

        with AbsenseOrder do begin
            ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AS7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AI13', "HR Order No.");
            ExcelMgt.FillCell('AV13', LocalRepMgt.FormatDate("HR Order Date"));
            ExcelMgt.FillCell('AU18', "Employee No.");

            Employee.Get("Employee No.");
            ExcelMgt.FillCell('A18', Employee.GetFullNameOnDate("HR Order Date"));
            Employee.GetJobEntry("Employee No.", "HR Order Date", EmplJobEntry);
            if OrgUnit.Get(EmplJobEntry."Org. Unit Code") then
                ExcelMgt.FillCell('A20', OrgUnit.Name);
            ExcelMgt.FillCell('A22', Employee.GetJobTitleName);
            ExcelMgt.FillCell('A24', "Travel Destination");
            ExcelMgt.FillCell('F35', "Travel Purpose");
            case "Travel Paid By Type" of
                "Travel Paid By Type"::Company:
                    ExcelMgt.FillCell('R38', Text001);
                "Travel Paid By Type"::Customer:
                    if Cust.Get("Travel Paid by No.") then
                        ExcelMgt.FillCell('R38', Cust.Name + ' ' + Cust."Name 2");
                "Travel Paid By Type"::Vendor:
                    if Vend.Get("Travel Paid by No.") then
                        ExcelMgt.FillCell('R38', Vend.Name + ' ' + Vend."Name 2");
            end;
            ExcelMgt.FillCell('O42', "Travel Reason Document");

            Employee.Get(CompanyInfo."Director No.");
            ExcelMgt.FillCell('J47', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP47', Employee.GetNameInitials);
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-9 Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT10(AbsenceHeader: Record "Absence Header"; CalendarDays: Decimal; StartDate: Date; EndDate: Date)
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("T-10 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-10 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        CompanyInfo.Get();

        with AbsenceHeader do begin
            ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AW7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AJ10', "HR Order No.");
            ExcelMgt.FillCell('AV10', LocalRepMgt.FormatDate("HR Order Date"));
            ExcelMgt.FillCell('AW13', "Employee No.");

            Employee.Get("Employee No.");
            ExcelMgt.FillCell('G13', Employee.GetFullNameOnDate("HR Order Date"));
            Employee.GetJobEntry("Employee No.", "HR Order Date", EmplJobEntry);
            if OrgUnit.Get(EmplJobEntry."Org. Unit Code") then
                ExcelMgt.FillCell('A15', OrgUnit.Name);
            ExcelMgt.FillCell('A17', Employee.GetJobTitleName);
            ExcelMgt.FillCell('K19', "Travel Destination");
            ExcelMgt.FillCell('D23', "Travel Purpose");

            FillDocumentInfoForT10(Employee."Person No.", "HR Order Date");

            ExcelMgt.FillCell('C27', Format(CalendarDays));

            Employee.Get(CompanyInfo."Director No.");
            ExcelMgt.FillCell('J35', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP35', Employee.GetNameInitials);

            ExcelMgt.FillCell('C29', LocMgt.Date2Text(StartDate));
            ExcelMgt.FillCell('AD29', LocMgt.Date2Text(EndDate));
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-10 Template Code"));
    end;

    local procedure FillDocumentInfoForT10(PersonNo: Code[20]; OrderDate: Date)
    var
        PersonalDocument: Record "Person Document";
        Person: Record Person;
        TaxpayerDocumentType: Record "Taxpayer Document Type";
    begin
        if Person.Get(PersonNo) then begin
            PersonalDocument.SetRange("Document Type", Person."Identity Document Type");
            PersonalDocument.SetRange("Person No.", PersonNo);
            PersonalDocument.SetFilter("Valid to Date", '%1|>%2', 0D, OrderDate);
            if PersonalDocument.FindFirst then begin
                TaxpayerDocumentType.Get(PersonalDocument."Document Type");
                ExcelMgt.FillCell('S32',
                  TaxpayerDocumentType."Document Name" + ' ' +
                  PersonalDocument."Document Series" + ' ' +
                  PersonalDocument."Document No.");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT10a(AbsenseOrder: Record "Absence Header"; CalendarDays: Decimal; StartDate: Date; EndDate: Date)
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("T-10a Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-10a Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        CompanyInfo.Get();

        with AbsenseOrder do begin
            ExcelMgt.FillCell('A6', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AQ6', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AC10', "HR Order No.");
            ExcelMgt.FillCell('AI10', LocalRepMgt.FormatDate("HR Order Date"));

            Employee.Get("Employee No.");
            ExcelMgt.FillCell('A13', Employee.GetFullNameOnDate("HR Order Date"));
            ExcelMgt.FillCell('AP13', "Employee No.");

            ExcelMgt.FillCell('H20', Employee.GetJobTitleName);
            ExcelMgt.FillCell('R20', "Travel Destination");

            ExcelMgt.FillCell('AB20', LocalRepMgt.FormatDate(StartDate));
            ExcelMgt.FillCell('AE20', LocalRepMgt.FormatDate(EndDate));
            ExcelMgt.FillCell('AH20', Format(CalendarDays));

            ExcelMgt.FillCell('AR20', Format("Travel Reason Document"));

            ExcelMgt.FillCell('A27', "Travel Purpose");

            if OrgUnit.Get(Employee."Org. Unit Code") then begin
                ExcelMgt.FillCell('A20', OrgUnit.Name);

                if Employee.Get(OrgUnit."Manager No.") then begin
                    ExcelMgt.FillCell('I30', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('S30', Employee.GetNameInitials);
                    ExcelMgt.FillCell('AG34', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('AQ34', Employee.GetNameInitials);
                end;
            end;

            if Employee.Get(CompanyInfo."Director No.") then begin
                ExcelMgt.FillCell('I34', Employee.GetJobTitleName);
                ExcelMgt.FillCell('S34', Employee.GetNameInitials);
            end;
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-10a Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT11(EmployeeJournalLine: Record "Employee Journal Line")
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        OrgUnit: Record "Organizational Unit";
        ReasonCode: Record "Reason Code";
    begin
        HumanResSetup.Get();
        HumanResSetup.TestField("T-11 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-11 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        CompanyInfo.Get();

        with EmployeeJournalLine do begin
            ExcelMgt.FillCell('A6', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AB6', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('Q10', "HR Order No.");
            ExcelMgt.FillCell('W10', LocalRepMgt.FormatDate("HR Order Date"));
            ExcelMgt.FillCell('AA15', "Employee No.");

            Employee.Get("Employee No.");
            ExcelMgt.FillCell('A15', Employee.GetFullNameOnDate("HR Order Date"));
            OrgUnit.Get(Employee."Org. Unit Code");
            ExcelMgt.FillCell('A17', OrgUnit.Name);
            ExcelMgt.FillCell('A19', Employee.GetJobTitleName);

            if ReasonCode.Get("Reason Code") then
                ExcelMgt.FillCell('A21', ReasonCode.Description);

            LocMgt.Amount2Text2('', Amount, WholeAmountText, HundredAmount);
            ExcelMgt.FillCell('G32', WholeAmountText);
            ExcelMgt.FillCell('AB34', Format(HundredAmount));
            ExcelMgt.FillCell('V36', Format(Amount, 0, '<Integer>'));
            ExcelMgt.FillCell('AC36', Format(HundredAmount));

            Employee.Get(CompanyInfo."Director No.");
            ExcelMgt.FillCell('J44', Employee.GetJobTitleName);
            ExcelMgt.FillCell('V44', Employee.GetNameInitials);
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-11 Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT73(LaborContract: Record "Labor Contract")
    var
        ExcelTemplate: Record "Excel Template";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Director No.");
        Director.Get(CompanyInfo."Director No.");

        HumanResSetup.Get();
        HumanResSetup.TestField("T-73 Template Code");

        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-73 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        with LaborContract do begin
            Employee.Get("Employee No.");

            ExcelMgt.FillCell('A6', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('AA6', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('AB16', Director.GetJobTitleName);
            ExcelMgt.FillCell('AA18', Director.GetNameInitials);

            if Accountant.Get(CompanyInfo."Accountant No.") then
                ExcelMgt.FillCell('Q62', Accountant.GetNameInitials);
            Employee.GetJobEntry("Employee No.", WorkDate, EmplJobEntry);
            OrgUnit.Get(EmplJobEntry."Org. Unit Code");
            ExcelMgt.FillCell('A8', OrgUnit.Name);
            ExcelMgt.FillCell('AA10', "No.");
            ExcelMgt.FillCell('D24', Employee.GetFullNameOnDate("Starting Date"));

            ExcelMgt.FillCell('AA11', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('AA12', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('AA13', LocalRepMgt.FormatDate("Ending Date"));
            ExcelMgt.FillCell('L19', "Employee No.");
            ExcelMgt.FillCell('O19', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('S19', LocalRepMgt.FormatDate("Starting Date"));
            ExcelMgt.FillCell('U19', LocalRepMgt.FormatDate("Ending Date"));
            ExcelMgt.FillCell('N23', "No.");
            ExcelMgt.FillCell('V23', Format(Date2DMY("Starting Date", 1)));
            ExcelMgt.FillCell('Y23', LocMgt.GetMonthName("Starting Date", true));
            ExcelMgt.FillCell('AD23', CopyStr(Format(Date2DMY("Starting Date", 3)), 3, 2));
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-73 Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT3a(StaffListOrderHeader: Record "Staff List Order Header"; Posted: Boolean)
    var
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        StaffListOrderLine: Record "Staff List Order Line";
        PostedStaffListOrderLine: Record "Posted Staff List Order Line";
        RowNo: Integer;
    begin
        CompanyInfo.Get();
        HumanResSetup.Get();
        HumanResSetup.TestField("T-3a Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-3a Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        ExcelMgt.FillCell('A1', LocalRepMgt.GetCompanyName);

        if Employee.Get(CompanyInfo."Director No.") then begin
            ExcelMgt.FillCell('J16', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP16', Employee.GetFullNameOnDate(StaffListOrderHeader."Posting Date"));
        end;

        if Employee.Get(CompanyInfo."Accountant No.") then begin
            ExcelMgt.FillCell('J20', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP20', Employee.GetFullNameOnDate(StaffListOrderHeader."Posting Date"));
        end;

        if Employee.Get(CompanyInfo."HR Manager No.") then begin
            ExcelMgt.FillCell('J22', Employee.GetJobTitleName);
            ExcelMgt.FillCell('AP23', Employee.GetFullNameOnDate(StaffListOrderHeader."Posting Date"));
        end;

        ExcelMgt.FillCell('AK6', StaffListOrderHeader."HR Order No.");
        ExcelMgt.FillCell('AX6', LocalRepMgt.FormatDate(StaffListOrderHeader."HR Order Date"));
        ExcelMgt.FillCell('I8', Format(StaffListOrderHeader.Description));
        ExcelMgt.FillCell('P10', LocalRepMgt.FormatDate(StaffListOrderHeader."Posting Date"));

        RowNo := 13;
        if not Posted then begin
            StaffListOrderLine.SetRange("Document No.", StaffListOrderHeader."No.");
            if StaffListOrderLine.FindSet then
                repeat
                    PrintFormT3aLines(StaffListOrderLine, RowNo);
                    RowNo += 1;
                until StaffListOrderLine.Next = 0;
        end else begin
            PostedStaffListOrderLine.SetRange("Document No.", StaffListOrderHeader."No.");
            if PostedStaffListOrderLine.FindSet then
                repeat
                    StaffListOrderLine.TransferFields(PostedStaffListOrderLine);
                    PrintFormT3aLines(StaffListOrderLine, RowNo);
                    RowNo += 1;
                until PostedStaffListOrderLine.Next = 0;
        end;

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-3a Template Code"));
    end;

    [Scope('OnPrem')]
    procedure PrintFormT3aLines(var StaffListOrderLine: Record "Staff List Order Line"; RowNo: Integer)
    var
        Text001: Label 'Create new Org. Unit %1';
        Text003: Label 'Remove Org. Unit %1 from Staff List';
        Text004: Label 'Rename Org. Unit %1 to %2';
        Text005: Label 'Create new Position %1 with salary %2 in Org. Unit %3';
        Text007: Label 'Remove Position %1 with salary %2 from Org. Unit %3';
        Text008: Label 'Rename Position %1 to %2 without changing salary and its duties';
        Position: Record Position;
    begin
        with StaffListOrderLine do begin
            ExcelMgt.CopyRow(RowNo);

            case Type of
                Type::"Org. Unit":
                    case Action of
                        Action::Approve:
                            ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text001, Name));
                        Action::Close:
                            ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text003, Name));
                        Action::Rename:
                            ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text004, Name, "New Name"));
                    end;
                Type::Position:
                    begin
                        Position.Get(Code);
                        case Action of
                            Action::Approve:
                                ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text005,
                                    Position."Job Title Name", Position."Monthly Salary Amount", Position."Org. Unit Name"));
                            Action::Close:
                                ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text007,
                                    Position."Job Title Name", Position."Monthly Salary Amount", Position."Org. Unit Name"));
                            Action::Rename:
                                ExcelMgt.FillCell('C' + Format(RowNo), StrSubstNo(Text008, Name, "New Name"));
                        end;
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintFormT61(LaborContract: Record "Labor Contract")
    var
        ExcelTemplate: Record "Excel Template";
        PostedPayrollDocLine: Record "Posted Payroll Document Line";
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
        ContractLine: Record "Labor Contract Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
        RowNo: Integer;
        TotalAmount: Decimal;
        AEInfoFound: Boolean;
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Director No.");
        Director.Get(CompanyInfo."Director No.");

        HumanResSetup.Get();
        HumanResSetup.TestField("T-61 Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."T-61 Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        ContractLine.SetRange("Contract No.", LaborContract."No.");
        ContractLine.SetRange("Operation Type", ContractLine."Operation Type"::Dismissal);
        ContractLine.FindLast;

        with ContractLine do begin
            Employee.Get(LaborContract."Employee No.");
            Position.Get("Position No.");

            ExcelMgt.FillCell('A7', LocalRepMgt.GetCompanyName);
            ExcelMgt.FillCell('DA7', CompanyInfo."OKPO Code");
            ExcelMgt.FillCell('DA8', LaborContract."No.");
            ExcelMgt.FillCell('DA9', LocalRepMgt.FormatDate(LaborContract."Starting Date"));
            ExcelMgt.FillCell('BO13', "Order No.");
            ExcelMgt.FillCell('CE13', LocalRepMgt.FormatDate("Order Date"));
            ExcelMgt.FillCell('A17', Employee.GetFullNameOnDate("Order Date"));
            ExcelMgt.FillCell('CV17', LaborContract."Employee No.");
            ExcelMgt.FillCell('A19', Employee."Org. Unit Name");
            ExcelMgt.FillCell('A21',
              StrSubstNo('%1 - %2, %3 - %4, %5 - %6, %7 - %8',
                Employee.FieldCaption("Job Title"), Employee."Job Title",
                Position.FieldCaption("Kind of Work"), Position."Kind of Work",
                LaborContract.FieldCaption("Work Mode"), Format(LaborContract."Work Mode"),
                Position.FieldCaption("Conditions of Work"), Position."Conditions of Work"));
            ExcelMgt.FillCell('CE23', LocalRepMgt.FormatDate(LaborContract."Ending Date"));
            ExcelMgt.FillCell('AM26', LocalRepMgt.FormatDate("Order Date"));
            ExcelMgt.FillCell('CM26', Format("Order No."));
            // vacation data
            ExcelMgt.FillCell('AH32', Format(Date2DMY("Order Date", 1)));
            ExcelMgt.FillCell('AO32', LocMgt.GetMonthName("Order Date", true));
            ExcelMgt.FillCell('BK32', CopyStr(Format(Date2DMY("Order Date", 3)), 3, 2));
            ExcelMgt.FillCell('AF30', Director.GetJobTitleName);
            ExcelMgt.FillCell('CI30', Director.GetNameInitials);

            // AE data
            AEInfoFound := false;
            EmplLedgEntry.Reset();
            EmplLedgEntry.SetCurrentKey("Employee No.");
            EmplLedgEntry.SetRange("Employee No.", Employee."No.");
            EmplLedgEntry.SetRange("Contract No.", "Contract No.");
            EmplLedgEntry.SetRange("HR Order No.", "Order No.");
            EmplLedgEntry.SetRange("HR Order Date", "Order Date");
            EmplLedgEntry.SetRange("Action Ending Date", "Ending Date");
            if EmplLedgEntry.FindSet then
                repeat
                    PostedPayrollDocLine.Reset();
                    PostedPayrollDocLine.SetCurrentKey("Document Type", "HR Order No.");
                    PostedPayrollDocLine.SetRange("HR Order No.", "Order No.");
                    PostedPayrollDocLine.SetRange("Employee No.", LaborContract."Employee No.");
                    PostedPayrollDocLine.SetRange("Element Code", EmplLedgEntry."Element Code");
                    if PostedPayrollDocLine.FindFirst then begin
                        PostedPayrollDocLine.CalcFields("AE Total Days", "AE Total Earnings");
                        if (PostedPayrollDocLine."AE Total Earnings" <> 0) and (not AEInfoFound) then begin
                            // ¬«½-ó« ¬á½Ñ¡ñáÓ¡ÙÕ ñ¡Ñ® ÓáßþÑÔ¡«ú« »ÑÓ¿«ñá
                            ExcelMgt.FillCell('BL41', Format(PostedPayrollDocLine."AE Total Days"));
                            // ßÓÑñ¡¿® ñ¡Ñó¡«® ºáÓáí«Ô«¬
                            ExcelMgt.FillCell('CY41', Format(PostedPayrollDocLine."AE Daily Earnings"));
                            // ¿Ô«ú«
                            ExcelMgt.FillCell('AF53', Format(PostedPayrollDocLine."AE Total Earnings"));

                            RowNo := 41;
                            PostedPayrollPeriodAE.SetRange("Document No.", PostedPayrollDocLine."Document No.");
                            PostedPayrollPeriodAE.SetRange("Line No.", PostedPayrollDocLine."Line No.");
                            if PostedPayrollPeriodAE.FindSet then
                                repeat
                                    ExcelMgt.FillCell('A' + Format(RowNo), Format(PostedPayrollPeriodAE.Year));
                                    ExcelMgt.FillCell('O' + Format(RowNo), Format(PostedPayrollPeriodAE.Month));
                                    ExcelMgt.FillCell('AF' + Format(RowNo),
                                      Format(PostedPayrollPeriodAE."Salary Amount" + PostedPayrollPeriodAE."Bonus Amount"));
                                    RowNo += 1;
                                until PostedPayrollPeriodAE.Next = 0;
                        end;
                        TotalAmount += PostedPayrollDocLine."Payroll Amount";
                    end;
                until (EmplLedgEntry.Next = 0);

            // éßÑú« ¡áþ¿ß½Ñ¡«
            ExcelMgt.FillCell('AE59', Format(TotalAmount));

            // æÒ¼¼á ¬ óÙ»½áÔÑ
            ExcelMgt.FillCell('DA59', Format(TotalAmount));
            ExcelMgt.FillCell('S61', LocMgt.Amount2Text('', TotalAmount));

          ExcelMgt.WriteAllToCurrentSheet;
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-61 Template Code"));
        end;
    end;

    [Scope('OnPrem')]
    procedure PrintSickLeaveAbsence(PostedPayrollDocument: Record "Posted Payroll Document"; PostedPayrollDocumentLine: Record "Posted Payroll Document Line")
    var
        CompanyInfo: Record "Company Information";
        HumanResSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        Employee: Record Employee;
        ExcelMgt: Codeunit "Excel Management";
        RecordOfService: Codeunit "Record of Service Management";
        InsQty: array[3] of Integer;
        InitialAbsenceLine: Record "Posted Absence Line";
        InitialAbsenceHeader: Record "Posted Absence Header";
        PayrollPeriod: Record "Payroll Period";
        TotalAmount: Decimal;
    begin
        CompanyInfo.Get();
        // CompanyInfo.TESTFIELD("Director No.");
        // Director.GET(CompanyInfo."Director No.");

        if InitialAbsenceHeader.Get(
             InitialAbsenceLine."Document Type"::"Sick Leave", PostedPayrollDocumentLine."HR Order No.")
        then
            InitialAbsenceLine.SetRange("Document Type", InitialAbsenceLine."Document Type"::"Sick Leave");
        InitialAbsenceLine.SetRange("Document No.", PostedPayrollDocumentLine."HR Order No.");
        if InitialAbsenceLine.FindFirst then;

        HumanResSetup.Get();
        HumanResSetup.TestField("Sick Leave Abs. Template Code");
        ExcelMgt.OpenBookForUpdate(ExcelTemplate.OpenTemplate(HumanResSetup."Sick Leave Abs. Template Code"));
        ExcelMgt.OpenSheet('Sheet1');

        with PostedPayrollDocument do begin
            ExcelMgt.FillCell('P2', InitialAbsenceHeader."Sick Certificate Series");
            ExcelMgt.FillCell('W2', InitialAbsenceHeader."Sick Certificate No.");
            ExcelMgt.FillCell('G4', CompanyInfo.Name);
            Employee.Get("Employee No.");
            ExcelMgt.FillCell('G5', Employee.GetFullName);
            ExcelMgt.FillCell('G6', Employee."Org. Unit Name");
            ExcelMgt.FillCell('V6', Employee."Job Title");
            ExcelMgt.FillCell('G7', Employee."No.");
            ExcelMgt.FillCell('I8', LocalRepMgt.FormatDate(InitialAbsenceLine."Start Date"));
            ExcelMgt.FillCell('S8', LocalRepMgt.FormatDate(InitialAbsenceLine."End Date"));
            ExcelMgt.FillCell('Q9', Format(InitialAbsenceLine."Calendar Days" - InitialAbsenceLine."Working Days"));
            RecordOfService.CalcEmplInsuredService(Employee, InitialAbsenceLine."Start Date", InsQty);
            ExcelMgt.FillCell('U12',
              GetPeriodPart(InsQty[1], 3) + ' ' +
              GetPeriodPart(InsQty[2], 2) + ' ' +
              GetPeriodPart(InsQty[3], 1));
            ExcelMgt.FillCell('B14', Format(PostedPayrollDocumentLine."Payment Percent"));

            FillAEPeriodInfo(PostedPayrollDocumentLine."Document No.", PostedPayrollDocumentLine."Line No.", ExcelMgt);
            PostedPayrollDocumentLine.CalcFields("AE Total Days", "AE Total FSI Earnings");
            ExcelMgt.FillCell('P19', Format(PostedPayrollDocumentLine."AE Total Days"));
            ExcelMgt.FillCell('Y19', Format(PostedPayrollDocumentLine."AE Daily Earnings"));

            if PayrollPeriod.Get("Period Code") then
                ExcelMgt.FillCell('P28', PayrollPeriod.Name);
        end;

        TotalAmount := FillBonusAmounts(PostedPayrollDocumentLine."HR Order No.",
            PostedPayrollDocumentLine."Document Type", ExcelMgt);

        ExcelMgt.FillCell('I27', Format(TotalAmount));

        FillBonus(InitialAbsenceLine, PostedPayrollDocumentLine, TotalAmount, ExcelMgt);

        ExcelMgt.WriteAllToCurrentSheet;
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."Sick Leave Abs. Template Code"));
    end;

    [Scope('OnPrem')]
    procedure FillBonusAmounts(HROrderNo: Code[20]; DocType: Integer; ExcelMgt: Codeunit "Excel Management") Amount: Decimal
    var
        RowNo: Integer;
        PostedPayrollDocumentLine: Record "Posted Payroll Document Line";
    begin
        RowNo := 38;
        Amount := 0;

        PostedPayrollDocumentLine.SetRange("HR Order No.", HROrderNo);
        PostedPayrollDocumentLine.SetRange("Document Type", DocType);

        if PostedPayrollDocumentLine.FindSet then
            repeat
                ExcelMgt.CopyRow(RowNo);
                ExcelMgt.FillCell('D' + Format(RowNo), LocalRepMgt.FormatDate(PostedPayrollDocumentLine."Action Starting Date"));
                ExcelMgt.FillCell('G' + Format(RowNo), LocalRepMgt.FormatDate(PostedPayrollDocumentLine."Action Ending Date"));
                ExcelMgt.FillCell('K' + Format(RowNo), Format(PostedPayrollDocumentLine."Payment Days"));
                ExcelMgt.FillCell('N' + Format(RowNo), Format(PostedPayrollDocumentLine."Payroll Amount"));
                ExcelMgt.FillCell('T' + Format(RowNo), Format(PostedPayrollDocumentLine."Payment Source"));

                Amount += PostedPayrollDocumentLine."Payroll Amount";

                RowNo += 1;
            until PostedPayrollDocumentLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillBonus(PostedAbsenceLine: Record "Posted Absence Line"; PostedPayrollDocumentLine: Record "Posted Payroll Document Line"; TotalAmount: Decimal; ExcelMgt: Codeunit "Excel Management")
    var
        SickLeaveSetup: Record "Sick Leave Setup";
        PayrollDocumentLine: Record "Payroll Document Line";
    begin
        with PostedAbsenceLine do begin
            ExcelMgt.FillCell('D25', LocalRepMgt.FormatDate("Start Date"));
            ExcelMgt.FillCell('F25', LocalRepMgt.FormatDate("End Date"));
            ExcelMgt.FillCell('K25', Format("Calendar Days"));
            ExcelMgt.FillCell('M25', Format("Payment Percent"));
            ExcelMgt.FillCell('S25', Format(PostedPayrollDocumentLine."AE Daily Earnings"));

            PayrollDocumentLine.TransferFields(PostedPayrollDocumentLine);
            ExcelMgt.FillCell('X25', Format(SickLeaveSetup.GetMaxDailyPayment(PayrollDocumentLine)));

            ExcelMgt.FillCell('AB25', Format(TotalAmount));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPeriodPart(Qty: Integer; Type: Integer): Text[30]
    var
        LocMgt: Codeunit "Localisation Management";
    begin
        if Qty <> 0 then
            exit(Format(Qty) + ' ' + LocMgt.GetPeriodText(Type));

        exit('');
    end;

    [Scope('OnPrem')]
    procedure FillAEPeriodInfo(DocumentNo: Code[20]; LineNo: Integer; ExcelMgt: Codeunit "Excel Management")
    var
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
    begin
        with PostedPayrollPeriodAE do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Line No.", LineNo);

            if FindFirst then begin
                ExcelMgt.FillCell('D19', Format(Date2DMY("Period Start Date", 3) - 1));
                ExcelMgt.FillCell('K19', Format(GetFSIEarnings(DocumentNo, LineNo, Date2DMY("Period Start Date", 3) - 1)));

                ExcelMgt.FillCell('D20', Format(Date2DMY("Period Start Date", 3)));
                ExcelMgt.FillCell('K20', Format(GetFSIEarnings(DocumentNo, LineNo, Date2DMY("Period Start Date", 3))));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFSIEarnings(DocumentNo: Code[20]; LineNo: Integer; PeriodYear: Integer) TotalFSIAmount: Decimal
    var
        PostedPayrollPeriodAE: Record "Posted Payroll Period AE";
    begin
        with PostedPayrollPeriodAE do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Line No.", LineNo);
            SetRange("Period Start Date", DMY2Date(1, 1, PeriodYear), DMY2Date(31, 12, PeriodYear));

            if FindSet then
                repeat
                    TotalFSIAmount += "Amount for FSI";
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetMinDate(Date1: Date; Date2: Date): Date
    begin
        if Date1 = 0D then
            exit(Date2);

        if Date2 = 0D then
            exit(Date1);

        if Date1 > Date2 then
            exit(Date2);

        exit(Date1);
    end;

    [Scope('OnPrem')]
    procedure GetMaxDate(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);

        exit(Date2);
    end;
}

