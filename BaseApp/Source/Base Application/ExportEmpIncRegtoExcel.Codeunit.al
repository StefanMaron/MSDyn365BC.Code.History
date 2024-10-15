codeunit 17373 "Export Emp. Inc. Reg. to Excel"
{

    trigger OnRun()
    begin
    end;

    var
        TempEmployee: Record Employee temporary;
        ExcelTemplate: Record "Excel Template";
        HumanResourcesSetup: Record "Human Resources Setup";
        ExcelMgt: Codeunit "Excel Management";
        ReportFileName: Text[250];
        RegisterNo: Text[30];
        TaxAgentName: Text[250];
        TaxAgentVATRegNo: Text[30];
        TaxAgentOKATO: Text[30];
        ReceiptDate: Date;
        GNICode: Text[30];
        ReportedYear: Integer;
        DataSign: Integer;

    [Scope('OnPrem')]
    procedure ExportRegisterToExcel()
    begin
        OpenBook;

        FillHeaderSection;

        FillBodySection;

        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanResourcesSetup."NDFL Register Template Code"));
    end;

    [Scope('OnPrem')]
    procedure OpenBook()
    var
        FileName: Text;
    begin
        HumanResourcesSetup.Get;
        HumanResourcesSetup.TestField("NDFL Register Template Code");
        FileName := ExcelTemplate.OpenTemplate(HumanResourcesSetup."NDFL Register Template Code");

        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('ï¿ßÔ1');
    end;

    [Scope('OnPrem')]
    procedure FillHeaderSection()
    begin
        ExcelMgt.FillCell('ReportedYear', Format(ReportedYear));
        ExcelMgt.FillCell('RegisterNo', RegisterNo);
        ExcelMgt.FillCell('ReceiptDate', Format(ReceiptDate));
        ExcelMgt.FillCell('GNICode', GNICode);
        ExcelMgt.FillCell('FileName', ReportFileName);
        ExcelMgt.FillCell('TaxAgentName', TaxAgentName);
        ExcelMgt.FillCell('TaxAgentVATRegNo', TaxAgentVATRegNo);
        ExcelMgt.FillCell('TaxAgentOKATO', TaxAgentOKATO);
        ExcelMgt.FillCell('DataSign', Format(DataSign));
        ExcelMgt.FillCell('DocumentsQty', Format(TempEmployee.Count));
    end;

    [Scope('OnPrem')]
    procedure FillBodySection()
    var
        Employee: Record Employee;
        CurrRowNo: Integer;
    begin
        CurrRowNo := 33;

        if TempEmployee.FindSet then
            repeat
                if CurrRowNo > 34 then
                    ExcelMgt.CopyRow(CurrRowNo);
                Employee.Get(TempEmployee."Manager No.");

                ExcelMgt.FillCell('A' + Format(CurrRowNo), TempEmployee."No.");
                ExcelMgt.FillCell('Z' + Format(CurrRowNo), Employee.GetFullName);
                ExcelMgt.FillCell('BW' + Format(CurrRowNo), Format(Employee."Birth Date"));

                CurrRowNo := CurrRowNo + 1;
            until TempEmployee.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure SetParameters(NewReportFileName: Text[250]; NewTaxAgentName: Text[250]; NewTaxAgentVATRegNo: Text[30]; NewTaxAgentOKATO: Text[30]; NewRegisterNo: Text[30]; NewReceiptDate: Date; NewGNICode: Text[30]; NewReportedYear: Integer; NewDataSign: Integer)
    begin
        ReportFileName := NewReportFileName;
        RegisterNo := NewRegisterNo;
        TaxAgentName := NewTaxAgentName;
        TaxAgentVATRegNo := NewTaxAgentVATRegNo;
        TaxAgentOKATO := NewTaxAgentOKATO;
        ReceiptDate := NewReceiptDate;
        GNICode := NewGNICode;
        ReportedYear := NewReportedYear;
        DataSign := NewDataSign;
    end;

    [Scope('OnPrem')]
    procedure AddEmployee(EmployeeNo: Code[20]; RefNo: Text[30])
    begin
        if not TempEmployee.Get(RefNo) then begin
            TempEmployee.Init;
            TempEmployee."No." := RefNo;
            TempEmployee."Manager No." := EmployeeNo;
            TempEmployee.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure BufferIsEmpty(): Boolean
    begin
        exit(TempEmployee.IsEmpty);
    end;
}

