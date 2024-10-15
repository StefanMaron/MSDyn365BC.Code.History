page 15000009 "Return File Setup List"
{
    AutoSplitKey = true;
    Caption = 'Return File Setup List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Return File Setup";

    layout
    {
        area(content)
        {
            repeater(Control1080000)
            {
                ShowCaption = false;
                field(FileName; FileName)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the return file.';

                    trigger OnAssistEdit()
                    begin
                        ComDlgFilename :=
                            CopyStr(FileMgt.UploadFile(CopyStr(FieldCaption("Return File Name"), 1, 50), "Return File Name"), 1, 250);

                        if ComDlgFilename <> '' then begin
                            Validate("Return File Name", ComDlgFilename);
                            FileName := FileMgt.GetFileName(ComDlgFilename);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Validate("Return File Name", CopyStr(FileName, 1, MaxStrLen("Return File Name")));
                        FileName := FileMgt.GetFileName(FileName);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FileName := FileMgt.GetFileName("Return File Name");
    end;

    var
        FileMgt: Codeunit "File Management";
        ComDlgFilename: Text[250];
        FileName: Text;
}

