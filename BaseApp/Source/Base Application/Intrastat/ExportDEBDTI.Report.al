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
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
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
                    }
                    field("Obligation Level"; ObligationLevel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Obligation Level';
                        OptionCaption = ',1,2,3,4,5';
                        ToolTip = 'Specifies the obligation level based on the amount of receipts and dispatches from January 1 to December 31 in the previous year. For more information about the obligation level you should use, see the French Customs website.';

                        trigger OnValidate()
                        begin
                            SetTransactionSpecFilter();
                        end;
                    }
                    field("Transaction Specification Filter"; TransactionSpecificationFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transaction Specification Filter';
                        ToolTip = 'Specifies a filter for which types of transactions on Intrastat lines that will be processed for the chosen obligation level. Leave the field blank to include all transaction specifications.';
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
        SetTransactionSpecFilter();
    end;

    var
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        ExportDEBDTI: Codeunit "Export DEB DTI";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        FileName: Text;
        TransactionSpecificationFilter: Text;
        Text001: Label 'The journal lines were successfully exported.';
        ObligationLevel: Option ,"1","2","3","4","5";

#if not CLEAN20
    [Obsolete('Replaced by new InitializeRequest(OutStream)', '20.0')]
    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
    end;

    local procedure ExportToXML(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatFileWriter.Initialize(false, false, 0);
        if FileName = '' then
            FileName := IntrastatFileWriter.GetDefaultXMLFileName();
        IntrastatFileWriter.InitializeNextFile(FileName);
        IntrastatFileWriter.SetStatisticsPeriod(IntrastatJnlBatch."Statistics Period");

        IntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.SetFilter("Transaction Specification", TransactionSpecificationFilter);
        if IntrastatJnlLine.FindSet() then
            repeat
                IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Export DEB DTI", true);
            until IntrastatJnlLine.Next() = 0;

        if ExportDEBDTI.ExportToXML(IntrastatJnlLine, ObligationLevel, IntrastatFileWriter.GetCurrFileOutStream()) then
            Message(Text001);

        IntrastatFileWriter.AddCurrFileToResultFile();
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    local procedure SetTransactionSpecFilter()
    begin
        // transaction codes 11 and 19 are for receipts, they are not reported for level 4 and 5.
        case ObligationLevel of
            1:
                TransactionSpecificationFilter := '11|19|21|29';
            4:
                TransactionSpecificationFilter := '<>29&<>11&<>19';
            5:
                TransactionSpecificationFilter := '<>11&<>19';
            else
                TransactionSpecificationFilter := '';
        end;
    end;
}

