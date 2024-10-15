page 26571 "Report Export Log"
{
    Caption = 'Report Export Log';
    Editable = false;
    PageType = List;
    SourceTable = "Export Log Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the export log entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the export log entry.';
                }
                field("Report Data No."; Rec."Report Data No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report data number associated with the export log entry.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name associated with the export log entry.';
                }
                field("Export Date"; Rec."Export Date")
                {
                    ToolTip = 'Specifies the export date of the export log entry.';
                    Visible = false;
                }
                field("Export Time"; Rec."Export Time")
                {
                    ToolTip = 'Specifies the export time of the export log entry.';
                    Visible = false;
                }
                field("Sender No."; Rec."Sender No.")
                {
                    ToolTip = 'Specifies the employee number associated with the export log entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export File")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export File';
                Image = ExportFile;
                ToolTip = 'Export the report data to a file.';

                trigger OnAction()
                begin
                    CalcFields("Exported File");
                    if "Exported File".HasValue() then begin
                        TempBlob.FromRecord(Rec, FieldNo("Exported File"));
                        FileMgt.BLOBExport(TempBlob, "File Name", true);
                    end else
                        Message(Text001);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Export File_Promoted"; "Export File")
                {
                }
            }
        }
    }

    var
        Text001: Label 'There is nothing to export.';
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
}

