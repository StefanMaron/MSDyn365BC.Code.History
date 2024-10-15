report 17457 "Pay Sheet T-53"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Paysheet T-53';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempPerson.FindFirst
                else
                    TempPerson.Next;

                with GenJnlLine do begin
                    SetRange("Journal Template Name", TemplateName);
                    SetRange("Journal Batch Name", BatchName);
                    SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                    SetRange("Account Type", "Account Type"::Vendor);
                    SetRange("Account No.", TempPerson."Vendor No.");
                    if FindSet then
                        repeat
                            FillRow(Amount);
                        until Next() = 0;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if TotalAmount <> 0 then begin
                    LocMgt.Amount2Text2('', TotalAmount, WholeAmountText, HundredAmount);
                    ExcelMgt.FillCell('H14', WholeAmountText);
                    ExcelMgt.FillCell('BD16', Format(HundredAmount));
                    ExcelMgt.FillCell('BQ16', Format(Round(TotalAmount, 1, '<')));
                    ExcelMgt.FillCell('CL16', Format(HundredAmount));
                end;

                if Counter >= TemplateRowsQty then
                    ExcelMgt.DeleteRows(RowNo, RowNo);
            end;

            trigger OnPreDataItem()
            begin
                FillInEmployeeList;

                SetRange(Number, 1, TempPerson.Count);
                Counter := 1;
                RowNo := 31;
                TemplateRowsQty := 33;

                TempPerson.SetCurrentKey("Last Name", "First Name");
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
                    field(TemplateName; TemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Template Name';
                        TableRelation = "Gen. Journal Template" WHERE(Type = CONST(Payments));

                        trigger OnValidate()
                        begin
                            if PrevTemplateName <> TemplateName then
                                BatchName := '';

                            PrevTemplateName := TemplateName;
                        end;
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Batch Name';
                        ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupBatch;
                        end;
                    }
                    field(PeriodStartDate; PeriodStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date of Period';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';

                        trigger OnValidate()
                        begin
                            PeriodStartDateOnAfterValidate;
                        end;
                    }
                    field(PeriodEndDate; PeriodEndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date of Period';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
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
            PeriodEndDate := CalcDate('<-1M + CM>', WorkDate);
            PeriodStartDate := CalcDate('<-CM>', PeriodEndDate);
            DocNo := CopyStr(Format(Date2DMY(PeriodStartDate, 3)), 3, 2) +
              Format(Date2DMY(PeriodStartDate, 2)) + '-';
            if HiddenTemplateName <> '' then
                TemplateName := HiddenTemplateName;

            if HiddenBatchName <> '' then
                BatchName := HiddenBatchName;

            RequestOptionsPage.Update;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
          ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResSetup."T-53 Template Code"))
        else
          ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        if PeriodStartDate = 0D then
            Error(Text14800);
        if PeriodEndDate = 0D then
            Error(Text14801);

        CompanyInfo.Get();

        HumanResSetup.Get();
        HumanResSetup.TestField("T-53 Template Code");

        if PreviewMode then
            DocNo := 'XXXXXXXXXX'
        else begin
            HumanResSetup.TestField("Calculation Sheet Nos.");
            DocNo := NoSeriesMgt.GetNextNo(HumanResSetup."Calculation Sheet Nos.", WorkDate, true);
        end;

        FileName := ExcelTemplate.OpenTemplate(HumanResSetup."T-53 Template Code");
        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('Sheet1');
        ExcelMgt.FillCell('A7', LocalReportMgt.GetCompanyName);
        if DepartmentName <> '' then
            ExcelMgt.FillCell('A9', DepartmentName);
        ExcelMgt.FillCell('CP7', CompanyInfo."OKPO Code");

        ExcelMgt.FillCell('AX26', DocNo);
        ExcelMgt.FillCell('BN26', Format(Today));
        ExcelMgt.FillCell('CG26', Format(PeriodStartDate));
        ExcelMgt.FillCell('CS26', Format(PeriodEndDate));

        if CompanyInfo."Director No." <> '' then begin
            Employee.Get(CompanyInfo."Director No.");
            ExcelMgt.FillCell('AA18', Employee.GetJobTitleName);
            ExcelMgt.FillCell('BQ18', Employee.GetNameInitials);
        end;

        if CompanyInfo."Accountant No." <> '' then begin
            Employee.Get(CompanyInfo."Accountant No.");
            ExcelMgt.FillCell('AO20', Employee.GetNameInitials);
        end;
    end;

    var
        Text14800: Label 'Please enter Period Start Date.';
        Text14801: Label 'Please enter Period End Date.';
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        ExcelTemplate: Record "Excel Template";
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        TempPerson: Record Person temporary;
        LocMgt: Codeunit "Localisation Management";
        LocalReportMgt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PeriodEndDate: Date;
        PeriodStartDate: Date;
        FileName: Text[1024];
        WholeAmountText: Text[1024];
        DepartmentName: Text[250];
        DocNo: Code[20];
        TemplateName: Code[10];
        PrevTemplateName: Code[10];
        BatchName: Code[10];
        HiddenTemplateName: Code[10];
        HiddenBatchName: Code[10];
        Counter: Integer;
        PreviewMode: Boolean;
        RowNo: Integer;
        TemplateRowsQty: Integer;
        TotalAmount: Decimal;
        HundredAmount: Decimal;
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure FillCell(ColumnCode: Code[10]; Amount: Decimal)
    begin
        if Amount <> 0 then
            ExcelMgt.FillCell(ColumnCode + Format(RowNo), Format(Amount));
    end;

    [Scope('OnPrem')]
    procedure FillInEmployeeList()
    var
        Person: Record Person;
        PersonNo: Code[20];
    begin
        with GenJnlLine do begin
            SetRange("Journal Template Name", TemplateName);
            SetRange("Journal Batch Name", BatchName);
            SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
            SetRange("Account Type", "Account Type"::Vendor);
            if FindSet then
                repeat
                    if FindPersonNo("Account No.", PersonNo) then
                        if not TempPerson.Get(PersonNo) then begin
                            Person.Get(PersonNo);
                            TempPerson := Person;
                            TempPerson.Insert();
                        end;
                until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure FindPersonNo(VendorNo: Code[20]; var PersonNo: Code[20]): Boolean
    var
        Person: Record Person;
    begin
        Person.SetRange("Vendor No.", VendorNo);
        if Person.FindFirst then begin
            PersonNo := Person."No.";
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FillRow(AmountToPay: Decimal)
    begin
        if Counter >= TemplateRowsQty then
            ExcelMgt.CopyRow(RowNo);

        ExcelMgt.FillCell('A' + Format(RowNo), Format(Counter));
        ExcelMgt.FillCell('J' + Format(RowNo), TempPerson."No.");
        ExcelMgt.FillCell('V' + Format(RowNo), TempPerson.GetNameInitials);
        FillCell('BF', AmountToPay);

        RowNo += 1;
        Counter += 1;

        TotalAmount := TotalAmount + AmountToPay;
    end;

    [Scope('OnPrem')]
    procedure LookupBatch()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if TemplateName = '' then
            exit;

        GenJnlBatch."Journal Template Name" := TemplateName;
        GenJnlBatch.Name := BatchName;
        GenJnlBatch.FilterGroup(2);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
            BatchName := GenJnlBatch.Name;
    end;

    [Scope('OnPrem')]
    procedure SetParameters(NewTemplateName: Code[10]; NewBatchName: Code[10])
    begin
        TemplateName := NewTemplateName;
        PrevTemplateName := NewTemplateName;
        BatchName := NewBatchName;
        HiddenTemplateName := NewTemplateName;
        HiddenBatchName := NewBatchName;
    end;

    local procedure PeriodStartDateOnAfterValidate()
    begin
        PeriodEndDate := CalcDate('<CM>', PeriodStartDate);
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

