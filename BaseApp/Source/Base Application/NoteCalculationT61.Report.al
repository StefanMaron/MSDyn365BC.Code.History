report 17361 "Note-Calculation T-61"
{
    Caption = 'Note-Calculation T-61';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Absence Header"; "Absence Header")
        {

            trigger OnAfterGetRecord()
            var
                PostedAbsenceHeader: Record "Posted Absence Header";
            begin
                FillEmployeeInfo("Employee No.");
                PostedAbsenceHeader.TransferFields("Absence Header");
            end;

            trigger OnPreDataItem()
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('Sheet1');
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
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(CreateDate; CreateDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Date';
                    }
                    field(PaymentSheetNo; PaymentSheetNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Sheet No.';
                    }
                    field(PaymentSheetDate; PaymentSheetDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payment Sheet Date';
                    }
                    field(TaxIncome; TaxIncome)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tax Income';
                    }
                    field(TaxPercent; TaxPercent)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tax Percent';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CreateDate := WorkDate;
            TaxIncome := false;
            TaxPercent := 13;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumResSetup."T-61 Template Code"));
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get;

        HumResSetup.Get;
        HumResSetup.TestField("T-61 Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumResSetup."T-61 Template Code");
    end;

    var
        ExcelTemplate: Record "Excel Template";
        HumResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        ExcelMgt: Codeunit "Excel Management";
        LocMgt: Codeunit "Localisation Management";
        TaxIncome: Boolean;
        TaxPercent: Integer;
        PaymentSheetNo: Code[10];
        PaymentSheetDate: Date;
        DocumentNo: Code[20];
        CreateDate: Date;
        FileName: Text[1024];

    [Scope('OnPrem')]
    procedure FillEmployeeInfo(EmployeeNo: Code[20])
    var
        LaborContracts: Record "Labor Contract";
        HRManager: Record Employee;
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);
        with Employee do begin
            ExcelMgt.FillCell('A7', CompanyInfo.Name + ' ' + CompanyInfo."Name 2");
            ExcelMgt.FillCell('DA7', CompanyInfo."OKPO Code");

            ExcelMgt.FillCell('DA8', "Contract No.");
            if LaborContracts.Get("Contract No.") then;
            ExcelMgt.FillCell('DA9', Format(LaborContracts."Starting Date"));

            ExcelMgt.FillCell('BO13', DocumentNo);
            ExcelMgt.FillCell('CE13', Format(CreateDate));

            ExcelMgt.FillCell('A17', GetFullName);
            ExcelMgt.FillCell('CW17', "No.");

            ExcelMgt.FillCell('A19', "Org. Unit Name");
            ExcelMgt.FillCell('A21', "Job Title");

            FillDismissalLineInfo("Contract No.");

            ExcelMgt.FillCell('CF28', LocMgt.Date2Text(LaborContracts."Starting Date"));
            ExcelMgt.FillCell('CF29', LocMgt.Date2Text(LaborContracts."Ending Date"));

            if HRManager.Get(CompanyInfo."HR Manager No.") then begin
                ExcelMgt.FillCell('AF30', HRManager."Job Title");
                ExcelMgt.FillCell('CI30', HRManager.GetNameInitials);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDismissalLineInfo(ContractNo: Code[20])
    var
        LaborContractLines: Record "Labor Contract Line";
        GroundsforTermination: Record "Grounds for Termination";
    begin
        LaborContractLines.SetRange("Contract No.", ContractNo);
        LaborContractLines.SetRange("Operation Type", LaborContractLines."Operation Type"::Dismissal);
        if LaborContractLines.FindFirst then
            ExcelMgt.FillCell('CE23', LocMgt.Date2Text(LaborContractLines."Starting Date"));

        if GroundsforTermination.Get(LaborContractLines."Dismissal Reason") then;
        ExcelMgt.FillCell('A24', LaborContractLines.Description);

        ExcelMgt.FillCell('AM26', LocMgt.Date2Text(LaborContractLines."Order Date"));
        ExcelMgt.FillCell('CM26', LaborContractLines."Order No.");
    end;
}

