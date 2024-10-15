report 17354 "Personal Account T-54a"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Personal Account T-54a';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.", "Org. Unit Code", Status;

            trigger OnAfterGetRecord()
            var
                i: Integer;
            begin
                Person.Get("Person No.");

                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('Sheet1');

                ExcelMgt.FillCell('A7', CompanyInfo.Name);
                ExcelMgt.FillCell('FJ7', CompanyInfo."OKPO Code");
                ExcelMgt.FillCell('A9', "Org. Unit Name");
                ExcelMgt.FillCell('Z13', GetFullName);
                ExcelMgt.FillCell('DV13', "No.");
                ExcelMgt.FillCell('FJ13', Format("Birth Date"));
                ExcelMgt.FillCell('BF18', ''); // document no.
                ExcelMgt.FillCell('BZ18', Format(FromDate));
                ExcelMgt.FillCell('CI18', Format(ToDate));
                ExcelMgt.FillCell('CR18', "Category Code");
                ExcelMgt.FillCell('DU18', Person."Social Security No.");
                ExcelMgt.FillCell('DH18', Person."VAT Registration No.");

                AltAddr.Reset();
                AltAddr.SetRange("Person No.", Employee."No.");
                AltAddr.SetRange("Address Type", AltAddr."Address Type"::Registration);
                if AltAddr.FindFirst then;

                ExcelMgt.FillCell('EK18', AltAddr."Region Code");
                ExcelMgt.FillCell('EU18', Format(Person."Family Status"));
                ExcelMgt.FillCell('FE18', Format(Person.ChildrenNumber(DateComposition)));
                ExcelMgt.FillCell('FL18', Format(Employee."Employment Date"));
                ExcelMgt.FillCell('FT18', Format(Employee."Termination Date"));

                // Footer
                ExcelMgt.FillCell('CR33', Format(DSDay));
                ExcelMgt.FillCell('CY33', Format(DSMonth));
                ExcelMgt.FillCell('DW33', CopyStr(Format(DSYear), 3, 2));

                // Employee Job Entry
                EmployeeJobEntry.Reset();
                EmployeeJobEntry.SetCurrentKey("Employee No.");
                EmployeeJobEntry.SetRange("Employee No.", "No.");
                EmployeeJobEntry.SetFilter("Position No.", '<>%1', '');
                if (FromDate <> 0D) and (ToDate <> 0D) then
                    EmployeeJobEntry.SetRange("Starting Date", FromDate, ToDate);
                EmployeeJobEntry.SetRange("Position Changed", true);

                // Employee Vacation Entry
                EmplAbsenceEntry.Reset();
                EmplAbsenceEntry.SetCurrentKey("Employee No.");
                EmplAbsenceEntry.SetRange("Employee No.", "No.");
                EmplAbsenceEntry.SetRange("Entry Type", EmplAbsenceEntry."Entry Type"::Usage);

                if EmployeeJobEntry.Count > EmplAbsenceEntry.Count then
                    ExpandExcelTable(EmployeeJobEntry.Count)
                else
                    ExpandExcelTable(EmplAbsenceEntry.Count);

                i := 25;
                if EmployeeJobEntry.FindSet then
                    repeat
                        Position.Get(EmployeeJobEntry."Position No.");
                        ExcelMgt.FillCell(StrSubstNo('J%1', i), EmployeeJobEntry."Document No.");
                        ExcelMgt.FillCell(StrSubstNo('A%1', i), Format(EmployeeJobEntry."Document Date"));
                        ExcelMgt.FillCell(StrSubstNo('S%1', i), EmployeeJobEntry."Org. Unit Code");
                        ExcelMgt.FillCell(StrSubstNo('AL%1', i), EmployeeJobEntry."Job Title Code");
                        ExcelMgt.FillCell(StrSubstNo('BB%1', i), Format(EmployeeJobEntry."Conditions of Work"));
                        ExcelMgt.FillCell(StrSubstNo('BL%1', i), Format(Position."Base Salary Amount"));
                        ExcelMgt.FillCell(StrSubstNo('CD%1', i), Format(Position."Additional Salary Amount"));
                        i := i + 1;
                    until EmployeeJobEntry.Next() = 0;

                i := 25;
                if EmplAbsenceEntry.FindSet then
                    repeat
                        ExcelMgt.FillCell(StrSubstNo('CV%1', i), EmplAbsenceEntry."Time Activity Code");
                        ExcelMgt.FillCell(StrSubstNo('DE%1', i), Format(EmplAbsenceEntry."HR Order Date"));
                        ExcelMgt.FillCell(StrSubstNo('DN%1', i), EmplAbsenceEntry."HR Order No.");
                        if EmplAbsenceEntry."Accrual Entry No." <> 0 then begin
                            EmplAbsenceEntry2.Get(EmplAbsenceEntry."Accrual Entry No.");
                            ExcelMgt.FillCell(StrSubstNo('DW%1', i), Format(EmplAbsenceEntry2."Start Date"));
                            ExcelMgt.FillCell(StrSubstNo('EE%1', i), Format(EmplAbsenceEntry2."End Date"));
                        end;
                        ExcelMgt.FillCell(StrSubstNo('EM%1', i), Format(EmplAbsenceEntry."Calendar Days"));
                        ExcelMgt.FillCell(StrSubstNo('EW%1', i), Format(EmplAbsenceEntry."Start Date"));
                        ExcelMgt.FillCell(StrSubstNo('FE%1', i), Format(EmplAbsenceEntry."End Date"));
                        ExcelMgt.FillCell(StrSubstNo('FM%1', i), Format(0)); // tax benefit total amount

                        i := i + 1;
                    until EmplAbsenceEntry.Next() = 0;

                // Deductions
                ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-54a Template Code"));
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                if GetRangeMin("No.") <> GetRangeMax("No.") then
                    Error(Text14800);
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
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the starting date.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Date';
                        ToolTip = 'Specifies a search method. If you select To Date, and there is no currency exchange rate on a certain date, the exchange rate for the nearest date is used.';
                    }
                    field(DateComposition; DateComposition)
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
            DateComposition := Today;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if DateComposition = 0D then
            Error(Text14801);

        DSDay := Format(Date2DMY(DateComposition, 1));
        DSMonth := Format(Date2DMY(DateComposition, 2));
        DSYear := Format(Date2DMY(DateComposition, 3));
        if StrLen(DSDay) < 2 then
            DSDay := '0' + DSDay;
        if StrLen(DSMonth) < 2 then
            DSMonth := '0' + DSMonth;

        HumanResSetup.Get();
        HumanResSetup.TestField("T-54a Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."T-54a Template Code");
    end;

    var
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        Person: Record Person;
        Position: Record Position;
        AltAddr: Record "Alternative Address";
        EmployeeJobEntry: Record "Employee Job Entry";
        EmplAbsenceEntry: Record "Employee Absence Entry";
        EmplAbsenceEntry2: Record "Employee Absence Entry";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        FileName: Text[1024];
        DateComposition: Date;
        DSDay: Code[2];
        DSMonth: Code[2];
        DSYear: Code[4];
        FromDate: Date;
        ToDate: Date;
        Text14800: Label 'You can select one employee only.';
        Text14801: Label 'You must enter Creation Date.';

    [Scope('OnPrem')]
    procedure ExpandExcelTable(QtyRowsToCopy: Integer)
    var
        I: Integer;
        FirstRowNo: Integer;
    begin
        FirstRowNo := 25;
        for I := FirstRowNo to FirstRowNo + QtyRowsToCopy - 1 do
            ExcelMgt.CopyRow(FirstRowNo);
    end;
}

