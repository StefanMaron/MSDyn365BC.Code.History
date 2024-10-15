page 15000008 "Return Files"
{
    AutoSplitKey = true;
    Caption = 'Return Files';
    PageType = List;
    SourceTable = "Return File";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Import; Import)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the return file from the bank is imported, if checked.';
                }
                field(FileName; FileName)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the return file.';

                    trigger OnAssistEdit()
                    begin
                        ComDlgFilename := CopyStr(FileMgt.OpenFileDialog(CopyStr(FieldCaption("File Name"), 1, 50), "File Name", ''), 1, 250);

                        if ComDlgFilename <> '' then begin
                            Validate("File Name", ComDlgFilename);
                            FileName := FileMgt.GetFileName(ComDlgFilename);
                        end;
                    end;
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line date of the return file.';
                }
                field(Time; Time)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time of the return file.';
                }
                field(Size; Size)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the return file.';
                }
                field(Format; Format)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the return file.';
                }
                field("<Agreement Code>"; "Agreement Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Agreement Code';
                    ToolTip = 'Specifies the agreement code that is associated with the return file.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FileName := FileMgt.GetFileName("File Name");
    end;

    var
        FileMgt: Codeunit "File Management";
        ComDlgFilename: Text[250];
        FileName: Text;
}

