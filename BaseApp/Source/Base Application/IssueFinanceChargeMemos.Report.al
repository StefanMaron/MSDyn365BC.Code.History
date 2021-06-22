report 193 "Issue Finance Charge Memos"
{
    Caption = 'Issue Finance Charge Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Finance Charge Memo Header"; "Finance Charge Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                Clear(FinChrgMemoIssue);
                FinChrgMemoIssue.Set("Finance Charge Memo Header", ReplacePostingDate, PostingDateReq);
                if NoOfRecords = 1 then begin
                    FinChrgMemoIssue.Run;
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                    Mark := not FinChrgMemoIssue.Run;
                end;

                if (PrintDoc <> PrintDoc::" ") and not Mark then begin
                    FinChrgMemoIssue.GetIssuedFinChrgMemo(IssuedFinChrgMemoHeader);
                    TempIssuedFinChrgMemoHeader := IssuedFinChrgMemoHeader;
                    TempIssuedFinChrgMemoHeader.Insert();
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                Window.Close;
                Commit();
                if PrintDoc <> PrintDoc::" " then
                    if TempIssuedFinChrgMemoHeader.FindSet then
                        repeat
                            IssuedFinChrgMemoHeader := TempIssuedFinChrgMemoHeader;
                            IsHandled := false;
                            OnBeforePrintRecords(IssuedFinChrgMemoHeader, IsHandled);
                            if not IsHandled then begin
                                IssuedFinChrgMemoHeader.SetRecFilter;
                                IssuedFinChrgMemoHeader.PrintRecords(false, PrintDoc = PrintDoc::Email, HideDialog);
                            end;
                        until TempIssuedFinChrgMemoHeader.Next = 0;
                MarkedOnly := true;
                if FindFirst then
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, "Finance Charge Memo Header");
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text001)
                else begin
                    Window.Open(Text002);
                    OldDateTime := CurrentDateTime;
                end;
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
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want the program to print the finance charge memos when they are issued.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the finance charge memos'' posting date with the date entered in the field below.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date. If you place a check mark in the check box above, the program will use this date on all finance charge memos when you post.';
                    }
                    field(HideEmailDialog; HideDialog)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Hide Email Dialog';
                        ToolTip = 'Specifies if you want to hide email dialog.';
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
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Issuing finance charge memo...';
        Text002: Label 'Issuing finance charge memos @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to issue some of the selected finance charge memos.\Do you want to see these finance charge memos?';
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        TempIssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header" temporary;
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        PrintDoc: Option " ",Print,Email;
        HideDialog: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;
}

