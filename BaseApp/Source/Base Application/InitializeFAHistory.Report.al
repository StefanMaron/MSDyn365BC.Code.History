report 31038 "Initialize FA History"
{
    Caption = 'Initialize FA History';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            begin
                FAHistoryEntry.SetRange("FA No.", "No.");
                if FAHistoryEntry.FindFirst or (("FA Location Code" = '') and ("Responsible Employee" = '')) then
                    CurrReport.Skip();

                FAHistoryEntry.InitializeFAHistory("Fixed Asset", PostingDate);
            end;

            trigger OnPostDataItem()
            begin
                Message(Text000Msg);
            end;

            trigger OnPreDataItem()
            begin
                FASetup.Get();
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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date to create fixed asset history entries.';
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

    trigger OnPreReport()
    begin
        if PostingDate = 0D then
            Error(Text001Err);
    end;

    var
        FAHistoryEntry: Record "FA History Entry";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        PostingDate: Date;
        NextEntryNo: Integer;
        Counter: Integer;
        Text000Msg: Label 'Initial FA History Entries are created.';
        Text001Err: Label 'Posting Date is required.';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewPostingDate: Date)
    begin
        PostingDate := NewPostingDate;
    end;
}

