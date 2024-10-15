page 15000100 "OCR Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'OCR Setup';
    PageType = Card;
    SourceTable = "OCR Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Format; Format)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an OCR payment file format.';
                }
                field(FileName; OCRSetupFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'FileName';
                    ToolTip = 'Specifies the full path of the OCR payment file.';

                    trigger OnAssistEdit()
                    begin
                        ComDlgFilename := FileMgt.UploadFile(FieldCaption(FileName), FileName);
                        if ComDlgFilename <> '' then begin
                            Validate(FileName, ComDlgFilename);
                            OCRSetupFileName := FileMgt.GetFileName(ComDlgFilename);
                        end;
                    end;
                }
                field("Delete Return File"; "Delete Return File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to rename the file after import and prevent the file from being imported more than once.';
                }
            }
            group("Gen. Ledger")
            {
                Caption = 'Gen. Ledger';
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a balance account type.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a balance account.';
                }
                field("Max. Divergence"; "Max. Divergence")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a maximum divergence value.';
                }
                field("Divergence Account No."; "Divergence Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the divergence account number that will receive posting.';
                }
                field("Journal Template Name"; "Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template.';
                }
                field("Journal Name"; "Journal Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        OCRSetupFileName := FileMgt.GetFileName(FileName);
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;

    var
        FileMgt: Codeunit "File Management";
        ComDlgFilename: Text[200];
        OCRSetupFileName: Text;
}

