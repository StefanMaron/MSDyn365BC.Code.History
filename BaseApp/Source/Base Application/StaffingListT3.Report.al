report 17373 "Staffing List T-3"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Staffing List T-3';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(StaffingListOrder; "Staff List Archive")
        {
            CalcFields = "Staff Positions";
            DataItemTableView = SORTING("Document No.");
            RequestFilterFields = "Document No.";
            dataitem(StaffingListLine; "Staff List Line Archive")
            {
                DataItemLink = "Document No." = FIELD("Document No.");
                DataItemTableView = SORTING("Document No.", "Org. Unit Code", "Job Title Code") WHERE(Type = CONST(Unit));
                dataitem(Position; Position)
                {
                    DataItemLink = "Org. Unit Code" = FIELD("Org. Unit Code"), "Job Title Code" = FIELD("Job Title Code");
                    DataItemTableView = SORTING("No.");

                    trigger OnAfterGetRecord()
                    var
                        Employee: Record Employee;
                        EmplJobEntry: Record "Employee Job Entry";
                        Value1: Decimal;
                        Value2: Decimal;
                        Value3: Decimal;
                    begin
                        if not IsStaffArrangement then
                            CurrReport.Skip();

                        ExcelMgt.CopyRow(RowNo);

                        if Employee.Get(EmplJobEntry.GetEmployeeNo("No.", StaffingListOrder."Staff List Date")) then
                            ExcelMgt.FillCell('AE' + Format(RowNo), '  ' + Employee.GetFullNameOnDate(StaffingListOrder."Document Date"))
                        else
                            ExcelMgt.FillCell('AE' + Format(RowNo), '  ' + Text14708);

                        if Rate <> 0 then
                            if GetDetailAdditionalSalary("No.", Value1, Value2, Value3) then begin
                                FillSalaryFields(RowNo, Rate, "Base Salary Amount" / Rate,
                                  Value1, Value2, Value3,
                                  "Monthly Salary Amount");
                            end else
                                FillSalaryFields(RowNo, Rate, "Base Salary Amount" / Rate,
                                  "Additional Salary Amount" / Rate, 0, 0,
                                  "Monthly Salary Amount");

                        RowNo += 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        case ShowStaff of
                            ShowStaff::"Staff Only":
                                SetRange("Out-of-Staff", false);
                            ShowStaff::"Out-of-Staff Only":
                                SetRange("Out-of-Staff", true);
                        end;

                        SetFilter("Starting Date", '<=%1', StaffingListOrder."Staff List Date");
                        SetFilter("Ending Date", '>%1|%2', StaffingListOrder."Staff List Date", 0D);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Positions: Decimal;
                    BaseSalary: Decimal;
                    BonusSalary: Decimal;
                    MonthlySalary: Decimal;
                    Bonus1: Decimal;
                    Bonus2: Decimal;
                    Bonus3: Decimal;
                begin
                    ExcelMgt.CopyRow(RowNo);

                    if OrgUnitCode <> "Org. Unit Code" then begin
                        if OrgUnitCode <> '' then
                            DrawFooter;

                        DrawHeader;

                        OrgUnitCode := "Org. Unit Code";
                    end;

                    ExcelMgt.FillCell('AE' + Format(RowNo), "Job Title Name");
                    OrgUnitName := "Org. Unit Name";

                    case ShowStaff of
                        ShowStaff::"Staff Only":
                            begin
                                Positions := "Staff Positions";
                                BaseSalary := "Staff Base Salary";
                                BonusSalary := "Staff Additional Salary";
                                MonthlySalary := "Staff Monthly Salary";
                                OrgUnitApprovedPositions += "Staff Positions";
                                OrgUnitMonthlySalary += "Staff Monthly Salary";

                                Position.SetRange("Out-of-Staff", false);
                            end;
                        ShowStaff::"Out-of-Staff Only":
                            begin
                                Positions := "Out-of-Staff Positions";
                                BaseSalary := "Out-of-Staff Base Salary";
                                BonusSalary := "Out-of-Staff Additional Salary";
                                MonthlySalary := "Out-of-Staff Monthly Salary";
                                OrgUnitMonthlySalary += "Out-of-Staff Monthly Salary";
                                OrgUnitApprovedPositions += "Out-of-Staff Positions";

                                Position.SetRange("Out-of-Staff", true);
                            end;
                        ShowStaff::All:
                            begin
                                Positions := "Staff Positions" + "Out-of-Staff Positions";
                                BaseSalary := "Staff Base Salary" + "Out-of-Staff Base Salary";
                                BonusSalary := "Staff Additional Salary" + "Out-of-Staff Additional Salary";
                                MonthlySalary := "Staff Monthly Salary" + "Out-of-Staff Monthly Salary";
                                OrgUnitMonthlySalary += "Staff Monthly Salary" + "Out-of-Staff Monthly Salary";
                                OrgUnitApprovedPositions += "Staff Positions" + "Out-of-Staff Positions";

                                Position.SetRange("Out-of-Staff");
                            end;
                    end;

                    if GetFullDetailAdditionalSalary("Org. Unit Code", "Job Title Code", Bonus1, Bonus2, Bonus3) then
                        FillSalaryFields(RowNo, Positions, BaseSalary, Bonus1, Bonus2, Bonus3, MonthlySalary)
                    else
                        FillSalaryFields(RowNo, Positions, BaseSalary, BonusSalary, 0, 0, MonthlySalary);

                    if IsStaffArrangement then
                        ExcelMgt.BoldRow(RowNo);

                    RowNo += 1;
                end;

                trigger OnPostDataItem()
                var
                    HRManager: Record Employee;
                    Accountant: Record Employee;
                begin
                    if OrgUnitCode <> '' then
                        DrawFooter;

                    ExcelMgt.FillCell('BI' + Format(RowNo + 1), Format(TotalApprovedPositions));
                    ExcelMgt.FillCell('DT' + Format(RowNo + 1), Format(TotalMonthlySalary));

                    if HRManager.Get(StaffingListOrder."HR Manager No.") then begin
                        ExcelMgt.FillCell('AJ' + Format(RowNo + 3), Format(HRManager.GetJobTitleName));
                        ExcelMgt.FillCell('DE' + Format(RowNo + 3), Format(HRManager.GetNameInitials));
                    end;

                    if Accountant.Get(StaffingListOrder."Chief Accountant No.") then
                        ExcelMgt.FillCell('BJ' + Format(RowNo + 6), Format(Accountant.GetNameInitials));
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Date Filter", 0D, StaffingListOrder."Staff List Date");
                    OrgUnitCode := '';

                    TotalApprovedPositions := 0;
                    TotalMonthlySalary := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ExcelMgt.FillCell('AJ11', Format("Staff List Date"));
                ExcelMgt.FillCell('BQ9', "Order No.");
                ExcelMgt.FillCell('CI9', Format("Order Date"));

                ExcelMgt.FillCell('EE10', LocMgt.Date2Text("Document Date"));
                ExcelMgt.FillCell('FF10', "Order No.");
                ExcelMgt.FillCell('DX11', Format("Staff Positions"));
            end;

            trigger OnPreDataItem()
            var
                Employee: Record Employee;
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('Sheet1');
                RowNo := 16;

                ExcelMgt.FillCell('A5', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
                ExcelMgt.FillCell('EV5', CompanyInfo."OKPO Code");

                if Employee.Get(CompanyInfo."HR Manager No.") then begin
                    ExcelMgt.FillCell('AJ19', Employee.GetJobTitleName);
                    ExcelMgt.FillCell('DE19', Employee.GetNameInitials);
                end;
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
                    field(ShowStaff; ShowStaff)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Staff';
                    }
                    field(IsStaffArrangement; IsStaffArrangement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Staff Arrangement';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-3 Template Code"))
        else
          ExcelMgt.CloseBook
    end;

    trigger OnPreReport()
    begin
        HumResSetup.Get();
        HumResSetup.TestField("T-3 Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-3 Template Code");

        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        HumResSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        FileName: Text[1024];
        RowNo: Integer;
        OrgUnitCode: Code[10];
        OrgUnitName: Text[50];
        OrgUnitApprovedPositions: Decimal;
        TotalApprovedPositions: Decimal;
        OrgUnitMonthlySalary: Decimal;
        TotalMonthlySalary: Decimal;
        Text14707: Label 'Total for %1';
        ShowStaff: Option "Staff Only","Out-of-Staff Only",All;
        IsStaffArrangement: Boolean;
        Text14708: Label 'Open Position';
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure DrawFooter()
    begin
        TotalApprovedPositions += OrgUnitApprovedPositions;
        TotalMonthlySalary += OrgUnitMonthlySalary;

        ExcelMgt.CopyRow(RowNo);
        ExcelMgt.FillCell('AE' + Format(RowNo), StrSubstNo(Text14707, OrgUnitName));
        ExcelMgt.FillCell('BI' + Format(RowNo), Format(OrgUnitApprovedPositions));
        ExcelMgt.FillCell('DT' + Format(RowNo), Format(OrgUnitMonthlySalary));
        RowNo += 1;

        OrgUnitApprovedPositions := 0;
        OrgUnitMonthlySalary := 0;
    end;

    [Scope('OnPrem')]
    procedure DrawHeader()
    begin
        ExcelMgt.CopyRow(RowNo);

        ExcelMgt.FillCell('A' + Format(RowNo), StaffingListLine."Org. Unit Name");
        ExcelMgt.FillCell('U' + Format(RowNo), StaffingListLine."Org. Unit Code");

        ExcelMgt.BoldRow(RowNo);

        RowNo += 1;
    end;

    [Scope('OnPrem')]
    procedure FillSalaryFields(RowNo: Integer; Positions: Decimal; BaseSalary: Decimal; BonusSalary1: Decimal; BonusSalary2: Decimal; BonusSalary3: Decimal; MonthlySalary: Decimal)
    begin
        ExcelMgt.FillCell('BI' + Format(RowNo), Format(Positions));
        ExcelMgt.FillCell('BX' + Format(RowNo), Format(Round(BaseSalary, 0.01)));
        ExcelMgt.FillCell('CM' + Format(RowNo), Format(Round(BonusSalary1, 0.01)));
        ExcelMgt.FillCell('CX' + Format(RowNo), Format(Round(BonusSalary2, 0.01)));
        ExcelMgt.FillCell('DI' + Format(RowNo), Format(Round(BonusSalary3, 0.01)));
        ExcelMgt.FillCell('DT' + Format(RowNo), Format(Round(MonthlySalary, 0.01)));
    end;

    [Scope('OnPrem')]
    procedure GetDetailAdditionalSalary(PositionNo: Code[20]; var Value1: Decimal; var Value2: Decimal; var Value3: Decimal): Boolean
    var
        ContractTermsSetup: Record "Labor Contract Terms Setup";
        PayrollElement: Record "Payroll Element";
    begin
        Value1 := 0;
        Value2 := 0;
        Value3 := 0;

        ContractTermsSetup.SetRange("Table Type", ContractTermsSetup."Table Type"::Position);
        ContractTermsSetup.SetRange("No.", PositionNo);
        ContractTermsSetup.SetRange("Additional Salary", true);
        if ContractTermsSetup.FindSet then
            repeat
                if PayrollElement.Get(ContractTermsSetup."Element Code") then
                    case PayrollElement."T-3 Report Column" of
                        1:
                            Value1 += ContractTermsSetup.Amount;
                        2:
                            Value2 += ContractTermsSetup.Amount;
                        3:
                            Value3 += ContractTermsSetup.Amount;
                    end;
            until ContractTermsSetup.Next() = 0;

        exit(DetailValueExists(Value1, Value2, Value3));
    end;

    [Scope('OnPrem')]
    procedure DetailValueExists(Value1: Decimal; Value2: Decimal; Value3: Decimal): Boolean
    begin
        exit((Value1 <> 0) or (Value2 <> 0) or (Value3 <> 0));
    end;

    [Scope('OnPrem')]
    procedure GetFullDetailAdditionalSalary(OrgUnitCode: Code[10]; JobTitleCode: Code[10]; var Value1: Decimal; var Value2: Decimal; var Value3: Decimal): Boolean
    var
        Position: Record Position;
        PosValue1: Decimal;
        PosValue2: Decimal;
        PosValue3: Decimal;
    begin
        Position.SetRange("Org. Unit Code", OrgUnitCode);
        Position.SetRange("Job Title Code", JobTitleCode);

        case ShowStaff of
            ShowStaff::"Staff Only":
                Position.SetRange("Out-of-Staff", false);
            ShowStaff::"Out-of-Staff Only":
                Position.SetRange("Out-of-Staff", true);
        end;

        Position.SetFilter("Starting Date", '<=%1', StaffingListOrder."Staff List Date");
        Position.SetFilter("Ending Date", '>%1|%2', StaffingListOrder."Staff List Date", 0D);

        if Position.FindSet then
            repeat
                GetDetailAdditionalSalary(Position."No.", PosValue1, PosValue2, PosValue3);
                Value1 += PosValue1;
                Value2 += PosValue2;
                Value3 += PosValue3;
            until Position.Next() = 0;

        exit(DetailValueExists(Value1, Value2, Value3));
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

