page 26563 "Statutory Report Data Overview"
{
    Caption = 'Statutory Report Data Overview';
    PageType = Card;
    SourceTable = "Statutory Report Data Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the statutory report data header information.';
                }
                field(TableCode; TableCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Code';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(LookupTable(Text));
                    end;

                    trigger OnValidate()
                    begin
                        TableCodeOnAfterValidate;
                    end;
                }
                field(ExcelSheetName; ExcelSheetName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Excel Sheet Name';
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupExcelSheet;
                    end;

                    trigger OnValidate()
                    begin
                        ExcelSheetNameOnAfterValidate;
                    end;
                }
                field(ShowOnlyChangedValues; ShowOnlyChangedValues)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Only Changed Values';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Data';
                Image = ShowMatrix;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the related details.';

                trigger OnAction()
                var
                    StatReportDataSubform: Page "_Stat. Report Data Subform";
                    ScalableTableDataSubform: Page "_Scalable Table Data Subform";
                begin
                    StatutoryReportTable.Get("Report Code", TableCode);

                    if StatutoryReportTable."Scalable Table" then begin
                        ScalableTableDataSubform.InitParameters("No.", TableCode, ExcelSheetName, ShowOnlyChangedValues);
                        ScalableTableDataSubform.RunModal();
                    end else begin
                        StatReportDataSubform.InitParameters("No.", TableCode, ExcelSheetName, ShowOnlyChangedValues);
                        StatReportDataSubform.RunModal();
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        StatutoryReportTable.SetCurrentKey("Report Code", "Sequence No.");
        StatutoryReportTable.SetRange("Report Code", "Report Code");
        if StatutoryReportTable.FindFirst() then begin
            TableCode := StatutoryReportTable.Code;
            FindFirstExcelSheet(TableCode);
        end;
    end;

    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        TableCode: Code[20];
        ExcelSheetName: Text[30];
        ShowOnlyChangedValues: Boolean;

    [Scope('OnPrem')]
    procedure LookupTable(var EntrdTableCode: Text[1024]): Boolean
    var
        PrevTableCode: Code[20];
    begin
        PrevTableCode := TableCode;
        StatutoryReportTable.FilterGroup(2);
        StatutoryReportTable.SetRange("Report Code", "Report Code");
        StatutoryReportTable.FilterGroup(0);
        StatutoryReportTable.Code := TableCode;

        if PAGE.RunModal(0, StatutoryReportTable) <> ACTION::LookupOK then
            exit(false);

        EntrdTableCode := StatutoryReportTable.Code;
        if EntrdTableCode <> PrevTableCode then
            FindFirstExcelSheet(EntrdTableCode);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure LookupExcelSheet(): Boolean
    begin
        StatReportExcelSheet.SetRange("Report Data No.", "No.");
        StatReportExcelSheet.SetRange("Report Code", "Report Code");
        StatReportExcelSheet.SetRange("Table Code", TableCode);
        if PAGE.RunModal(0, StatReportExcelSheet) <> ACTION::LookupOK then
            exit(false);

        ExcelSheetName := StatReportExcelSheet."Sheet Name";
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FindFirstExcelSheet(NewTableCode: Code[20])
    begin
        StatReportExcelSheet.SetRange("Report Code", "Report Code");
        StatReportExcelSheet.SetRange("Table Code", NewTableCode);
        if StatReportExcelSheet.FindFirst() then
            ExcelSheetName := StatReportExcelSheet."Sheet Name";
    end;

    local procedure TableCodeOnAfterValidate()
    begin
        CurrPage.SaveRecord;
    end;

    local procedure ExcelSheetNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
    end;
}

