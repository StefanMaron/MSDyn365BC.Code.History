page 2180 "O365 Import from Excel Wizard"
{
    Caption = 'Import from Excel Wizard';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = NavigatePage;
    SourceTable = "O365 Field Excel Mapping";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Step1)
            {
                Caption = 'Step 1';
                Visible = Step1Visible;
                group("Specify the Excel file name")
                {
                    Caption = 'Specify the Excel file name';
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Excel File Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the Excel file that contains the data to import.';

                        trigger OnAssistEdit()
                        begin
                            OpenExcelFile;
                        end;
                    }
                    field(SheetName; SheetName)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Excel Sheet Name';
                        Editable = false;
                        ToolTip = 'Specifies the Excel sheet name to be imported from.';

                        trigger OnAssistEdit()
                        begin
                            if FileName = '' then
                                exit;

                            SelectAndReadSheet;
                        end;
                    }
                    field(DataHasHeaders; DataHasHeaders)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Data has headers';
                        ToolTip = 'Specifies whether the Excel sheet contains column headers as the first row.';
                    }
                }
            }
            group(Step2)
            {
                Caption = 'Step 2';
                Visible = Step2Visible;
                group("Enter the Excel row number to start import from")
                {
                    Caption = 'Enter the Excel row number to start import from';
                    field(StartRowNo; StartRowNo)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Start Row Number';
                        MinValue = 0;
                        ToolTip = 'Specifies the first Excel row number with data to be imported.';

                        trigger OnValidate()
                        begin
                            ValidateStartRowNo(StartRowNo);
                        end;
                    }
                    part(ExcelSheetDataSubPage; "O365 Excel Sheet Data SubPage")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Excel Sheet Data';
                    }
                }
            }
            group(Step3)
            {
                Caption = 'Step 3';
                Visible = Step3Visible;
                group("Choose the Excel column number for each field you would like to import")
                {
                    Caption = 'Choose the Excel column number for each field you would like to import';
                    repeater(Control16)
                    {
                        ShowCaption = false;
                        field("Field Name"; "Field Name")
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            Editable = false;
                            StyleExpr = Style;
                            ToolTip = 'Specifies the field name that the Excel column maps to.';
                        }
                        field("Excel Column No."; "Excel Column No.")
                        {
                            ApplicationArea = Basic, Suite, Invoicing;
                            MinValue = 0;
                            ToolTip = 'Specifies the Excel column number that the field name maps to.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupColumn;
                                CurrPage.SaveRecord;
                                NextEnabled := DoesMappingExist;
                            end;

                            trigger OnValidate()
                            begin
                                CheckMaxAllowedExcelColumnNo;
                                CurrPage.SaveRecord;
                                NextEnabled := DoesMappingExist;
                            end;
                        }
                    }
                    part(ExcelSheetDataSubPage2; "O365 Excel Sheet Data SubPage")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Excel Sheet Data';
                    }
                }
            }
            group(Step4)
            {
                Caption = 'Step 4';
                Visible = Step4Visible;
                group(Preview)
                {
                    Caption = 'Preview';
                    part(ExcelSheetDataSubPage3; "O365 Excel Sheet Data SubPage")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Excel Sheet Data';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    OnActionFinish;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Style := SetStyle;
    end;

    trigger OnOpenPage()
    begin
        ResetWizardControls;
        ShowFirstStep;
        SetSubpagesUseEmphasizing;
        DataHasHeaders := true;
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempStartRowCellNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileMgt: Codeunit "File Management";
        O365ExcelImportMgt: Codeunit "O365 Excel Import Management";
        FileName: Text;
        ServerFileName: Text;
        SheetName: Text[250];
        Style: Text;
        StartRowNo: Integer;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step4Visible: Boolean;
        DataHasHeaders: Boolean;
        Step: Option "Step 1","Step 2","Step 3","Step 4";
        ImportExcelFileTxt: Label 'Import Excel File ';
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        ImportResultMsg: Label '%1 record(s) sucessfully imported.', Comment = '%1 - number';
        StartRowNoOverLimitErr: Label 'The start row number cannot be greater than %1.', Comment = '%1 - number';
        ImportCustomersFromExcelWizardTxt: Label 'Import customers from Excel';
        ImportItemsFromExcelWizardTxt: Label 'Import prices from Excel';
        ObjType: Option Customer,Item;
        NoDataOnTheExcelSheetMsg: Label 'There is no data in the Excel sheet %1.', Comment = '%1 - name of the Excel sheet';
        ColumnNoOverLimitErr: Label 'The Excel column number cannot be greater than %1.', Comment = '%1 - number';

    local procedure NextStep(Backwards: Boolean)
    begin
        ResetWizardControls;

        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::"Step 1":
                ShowFirstStep;
            Step::"Step 2":
                ShowSecondStep;
            Step::"Step 3":
                ShowThirdStep;
            Step::"Step 4":
                ShowFinalStep;
        end;

        CurrPage.Update(false);
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        Step1Visible := false;
        Step2Visible := false;
        Step3Visible := false;
        Step4Visible := false;
    end;

    local procedure ShowFirstStep()
    begin
        Step1Visible := true;
        BackEnabled := false;
        NextEnabled := SheetName <> '';
    end;

    local procedure ShowSecondStep()
    begin
        Step2Visible := true;
        NextEnabled := StartRowNo <> 0;
        if TempExcelBuffer.IsEmpty then
            Message(NoDataOnTheExcelSheetMsg, SheetName);

        if StartRowNo = 0 then begin
            if DataHasHeaders then
                if O365ExcelImportMgt.AutomapColumns(Rec, TempExcelBuffer) then
                    ValidateStartRowNo(2);

            if not DataHasHeaders then
                ValidateStartRowNo(1);
        end;
    end;

    local procedure ShowThirdStep()
    begin
        FillStartRowCellBuffer;
        Step3Visible := true;
        BackEnabled := true;
        NextEnabled := DoesMappingExist;
        FinishEnabled := false;
    end;

    local procedure ShowFinalStep()
    var
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
    begin
        TempO365FieldExcelMapping := Rec;
        CurrPage.ExcelSheetDataSubPage3.PAGE.SetColumnMapping(Rec);
        Rec := TempO365FieldExcelMapping;
        CurrPage.ExcelSheetDataSubPage3.PAGE.SetColumnVisibility;
        CurrPage.ExcelSheetDataSubPage3.PAGE.SetRowNoFilter;
        Step4Visible := true;
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure OpenExcelFile()
    var
        PrevServerFileName: Text;
    begin
        PrevServerFileName := ServerFileName;
        ServerFileName := FileMgt.UploadFile(ImportExcelFileTxt, ExcelFileExtensionTok);
        if ServerFileName = '' then begin
            if PrevServerFileName <> '' then
                ServerFileName := PrevServerFileName;
            exit;
        end;

        SelectAndReadSheet;
    end;

    local procedure ReadSheet()
    begin
        TempExcelBuffer.OpenBook(ServerFileName, SheetName);
        TempExcelBuffer.ReadSheet;
    end;

    local procedure ClearTempExcelBuffer()
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
    end;

    local procedure SelectAndReadSheet()
    var
        PrevSheetName: Text[250];
    begin
        PrevSheetName := SheetName;
        SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
        if SheetName = '' then begin
            if PrevSheetName <> '' then
                SheetName := PrevSheetName;
            exit;
        end;
        FileName := FileMgt.GetFileName(ServerFileName);
        ClearTempExcelBuffer;
        ReadSheet;
        SendExcelBufferToSubpages;
        NextEnabled := true;
    end;

    local procedure SendExcelBufferToSubpages()
    begin
        CurrPage.ExcelSheetDataSubPage.PAGE.SetExcelBuffer(TempExcelBuffer);
        CurrPage.ExcelSheetDataSubPage2.PAGE.SetExcelBuffer(TempExcelBuffer);
        CurrPage.ExcelSheetDataSubPage3.PAGE.SetExcelBuffer(TempExcelBuffer);
    end;

    local procedure SendStartRowNoToSubpages()
    begin
        CurrPage.ExcelSheetDataSubPage.PAGE.SetStartRowNo(StartRowNo);
        CurrPage.ExcelSheetDataSubPage2.PAGE.SetStartRowNo(StartRowNo);
        CurrPage.ExcelSheetDataSubPage3.PAGE.SetStartRowNo(StartRowNo);
    end;

    local procedure FillStartRowCellBuffer()
    var
        i: Integer;
    begin
        TempStartRowCellNameValueBuffer.Reset();
        TempStartRowCellNameValueBuffer.DeleteAll();

        if StartRowNo = 0 then
            exit;

        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", StartRowNo);
        if TempExcelBuffer.FindSet then
            repeat
                i += 1;
                TempStartRowCellNameValueBuffer.ID := i;
                TempStartRowCellNameValueBuffer.Name :=
                  CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(TempStartRowCellNameValueBuffer.Name));
                TempStartRowCellNameValueBuffer.Insert();
            until TempExcelBuffer.Next = 0;
    end;

    procedure PrepareCustomerImportData()
    begin
        ObjType := ObjType::Customer;
        O365ExcelImportMgt.FillCustomerFieldsMappingBuffer(Rec);
        CurrPage.Caption := ImportCustomersFromExcelWizardTxt;
    end;

    procedure PrepareItemImportData()
    begin
        ObjType := ObjType::Item;
        O365ExcelImportMgt.FillItemFieldsMappingBuffer(Rec);
        CurrPage.Caption := ImportItemsFromExcelWizardTxt;
    end;

    local procedure DoesMappingExist() MappingExists: Boolean
    var
        TempO365FieldExcelMapping: Record "O365 Field Excel Mapping" temporary;
    begin
        TempO365FieldExcelMapping := Rec;
        SetFilter("Excel Column No.", '<>%1', 0);
        MappingExists := not IsEmpty;
        Reset;
        Rec := TempO365FieldExcelMapping;
        CurrPage.Update(false);
    end;

    local procedure LookupColumn()
    var
        O365ExcelColumns: Page "O365 Excel Columns";
    begin
        O365ExcelColumns.SetStartRowCellBuffer(TempStartRowCellNameValueBuffer);
        O365ExcelColumns.LookupMode(true);
        if O365ExcelColumns.RunModal = ACTION::LookupOK then begin
            O365ExcelColumns.GetRecord(TempStartRowCellNameValueBuffer);
            Validate("Excel Column No.", TempStartRowCellNameValueBuffer.ID);
            CheckMaxAllowedExcelColumnNo;
        end;
    end;

    local procedure OnActionFinish()
    var
        O365ExcelImportManagement: Codeunit "O365 Excel Import Management";
        ImportedRecordsQty: Integer;
    begin
        ImportedRecordsQty := O365ExcelImportManagement.ImportData(TempExcelBuffer, Rec, StartRowNo, ObjType);
        CurrPage.Close;
        if ImportedRecordsQty > 0 then
            Message(ImportResultMsg, ImportedRecordsQty);
    end;

    local procedure SetStyle(): Text
    begin
        if "Excel Column No." = 0 then
            exit('');

        exit('Strong');
    end;

    [Scope('OnPrem')]
    procedure SetParameters(var NewExcelBuffer: Record "Excel Buffer"; NewExcelSheetName: Text[250])
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        if NewExcelBuffer.FindSet then
            repeat
                TempExcelBuffer := NewExcelBuffer;
                TempExcelBuffer.Insert();
            until NewExcelBuffer.Next = 0;

        SheetName := NewExcelSheetName;

        SendExcelBufferToSubpages;
    end;

    local procedure ValidateStartRowNo(NewStartRowNo: Integer)
    begin
        StartRowNo := NewStartRowNo;
        CheckMaxAllowedStartRowNo;
        FillStartRowCellBuffer;
        SendStartRowNoToSubpages;
        CurrPage.Update(false);
        NextEnabled := StartRowNo <> 0;
    end;

    local procedure SetSubpagesUseEmphasizing()
    begin
        CurrPage.ExcelSheetDataSubPage.PAGE.SetUseEmphasizing;
        CurrPage.ExcelSheetDataSubPage2.PAGE.SetUseEmphasizing;
    end;

    local procedure CheckMaxAllowedStartRowNo()
    var
        MaxExcelRowNo: Integer;
    begin
        MaxExcelRowNo := GetMaxExcelRowNo;
        if StartRowNo > MaxExcelRowNo then
            Error(StartRowNoOverLimitErr, MaxExcelRowNo);
    end;

    local procedure CheckMaxAllowedExcelColumnNo()
    var
        MaxColumnNo: Integer;
    begin
        MaxColumnNo := GetMaxExcelExcelColumnNo;
        if "Excel Column No." > MaxColumnNo then
            Error(ColumnNoOverLimitErr, MaxColumnNo);
    end;

    local procedure GetMaxExcelRowNo(): Integer
    begin
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast then;
        exit(TempExcelBuffer."Row No.");
    end;

    local procedure GetMaxExcelExcelColumnNo(): Integer
    begin
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast then;
        exit(TempExcelBuffer."Column No.");
    end;
}

