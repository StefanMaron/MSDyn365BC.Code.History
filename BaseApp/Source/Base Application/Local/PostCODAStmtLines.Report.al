report 2000059 "Post CODA Stmt. Lines"
{
    Caption = 'Post CODA Stmt. Lines';
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Gen. Journal Line" = rim;
    ProcessingOnly = true;

    dataset
    {
        dataitem(CodBankStmt; "CODA Statement")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            dataitem(CodBankStmtLine; "CODA Statement Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type) WHERE(ID = CONST(Movement));

                trigger OnAfterGetRecord()
                begin
                    if "Application Status" = "Application Status"::" " then
                        CodBankStmtPost.ProcessCodBankStmtLine(CodBankStmtLine);
                    LineNo := LineNo + 1;
                    Window.Update(2, LineNo);
                    Window.Update(3, Round(LineNo / TotRecords * 10000, 1));
                end;

                trigger OnPostDataItem()
                begin
                    if PrintReport then begin
                        Commit();
                        ManualApplication.SetSelection(false);
                        ManualApplication.SetTableView(CodBankStmt);
                        ManualApplication.RunModal
                    end
                end;

                trigger OnPreDataItem()
                begin
                    TotRecords := Count;
                    CodBankStmtPost.InitCodeunit(false, DefaultApplication);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, StrSubstNo(Text001, "Bank Account No.", "Statement No."));
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  '#1#################################\\' +
                  Text000)
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DefaultApplication; DefaultApplication)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Default Posting';
                        ToolTip = 'Specifies if you want the CODA statement lines that cannot be matched to a general ledger account or to a customer or vendor ledger entry, to be considered as default postings in the Transaction Coding table. If this field is cleared, you will have to enter the information manually and then run this batch job again.';
                    }
                    field(PrintReport; PrintReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print List';
                        ToolTip = 'Specifies if you want to print a report that contains all statement lines that have been considered as default posting.';
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

    var
        Text000: Label 'Document No.          #2###### @3@@@@@@@@@@@@@';
        Text001: Label 'Initializing %1 %2...', Comment = 'Parameter 1 - bank account number, 2 - statement number.';
        ManualApplication: Report "CODA Statement - List";
        CodBankStmtPost: Codeunit "Post Coded Bank Statement";
        Window: Dialog;
        DefaultApplication: Boolean;
        PrintReport: Boolean;
        LineNo: Integer;
        TotRecords: Integer;
}

