report 10821 "Export DEB DTI"
{
    Caption = 'Export DEB DTI';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);

            trigger OnAfterGetRecord()
            begin
                ExportToXML("Intrastat Jnl. Batch");
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
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the path and file name to store your DEB data. Add the XML file name extension to the file name.';

                        trigger OnAssistEdit()
                        var
                            FileMgt: Codeunit "File Management";
                        begin
                            if FileName = '' then
                                FileName := '.xml';
                            FileName := FileMgt.SaveFileDialog(Text002, FileName, '');
                        end;
                    }
                    field("Obligation Level"; ObligationLevel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Obligation Level';
                        OptionCaption = ',1,2,3,4';
                        ToolTip = 'Specifies the obligation level based on the amount of receipts and dispatches from January 1 to December 31 in the previous year. For more information about the obligation level you should use, see the French Customs website.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ObligationLevel := 1;
    end;

    trigger OnPreReport()
    begin
        if FileName = '' then
            Error(Text004);
    end;

    var
        FileName: Text;
        Text001: Label 'The journal lines were successfully exported.';
        ObligationLevel: Option ,"1","2","3","4";
        Text002: Label 'Export DEB DTI+ to XML.';
        Text004: Label 'A destination file must be specified.';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure ExportToXML(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ExportDEBDTI: Codeunit "Export DEB DTI";
    begin
        IntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        if ExportDEBDTI.ExportToXML(IntrastatJnlLine, ObligationLevel, FileName) then
            Message(Text001);
    end;
}

