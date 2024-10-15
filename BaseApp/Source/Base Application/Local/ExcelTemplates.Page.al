page 14919 "Excel Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Excel Templates';
    PageType = List;
    SourceTable = "Excel Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for a Microsoft Excel template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of a Microsoft Excel template.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name for a Microsoft Excel template.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Import Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Template';
                    Ellipsis = true;
                    Image = ImportExcel;

                    trigger OnAction()
                    var
                        RecordRef: RecordRef;
                        TemplateExists: Boolean;
                    begin
                        TemplateExists := BLOB.HasValue;
                        Filename := FileMgt.BLOBImport(TempBlob, '*.xls');
                        if Filename = '' then
                            exit;
                        if TemplateExists then
                            if not Confirm(Text001, false, Code) then
                                exit;
                        TempBlob.ToRecordRef(RecordRef, FieldNo(BLOB));

                        UpdateTemplateHeight(Filename);

                        while StrPos(Filename, '\') <> 0 do
                            Filename := CopyStr(Filename, StrPos(Filename, '\') + 1);
                        "File Name" := CopyStr(Filename, 1, MaxStrLen("File Name"));
                        CurrPage.SaveRecord();
                    end;
                }
                action("E&xport Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport Template';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Export the template for use in another database.';

                    trigger OnAction()
                    begin
                        CalcFields(BLOB);
                        if BLOB.HasValue() then begin
                            TempBlob.FromRecord(Rec, FieldNo(BLOB));
                            FileMgt.BLOBExport(TempBlob, "File Name", true);
                        end;
                    end;
                }
                action("Delete Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Template';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        if BLOB.HasValue() then
                            if Confirm(Text002, false, Code) then begin
                                CalcFields(BLOB);
                                Clear(BLOB);
                                "File Name" := '';
                                CurrPage.SaveRecord();
                            end;
                    end;
                }
            }
        }
    }

    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        Text001: Label 'Do you want to replace the existing definition for template %1?';
        Text002: Label 'Do you want to delete the definition for template %1?';
        Filename: Text;
}

